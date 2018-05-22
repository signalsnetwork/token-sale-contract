pragma solidity ^0.4.24;

import '../zeppelin/contracts/ownership/Ownable.sol';
import '../zeppelin/contracts/lifecycle/Pausabe.sol';
import '../mainsale/SignalsToken.sol';


contract Bounty is Ownable, Pausable {
    SignalsToken SGN = SignalsToken(0xb2135ab9695a7678dd590b1a996cb0f37bcb0718);
    address public TokenBucket = 0x0; //TODO: change

    mapping (string => bool) onlyOnce;

    event BountyPaid(address beneficiary, uint256 amount);
    event TokenBucketChanged(address newBucket);


    /*
     * Constructor assigning the TokenBucket
     */
    constructor(address bucket) {
        TokenBucket = bucket;
    }

    /*
     * Function to use to pay out the bounty directly to the bounty hunter
     * @param string uID - database assigned ID of the bounty hunter
     * @param address beneficiary - database stored address of the bounty hunter
     * @param uint256 amount - database stored amount to be paid out to the bounty hunter
     * @dev Relies on proper backend handling
     * @dev Requires SGN allowance at the TokenBucket for this contract
     */
    function payBounty(string uID, address beneficiary, uint256 amount) onlyOwner {
        require(!onlyOnce[uID]);

        SGN.transferFrom(TokenBucket, beneficiary, amount);
        emit BountyPaid(beneficiary, amount);

        onlyOnce[uID] = true;
    }

    /*
     * Proxy function to swapFor
     */
    function clean() onlyOwner {
        selfdestruct(owner);
    }

    /*
     * Function to change the TokenBucket - address with SGN allowance for this contract
     * @param address newBucket - new address which is expected to have an allowance for this contract
     */
    function changeTokenBucket(address newBucket) {
        TokenBucket = newBucket;
        emit TokenBucketChanged(newBucket);
    }
}