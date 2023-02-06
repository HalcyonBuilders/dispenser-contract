import { Ed25519Keypair, JsonRpcProvider, RawSigner, Network } from "@mysten/sui.js";

export const keypair = Ed25519Keypair.deriveKeypair(
    "stick trend survey toy steel neutral bus hamster delay apple solar vague"
);

export const provider = new JsonRpcProvider(Network.DEVNET);

export const signer = new RawSigner(keypair, provider);


// ---------------------------------

export const package_id = "0x6dd198675aac7206657d082c63f3f5513d2b3318";

export const mint_cap = "0xb6f4b36b23862d20439615b325fcfc103fdde1b0";

export const admin_cap = "0x36cef979b78633a2b802761b1278b2891c616071";

export const dispenser = "0x33150f84dd9f6052dafa528c7d462ef59a2e0321";

export const monkey = "0xbe3502f8ab294ada7d28ac2ec6c5fb8ebf47d0fe";

export const funds = "0x46dfa5be6af6c4c5d34246ff91e5fd0ba666f20b";

// addr: 0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b