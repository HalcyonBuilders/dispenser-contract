module dispenser::bottle {
    use std::string;
    use std::vector;
    use std::hash;

    use sui::address;
    use sui::sui::SUI;
    use sui::coin;
    use sui::clock;
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, ID, UID};
    use sui::url;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use nft_protocol::nft;
    use nft_protocol::url as url_display;
    use nft_protocol::display;
    use nft_protocol::creators;
    use nft_protocol::mint_cap::{Self, MintCap};
    use nft_protocol::collection::{Self};

    use dispenser::parse;

    // ========== errors ==========

    const ESaleInactive: u64 = 0;
    const EFundsInsufficient: u64 = 1;
    const ENotVerified: u64 = 2;
    const ENoBottleLeft: u64 = 3;
    const ENotValidHexCharacter: u64 = 4;
    const EWrongTestNft: u64 = 5;
    const ENotFilled: u64 = 6;
    const ESaleNotStarted: u64 = 7;
    const ESaleEnded: u64 = 8;
    const EWrongTestCoin: u64 = 9;

    const BURN_ADDRESS: address = @0x09e26bc2ba60b37e6f06f3961a919da18feb5a2b;

    // ========== events ==========

    struct RandomReceived has copy, drop {
        id: ID,
        is_filled: bool,
    }

    struct AddressRegistered has copy, drop {addr: address}

    // ========== witnesses ==========

    struct BOTTLE has drop {}

    struct Witness has drop {}

    // ========== objects ==========

    struct AdminCap<phantom BOTTLE> has key {id: UID}

    struct Dispenser<phantom BOTTLE> has key {
        id: UID,
        active: bool,
        start_timestamp: u64,
        end_timestamp: u64,
        price: u64,
        price_in_coins: u64,
        balance: Balance<SUI>,
        supply: u64,
        left: u64,
        test_nft: StructTag,
        test_coin: StructTag,
    }

    // ========== structs ==========

    struct StructTag has store, copy, drop {
        package_id: ID,
        module_name: string::String,
        struct_name: string::String,
        generics: vector<string::String>, 
    }

    // ========== functions ==========

    fun init(witness: BOTTLE, ctx: &mut TxContext) {
        // create collection
        let (mint_cap, collection) = collection::create(&witness, ctx);

        collection::add_domain(
            &Witness {},
            &mut collection,
            creators::from_address<BOTTLE, Witness>(&Witness {}, tx_context::sender(ctx))
        );
        // Register custom domains
        display::add_collection_display_domain(
            &Witness {},
            &mut collection,
            string::utf8(b"Bottles"),
            string::utf8(b"Filled and empty water bottles earning you a Wetlist for Thirsty Monkeys"),
        );
        url_display::add_collection_url_domain(
            &Witness {},
            &mut collection,
            url::new_unsafe_from_bytes(b"https://halcyon.builders/"),
        );
        display::add_collection_symbol_domain(
            &Witness {},
            &mut collection,
            string::utf8(b"BOTTLES"),
        );

        transfer::share_object(collection);
        transfer::share_object(mint_cap);
        transfer::share_object(
            Dispenser<BOTTLE>{
                id: object::new(ctx),
                active: false,
                start_timestamp: 0,
                end_timestamp: 0,
                price: 5000000,
                price_in_coins: 5000000,
                balance: balance::zero(),
                supply: 0,
                left: 0,
                test_nft: StructTag {
                    package_id: object::id_from_bytes(b""),
                    module_name: string::utf8(b""),
                    struct_name: string::utf8(b""),
                    generics: vector::empty<string::String>(),
                },
                test_coin: StructTag {
                    package_id: object::id_from_bytes(b""),
                    module_name: string::utf8(b""),
                    struct_name: string::utf8(b""),
                    generics: vector::empty<string::String>(),
                },
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
        clock: &clock::Clock,
        ctx: &mut TxContext,
    ) {
        assert_is_active(dispenser, clock);
        assert!(dispenser.left > 0, ENoBottleLeft);
        assert!(coin::value(funds) >= dispenser.price, EFundsInsufficient);

        let balance = coin::balance_mut(funds);
        let amount = balance::split(balance, dispenser.price);
        balance::join(&mut dispenser.balance, amount);

        if (dispenser.supply != 0) dispenser.left = dispenser.left - 1;
        mint_and_send_random(mint_cap, ctx);
    }

    public entry fun buy_random_bottle_with_coins<C>(
        mint_cap: &MintCap<BOTTLE>,
        dispenser: &mut Dispenser<BOTTLE>,
        funds: &mut coin::Coin<C>,
        ctx: &mut TxContext,
    ) {
        assert!(coin::value(funds) >= dispenser.price_in_coins, EFundsInsufficient);
        assert!(get_struct_tag<coin::Coin<C>>() == dispenser.test_coin, EWrongTestCoin);

        let balance = coin::balance_mut(funds);
        let amount = balance::split(balance, dispenser.price);
        transfer::transfer(coin::from_balance<C>(amount, ctx), BURN_ADDRESS);

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

    public entry fun swap_monkey<N>(
        mint_cap: &MintCap<BOTTLE>,
        dispenser: &Dispenser<BOTTLE>,
        nft: nft::Nft<N>, 
        ctx: &mut TxContext,
    ) {
        assert!(get_struct_tag<nft::Nft<N>>() == dispenser.test_nft, 5);
        assert!(nft::name<N>(&nft) == &string::utf8(b"Wen Wetlist Monkey"), 5);

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

    public entry fun register_wetlist(
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
        let rand_nb = vector::borrow(&hash::sha3_256(vector::empty()), 0);
        if (*rand_nb < 1) {
            mint_and_send_filled(mint_cap, ctx);
        } else {
            mint_and_send_empty(mint_cap, ctx);
        };
    }

    fun mint_and_send_filled(
        mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) { 
        let name = string::utf8(b"Filled Bottle");
        let url = url::new_unsafe_from_bytes(b"https://i.postimg.cc/Rh0SbXhJ/Filled-Bottle.png");
        let description = string::utf8(b"This bottle filled with fresh water earns you a Wetlist, go burn it!");
    
        let nft = nft::from_mint_cap(mint_cap, name, url, ctx);

        display::add_display_domain(&Witness {}, &mut nft, name, description);
        url_display::add_url_domain(&Witness {}, &mut nft, url);
        display::add_collection_id_domain(
            &Witness {}, &mut nft, mint_cap::collection_id(mint_cap),
        );

        let id = object::id(&nft);

        event::emit(RandomReceived{
            id,
            is_filled: true,
        });

        transfer::transfer(nft, tx_context::sender(ctx));
    }

    fun mint_and_send_empty(
        mint_cap: &MintCap<BOTTLE>,
        ctx: &mut TxContext,
    ) {
        let name = string::utf8(b"Empty Bottle");
        let description = string::utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
        let url = url::new_unsafe_from_bytes(b"https://i.postimg.cc/tTxtnNpP/Empty-Bottle.png");
        
        let nft = nft::from_mint_cap(mint_cap, name, url, ctx);
    
        display::add_display_domain(&Witness {}, &mut nft, name, description);
        url_display::add_url_domain(&Witness {}, &mut nft, url);
        display::add_collection_id_domain(
            &Witness {}, &mut nft, mint_cap::collection_id(mint_cap),
        );

        let id = object::id(&nft);

        event::emit(RandomReceived{
            id,
            is_filled: false,
        });
        transfer::transfer(nft, tx_context::sender(ctx));
    }

    // ========== admin setup functions ==========

    public entry fun set_batch(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        start_timestamp: u64,
        end_timestamp: u64,
        price: u64,
        supply: u64,
        _ctx: &mut TxContext
    ) {
        dispenser.active = false;
        dispenser.start_timestamp = start_timestamp;
        dispenser.end_timestamp = end_timestamp;
        dispenser.price = price;
        dispenser.supply = supply;
    }

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

    public entry fun set_test_nft(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>, 
        package_id: ID,
        module_name: vector<u8>,
        struct_name: vector<u8>,
        gen1: vector<u8>,
        gen2: vector<u8>,
        gen3: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let generics = vector::empty<string::String>();
        vector::push_back(&mut generics, string::utf8(gen1));
        vector::push_back(&mut generics, string::utf8(gen2));
        vector::push_back(&mut generics, string::utf8(gen3));
        
        dispenser.test_nft = StructTag {
            package_id,
            module_name: string::utf8(module_name),
            struct_name: string::utf8(struct_name),
            generics,
        }
    }

    public entry fun set_test_coin(
        _: &AdminCap<BOTTLE>, 
        dispenser: &mut Dispenser<BOTTLE>,
        gen1: vector<u8>,
        gen2: vector<u8>,
        gen3: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let generics = vector::empty<string::String>();
        vector::push_back(&mut generics, string::utf8(gen1));
        vector::push_back(&mut generics, string::utf8(gen2));
        vector::push_back(&mut generics, string::utf8(gen3));

        dispenser.test_coin = StructTag {
            package_id: object::id_from_bytes(b"0000000000000000000000000000000000000002"),
            module_name: string::utf8(b"coin"),
            struct_name: string::utf8(b"Coin"),
            generics,
        }
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

    fun assert_is_active(dispenser: &Dispenser<BOTTLE>, clock: &clock::Clock) {
        assert!(dispenser.active, ESaleInactive);
        let time = clock::timestamp_ms(clock);
        assert!(
            dispenser.start_timestamp > time && 
            dispenser.end_timestamp < time, 
            ESaleInactive
        );
    }

    public fun get_struct_tag<T>(): StructTag {
        let (package_id, module_name, struct_name, generics) = parse::type_name_decomposed<T>();

        StructTag { package_id, module_name, struct_name, generics }
    }

    // ========== tests ==========

    // #[test_only]
    // use sui::test_scenario as test;

    // #[test_only]
    // const EWrongBalance: u64 = 10;
    // const ESetters: u64 = 11;

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

    //         // buy_random_bottle(&mint_cap, &mut dispenser, &mut coin, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 5000000, 10);
    //         claim_random_bottle(&mint_cap, 35340, test::ctx(scenario));
    //         claim_filled_bottle(&mint_cap, 35340, test::ctx(scenario));

    //         test::return_to_address<AdminCap<BOTTLE>>(admin, admin_cap);
    //         test::return_shared<Dispenser<BOTTLE>>(dispenser);
    //         test::return_shared<MintCap<BOTTLE>>(mint_cap);
    //         transfer::transfer(coin, buyer);
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         assert!(test::has_most_recent_for_address<nft::Nft<BOTTLE>>(buyer), 0);
    //         let filled = test::take_from_sender<nft::Nft<BOTTLE>>(scenario);
    //         register(filled, test::ctx(scenario));
    //     };
    //     test::end(scenario_val);
    // }

    // #[test]
    // fun test_admin_functions() {
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
    //         let monkey = test::take_shared<Monkey<BOTTLE>>(scenario);

    //         let coin = coin::mint_for_testing<SUI>(1000000000, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 0, 10);
    //         activate_sale(&admin_cap, &mut dispenser, test::ctx(scenario));

    //         // set_monkey(&admin_cap, &mut monkey, b"slkjf", b"slkjf", b"slkjf", b"slkjf", test::ctx(scenario));
    //         assert!(dispenser.price == 3000000 && dispenser.left == 2 && dispenser.supply == 2, 11);

    //         // buy_random_bottle(&mint_cap, &mut dispenser, &mut coin, &clock::Clock, test::ctx(scenario));
    //         assert!(balance::value<SUI>(&dispenser.balance) == 3000000, 10);
    //         // buy_random_bottle(&mint_cap, &mut dispenser, &mut coin, &clock::Clock, test::ctx(scenario));
    //         claim_filled_bottle(&mint_cap, 35340, test::ctx(scenario));
    //         claim_random_bottle(&mint_cap, 35340, test::ctx(scenario));

    //         test::return_to_address<AdminCap<BOTTLE>>(admin, admin_cap);
    //         test::return_shared<Dispenser<BOTTLE>>(dispenser);
    //         test::return_shared<MintCap<BOTTLE>>(mint_cap);
    //         test::return_shared<Monkey<BOTTLE>>(monkey);
    //         transfer::transfer(coin, buyer);
    //     };
    //     test::next_tx(scenario, buyer);
    //     {
    //         assert!(test::has_most_recent_for_address<nft::Nft<BOTTLE>>(buyer), 0);
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
