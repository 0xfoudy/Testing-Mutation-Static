// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/StakeableNFT.sol";

contract StakeableNFTTest is Test {
    StakeableNFT public stakeableNFT;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        user1 = address(1);
        user2 = address(2);
        stakeableNFT = new StakeableNFT();
    }

    function testTryMint() public {
        stakeableNFT.mint();
        assertEq(stakeableNFT.tokenSupply(), 1);
        assertEq(stakeableNFT.ownerOf(0), owner);
    }

    function testTryOvermint() public {
        for (uint256 i = 0; i < 20; ++i) {
            stakeableNFT.mint();
        }
        assertEq(stakeableNFT.tokenSupply(), 20);
        vm.expectRevert("Supply already at limit");
        stakeableNFT.mint();
    }

    function testURI() public {
        stakeableNFT.mint();
        assertEq(stakeableNFT.tokenURI(0), "ipfs://QmZZzC4v7M6ZTYnuEgfA5qwHQUTm1DwRF8j3CQKtY6EXMF/0");
    }
}
