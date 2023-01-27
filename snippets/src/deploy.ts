import { execSync } from "child_process";
import { signer } from "./config";

(async () => {
    console.log("running...");

    const cliPath = "/home/titouanmarchal/.cargo/bin/sui";
    const packagePath = "/home/titouanmarchal/ThounyBreasty/Projects/Sui/Halcyon/Dispenser/contract";

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
})()
