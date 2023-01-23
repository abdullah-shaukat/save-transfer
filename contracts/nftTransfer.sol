// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket {

    uint64 public serviceFee = 100;     // 100 basis points == 1% (means 100 / 1000)
    mapping(address => mapping(uint256 => uint256)) public prices;  // collection address --> token ID --> price in eth

    function swapOut(address token, address recipient, uint256 tokenId) public payable {
        require(token != address(0x0) && recipient != address(0x0), "Token & recipient addresses connot be Zero!");
        require(prices[token][tokenId] > 0, "Invalid token ID or collection");

        uint256 value = msg.value;  // should be in ethers
        uint price = (prices[token][tokenId]);  // convert ethers to wei
        uint totalFee = (price * serviceFee) / 10000; // calculate 1% service fee (0.01)
        require(value >= (price + totalFee), "Insufficient ether provided!");

        // require(IERC721(token).safeTransferFrom(msg.sender, recipient, tokenId), "Transfer of NFT ownership failed!");
        IERC721(token).safeTransferFrom(msg.sender, recipient, tokenId);

        // send any extra ether to the target address
        uint256 excessEth = value - (price + totalFee);
        (bool sent, ) = recipient.call{value: excessEth}("");
        require(sent, "Failed to send excess Ether to recipent!");
    }

    function setPrice(address token, uint256 tokenId, uint256 priceInEth) public {
        // require(msg.sender == token, "Only the token contract can set its own prices");
        prices[token][tokenId] = priceInEth;
    }

}
