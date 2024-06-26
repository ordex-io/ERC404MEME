// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {AutomationBaseStorage} from "./AutomationBaseStorage.sol";
import {IAutomationBase} from "./IAutomationBase.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {DNAStorage} from "../dna/DNAStorage.sol";

abstract contract AutomationBase is
    IAutomationBase,
    SafeOwnable,
    AutomationCompatible
{
    /// @notice This modifier prevent calls for others than the caller registered.
    /// Necessary to protect performUpkeep from untrusted callers
    modifier onlyUpKeepCaller() {
        // This prevent calls for others than the caller registered
        if (msg.sender != AutomationBaseStorage.layout().upKeepCaller) {
            revert NoAutomationRegister();
        }
        _;
    }

    /// @param caller_ The address that will be performing the automation calls
    /// @param minPending_ The minimum of NFT waiting to be revealed
    /// @param minWait_ The minimum time to wait before reveal
    /// @param maxWait_ The maximum time to wait before ask for reveal
    /// @dev If minPending_ is defined with zero, the contract will interprete this
    /// as need only one on pending list. This is just for safety and avoid calling
    /// always event when there is no need to do.
    function __AutomationBase_Init(
        address caller_,
        uint96 minPending_,
        uint128 minWait_,
        uint128 maxWait_
    ) internal {
        if (maxWait_ != 0 && maxWait_ < minWait_) {
            revert TimeMismatch();
        }
        AutomationBaseStorage.layout().upKeepCaller = caller_;
        AutomationBaseStorage.layout().minPending = minPending_;
        AutomationBaseStorage.layout().minWait = minWait_;
        AutomationBaseStorage.layout().maxWait = maxWait_;
        AutomationBaseStorage.layout().lastCall = uint128(block.timestamp);
    }

    function checkUpkeep(
        bytes calldata
    ) external view cannotExecute returns (bool upkeepNeeded, bytes memory) {
        AutomationBaseStorage.Layout memory l = AutomationBaseStorage.layout();

        // Execute if max wait is reached OR minPending and minWait were not defined
        if (
            (l.maxWait != 0 && block.timestamp >= l.lastCall + l.maxWait) ||
            (l.minPending == 0 && l.minWait == 0)
        ) {
            // So means that need atleast one NFT on pending list to perform
            upkeepNeeded = DNAStorage.pendingReveals() != 0;
        }
        // Both values were defined
        else if (l.minPending != 0 && l.minWait != 0) {
            // Both values need to be met to perfomUpkeep and need atleast one NFT
            // on pending list to perform
            upkeepNeeded = upkeepNeeded =
                DNAStorage.pendingReveals() != 0 &&
                DNAStorage.pendingReveals() >= l.minPending &&
                block.timestamp >= l.lastCall + l.minWait;
        }
        // Only min pending is defined
        else if (l.minPending != 0) {
            // Only need the mimium amout of NFT on pending list to perfomUpkeep
            upkeepNeeded = DNAStorage.pendingReveals() >= l.minPending;
        }
        // Only min wait time is defined
        else if (l.minWait != 0) {
            // Only need to reach the minimum time to perfomUpkeep and need atleast
            // one NFT on pending list to perform
            upkeepNeeded =
                DNAStorage.pendingReveals() != 0 &&
                block.timestamp >= l.lastCall + l.minWait;
        }

        return (upkeepNeeded, bytes(""));
    }

    /// @param newCaller_ The new address that will be performing the automation calls. Using chainlink, can be forwarder.
    function setCallerAddress(address newCaller_) public onlyOwner {
        AutomationBaseStorage.layout().upKeepCaller = newCaller_;
    }

    /// @return The address that can make the automation calls
    function getCallerAddress() public view returns (address) {
        return AutomationBaseStorage.layout().upKeepCaller;
    }
}
