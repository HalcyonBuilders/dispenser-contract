import { PACKAGE_ID, ADMIN_CAP, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::set_test_nft`,
        typeArguments: [],
        arguments: [
            tx.object(ADMIN_CAP),
            tx.object(DISPENSER),
            tx.pure("0x583ed0aa2648637bb6177c395f9c89f0fc8b649e4983d13968cff4245a85650b"), // package_id
            tx.pure("nft"), // module_name
            tx.pure("Nft"), // struct_name
            tx.pure("218b871bb91619a8dd9dc7daa22c5a7f70a77de5cd8b08e6dd705773c2e16e44"), // gen1 (sans 0x)
            tx.pure("HalcyonDispenser"), // gen2
            tx.pure("HALCYONDISPENSER"), // gen3

            // tx.object(ADMIN_CAP),
            // tx.object(DISPENSER),
            // tx.pure("0x64238cbcc0508e6a74ed679a766912bbff9f56114bedd789230b63ba0ead3cb0"), // package_id
            // tx.pure("bottles"), // module_name
            // tx.pure("EmptyBottle"), // struct_name
            // tx.pure(""), // gen1 (sans 0x)
            // tx.pure(""), // gen2
            // tx.pure(""), // gen3
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
