// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VireoETH.sol";
import "./VireoX.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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


contract VireoStaker is Ownable {

    // lido contract proxy address(testnet)
    address public lido_stETH = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F;
    Ilido_stETH lido = Ilido_stETH(lido_stETH);
    VireoETH public vrETH;
    VireoX public vireoX;

    mapping(address => uint256) public userStETHBalances;

    string vireoXLevelOneUri = "https://static.wikia.nocookie.net/pokemon/images/5/57/%EC%9D%B4%EC%83%81%ED%95%B4%EC%94%A8_%EA%B3%B5%EC%8B%9D_%EC%9D%BC%EB%9F%AC%EC%8A%A4%ED%8A%B8.png/revision/latest/scale-to-width-down/1200?cb=20170404232618&path-prefix=ko";
    

    constructor(address _vrETH, address _vireoX) {
        vrETH = VireoETH(_vrETH);
        vireoX = VireoX(_vireoX);
    }

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    function editVireoETH(address _vrETH) public onlyOwner {
        vrETH = VireoETH(_vrETH);
    }

    function editVireoX(address _vireoX) public onlyOwner {
        vireoX = VireoX(_vireoX);
    }



    function stakeETH() public payable {
        require(msg.value > 0, "msg.value must be greater than 0");
        uint256 stETHAmount = lido.submit{value: msg.value}(address(0));
        userStETHBalances[msg.sender] += stETHAmount;
        vrETH.mint(msg.sender, stETHAmount);
        // check if user has vireoX
        // if don't have
        if (vireoX.balanceOf(msg.sender) == 0) {
            vireoX.safeMint(msg.sender,vireoXLevelOneUri, msg.value);
        } else {
            vireoX.requestEditUserInfo(msg.sender, msg.value);
        }

        emit Staked(msg.sender, stETHAmount);
    }

    // burn vrETH and return stETH what this contract has to user
    function unstakeETH(uint256 amount) public {
        require(amount > 0, "amount must be greater than 0");
        require(userStETHBalances[msg.sender] >= amount, "not enough stETH");
        lido.transferFrom(address(this), msg.sender, amount);
        vrETH.burnFrom(msg.sender, amount);
        userStETHBalances[msg.sender] -= amount;
        emit Unstaked(msg.sender, amount);
    }

    



    
}
