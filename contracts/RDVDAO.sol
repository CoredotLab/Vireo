// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RDVETH.sol";

interface Ilido_stETH {
    /**
     * @notice Send funds to the pool with optional _referral parameter
     * @dev This function is alternative way to submit funds. Supports optional referral address.
     * @dev If _referral is zero address, no referral will be stored.
     * @return Amount of StETH shares generated
     */
    function submit(address _referral) external payable returns (uint256);
}


contract RDVDAO {

    // lido contract proxy address(testnet)
    address public lido_stETH = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F;
    RDVETH public rdvETH;

    constructor(address _rdvETH) {
        rdvETH = RDVETH(_rdvETH);
    }


    
    
}
