// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "./StakeableNFT.sol";
import "./StakeRewardToken.sol";
import "forge-std/console.sol";

contract NFTStaker is IERC721Receiver, Ownable {
    IERC721 public immutable stakeableNFT;
    StakeRewardToken public immutable rewardToken;
    mapping(uint256 => StakerInfo) public tokenIdToStaker;
    mapping(address => uint256[]) public addressToTokenIdMap;
    uint256[20] public rewardsPerDay = [10, 11, 13, 13, 12, 16, 17, 18, 14, 16, 10, 12, 13, 15, 13, 14, 11, 17, 17, 18];
    uint256 public constant _decimals = 18;

    struct StakerInfo {
        address nftOwner;
        uint256 timeStaked;
        uint256 leftover;
    }

    constructor(IERC721 _address, address _rewardToken) {
        stakeableNFT = _address;
        rewardToken = StakeRewardToken(_rewardToken);
    }

    function getStakerInfo(uint256 tokenId) public view returns (StakerInfo memory) {
        return tokenIdToStaker[tokenId];
    }

    function getRewardPerDay(uint256 tokenId) public view returns (uint256) {
        return rewardsPerDay[tokenId];
    }

    function withdrawNFT(uint256 tokenId) external {
        require(getStakerInfo(tokenId).nftOwner == msg.sender, "Not original owner");
        delete tokenIdToStaker[tokenId];
        delete addressToTokenIdMap[msg.sender][tokenId];
        stakeableNFT.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function collectTokenRewards(uint256 tokenId) public {
        require(getStakerInfo(tokenId).nftOwner == msg.sender, "Not original owner");
        (uint256 toGive, uint256 toRetain) = calculateReward(tokenId);
        tokenIdToStaker[tokenId].timeStaked = block.timestamp;
        tokenIdToStaker[tokenId].leftover = toRetain;
        rewardToken.mintReward(toGive, msg.sender);
    }

    function collectRewards() public {
        for (uint256 i = 0; i < addressToTokenIdMap[msg.sender].length; ++i) {
            collectTokenRewards(addressToTokenIdMap[msg.sender][i]);
        }
    }

    function calculateReward(uint256 tokenId) public view returns (uint256, uint256) {
        uint256 timesSinceClaim = block.timestamp - tokenIdToStaker[tokenId].timeStaked;
        uint256 totalRewards = tokenIdToStaker[tokenId].leftover
            + rewardsPerDay[tokenId] * 10 ** _decimals * (timesSinceClaim) / (60 * 60 * 24);
        uint256 unitsOfTenRewards = (totalRewards / 10 ** 18) * 10 ** 18;
        uint256 remainder = totalRewards - unitsOfTenRewards;
        return (unitsOfTenRewards, remainder);
    }

    // depositing an additional NFT will let users claim pending reward and start fresh
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // to prevent random NFTs to be sent
        require(msg.sender == address(stakeableNFT), "Non acceptable NFT");
        tokenIdToStaker[tokenId].nftOwner = from;
        tokenIdToStaker[tokenId].timeStaked = block.timestamp;
        addressToTokenIdMap[from].push(tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }
}
