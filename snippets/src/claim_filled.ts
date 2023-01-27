import { package_id, mint_cap, admin_cap, dispenser, monkey, funds, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: package_id,
        module: "bottle",
        function: "claim_filled_bottle",
        typeArguments: [],
        arguments: [
            mint_cap,
            "3870",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()
