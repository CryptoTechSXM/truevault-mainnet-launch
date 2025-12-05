 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TrueVaultUSDT is ERC20, ReentrancyGuard, Pausable, Ownable2Step {
    using SafeERC20 for IERC20;
    IERC20 public constant want = IERC20(0x55d398326f99059fF775485246999027B3197955);
    uint256 public totalDeposits;
    address public immutable guardian;
    constructor(address _guardian, address initialOwner) ERC20("TrueVault USDT", "tvUSDT") Ownable2Step(initialOwner) {
        guardian = _guardian;
    }
    function deposit(uint256 a) external whenNotPaused nonReentrant { uint256 s = totalSupply()==0?a:(a*totalSupply())/totalDeposits; totalDeposits+=a; _mint(msg.sender,s); want.safeTransferFrom(msg.sender,address(this),a); }
    function withdraw(uint256 s) external whenNotPaused nonReentrant { uint256 a=(s*totalDeposits)/totalSupply(); _burn(msg.sender,s); totalDeposits-=a; want.safeTransfer(msg.sender,a); }
    function emergencyWithdraw() external nonReentrant { uint256 s=balanceOf(msg.sender); uint256 a=(s*totalDeposits)/totalSupply(); _burn(msg.sender,s); totalDeposits-=a; want.safeTransfer(msg.sender,a); }
    function pause() external { require(msg.sender==guardian||msg.sender==owner()); _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
