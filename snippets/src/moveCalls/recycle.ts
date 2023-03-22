import { PACKAGE_ID, MINT_CAP, signer } from "../config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "recycle",
        typeArguments: [],
        arguments: [
            MINT_CAP,
            "0x06bbd587f6f05d4aac81aadaff9a982f5a587d1b",
            "0x5941764fae3a94c554d04d0dbd92d7c42a3aabcb",
            "0x5a97bbf638cae68c4ae9641f3f58104a5d618774",
            "0xd4c5326c5be3327428d5d9354288d7afacf013e6",
            "0xe2d722f876c3041f1124bb615363c679c76efc96",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);
})()
