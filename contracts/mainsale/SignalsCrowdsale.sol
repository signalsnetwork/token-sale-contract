pragma solidity ^0.4.20;

import '../zeppelin/contracts/crowdsale/FinalizableCrowdsale.sol';
import './KYC.sol';
import './KYC2.sol';
import './pools/AdvisoryPool.sol';
import './pools/CommunityPool.sol';
import './pools/CompanyReserve.sol';
import './pools/PresalePool.sol';

contract SignalsCrowdsale is FinalizableCrowdsale {

    // Cap & price related values
    uint256 public constant HARD_CAP = 18000*(10**18);
    uint256 public toBeRaised = 18000*(10**18);
    uint256 public constant PRICE = 360000;
    uint256 public tokensSold;
    uint256 public constant maxTokens = 185000000*(10**9);

    // Allocation constants
    uint constant ADVISORY_SHARE = 18500000*(10**9); //FIXED
    uint constant BOUNTY_SHARE = 3700000*(10**9); // FIXED
    uint constant COMMUNITY_SHARE = 37000000*(10**9); //FIXED
    uint constant COMPANY_SHARE = 33300000*(10**9); //FIXED
    uint constant PRESALE_SHARE = 7856217611546440; // FIXED;

    // Address pointers
    address constant ADVISORS = 0x98280b2FD517a57a0B8B01b674457Eb7C6efa842; // TODO: change
    address constant BOUNTY = 0x8726D7ac344A0BaBFd16394504e1cb978c70479A; // TODO: change
    address constant COMMUNITY = 0x90CDbC88aB47c432Bd47185b9B0FDA1600c22102; // TODO: change
    address constant COMPANY = 0xC010b2f2364372205055a299B28ef934f090FE92; // TODO: change
    address constant PRESALE = 0x7F3a38fa282B16973feDD1E227210Ec020F2481e; // TODO: change
    CrowdsaleRegister register;
    PrivateRegister register2;

    // Start & End related vars
    bool public ready;

    // Events
    event SaleWillStart(uint256 time);
    event SaleReady();
    event SaleEnds(uint256 tokensLeft);

    function SignalsCrowdsale(address _token, address _wallet, address _register, address _register2) public
    FinalizableCrowdsale()
    Crowdsale(_token, _wallet)
    {
        register = CrowdsaleRegister(_register);
        register2 = PrivateRegister(_register2);
    }
    

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool started = (startTime <= now); 
        bool nonZeroPurchase = msg.value != 0;
        bool capNotReached = (weiRaised < HARD_CAP);
        bool approved = register.approved(msg.sender);
        bool approved2 = register2.approved(msg.sender);
        return ready && started && !hasEnded && nonZeroPurchase && capNotReached && (approved || approved2);
    }

    /*
     * Buy in function to be called from the fallback function
     * @param beneficiary address
     */
    function buyTokens(address beneficiary) private {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // base discount
        uint256 discount = ((toBeRaised*10000)/HARD_CAP)*15;
                
        // calculate token amount to be created
        uint256 tokens;

        // update state
        weiRaised = weiRaised.add(weiAmount);
        toBeRaised = toBeRaised.sub(weiAmount);

        uint commission;
        uint extra;
        uint premium;

        if (register.approved(beneficiary)) {
            (commission, extra) = register.getBonuses(beneficiary);

            // If extra access granted then give additional %
            if (extra > 0) {
                discount += extra*10000;
            }
            tokens =  howMany(msg.value, discount);

            // If referral was involved, give some percent to the source
            if (commission > 0) {
                premium = tokens.mul(commission).div(100);
                token.mint(BOUNTY, premium);
            }

        } else {
            extra = register2.getBonuses(beneficiary);
            if (extra > 0) {
                discount = extra*10000;
                tokens =  howMany(msg.value, discount);
            }
        }

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        tokensSold += tokens + premium;
        forwardFunds();
        
        assert(token.totalSupply() <= maxTokens);
    }

    /*
     * Helper token emission functions
     * @param value uint256 of the wei amount that gets invested
     * @return uint256 of how many tokens can one get
     */
    function howMany(uint256 value, uint256 discount) public view returns (uint256){
        uint256 actualPrice = PRICE * (1000000 - discount) / 1000000;
        return value / actualPrice;
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

        tokensSold = PRESALE_SHARE;
        
        ready = true; 
        SaleReady(); 
    }

    /*
     * Function to do set or adjust the startTime - NOT MANDATORY but good for future start
     */
    function changeStart(uint256 _time) public onlyOwner {
        startTime = _time;
        SaleWillStart(_time);
    }

    /*
     * Function end or pause the sale
     * @dev It's MANDATORY to finalize()
     */
    function endSale(bool end) public onlyOwner {
        require(startTime <= now);
        uint256 tokensLeft = maxTokens - token.totalSupply();
        if (tokensLeft > 0) {
            token.mint(wallet, tokensLeft);
        }
        hasEnded = end;
        SaleEnds(tokensLeft);
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
    function cleanUp() public onlyOwner {
        require(isFinalized);
        selfdestruct(owner);
    }

}



