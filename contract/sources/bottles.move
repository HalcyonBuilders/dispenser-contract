module dispenser::bottles {
    use std::option;
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
    use sui::package;
    use sui::vec_set;

    use nft_protocol::nft::{Self, Nft};
    use nft_protocol::creators;
    use nft_protocol::mint_cap::{Self, MintCap};
    use nft_protocol::collection::{Self};
    use nft_protocol::display_info;
    use nft_protocol::witness;

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
    const ENotStarted: u64 = 10;
    const EEnded: u64 = 11;
    const EWrongName: u64 = 12;

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
        test_nft_name: string::String,
        test_coin: StructTag,
        mint_cap: MintCap<BOTTLES>,
    }

    // ========== structs ==========

    struct StructTag has store, copy, drop {
        package_id: ID,
        module_name: string::String,
        struct_name: string::String,
        generics: vector<string::String>, 
    }

    // ========== functions ==========

    fun init(otw: BOTTLES, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        let delegated_witness = witness::from_witness(Witness {});
        // create collection
        let collection = collection::create<BOTTLES>(delegated_witness, ctx);
        // Creates an unregulated mint cap
        let mint_cap = mint_cap::new_from_publisher(&publisher, &collection, option::none(), ctx);

        collection::add_domain(
            delegated_witness,
            &mut collection,
            creators::new(vec_set::singleton(tx_context::sender(ctx)))
        );
        collection::add_domain(
            delegated_witness,
            &mut collection,
            display_info::new(
                string::utf8(b"Bottles"),
                string::utf8(b"Filled and empty sui bottles earning you Wetlists for Thirsty Monkeys"),
            ),
        );
        collection::add_domain(
            delegated_witness,
            &mut collection,
            url::new_unsafe_from_bytes(b"https://halcyon.builders/dispenser"),
        );

        transfer::public_share_object(collection);
        transfer::share_object(
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
                    module_name: string::utf8(b""),
                    struct_name: string::utf8(b""),
                    generics: vector::empty<string::String>(),
                },
                test_nft_name: string::utf8(b""),
                test_coin: StructTag {
                    package_id: object::id_from_address(@0x0),
                    module_name: string::utf8(b""),
                    struct_name: string::utf8(b""),
                    generics: vector::empty<string::String>(),
                },
                mint_cap,
            }
        );
        transfer::transfer(
            AdminCap<BOTTLES> {
                id: object::new(ctx),
            }, 
            tx_context::sender(ctx)
        );

        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    // ========== entry functions ==========

    public entry fun give_random_bottles(
        _admin_cap: &AdminCap<BOTTLES>,
        dispenser: &mut Dispenser,
        recipients: vector<address>,
        ctx: &mut TxContext,
    ) {
        let (i, nb) = (0, vector::length(&recipients));
        while (i < nb) {
            let nft = mint_random(&mut dispenser.mint_cap, ctx);
            transfer::public_transfer(nft, vector::pop_back(&mut recipients));
        }
    }

    public entry fun give_filled_bottles(
        _admin_cap: &AdminCap<BOTTLES>,
        dispenser: &mut Dispenser,
        recipients: vector<address>,
        ctx: &mut TxContext,
    ) {
        let (i, nb) = (0, vector::length(&recipients));
        while (i < nb) {
            let nft = mint_filled(&mut dispenser.mint_cap, ctx);
            transfer::public_transfer(nft, vector::pop_back(&mut recipients));
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
        mint_and_send_random(&mut dispenser.mint_cap, ctx);
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
        transfer::public_transfer(coin::from_balance<C>(amount, ctx), BURN_ADDRESS);

        if (dispenser.supply != 0) dispenser.left = dispenser.left - 1;
        mint_and_send_random(&mut dispenser.mint_cap, ctx);
    }

    public entry fun claim_random_bottle(
        dispenser: &mut Dispenser,
        magic_nb: u64,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        mint_and_send_random(&mut dispenser.mint_cap, ctx);
    }

    public entry fun claim_filled_bottle(
        dispenser: &mut Dispenser,
        magic_nb: u64,
        ctx: &mut TxContext,
    ) {
        // verification has role on discord
        assert_is_verified(magic_nb, ctx);

        mint_and_send_filled(&mut dispenser.mint_cap, ctx);
    }

    public entry fun swap_nft<N>(
        dispenser: &mut Dispenser,
        nft: Nft<N>, 
        ctx: &mut TxContext,
    ) {
        assert!(is_same_type(&get_struct_tag<Nft<N>>(), &dispenser.test_nft), EWrongTestNft);
        assert!(nft::name<N>(&nft) == &dispenser.test_nft_name, EWrongName);

        transfer::public_transfer(nft, BURN_ADDRESS);
        mint_and_send_filled(&mut dispenser.mint_cap, ctx);
    }

    public entry fun recycle(
        dispenser: &mut Dispenser,
        b1: Nft<BOTTLES>,
        b2: Nft<BOTTLES>,
        b3: Nft<BOTTLES>,
        b4: Nft<BOTTLES>,
        b5: Nft<BOTTLES>,
        ctx: &mut TxContext,
    ) {
        transfer::public_transfer(b1, BURN_ADDRESS);
        transfer::public_transfer(b2, BURN_ADDRESS);
        transfer::public_transfer(b3, BURN_ADDRESS);
        transfer::public_transfer(b4, BURN_ADDRESS);
        transfer::public_transfer(b5, BURN_ADDRESS);

        mint_and_send_random(&mut dispenser.mint_cap, ctx);
    }

    public entry fun register_wetlist(
        filled: Nft<BOTTLES>, 
        ctx: &mut TxContext
    ) {
        assert!(nft::name(&filled) == &string::utf8(b"Filled Bottle"), ENotFilled);
        transfer::public_transfer(filled, BURN_ADDRESS);
        // event to retrieve and save the address in the database
        event::emit(AddressRegistered{addr: tx_context::sender(ctx)});
    }

    // ========== private functions ==========

    fun mint_and_send_random(
        mint_cap: &mut MintCap<BOTTLES>,
        ctx: &mut TxContext,
    ) { 
        let nft = mint_random(mint_cap, ctx);
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    fun mint_and_send_filled(
        mint_cap: &mut MintCap<BOTTLES>,
        ctx: &mut TxContext,
    ) { 
        let nft = mint_filled(mint_cap, ctx);
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    fun mint_and_send_empty(
        mint_cap: &mut MintCap<BOTTLES>,
        ctx: &mut TxContext,
    ) {
        let nft = mint_empty(mint_cap, ctx);
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    fun mint_random(
        mint_cap: &mut MintCap<BOTTLES>,
        ctx: &mut TxContext,
    ): Nft<BOTTLES> {
        let rand_nb = vector::borrow(&hash::sha3_256(vector::empty()), 0);
        let nft;
        if (*rand_nb < 1) {
            nft = mint_filled(mint_cap, ctx);
        } else {
            nft = mint_empty(mint_cap, ctx);
        };
        nft
    }

    fun mint_filled(
        mint_cap: &mut MintCap<BOTTLES>,
        ctx: &mut TxContext,
    ): Nft<BOTTLES> {
        let delegated_witness = witness::from_witness<BOTTLES, Witness>(Witness {});
        let name = string::utf8(b"Filled Bottle");
        let url = url::new_unsafe_from_bytes(b"https://i.postimg.cc/Rh0SbXhJ/Filled-Bottle.png");
        let description = string::utf8(b"This bottle filled with fresh water earns you a Wetlist, go burn it!");

        let nft = nft::from_mint_cap<BOTTLES>(mint_cap, name, url, ctx);

        nft::add_domain(delegated_witness, &mut nft, display_info::new(name, description));
        nft::add_domain(delegated_witness, &mut nft, url);
        nft::add_domain(delegated_witness, &mut nft, mint_cap::collection_id(mint_cap));

        let id = object::id(&nft);

        event::emit(RandomReceived{
            id,
            is_filled: true,
        });

        nft
    }

    fun mint_empty(
        mint_cap: &mut MintCap<BOTTLES>,
        ctx: &mut TxContext,
    ): Nft<BOTTLES> {
        let delegated_witness = witness::from_witness<BOTTLES, Witness>(Witness {});
        let name = string::utf8(b"Empty Bottle");
        let description = string::utf8(b"This bottle is empty and is worth nothing, maybe you could recycle it?");
        let url = url::new_unsafe_from_bytes(b"https://i.postimg.cc/tTxtnNpP/Empty-Bottle.png");
        
        let nft = nft::from_mint_cap<BOTTLES>(mint_cap, name, url, ctx);
    
        nft::add_domain(delegated_witness, &mut nft, display_info::new(name, description));
        nft::add_domain(delegated_witness, &mut nft, url);
        nft::add_domain(delegated_witness, &mut nft, mint_cap::collection_id(mint_cap));

        let id = object::id(&nft);

        event::emit(RandomReceived{
            id,
            is_filled: false,
        });

        nft
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
        transfer::transfer(admin, receiver);
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
        name: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let generics = string::utf8(gen1);
        string::append_utf8(&mut generics, b"::");
        string::append_utf8(&mut generics, gen2);
        string::append_utf8(&mut generics, b"::");
        string::append_utf8(&mut generics, gen3);
        
        dispenser.test_nft = StructTag {
            package_id,
            module_name: string::utf8(module_name),
            struct_name: string::utf8(struct_name),
            generics: vector[generics],
        };

        dispenser.test_nft_name = string::utf8(name);
    }

    public entry fun set_test_coin(
        _: &AdminCap<BOTTLES>, 
        dispenser: &mut Dispenser,
        gen1: vector<u8>,
        gen2: vector<u8>,
        gen3: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let generics = string::utf8(gen1);
        string::append_utf8(&mut generics, b"::");
        string::append_utf8(&mut generics, gen2);
        string::append_utf8(&mut generics, b"::");
        string::append_utf8(&mut generics, gen3);

        dispenser.test_coin = StructTag {
            package_id: object::id_from_address(@0x2),
            module_name: string::utf8(b"coin"),
            struct_name: string::utf8(b"Coin"),
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

        transfer::public_transfer(profits, receiver)
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
        assert!(dispenser.start_timestamp < time, ENotStarted); 
        assert!(dispenser.end_timestamp > time, EEnded);
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

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(BOTTLES {}, ctx)
    }
}