// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";

contract CauldronFactory {
    address public immutable MASTER_CONTRACT;

    event CauldronCloned(address indexed clone, address indexed creator);

    error ErrZeroAddress();
    error ErrCloneCreationFailed();
    error ErrInitializationFailed();

    constructor(address _masterContract) {
        if (_masterContract == address(0)) {
            revert ErrZeroAddress();
        }
        MASTER_CONTRACT = _masterContract;
    }

    /// @notice Creates a new cauldron clone
    /// @param data Initialization data for the cauldron
    /// @return The address of the newly created clone
    function createCauldron(bytes calldata data) external returns (address) {
        // Create the clone
        address clone = Clones.clone(MASTER_CONTRACT);
        if (clone == address(0)) {
            revert ErrCloneCreationFailed();
        }

        // Initialize the clone
        try CauldronV4(clone).init(data) {
            emit CauldronCloned(clone, msg.sender);
            return clone;
        } catch {
            revert ErrInitializationFailed();
        }
    }

    /// @notice Creates multiple cauldron clones in a single transaction
    /// @param dataArray Array of initialization data for each cauldron
    /// @return Array of clone addresses
    function createMultipleCauldrons(bytes[] calldata dataArray) external returns (address[] memory) {
        address[] memory clones = new address[](dataArray.length);

        for (uint256 i = 0; i < dataArray.length; i++) {
            address clone = Clones.clone(MASTER_CONTRACT);
            if (clone == address(0)) {
                revert ErrCloneCreationFailed();
            }

            try CauldronV4(clone).init(dataArray[i]) {
                clones[i] = clone;
                emit CauldronCloned(clone, msg.sender);
            } catch {
                revert ErrInitializationFailed();
            }
        }

        return clones;
    }

    /// @notice Predicts the address of a clone before creation
    /// @param salt Unique salt for deterministic address
    /// @return The predicted clone address
    function predictCloneAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(MASTER_CONTRACT, salt);
    }

    /// @notice Creates a clone with a deterministic address
    /// @param salt Unique salt for deterministic address
    /// @param data Initialization data for the cauldron
    /// @return The address of the newly created clone
    function createDeterministicCauldron(bytes32 salt, bytes calldata data) external returns (address) {
        address clone = Clones.cloneDeterministic(MASTER_CONTRACT, salt);
        if (clone == address(0)) {
            revert ErrCloneCreationFailed();
        }

        try CauldronV4(clone).init(data) {
            emit CauldronCloned(clone, msg.sender);
            return clone;
        } catch {
            revert ErrInitializationFailed();
        }
    }
}
