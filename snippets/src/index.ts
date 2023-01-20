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

    // deployment
    const deploy = async () => {
        const compiledModules = JSON.parse(
            execSync(
                `${cliPath} move build --dump-bytecode-as-base64 --path ${packagePath}`,
                { encoding: "utf-8" }
            )
        );

        const publishTxn = await signer.publish({
            compiledModules,
            gasBudget: 100000,
        });
        console.log("publishTxn", publishTxn);
    }

    const mint_rand =async () => {
        const moveCallTxn = await signer.executeMoveCall({
            packageObjectId: "0x287586aff1e535900b09d8da1659f5889cda6d0e",
            module: "bottle",
            function: "mint_rand_bottle",
            typeArguments: [],
            arguments: ["0xd8f88b98aa4b8f7383ff0ec46a9017d0eaa2e771"],
            gasBudget: 10000
        });
        console.log("moveCallTxn", moveCallTxn);
    }

    mint_rand()
})()
