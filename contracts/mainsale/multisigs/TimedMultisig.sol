pragma solidity 0.4.15;
import "./MultiSigWallet.sol";


/// @title Multisignature wallet with monthly limit - Allows an owner to withdraw a monthly limit without multisig.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWalletWithMonthlyLimit is MultiSigWallet {

    /*
     *  Events
     */
    event MonthlyLimitChange(uint monthlyLimit);

    /*
     *  Storage
     */
    uint public monthlyLimit;
    uint public lastDay;
    uint public spentThisMonth;

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners, required number of confirmations and monthly withdraw limit.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _monthlyLimit Amount in wei, which can be withdrawn without confirmations on a monthly basis.
    function MultiSigWalletWithMonthlyLimit(address[] _owners, uint _required, uint _monthlyLimit)
    public
    MultiSigWallet(_owners, _required)
    {
        monthlyLimit = _monthlyLimit;
    }

    /// @dev Allows to change the monthly limit. Transaction has to be sent by wallet.
    /// @param _monthlyLimit Amount in wei.
    function changemonthlyLimit(uint _monthlyLimit)
    public
    onlyWallet
    {
        monthlyLimit = _monthlyLimit;
        monthlyLimitChange(_monthlyLimit);
    }

    /// @dev Allows anyone to execute a confirmed transaction or ether withdraws until monthly limit is reached.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) {
            txn.executed = true;
            if (!_confirmed)
                spentThisMonth += txn.value;
            if (txn.destination.call.value(txn.value)(txn.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                txn.executed = false;
                if (!_confirmed)
                    spentThisMonth -= txn.value;
            }
        }
    }

    /*
     * Internal functions
     */
    /// @dev Returns if amount is within monthly limit and resets spentThisMonth after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under monthly limit.
    function isUnderLimit(uint amount)
    internal
    returns (bool)
    {
        if (now > lastDay + 30 days) {
            lastDay = now;
            spentThisMonth = 0;
        }
        if (spentThisMonth + amount > monthlyLimit || spentThisMonth + amount < spentThisMonth)
            return false;
        return true;
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
    public
    constant
    returns (uint)
    {
        if (now > lastDay + 30 days)
            return monthlyLimit;
        if (monthlyLimit < spentThisMonth)
            return 0;
        return monthlyLimit - spentThisMonth;
    }
}