// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract NFTMarket is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    /**
     * @notice Initialize the link token and target oracle
     *
     * Goerli Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
     * jobId: ca98366cc7314957b8c012c72f05aeeb (single word response)
     *
     */

    address private owner;
    uint256 private serviceFee = 100;     // 100 basis points == 1% (means 100 / 1000)
    bytes32 private jobId;
    uint256 private fee;
    uint256 public prices;
    uint256 private collectedServiceFee = 0;

    bool private locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        prices = 0;
        owner = msg.sender;
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10;  // varies as per network & job
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);  // for goerli (https://docs.chain.link/any-api/testnet-oracles)
    }

    modifier onlyOnwer() {
        require(msg.sender == owner, "Rights reserved for the owner only!");
        _;
    }

    function requestTokenPrice(address _collection, uint256 _tokenId) public returns (bytes32 reqestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add("get","https://mocki.io/v1/e1a5efac-8e18-4f70-9947-105fa4edf466");
        // req.addBytes("address", abi.encode(_collection)); 
        // say; {"contract" : { "tokens" : { "value": 123} } } then req.add("path", "contract,tokens,value")
        // json structure { "value": 123 }
        req.add("path", "value");

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    function fulfill(
        bytes32 _requestId,
        uint256 _price
    ) public recordChainlinkFulfillment(_requestId) {
        prices = _price;
    }

    function swapOut(address _token, address _recipient, uint256 _tokenId) external payable noReentrant {
        require(_token != address(0x0) && _recipient != address(0x0), "Token & recipient addresses connot be Zero!");
        // requestTokenPrice(_token, _tokenId);
        require(prices > 0, "Invalid token ID or collection");

        uint256 value = msg.value;  // should be in ethers
        uint totalFee = (prices * serviceFee) / 10000; // calculate 1% service fee (0.01)
        collectedServiceFee += totalFee;
        require(value >= (prices + totalFee), "Insufficient ether provided!");

        IERC721(_token).safeTransferFrom(msg.sender, _recipient, _tokenId);

        // send any extra ether to the target address & token price to owner
        uint256 excessEth = value - (prices + totalFee);
        (bool sent, ) = _recipient.call{value: excessEth}("");
        require(sent, "Failed to send excess Ether to recipent!");
        (sent, ) = _recipient.call{value: prices}("");
        require(sent, "Failed to send NFT price Ether to owner!");
    }

    function changeOwner(address _owner) external onlyOnwer {
        owner = _owner;
    }

    function setServiceFee(uint256 basisPoints) external onlyOnwer {
        serviceFee = basisPoints;
    }

    function getServiceFee() external view returns (uint256 serviceCharges) {
        serviceCharges = serviceFee;
    }

    function claimServiceFee() external payable onlyOnwer noReentrant {
        assert(collectedServiceFee > 0);
        (bool sent, ) = owner.call{value: collectedServiceFee}("");
        require(sent, "Failed to send service fees to owner!");
        collectedServiceFee = 0;
    }

}
