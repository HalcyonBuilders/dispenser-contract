import { package_id, mint_cap, admin_cap, dispenser, monkey, funds, signer } from "./config";

(async () => {
    console.log("running...");

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId: package_id,
        module: "bottle",
        function: "set_monkey",
        typeArguments: [],
        arguments: [
            admin_cap,
            monkey,
            "0x6dd198675aac7206657d082c63f3f5513d2b3318",
            "bottle",
            "::bottle::Nft<0x6dd198675aac7206657d082c63f3f5513d2b3318::bottle::BOTTLE>",
            "Empty Bottle"
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()
