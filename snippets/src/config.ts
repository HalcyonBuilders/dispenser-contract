import { Ed25519Keypair, JsonRpcProvider, RawSigner, devnetConnection, TransactionBlock } from "@mysten/sui.js";
import dotenv from "dotenv";

// export const connection = new Connection({
//     fullnode: "https://testnet.artifact.systems/sui",
//     faucet: "",
// });

dotenv.config();

export const keypair = Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(process.env.KEY!, "base64")).slice(1));

export const provider = new JsonRpcProvider(devnetConnection);

export const signer = new RawSigner(keypair, provider);

export const tx = new TransactionBlock();

// ---------------------------------

export const PACKAGE_ID = "0x672d9c69ff785f0d2608c38f2e473f349132b260e2d06149e411d770f11a885a";

export const ADMIN_CAP = "0x113ac6997e58c7e408e3360b5cd5284a2061127178ad95a0dc770c12da26c0ed";

export const DISPENSER = "0xf2bb3258dafbadc27abe376ac5cfb00187da07eea03e0a6eb38ab48f227298ec";

// ethos addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd

// cli addr: 0xb242bbfb17bbb802e242fcf033bb9c33ae349a0c2b48c8cb6b9a079acc20432f
