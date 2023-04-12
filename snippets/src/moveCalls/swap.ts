import { PACKAGE_ID, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::swap_nft`,
        typeArguments: [
            `${PACKAGE_ID}::bottles::BOTTLES`
        ],
        arguments: [
            tx.object(DISPENSER),
            tx.object("0xc964d0fc26889112b2d3b121ab80aabb3b40bbc643d2da3496cd296969636e37"),
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
