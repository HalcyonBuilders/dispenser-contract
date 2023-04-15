import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::set_test_coin`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure("1d981ebd7bbf06ac3a01fbe4c21dd5978e3ddeac802102ff31b2fc179f753047"), // gen1
            tx.pure("test_coin"), // gen2
            tx.pure("TEST_COIN"), // gen3
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
