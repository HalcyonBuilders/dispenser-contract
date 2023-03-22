import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer } from "../config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "collect_profits",
        typeArguments: [],
        arguments: [
            ADMIN_CAP,
            DISPENSER,
            "0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
