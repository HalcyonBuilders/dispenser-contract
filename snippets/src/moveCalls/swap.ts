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
            tx.pure("0x20db8d95fd302cad47cafb32079aa7a4c45aee2e4412d53ca145cd6f6deafb4b"),
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
