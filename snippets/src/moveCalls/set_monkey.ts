import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer } from "../config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "set_monkey",
        typeArguments: [],
        arguments: [
            ADMIN_CAP,
            DISPENSER,
            "44bce0a788da82390b569403f6a0ef32e9d28a1a",
            "bottle",
            "BOTTLE",
            "Empty Bottle"
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
