pragma solidity ^0.4.20;

import '../zeppelin/contracts/ownership/Ownable.sol';

contract PrivateRegister is Ownable {

    struct contribution {
        bool approved;
        uint8 extra;
    }

    mapping (address => contribution) verified;

    event ApprovedInvestor(address indexed investor);
    event BonusesRegistered(address indexed investor, uint8 extra);

    /*
     * Approve function to adjust allowance to investment of each individual investor
     * @param _investor address sets the beneficiary for later use
     * @param _referral address to pay a commission in token to
     * @param _commission uint8 expressed as a number between 0 and 5
    */
    function approve(address _investor, uint8 _extra) onlyOwner public{
        require(!isContract(_investor));
        verified[_investor].approved = true;
        if (_extra <= 100) {
            verified[_investor].extra = _extra;
            BonusesRegistered(_investor, _extra);
        }
        ApprovedInvestor(_investor);
    }

    /*
     * Constant call to find out if an investor is registered
     * @param _investor address to be checked
     * @return bool is true is _investor was approved
     */
    function approved(address _investor) view public returns (bool) {
        return verified[_investor].approved;
    }

    /*
     * Constant call to find out the referral and commission to bound to an investor
     * @param _investor address to be checked
     * @return address of the referral, returns 0x0 if there is none
     * @return uint8 commission to be paid out on any investment
     */
    function getBonuses(address _investor) view public returns (uint8 extra) {
        return verified[_investor].extra;
    }

    /*
     * Check if address is a contract to prevent contracts from participating the direct sale.
     * @param addr address to be checked
     * @return boolean of it is or isn't an contract address
     * @credits Manuel Aráoz
     */
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}