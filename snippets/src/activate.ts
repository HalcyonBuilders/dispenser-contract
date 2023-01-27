import { package_id, mint_cap, admin_cap, dispenser, monkey, funds, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: package_id,
        module: "bottle",
        function: "activate_sale",
        typeArguments: [],
        arguments: [
            admin_cap,
            dispenser,
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()
