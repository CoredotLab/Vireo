// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./VireoETH.sol";
import "./VireoX.sol";

interface Ilido_stETH {
    /**
     * @notice Send funds to the pool with optional _referral parameter
     * @dev This function is alternative way to submit funds. Supports optional referral address.
     * @dev If _referral is zero address, no referral will be stored.
     * @return Amount of StETH shares generated
     */
    function submit(address _referral) external payable returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}


contract VireoStaker {

    // lido contract proxy address(testnet)
    address public lido_stETH = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F;
    Ilido_stETH lido = Ilido_stETH(lido_stETH);
    VireoETH public vrETH;
    VireoX public vireoX;

    mapping(address => uint256) public userStETHBalances;
    

    constructor(address _vrETH, address _vireoX) {
        vrETH = VireoETH(_vrETH);
        vireoX = VireoX(_vireoX);
    }

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    function stakeETH() public payable {
        uint256 stETHAmount = lido.submit{value: msg.value}(address(0));
        userStETHBalances[msg.sender] += stETHAmount;
        vrETH.mint(msg.sender, stETHAmount);
        emit Staked(msg.sender, stETHAmount);
    }

    // burn rdvETH and return stETH what this contract has to user
    function unstakeETH(uint256 amount) public {
        require(userStETHBalances[msg.sender] >= amount, "not enough stETH");
        lido.transferFrom(address(this), msg.sender, amount);
        vrETH.burnFrom(msg.sender, amount);
        userStETHBalances[msg.sender] -= amount;
        emit Unstaked(msg.sender, amount);
    }



    
}
