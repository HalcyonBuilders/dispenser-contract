import { PACKAGE_ID, ADMIN_CAP, MONKEY, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "set_monkey",
        typeArguments: [],
        arguments: [
            ADMIN_CAP,
            MONKEY,
            "32b7adf6d37109671ca391afb9657b4d3c89101c",
            "bottle",
            "BOTTLE",
            "Empty Bottle"
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
