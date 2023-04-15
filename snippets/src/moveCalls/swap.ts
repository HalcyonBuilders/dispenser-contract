import { PACKAGE_ID, DISPENSER, signer, tx } from "../config";

(async () => {
    console.log("running...");

    tx.moveCall({
        target: `${PACKAGE_ID}::bottles::swap_nft`,
        typeArguments: [
            "0x583ed0aa2648637bb6177c395f9c89f0fc8b649e4983d13968cff4245a85650b::nft::Nft<0x218b871bb91619a8dd9dc7daa22c5a7f70a77de5cd8b08e6dd705773c2e16e44::HalcyonDispenser::HALCYONDISPENSER>"
        ],
        arguments: [
            tx.object(DISPENSER),
            tx.object("0x79dcd31b1c5392fc6e859d400208c97455e58bec5281bd8c687cca39400be223"),
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
