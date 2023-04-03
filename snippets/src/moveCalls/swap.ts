import { PACKAGE_ID, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottle::swap_nft`,
        typeArguments: [
            `${PACKAGE_ID}::bottle::BOTTLE`
        ],
        arguments: [
            tx.object(DISPENSER),
            tx.object("0x9731085d88393198eb99f3e337e4f6f0487e0d5c8b20bd39d61febfefc1a996a"),
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
