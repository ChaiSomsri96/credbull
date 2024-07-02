//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
	mapping(address => bool) public faucetedList;

	constructor() ERC20("Test Token", "TT") {
    }

	function faucet() public {
        require(!faucetedList[_msgSender()], "Address already received faucet");
        faucetedList[_msgSender()] = true;
        _mint(_msgSender(), 900000000 * (10 ** decimals()));
    }
}