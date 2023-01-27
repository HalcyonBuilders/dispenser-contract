import { package_id, mint_cap, admin_cap, dispenser, monkey, funds, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: package_id,
        module: "bottle",
        function: "collect_profits",
        typeArguments: [],
        arguments: [
            admin_cap,
            dispenser,
            "0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b",
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()
