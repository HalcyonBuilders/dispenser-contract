import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottle::set_test_nft`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure("0x49da9700dd1db4f99e46fdaad2b867d32e0adb068e162c33eeeed3ab1416ad09"), // package_id
            tx.pure("nft"), // module_name
            tx.pure("Nft"), // struct_name
            tx.pure("9e5c8165e4a4985185d8caa299bbc2c856abbbfe4cde8a5cb932e0ed24f9193a"), // gen1 (sans 0x)
            tx.pure("bottle"), // gen2
            tx.pure("BOTTLE"), // gen3
            tx.pure("Empty Bottle"), // name
        ]
    });
    tx.setGasBudget(10000);
    const moveCallTxn = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        options: {
            showObjectChanges: true,
        }
    });

    console.log("moveCallTxn", moveCallTxn);
})()
