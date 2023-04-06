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

export const PACKAGE_ID = "0xd67588ed780942a1fa85eff1e05cb9dfd2a201bf83203198a03193624f7ba230";

export const ADMIN_CAP = "0x5647f1d23ed8fc0a6582d241d773563f1639b7c6a262d303356c44f01a0d7b7b";

export const DISPENSER = "0x384437e7143aaf1cc7a1da6d4abc55e041204a852866d096cb95f061994ea9f7";

export const COLLECTION = "0x6b72e0274a15daa009f93413c7a6445bf5ad59c9cbc21d49fb58572632275f6c";

// ethos addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd

// cli addr: 0xb242bbfb17bbb802e242fcf033bb9c33ae349a0c2b48c8cb6b9a079acc20432f
