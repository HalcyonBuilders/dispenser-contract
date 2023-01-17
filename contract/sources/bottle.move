module nft_protocol::bottle {
    use std::string;

    use sui::url;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use originmate::pseudorandom;

    use nft_protocol::nft;
    use nft_protocol::display;
    use nft_protocol::creators;
    use nft_protocol::collection::{Self, MintCap};

    /// One time witness is only instantiated in the init method
    struct BOTTLE has drop {}
    struct DISPENSER has drop {}

    /// Can be used for authorization of other actions post-creation. It is
    /// vital that this struct is not freely given to any contract, because it
    /// serves as an auth token.
    struct Witness has drop {}

    fun init(witness: BOTTLE, ctx: &mut TxContext) {
        let (mint_cap, collection) = collection::create(
            &witness, ctx,
        );

        collection::add_domain(
            &mut collection,
            &mut mint_cap,
            creators::from_address(tx_context::sender(ctx))
        );

        // Register custom domains
        display::add_collection_display_domain(
            &mut collection,
            &mut mint_cap,
            string::utf8(b"Bottles"),
            string::utf8(b"Filled and empty water bottles earning you a Wetlist for Thirsty Monkeys"),
        );

        display::add_collection_url_domain(
            &mut collection,
            &mut mint_cap,
            sui::url::new_unsafe_from_bytes(b"https://halcyon.builders/"),
        );

        display::add_collection_symbol_domain(
            &mut collection,
            &mut mint_cap,
            string::utf8(b"BOTTLES")
        );

        transfer::share_object(collection);
        transfer::share_object(mint_cap);
    }

    public entry fun mint_nft(
        _mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) {
        let nft = nft::new<BOTTLE, Witness>(
            &Witness {}, tx_context::sender(ctx), ctx
        );

        let name;
        let description;
        let url;
        let rand_nb = pseudorandom::rand_u64_range_no_counter(&tx_context::sender(ctx), 0, 4, ctx);

        if (rand_nb > 0) {
            name = string::utf8(b"Filled Bottle");
            description = string::utf8(b"This bottle filled with cool water earn you a Wetlist, go burn it!");
            url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/5259d912-c344-4d70-9b56-01cf2d49a027/bouteille.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152027Z&X-Amz-Expires=86400&X-Amz-Signature=2dba4fdf029485d81ce063b1c42ba7b10de6f2a06363662de9eb2fddcd79e876&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22bouteille.png%22&x-id=GetObject");
        } else {
            name = string::utf8(b"Empty Bottle");
            description = string::utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
            url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/15a31d77-8c67-4be6-a7f1-1e5300c71515/Bottle8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152059Z&X-Amz-Expires=86400&X-Amz-Signature=3b1b1b27528d44c92bfd2ad66f308564e89dba0df56c4a5dda214819fcaedbcd&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22Bottle8.png%22&x-id=GetObject");
        };

        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        transfer::transfer(nft, tx_context::sender(ctx));
    }

    // ------------- tests ---------------

    #[test_only]
    use sui::test_scenario;
    use nft_protocol::nft::Nft;

    #[test]
    fun test_mint_nft() {
        let buyer = @0xBABE;

        let scenario_val = test_scenario::begin(@admin);
        let scenario = &mut scenario_val;
        {
            init(BOTTLE{}, test_scenario::ctx(scenario));
        };
        test_scenario::next_tx(scenario, buyer);
        {
            assert!(test_scenario::has_most_recent_shared<MintCap<BOTTLE>>(), 1);
            let cap = test_scenario::take_shared<MintCap<BOTTLE>>(scenario);
            mint_nft(&cap, test_scenario::ctx(scenario));
            test_scenario::return_shared<MintCap<BOTTLE>>(cap);
        };
        test_scenario::next_tx(scenario, buyer);
        {
            assert!(test_scenario::has_most_recent_for_address<Nft<BOTTLE>>(buyer), 0);
        };
        test_scenario::end(scenario_val);
    }

}
