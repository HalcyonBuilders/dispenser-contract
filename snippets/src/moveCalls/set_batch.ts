import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::set_batch`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure(true), // active
            tx.pure(0), // start_timestamp
            tx.pure(100000000000000), // end_timestamp
            // tx.pure(1682071828000), // end_timestamp
            tx.pure(100000000), // price
            tx.pure(100000000000000), // price_in_coins
            tx.pure(1000), // supply
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
