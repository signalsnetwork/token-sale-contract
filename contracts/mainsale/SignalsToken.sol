pragma solidity ^0.4.0;

import '../zeppelin/contracts/token/MintableToken.sol';
import '../zeppelin/contracts/token/PausableToken.sol';

/**
 * @title Signals token
 * @dev Mintable token created for Signals.Network
 */
contract SignalsToken is PausableToken, MintableToken {

    // Standard token variables
    string constant public name = "Signals Network Token";
    string constant public symbol = "SGN";
    uint8 constant public decimals = 9;

}
