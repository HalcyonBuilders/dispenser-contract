import { Ed25519Keypair, JsonRpcProvider, RawSigner, Network } from "@mysten/sui.js";

export const keypair = Ed25519Keypair.deriveKeypair(
    "stick trend survey toy steel neutral bus hamster delay apple solar vague"
);

export const provider = new JsonRpcProvider(Network.DEVNET);

export const signer = new RawSigner(keypair, provider);


// ---------------------------------

export const package_id = "0x7084f37e2ef08ee520d41ffcb0b86c86c9c5617b";

export const mint_cap = "0xd9edccf5ff2bffbdae09421920961e4fb76641b7";

export const admin_cap = "0x001ff2deb8169b662f0554e41f00e19645e00a9a";

export const dispenser = "0x52782afd558891cba8bff2f61ed1e881f69fa956";

export const monkey = "0x482aac7993420d9e1a5b5d3ff3e51fa1636ec655";

export const funds = "0x46dfa5be6af6c4c5d34246ff91e5fd0ba666f20b";

// addr: 0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b