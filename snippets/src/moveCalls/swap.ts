import { PACKAGE_ID, ADMIN_CAP, signer, DISPENSER } from "../config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "swap_monkey",
        typeArguments: [
            "0x564fb6c97f3d098e8737fb8b13b6eaf7a6ca6784::bottle::BOTTLE"
        ],
        arguments: [
            ADMIN_CAP,
            DISPENSER,
            "0xeea459aa5cffcbc500fa02db95b20e15bcdde332",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
