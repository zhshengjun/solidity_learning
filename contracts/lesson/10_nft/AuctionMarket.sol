// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {FeeManager} from "./FeeManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AuctionMarket
/// @notice 英式拍卖市场：后一个有效出价必须至少高出当前最高价 5%。
/// @dev NFT 留在卖家地址，拍卖结束且有人出价时才转给最高出价者。
contract AuctionMarket is ReentrancyGuard {
    error InvalidFeeManager();
    error InvalidStartPrice();
    error DurationTooShort();
    error InvalidNFTContract();
    error NotNFTOwner();
    error MarketNotApproved();
    error AuctionNotActive();
    error AuctionHasEnded();
    error SellerCannotBid();
    error BidTooLow();
    error NoPendingReturn();
    error AuctionNotEnded();
    error PaymentFailed(address recipient, uint256 amount);

    /// @notice 一场拍卖的完整状态。
    struct Auction {
        /// @notice NFT 当前所有者，也是成功结算后的收款人。
        address seller;
        /// @notice ERC-721 合约地址。
        address nftContract;
        /// @notice NFT 的 tokenId。
        uint256 tokenId;
        /// @notice 第一笔出价的最低价格，单位 wei。
        uint256 startPrice;
        /// @notice 当前最高出价，单位 wei。
        uint256 highestBid;
        /// @notice 当前最高出价者；尚未出价时为零地址。
        address highestBidder;
        /// @notice Unix 时间戳；此时刻后才能结算。
        uint256 endTime;
        /// @notice true 表示可继续出价；结算后为 false。
        bool active;
    }

    /// @notice 共用的费率、版税和跨市场 NFT 锁定合约。
    FeeManager public immutable feeManager;

    /// @notice auctionId 到拍卖内容的映射。
    mapping(uint256 => Auction) public auctions;

    /// @notice 被超越的出价者可自行提取的 ETH。
    /// @dev pull payment 模式避免在 placeBid 中直接退款造成 DoS 或重入风险。
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;

    /// @notice 单调递增的拍卖 ID 计数器。
    uint256 public auctionCounter;

    /// @notice 卖家成功创建拍卖。
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 startPrice, uint256 endTime);
    /// @notice 新最高价产生；旧最高价会记入 pendingReturns。
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    /// @notice 拍卖结束；流拍时 winner 为零地址、finalPrice 为零。
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 finalPrice);

    /**
     * @param _feeManager 已部署的共享 FeeManager 地址。
     */
    constructor(FeeManager _feeManager) {
        require(address(_feeManager) != address(0), InvalidFeeManager());
        feeManager = _feeManager;
    }

    /**
     * @notice 创建一场拍卖。
     * @dev 调用前卖家必须授权本合约；NFT 不会在这里转入市场。
     * @return auctionId 新创建的拍卖 ID。
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 durationHours
    ) external returns (uint256 auctionId) {
        require(startPrice > 0, InvalidStartPrice());
        require(durationHours >= 1, DurationTooShort());
        require(nftContract != address(0), InvalidNFTContract());

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, NotNFTOwner());
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            MarketNotApproved()
        );

        // 先登记共享锁，避免同一 NFT 同时进入 FixedPriceMarket。
        feeManager.openNFT(nftContract, tokenId);
        auctionId = ++auctionCounter;
        uint256 endTime = block.timestamp + durationHours * 1 hours;
        auctions[auctionId] = Auction(msg.sender, nftContract, tokenId, startPrice, 0, address(0), endTime, true);

        emit AuctionCreated(auctionId, msg.sender, nftContract, tokenId, startPrice, endTime);
    }

    /**
     * @notice 对一场有效且未结束的拍卖出价。
     * @dev 新出价覆盖旧最高价，旧最高价改为 pendingReturns 中的可提现余额。
     */
    function placeBid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(auction.active, AuctionNotActive());
        require(block.timestamp < auction.endTime, AuctionHasEnded());
        require(msg.sender != auction.seller, SellerCannotBid());

        // 首次出价至少为起拍价；之后每次至少增加当前最高价的 5%。
        uint256 minBid = auction.highestBid == 0
            ? auction.startPrice
            : auction.highestBid + auction.highestBid * 5 / 100;
        require(msg.value >= minBid, BidTooLow());

        if (auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    /**
     * @notice 提取自己被超越的出价。
     * @dev 先清零再转账，并由 nonReentrant 防止回调重入。
     */
    function withdrawBid(uint256 auctionId) external nonReentrant {
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, NoPendingReturn());

        pendingReturns[auctionId][msg.sender] = 0;
        _pay(msg.sender, amount);
    }

    /**
     * @notice 结束已到期的拍卖，任何人均可调用。
     * @dev 有人出价则转移 NFT 并分账；无人出价则仅解除共享锁并标记流拍。
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.active, AuctionNotActive());
        require(block.timestamp >= auction.endTime, AuctionNotEnded());

        // Effects：先终止拍卖，避免在后续外部调用期间重复结算。
        auction.active = false;
        feeManager.closeNFT(auction.nftContract, auction.tokenId);

        if (auction.highestBidder == address(0)) {
            emit AuctionEnded(auctionId, address(0), 0);
            return;
        }

        // 从共享规则中心取得本次成交的版税和平台费。
        (address royaltyReceiver, uint256 royaltyAmount, uint256 fee) = feeManager.calculateElementInfo(
            auction.nftContract,
            auction.tokenId,
            auction.highestBid
        );
        uint256 sellerAmount = auction.highestBid - fee - royaltyAmount;

        // Interactions：NFT 给赢家，ETH 按版税、卖家、平台费顺序分配。
        IERC721(auction.nftContract).safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);
        _pay(royaltyReceiver, royaltyAmount);
        _pay(auction.seller, sellerAmount);
        _pay(feeManager.feeRecipient(), fee);

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    /**
     * @dev 使用 call 转 ETH；金额为零时跳过无意义的外部调用。
     */
    function _pay(address recipient, uint256 amount) private {
        if (amount == 0) return;
        (bool success,) = recipient.call{value: amount}("");
        require(success, PaymentFailed(recipient, amount));
    }
}
