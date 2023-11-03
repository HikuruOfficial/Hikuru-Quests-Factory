import credits.leo;

// This example demonstrates - still in developments
program hikuru_quests_factory.aleo {

    // The Title and description is ascii text represented in bits, and the u128 value of the bitstring.
    struct Title {
        data0: u128,
        data1: u128,
        data2: u128,
        data3: u128
    }
    struct Description {
        data0: u128,
        data1: u128,
        data2: u128,
        data3: u128,
        data4: u128,
        data5: u128,
        data6: u128,
        data7: u128
    }

    struct Quest {
        creator: address;
        reward_contract: address;
        title: Title;
        description: Description;
        quests_reward_type: u128;
        end_time: u128;
        hikuru_qid: u128;
        max_participation: u128;
        participants_count: u128;
        max_reward_per_user: u64;
        total_reward_pool: u64;
        is_completed: bool;
        with_reward: bool;
        referral_system: bool;
    }


    struct QuestParticipant {
        quest_id: u64;
        hikuru_qid: u128;
        quests_participant_id: u128;
    }


    mapping quests: u64 =>  Quest;

    mapping factory_settings: u8 => u64;
    // 0u8 - is active
    // 1u8 - fee amount
    // 2u8 - quests amount
    mapping owners: address => bool;
    // mapping hikuru_piggy_bank: u8  => address;

    // mapping (quest_id, hikuru_qid, quests_participant_id) => address;
    mapping quests_participants: field => address;



    transition initialize_factory () {
        assert_eq(self.caller, aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl);
        return then finalize();
    }

    finalize initialize_factory () {
        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_initialized: u64 = factory_settings_status & 1u64;

        // initialization allowed only once
        assert_eq(is_initialized, 0u64);

        // set default owner
        owners.set(aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl, true);

        // set factory is active
        factory_settings.set(0u8, 1u64);
        factory_settings.set(1u8, 10_000_000u64); // set default hikuru fees to 10 aleo credit

    }

    transition change_owner_status(editable_address: address, new_status: bool){
        return then finalize(editable_address, new_status, self.caller);
    }
    finalize change_owner_status (editable_address: address, new_status: bool, caller: address) {
        let caller_status: bool = owners.get_or_use(caller, false);
        assert_eq(caller_status, true); // only old owner can change status and grand to someone

        // set new status for editable_address
        owners.set(editable_address, new_status);
    }

    transition change_factory_status(editable_index: u8, new_status: u64){
        return then finalize(editable_index, new_status, self.caller);
    }
    finalize change_factory_status (editable_index: u8, new_status: u64, caller: address) {
        let caller_status: bool = owners.get_or_use(caller, false);
        assert_eq(caller_status, true); // only owner can modify settings

        // set new status for editable_index
        factory_settings.set(editable_index, new_status);
    }



    transition quest_creation_public (
    //   s: signature,
    //   a: address,
    //   v: field,
      reward_contract: address,
      title: Title,
      description: Description,
      quests_reward_type: u128,
      end_time: u128,
      hikuru_qid: u128,
      max_participation: u128,
      participants_count: u128,
      max_reward_per_user: u64,
      total_reward_pool: u64,
      is_completed: bool,
      with_reward: bool,
    ) -> Quest {
        //  let first: bool = signature::verify(s, a, v);
        //  let second: bool = s.verify(a, v);
        //  assert_eq(first, second);


        credits.leo/transfer_public(
            aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl,
            10_000_000u64 + total_reward_pool
        );


        assert_eq(max_participation>0u128, true); // cant be ZERO


        let quest: Quest = Quest {
            creator: self.caller,
            reward_contract: reward_contract,
            title: title,
            description: description,
            quests_reward_type: quests_reward_type,
            end_time: end_time,
            hikuru_qid: hikuru_qid,
            max_participation: max_participation,
            participants_count: participants_count,
            max_reward_per_user: max_reward_per_user,
            total_reward_pool: total_reward_pool,
            is_completed: is_completed,
            with_reward: with_reward,
            referral_system: false,
        };

        return quest then finalize(quest);
    }

    finalize quest_creation_public(quest: Quest) {
        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_active: u64 = factory_settings_status & 1u64;
        assert_eq(is_active, 1u64); // check is active

        let quests_id: u64 = factory_settings.get_or_use(2u8, 0u64);
        let new_quests_id: u64 = quests_id + 1u64;

        factory_settings.set(2u8, new_quests_id);
        quests.set(new_quests_id, quest);
    }

    transition quest_creation_private (
    //   s: signature,
    //   a: address,
    //   v: field,
      reward_contract: address,
      title: Title,
      description: Description,
      quests_reward_type: u128,
      end_time: u128,
      hikuru_qid: u128,
      max_participation: u128,
      participants_count: u128,
      max_reward_per_user: u64,
      total_reward_pool: u64,
      is_completed: bool,
      with_reward: bool,
      private payment: credits.leo/credits

    ) -> (Quest, credits.leo/credits) {
        //  let first: bool = signature::verify(s, a, v);
        //  let second: bool = s.verify(a, v);
        //  assert_eq(first, second);

        let aleo_change: credits = credits.leo/transfer_private_to_public(
            payment,
            aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl,
            10_000_000u64 + total_reward_pool
        );

        let quest: Quest = Quest {
            creator: self.caller,
            reward_contract: reward_contract,
            title: title,
            description: description,
            quests_reward_type: quests_reward_type,
            end_time: end_time,
            hikuru_qid: hikuru_qid,
            max_participation: max_participation,
            participants_count: participants_count,
            max_reward_per_user: max_reward_per_user,
            total_reward_pool: total_reward_pool,
            is_completed: is_completed,
            with_reward: with_reward,
            referral_system: false,
        };

        return (quest, aleo_change) then finalize(quest);
    }

    finalize quest_creation_private(quest: Quest) {
        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_active: u64 = factory_settings_status & 1u64;
        assert_eq(is_active, 1u64); // check is active

        // let piggy_bank: address = hikuru_piggy_bank.get_or_use(0u8, aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl);
        // let amount: u64 = factory_settings.get_or_use(1u8, 6000000u64);


        let quests_id: u64 = factory_settings.get_or_use(2u8, 0u64);
        let new_quests_id: u64 = quests_id + 1u64;

        factory_settings.set(2u8, new_quests_id);
        quests.set(new_quests_id, quest);
    }





    transition select_random_winners(quest_id:u64, time_now: u128) {
        return then finalize(quest_id, time_now, self.caller);
    }

    finalize select_random_winners(quest_id:u64, time_now: u128, caller:address) {
        let caller_status: bool = owners.get_or_use(caller, false);
        assert_eq(caller_status, true); // only old owner can change status and grand to someone

        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_active: u64 = factory_settings_status & 1u64;
        assert_eq(is_active, 1u64); // check is active



        let contains: bool = quests.contains(quest_id);
        assert_eq(contains, true); // quest not exist

        let quest: Quest = quests.get(quest_id);
        assert_eq(quest.end_time<=time_now, false); // quest not finished yet

        let finished_quest: Quest = Quest {
            creator: quest.creator,
            reward_contract: quest.reward_contract,
            title: quest.title,
            description: quest.description,
            quests_reward_type: quest.quests_reward_type,
            end_time: quest.end_time,
            hikuru_qid: quest.hikuru_qid,
            max_participation: quest.max_participation,
            participants_count: quest.participants_count,
            max_reward_per_user: quest.max_reward_per_user,
            total_reward_pool: quest.total_reward_pool,
            is_completed: true,
            with_reward: quest.with_reward,
            referral_system: quest.referral_system
        };

        // select random u128 for selecting random participant
        let random_u128: u128  = ChaCha::rand_u128();
        let winner_id: u128 = random_u128 % finished_quest.participants_count;


        let quest_participant_hash: field = get_participant(
                quest_id,
                finished_quest.hikuru_qid,
                winner_id
            );


        quests.set(quest_id, finished_quest);

        let winner_address: address = quests_participants.get(quest_participant_hash);

        // transfer reward to user
        credits.leo/transfer_public(
            winner_address,
            finished_quest.max_reward_per_user
        );
    }

    transition acceptance_participation(quest_id: u64) {
        return then finalize(quest_id, self.caller);
    }

    finalize acceptance_participation(quest_id: u64, caller: address) {

        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_active: u64 = factory_settings_status & 1u64;
        assert_eq(is_active, 1u64); // check is active


        let quest_exists: bool = quests.contains(quest_id);
        assert_eq(quest_exists, true); // Make sure the quest exists

        let quest: Quest = quests.get(quest_id);

        assert_eq(quest.is_completed, false); // Quest should not be completed

        assert_eq(quest.participants_count < quest.max_participation, true); // Ensure max participation is not reached


        // Generate unique hash for store participant address
        // Generate before count increament because index start from ZERO
        let quest_participant_hash: field = get_participant(
            quest_id,
            quest.hikuru_qid,
            quest.participants_count
        );


        let updated_quest: Quest = Quest {
            creator: quest.creator,
            reward_contract: quest.reward_contract,
            title: quest.title,
            description: quest.description,
            quests_reward_type: quest.quests_reward_type,
            end_time: quest.end_time,
            hikuru_qid: quest.hikuru_qid,
            max_participation: quest.max_participation,
            participants_count: quest.participants_count+1u128,
            max_reward_per_user: quest.max_reward_per_user,
            total_reward_pool: quest.total_reward_pool,
            is_completed: quest.is_completed,
            with_reward: quest.with_reward,
            referral_system: quest.referral_system
        };


        quests_participants.set(quest_participant_hash, caller);
        quests.set(quest_id, updated_quest);

    }


    inline get_participant (quest_id: u64, hikuru_qid: u128, quests_participant_id: u128) -> field {
        return BHP256::hash_to_field(QuestParticipant {
            quest_id: quest_id,
            hikuru_qid: hikuru_qid,
            quests_participant_id: quests_participant_id
        });
    }
}