pragma solidity ^0.4.11;

import "./SignalsToken.sol";

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    SignalsToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, address _wallet) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != 0x0);

        token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (SignalsToken) {
        return new SignalsToken();
    }
    // fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {}

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }


}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal {
    }
}


/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 public goal;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    function RefundableCrowdsale(uint256 _goal) {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    // We're overriding the fund forwarding from Crowdsale.
    // In addition to sending the funds, we want to call
    // the RefundVault deposit function
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    // vault finalization task, called when owner calls finalize()
    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        super.finalization();
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }
}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    function CappedCrowdsale(uint256 _cap) {
        require(_cap > 0);
        cap = _cap;
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= cap;
        return super.validPurchase() && withinCap;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        return super.hasEnded() || capReached;
    }

}

/**
 * @title SignalsToken crowdsale
 * @dev v0.7 of Signals Crowdsourcing contract based on OpenZeppeling implementations
 */
contract SignalsCrowdsale is CappedCrowdsale, RefundableCrowdsale {

    // define Signals dependad variables
    uint256 tokensSold;
    uint256 tokensToBeSold;
    bool initialized;

    // initial price
    uint256 ip;
    // final price
    uint256 fp;
    // final price - initial price
    uint256 pd = fp - ip;
    // total supply * initial price
    uint256 tsip = tokensToBeSold * ip;

    //Signals company account
    address signalsCompany;
    //Signals bounty account
    address signalsBounty;


    function SignalsCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _goal, uint256 _cap, address _wallet)
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _wallet)
    {
        //As goal needs to be met for a successful crowdsale
        //the value needs to less or equal than a cap which is limit for accepted funds
        require(_goal <= _cap);

        // pricing setup
        tokensToBeSold = 75000000*(10**9);
        ip = 823379;
        fp = 968681;

        // wallets setup
        signalsCompany = msg.sender;
        signalsBounty = msg.sender;

        // after construction the initialize() function should be called as a next step
    }

    // TODO: add pausability
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = howMany(msg.value);


        //
        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        tokensSold += tokens;

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();

    }

    // helper token emission functions
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


    function initialize() onlyOwner {
        require(!initialized);
        require(!isFinalized);

        allocate();
        token.pause();
        initialized = true;
    }


    // allocation of funds  - TODO: create allocation contracts respectively
    function allocate() internal {
        token.mint(signalsCommunity, 15000000*(10**9));
        token.mint(signalsReserve, 13500000*(10**9));
        token.mint(signalsAdvisors, 7500000*(10**9));
        token.mint(signalsBounty, 1500000*(10**9));
    }

    function finalization() internal {
        token.unpause();
        super.finalization();
    }
}