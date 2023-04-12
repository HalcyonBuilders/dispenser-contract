import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::set_test_nft`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure("0xa0e7500b1b8420f6e6d187d3f2f10b886ebc9d583f40754b4576ca9d3844b845"), // package_id
            tx.pure("nft"), // module_name
            tx.pure("Nft"), // struct_name
            tx.pure("963aa152ca6e179565849b3e2267a407cedcae4afab100329a54ab440aecaac9"), // gen1 (sans 0x)
            tx.pure("bottles"), // gen2
            tx.pure("BOTTLES"), // gen3
            tx.pure("Not this"), // name
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
