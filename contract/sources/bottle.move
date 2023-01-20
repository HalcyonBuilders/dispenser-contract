module nft_protocol::bottle {
    use std::string;

    use sui::sui::SUI;
    use sui::coin;
    use sui::object::{Self, UID};
    use sui::url;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use originmate::pseudorandom::rand_u64_range_no_counter;

    use nft_protocol::nft;
    use nft_protocol::display;
    use nft_protocol::creators;
    use nft_protocol::collection::{Self, MintCap};
    use nft_protocol::transfer_allowlist;

    const ESaleInactive: u64 = 0;
    const EFundsInsufficient: u64 = 1;

    struct BOTTLE has drop {}
    struct Witness has drop {}
    struct Admin<phantom BOTTLE> has key {
        id: UID,
    }
    struct Dispenser<phantom BOTTLE> has key {
        id: UID,
        active: bool,
        price: u64,
    }


    fun init(witness: BOTTLE, ctx: &mut TxContext) {
        // create collection
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

        // create allowlist
        let col_cap = transfer_allowlist::create_collection_cap<BOTTLE, Witness>(
            &Witness {}, ctx,
        );

        let allowlist = transfer_allowlist::create(Witness {}, ctx);
        transfer_allowlist::insert_collection(
            Witness {},
            &col_cap,
            &mut allowlist,
        );

        transfer::share_object(collection);
        transfer::share_object(mint_cap);
        transfer::share_object(allowlist);
        transfer::share_object(
            Dispenser<BOTTLE>{
                id: object::new(ctx),
                active: false,
                price: 5000000,
            }
        );
        transfer::transfer(col_cap, tx_context::sender(ctx));
        transfer::transfer(
            Admin<BOTTLE> {
                id: object::new(ctx),
            }, 
            tx_context::sender(ctx)
        );
    }

    public entry fun mint_rand_bottle(
        _mint_cap: &MintCap<BOTTLE>,
        dispenser: &mut Dispenser<BOTTLE>,
        funds: &mut coin::Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(dispenser.active, ESaleInactive);
        assert!(coin::value(funds) >= dispenser.price, EFundsInsufficient);
        let rand_nb = rand_u64_range_no_counter(&tx_context::sender(ctx), 0, 4, ctx);

        if (rand_nb < 1) {
            send_filled(tx_context::sender(ctx), _mint_cap, ctx);
        } else {
            send_empty(tx_context::sender(ctx), _mint_cap, ctx);
        };
    }

    public entry fun admin_giveaway_filled(
        _: &Admin<BOTTLE>,
        receiver: address,
        mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext
    ) {
        send_filled(receiver, mint_cap, ctx);
    }

    fun send_filled(
        receiver: address,
        _mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) { 
        let nft = nft::new<BOTTLE, Witness>(
            &Witness {}, tx_context::sender(ctx), ctx
        );

        let name = string::utf8(b"Filled Bottle");
        let description = string::utf8(b"This bottle filled with cool water earn you a Wetlist, go burn it!");
        let url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/5259d912-c344-4d70-9b56-01cf2d49a027/bouteille.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152027Z&X-Amz-Expires=86400&X-Amz-Signature=2dba4fdf029485d81ce063b1c42ba7b10de6f2a06363662de9eb2fddcd79e876&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22bouteille.png%22&x-id=GetObject");
    
        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        transfer::transfer(nft, receiver);
    }

    fun send_empty(
        receiver: address,
        _mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) {
        let nft = nft::new<BOTTLE, Witness>(
            &Witness {}, tx_context::sender(ctx), ctx
        );

        let name = string::utf8(b"Empty Bottle");
        let description = string::utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
        let url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/15a31d77-8c67-4be6-a7f1-1e5300c71515/Bottle8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152059Z&X-Amz-Expires=86400&X-Amz-Signature=3b1b1b27528d44c92bfd2ad66f308564e89dba0df56c4a5dda214819fcaedbcd&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22Bottle8.png%22&x-id=GetObject");
    
        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        transfer::transfer(nft, receiver);
    }

    public entry fun swap_monkey(_ctx: &mut TxContext) {
        // TODO
    }

    public entry fun transfer_admin_cap(
        admin: Admin<BOTTLE>, 
        receiver: address, 
        _ctx: &mut TxContext
    ) {
        transfer::transfer(admin, receiver);
    }

    public entry fun activate_sale(
        _: &Admin<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        _ctx: &mut TxContext
    ) {
        dispenser.active = true;
    }

    public entry fun deactivate_sale(
        _: &Admin<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        _ctx: &mut TxContext
    ) {
        dispenser.active = false;
    }

    public entry fun set_price(
        _: &Admin<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        price: u64,
        _ctx: &mut TxContext
    ) {
        dispenser.price = price;
    }

    // ------------- tests ---------------

    #[test_only]
    use sui::test_scenario as test;

    #[test]
    fun test_mint_nft() {
        let buyer = @0xBABE;
        let admin = @0xCAFE;

        let scenario_val = test::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(BOTTLE{}, test::ctx(scenario));
        };
        test::next_tx(scenario, buyer);
        {
            let admin_cap = test::take_from_address<Admin<BOTTLE>>(scenario, admin);
            let dispenser = test::take_shared<Dispenser<BOTTLE>>(scenario);
            let mint_cap = test::take_shared<MintCap<BOTTLE>>(scenario);

            let coin = coin::mint_for_testing<SUI>(1000000000, test::ctx(scenario));

            activate_sale(&admin_cap, &mut dispenser, test::ctx(scenario));
            mint_rand_bottle(&mint_cap, &mut dispenser, &mut coin, test::ctx(scenario));
            
            test::return_to_address<Admin<BOTTLE>>(admin, admin_cap);
            test::return_shared<Dispenser<BOTTLE>>(dispenser);
            test::return_shared<MintCap<BOTTLE>>(mint_cap);
            transfer::transfer(coin, buyer);
        };
        test::next_tx(scenario, buyer);
        {
            assert!(test::has_most_recent_for_address<nft::Nft<BOTTLE>>(buyer), 0);
        };
        test::end(scenario_val);
    }

}
