import credits.leo;

//todo: apply fee and fee change
program hikuru_quests_factory.aleo {


    // Define a structure for quests
    struct Quest {
        creator: address;
        reward_contract: address;
        reward_type: u64;
        start_time: u32;
        end_time: u32;
        hikuru_qid: u128;
        max_participation: u128;
        participants_count: u128;
        max_reward_per_user: u64; // if is nft type - where will store collectionId
        total_reward_pool: u64;
        is_completed: bool;
        is_paused: bool;
        with_reward: bool;
        referral_system: bool;
    }

    // reward_type:
    // 0 - Native
    // 1 - ERC20
    // 2 - ERC721
    // 3 - ERC1155 - reward for every user
    // 4 - ERC1155 - reward for random selected (maxParticipant) users
    // 5 - Whitelist

    // Define a structure for whitelist entries
    struct QuestParticipant {
        hikuru_qid: u64;
        participant_address: address;
    }

    struct CollectionId {
        collection_number: u64
    }

    struct CollectionData {
        updatable: bool
    }

    struct CollectionPublicData {
        royalty_fees: u64,
        royalty_address: address,
        metadata_uri: String,
        base_uri: String,
        publicizable: bool
    }

    struct String {
        part0: u128,
        part1: u128,
        part2: u128,
        part3: u128,
    }

    struct TokenId {
        token_number: u64,
        collection_number: u64
    }

    struct TokenData {
        metadata_uri: String,
        transferable: bool
    }


    record Collection {
        owner: address,
        id: CollectionId,
        data: CollectionData
    }
    record Token {
        owner: address,
        id: TokenId,
        data: TokenData
    }


    // Define mappings for quests and whitelists
    mapping quests: u64 => Quest;
    mapping quest_whitelists: QuestParticipant => bool;
    mapping factory_settings: u8 => u64;
    // 0u8 - is active
    // 1u8 - fee amount
    // 2u8 - quests amount
    // 3u8 - nft collection number
    mapping owners: address => bool;
    mapping quests_participants: field => bool;

    mapping publicTokenData: TokenId => TokenData;
    mapping collectionPublicData: CollectionId => CollectionPublicData;
    mapping publicTokenOwners: TokenId => address;
    mapping tokenExists: TokenId => bool;



    // FACTORY ADMINISTRATION
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

    transition change_owner_status(
        editable_address: address,
        new_status: bool
    ){
        return then finalize(editable_address, new_status, self.caller);
    }
    finalize change_owner_status (
        editable_address: address, 
        new_status: bool, 
        caller: address
    ) {
        let caller_status: bool = owners.get_or_use(caller, false);
        assert_eq(caller_status, true); // only old owner can change status and grand to someone

        // set new status for editable_address
        owners.set(editable_address, new_status);
    }

    transition change_factory_status(
        editable_index: u8, 
        new_status: u64
    ){
        return then finalize(editable_index, new_status, self.caller);
    }
    finalize change_factory_status (editable_index: u8, new_status: u64, caller: address) {
        let caller_status: bool = owners.get_or_use(caller, false);
        assert_eq(caller_status, true); // only owner can modify settings

        // set new status for editable_index
        factory_settings.set(editable_index, new_status);
    }



    inline get_participant (
        quest_id: u64,
        participant:address
    ) -> field {
        return BHP256::hash_to_field(QuestParticipant {
            hikuru_qid: quest_id,
            participant_address: participant,
        });
    }
    inline verify_field(s: signature, a: address, v: field) {
        let first: bool = signature::verify(s, a, v);
        let second: bool = s.verify(a, v);
        assert_eq(first, second);
    }


    // QUEST CONTROL PANEL

    // TODO: before create nft quest user should create nft collection
    // Function to create a quest privatly
    transition quest_creation (
      private s: signature,
      private v: field,
      private reward_contract: address,
      private quests_reward_type: u64,
      private start_time: u32,
      private end_time: u32,
      private hikuru_qid: u128,
      private max_participation: u128,
      private max_reward_per_user: u64,
      private total_reward_pool: u64,
      private with_reward: bool,
      private referral_system: bool,
      private payment: credits.leo/credits
    ) -> (Quest, credits.leo/credits) {
        // more security
        verify_field(s, self.caller, v);

        let aleo_change: credits = credits.leo/transfer_private_to_public(
            payment,
            aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl,
            10_000_000u64 + total_reward_pool
        );

        let quest: Quest = Quest {
            creator: self.caller,
            reward_contract: reward_contract,
            reward_type: quests_reward_type,
            start_time: start_time,
            end_time: end_time,
            hikuru_qid: hikuru_qid,
            max_participation: max_participation,
            participants_count: 0u128,
            max_reward_per_user: max_reward_per_user,
            total_reward_pool: total_reward_pool,
            is_completed: false,
            is_paused: false,
            with_reward: with_reward,
            referral_system: referral_system,
        };

        return (quest, aleo_change) then finalize(quest);
    }

    finalize quest_creation(
        quest: Quest
    ) {
        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_active: u64 = factory_settings_status & 1u64;
        assert_eq(is_active, 1u64); // check is active

        let quests_id: u64 = factory_settings.get_or_use(2u8, 0u64);
        let new_quests_id: u64 = quests_id + 1u64;

        factory_settings.set(2u8, new_quests_id);
        quests.set(new_quests_id, quest);
    }



    transition update_quest(
        private quest_id: u64,
        private new_max_participation: u128,
        private new_start_time: u32,
        private new_end_time: u32,
        private new_is_paused:bool,
    ) -> u64 {
        return (quest_id) then finalize(quest_id,  new_max_participation, new_start_time, new_end_time, new_is_paused, self.caller);
    }

    finalize update_quest(
        quest_id: u64,
        new_max_participation: u128,
        new_start_time: u32,
        new_end_time: u32,
        new_is_paused:bool,
        caller: address
    ) {
        
        let factory_settings_status: u64 = factory_settings.get_or_use(0u8, 0u64);
        let is_active: u64 = factory_settings_status & 1u64;
        assert_eq(is_active, 1u64); // check is active

        // check is time correct
        assert(
            new_start_time.eq(0u32).or( // if 0 than mint anytime
               new_start_time <= block.height
            )
        );
        assert(
            new_end_time.eq(0u32).or( // if 0 than mint anytime
                block.height < new_end_time
            )
        );
        assert(new_start_time < new_end_time);

        
        let quest_exists: bool = quests.contains(quest_id);
        assert_eq(quest_exists, true); // Make sure the quest exists

        let quest: Quest = quests.get(quest_id);

        assert_eq(quest.creator, caller); // Quest update could only creator
        assert_eq(quest.is_completed, false); // Quest should not be completed


        let updated_quest: Quest = Quest {
            creator: quest.creator,
            reward_contract: quest.reward_contract,
            reward_type: quest.reward_type,
            start_time: new_start_time,
            end_time: new_end_time,
            hikuru_qid: quest.hikuru_qid,
            max_participation: new_max_participation,
            participants_count: quest.participants_count,
            max_reward_per_user: quest.max_reward_per_user,
            total_reward_pool: quest.total_reward_pool,
            is_completed: quest.is_completed,
            is_paused: new_is_paused,
            with_reward: quest.with_reward,
            referral_system: quest.referral_system
        };

        quests.set(quest_id, updated_quest);
    }






    // Function to accept a participant for a quest
    transition accept_participant(
        private quest_id: u64
    ) {
        return then finalize(quest_id, self.caller);
    }
    finalize accept_participant(
        quest_id: u64,
        participant: address
    ){

        let quest_exists: bool = quests.contains(quest_id);
        assert_eq(quest_exists, true); // Make sure the quest exists

        let quest: Quest = quests.get(quest_id);

        // Check mint block heights
        assert(
            quest.start_time.eq(0u32).or(
                quest.start_time <= block.height
            )
        );
        assert(
            quest.end_time.eq(0u32).or(
                block.height < quest.end_time
            )
        );

        assert_eq(quest.is_completed, false); // Quest should not be completed
        assert_eq(quest.is_paused, false); // Quest should not be paused
        assert_eq(quest.participants_count < quest.max_participation, true); // Ensure max participation is not reached

        let quest_participant_hash: field = get_participant(
            quest_id,
            participant
        );

        let is_already_participated: bool = quests_participants.get_or_use(quest_participant_hash, false);
        assert_eq(is_already_participated, false); // Cant twice participate

        let updated_quest: Quest = Quest {
            creator: quest.creator,
            reward_contract: quest.reward_contract,
            reward_type: quest.reward_type,
            start_time: quest.start_time,
            end_time: quest.end_time,
            hikuru_qid: quest.hikuru_qid,
            max_participation: quest.max_participation,
            participants_count: quest.participants_count+1u128,
            max_reward_per_user: quest.max_reward_per_user,
            total_reward_pool: quest.total_reward_pool,
            is_completed: quest.is_completed,
            is_paused: quest.is_paused,
            with_reward: quest.with_reward,
            referral_system: quest.referral_system
        };

        quests_participants.set(quest_participant_hash, true);
        quests.set(quest_id, updated_quest);
    }


    // Token: whitelist
    transition aleo_whitelist(
        private quest_id: u64,
        private reward_per_user: u64,
        private participant: address
    ) {
        assert_eq(self.caller, aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl);

        credits.leo/transfer_public(
            aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl,
            reward_per_user
        );

        return then finalize(quest_id, participant, self.caller);
    }

    finalize aleo_whitelist(
        quest_id: u64,
        participant: address,
        caller: address
    ) {
        let caller_status: bool = owners.get_or_use(caller, false);
        assert_eq(caller_status, true); // Ensure that only an owner can modify the whitelist

        let quest_exists: bool = quests.contains(quest_id);
        assert_eq(quest_exists, true); // Ensure the quest exists

        let whitelist_entry: QuestParticipant = QuestParticipant {
            hikuru_qid: quest_id,
            participant_address: participant
        };

        // Set or update the whitelist status for the participant in the given quest
        quest_whitelists.set(whitelist_entry, true);
    }
    

    // NFT managament

    transition create_collection(
        private collection_number: u64, 
        private collection_data: CollectionData,
        public collection_public_data: CollectionPublicData,
    ) -> private Collection {
        assert_neq(collection_number, 0u64);
        let collection_id: CollectionId = CollectionId {
            collection_number: collection_number
        };

        let collection: Collection = Collection {
            owner: self.caller,
            id: collection_id,
            data: collection_data
        };
        return collection then finalize(
            collection_id, 
            collection_public_data
        );
    }
    finalize create_collection(
        public collection_id: CollectionId,
        public collection_public_data: CollectionPublicData
    ) {
        let collection_exists: bool = collectionPublicData.contains(
            collection_id
        );
        assert(collection_exists.not());

        collectionPublicData.set(collection_id, collection_public_data);
    }

    transition mint_private(
        private collection: Collection, 
        public token_number: u64,
        private receiver: address,
        private token_data: TokenData
    ) -> (private Token, private Collection) {
        let new_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: collection.data
        };
        let token_id: TokenId = TokenId {
            collection_number: collection.id.collection_number,
            token_number: token_number
        };

        let token : Token = Token {
            owner: receiver,
            id: token_id,
            data: token_data
        };
        return (token, new_collection) then finalize(token_id);
    }
    finalize mint_private(
        public token_id: TokenId,
    ) {
        let token_exists: bool = tokenExists.contains(token_id);
        assert(token_exists.not());

        tokenExists.set(token_id, true);
    }

    transition transfer_token_private(
        private token: Token,
        private receiver: address
    ) -> private Token {
        assert(token.data.transferable);
        let out_token: Token = Token {
            owner: receiver,
            id: token.id,
            data: token.data
        };

        return out_token;
    }

    transition burn_private(
        private collection: Collection,
        private token: Token
    ) -> private Collection {
        assert_eq(token.id.collection_number, collection.id.collection_number);
        assert(collection.data.updatable);

        let collection_data: CollectionData = CollectionData {
            updatable: collection.data.updatable,
        };

        let new_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: collection_data
        };

        return new_collection then finalize(
            token.id
        );
    }
    finalize burn_private(
        public token_id: TokenId
    ) {
        tokenExists.remove(token_id);
    }

    transition nft_whitelist(
        private quest_id: u64,
        private token_number: u64,
        private metadata_uri: String,
        private receiver: address
    ) {
        assert_eq(self.caller, aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl);

        // Mint the token
        return then finalize(quest_id, token_number, receiver, metadata_uri);
    }
    finalize nft_whitelist(
        quest_id: u64,
        token_number: u64,
        receiver: address,
        metadata_uri: String,
    ) {
        let quest_exists: bool = quests.contains(quest_id);
        assert_eq(quest_exists, true); // Ensure the quest exists

        let quest: Quest = quests.get(quest_id);

        // Construct the token data
        let token_data: TokenData = TokenData {
            metadata_uri: metadata_uri,
            transferable: true
        };

        // Construct the token ID
        let token_id: TokenId = TokenId {
            collection_number: quest.max_reward_per_user, // Using max_reward_per_user as collection_number
            token_number: token_number
        };

        // Update the token mappings
        tokenExists.set(token_id, true);
        publicTokenData.set(token_id, token_data);
        publicTokenOwners.set(token_id, receiver);

        // Update the whitelist
        let whitelist_entry: QuestParticipant = QuestParticipant {
            hikuru_qid: quest_id,
            participant_address: receiver
        };
        quest_whitelists.set(whitelist_entry, true);
    }


}
