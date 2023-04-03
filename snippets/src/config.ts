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

export const PACKAGE_ID = "0x5c62d45df7f770cb370aec4791f9afe7264362b8ec30f0dd917c1c18e7b693cd";

export const ADMIN_CAP = "0x751d07ba64d2212862534ed0746a97203fc939aecf39ab146e386831c2ca4ecf";

export const DISPENSER = "0xb86e25af4d4319555e4c1f431b2b7d13faa8d8e9b2d1771ee1c87684c0607a0b";

export const FUNDS = "0x75dac41c5de0fca70dbfecf84554e1e691f9631518dc6a4c7d7796ff1f4b42d9";

// ethos addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd

// cli addr: 0xb242bbfb17bbb802e242fcf033bb9c33ae349a0c2b48c8cb6b9a079acc20432f
