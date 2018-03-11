pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../SignalsToken.sol';

/*
 * Company reserve pool where the tokens will be locked for two years
 * @title Company token reserve
 */
contract AdviserTimeLock is Ownable{

    SignalsToken token;
    uint256 withdrawn;
    uint start;

    event TokensWithdrawn(address owner, uint amount);

    /*
     * Constructor changing owner to owner multisig & setting time lock
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function AdviserTimeLock(address _token, address _owner) public{
        token = SignalsToken(_token);
        owner = _owner;
        start = now;
        // Initial token allocation;
        token.transfer(owner, 1850000000000000000000000); // Initial allowance
        TokenWithdrawn(owner, 1850000000000000000000000);
    }

    /*
     * Only function for periodical tokens withdrawal (with monthly allowance)
     * @dev Will withdraw the whole allowance;
     */
    function withdraw() onlyOwner public {
        require(now - start >= 25920000);
        uint toWithdraw = canWithdraw();
        token.transfer(owner, toWithdraw);
        withdrawn += toWithdraw;
        TokensWithdrawn(owner, toWithdraw);
    }

    /*
     * Only function for the tokens withdrawal (with two years time lock)
     * @dev Based on division down rounding
     */
    function canWithdraw() public returns (uint256) {
        uint256 sinceStart = now - start;
        uint256 allowed = (sinceStart/2592000)*504546000000000000000000;
        uint256 toWithdraw;
        if (allowed > token.balanceOf(this(address))) {
            toWithdraw = token.balanceOf(this(address));
        } else {
            toWithdraw = allowed - withdrawn;
        }
        return toWithdraw;
    }

    /*
     * Function to clean up the state and moved not allocated tokens to custody
     */
    function cleanUp() onlyOwner public {
        require(token.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}
