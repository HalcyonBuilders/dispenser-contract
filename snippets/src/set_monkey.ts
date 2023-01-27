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
            "0x7084f37e2ef08ee520d41ffcb0b86c86c9c5617b",
            "nft",
            "::bottle::Nft<0x7084f37e2ef08ee520d41ffcb0b86c86c9c5617b::bottle::BOTTLE>"
        ],
        gasBudget: 10000
    });
    console.log("moveCallTxn", moveCallTxn);

})()
