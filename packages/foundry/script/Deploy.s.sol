//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "../contracts/TestToken.sol";
import "../contracts/TestVault.sol";

import "./DeployHelpers.s.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);

        YourContract yourContract =
            new YourContract(vm.addr(deployerPrivateKey));
        console.logString(
            string.concat(
                "YourContract deployed at: ", vm.toString(address(yourContract))
            )
        );

        //Deploy TestToken contract

        TestToken testToken = new TestToken();
        console.logString(
            string.concat(
                "TestToken deployed at: ", vm.toString(address(testToken))
            )
        );

        TestVault testVault = new TestVault(
            IERC20(testToken),
            100 * 1e18,
            8000 * 1e18,
            vm.addr(deployerPrivateKey)
        );

        console.logString(
            string.concat(
                "TestVault deployed at: ", vm.toString(address(testVault))
            )
        );

        //Add wallets to whitelist
        address[] memory walletsToWhitelist = new address[](5);
        walletsToWhitelist[0] = 0x833Ac83f32785818247897c1c50d4bE927efbEB1;
        walletsToWhitelist[1] = 0x6d6073446EfE7d946167652Fa1F95cd2801A0530;
        walletsToWhitelist[2] = 0x3D40c4B21db362C3580e6A1F6f84a50663266F64;
        walletsToWhitelist[3] = 0x8eeB0661e151933Ad8caC8A0691d7DC72B7De5D2;
        walletsToWhitelist[4] = 0x47CE5ad8013F7B4F89f76652D0CAD067C6F9c1F2;

        for (uint i = 0; i < walletsToWhitelist.length; i++) {
            testVault.addWhitelisted(walletsToWhitelist[i]);
            console.logString(
                string.concat(
                    "Added to whitelist: ", vm.toString(walletsToWhitelist[i])
                )
            );
        }

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
