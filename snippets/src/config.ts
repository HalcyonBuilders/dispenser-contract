import { Ed25519Keypair, Connection, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js";
import dotenv from "dotenv";

export const testnetConnection = new Connection({
    fullnode: "https://explorer-rpc.testnet.sui.io/",
    faucet: "",
});

dotenv.config();

export const keypair = Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(process.env.KEY!, "base64")).slice(1));

export const provider = new JsonRpcProvider(testnetConnection);

export const signer = new RawSigner(keypair, provider);

export const tx = new TransactionBlock();

// ---------------------------------

export const PACKAGE_ID = "0xed54aeff9921b073f4036e9015b8913cc0f6235fca9ab20be92217901ac511c4";

export const ADMIN_CAP = "0xbaf0b55855fe60e3aebc823a02f5cbc5a93ba0ea6bb6b7d2ad3f4d6c7f885828";

export const DISPENSER = "0x882b9ffe1a1315a112621596d35dc7de8b54f8ecc63bf25cdf65c6d4d4bd3fd4";

export const COLLECTION = "0xfbdc3d8c86f57d8d29dc594fc1835076e93f0d1b6829455c6bd4aab119c33f13"

// ethos addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd

// cli addr: 0xb242bbfb17bbb802e242fcf033bb9c33ae349a0c2b48c8cb6b9a079acc20432f
