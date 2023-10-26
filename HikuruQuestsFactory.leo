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
      max_reward_per_user: u128;
      total_reward_pool: u128;
      participants_list: address[];
      is_completed: bool;
      with_reward: bool;
      referral_system: bool;
    }


    mapping quests: u128 =>  Quest;

    transition quest_creation (
      reward_contract: address,
      title: Title,
      description: Description,
      quests_reward_type: u128,
      end_time: u128,
      hikuru_qid: u128,
      max_participation: u128,
      participants_count: u128,
      max_reward_per_user: u128,
      total_reward_pool: u128,
      is_completed: bool,
      with_reward: bool,
    ) -> Quest {
        
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
            participants_list: address[],
            is_completed: is_completed,
            with_reward: with_reward,
            referral_system: false
        };

        return quest then finalize(quest);
    }

    finalize  quest_creation(quest: Quest) {
        Mapping::set(quests, quest.hikuru_qid, quest);
    }

    transition select_random_winners(winners: address[], hikuru_qid:u128, time_now: u128) {
        return finalize(winners, hikuru_qid, time_now);
    }

    finalize select_random_winners(winners: address[], hikuru_qid:u128, time_now: u128) {
        let contains: bool = Mapping::contains(quests, hikuru_qid);
        assert_eq(contains, false); // quest not exist

        let quest: Quest = Mapping::get(quests, hikuru_qid);
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
            participants_list: quest.participants_list,
            is_completed: true,
            with_reward: quest.with_reward,
            referral_system: quest.referral_system
        };

        Mapping::set(quests, quest.hikuru_qid, finished_quest);
        
    }

    transition acceptance_participation(hikuru_qid: u128) {
        return finalize(hikuru_qid);
    }

    finalize acceptance_participation(hikuru_qid) {
        let quest_exists: bool = Mapping::contains(quests, hikuru_qid);
        assert_eq(quest_exists, true); // Make sure the quest exists

        let quest: Quest = Mapping::get(quests, hikuru_qid);

        assert_eq(quest.participants_count < quest.max_participation, true); // Ensure max participation is not reached

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
            participants_list: quest.participants_list,
            is_completed: quest.is_completed,
            with_reward: quest.with_reward,
            referral_system: quest.referral_system
        };

        Mapping::set(quests, quest.hikuru_qid, updated_quest);
    }


}
