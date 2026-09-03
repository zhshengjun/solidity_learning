// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title FeeManager
/// @notice 固定价市场与拍卖市场共用的费率、版税计算和 NFT 活跃状态中心。
/// @dev 本合约不托管 NFT 或 ETH；实际资产转移仍在两个 Market 合约内完成。
contract FeeManager is Ownable {
    error InvalidFeeRecipient();
    error NotMarket();
    error InvalidMarket();
    error NFTAlreadyActive();
    error RoyaltyTooHigh();
    error InvalidRoyalty();
    error FeeTooHigh();

    /// @notice 平台手续费率，单位为基点；250 表示 2.5%。
    uint256 public platformFee = 250;

    /// @notice 接收平台手续费的地址，同时可修改手续费率和自身地址。
    address public feeRecipient;

    /// @notice 被 owner 授权、可修改 activeNFTs 的市场合约白名单。
    mapping(address => bool) public markets;

    /// @notice 某 NFT 是否正在任一受信任市场中挂单或拍卖。
    /// @dev key 为 nftContract => tokenId，用于阻止同一 NFT 跨市场重复上架。
    mapping(address => mapping(uint256 => bool)) public activeNFTs;

    /**
     * @param _feeRecipient 初始平台手续费接收人。
     */
    constructor(address _feeRecipient) Ownable(msg.sender) {
        require(_feeRecipient != address(0), InvalidFeeRecipient());
        feeRecipient = _feeRecipient;
    }

    /// @dev 只允许 owner 已登记的市场合约调用。
    modifier onlyMarket() {
        require(markets[msg.sender], NotMarket());
        _;
    }

    /**
     * @notice 登记或移除一个市场合约。
     * @dev 部署 FixedPriceMarket 和 AuctionMarket 后，owner 必须分别登记它们。
     */
    function setMarket(address market, bool enabled) external onlyOwner {
        require(market != address(0), InvalidMarket());
        markets[market] = enabled;
    }

    /**
     * @notice 将 NFT 标记为活跃，阻止其他市场再次上架。
     * @dev 若同一个 NFT 已有固定价挂单或拍卖，此调用会 revert。
     */
    function openNFT(address nftContract, uint256 tokenId) external onlyMarket {
        require(!activeNFTs[nftContract][tokenId], NFTAlreadyActive());
        activeNFTs[nftContract][tokenId] = true;
    }

    /**
     * @notice 在成交、下架或拍卖结束时解除 NFT 活跃标记。
     */
    function closeNFT(
        address nftContract,
        uint256 tokenId
    ) external onlyMarket {
        activeNFTs[nftContract][tokenId] = false;
    }

    /**
     * @notice 计算一笔成交应支付的平台费和 ERC-2981 版税。
     * @dev NFT 不支持 ERC-2981 或接口调用失败时，版税返回零；平台费仍会计算。
     * @return royaltyReceiver 版税接收人；不支持版税时为零地址
     * @return royaltyAmount 版税金额
     * @return fee 平台手续费金额
     */
    function calculateElementInfo(
        address nftContract,
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        returns (address royaltyReceiver, uint256 royaltyAmount, uint256 fee)
    {
        // 不支持的版税的是0
        royaltyReceiver = address(0);
        royaltyAmount = 0;

        fee = (salePrice * platformFee) / 10_000;

        // 先用 ERC-165 确认支持官方 IERC2981 接口，避免直接调用非标准 NFT 合约。
        try
            IERC165(nftContract).supportsInterface(type(IERC2981).interfaceId)
        returns (bool supported) {
            if (supported) {
                // 即使 NFT 声称支持 ERC-2981，royaltyInfo 仍可能 revert，因此单独捕获。
                try
                    IERC2981(nftContract).royaltyInfo(tokenId, salePrice)
                returns (address receiver, uint256 amount) {
                    // 版税不能吞掉卖家收益，也不能支付给零地址。
                    require(amount <= salePrice - fee, RoyaltyTooHigh());
                    require(
                        amount == 0 || receiver != address(0),
                        InvalidRoyalty()
                    );

                    royaltyReceiver = receiver;
                    royaltyAmount = amount;
                } catch {}
            }
        } catch {}
    }

    /**
     * @notice 更新平台费率，最高 10%。
     * @dev 仅 owner 可修改；feeRecipient 仅负责接收手续费。
     */
    function setPlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1_000, FeeTooHigh());
        platformFee = newFee;
    }

    /**
     * @notice 更新平台手续费接收人。
     */
    function updateFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), InvalidFeeRecipient());
        feeRecipient = newRecipient;
    }
}
