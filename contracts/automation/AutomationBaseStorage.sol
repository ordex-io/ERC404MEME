// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library AutomationBaseStorage {
    error NoAutomationRegister();

    struct Layout {
        address automationRegistry;
        uint96 minPending;
        uint256 maxWaiting;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("ordex.contracts.storage.automation");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function onlyAutoRegistry() internal view {
        // This prevent calls for others than the registry
        if (msg.sender != layout().automationRegistry) {
            revert NoAutomationRegister();
        }
    }
}
