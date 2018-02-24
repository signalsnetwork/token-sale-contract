pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../SignalsToken.sol';

/*
 * Company reserve pool where the tokens will be locked for two years
 * @title Company token reserve
 */
contract TokenTimeLock is Ownable{

    SignalsToken token;
    uint timeLock;

    event TokensWithdrawn(address owner, uint amount);

    /*
     * Constructor changing owner to owner multisig & setting time lock
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function TokenTimeLock(address _token, address _owner, uint256 _time) public{
        token = SignalsToken(_token);
        owner = _owner;
        timeLock = now + _time;
    }

    /*
     * Only function for the tokens withdrawal (with two years time lock)
     * @param uint amount of tokens to be withdrawn
     */
    function withdraw() onlyOwner public {
        require(timeLock <= now);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(owner, amount);
        TokensWithdrawn(owner, amount);
        selfdestruct(owner);
    }
}
