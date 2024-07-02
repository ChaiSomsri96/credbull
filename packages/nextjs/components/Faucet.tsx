import React from 'react';
import { useScaffoldWriteContract } from '~~/hooks/scaffold-eth';

const Faucet: React.FC = () => {
  const { writeContractAsync: writeTestTokenAsync, isPending: isFaucetPending } = useScaffoldWriteContract("TestToken");

  const handleFaucet = async () => {
    try {
      await writeTestTokenAsync(
        {
          functionName: "faucet",
          args: [],
        },
        {
          onBlockConfirmation: txnReceipt => {
            console.log("📦 Transaction blockHash", txnReceipt.blockHash);
          },
        },
      );
    } catch (e) {
      console.error("Error handleFaucet", e);
    }
  };

  return (
    <button className="btn btn-primary ml-4 w-[120px]" onClick={handleFaucet} disabled={isFaucetPending}>
      {isFaucetPending ? <span className="loading loading-spinner loading-sm"></span> : "Faucet"}
    </button>
  );
};

export default Faucet;