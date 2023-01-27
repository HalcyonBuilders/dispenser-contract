import { package_id, mint_cap, admin_cap, dispenser, monkey, funds, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: package_id,
        module: "bottle",
        function: "buy_random_bottle",
        typeArguments: [],
        arguments: [
            mint_cap,
            dispenser,
            funds,
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()

// TODO: change to buy_random_bottle