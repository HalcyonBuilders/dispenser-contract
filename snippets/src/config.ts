import { Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

export const keypair = Ed25519Keypair.deriveKeypair(
    "stick trend survey toy steel neutral bus hamster delay apple solar vague"
);

export const provider = new JsonRpcProvider();

export const signer = new RawSigner(keypair, provider);

// ---------------------------------

export const PACKAGE_ID = "0xaa7bec2916a66f5e4e4c49b9c35d8028589de6a7";

export const MINT_CAP = "0x094e96346971ceaaedb17ae9a4bf0ab441cfc51d";

export const ADMIN_CAP = "0x6540a624e06376bf2844fd166c353d141d6e9b46";

export const DISPENSER = "0x3c94ea6422bc907780358859864fca755089c71e";

export const FUNDS = "0x81678a4e1d6963e7fd597b2c03f9d9d8d93be6e0";

// addr: 0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b
