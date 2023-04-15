import { PACKAGE_ID, tx, signer } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::claim_random_bottle`,
        typeArguments: [],
        arguments: [
            tx.pure(3149),
        ]
    });
    tx.setGasBudget(10000000);
    const moveCallTxn = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        options: {
            showObjectChanges: true,
            showEffects: true,
        }
    });

    console.log("moveCallTxn", moveCallTxn);
    console.log("STATUS: ", moveCallTxn.effects?.status);
})()
