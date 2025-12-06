// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrueVaultUSDT is ERC20, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public constant want = IERC20(0x55d398326f99059fF775485246999027B3197955);
    uint256 public totalDeposits;
    address public immutable guardian;

    constructor(address _guardian, address initialOwner) 
        ERC20("TrueVault USDT", "tvUSDT") 
        Ownable(initialOwner) 
    {
