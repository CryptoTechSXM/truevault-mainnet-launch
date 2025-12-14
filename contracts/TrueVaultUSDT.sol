// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVToken {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

contract TrueVaultUSDT is ERC20, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // BSC USDT
    IERC20 public constant want = IERC20(0x55d398326f99059fF775485246999027B3197955);

    // Venus vUSDT (BSC)
    IVToken public constant vUSDT = IVToken(0xfD5840Cd36d94D7229439859C0112a4185BC0255);

    address public immutable guardian;

    // Keep some USDT idle for instant withdrawals (basis points)
    uint256 public bufferBps = 300; // 3%
    uint256 public constant BPS = 10_000;

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event BufferUpdated(uint256 newBufferBps);

    constructor(address _guardian, address initialOwner)
        ERC20("TrueVault USDT", "tvUSDT")
        Ownable(initialOwner)
    {
        require(_guardian != address(0), "guardian=0");
        guardian = _guardian;
    }

    // ---------- Views ----------

    function totalAssets() public view returns (uint256) {
        // idle USDT
        uint256 idle = want.balanceOf(address(this));

        // underlying value of vUSDT held (Compound/Venus style)
        uint256 vBal = vUSDT.balanceOf(address(this));
        uint256 ex = vUSDT.exchangeRateStored(); // scaled by 1e18
        uint256 inVenus = (vBal * ex) / 1e18;

        return idle + inVenus;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 ts = totalSupply();
        uint256 ta = totalAssets();
        if (ts == 0 || ta == 0) return assets; // first depositor 1:1
        return (assets * ts) / ta;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 ts = totalSupply();
        if (ts == 0) return shares;
        return (shares * totalAssets()) / ts;
    }

    // ---------- User actions ----------

    function deposit(uint256 assets) external nonReentrant whenNotPaused returns (uint256 shares) {
        require(assets > 0, "assets=0");

        shares = convertToShares(assets);
        require(shares > 0, "shares=0");

        want.safeTransferFrom(msg.sender, address(this), assets);
        _mint(msg.sender, shares);

        _rebalanceToBuffer();

        emit Deposit(msg.sender, assets, shares);
    }

    function withdraw(uint256 assets) external nonReentrant whenNotPaused returns (uint256 shares) {
        require(assets > 0, "assets=0");

        shares = convertToShares(assets);
        // round up to protect vault solvency on dust rounding
        if (convertToAssets(shares) < assets) shares += 1;

        _burn(msg.sender, shares);

        _ensureLiquidity(assets);
        want.safeTransfer(msg.sender, assets);

        _rebalanceToBuffer();

        emit Withdraw(msg.sender, assets, shares);
    }

    function redeem(uint256 shares) external nonReentrant whenNotPaused returns (uint256 assets) {
        require(shares > 0, "shares=0");

        assets = convertToAssets(shares);

        _burn(msg.sender, shares);

        _ensureLiquidity(assets);
        want.safeTransfer(msg.sender, assets);

        _rebalanceToBuffer();

        emit Withdraw(msg.sender, assets, shares);
    }

    // ---------- Internal Venus plumbing ----------

    function _ensureLiquidity(uint256 needed) internal {
        uint256 idle = want.balanceOf(address(this));
        if (idle >= needed) return;

        uint256 shortfall = needed - idle;
        uint256 err = vUSDT.redeemUnderlying(shortfall);
        require(err == 0, "redeem failed");
    }

    function _rebalanceToBuffer() internal {
        uint256 ta = totalAssets();
        if (ta == 0) return;

        uint256 targetIdle = (ta * bufferBps) / BPS;
        uint256 idle = want.balanceOf(address(this));

        if (idle > targetIdle) {
            uint256 toInvest = idle - targetIdle;

            want.safeIncreaseAllowance(address(vUSDT), toInvest);
            uint256 err = vUSDT.mint(toInvest);
            require(err == 0, "mint failed");

            // optional hygiene
            want.safeApprove(address(vUSDT), 0);
        }
    }

    // ---------- Admin / Safety ----------

    function setBufferBps(uint256 newBps) external onlyOwner {
        require(newBps <= 2000, "too high"); // <= 20%
        bufferBps = newBps;
        emit BufferUpdated(newBps);
    }

    function pause() external {
        require(msg.sender == guardian || msg.sender == owner(), "not allowed");
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
