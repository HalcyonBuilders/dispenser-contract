import { Ed25519Keypair, JsonRpcProvider, RawSigner, Network } from "@mysten/sui.js";
import { execSync } from "child_process";
// import fs from "fs";

(async () => {
    console.log("running...");

    const cliPath = "/home/titouanmarchal/.cargo/bin/sui";
    const packagePath = "/home/titouanmarchal/ThounyBreasty/Projects/Sui/Halcyon/Dispenser/contract";
    // Generate a new Keypair
    const keypair = Ed25519Keypair.deriveKeypair(
        "stick trend survey toy steel neutral bus hamster delay apple solar vague"
    );
    const provider = new JsonRpcProvider(Network.DEVNET);
    const signer = new RawSigner(keypair, provider);

    const address = keypair.getPublicKey().toSuiAddress();
    console.log(address);

    const compiledModules = JSON.parse(
        execSync(
            `${cliPath} move build --dump-bytecode-as-base64 --path ${packagePath}`,
            { encoding: "utf-8" }
        )
    );

    const publishTxn = await signer.publish({
        compiledModules,
        gasBudget: 10000,
    });
    console.log("publishTxn", publishTxn);
})()
