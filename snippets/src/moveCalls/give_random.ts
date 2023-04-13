import { PACKAGE_ID, ADMIN_CAP, signer, tx } from "../config";

(async () => {
    console.log("running...");

    const addresses = [
        "0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd",
        "0xfcd5f2eee4ca6d81d49c85a1669503b7fc8e641b406fe7cdb696a67ef861492c",
    ];

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::give_random_bottles`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.pure(addresses),
        ],
    });
    tx.setGasBudget(10000000);
    const moveCallTxn = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForEffectsCert",
        options: {
            showObjectChanges: true,
            showEffects: true,
        }
    });

    console.log("moveCallTxn", moveCallTxn);
    console.log("STATUS: ", moveCallTxn.effects?.status);
})()
