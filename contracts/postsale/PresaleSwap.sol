pragma solidity ^0.4.24;

import '../zeppelin/contracts/ownership/Ownable.sol';
import '../zeppelin/contracts/lifecycle/Pausabe.sol';
import '../mainsale/pools/PresalePool.sol';

/*
 *  Fixer contract for the presale token swap
 *  @title PresaleSwap
 *  @dev Requires to transfer ownership of the PresalePool to this contract
 *  @dev Requires to make an EIP20 allowance of the SGN token from the TokenBucket
 */
contract PresaleSwap is Ownable, Pausable {
    PresalePool PPool = PresalePool(0x7F3a38fa282B16973feDD1E227210Ec020F2481e);
    SignalsToken SGN = SignalsToken(0xb2135ab9695a7678dd590b1a996cb0f37bcb0718);
    CrowdsaleRegister KYC = CrowdsaleRegister(0xd5D7D89a913F0AeB3B9a4a685a7c846e8220fc07);
    address public TokenBucket;

    mapping (address => uint256)addAllowance;
    bool cleanCalled = false;

    event Swapped(address beneficiary, bool success);
    event TokensGranted(address beneficiary, uint256 allowance);
    event TokenBucketChanged(address newBucket);

    /*
     * Constructor to set the TokenBucket
     */
    constructor(address bucket) {
        TokenBucket = bucket;
    }

    /*
     * Proxy function to swapFor
     */
    function() public {
        swapFor(msg.sender);
    }

    /*
     * Proxy function to swapFor
     */
    function swap() public {
        swapFor(msg.sender);
    }

    /*
     * Function to call the original swap contract which also assigns additional tokens
     * @param address beneficiary - the address to perform the swap and distribution for
     * @dev requires the contract to be unpaused (see Pausable.sol)
     */
    function swapFor(address beneficiary) whenNotPaused public {
        require(KYC.approved(beneficiary));
        bool success = PPool.swapFor(beneficiary);
        emit Swapped(beneficiary, success);

        uint256 allowance = addAllowance[beneficiary];

        if (allowance > 0) {
            addAllowance[beneficiary] = 0;
            SGN.transferFrom(TokenBucket, beneficiary, allowance); // TODO: change TO transferFrom
            emit TokensGranted(beneficiary, allowance);
        }
    }


    /*
     * Function to assign additional allowances distributed via swapFor function
     * @param address beneficiary is the address of the party which should be given additional allowance
     * @param uin256 allowance is the actual additional allowance to be assigned
     * @dev this can also change allowances to 0 or add some extra if the withdrawal was done already
     */
    function changeAllowance(address beneficiary, uint256 allowance) public onlyOwner {
        addAllowance[beneficiary] = allowance;
        emit AllowanceChanged(beneficiary, allowance);
    }

    /*
     * Function to assign additional allowances distributed via swapFor function over an array
     * @param address[] beneficiaries' list of addresses that should have additional allowance
     * @param uint256[] allowances of the beneficiaries from the array of first input
     * @dev this just calls the changeAllowance function in a for loop
     * @dev should be tested for max length of arrays
     */
    function massChangeAllowance(address[] beneficiaries, uint256[] allowances) onlyOwner {
        uint256 lenInput1 = beneficiaries.lenght;
        uint256 lenInput2 = beneficiaries.lenght;
        require(lenInput1 == lenInput2);

        for (uint256 i; i < lenInput1 ;i++) {
           changeAllowance(beneficiaries[i], allowances[i]);
        }
    }

    /*
     * Function to clean up the state and moved not allocated tokens to custody
     */
    function clean() onlyOwner public {

        // to ensure it's not called accidentally
        if (cleanCalled == false) {
            cleanCalled = true;
        }

        // on second call DO clean up
        if (cleanCalled == true) {
            PPool.clean();
            uint256 notAllocated = token.balanceOf(address(this));
            SGN.transfer(owner, notAllocated);
            selfdestruct(owner);
        }
    }

    /*
     * Function to change the owner of the original PresaleSwap contract
     * @param address newOwner - the new owner of the original PresalePool contract
     */
    function changeOwnerOfPPool(address newOwner) {
        PPool.transferOwnership(newOwner);
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