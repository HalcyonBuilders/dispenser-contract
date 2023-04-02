#[test_only]
module dispenser::test_bottle {
    use sui::test_scenario as test;
    use sui::coin;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::clock;

    use nft_protocol::nft;

    use dispenser::bottle::{Self, Dispenser, AdminCap};

    const EWrongBalance: u64 = 100;
    const ESetters: u64 = 101;
    const EHasNotNft: u64 = 102;

    const BUYER: address = @0xBABE;
    const ADMIN: address = @0xCAFE;

    struct Coin has drop {}

    fun init_scenario(): test::Scenario {
        let scenario = test::begin(ADMIN);

        bottle::init_for_testing(test::ctx(&mut scenario));
        clock::create_for_testing(test::ctx(&mut scenario));

        scenario
    }

    fun buy_random_bottle(
        active: bool, 
        start_timestamp: u64, 
        end_timestamp: u64, 
        price: u64, 
        supply: u64,
        timestamp: u64,
        sui: u64,
    ) {
        let scenario = init_scenario();
        test::next_tx(&mut scenario, ADMIN);
        {
            // activate sale
            let dispenser = test::take_shared<Dispenser>(&scenario);
            let admin_cap = test::take_from_address<AdminCap<bottle::BOTTLE>>(&scenario, ADMIN);
            bottle::set_batch(&admin_cap, &mut dispenser, active, start_timestamp, end_timestamp, price, supply, test::ctx(&mut scenario));
            test::return_to_address<AdminCap<bottle::BOTTLE>>(ADMIN, admin_cap);
            test::return_shared<Dispenser>(dispenser);
        };
        test::next_tx(&mut scenario, BUYER);
        {
            let dispenser = test::take_shared<Dispenser>(&scenario);
            let clock = test::take_shared<clock::Clock>(&scenario);
            clock::increment_for_testing(&mut clock, timestamp);
            let coins = coin::mint_for_testing<SUI>(sui, test::ctx(&mut scenario));

            bottle::buy_random_bottle(&mut dispenser, &mut coins, &clock, test::ctx(&mut scenario));
            assert!(bottle::get_dispenser_balance_value(&dispenser) == sui, 10);

            transfer::public_transfer(coins, BUYER);
            test::return_shared<Dispenser>(dispenser);
            test::return_shared<clock::Clock>(clock);
        };
        test::next_tx(&mut scenario, BUYER);
        {
            assert!(test::has_most_recent_for_address<nft::Nft<bottle::BOTTLE>>(BUYER), 13);
        };
        test::end(scenario);
    }

    #[test]
    fun test_buy_random_bottle() {
        buy_random_bottle(true, 0, 10, 1, 1, 1, 1);
    }

    #[test]
    #[expected_failure(abort_code = bottle::ESaleInactive)]
    fun error_inactive_buy_random_bottle() {
        buy_random_bottle(false, 0, 10, 1, 1, 1, 1);
    }

    #[test]
    #[expected_failure(abort_code = bottle::ESaleInactive)]
    fun error_ended_buy_random_bottle() {
        buy_random_bottle(true, 0, 0, 1, 1, 1, 1);
    }

    #[test]
    #[expected_failure(abort_code = bottle::ESaleInactive)]
    fun error_not_started_buy_random_bottle() {
        buy_random_bottle(true, 1, 10, 1, 1, 1, 1);
    }

    #[test]
    #[expected_failure(abort_code = bottle::ENoBottleLeft)]
    fun error_no_left_buy_random_bottle() {
        buy_random_bottle(true, 0, 10, 1, 0, 1, 1);
    }

    #[test]
    #[expected_failure(abort_code = bottle::EFundsInsufficient)]
    fun error_funds_buy_random_bottle() {
        buy_random_bottle(true, 0, 10, 1, 1, 1, 0);
    }

    // #[test]
    // fun test_mint_nft() {
    //     let scenario = init_scenario();
    //     test::next_tx(&mut scenario, BUYER);
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
    //         assert!(test::has_most_recent_for_address<nft::Nft<bottle::BOTTLE>>(BUYER), 13);
            // let filled = test::take_from_sender<nft::Nft<bottle::BOTTLE>>(&mut scenario);
            // bottle::register_wetlist(filled, test::ctx(&mut scenario));
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