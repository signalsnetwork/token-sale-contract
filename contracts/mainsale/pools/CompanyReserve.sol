pragma solidity ^0.4.20;

import './TokenTimeLock.sol';

/*
 * Company reserve pool where the tokens will be locked for two years
 * @title Company token reserve
 */
contract CompanyReserve is TokenTimeLock{

    /*
     * Constructor changing owner to owner multisig & setting time lock
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function CompanyReserve(address _token, address _owner)
    TokenTimeLock(_token, _owner, 63072000)
    public {}
}
