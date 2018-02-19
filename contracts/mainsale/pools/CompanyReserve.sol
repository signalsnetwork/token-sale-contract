pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../SignalsToken.sol';

/*
 * Company reserve pool where the tokens will be locked for two years
 * @title Company token reserve
 */
contract CompanyReserve is Ownable{

    SignalsToken token;
    uint timeLock;

    event ReserveWithdrawn(address Owner, uint amount);

    /*
     * Constructor changing owner to owner multisig & setting time lock
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function CompanyReserve(address _token, address _owner) public{
        token = SignalsToken(_token);
        owner = _owner;
        timeLock = now + 730 days;
    }

    /*
     * Only function for the tokens withdrawal (with two years time lock)
     * @param uint amount of tokens to be withdrawn
     */
    function withdrawReserve(uint amount) onlyOwner {
        require(now >= timeLock);
        token.transfer(owner, amount);
    }
}
