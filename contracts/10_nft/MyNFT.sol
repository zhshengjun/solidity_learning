// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    // Token ID计数器
    uint256 private _tokenIdCounter;

    // 最大供应量
    uint256 public constant MAX_SUPPLY = 10000;

    // 铸造价格
    uint256 public mintPrice = 0.01 ether;

    /**
     * @dev NFT铸造事件
     * @param minter 铸造者地址
     * @param tokenId 新创建的Token ID
     * @param uri 元数据URI
     */
    event NFTMinted(
        address indexed minter,
        uint256 indexed tokenId,
        string uri
    );

    // 余额异常
    error InsufficientPayment();

    // 构造器，这里还是需要显示的引入 ERC721
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    /**
     * @dev 铸造NFT
     * @param uri NFT的元数据URI（通常是IPFS链接）
     * @return 新创建的Token ID
     * @notice 需要支付mintPrice的ETH才能铸造
     */
    function mint(string memory uri) public payable returns (uint256) {
        // 检查供应量限制
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");

        // 检查支付金额
        require(msg.value >= mintPrice, InsufficientPayment());

        // 递增计数器
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        // 安全铸造NFT
        _safeMint(msg.sender, newTokenId);

        // 设置元数据URI
        _setTokenURI(newTokenId, uri);

        // 触发事件
        emit NFTMinted(msg.sender, newTokenId, uri);

        return newTokenId;
    }

    /**
     * @dev 查询总供应量
     * @return 已铸造的NFT数量
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 提取铸造费用
     * @notice 只有合约所有者可以调用
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "withdraw failed");
    }

    /**
     * @dev 设置铸造价格
     * @param newPrice 新的铸造价格（wei）
     * @notice 只有合约所有者可以调用
     */
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }
}
