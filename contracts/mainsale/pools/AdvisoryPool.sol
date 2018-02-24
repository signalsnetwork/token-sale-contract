pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../SignalsToken.sol';
import './TokenTimeLock.sol';

/*
 * Pre-allocation pool for company advisers
 * @title Advisory pool
 */
contract AdvisoryPool is Ownable{

    SignalsToken token;

    /*
     * @dev constant addresses of all advisers
     */
    address ADVISER1 = address(this);
    address ADVISER2 = address(this);
    address ADVISER3 = address(this);
    address ADVISER4 = address(this);
    address ADVISER5 = address(this);
    address ADVISER6 = address(this);
    address ADVISER7 = address(this);
    
    TokenTimeLock public tokenLocker7; 

    /*
     * Constructor changing owner to owner multisig & calling the allocation
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function AdvisoryPool(address _token, address _owner) public {
        owner = _owner;
        token = SignalsToken(_token);
    }

    /*
     * Allocation function, tokens get allocated from this contract as current token owner
     * @dev only accessible from the constructor
     */
    function initiate() public onlyOwner {
        require(token.balanceOf(address(this)) == 7500000*(10**18));
        
        tokenLocker7 = new TokenTimeLock(address(token), ADVISER7, 31536000);

        token.transfer(ADVISER1, 1500000*(10**18));
        token.transfer(ADVISER2, 1000000*(10**18));
        token.transfer(ADVISER3, 1000000*(10**18));
        token.transfer(ADVISER4, 1000000*(10**18));
        token.transfer(ADVISER5, 1000000*(10**18));
        token.transfer(ADVISER6, 1000000*(10**18));
        token.transfer(address(tokenLocker7), 1000000*(10**18));
    }

    /*
     * Clean up function for token loss prevention and cleaning up Ethereum blockchain
     * @dev call to clean up the contract
     */
    function cleanUp() onlyOwner public {
        uint256 notAllocated = token.balanceOf(address(this));
        token.transfer(owner, notAllocated);
        selfdestruct(owner);
    }
}
