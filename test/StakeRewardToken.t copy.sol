// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/StakeRewardToken.sol";

contract StakeRewardTokenTest is Test {
    StakeRewardToken public stakeRewardToken;
    uint256 constant DECIMALS = 10 ** 18;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        user1 = address(1);
        user2 = address(2);
        stakeRewardToken = new StakeRewardToken();
    }

    function testAllowToMintNonAdmin() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user1);
        stakeRewardToken.allowToMint(user1);
    }

    function testPreventFromMintNonAdmin() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user1);
        stakeRewardToken.preventFromMinting(user1);
    }

    function testTryMint() public {
        vm.expectRevert("not allowed to mint");
        vm.prank(user1);
        stakeRewardToken.mintReward(1500 * DECIMALS, user1);
        stakeRewardToken.allowToMint(user1);
        vm.prank(user1);
        stakeRewardToken.mintReward(1500 * DECIMALS, user1);
        assertEq(stakeRewardToken.totalSupply(), 1500 * DECIMALS);
        assertEq(stakeRewardToken.balanceOf(user1), 1500 * DECIMALS);

        stakeRewardToken.preventFromMinting(user1);
        vm.expectRevert("not allowed to mint");
        stakeRewardToken.mintReward(1500 * DECIMALS, user1);
    }
}
