pragma solidity ^0.4.20;

import '../zeppelin/contracts/crowdsale/FinalizableCrowdsale.sol';
import './KYC.sol';
import './pools/AdvisoryPool.sol';
import './pools/CommunityPool.sol';
import './pools/CompanyReserve.sol';
import './pools/PresalePool.sol';

contract SignalsCrowdsale is FinalizableCrowdsale {

    // define Signals crowdsale dependant variables
    uint256 tokensSold;
    uint256 tokensToBeSold;
    //bool initialized; //TODO: to use in case creation won't fit in one block
    bool finalized;

    // initial price
    uint256 ip;
    // final price
    uint256 fp;
    // final price - initial price
    uint256 pd = fp - ip;
    // total supply * initial price
    uint256 tsip = tokensToBeSold * ip;

    // Pseudo constants
    uint256 PRICE;
    uint256 HARD_CAP;
    CrowdsaleRegister register;

    uint constant ADVISORY_SHARE = 15000000*(10**18);
    uint constant BOUNTY_SHARE = 3000000*(10**18);
    uint constant COMMUNITY_SHARE = 30000000*(10**18);
    uint constant COMPANY_SHARE = 27000000*(10**18);
    uint constant PRESALE_SHARE = 9000000*(10**18); // TODO: change; cca 9.000.000
    // Sold initially in a private sale
    uint constant PRIVATE_INVESTORS = 30000000*(10**18); // TODO: change

    event SaleExtended(uint newEnd);
    function SignalsCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _register, uint256 _WEIUSD) public
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _wallet)
    {
        register = CrowdsaleRegister(_register);
        HARD_CAP = 18000000/(_WEIUSD);
        //price = (0.3/_WEIUSD)
        
        // pricing setup
        tokensToBeSold = 75000000*(10**9);
        ip = 3333;
        fp = 968681;

        // Pre-alloc contracts publishing
        AdvisoryPool PoolA = new AdvisoryPool();
        address PoolB = 0x0; //TODO: find out the allocations
        CommunityPool PoolC = new CommunityPool();
        CompanyReserve Reserve = new CompanyReserve();
        PresalePool PoolP = new PresalePool();
        // Private sale counting in the main sale
        address PoolPI = 0x0; //TODO: find out the allocations

        // Pre-allocation to pools
        token.Mint(address(PoolA),ADVISORY_SHARE);
        token.Mint(address(PoolB),BOUNTY_SHARE);
        token.Mint(address(PoolC),COMMUNITY_SHARE);
        token.Mint(address(Reserve),COMPANY_SHARE);
        token.Mint(address(PoolP),PRESALE_SHARE);
        // Private sale distribution
        token.Mint(address(PoolPI), PRIVATE_INVESTORS);
        tokensSold = PRESALE_SHARE + PRIVATE_INVESTORS;

    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool capNotReached = (weiRaised < HARD_CAP);
        bool approved = register.approved(msg.sender);
        return withinPeriod && nonZeroPurchase && capNotReached && approved;
    }

    /*
     * Buy in function to be called from the fallback function
     * @param beneficiary address
     */
    function buyTokens(address beneficiary) private payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = howMany(msg.value);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        address referral;
        uint commission;
        bool extra;
        uint premium;
        (referral,commission, extra) = register.getReferral(msg.sender);

        // If referral was involved, give some percent to the source
        if (referral != 0x0) {
            premium = tokens.mul(commission).div(100);
            token.mint(referral, premium);
        }
        // If extra access granted then give additional 2%
        if (extra) {
            tokens += tokens.mul(2).div(100);
        }
        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        tokensSold += tokens + premium;
        forwardFunds();
        // TODO: check HARD_CAP wasn't passed
    }

    /*
     * Helper token emission functions
     * @param value uint256 of the wei amount that gets invested
     * @return uint256 of how many tokens can one get
     */
    function howMany(uint256 value) public returns (uint256){
        uint256 a = sqrt(4*((tsip+pd*tokensSold)**2)+value.mul(8*pd*tokensToBeSold));
        uint256 b = 2*(tsip+pd*tokensSold);
        uint256 c = 2*pd;

        // get a result with
        return round(((a-b)*10)/c);
    }

    // improved rounding function for the first decimal
    function round(uint x) internal returns (uint y) {
        uint z = x % 10;

        if (z < 5) {
            return x/10;
        }

        else {
            return (x/10)+1;
        }
    }

    // squareroot implementation
    function sqrt(uint x) internal returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /*
     * Adjust finalization to transfer token ownership to the fund holding address for further use
     */
    function finalization() internal {
        token.transferOwnership(wallet);
    }

    function cleanShit() onlyOwner {
        require(finalized);
        selfdestruct(owner);
    }
    /*
     * Optional settings to extend the duration
     * @param _newEndTime uint256 is the new time stamp of extended presale duration
     */
    function extendDuration(uint256 _newEndTime) onlyOwner public {
        require(!isFinalized);
        require(endTime < _newEndTime);
        endTime = _newEndTime;
        SaleExtended(_newEndTime);
    }
}



