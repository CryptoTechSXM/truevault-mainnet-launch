 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TrueVaultToken is ERC20, Ownable2Step {
    constructor(address initialOwner) ERC20("TrueVault Token", "TVLT") {
        _mint(initialOwner, 10_000_000 * 1e9);
    }
}
