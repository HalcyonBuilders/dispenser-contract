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

export const PACKAGE_ID = "0xdc010c360f085ce8a095c3363eb9ac3c6f67fcb850096106383cba0512f6261d";

export const ADMIN_CAP = "0xb9956996f46d92beef399863d15fc06753a31f4576e14c650e5c0cd764f8fe98";

export const DISPENSER = "0xe1df932afaa907d8f429665a45159a888d533ea3b33af5eb2c449e8c51871d92";

export const FUNDS = "0x75dac41c5de0fca70dbfecf84554e1e691f9631518dc6a4c7d7796ff1f4b42d9";

// addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd
