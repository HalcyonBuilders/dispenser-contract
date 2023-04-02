import { PACKAGE_ID, DISPENSER, tx, signer } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottle::recycle`,
        typeArguments: [],
        arguments: [
            tx.object(DISPENSER),
            tx.pure("0x06bbd587f6f05d4aac81aadaff9a982f5a587d1b"),
            tx.pure("0x5941764fae3a94c554d04d0dbd92d7c42a3aabcb"),
            tx.pure("0x5a97bbf638cae68c4ae9641f3f58104a5d618774"),
            tx.pure("0xd4c5326c5be3327428d5d9354288d7afacf013e6"),
            tx.pure("0xe2d722f876c3041f1124bb615363c679c76efc96"),
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
