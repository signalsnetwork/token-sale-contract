pragma solidity ^0.4.24;

import '../zeppelin/contracts/ownership/Ownable.sol';
import '../mainsale/pools/PresalePool.sol';


/*
 *  Fixer contract for the presale token swap
 *  @title PresaleSwap
 *  @dev Requires to transfer ownership of the PresalePool to this contract
 */
contract PresaleSwap is Ownable {
    PresalePool PPool = PresalePool(0x0);
    SignalsToken SGN = SignalsToken(0x0);
    CrowdsaleRegister KYC = CrowdsaleRegister(0x0);

    mapping (address => uint256)addAllowance;

    event Swapped(address beneficiary, bool success);
    event TokensGrated(address beneficiary, uint256 allowance);

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

    function changeAllowance(address beneficiary, uint256 allowance) onlyOwner {
        addAllowance[beneficiary] = allowance;
        emit AllowanceChanged(beneficiary, allowance);
    }

    /*
     * Function to clean up the state and moved not allocated tokens to custody
     */
    function clean() onlyOwner public {
        PPool.clean();
        uint256 notAllocated = token.balanceOf(address(this));
        SGN.transfer(owner, notAllocated);
        selfdestruct(owner);
    }
}