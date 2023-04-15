import { PACKAGE_ID, ADMIN_CAP, signer, tx } from "../config";

(async () => {
    console.log("running...");

    const addresses = [
        "0xb95877ace060f46272b7caa8926e5e0966720e6d084e2456b9b9ed9a63594ef2",
    ];

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::give_filled_bottles`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.pure(addresses),
        ],
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
