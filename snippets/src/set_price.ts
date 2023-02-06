import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "set_price",
        typeArguments: [],
        arguments: [
            ADMIN_CAP,
            DISPENSER,
            "300000",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
