//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./IStaking.sol";

/**
 *
 * CryptoGram Funding Receiver
 * Will Allocate Funding To Different Sources
 * Contract Developed By DeFi Mark (MoonMark)
 *
 */
contract CGDistributor {
    
    using Address for address;
    
    // Farming Manager
    address public farm;
    address public stake;

    // CG Token
    address public constant Token = 0xdEBAA696f6Ed65c9D26d51F2Afb2F323f3c058E1;
    
    // allocation to farm + stake
    uint256 public farmFee;
    
    // ownership
    address public _master;
    modifier onlyMaster(){require(_master == msg.sender, 'Sender Not Master'); _;}
    
    constructor() {
    
        _master = 0x44ef27270D0e222111291F6a448A618FAb9284cc;

        farm = 0xF5557151e171B1af542b7AEa0aE05eCaccD62ee7;
        stake = 0xc0DD5D53D532b9C4Ba48B7375750B7Fd4bAd8Dd7;
    
        farmFee = 80;
    }
    
    event SetFarm(address farm);
    event SetStaker(address staker);
    event SetFundPercents(uint256 farmPercentage);
    event Withdrawal(uint256 amount);
    event OwnershipTransferred(address newOwner);
    
    // MASTER 
    
    function setFarm(address _farm) external onlyMaster {
        farm = _farm;
        emit SetFarm(_farm);
    }
    
    function setStake(address _stake) external onlyMaster {
        stake = _stake;
        emit SetStaker(_stake);
    }

    function setFarmPercentage(uint256 farmPercentage) external onlyMaster {
        farmFee = farmPercentage;
        emit SetFundPercents(farmPercentage);
    }
    
    function manualWithdraw(address token) external onlyMaster {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0);
        IERC20(token).transfer(_master, bal);
        emit Withdrawal(bal);
    }
    
    function BNBWithdrawal() external onlyMaster returns (bool s){
        uint256 bal = address(this).balance;
        require(bal > 0);
        (s,) = payable(_master).call{value: bal}("");
        emit Withdrawal(bal);
    }
    
    function transferMaster(address newMaster) external onlyMaster {
        _master = newMaster;
        emit OwnershipTransferred(newMaster);
    }
    
    
    // ONLY APPROVED
    
    function distribute() external {
        _distribute();
    }

    // PRIVATE
    
    function _distribute() private {
        
        uint256 tokenBal = IERC20(Token).balanceOf(address(this));
        
        uint256 farmBal = (tokenBal * farmFee) / 100;
        uint256 stakeBal = tokenBal - farmBal;

        if (farmBal > 0 && farm != address(0)) {
            IERC20(Token).approve(farm, farmBal);
            IStaking(farm).deposit(farmBal);
        }
        
        if (stakeBal > 0 && stake != address(0)) {
            IERC20(Token).approve(stake, stakeBal);
            IStaking(stake).deposit(stakeBal);
        }
    }
    
    receive() external payable {
        (bool s,) = payable(_master).call{value: msg.value}("");
        require(s, 'Failure on Token Purchase');
        _distribute();
    }
    
}