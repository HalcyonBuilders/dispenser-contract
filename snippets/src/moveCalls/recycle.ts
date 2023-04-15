import { PACKAGE_ID, tx, signer } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::recycle`,
        typeArguments: [],
        arguments: [
            tx.pure("0xf9ea18f93ff674b51d7f9f07eaa924a640a09e32d0e0671df4b4cc3adfc7c43f"),
            tx.pure("0x2dab1148c48c04717ad65e76c6154c6efea6cbaba22ea4bc0b58d777b7963dd6"),
            tx.pure("0x88372d299fec807ae9dd6fab73b7b6a7750d2281c15f4cef32dacdf10220aca6"),
            tx.pure("0x755ff91c0cf729d03514f30eabf194290c41db418856847f66f3685ba78ef9e2"),
            tx.pure("0x47ed15fa61128bd6f31272a247b7e28ce9994bd65df0710cdc881fd6fe54c29b"),
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
