import { package_id, mint_cap, admin_cap, dispenser, monkey, funds, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: package_id,
        module: "bottle",
        function: "swap_monkey",
        typeArguments: [],
        arguments: [
            mint_cap,
            monkey,
            "0x3e38dd802cd4a84a890ba610c92a21c453bf5cfa",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()
