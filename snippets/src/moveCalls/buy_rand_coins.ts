import { PACKAGE_ID, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::buy_random_bottle_with_coins`,
        typeArguments: [
            "0x194baba05589e135f9e35e65e360655deb2502695158e0c31bb5eecd2d53f0e7::test_coin::TEST_COIN"
        ],
        arguments: [
            tx.object(DISPENSER),
            tx.object("0x261c972a719a4ec0aaef0ed6468d30f423c27dcf5011975552acc3e25fe7e1cb"),
            tx.object("0x0000000000000000000000000000000000000000000000000000000000000006"),
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
