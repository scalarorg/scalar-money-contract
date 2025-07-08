// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Owned } from "@solmate/auth/Owned.sol";
import { IOracle } from "@abracadabra/interfaces/IOracle.sol";
import { AggregatorV3Interface } from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";

contract ChainLinkOracleAdaptor is IOracle, Owned {
    AggregatorV3Interface public immutable aggregator;
    uint8 public immutable overrideDecimals;
    string private name_;
    string private symbol_;

    constructor(
        address _aggregator,
        uint8 _overrideDecimals,
        string memory _name,
        string memory _symbol
    )
        Owned(msg.sender)
    {
        aggregator = AggregatorV3Interface(_aggregator);
        overrideDecimals = _overrideDecimals;
        name_ = _name;
        symbol_ = _symbol;
    }

    /// @notice Returns the number of decimals expected by consumers (e.g., 18)
    function decimals() external view override returns (uint8) {
        return overrideDecimals;
    }

    /// @notice Reads and returns the latest price, modifying no state
    function peek(bytes calldata) external view override returns (bool, uint256) {
        return _read();
    }

    /// @notice Reads and returns the latest price, modifying no state
    function peekSpot(bytes calldata) external view override returns (uint256 rate) {
        (, rate) = _read();
    }

    /// @notice Reads and returns the latest price (no-op state write)
    function get(bytes calldata) external view override returns (bool, uint256) {
        return _read();
    }

    function _read() internal view returns (bool, uint256) {
        (, int256 answer,,,) = aggregator.latestRoundData();
        if (answer <= 0) return (false, 0);

        uint256 price = uint256(answer);
        uint8 feedDecimals = aggregator.decimals();

        // we not need read the real price, need to read 1 USD = ? fee price

        // Scale price to match overrideDecimals (commonly 18)
        if (feedDecimals < overrideDecimals) {
            price *= 10 ** (overrideDecimals - feedDecimals);
        } else if (feedDecimals > overrideDecimals) {
            price /= 10 ** (feedDecimals - overrideDecimals);
        }

        price = 10 ** (overrideDecimals + overrideDecimals) / price;

        return (true, price);
    }

    function name(bytes calldata) external view override returns (string memory) {
        return name_;
    }

    function symbol(bytes calldata) external view override returns (string memory) {
        return symbol_;
    }
}
