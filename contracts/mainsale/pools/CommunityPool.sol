pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../SignalsToken.sol';

/*
 * Pre-allocation pool for the community, will be govern by a company multisig
 * @title Community pool
 */
contract CommunityPool is Ownable{

    SignalsToken token;

    event CommunityTokensAllocated(address indexed member, uint amount);

    /*
     * Constructor changing owner to owner multisig
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function CommunityPool(address _token, address _owner) public{
        token = SignalsToken(_token);
        owner = _owner;
    }

    /*
     * Function to alloc tokens to a community member
     * @param address of community member
     * @param uint amount units of tokens to be given away
     */
    function allocToMember(address member, uint amount) public onlyOwner {
        require(amount > 0);
        token.transfer(member, amount);
        CommunityTokensAllocated(member, amount);
    }

    /*
     * Clean up function
     * @dev call to clean up the contract after all tokens were assigned
     */
    function clean() public onlyOwner {
        require(token.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}
