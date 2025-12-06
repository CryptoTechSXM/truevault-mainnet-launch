// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TrueVaultTimelock is TimelockController {
    constructor(uint256 d, address[] memory p, address[] memory e, address a)
        TimelockController(d,p,e,a) {}
}
