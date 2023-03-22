import type { OwnedObjectRef } from "@mysten/sui.js";
import { PACKAGE_ID, MINT_CAP, signer, provider } from "../config";
import { wait, IObjectInfo } from "../utils";

(async () => {
    console.log("running...");

    const callTx = await signer.executeMoveCall({
        packageObjectId: PACKAGE_ID,
        module: "bottle",
        function: "claim_random_bottle",
        typeArguments: [],
        arguments: [
            MINT_CAP,
            "3870",
        ],
        gasBudget: 10000
    });

    // eslint-disable-next-line array-callback-return
    const ids = (callTx as any).effects.effects.created.map((item: OwnedObjectRef) => item.reference.objectId)
    wait(5000);
    const batch = await provider.getObjectBatch(ids);

    const objects: IObjectInfo[] = [];

    batch.forEach((item: any) => {
        objects.push({
            id: item.details.reference.objectId,
            type: item.details.data?.type.slice(44),
        });
    });
    console.log("moveCallTxn", objects);
})()
