import { PACKAGE_ID, ADMIN_CAP, signer } from "../config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "transfer_admin_cap",
        typeArguments: [],
        arguments: [
            ADMIN_CAP,
            "",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
