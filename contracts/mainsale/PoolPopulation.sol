pragma solidity ^0.4.20;

import '../zeppelin/contracts/ownership/Ownable.sol';
import './pools/AdvisoryPool.sol';
import './pools/CommunityPool.sol';
import './pools/CompanyReserve.sol';
import './pools/PresalePool.sol';

contract PoolPopulation is Ownable {

    // Pre-alloc contracts publishing
    AdvisoryPool public PoolA;
    CommunityPool public PoolC;
    CompanyReserve public Reserve;
    PresalePool public PoolP;

    function PoolPopulation(address token, address multiSig, address register, uint compensation1, uint compensation2) public {
        // Pre-alloc contracts publishing
        PoolA = new AdvisoryPool(token, multiSig);
        PoolC = new CommunityPool(token, multiSig);
        Reserve = new CompanyReserve(token, multiSig);
        PoolP = new PresalePool(token, register, multiSig, compensation1, compensation2);
    }

    function clean() onlyOwner public {
        selfdestruct(owner);
    }
}



