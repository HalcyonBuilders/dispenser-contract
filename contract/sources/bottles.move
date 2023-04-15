module dispenser::bottles {
    use std::string::{Self, String, utf8};
    use std::vector;

    use sui::math;
    use sui::address;
    use sui::sui::SUI;
    use sui::coin;
    use sui::clock;
    use sui::display;
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, ID, UID};
    use sui::url;
    use sui::transfer::{public_transfer, transfer, public_share_object, share_object};
    use sui::tx_context::{Self, TxContext};
    use sui::package;

    use nft_protocol::collection::{Self};
    use nft_protocol::witness;

    use dispenser::parse;

    // ========== errors ==========

    const ESaleInactive: u64 = 0;
    const EFundsInsufficient: u64 = 1;
    const ENotVerified: u64 = 2;
    const ENoBottleLeft: u64 = 3;
    const EWrongTestNft: u64 = 4;
    const ESaleNotStarted: u64 = 5;
    const ESaleEnded: u64 = 6;
    const EWrongTestCoin: u64 = 7;
    const EBadRange: u64 = 8;
    const ETooFewBytes: u64 = 9;

    const BURN_ADDRESS: address = @0x4a3af36df1b20c8d79b31e50c07686c70d63310e4f9fff8d9f8b7f4eb703a2fd;

    // ========== events ==========

    struct RandomReceived has copy, drop {
        id: ID,
        is_filled: bool,
    }

    struct AddressRegistered has copy, drop {addr: address}

    // ========== witnesses ==========

    struct BOTTLES has drop {}

    struct Witness has drop {}

    // ========== objects ==========
    
    struct AdminCap<phantom BOTTLES> has key {id: UID}

    struct EmptyBottle has key, store {
        id: UID,
        name: String,
        description: String,
        url: url::Url,
    }

    struct FilledBottle has key, store {
        id: UID,
        name: String,
        description: String,
        url: url::Url,
    }

    struct Dispenser has key {
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
        module_name: String,
        struct_name: String,
        generics: vector<String>, 
    }

    // ========== functions ==========

    fun init(otw: BOTTLES, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        let sender = tx_context::sender(ctx);

        let display = display::new<EmptyBottle>(&publisher, ctx);
        display::add(&mut display, utf8(b"name"), utf8(b"{name}"));
        display::add(&mut display, utf8(b"description"), utf8(b"{description}"));
        display::add(&mut display, utf8(b"image_url"), utf8(b"{url}"));
        display::update_version(&mut display);
        public_transfer(display, sender);

        let display = display::new<FilledBottle>(&publisher, ctx);
        display::add(&mut display, utf8(b"name"), utf8(b"{name}"));
        display::add(&mut display, utf8(b"description"), utf8(b"{description}"));
        display::add(&mut display, utf8(b"image_url"), utf8(b"{url}"));
        display::update_version(&mut display);
        public_transfer(display, sender);

        let empty_dw = witness::from_witness(Witness {});
        let empty_collection = collection::create<EmptyBottle>(empty_dw, ctx);
        collection::add_domain(
            empty_dw,
            &mut empty_collection,
            url::new_unsafe_from_bytes(b"https://halcyon.builders/dispenser"),
        );
        public_share_object(empty_collection);

        let filled_dw = witness::from_witness(Witness {});
        let filled_collection = collection::create<FilledBottle>(filled_dw, ctx);
        collection::add_domain(
            filled_dw,
            &mut filled_collection,
            url::new_unsafe_from_bytes(b"https://halcyon.builders/dispenser"),
        );
        public_share_object(filled_collection);

        share_object(
            Dispenser{
                id: object::new(ctx),
                active: false,
                start_timestamp: 0,
                end_timestamp: 0,
                price: 0,
                price_in_coins: 0,
                balance: balance::zero(),
                supply: 0,
                left: 0,
                test_nft: StructTag {
                    package_id: object::id_from_address(@0x0),
                    module_name: utf8(b""),
                    struct_name: utf8(b""),
                    generics: vector::empty<String>(),
                },
                test_coin: StructTag {
                    package_id: object::id_from_address(@0x0),
                    module_name: utf8(b""),
                    struct_name: utf8(b""),
                    generics: vector::empty<String>(),
                },
            }
        );
        transfer(
            AdminCap<BOTTLES> {
                id: object::new(ctx),
            }, 
            sender
        );

        public_transfer(publisher, sender);
    }

    // ========== entry functions ==========

    public entry fun give_random_bottles(
        _admin_cap: &AdminCap<BOTTLES>,
        receivers: vector<address>,
        ctx: &mut TxContext,
    ) {
        let (i, nb) = (0, vector::length(&receivers));
        while (i < nb) {
            mint_and_send_random(vector::pop_back(&mut receivers), ctx);
            i = i + 1;
        }
    }

    public entry fun give_filled_bottles(
        _admin_cap: &AdminCap<BOTTLES>,
        receivers: vector<address>,
        ctx: &mut TxContext,
    ) {
        let (i, nb) = (0, vector::length(&receivers));
        while (i < nb) {
            mint_and_send_filled(vector::pop_back(&mut receivers), ctx);
            i = i + 1;
        }
    }

    public entry fun buy_random_bottle(
        dispenser: &mut Dispenser,
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
        mint_and_send_random(tx_context::sender(ctx), ctx);
    }

    public entry fun buy_random_bottle_with_coins<C>(
        dispenser: &mut Dispenser,
        funds: &mut coin::Coin<C>,
        clock: &clock::Clock,
        ctx: &mut TxContext,
    ) {
        assert_is_active(dispenser, clock);
        assert!(dispenser.left > 0, ENoBottleLeft);
        assert!(coin::value(funds) >= dispenser.price_in_coins, EFundsInsufficient);
        assert!(is_same_type(&get_struct_tag<coin::Coin<C>>(), &dispenser.test_coin), EWrongTestCoin);

        let balance = coin::balance_mut(funds);
        let amount = balance::split(balance, dispenser.price_in_coins);
        public_transfer(coin::from_balance<C>(amount, ctx), BURN_ADDRESS);

        if (dispenser.supply != 0) dispenser.left = dispenser.left - 1;
        mint_and_send_random(tx_context::sender(ctx), ctx);
    }

    public entry fun claim_random_bottle(
        magic_nb: u64,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        mint_and_send_random(tx_context::sender(ctx), ctx);
    }

    public entry fun claim_filled_bottle(
        magic_nb: u64,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        mint_and_send_filled(tx_context::sender(ctx), ctx);
    }

    public entry fun swap_nft<N: key + store>(
        dispenser: &mut Dispenser,
        nft: N,
        ctx: &mut TxContext,
    ) {
        assert!(is_same_type(&get_struct_tag<N>(), &dispenser.test_nft), EWrongTestNft);

        public_transfer(nft, BURN_ADDRESS);
        mint_and_send_filled(tx_context::sender(ctx), ctx);
    }

    public entry fun recycle(
        b1: EmptyBottle,
        b2: EmptyBottle,
        b3: EmptyBottle,
        b4: EmptyBottle,
        b5: EmptyBottle,
        ctx: &mut TxContext,
    ) {
        public_transfer(b1, BURN_ADDRESS);
        public_transfer(b2, BURN_ADDRESS);
        public_transfer(b3, BURN_ADDRESS);
        public_transfer(b4, BURN_ADDRESS);
        public_transfer(b5, BURN_ADDRESS);

        mint_and_send_random(tx_context::sender(ctx), ctx);
    }

    public entry fun register_wetlist(
        filled: FilledBottle,
        ctx: &mut TxContext
    ) {
        public_transfer(filled, BURN_ADDRESS);
        // event to retrieve and save the address in the database
        event::emit(AddressRegistered{addr: tx_context::sender(ctx)});
    }

    // ========== private functions ==========

    fun mint_and_send_random(
        receiver: address,
        ctx: &mut TxContext,
    ) { 
        let rand_nb = random_from_range(0, 10, ctx);
        if (rand_nb < 1) {
            mint_and_send_filled(receiver, ctx);
        } else {
            mint_and_send_empty(receiver, ctx);
        };
    }

    fun mint_and_send_filled(
        receiver: address,
        ctx: &mut TxContext,
    ) {
        let name = utf8(b"Filled Bottle");
        let url = url::new_unsafe_from_bytes(b"https://i.postimg.cc/Rh0SbXhJ/Filled-Bottle.png");
        let description = utf8(b"This bottle filled with fresh water earns you a Wetlist, go burn it!");

        let nft = FilledBottle {
            id: object::new(ctx),
            name,
            description,
            url,
        };

        let id = object::id(&nft);

        event::emit(RandomReceived{
            id,
            is_filled: true,
        });

        public_transfer(nft, receiver);
    }

    fun mint_and_send_empty(
        receiver: address,
        ctx: &mut TxContext,
    ) {
        let name = utf8(b"Empty Bottle");
        let description = utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
        let url = url::new_unsafe_from_bytes(b"https://i.postimg.cc/tTxtnNpP/Empty-Bottle.png");
        
        let nft = EmptyBottle {
            id: object::new(ctx),
            name,
            description,
            url,
        };
    
        let id = object::id(&nft);

        event::emit(RandomReceived{
            id,
            is_filled: false,
        });

        public_transfer(nft, receiver);
    }

    // ========== admin setup functions ==========

    public entry fun set_batch(
        _: &AdminCap<BOTTLES>, 
        dispenser: &mut Dispenser, 
        active: bool,
        start_timestamp: u64,
        end_timestamp: u64,
        price: u64,
        price_in_coins: u64,
        supply: u64,
        _ctx: &mut TxContext
    ) {
        dispenser.active = active;
        dispenser.start_timestamp = start_timestamp;
        dispenser.end_timestamp = end_timestamp;
        dispenser.price = price;
        dispenser.price_in_coins = price_in_coins;
        dispenser.supply = supply;
        dispenser.left = supply;
    }

    public entry fun transfer_admin_cap(
        admin: AdminCap<BOTTLES>, 
        receiver: address, 
        _ctx: &mut TxContext
    ) {
        transfer(admin, receiver);
    }

    public entry fun activate_sale(
        _: &AdminCap<BOTTLES>, 
        dispenser: &mut Dispenser, 
        _ctx: &mut TxContext
    ) {
        dispenser.active = true;
    }

    public entry fun deactivate_sale(
        _: &AdminCap<BOTTLES>, 
        dispenser: &mut Dispenser, 
        _ctx: &mut TxContext
    ) {
        dispenser.active = false;
    }

    public entry fun set_test_nft(
        _: &AdminCap<BOTTLES>, 
        dispenser: &mut Dispenser, 
        package_id: ID,
        module_name: vector<u8>,
        struct_name: vector<u8>,
        gen1: vector<u8>,
        gen2: vector<u8>,
        gen3: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let generics = utf8(gen1);
        if (!vector::is_empty(&gen1) && !vector::is_empty(&gen2)) {
            string::append_utf8(&mut generics, b"::");
            string::append_utf8(&mut generics, gen2);
            if (!vector::is_empty(&gen3)) {
                string::append_utf8(&mut generics, b"::");
                string::append_utf8(&mut generics, gen3);
            }
        };
        
        dispenser.test_nft = StructTag {
            package_id,
            module_name: utf8(module_name),
            struct_name: utf8(struct_name),
            generics: vector[generics],
        };
    }

    public entry fun set_test_coin(
        _: &AdminCap<BOTTLES>, 
        dispenser: &mut Dispenser,
        gen1: vector<u8>,
        gen2: vector<u8>,
        gen3: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let generics = utf8(gen1);
        string::append_utf8(&mut generics, b"::");
        string::append_utf8(&mut generics, gen2);
        string::append_utf8(&mut generics, b"::");
        string::append_utf8(&mut generics, gen3);

        dispenser.test_coin = StructTag {
            package_id: object::id_from_address(@0x2),
            module_name: utf8(b"coin"),
            struct_name: utf8(b"Coin"),
            generics: vector[generics],
        };
    }

    public entry fun collect_profits(
        _: &AdminCap<BOTTLES>,
        dispenser: &mut Dispenser,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let amount = balance::value(&dispenser.balance);
        let profits = coin::take(&mut dispenser.balance, amount, ctx);

        public_transfer(profits, receiver)
    }

    // ========== utils ==========

    fun assert_is_verified(magic_nb: u64, ctx: &mut TxContext) {
        let addr_in_bytes = address::to_bytes(tx_context::sender(ctx));
        let b20_in_dec = vector::pop_back<u8>(&mut addr_in_bytes);
        let b19_in_dec = vector::pop_back<u8>(&mut addr_in_bytes);
        let multiplied = ((b20_in_dec as u64) * (b19_in_dec as u64));
        assert!(multiplied == magic_nb, ENotVerified);
    }

    fun assert_is_active(dispenser: &Dispenser, clock: &clock::Clock) {
        assert!(dispenser.active, ESaleInactive);
        let time = clock::timestamp_ms(clock);
        assert!(dispenser.start_timestamp < time, ESaleNotStarted); 
        assert!(dispenser.end_timestamp > time, ESaleEnded);
    }

    fun get_struct_tag<T>(): StructTag {
        let (package_id, module_name, struct_name, generics) = parse::type_name_decomposed<T>();

        StructTag { package_id, module_name, struct_name, generics }
    }

    fun is_same_type(type1: &StructTag, type2: &StructTag): bool {
        (type1.package_id == type2.package_id
            && type1.module_name == type2.module_name
            && type1.struct_name == type2.struct_name
            && type1.generics == type2.generics)
    }

    public fun get_dispenser_balance_value(dispenser: &Dispenser): u64 {
        balance::value(&dispenser.balance)
    }

    fun random_from_range(min: u64, max: u64, ctx: &mut TxContext): u64 {
        assert!(max > min, EBadRange);

        let uid = object::new(ctx);
        let bytes = object::uid_to_bytes(&uid);
        object::delete(uid);

        let num = from_bytes(bytes);
        num % (max - min) + min
    }

    fun from_bytes(bytes: vector<u8>): u64 {
        assert!(vector::length(&bytes) >= 8, ETooFewBytes);

        let i: u8 = 0;
        let sum: u64 = 0;
        while (i < 8) {
            sum = sum + (*vector::borrow(&bytes, (i as u64)) as u64) * math::pow(2, (7 - i) * 8);
            i = i + 1;
        };

        sum
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(BOTTLES {}, ctx)
    }
}