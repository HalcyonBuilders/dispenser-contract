import { PACKAGE_ID, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::buy_random_bottle_with_coins`,
        typeArguments: [
            "0x1d981ebd7bbf06ac3a01fbe4c21dd5978e3ddeac802102ff31b2fc179f753047::test_coin::TEST_COIN"
        ],
        arguments: [
            tx.object(DISPENSER),
            tx.object("0xbb91eab2b717cd549eea68f86e3a70ac2c6796c8b52a0fab7f7420d33d6a00c2"),
            tx.object("0x0000000000000000000000000000000000000000000000000000000000000006"),
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
