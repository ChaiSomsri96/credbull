// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Vm.sol";

contract WhitelistHelper {
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256('hevm cheat code'))))));

    function getWhitelistAddresses(string memory filePath) public view returns (address[] memory) {
        string memory json = vm.readFile(filePath);
        address[] memory addresses = abi.decode(vm.parseJson(json, ".whitelistAddresses"), (address[]));
        return addresses;
    }
}