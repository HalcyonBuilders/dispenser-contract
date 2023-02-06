import { PACKAGE_ID, MINT_CAP, MONKEY, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "swap_monkey",
        typeArguments: [
            "0x32b7adf6d37109671ca391afb9657b4d3c89101c::bottle::BOTTLE"
        ],
        arguments: [
            MINT_CAP,
            MONKEY,
            "0x2feaae049be2c5b2ac76cf3977ca39641ed85889",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
