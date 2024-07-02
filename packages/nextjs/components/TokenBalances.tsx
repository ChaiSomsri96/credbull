import React from 'react';
import { useScaffoldReadContract, useDeployedContractInfo } from '~~/hooks/scaffold-eth';
import { formatUnits } from 'viem';

const TokenBalances: React.FC<{ address: string }> = ({ address }) => {
  const { data: vaultBalance } = useScaffoldReadContract({
    contractName: "TestVault",
    functionName: "balanceOf",
    args: [address],
  });

  const { data: minDepositAmount } = useScaffoldReadContract({
    contractName: "TestVault",
    functionName: "minDepositAmount",
    args: [],
  });

  const { data: maxTotalAmount } = useScaffoldReadContract({
    contractName: "TestVault",
    functionName: "maxTotalAmount",
    args: [],
  });

  const { data: tokenBalance } = useScaffoldReadContract({
    contractName: "TestToken",
    functionName: "balanceOf",
    args: [address],
  });

  const { data: testVault } = useDeployedContractInfo("TestVault");
  const { data: testToken } = useDeployedContractInfo("TestToken");

  const formatBalance = (balance: any) => {
    return parseFloat(formatUnits(BigInt(balance), 18)).toFixed(18);
  };

  return (
    <div>
      <p><span className="font-bold">Vault:</span> <a target="_blank"  href={`http://localhost:3000/blockexplorer/address/${testVault?.address? testVault?.address : ''}`}>{ testVault?.address? testVault?.address : ''}</a></p>
      <p><span className="font-bold">Asset:</span> <a target="_blank"  href={`http://localhost:3000/blockexplorer/address/${testToken?.address? testToken?.address : ''}`}>{ testToken?.address? testToken?.address : ''}</a></p>
      <p><span className="font-bold">MinDepositAmount:</span> {minDepositAmount ? formatBalance(minDepositAmount) : '0'}</p>
      <p><span className="font-bold">MaxTotalAmount:</span> {maxTotalAmount ? formatBalance(maxTotalAmount) : '0'}</p>
      <p><span className="font-bold">Shares Balance:</span> {vaultBalance ? formatBalance(vaultBalance) : '0'}</p>
      <p><span className="font-bold">Asset Balance:</span> {tokenBalance ? formatBalance(tokenBalance) : '0'}</p>
    </div>
  );
};

export default TokenBalances;