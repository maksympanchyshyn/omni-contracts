// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@layerzerolabs/solidity-examples/contracts/token/onft721/ONFT721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @author Maksym Panchyshyn
 * @title OmniGraph
 */
contract OmniGraph is ONFT721, ERC721Enumerable {
  /************
   *   ERRORS  *
   ************/

  /**
   * @notice Contract error codes, used to specify the error
   * CODE LIST:
   * E1    "Invalid token URI lock state"
   * E2    "Mint exceeds the limit"
   * E3    "Invalid mint fee"
   * E4    "Invalid token ID"
   * E5    "Invalid fee collector address"
   * E6    "Invalid earned fee amount: nothing to claim"
   * E7    "Caller is not a fee collector"
   */
  uint8 public constant ERROR_INVALID_URI_LOCK_STATE = 1;
  uint8 public constant ERROR_MINT_EXCEEDS_LIMIT = 2;
  uint8 public constant ERROR_MINT_INVALID_FEE = 3;
  uint8 public constant ERROR_INVALID_TOKEN_ID = 4;
  uint8 public constant ERROR_INVALID_COLLECTOR_ADDRESS = 5;
  uint8 public constant ERROR_NOTHING_TO_CLAIM = 6;
  uint8 public constant ERROR_NOT_FEE_COLLECTOR = 7;

  /**
   * @notice Basic error, thrown every time something goes wrong according to the contract logic.
   * @dev The error code indicates more details.
   */
  error OmniGraph_CoreError(uint256 errorCode);

  /************
   *   EVENTS  *
   ************/

  /**
   * State change
   */
  event MintFeeChanged(uint256 indexed oldMintFee, uint256 indexed newMintFee);
  event BridgeFeeChanged(uint256 indexed oldBridgeFee, uint256 indexed newBridgeFee);
  event FeeCollectorChanged(address indexed oldFeeCollector, address indexed newFeeCollector);
  event TokenURIChanged(string indexed oldTokenURI, string indexed newTokenURI);
  event TokenURILocked(bool indexed newState);

  /**
   * Mint / bridge / claim
   */
  event ONFTMinted(address indexed minter, uint256 indexed itemId, uint256 feeEarnings);
  event BridgeFeeEarned(address indexed from, uint16 indexed dstChainId, uint256 amount);
  event FeeEarningsClaimed(address indexed collector, uint256 claimedAmount);

  /***********************
   *   VARIABLES / STATES *
   ***********************/

  /// TOKEN ID ///
  uint256 public immutable startMintId;
  uint256 public immutable maxMintId;

  uint256 public tokenCounter;

  /// FEE ///
  uint256 public mintFee;
  uint256 public bridgeFee;
  address public feeCollector;

  uint256 public feeEarnedAmount;
  uint256 public feeClaimedAmount;

  /// TOKEN URI ///
  string private _tokenBaseURI;
  bool public tokenBaseURILocked;

  /***************
   *   MODIFIERS  *
   ***************/

  /**
   * @dev Protects functions available only to the fee collector, e.g. fee claiming
   */
  modifier onlyFeeCollector() {
    _checkFeeCollector();
    _;
  }

  /*****************
   *   CONSTRUCTOR  *
   *****************/

  /**
   * @param _minGasToTransfer min amount of gas required to transfer, and also store the payload. See {ONFT721Core}
   * @param _lzEndpoint LayerZero endpoint address
   * @param _startMintId min token ID that can be mined
   * @param _endMintId max token ID that can be mined
   */
  constructor(
    uint256 _minGasToTransfer,
    address _lzEndpoint,
    uint256 _startMintId,
    uint256 _endMintId
  ) ONFT721('OmniGraph', 'OG', _minGasToTransfer, _lzEndpoint) {
    require(_startMintId < _endMintId, 'Invalid mint range');
    require(_endMintId < type(uint256).max, 'Incorrect max mint ID');

    startMintId = _startMintId;
    maxMintId = _endMintId;
    tokenCounter = _startMintId;
    feeCollector = _msgSender();
    mintFee = 0;
    bridgeFee = 0;
  }

  /***********************
   *   SETTERS / GETTERS  *
   ***********************/

  /**
   * @notice ADMIN Change minting fee
   * @param _mintFee new minting fee
   *
   * @dev emits {OmniGraph-MintFeeChanged}
   */
  function setMintFee(uint256 _mintFee) external onlyOwner {
    uint256 oldMintFee = mintFee;
    mintFee = _mintFee;
    emit MintFeeChanged(oldMintFee, _mintFee);
  }

  /**
   * @notice ADMIN Change bridge fee
   * @param _bridgeFee new bridge fee
   *
   * @dev emits {OmniGraph-BridgeFeeChanged}
   */
  function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
    uint256 oldBridgeFee = bridgeFee;
    bridgeFee = _bridgeFee;
    emit BridgeFeeChanged(oldBridgeFee, _bridgeFee);
  }

  /**
   * @notice ADMIN Change fee collector address
   * @param _feeCollector new address for the collector
   *
   * @dev emits {OmniGraph-FeeCollectorChanged}
   */
  function setFeeCollector(address _feeCollector) external onlyOwner {
    _validate(_feeCollector != address(0), ERROR_INVALID_COLLECTOR_ADDRESS);
    address oldFeeCollector = feeCollector;
    feeCollector = _feeCollector;
    emit FeeCollectorChanged(oldFeeCollector, _feeCollector);
  }

  /**
   * @notice ADMIN Change base URI
   * @param _newTokenBaseURI new URI
   *
   * @dev emits {OmniGraph-TokenURIChanged}
   */
  function setTokenBaseURI(string calldata _newTokenBaseURI) external onlyOwner {
    _validate(!tokenBaseURILocked, ERROR_INVALID_URI_LOCK_STATE);
    string memory oldTokenBaseURI = _tokenBaseURI;
    _tokenBaseURI = _newTokenBaseURI;
    emit TokenURIChanged(oldTokenBaseURI, _newTokenBaseURI);
  }

  /**
   * @notice ADMIN Lock / unlock base URI
   * @param locked lock token URI if true, unlock otherwise
   *
   * @dev emits {OmniGraph-TokenURILocked}
   */
  function setTokenBaseURILocked(bool locked) external onlyOwner {
    _validate(tokenBaseURILocked != locked, ERROR_INVALID_URI_LOCK_STATE);
    tokenBaseURILocked = locked;
    emit TokenURILocked(locked);
  }

  /**
   * @notice Retrieving token URI by its ID (for this contract all IDs have same URI)
   * @param tokenId identifier of the token
   *
   * @dev emits {OmniGraph-TokenURILocked}
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _validate(_exists(tokenId), ERROR_INVALID_TOKEN_ID);
    return string(abi.encodePacked(_tokenBaseURI));
  }

  /************
   *   MINT    *
   ************/

  /**
   * @notice Mint new OmniGraph ONFT
   *
   * @dev new token ID must be in range [startMintId - maxMintId]
   * @dev tx value must be equal to mintFee. See {OmniGraph-mintFee}
   * @dev emits {OmniGraph-ONFTMinted}
   */
  function mint() external payable nonReentrant {
    uint256 newItemId = tokenCounter;
    uint256 feeEarnings = mintFee;

    _validate(newItemId < maxMintId, ERROR_MINT_EXCEEDS_LIMIT);
    _validate(msg.value >= feeEarnings, ERROR_MINT_INVALID_FEE);

    ++tokenCounter;

    feeEarnedAmount += feeEarnings;

    _safeMint(_msgSender(), newItemId);
    emit ONFTMinted(_msgSender(), newItemId, feeEarnings);
  }

  /**************
   *   BRIDGE    *
   **************/

  /**
   * @notice Estimate fee to send token to another chain
   * @param _dstChainId destination LayerZero chain ID
   * @param _toAddress address on destination
   * @param _tokenId token to be sent
   * @param _useZro flag to use ZRO as fee
   * @param _adapterParams relayer adapter parameters
   *
   * @dev See {ONFT721Core-estimateSendFee}
   * @dev Overridden to add bridgeFee to native fee
   */
  function estimateSendFee(
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint _tokenId,
    bool _useZro,
    bytes memory _adapterParams
  ) public view virtual override(ONFT721Core, IONFT721Core) returns (uint nativeFee, uint zroFee) {
    return
      this.estimateSendBatchFee(
        _dstChainId,
        _toAddress,
        _toSingletonArray(_tokenId),
        _useZro,
        _adapterParams
      );
  }

  /**
   * @notice Estimate fee to send batch of tokens to another chain
   * @param _dstChainId destination LayerZero chain ID
   * @param _toAddress address on destination
   * @param _tokenIds tokens to be sent
   * @param _useZro flag to use ZRO as fee
   * @param _adapterParams relayer adapter parameters
   *
   * @dev See {ONFT721Core-estimateSendBatchFee}
   * @dev Overridden to add bridgeFee to native fee
   */
  function estimateSendBatchFee(
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint[] memory _tokenIds,
    bool _useZro,
    bytes memory _adapterParams
  ) public view override(ONFT721Core, IONFT721Core) returns (uint256 nativeFee, uint256 zroFee) {
    (nativeFee, zroFee) = super.estimateSendBatchFee(
      _dstChainId,
      _toAddress,
      _tokenIds,
      _useZro,
      _adapterParams
    );
    nativeFee += bridgeFee;
    return (nativeFee, zroFee);
  }

  /**
   * @notice Send token to another chain
   * @param _from sender address, token owner or approved address
   * @param _dstChainId destination LayerZero chain ID
   * @param _toAddress address on destination
   * @param _tokenId token to be sent
   * @param _refundAddress address that would receive remaining funds
   * @param _zroPaymentAddress address that would pay fees in zro
   * @param _adapterParams relayer adapter parameters
   *
   * @dev See {ONFT721Core-sendFrom}
   * @dev Overridden to collect bridgeFee
   */
  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) public payable override(ONFT721Core, IONFT721Core) {
    _handleSend(
      _from,
      _dstChainId,
      _toAddress,
      _toSingletonArray(_tokenId),
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  /**
   * @notice Send token to another chain
   * @param _from sender address, token owner or approved address
   * @param _dstChainId destination LayerZero chain ID
   * @param _toAddress address on destination
   * @param _tokenIds tokens to be sent
   * @param _refundAddress address that would receive remaining funds
   * @param _zroPaymentAddress address that would pay fees in zro
   * @param _adapterParams relayer adapter parameters
   *
   * @dev See {ONFT721Core-sendBatchFrom}
   * @dev Overridden to collect bridgeFee
   */
  function sendBatchFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint[] memory _tokenIds,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) public payable virtual override(ONFT721Core, IONFT721Core) {
    _handleSend(
      _from,
      _dstChainId,
      _toAddress,
      _tokenIds,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  /**
   * @notice Internal function to handle send to another chain
   * @param _from sender address, token owner or approved address
   * @param _dstChainId destination LayerZero chain ID
   * @param _toAddress address on destination
   * @param _tokenIds tokens to be sent
   * @param _refundAddress address that would receive remaining funds
   * @param _zroPaymentAddress address that would pay fees in zro
   * @param _adapterParams relayer adapter parameters
   *
   * @dev emits {OmniGraph-BridgeFeeEarned}
   */
  function _handleSend(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint[] memory _tokenIds,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) private {
    uint256 _bridgeFee = bridgeFee;
    uint256 _nativeFee = msg.value - _bridgeFee;

    feeEarnedAmount += _bridgeFee;

    _send(
      _from,
      _dstChainId,
      _toAddress,
      _tokenIds,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams,
      _nativeFee
    );

    emit BridgeFeeEarned(_from, _dstChainId, _bridgeFee);
  }

  /**
   * @notice Internal function to handle send to another chain
   * @param _from sender address, token owner or approved address
   * @param _dstChainId destination LayerZero chain ID
   * @param _toAddress address on destination
   * @param _tokenIds tokens to be sent
   * @param _refundAddress address that would receive remaining funds
   * @param _zroPaymentAddress address that would pay fees in zro
   * @param _adapterParams relayer adapter parameters
   * @param _nativeFee fee amount to be sent to LayerZero (without bridgeFee)
   *
   * @dev Mimics the behavior of {ONFT721Core}
   * @dev emits {IONFT721Core-SendToChain}
   */
  function _send(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint[] memory _tokenIds,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams,
    uint256 _nativeFee
  ) internal virtual {
    // allow 1 by default
    require(_tokenIds.length > 0, 'tokenIds[] is empty');
    require(
      _tokenIds.length == 1 || _tokenIds.length <= dstChainIdToBatchLimit[_dstChainId],
      'batch size exceeds dst batch limit'
    );

    for (uint i = 0; i < _tokenIds.length; i++) {
      _debitFrom(_from, _dstChainId, _toAddress, _tokenIds[i]);
    }

    bytes memory payload = abi.encode(_toAddress, _tokenIds);

    _checkGasLimit(
      _dstChainId,
      FUNCTION_TYPE_SEND,
      _adapterParams,
      dstChainIdToTransferGas[_dstChainId] * _tokenIds.length
    );
    _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, _nativeFee);
    emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds);
  }

  /*************
   *   CLAIM    *
   *************/

  /**
   * @notice FEE_COLLECTOR Claim earned fee (mint + bridge)
   *
   * @dev earned amount must be more than zero to claim
   * @dev emits {OmniGraph-FeeEarningsClaimed}
   */
  function claimFeeEarnings() external onlyFeeCollector nonReentrant {
    uint256 _feeEarnedAmount = feeEarnedAmount;
    _validate(_feeEarnedAmount != 0, ERROR_NOTHING_TO_CLAIM);

    uint256 currentEarnings = _feeEarnedAmount;
    feeEarnedAmount = 0;
    feeClaimedAmount += currentEarnings;

    address _feeCollector = feeCollector;
    (bool success, ) = payable(_feeCollector).call{value: currentEarnings}('');
    require(success, 'Failed to send Ether');
    emit FeeEarningsClaimed(_feeCollector, currentEarnings);
  }

  /*****************
   *   OVERRIDES    *
   *****************/

  /**
   * @dev See {ERC721-_beforeTokenTransfer}
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
  }

  /**
   * @dev See {ERC721-supportsInterface}
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721Enumerable, ONFT721) returns (bool) {
    return interfaceId == type(IONFT721).interfaceId || super.supportsInterface(interfaceId);
  }

  /***************
   *   HELPERS    *
   ***************/

  /**
   * @notice Checks if address is current fee collector
   */
  function _checkFeeCollector() internal view {
    _validate(feeCollector == _msgSender(), ERROR_NOT_FEE_COLLECTOR);
  }

  /**
   * @notice Checks if the condition is met and reverts with an error if not
   * @param _clause condition to be checked
   * @param _errorCode code that will be passed in the error
   */
  function _validate(bool _clause, uint8 _errorCode) internal pure {
    if (!_clause) revert OmniGraph_CoreError(_errorCode);
  }
}
