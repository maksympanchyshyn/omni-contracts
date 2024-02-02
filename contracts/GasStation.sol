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
    uint16 _dstChainId,
    bytes memory _payload,
    bytes memory _adapterParams
  ) public view virtual returns (uint nativeFee, uint zroFee) {
    return lzEndpoint.estimateFees(_dstChainId, address(this), _payload, false, _adapterParams);
  }

  function refuelGas(
    uint16 _dstChainId,
    bytes memory _payload,
    bytes memory _adapterParams
  ) public payable virtual {
    _checkGasLimit(_dstChainId, 0, _adapterParams, 0);
    (uint nativeFee, ) = estimateSendFee(_dstChainId, _payload, _adapterParams);
    require(msg.value >= nativeFee, 'Not enough gas to send');

    _lzSend(_dstChainId, _payload, payable(msg.sender), address(0x0), _adapterParams, nativeFee);
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
