import { Ed25519Keypair, Connection, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js";
import dotenv from "dotenv";

export const connection = new Connection({
    fullnode: "https://sui-testnet.nodeinfra.com/",
    faucet: "",
});

dotenv.config();

export const keypair = Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(process.env.KEY!, "base64")).slice(1));

export const provider = new JsonRpcProvider(connection);

export const signer = new RawSigner(keypair, provider);

export const tx = new TransactionBlock();

// ---------------------------------

export const PACKAGE_ID = "0x733ec22595c116fc9cdb4d1a9073ac10c10fd7d366dc7359906c3c1527abdda7";

export const ADMIN_CAP = "0x1f06167041b2a1b498793b1d4d310faeaf67d011d00f0f72aad61e3a3ffd065f";

export const DISPENSER = "0xde11121d99da40e18398c4f20d2ad3b7da2c82316663e361be5ca296c861b0cf";

// export const COLLECTION = "0x27150120370befb9851d54813576bcce0ff7b637efc4e603ba9f10ff1d434f50";

// ethos addr: 0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd

// cli addr: 0xb242bbfb17bbb802e242fcf033bb9c33ae349a0c2b48c8cb6b9a079acc20432f
