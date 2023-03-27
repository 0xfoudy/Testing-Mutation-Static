// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract StakeableNFT is ERC721 {
    uint256 public tokenSupply;
    uint256 public constant MAX_SUPPLY = 10;

    constructor() ERC721("StakeableNFT", "Steak"){
        tokenSupply = 0;
    }

    function mint() external {
        require(tokenSupply < MAX_SUPPLY, "Supply already at limit");
        _mint(msg.sender, tokenSupply);
        ++tokenSupply;
    }

    function _baseURI() internal pure override returns (string memory){
        return "ipfs://QmZZzC4v7M6ZTYnuEgfA5qwHQUTm1DwRF8j3CQKtY6EXMF/";
    }
}