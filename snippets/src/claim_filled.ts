import { PACKAGE_ID, MINT_CAP, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "claim_filled_bottle",
        typeArguments: [],
        arguments: [
            MINT_CAP,
            "3870",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
