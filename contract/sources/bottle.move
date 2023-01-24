module nft_protocol::bottle {
    use std::string;
    use std::option;
    use std::vector;

    use sui::address;
    use sui::sui::SUI;
    use sui::coin;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use sui::url;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use originmate::pseudorandom::rand_u64_range_no_counter;

    use nft_protocol::nft;
    use nft_protocol::display;
    use nft_protocol::creators;
    use nft_protocol::collection::{Self, MintCap};
    use nft_protocol::unprotected_safe::{Self as safe, UnprotectedSafe as Safe};
    use nft_protocol::transfer_allowlist;

    const ESaleInactive: u64 = 0;
    const EFundsInsufficient: u64 = 1;
    const ENotVerified: u64 = 2;
    const ENoBottleLeft: u64 = 3;
    const ENotValidHexCharacter: u64 = 4;

    const BURN_ADDRESS: address = @0xaacfea8d66fe120dae87ac8a7924fe5c510f1c3a;

    // TODO: add events (buy_rand, claim, recycle)

    struct BOTTLE has drop {}
    struct Witness has drop {}
    struct AdminCap<phantom BOTTLE> has key {id: UID}
    struct Dispenser<phantom BOTTLE> has key {
        id: UID,
        active: bool,
        price: u64,
        balance: Balance<SUI>,
        supply: u64,
        left: u64,
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
            url::new_unsafe_from_bytes(b"https://halcyon.builders/"),
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
        transfer_allowlist::insert_authority<Witness, Witness>(
            Witness {},
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
                balance: balance::zero(),
                supply: 0,
                left: 0,
            }
        );
        transfer::transfer(col_cap, tx_context::sender(ctx));
        transfer::transfer(
            AdminCap<BOTTLE> {
                id: object::new(ctx),
            }, 
            tx_context::sender(ctx)
        );
    }

    public entry fun buy_rand_bottle(
        mint_cap: &MintCap<BOTTLE>,
        dispenser: &mut Dispenser<BOTTLE>,
        opt_safe: option::Option<Safe>,
        funds: &mut coin::Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(dispenser.active, ESaleInactive);
        // if supply == 0, it means there is no limit
        if (dispenser.supply != 0) {assert!(dispenser.left > 0, ENoBottleLeft);};
        assert!(coin::value(funds) >= dispenser.price, EFundsInsufficient);

        let balance = coin::balance_mut(funds);
        let amount = balance::split(balance, dispenser.price);
        balance::join(&mut dispenser.balance, amount);

        let nft: nft::Nft<BOTTLE>;
        let rand_nb = rand_u64_range_no_counter(&tx_context::sender(ctx), 0, 10, ctx);
        if (rand_nb < 1) {
            nft = mint_filled(mint_cap, ctx);
        } else {
            nft = mint_empty(mint_cap, ctx);
        };

        if (option::is_none(&opt_safe)) { 
            let (safe, cap) = safe::new(ctx); 
            transfer::transfer(cap, tx_context::sender(ctx));
            safe::deposit_nft(nft, &mut safe, ctx);
            transfer::share_object(safe);
        } else {
            let safe = option::extract(&mut opt_safe);
            safe::deposit_nft(nft, &mut safe, ctx);
        };
        // TODO: managing Safe (creation or borrowing)
    }

    public entry fun claim_filled_bottle(
        magic_nb: u64,
        mint_cap: &MintCap<BOTTLE>,
        opt_safe: option::Option<Safe>,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        let nft = mint_filled(mint_cap, ctx);

        if (option::is_none(&opt_safe)) { 
            let (safe, cap) = safe::new(ctx); 
            transfer::transfer(cap, tx_context::sender(ctx));
            safe::deposit_nft(nft, &mut safe, ctx);
            transfer::share_object(safe);
        } else {
            let safe = option::extract(&mut opt_safe);
            safe::deposit_nft(nft, &mut safe, ctx);
        };
        // TODO: managing Safe (creation or borrowing)
    }

    public entry fun recycle(
        mint_cap: &MintCap<BOTTLE>,
        safe: Safe,
        ctx: &mut TxContext,
    ) {
        
    }

    fun mint_filled(
        _mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ): nft::Nft<BOTTLE> { 
        let nft = nft::new<BOTTLE, Witness>(
            &Witness {}, tx_context::sender(ctx), ctx
        );

        let name = string::utf8(b"Filled Bottle");
        let description = string::utf8(b"This bottle filled with cool water earn you a Wetlist, go burn it!");
        let url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/5259d912-c344-4d70-9b56-01cf2d49a027/bouteille.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152027Z&X-Amz-Expires=86400&X-Amz-Signature=2dba4fdf029485d81ce063b1c42ba7b10de6f2a06363662de9eb2fddcd79e876&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22bouteille.png%22&x-id=GetObject");
    
        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        return nft
    }

    fun mint_empty(
        _mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ): nft::Nft<BOTTLE> {
        let nft = nft::new<BOTTLE, Witness>(
            &Witness {}, tx_context::sender(ctx), ctx
        );

        let name = string::utf8(b"Empty Bottle");
        let description = string::utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
        let url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/15a31d77-8c67-4be6-a7f1-1e5300c71515/Bottle8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152059Z&X-Amz-Expires=86400&X-Amz-Signature=3b1b1b27528d44c92bfd2ad66f308564e89dba0df56c4a5dda214819fcaedbcd&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22Bottle8.png%22&x-id=GetObject");
    
        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        return nft
    }

    // public entry fun swap_monkey<T: drop>(nft: nft::Nft<T>, _ctx: &mut TxContext) {
        
    // }

    // admin setup functions

    public entry fun transfer_admin_cap(
        admin: AdminCap<BOTTLE>, 
        receiver: address, 
        _ctx: &mut TxContext
    ) {
        transfer::transfer(admin, receiver);
    }

    public entry fun activate_sale(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        _ctx: &mut TxContext
    ) {
        dispenser.active = true;
    }

    public entry fun deactivate_sale(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        _ctx: &mut TxContext
    ) {
        dispenser.active = false;
    }

    public entry fun set_price(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        price: u64,
        _ctx: &mut TxContext
    ) {
        dispenser.price = price;
    }

    public entry fun set_supply(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        supply: u64,
        _ctx: &mut TxContext
    ) {
        dispenser.supply = supply;
        dispenser.left = supply;
    }

    public entry fun collect_profits(
        _: &AdminCap<BOTTLE>,
        dispenser: &mut Dispenser<BOTTLE>,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let amount = balance::value(&dispenser.balance);
        let profits = coin::take(&mut dispenser.balance, amount, ctx);

        transfer::transfer(profits, receiver)
    }

    // utils

    fun decode_byte(hex: u8): u8 {
        if (/* 0 .. 9 */ 48 <= hex && hex < 58) {
            hex - 48
        } else if (/* A .. F */ 65 <= hex && hex < 71) {
            10 + hex - 65
        } else if (/* a .. f */ 97 <= hex && hex < 103) {
            10 + hex - 97
        } else {
            abort ENotValidHexCharacter
        }
    }

    fun assert_is_verified(magic_nb: u64, ctx: &mut TxContext) {
        let addr_in_bytes = address::to_bytes(tx_context::sender(ctx));
        let b20_in_dec = vector::pop_back<u8>(&mut addr_in_bytes);
        let b19_in_dec = vector::pop_back<u8>(&mut addr_in_bytes);
        let multiplied = ((b20_in_dec as u64) * (b19_in_dec as u64));
        assert!(multiplied == magic_nb, ENotVerified);
    }

    // ------------- tests ---------------

    #[test_only]
    use sui::test_scenario as test;

    #[test_only]
    const EWrongBalance: u64 = 10;

    // #[test]
    // fun test_mint_nft() {
    //     let buyer = @0xBABE;
    //     let admin = @0xCAFE;

    //     let scenario_val = test::begin(admin);
    //     let scenario = &mut scenario_val;
    //     {
    //         init(BOTTLE{}, test::ctx(scenario));
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         let admin_cap = test::take_from_address<AdminCap<BOTTLE>>(scenario, admin);
    //         let dispenser = test::take_shared<Dispenser<BOTTLE>>(scenario);
    //         let mint_cap = test::take_shared<MintCap<BOTTLE>>(scenario);

    //         let coin = coin::mint_for_testing<SUI>(1000000000, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 0, 10);
    //         activate_sale(&admin_cap, &mut dispenser, test::ctx(scenario));

    //         buy_rand_bottle(&mint_cap, &mut dispenser, option::none(), &mut coin, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 5000000, 10);

    //         test::return_to_address<AdminCap<BOTTLE>>(admin, admin_cap);
    //         test::return_shared<Dispenser<BOTTLE>>(dispenser);
    //         test::return_shared<MintCap<BOTTLE>>(mint_cap);
    //         transfer::transfer(coin, buyer);
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         assert!(test::has_most_recent_for_address<nft::Nft<BOTTLE>>(buyer), 0);
    //     };
    //     test::end(scenario_val);
    // }

    // #[test]
    // fun test_allowlist() {
    //     let buyer = @0xBABE;
    //     let admin = @0xCAFE;

    //     let scenario_val = test::begin(admin);
    //     let scenario = &mut scenario_val;
    //     {
    //         init(BOTTLE{}, test::ctx(scenario));
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         let admin_cap = test::take_from_address<AdminCap<BOTTLE>>(scenario, admin);
    //         let dispenser = test::take_shared<Dispenser<BOTTLE>>(scenario);
    //         let mint_cap = test::take_shared<MintCap<BOTTLE>>(scenario);

    //         let coin = coin::mint_for_testing<SUI>(1000000000, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 0, 10);
    //         activate_sale(&admin_cap, &mut dispenser, test::ctx(scenario));

    //         buy_rand_bottle(&mint_cap, &mut dispenser, &mut coin, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 5000000, 10);

    //         test::return_to_address<AdminCap<BOTTLE>>(admin, admin_cap);
    //         test::return_shared<Dispenser<BOTTLE>>(dispenser);
    //         test::return_shared<MintCap<BOTTLE>>(mint_cap);
    //         transfer::transfer(coin, buyer);
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         let nft = test::take_from_sender<nft::Nft<BOTTLE>>(scenario);
    //         transfer::transfer(nft, admin);
    //         // TODO: needs Safe implementation for allowlist to work
    //     };
    //     test::end(scenario_val);
    // }

    // #[test]
    // fun test_magic_number() {
    //     let buyer = @0xBABE;
    //     let admin = @0xCAFE;

    //     let scenario_val = test::begin(admin);
    //     let scenario = &mut scenario_val;
    //     {
    //         init(BOTTLE{}, test::ctx(scenario));
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         claim_filled_bottle(35340, test::ctx(scenario));
    //     };
    //     test::end(scenario_val);
    // }

}
