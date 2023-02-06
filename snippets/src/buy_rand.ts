import { PACKAGE_ID, MINT_CAP, DISPENSER, FUNDS, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "buy_random_bottle",
        typeArguments: [],
        arguments: [
            MINT_CAP,
            DISPENSER,
            FUNDS,
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
