pragma solidity ^0.4.24;

import '../zeppelin/contracts/ownership/Ownable.sol';
import '../mainsale/pools/PresalePool.sol';


/*
 *  Fixer contract for the presale token swap
 *  @title PresaleSwap
 *  @dev Requires to transfer ownership of the PresalePool to this contract
 */
contract PresaleSwap is Ownable {
    PresalePool PPool = PresalePool(0x7F3a38fa282B16973feDD1E227210Ec020F2481e);
    SignalsToken SGN = SignalsToken(0xb2135ab9695a7678dd590b1a996cb0f37bcb0718);
    CrowdsaleRegister KYC = CrowdsaleRegister(0xd5D7D89a913F0AeB3B9a4a685a7c846e8220fc07);

    mapping (address => uint256)addAllowance;
    bool cleanCalled = false;

    event Swapped(address beneficiary, bool success);
    event TokensGranted(address beneficiary, uint256 allowance);

    constructor() {
    }

    function() public {
        swapFor(msg.sender);
    }

    function swap() public {
        swapFor(msg.sender);
    }

    function swapFor(address beneficiary) public {
        require(KYC.approved(beneficiary));
        bool success = PPool.swapFor(beneficiary);
        emit Swapped(beneficiary, success);

        uint256 allowance = addAllowance[beneficiary];

        if (allowance > 0) {
            addAllowance[beneficiary] = 0;
            SGN.transfer(beneficiary, allowance);
            emit TokensGrated(beneficiary, allowance);
        }
    }


    function changeAllowance(address beneficiary, uint256 allowance) public onlyOwner {
        addAllowance[beneficiary] = allowance;
        emit AllowanceChanged(beneficiary, allowance);
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
}