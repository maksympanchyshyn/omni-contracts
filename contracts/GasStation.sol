// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol';

/**
 * @author Maksym Panchyshyn
 * @title GasStation
 */
contract GasStation is NonblockingLzApp {
  using BytesLib for bytes;

  constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

  function estimateSendFee(
    uint16 dstChainId,
    bytes memory payload,
    bytes memory adapterParams
  ) public view virtual returns (uint nativeFee, uint zroFee) {
    return lzEndpoint.estimateFees(dstChainId, address(this), payload, false, adapterParams);
  }

  function refuelGas(
    uint16 dstChainId,
    bytes memory payload,
    bytes memory adapterParams
  ) public payable virtual {
    _checkGasLimit(dstChainId, 0, adapterParams, 0);
    (uint nativeFee, ) = estimateSendFee(dstChainId, payload, adapterParams);
    require(msg.value >= nativeFee, 'Not enough gas to send');

    _lzSend(dstChainId, payload, payable(msg.sender), address(0x0), adapterParams, nativeFee);
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(success);
  }

  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual override {}
}
