import { Ed25519Keypair, JsonRpcProvider, RawSigner, Base64DataBuffer, Network } from "@mysten/sui.js";
import { execSync } from "child_process";
import fs from "fs";
import { join } from "path";

(async() => {

    console.log("running...");
    
    const cliPath = "/home/titouanmarchal/.cargo/bin/sui";
    const packagePath = "/home/titouanmarchal/ThounyBreasty/Projects/Sui/Halcyon/Dispenser/contract";
    // Generate a new Keypair
    const keypair = Ed25519Keypair.deriveKeypair(
        "found round original fancy funny gloom cushion mask stairs pact legal open"
    );
    const provider = new JsonRpcProvider(Network.DEVNET);
    const address = keypair.getPublicKey().toSuiAddress();
    console.log(address);
    
    const signer = new RawSigner(keypair, provider);
    const compiledModules = JSON.parse(
        execSync(
            `${cliPath} move build --dump-bytecode-as-base64 --path ${packagePath}`,
            { encoding: "utf-8" }
        )
    );
    
    // const modulesInBytes = compiledModules.map((m: (string | Uint8Array)) =>
    //     Array.from(new Base64DataBuffer(m).getData())
    // );
    
    const publishTxn = await signer.publish({
        compiledModules: compiledModules,
        gasBudget: 1000000,
    });
    console.log("publishTxn", publishTxn);
    return;
})();