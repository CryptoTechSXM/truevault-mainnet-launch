import { useState } from 'react';
import { ethers } from 'ethers';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useWriteContract } from 'wagmi';

export default function Home() {
  const { address } = useAccount();
  const { writeContract } = useWriteContract();
  const [amount, setAmount] = useState('');

  const deposit = async () => {
    if (!address || !amount) return;
    const usdt = new ethers.Contract('0x55d398326f99059fF775485246999027B3197955', ['function approve(address spender, uint256 amount) external returns (bool)'], useAccount().connector.getProvider());
    const vault = new ethers.Contract('0x033B6dBaB9c178F94725571e71215Ba078cD5dC4', ['function deposit(uint256 amount) external'], useAccount().connector.getProvider());

    await usdt.approve('0x033B6dBaB9c178F94725571e71215Ba078cD5dC4', ethers.parseUnits(amount, 18));
    await vault.deposit(ethers.parseUnits(amount, 18));
  };

  return (
    <div style={{padding: '20px', textAlign: 'center'}}>
      <h1>TrueVault – USDT Yield Vault</h1>
      <p>17–23% APY – Private Beta</p>
      <ConnectButton />
      {address && (
        <div>
          <input placeholder="USDT Amount" value={amount} onChange={(e) => setAmount(e.target.value)} />
          <button onClick={deposit}>Deposit USDT</button>
        </div>
      )}
      <p>TVLT Token: 0x119402f451537b0EE0e4340a5fF8b4332e05407b</p>
      <p>Vault: 0x033B6dBaB9c178F94725571e71215Ba078cD5dC4</p>
      <p>Timelock: 0xC8B1A3641e0fE5DaB8F5460D00F4E188547528dB</p>
      <p>Airdrop Tool: <a href="https://distributepro.truevault.finance">DistributePro</a></p>
    </div>
  );
}
