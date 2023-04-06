import { PACKAGE_ID, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::register_wetlist`,
        typeArguments: [],
        arguments: [
            tx.object("0x09b9a77637cc1ec3ee9952a590f5d9d4cdb0a03dcb0177c5930eb1078d3acc44"),
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
