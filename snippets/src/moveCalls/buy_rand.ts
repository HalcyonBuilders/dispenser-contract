import { PACKAGE_ID, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::buy_random_bottle`,
        typeArguments: [],
        arguments: [
            tx.object(DISPENSER),
            tx.gas,
            tx.object("0x0000000000000000000000000000000000000000000000000000000000000006"),
        ]
    });
    // tx.setGasBudget(10000000);
    const moveCallTxn = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForEffectsCert",
        options: {
            // showObjectChanges: true,
            showEffects: true,
        }
    });

    console.log("moveCallTxn", moveCallTxn);
    console.log("STATUS: ", moveCallTxn.effects?.status);
})()
