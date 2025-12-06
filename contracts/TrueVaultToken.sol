// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrueVaultToken is ERC20, Ownable {
    constructor(address initialOwner) 
        ERC20("TrueVault Token", "TVLT") 
        Ownable(initialOwner) 
    {
        _mint(initialOwner, 10_000_000 * 10**18); // 10 million TVLT
    }
}
