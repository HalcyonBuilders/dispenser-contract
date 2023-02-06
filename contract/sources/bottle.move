module dispenser::bottle {
    use std::string;
    use std::vector;

    use sui::address;
    use sui::sui::SUI;
    use sui::coin;
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, ID, UID};
    use sui::url;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use originmate::pseudorandom::rand_u64_range_no_counter;

    use nft_protocol::nft;
    use nft_protocol::display;
    use nft_protocol::creators;
    use nft_protocol::mint_cap::{MintCap};
    use nft_protocol::collection::{Self};
    use nft_protocol::utils;

    // ========== errors ==========

    const ESaleInactive: u64 = 0;
    const EFundsInsufficient: u64 = 1;
    const ENotVerified: u64 = 2;
    const ENoBottleLeft: u64 = 3;
    const ENotValidHexCharacter: u64 = 4;
    const EWrongMonkey: u64 = 5;
    const ENotFilled: u64 = 6;

    const BURN_ADDRESS: address = @0xaacfea8d66fe120dae87ac8a7924fe5c510f1c3a;

    // ========== events ==========

    struct FilledReceived has copy, drop {id: ID}
    struct EmptyReceived has copy, drop {id: ID}
    struct AddressRegistered has copy, drop {addr: address}

    // ========== objects ==========

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
    struct Monkey<phantom BOTTLE> has key {
        id: UID,
        nft_package: string::String,
        nft_module: string::String,
        nft_type: string::String,
        nft_name: string::String,
    }

    fun init(witness: BOTTLE, ctx: &mut TxContext) {
        // create collection
        let (mint_cap, collection) = collection::create(&witness, ctx);
        let delegated_witness = nft_protocol::witness::from_witness(&witness);

        collection::add_domain(
            delegated_witness,
            &mut collection,
            creators::from_address(&witness, tx_context::sender(ctx), ctx)
        );
        // Register custom domains
        display::add_collection_display_domain(
            delegated_witness,
            &mut collection,
            string::utf8(b"Bottles"),
            string::utf8(b"Filled and empty water bottles earning you a Wetlist for Thirsty Monkeys"),
            ctx
        );
        display::add_collection_url_domain(
            delegated_witness,
            &mut collection,
            url::new_unsafe_from_bytes(b"https://halcyon.builders/"),
            ctx
        );
        display::add_collection_symbol_domain(
            delegated_witness,
            &mut collection,
            string::utf8(b"BOTTLES"),
            ctx
        );

        transfer::share_object(collection);
        transfer::share_object(mint_cap);
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
        transfer::share_object(
            Monkey<BOTTLE>{
                id: object::new(ctx),
                nft_package: string::utf8(b""),
                nft_module: string::utf8(b""),
                nft_type: string::utf8(b""),
                nft_name: string::utf8(b"")
            }
        );
        transfer::transfer(
            AdminCap<BOTTLE> {
                id: object::new(ctx),
            }, 
            tx_context::sender(ctx)
        );
    }

    // ========== entry functions ==========

    public entry fun buy_random_bottle(
        mint_cap: &MintCap<BOTTLE>,
        dispenser: &mut Dispenser<BOTTLE>,
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

        if (dispenser.supply != 0) dispenser.left = dispenser.left - 1;
        mint_and_send_random(mint_cap, ctx);
    }

    public entry fun claim_random_bottle(
        mint_cap: &MintCap<BOTTLE>,
        magic_nb: u64,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        mint_and_send_random(mint_cap, ctx);
    }

    public entry fun claim_filled_bottle(
        mint_cap: &MintCap<BOTTLE>,
        magic_nb: u64,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        mint_and_send_filled(mint_cap, ctx);
    }

    public entry fun swap_monkey<M: key, store>(
        mint_cap: &MintCap<BOTTLE>,
        monkey: &Monkey<BOTTLE>, 
        nft: nft::Nft<M>, 
        ctx: &mut TxContext,
    ) {
        let (
            nft_package, 
            nft_module, 
            nft_type
        ) = utils::get_package_module_type<nft::Nft<M>>();
        
        let domain = nft::borrow_domain<M, display::DisplayDomain>(&nft);

        assert!(
            monkey.nft_package == nft_package && 
            monkey.nft_module == nft_module && 
            monkey.nft_type == nft_type &&
            display::name(domain) == &monkey.nft_name,
            5
        );


        transfer::transfer(nft, BURN_ADDRESS);
        mint_and_send_filled(mint_cap, ctx);
    }

    public entry fun recycle(
        mint_cap: &MintCap<BOTTLE>,
        b1: nft::Nft<BOTTLE>,
        b2: nft::Nft<BOTTLE>,
        b3: nft::Nft<BOTTLE>,
        b4: nft::Nft<BOTTLE>,
        b5: nft::Nft<BOTTLE>,
        ctx: &mut TxContext,
    ) {
        transfer::transfer(b1, BURN_ADDRESS);
        transfer::transfer(b2, BURN_ADDRESS);
        transfer::transfer(b3, BURN_ADDRESS);
        transfer::transfer(b4, BURN_ADDRESS);
        transfer::transfer(b5, BURN_ADDRESS);

        mint_and_send_random(mint_cap, ctx);
    }

    public entry fun register(
        filled: nft::Nft<BOTTLE>, 
        ctx: &mut TxContext
    ) {
        let domain = nft::borrow_domain<BOTTLE, display::DisplayDomain>(&filled);
        assert!(display::name(domain) == &string::utf8(b"Filled Bottle"), ENotFilled);
        transfer::transfer(filled, BURN_ADDRESS);
        // event to retrieve and save the address in the database
        event::emit(AddressRegistered{addr: tx_context::sender(ctx)});
    }

    // ========== private functions ==========

    fun mint_and_send_random(
        mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) {
        let rand_nb = rand_u64_range_no_counter(&tx_context::sender(ctx), 0, 10, ctx);
        if (rand_nb < 1) {
            mint_and_send_filled(mint_cap, ctx);
        } else {
            mint_and_send_empty(mint_cap, ctx);
        };
    }

    fun mint_and_send_filled(
        mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) { 
        let nft = nft::new<BOTTLE>(mint_cap, tx_context::sender(ctx), ctx);

        let name = string::utf8(b"Filled Bottle");
        let description = string::utf8(b"This bottle filled with cool water earn you a Wetlist, go burn it!");
        let url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/5259d912-c344-4d70-9b56-01cf2d49a027/bouteille.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152027Z&X-Amz-Expires=86400&X-Amz-Signature=2dba4fdf029485d81ce063b1c42ba7b10de6f2a06363662de9eb2fddcd79e876&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22bouteille.png%22&x-id=GetObject");
    
        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        transfer::transfer(nft, tx_context::sender(ctx));
    }

    fun mint_and_send_empty(
        mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) {
        let nft = nft::new<BOTTLE>(mint_cap, tx_context::sender(ctx), ctx);

        let name = string::utf8(b"Empty Bottle");
        let description = string::utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
        let url = url::new_unsafe_from_bytes(b"https://s3.us-west-2.amazonaws.com/secure.notion-static.com/15a31d77-8c67-4be6-a7f1-1e5300c71515/Bottle8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20230112%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20230112T152059Z&X-Amz-Expires=86400&X-Amz-Signature=3b1b1b27528d44c92bfd2ad66f308564e89dba0df56c4a5dda214819fcaedbcd&X-Amz-SignedHeaders=host&response-content-disposition=filename%3D%22Bottle8.png%22&x-id=GetObject");
    
        display::add_display_domain(&mut nft, name, description, ctx);
        display::add_url_domain(&mut nft, url, ctx);

        transfer::transfer(nft, tx_context::sender(ctx));
    }

    // ========== admin setup functions ==========

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

    public entry fun set_monkey(
        _: &AdminCap<BOTTLE>, 
        monkey: &mut Monkey<BOTTLE>, 
        nft_package: vector<u8>,
        nft_module: vector<u8>,
        nft_type: vector<u8>,
        nft_name: vector<u8>,
        _ctx: &mut TxContext
    ) {
        monkey.nft_package = string::utf8(nft_package);
        monkey.nft_module = string::utf8(nft_module);
        monkey.nft_type = string::utf8(nft_package);
        string::append_utf8(&mut monkey.nft_type, nft_type);
        monkey.nft_name = string::utf8(nft_name);
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

    // ========== utils ==========

    fun assert_is_verified(magic_nb: u64, ctx: &mut TxContext) {
        let addr_in_bytes = address::to_bytes(tx_context::sender(ctx));
        let b20_in_dec = vector::pop_back<u8>(&mut addr_in_bytes);
        let b19_in_dec = vector::pop_back<u8>(&mut addr_in_bytes);
        let multiplied = ((b20_in_dec as u64) * (b19_in_dec as u64));
        assert!(multiplied == magic_nb, ENotVerified);
    }

    // ========== tests ==========

    #[test_only]
    use sui::test_scenario as test;

    #[test_only]
    const EWrongBalance: u64 = 10;
    const ESetters: u64 = 11;

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
            let admin_cap = test::take_from_address<AdminCap<BOTTLE>>(scenario, admin);
            let dispenser = test::take_shared<Dispenser<BOTTLE>>(scenario);
            let mint_cap = test::take_shared<MintCap<BOTTLE>>(scenario);

            let coin = coin::mint_for_testing<SUI>(1000000000, test::ctx(scenario));
            assert!(balance::value<SUI>(&dispenser.balance) == 0, 10);
            activate_sale(&admin_cap, &mut dispenser, test::ctx(scenario));

            buy_random_bottle(&mint_cap, &mut dispenser, &mut coin, test::ctx(scenario));
            assert!(balance::value<SUI>(&dispenser.balance) == 5000000, 10);
            claim_random_bottle(&mint_cap, 35340, test::ctx(scenario));
            claim_filled_bottle(&mint_cap, 35340, test::ctx(scenario));

            test::return_to_address<AdminCap<BOTTLE>>(admin, admin_cap);
            test::return_shared<Dispenser<BOTTLE>>(dispenser);
            test::return_shared<MintCap<BOTTLE>>(mint_cap);
            transfer::transfer(coin, buyer);
        };
        test::next_tx(scenario, buyer);
        {
            assert!(test::has_most_recent_for_address<nft::Nft<BOTTLE>>(buyer), 0);
            let filled = test::take_from_sender<nft::Nft<BOTTLE>>(scenario);
            register(filled, test::ctx(scenario));
        };
        test::end(scenario_val);
    }

    #[test]
    fun test_admin_functions() {
        let buyer = @0xBABE;
        let admin = @0xCAFE;

        let scenario_val = test::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(BOTTLE{}, test::ctx(scenario));
        };
        test::next_tx(scenario, buyer);
        {
            let admin_cap = test::take_from_address<AdminCap<BOTTLE>>(scenario, admin);
            let dispenser = test::take_shared<Dispenser<BOTTLE>>(scenario);
            let mint_cap = test::take_shared<MintCap<BOTTLE>>(scenario);
            let monkey = test::take_shared<Monkey<BOTTLE>>(scenario);

            let coin = coin::mint_for_testing<SUI>(1000000000, test::ctx(scenario));
            assert!(balance::value<SUI>(&dispenser.balance) == 0, 10);
            activate_sale(&admin_cap, &mut dispenser, test::ctx(scenario));

            set_price(&admin_cap, &mut dispenser, 3000000, test::ctx(scenario));
            set_supply(&admin_cap, &mut dispenser, 2, test::ctx(scenario));
            set_monkey(&admin_cap, &mut monkey, b"slkjf", b"slkjf", b"slkjf", b"slkjf", test::ctx(scenario));
            assert!(dispenser.price == 3000000 && dispenser.left == 2 && dispenser.supply == 2, 11);

            buy_random_bottle(&mint_cap, &mut dispenser, &mut coin, test::ctx(scenario));
            assert!(balance::value<SUI>(&dispenser.balance) == 3000000, 10);
            buy_random_bottle(&mint_cap, &mut dispenser, &mut coin, test::ctx(scenario));
            claim_filled_bottle(&mint_cap, 35340, test::ctx(scenario));
            claim_random_bottle(&mint_cap, 35340, test::ctx(scenario));

            test::return_to_address<AdminCap<BOTTLE>>(admin, admin_cap);
            test::return_shared<Dispenser<BOTTLE>>(dispenser);
            test::return_shared<MintCap<BOTTLE>>(mint_cap);
            test::return_shared<Monkey<BOTTLE>>(monkey);
            transfer::transfer(coin, buyer);
        };
        test::next_tx(scenario, buyer);
        {
            assert!(test::has_most_recent_for_address<nft::Nft<BOTTLE>>(buyer), 0);
        };
        test::end(scenario_val);
    }


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
