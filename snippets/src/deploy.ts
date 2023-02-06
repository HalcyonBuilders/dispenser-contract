import { execSync } from "child_process";
import { signer, provider } from "./config";

(async () => {
    console.log("running...");
    
    // await provider.requestSuiFromFaucet("0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b");
    
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
