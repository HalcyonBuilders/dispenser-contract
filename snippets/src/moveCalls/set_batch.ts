import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottle::set_batch`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure(true), // active
            tx.pure(1680506884155), // start_timestamp
            tx.pure(16805065217550), // end_timestamp
            tx.pure(2000000), // price
            tx.pure(1), // supply
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
