// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTMarket is ChainlinkClient, ConfirmedOwner {
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

    // address private owner;
    uint256 private serviceFee = 100;     // 100 basis points == 1% (means 100 / 1000)
    uint256 private collectedServiceFee = 0;
    uint256 private fee;
    bytes32 private jobId;
    address private admin;
    address private linkFaucetAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    string private backendAPI = "https://mocki.io/v1/1a4747ea-b5c1-4a11-8cb3-c841062a5585";
    bool private locked;

    uint256 public prices;  // will be retrived in wei

    modifier noReentrant() {
        require(!locked, "No re-entrancy!");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "No right to access!");
        _;
    }

    constructor() ConfirmedOwner(msg.sender) {
        prices = 0;
        admin = msg.sender;

        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)  // for goerli (https://docs.chain.link/any-api/testnet-oracles)
    }

    function requestTokenPrice(address _collection, uint256 _tokenId) public returns (bytes32 reqestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        string memory link = string(abi.encodePacked(backendAPI, "?address=", Strings.toHexString(uint256(uint160(_collection)), 20), "&tokenId=", Strings.toString(_tokenId)));

        // Set the URL to perform the GET request on "abc" + route
        req.add(
            "get",
            link
        );
        // json structure { "value": 123 }
        req.add("path", "value");

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10 ** 18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    function fulfill(
        bytes32 _requestId,
        uint256 _volume
    ) public recordChainlinkFulfillment(_requestId) {
        prices = _volume;
    }

    function swapOut(address _token, address _recipient, uint256 _tokenId) external payable noReentrant returns (bool swapStatus) {
        require(_token != address(0x0) && _recipient != address(0x0), "Token & recipient addresses connot be Zero!");
        requestTokenPrice(_token, _tokenId);
        require(prices > 0, "Invalid token ID or collection");

        uint256 value = msg.value;  // should be in ethers
        uint totalFee = (prices * serviceFee) / 10000; // calculate 1% service fee (0.01)
        collectedServiceFee += totalFee;
        require(value >= (prices + totalFee), "Insufficient ether provided!");

        // send NFT price to the owner of NFT
        (bool sent, ) = (IERC721(_token).ownerOf(_tokenId)).call{value: prices}("");
        require(sent, "Failed to send NFT price Ether to owner!");
        
        // send any extra ether to the target address
        uint256 excessEth = value - (prices + totalFee);
        (sent, ) = (msg.sender).call{value: excessEth}("");
        require(sent, "Failed to send excess Ether to recipent!");

        IERC721(_token).safeTransferFrom(msg.sender, _recipient, _tokenId);
        swapStatus = true;
    }

    function setServiceFee(uint256 basisPoints) external {
        serviceFee = basisPoints;
    }

    function getServiceFee() external view returns (uint256 serviceCharges) {
        serviceCharges = serviceFee;
    }

    function changeOwner(address _owner) external  onlyAdmin {
        require(_owner != address(0x0), "Address cannot be null!");
        admin = _owner;
    }

    function claimServiceFee() external payable onlyAdmin noReentrant {
        assert(collectedServiceFee > 0);
        (bool sent, ) = admin.call{value: collectedServiceFee}("");
        require(sent, "Failed to send service fees to owner!");
        collectedServiceFee = 0;
    }

    function claimChainLinkTokens() external onlyAdmin noReentrant {
        assert(IERC20(linkFaucetAddress).balanceOf(address(this)) > 0);
        IERC20(linkFaucetAddress).transfer(admin, IERC20(linkFaucetAddress).balanceOf(address(this)));
    }

    function chainLinkBalance() external view returns (uint256 _tokens) {
        return IERC20(linkFaucetAddress).balanceOf(address(this));
    }

}
