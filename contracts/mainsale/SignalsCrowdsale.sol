pragma solidity ^0.4.20;

import '../zeppelin/contracts/crowdsale/FinalizableCrowdsale.sol';
import './KYC.sol';
import './pools/AdvisoryPool.sol';
import './pools/CommunityPool.sol';
import './pools/CompanyReserve.sol';
import './pools/PresalePool.sol';

contract SignalsCrowdsale is FinalizableCrowdsale {

    // Cap & price related values
    uint256 public constant HARD_CAP = 18947368421052630000000;
    uint256 public constant INITIAL_PRICE = 3333;
    uint256 public tokensSold;

    // Allocation constants
    uint constant ADVISORY_SHARE = 15000000*(10**18);
    uint constant BOUNTY_SHARE = 3000000*(10**18);
    uint constant COMMUNITY_SHARE = 30000000*(10**18);
    uint constant COMPANY_SHARE = 27000000*(10**18);
    uint constant PRESALE_SHARE = 9000000*(10**18); // TODO: change; cca 9.000.000
    uint constant PRIVATE_INVESTORS = 30000000*(10**18); // TODO: change to ?

    // Address pointers
    address constant ADVISORS = 0x28dd7d6f41331e5013ee6c802641cc63b06c238a;
    address constant BOUNTY = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
    address constant COMMUNITY = 0x50188f5ba2cd4dfde54469893d53a2e0c4b71824;
    address constant COMPANY = 0xa4b34e7863b1c17e27b51761646e8dfd5da56e2b;
    address constant PRESALE = 0xd7c1f640af9b2947edc5ca9445e3eb75e5d7d9c0;
    address constant PRIVATE = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
    CrowdsaleRegister register;

    // Start & End related vars
    uint256 startTime;
    bool public ready;

    // Events
    event SaleWillStart(uint256 time);
    event SaleReady();
    event SaleEnds();

    function SignalsCrowdsale(address _token, address _wallet, address _register) public
    FinalizableCrowdsale()
    Crowdsale(_token, _wallet)
    {
        register = CrowdsaleRegister(_register);

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
        // TODO: check HARD_CAP wasn't passed (or don't?)
    }

    /*
     * Helper token emission functions
     * @param value uint256 of the wei amount that gets invested
     * @return uint256 of how many tokens can one get
     */
    function howMany(uint256 value) public returns (uint256){
        return value * (INITIAL_PRICE - (INITIAL_PRICE*((weiRaised/HARD_CAP)*15/100)));
    }

    /*
     * Function to do preallocations - MANDATORY to continue
     * @dev It's separated so it doesn't have to run in constructor
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
     * Function to do set or adjust the startTime - NOT MANDATORY but good for future start
     */
    function changeStart(uint256 _time) onlyOwner {
        startTime = _time;
        SaleWillStart(_time);
    }

    /*
     * Function end or pause the sale
     * @dev It's MANDATORY to finalize()
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

    /*
     * Clean up function to get the contract selfdestructed - OPTIONAL
     */
    function cleanUp() onlyOwner {
        require(isFinalized);
        selfdestruct(owner);
    }

}



