import { PACKAGE_ID, signer } from "../config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "register_wetlist",
        typeArguments: [],
        arguments: [
            "0x12371f6bd88ca278f6b1ea50149a806d136f889a",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
