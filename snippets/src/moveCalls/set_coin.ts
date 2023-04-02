import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottle::set_test_coin`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure("0000000000000000000000000000000000000000000000000000000000000002"), // gen1
            tx.pure("sui"), // gen2
            tx.pure("SUI"), // gen3
            tx.pure(2000000), // price
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
