// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "./StakeableNFT.sol"; 
import "./StakeRewardToken.sol";
import "forge-std/console.sol";

contract NFTStaker is IERC721Receiver, Ownable{
    IERC721 public stakeableNFT;
    mapping(uint256 => address) public originalOwner;
    mapping(address => stakerInfo) public stakersMap;
    uint256 constant public _rewardsPerDay = 10;
    uint256 constant public _decimals = 18;
    StakeRewardToken public rewardToken;

    struct stakerInfo {
        uint256 nftsStaked;
        uint256 timeStaked;
        uint256 leftover;
    }

    function getStakerInfo(address user) public view returns (stakerInfo memory){
        return stakersMap[user];
    }

    constructor(IERC721 _address, address _rewardToken) {
        stakeableNFT = _address;
        rewardToken = StakeRewardToken(_rewardToken);
    }

    function depositNFT(uint256 tokenId) external{
        originalOwner[tokenId] = msg.sender;
        stakeableNFT.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function withdrawNFT(uint256 tokenId) external{
        require(originalOwner[tokenId] == msg.sender, "Not original owner");
        stakersMap[msg.sender].nftsStaked -= 1;
        stakeableNFT.safeTransferFrom(address(this), msg.sender, tokenId);      
    }

    function newDeposit(address from) internal {
        if(stakersMap[from].nftsStaked > 0) {
            collectRewards();
        }
        stakersMap[from].nftsStaked += 1;
    }

    function collectRewards(address from) internal {
        (uint256 toGive, uint256 toRetain) = calculateReward(from);
        rewardToken.mintReward(toGive, from);
        stakersMap[from].timeStaked = block.timestamp;
        stakersMap[from].leftover = toRetain;
    }

    function collectRewards() public {
        collectRewards(msg.sender);
    }

    function calculateReward(address from) public view returns (uint256, uint256){
        uint256 timesSinceClaim = block.timestamp - stakersMap[from].timeStaked;
        uint256 totalRewards = stakersMap[from].leftover + stakersMap[from].nftsStaked * _rewardsPerDay * 10**_decimals * (timesSinceClaim)/(60*60*24);
        uint256 unitsOfTenRewards = (totalRewards/10**18)*10**18;
        uint256 remainder = totalRewards - unitsOfTenRewards;
        return (unitsOfTenRewards, remainder);
    }

    // depositing an additional NFT will let users claim pending reward and start fresh
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // make sure we can only transfer the NFT collection we want
        require(msg.sender == address(stakeableNFT), "Non acceptable NFT");
        originalOwner[tokenId] = from;
        newDeposit(from);
        return IERC721Receiver.onERC721Received.selector;
    }
}