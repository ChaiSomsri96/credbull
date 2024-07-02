"use client";

import Link from "next/link";
import { useState } from "react";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { BugAntIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import TokenBalances from '~~/components/TokenBalances'; 
import Faucet from '~~/components/Faucet'; 
import ActionButton from '~~/components/ActionButton';
import AddYield from '~~/components/AddYield';

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <TokenBalances address={connectedAddress} />
          
          <div className="flex items-center mt-4">
            <div className="flex-grow"></div>
            <Faucet />
          </div>
          
          
          <AddYield contractName="TestVault" />
          <ActionButton type="Deposit" contractName="TestVault" placeholder="Enter assets" />
          <ActionButton type="Mint" contractName="TestVault" placeholder="Enter shares" />
          <ActionButton type="Withdraw" contractName="TestVault" placeholder="Enter assets" />
          <ActionButton type="Redeem" contractName="TestVault" placeholder="Enter shares" />
          

        </div>

        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <BugAntIcon className="h-8 w-8 fill-secondary" />
              <p>
                Tinker with your smart contract using the{" "}
                <Link href="/debug" passHref className="link">
                  Debug Contracts
                </Link>{" "}
                tab.
              </p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" />
              <p>
                Explore your local transactions with the{" "}
                <Link href="/blockexplorer" passHref className="link">
                  Block Explorer
                </Link>{" "}
                tab.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
