pragma solidity ^0.4.20;

import '../../zeppelin/contracts/ownership/Ownable.sol';
import '../SignalsToken.sol';
import './AdviserTimeLock.sol';

/*
 * Pre-allocation pool for company advisers
 * @title Advisory pool
 */
contract AdvisoryPool is Ownable{

    SignalsToken token;

    /*
     * @dev constant addresses of all advisers
     */
    address constant ADVISER1 = 0x7915D5A865FE68C63112be5aD3DCA5187EB08f24;
    address constant ADVISER2 = 0x31cFF39AA68B91fa7C957272A6aA8fB8F7b69Cb0;
    address constant ADVISER3 = 0x358b3aeec9fae5ab15fe28d2fe6c7c9fda596857;
    address constant ADVISER4 = 0x1011FC646261eb5d4aB875886f1470d4919d83c8;
    address constant ADVISER5 = 0xcc04Cd98da89A9172372aEf4B62BEDecd01A7F5a;
    address constant ADVISER6 = 0xECD791f8E548D46A9711D853Ead7edC685Ca4ee8;
    address constant ADVISER7 = 0x38B58e5783fd4D077e422B3362E9d6B265484e3f;
    address constant ADVISER8 = 0x2934205135A129F995AC891C143cCae83ce175c7;
    address constant ADVISER9 = 0x9F5D00F4A383bAd14DEfA9aee53C5AF2ad9ad32F;
    address constant ADVISER10 = 0xBE993c982Fc5a0C0360CEbcEf9e4d2727339d96B;
    address constant ADVISER11 = 0xdf1E2126eB638335eFAb91a834db4c57Cbe18735;
    address constant ADVISER12 = 0x8A404969Ad1BCD3F566A7796722f535eD9cA22b2;
    address constant ADVISER13 = 0x066a8aD6fA94AC83e1AFB5Aa7Dc62eD1D2654bB2;
    address constant ADVISER14 = 0xA1425Fa987d1b724306d93084b93D62F37482c4b;
    address constant ADVISER15 = 0x4633515904eE5Bc18bEB70277455525e84a51e90;
    address constant ADVISER16 = 0x230783Afd438313033b07D39E3B9bBDBC7817759;
    address constant ADVISER17 = 0xe8b9b07c1cca9aE9739Cec3D53004523Ab206CAc;
    address constant ADVISER18 = 0x0E73f16CfE7F545C0e4bB63A9Eef18De8d7B422d;
    address constant ADVISER19 = 0x6B4c6B603ca72FE7dde971CF833a58415737826D;
    address constant ADVISER20 = 0x823D3123254a3F9f9d3759FE3Fd7d15e21a3C5d8;
    address constant ADVISER21 = 0x0E48bbc496Ae61bb790Fc400D1F1a57520f772Df;
    address constant ADVISER22 = 0x06Ee8eCc0145CcaCEc829490e3c557f577BE0e85;
    address constant ADVISER23 = 0xbE56bFF75A1cB085674Cc37a5C8746fF6C43C442;
    address constant ADVISER24 = 0xeefB9234302128259D46ED9e223FBC48b5edb5D1;
    address constant ADVISER25 = 0x50EF1d6a7435C7FB3dB7c204b74EB719b1EE3dab;
    address constant ADVISER26 = 0x3e9fed606822D5071f8a28d2c8B51E6964160CB2;

    AdviserTimeLock public tokenLocker23;

    /*
     * Constructor changing owner to owner multisig & calling the allocation
     * @param address of the Signals Token contract
     * @param address of the owner multisig
     */
    function AdvisoryPool(address _token, address _owner) public {
        owner = _owner;
        token = SignalsToken(_token);
    }

    /*
     * Allocation function, tokens get allocated from this contract as current token owner
     * @dev only accessible from the constructor
     */
    function initiate() public onlyOwner {
        require(token.balanceOf(address(this)) == 18500000000000000000000000);
        tokenLocker23 = new AdviserTimeLock(address(token), ADVISER23);

        token.transfer(ADVISER1, 380952380000000000000000);
        token.transfer(ADVISER2, 380952380000000000000000);
        token.transfer(ADVISER3, 659200000000000000000000);
        token.transfer(ADVISER4, 95238100000000000000000);
        token.transfer(ADVISER5, 1850000000000000000000000);
        token.transfer(ADVISER6, 15384620000000000000000);
        token.transfer(ADVISER7, 62366450000000000000000);
        token.transfer(ADVISER8, 116805560000000000000000);
        token.transfer(ADVISER9, 153846150000000000000000);
        token.transfer(ADVISER10, 10683760000000000000000);
        token.transfer(ADVISER11, 114285710000000000000000);
        token.transfer(ADVISER12, 576923080000000000000000);
        token.transfer(ADVISER13, 76190480000000000000000);
        token.transfer(ADVISER14, 133547010000000000000000);
        token.transfer(ADVISER15, 96153850000000000000000);
        token.transfer(ADVISER16, 462500000000000000000000);
        token.transfer(ADVISER17, 462500000000000000000000);
        token.transfer(ADVISER18, 399865380000000000000000);
        token.transfer(ADVISER19, 20032050000000000000000);
        token.transfer(ADVISER20, 35559130000000000000000);
        token.transfer(ADVISER21, 113134000000000000000000);
        token.transfer(ADVISER22, 113134000000000000000000);
        token.transfer(address(tokenLocker23), 7400000000000000000000000);
        token.transfer(ADVISER24, 100000000000000000000000);
        token.transfer(ADVISER25, 100000000000000000000000);
        token.transfer(ADVISER26, 2747253000000000000000000);

    }

    /*
     * Clean up function for token loss prevention and cleaning up Ethereum blockchain
     * @dev call to clean up the contract
     */
    function cleanUp() onlyOwner public {
        uint256 notAllocated = token.balanceOf(address(this));
        token.transfer(owner, notAllocated);
        selfdestruct(owner);
    }
}
