// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/StakeableNFT.sol";
import "../src/NFTStaker.sol";
import "../src/StakeRewardToken.sol";

contract NFTStakerTest is Test {
    NFTStaker public stakingContract;
    StakeableNFT public stakeableNFT;
    StakeRewardToken public stakeRewardToken;
    address owner;
    address user;
    uint256 constant testTokenId = 0;
    bytes32[] proof;

    function setUp() public {
        owner = address(this);
        user = address(1);
        stakeableNFT = new StakeableNFT();
        stakeRewardToken = new StakeRewardToken();
        stakingContract = new NFTStaker(stakeableNFT, address(stakeRewardToken));
        stakeRewardToken.allowToMint(address(stakingContract));
    }

    function testInit() public {
        assertEq(address(stakingContract.stakeableNFT()), address(stakeableNFT));
        assertEq(address(stakingContract.rewardToken()), address(stakeRewardToken));
    }

    function testDepositWithoutApproval() public {
        vm.startPrank(user);
        stakeableNFT.mint();
        vm.expectRevert("ERC721: caller is not token owner or approved");
        stakingContract.depositNFT(testTokenId);
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.startPrank(user);
        stakeableNFT.mint();
        stakeableNFT.approve(address(stakingContract), stakeableNFT.tokenSupply() - 1);
        stakingContract.depositNFT(stakeableNFT.tokenSupply() - 1);
        vm.stopPrank();

        assertEq(stakeableNFT.balanceOf(user), 0);
        assertEq(stakeableNFT.balanceOf(address(stakingContract)), 1);
        uint256 tokenId = stakeableNFT.tokenSupply() - 1;
        assertEq(stakingContract.getStakerInfo(tokenId).nftOwner, user);
        assertEq(stakingContract.getStakerInfo(tokenId).timeStaked, block.number);
    }

    function testWithdrawAfterDeposit() public {
        testDeposit();
        vm.prank(user);
        stakingContract.withdrawNFT(testTokenId);

        assertEq(stakeableNFT.balanceOf(user), 1);
        assertEq(stakeableNFT.balanceOf(address(stakingContract)), 0);
    }

    function testTransferInsteadOfDeposit() public {
        vm.startPrank(user);
        stakeableNFT.mint();
        vm.expectRevert("Please transfer the NFT through the staking function");
        stakeableNFT.safeTransferFrom(user, address(stakingContract), 0);

        assertEq(stakeableNFT.balanceOf(user), 1);
        assertEq(stakeableNFT.balanceOf(address(stakingContract)), 0);
        vm.stopPrank();
    }

    function testCollectRewardSingleToken() public {
        vm.startPrank(user);
        stakeableNFT.mint();
        stakeableNFT.mint();
        stakeableNFT.mint();
        stakeableNFT.approve(address(stakingContract), 2);
        stakingContract.depositNFT(2);

        vm.warp(block.timestamp + 60 * 60 * 24);
        stakingContract.collectReward(2);

        assertEq(stakeRewardToken.balanceOf(user), 1 * stakingContract.getRewardPerDay(2) * 10 ** 18);
    }

    function testWithdrawOthersNFT() public {
        testDeposit();
        vm.expectRevert("Not original owner");
        vm.prank(owner);
        uint256 tokenId = 0;
        stakingContract.withdrawNFT(tokenId);
    }

    function testRewardCalculation() public {
        vm.startPrank(user);
        stakeableNFT.mint();
        stakeableNFT.approve(address(stakingContract), stakeableNFT.tokenSupply() - 1);
        stakingContract.depositNFT(stakeableNFT.tokenSupply() - 1);
        stakeableNFT.mint();
        stakeableNFT.approve(address(stakingContract), stakeableNFT.tokenSupply() - 1);
        stakingContract.depositNFT(stakeableNFT.tokenSupply() - 1);
        vm.stopPrank();

        vm.warp(block.timestamp + 60 * 60 * 24);
        vm.warp(block.timestamp + 60 * 60 * 24);

        (uint256 reward,) = stakingContract.calculateReward(0);
        (uint256 reward2,) = stakingContract.calculateReward(1);
        assertEq(reward, 2 * stakingContract.getRewardPerDay(0) * 10 ** 18);
        assertEq(reward2, 2 * stakingContract.getRewardPerDay(1) * 10 ** 18);
    }

    function testStakeAndReward() public {
        testDeposit();
        uint256 tokenId = 0;
        (uint256 reward, uint256 remainder) = stakingContract.calculateReward(tokenId);
        assertEq(reward, 0);

        vm.warp(block.timestamp + 60 * 60 * 24);
        (reward,) = stakingContract.calculateReward(tokenId);
        assertEq(reward, stakingContract.getRewardPerDay(tokenId) * 10 ** 18);

        vm.prank(user);
        stakingContract.collectRewards();
        uint256 leftovers = stakingContract.getStakerInfo(tokenId).leftover;
        (reward, remainder) = stakingContract.calculateReward(tokenId);
        assertEq(reward, 0);
        assertEq(remainder, leftovers);
        assertEq(stakeRewardToken.balanceOf(user), stakingContract.getRewardPerDay(tokenId) * 10 ** 18);
    }
}
