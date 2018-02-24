pragma solidity ^0.4.20;

import '../zeppelin/contracts/crowdsale/FinalizableCrowdsale.sol';
import './KYC.sol';
import './pools/AdvisoryPool.sol';
import './pools/CommunityPool.sol';
import './pools/CompanyReserve.sol';
import './pools/PresalePool.sol';

contract SignalsCrowdsale is FinalizableCrowdsale {

    // Cap related variables
    uint256 public constant HARD_CAP = 18947368421052630000000;
    uint256 tokensSold;
    uint256 tokensToBeSold;
    
    // Pricing setup
    uint256 ip; // initial price
    uint256 fp; // final price
    uint256 pd; // final price - initial price
    uint256 tsip; // total supply * initial price

    // Allocation constants
    uint constant ADVISORY_SHARE = 15000000*(10**18);
    uint constant BOUNTY_SHARE = 3000000*(10**18);
    uint constant COMMUNITY_SHARE = 30000000*(10**18);
    uint constant COMPANY_SHARE = 27000000*(10**18);
    uint constant PRESALE_SHARE = 9000000*(10**18); // TODO: change; cca 9.000.000
    uint constant PRIVATE_INVESTORS = 30000000*(10**18); // TODO: change

    // Address pointers
    address constant ADVISORS;
    address constant BOUNTY;
    address constant COMMUNITY;
    address constant COMPANY;
    address constant PRESALE;
    address constant PRIVATE;
    CrowdsaleRegister register;

    // Start & End related vars
    uint256 startTime;
    bool public ready; 
    bool public hasEnded;
    
    event SaleWillStart(uint256 time);
    event SaleReady();
    event SaleEnds();

    function SignalsCrowdsale(address _token, address _wallet, address _register) public
    FinalizableCrowdsale()
    Crowdsale(_token, _wallet)
    {
        register = CrowdsaleRegister(_register);
        // pricing setup
        tokensToBeSold = 75000000*(10**9);
        ip = 3333;
        fp = 2833;
        pd = fp - ip; // final price - initial price
        tsip = tokensToBeSold * ip; // total supply * initial price
    }
    

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool started = (startTime <= now); 
        bool nonZeroPurchase = msg.value != 0;
        bool capNotReached = (weiRaised < HARD_CAP);
        bool approved = register.approved(msg.sender);
        return ready && started && !hasEnded && nonZeroPurchase && capNotReached && approved;
    }

    /*
     * Buy in function to be called from the fallback function
     * @param beneficiary address
     */
    function buyTokens(address beneficiary) private {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = howMany(msg.value);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        uint commission;
        uint extra;
        uint premium;
        (commission, extra) = register.getBonuses(msg.sender);

        // If referral was involved, give some percent to the source
        if (commission > 0) {
            premium = tokens.mul(commission).div(100);
            token.mint(BOUNTY, premium);
        }
        // If extra access granted then give additional %
        if (extra > 0) {
            tokens += tokens.mul(extra).div(100);
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
     * TODO:
     */
    function initialize() public onlyOwner {
        require(!ready);

        // Pre-allocation to pools
        token.mint(ADVISORS,ADVISORY_SHARE);
        token.mint(BOUNTY,BOUNTY_SHARE);
        token.mint(COMMUNITY,COMMUNITY_SHARE);
        token.mint(COMPANY,COMPANY_SHARE);
        token.mint(PRESALE,PRESALE_SHARE);
        token.mint(PRIVATE, PRIVATE_INVESTORS);

        tokensSold = PRESALE_SHARE + PRIVATE_INVESTORS;
        
        ready = true; 
        SaleReady(); 
    }
    
    /*
     * TODO: 
     */
    function changeStart(uint256 _time) onlyOwner {
        startTime = _time;
        SaleWillStart(_time);
    }

    /*
     * TODO: 
     */
    function endSale(bool end) onlyOwner {
        require(startTime <= now); 
        hasEnded = end;
        SaleEnds();
    }
    
    /*
     * Adjust finalization to transfer token ownership to the fund holding address for further use
     */
    function finalization() internal {
        token.finishMinting(); 
        token.transferOwnership(wallet);
    }

    function cleanUp() onlyOwner {
        require(isFinalized);
        selfdestruct(owner);
    }

}



