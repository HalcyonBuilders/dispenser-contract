import { Ed25519Keypair, devnetConnection, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js";
import dotenv from "dotenv";

// export const testnetConnection = new Connection({
//     fullnode: "https://explorer-rpc.testnet.sui.io/",
//     faucet: "",
// });

dotenv.config();

export const keypair = Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(process.env.KEY!, "base64")).slice(1));

export const provider = new JsonRpcProvider(devnetConnection);

export const signer = new RawSigner(keypair, provider);

export const tx = new TransactionBlock();

// ---------------------------------

export const PACKAGE_ID = "0x963aa152ca6e179565849b3e2267a407cedcae4afab100329a54ab440aecaac9";

export const ADMIN_CAP = "0xae0592db8aaa72cfac4e7687b3f9f11ec214d8d3cdf37516568d3fe57daacec6";

export const DISPENSER = "0x94db597bb6a9850acfc01f709d4e09783f91c0661a4ca3eb3d978e5e7afedc60";

export const COLLECTION = "0x27150120370befb9851d54813576bcce0ff7b637efc4e603ba9f10ff1d434f50";

// ethos addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd

// cli addr: 0xb242bbfb17bbb802e242fcf033bb9c33ae349a0c2b48c8cb6b9a079acc20432f
