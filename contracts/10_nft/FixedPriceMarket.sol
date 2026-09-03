// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FeeManager} from "./FeeManager.sol";

/// @title FixedPriceMarket
/// @notice 以固定 ETH 价格出售 ERC-721 的市场合约。
/// @dev NFT 留在卖家地址，成交时才通过已授予的授权转移。
contract FixedPriceMarket is ReentrancyGuard {
    error InvalidFeeManager();
    error InvalidPrice();
    error InvalidNFTContract();
    error NotNFTOwner();
    error MarketNotApproved();
    error ListingNotActive();
    error NotListingSeller();
    error InsufficientPayment();
    error CannotBuyOwnNFT();
    error PaymentFailed(address recipient, uint256 amount);

    /// @notice 一条固定价挂单的完整状态。
    struct Listing {
        /// @notice NFT 当前所有者，也是成交后的收款人。
        address seller;
        /// @notice ERC-721 合约地址。
        address nftContract;
        /// @notice NFT 的 tokenId。
        uint256 tokenId;
        /// @notice 成交价格，单位 wei。
        uint256 price;
        /// @notice true 表示尚可购买；成交或下架后为 false。
        bool active;
    }

    /// @notice 共用的费率、版税和跨市场 NFT 锁定合约。
    FeeManager public immutable feeManager;

    /// @notice listingId 到挂单内容的映射。
    mapping(uint256 => Listing) public listings;

    /// @notice 单调递增的挂单 ID 计数器。
    uint256 public listingCounter;

    /// @notice 卖家成功创建固定价挂单。
    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    /// @notice 卖家主动取消挂单。
    event NFTDelisted(uint256 indexed listingId);
    /// @notice 卖家修改挂单价格。
    event PriceUpdated(uint256 indexed listingId, uint256 newPrice);
    /// @notice 买家付款、NFT 转移和资金分配全部成功后发出。
    event NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 price);

    /**
     * @param _feeManager 已部署的共享 FeeManager 地址。
     */
    constructor(FeeManager _feeManager) {
        require(address(_feeManager) != address(0), InvalidFeeManager());
        feeManager = _feeManager;
    }

    /**
     * @notice 创建一条固定价挂单。
     * @dev 调用前，卖家必须授权本合约转移该 NFT；NFT 不会在这里转入市场。
     * @return listingId 新创建的挂单 ID。
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 price) external returns (uint256 listingId) {
        require(price > 0, InvalidPrice());
        require(nftContract != address(0), InvalidNFTContract());

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, NotNFTOwner());
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            MarketNotApproved()
        );

        // 先登记共享锁，避免同一 NFT 同时进入 AuctionMarket。
        feeManager.openNFT(nftContract, tokenId);
        listingId = ++listingCounter;
        listings[listingId] = Listing(msg.sender, nftContract, tokenId, price, true);

        emit NFTListed(listingId, msg.sender, nftContract, tokenId, price);
    }

    /**
     * @notice 取消自己的有效挂单。
     * @dev 只修改状态和解除共享锁，不需要 NFT 转移。
     */
    function delistNFT(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.active, ListingNotActive());
        require(listing.seller == msg.sender, NotListingSeller());

        listing.active = false;
        feeManager.closeNFT(listing.nftContract, listing.tokenId);
        emit NFTDelisted(listingId);
    }

    /**
     * @notice 修改自己的有效挂单价格。
     */
    function updatePrice(uint256 listingId, uint256 newPrice) external {
        require(newPrice > 0, InvalidPrice());

        Listing storage listing = listings[listingId];
        require(listing.active, ListingNotActive());
        require(listing.seller == msg.sender, NotListingSeller());

        listing.price = newPrice;
        emit PriceUpdated(listingId, newPrice);
    }

    /**
     * @notice 以挂单价格购买 NFT，多付的 ETH 会退还给买家。
     * @dev 先关闭挂单并解除锁，再进行外部 NFT/ETH 调用，遵循 CEI 原则。
     */
    function buyNFT(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, ListingNotActive());
        require(msg.value >= listing.price, InsufficientPayment());
        require(msg.sender != listing.seller, CannotBuyOwnNFT());

        // Effects：阻止重入时重复购买同一挂单。
        listing.active = false;
        feeManager.closeNFT(listing.nftContract, listing.tokenId);

        // 从共享规则中心取得本次成交的版税和平台费。
        (address royaltyReceiver, uint256 royaltyAmount, uint256 fee) = feeManager.calculateElementInfo(
            listing.nftContract,
            listing.tokenId,
            listing.price
        );
        uint256 sellerAmount = listing.price - fee - royaltyAmount;

        // Interactions：NFT 给买家，ETH 按版税、卖家、平台费顺序分配。
        IERC721(listing.nftContract).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        _pay(royaltyReceiver, royaltyAmount);
        _pay(listing.seller, sellerAmount);
        _pay(feeManager.feeRecipient(), fee);
        _pay(msg.sender, msg.value - listing.price);

        emit NFTSold(listingId, msg.sender, listing.seller, listing.price);
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
