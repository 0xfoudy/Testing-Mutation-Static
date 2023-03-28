// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract StakeRewardToken is ERC20, Ownable {
    mapping(address => bool) private allowedToMint;
    uint256 public constant DECIMALS = 18;

    constructor() ERC20("StakeRewardToken", "RWRD") {}

    function allowToMint(address newMinter) public onlyOwner {
        allowedToMint[newMinter] = true;
    }

    function preventFromMinting(address exMinter) public onlyOwner {
        allowedToMint[exMinter] = false;
    }

    function mintReward(uint256 amountToMint, address to) public {
        require(allowedToMint[msg.sender], "not allowed to mint");
        _mint(to, amountToMint);
    }
}
