// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";

contract CauldronFactory {
  address public immutable MASTER_CONTRACT;

  event CauldronCloned(address indexed clone);

  constructor(address _masterContract) {
    MASTER_CONTRACT = _masterContract;
  }

  function createCauldron(bytes calldata data) external returns (address) {
    address clone = Clones.clone(MASTER_CONTRACT);
    CauldronV4(clone).init(data);
    emit CauldronCloned(clone);
    return clone;
  }
}
