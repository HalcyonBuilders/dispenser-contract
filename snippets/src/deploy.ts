import { SuiCertifiedTransactionEffects, CertifiedTransaction } from "@mysten/sui.js";
import { Infer } from "superstruct";
import { execSync } from "child_process";
import { signer, provider } from "./config";
import * as fs from "fs";
import { stringify } from "csv";

interface IObjectInfo {
    id: string
    type: string
}

const wait = (ms: number): void => {
    const date = Date.now();
    let currentDate: number;
    do {
        currentDate = Date.now();
    } while (currentDate - date < ms);
};

(async () => {
    console.log("running...");
    // await provider.requestSuiFromFaucet("0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b");

    const cliPath = "/home/titouanmarchal/.cargo/bin/sui";
    const packagePath = "/home/titouanmarchal/ThounyBreasty/Projects/Sui/Halcyon/Dispenser/contract";

    const compiledModules = JSON.parse(
        execSync(
            `${cliPath} move build --dump-bytecode-as-base64 --path ${packagePath}`,
            { encoding: "utf-8" }
        )
    );

    try {
        const info = await signer.publish(
            { compiledModules, gasBudget: 100000 },
            "WaitForEffectsCert"
        ) as {
            EffectsCert: {
                effects: Infer<typeof SuiCertifiedTransactionEffects>
                certificate: CertifiedTransaction
            }
        };

        const created = info.EffectsCert.effects.effects.created!.map(
            (item) => item.reference.objectId
        );

        wait(5000);
        const objectBatch = await provider.getObjectBatch(created);

        let packageObjectId = "";
        const createdObjects: IObjectInfo[] = [];

        objectBatch.forEach((item: any) => {
            if (item.details.data?.dataType === "package") {
                packageObjectId = item.details.reference.objectId;
            } else {
                if (item.details.data.type.startsWith("0x2::") === false) {
                    createdObjects.push({
                        id: item.details.reference.objectId,
                        type: item.details.data?.type.slice(44),
                    });
                }
            }
        });

        const writableStream = fs.createWriteStream("../created_objects.csv");
        const stringifier = stringify({ header: true, columns: ["type", "id"] });

        for (let i = 0; i < createdObjects.length; i++) {
            stringifier.write([createdObjects[i].id, createdObjects[i].type]);
        }
        stringifier.pipe(writableStream);

        console.log("Successfully deployed at: " + packageObjectId);
    } catch (e) {
        console.log(e);
    }
})()
