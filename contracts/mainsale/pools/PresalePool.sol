pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../PresaleToken.sol';
import '../SignalsToken.sol';
import '../KYC.sol';


/*
 *  Token pool for the presale tokens swap
 *  @title PresalePool
 *  @dev Requires to transfer ownership of both PresaleToken contracts to this contract
 */
contract PresalePool is Ownable {

    PresaleToken public PublicPresale;
    PresaleToken public PartnerPresale;
    SignalsToken token;
    CrowdsaleRegister registry;

    /*
     * Compensation coefficient based on the difference between the max ETHUSD price during the presale
     * and price fix for mainsale
     */
    uint256 compensation1;
    uint256 compensation2;
    // Date after which all tokens left will be transfered to the company reserve
    uint256 deadLine;

    event SupporterResolved(address indexed supporter, uint256 burned, uint256 created);
    event PartnerResolved(address indexed partner, uint256 burned, uint256 created);

    /*
     * Constructor changing owner to owner multisig, setting all the contract addresses & compensation rates
     * @param address of the Signals Token contract
     * @param address of the KYC registry
     * @param address of the owner multisig
     * @param uint rate of the compensation for early investors
     * @param uint rate of the compensation for partners
     */
    function PresalePool(address _token, address _registry, address _owner, uint comp1, uint comp2) public {
        owner = _owner;
        PublicPresale = PresaleToken(0x15fEcCA27add3D28C55ff5b01644ae46edF15821); 
        PartnerPresale = PresaleToken(0xa70435D1a3AD4149B0C13371E537a22002Ae530d);
        token = SignalsToken(_token);
        registry = CrowdsaleRegister(_registry);
        compensation1 = comp1;
        compensation2 = comp2;
        deadLine = now + 30 days;
    }

    /*
     * Fallback function for simple contract usage, only calls the swap()
     * @dev left for simpler interaction
     */
    function() public {
        swap();
    }

    /*
     * Function swapping the presale tokens for the Signal tokens regardless on the presale pool
     * @dev requires having ownership of the two presale contracts
     * @dev requires the calling party to finish the KYC process fully
     */
    function swap() public {
        require(registry.approved(msg.sender));
        uint256 oldBalance;
        uint256 newBalance;

        if (PublicPresale.balanceOf(msg.sender) > 0) {
            oldBalance = PublicPresale.balanceOf(msg.sender);
            newBalance = oldBalance * compensation1 / 100;
            PublicPresale.burnTokens(msg.sender, oldBalance);
            token.transfer(msg.sender, newBalance);
            SupporterResolved(msg.sender, oldBalance, newBalance);
        }

        if (PartnerPresale.balanceOf(msg.sender) > 0) {
            oldBalance = PartnerPresale.balanceOf(msg.sender);
            newBalance = oldBalance * compensation2 / 100;
            PartnerPresale.burnTokens(msg.sender, oldBalance);
            token.transfer(msg.sender, newBalance);
            PartnerResolved(msg.sender, oldBalance, newBalance);
        }
    }

    /*
     * Function swapping the presale tokens for the Signal tokens regardless on the presale pool
     * @dev initiated from Signals (passing the ownership to a oracle to handle a script is recommended)
     * @dev requires having ownership of the two presale contracts
     * @dev requires the calling party to finish the KYC process fully
     */
    function swapFor(address whom) onlyOwner public returns(bool) {
        require(registry.approved(whom));
        uint256 oldBalance;
        uint256 newBalance;
        
        if (PublicPresale.balanceOf(whom) > 0) {
            oldBalance = PublicPresale.balanceOf(whom);
            newBalance = oldBalance * compensation1 / 100;
            PublicPresale.burnTokens(whom, oldBalance);
            token.transfer(whom, newBalance);
            SupporterResolved(whom, oldBalance, newBalance);
        }

        if (PartnerPresale.balanceOf(whom) > 0) {
            oldBalance = PartnerPresale.balanceOf(whom);
            newBalance = oldBalance * compensation2 / 100;
            PartnerPresale.burnTokens(whom, oldBalance);
            token.transfer(whom, newBalance);
            SupporterResolved(whom, oldBalance, newBalance);
        }

        return true;
    }

    /*
     * Function to clean up the state and moved not allocated tokens to custody
     */
    function clean() onlyOwner public {
        require(now >= deadLine);
        uint256 notAllocated = token.balanceOf(address(this));
        token.transfer(owner, notAllocated);
        selfdestruct(owner);
    }
}
