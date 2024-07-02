import React, { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { useScaffoldWriteContract, useDeployedContractInfo, useScaffoldReadContract } from '~~/hooks/scaffold-eth';
import { parseEther } from 'viem';

type ActionType = 'deposit' | 'mint' | 'withdraw' | 'redeem';

interface ActionButtonProps {
  type: ActionType;
  contractName: string;
  placeholder: string;
}

const ActionButton: React.FC<ActionButtonProps> = ({ type, contractName, placeholder }) => {
  const { address: connectedAddress } = useAccount();
  const { writeContractAsync, isPending } = useScaffoldWriteContract(contractName);
  const { writeContractAsync: writeTestTokenAsync, isPending: isApproving } = useScaffoldWriteContract("TestToken");
  const { data: contractData } = useDeployedContractInfo(contractName);
  const { data: allowance } = useScaffoldReadContract({
    contractName: "TestToken",
    functionName: "allowance",
    args: [connectedAddress, contractData?.address],
  });

  const [amount, setAmount] = useState('');
  const [needsApproval, setNeedsApproval] = useState(false);

  useEffect(() => {
    if (connectedAddress && allowance !== undefined && amount) {
      const requiredAmount = parseEther(amount || '0');
      setNeedsApproval(requiredAmount > BigInt(allowance));
    }
  }, [amount, allowance, connectedAddress]);

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (/^\d*\.?\d*$/.test(value)) {
      setAmount(value);
    }
  };

  const handleAction = async () => {
    try {
	  if (!amount) {
        return;
      }

      const parsedAmount = parseEther(amount);
      let args;

      if (type === 'Deposit' || type === 'Mint') {
      	if (needsApproval) {
      		const maxApprovalAmount = parseEther('900000000');
      		await writeTestTokenAsync(
	          {
	            functionName: "approve",
	            args: [contractData?.address, maxApprovalAmount],
	          },
	          {
	            onBlockConfirmation: txnReceipt => {
	              console.log(`📦 Approval transaction blockHash`, txnReceipt.blockHash);
	            },
	          },
	        );
      	}
      }

      let funcName = '';

      switch (type) {
        case 'Deposit':
          args = [parsedAmount, connectedAddress];
          funcName = 'deposit';
          break;
        case 'Mint':
          args = [parsedAmount, connectedAddress];
          funcName = 'mint';
          break;
        case 'Withdraw':
          args = [parsedAmount, connectedAddress, connectedAddress];
          funcName = 'withdraw';
          break;
        case 'Redeem':
          args = [parsedAmount, connectedAddress, connectedAddress];
          funcName = 'redeem';
          break;
        default:
          return;
      }

      await writeContractAsync(
        {
          functionName: funcName,
          args,
        },
        {
          onBlockConfirmation: txnReceipt => {
            console.log(`📦 ${type} transaction blockHash`, txnReceipt.blockHash);
          },
        },
      );
    } catch (e) {
      console.error(`Error during ${type}`, e);
    }
  };

  return (
    <div className="flex items-center mt-4">
      <input
        type="text"
        className="input input-bordered flex-grow"
        placeholder={`${placeholder}`}
        value={amount}
        onChange={handleAmountChange}
        pattern="^\d*\.?\d*$"
      />
      <button className="btn btn-primary ml-4 w-[120px]" onClick={handleAction} disabled={isPending || isApproving}>
        {isPending || isApproving ? <span className="loading loading-spinner loading-sm"></span> : type}
      </button>
    </div>
  );
};

export default ActionButton;