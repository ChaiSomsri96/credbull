import React, { useState } from 'react';
import { useScaffoldWriteContract, useDeployedContractInfo } from '~~/hooks/scaffold-eth';
import { parseEther } from 'viem';

interface AddYieldProps {
  contractName: string;
}

const AddYield: React.FC<AddYieldProps> = ({contractName}) => {
	const [amount, setAmount] = useState('');

	const { data: contractData } = useDeployedContractInfo(contractName);
	const { writeContractAsync, isPending } = useScaffoldWriteContract("TestToken");

	const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
	    const value = e.target.value;
	    if (/^\d*\.?\d*$/.test(value)) {
	      setAmount(value);
	    }
	};

	const handleAction = async() => {
		try {
			if (!amount) {
        		return;
      		}

      		const parsedAmount = parseEther(amount);

      		await writeContractAsync(
	      		{
	      			functionName: "transfer",
	      			args: [contractData?.address, parsedAmount],
	      		},
	      		{
		          onBlockConfirmation: txnReceipt => {
		            console.log(`📦transaction blockHash`, txnReceipt.blockHash);
		          },
		        },
      		);
		} catch (e) {
      		console.error(`Error handleAction`, e);
    	}
	}

	return (
    <div className="flex items-center mt-4">
      <input
        type="text"
        className="input input-bordered flex-grow"
        placeholder="Enter assets"
        value={amount}
        onChange={handleAmountChange}
        pattern="^\d*\.?\d*$"
      />
      <button className="btn btn-primary ml-4 w-[120px]" onClick={handleAction} disabled={isPending}>
        {isPending ? <span className="loading loading-spinner loading-sm"></span> : "Donation"}
      </button>
    </div>
  );
};

export default AddYield;