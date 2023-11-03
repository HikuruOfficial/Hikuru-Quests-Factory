import credits.aleo;
program hikuru_quests_factory.aleo;


struct Title:
    data0 as u128;
    data1 as u128;
    data2 as u128;
    data3 as u128;

struct Description:
    data0 as u128;
    data1 as u128;
    data2 as u128;
    data3 as u128;
    data4 as u128;
    data5 as u128;
    data6 as u128;
    data7 as u128;

struct Quest:
    creator as address;
    reward_contract as address;
    title as Title;
    description as Description;
    quests_reward_type as u128;
    end_time as u128;
    hikuru_qid as u128;
    max_participation as u128;
    participants_count as u128;
    max_reward_per_user as u64;
    total_reward_pool as u64;
    is_completed as boolean;
    with_reward as boolean;
    referral_system as boolean;

struct QuestParticipant:
    quest_id as u64;
    hikuru_qid as u128;
    quests_participant_id as u128;


mapping quests:
	key as u64.public;
	value as Quest.public;


mapping factory_settings:
	key as u8.public;
	value as u64.public;


mapping owners:
	key as address.public;
	value as boolean.public;


mapping quests_participants:
	key as field.public;
	value as address.public;

function initialize_factory:
    assert.eq self.caller aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl;
    async initialize_factory into r0;
    output r0 as hikuru_quests_factory.aleo/initialize_factory.future;

finalize initialize_factory:
    get.or_use factory_settings[0u8] 0u64 into r0;
    and r0 1u64 into r1;
    assert.eq r1 0u64;
    set true into owners[aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl];
    set 1u64 into factory_settings[0u8];
    set 10_000_000u64 into factory_settings[1u8];


function change_owner_status:
    input r0 as address.private;
    input r1 as boolean.private;
    async change_owner_status r0 r1 self.caller into r2;
    output r2 as hikuru_quests_factory.aleo/change_owner_status.future;

finalize change_owner_status:
    input r0 as address.public;
    input r1 as boolean.public;
    input r2 as address.public;
    get.or_use owners[r2] false into r3;
    assert.eq r3 true;
    set r1 into owners[r0];


function change_factory_status:
    input r0 as u8.private;
    input r1 as u64.private;
    async change_factory_status r0 r1 self.caller into r2;
    output r2 as hikuru_quests_factory.aleo/change_factory_status.future;

finalize change_factory_status:
    input r0 as u8.public;
    input r1 as u64.public;
    input r2 as address.public;
    get.or_use owners[r2] false into r3;
    assert.eq r3 true;
    set r1 into factory_settings[r0];


function quest_creation_public:
    input r0 as address.private;
    input r1 as Title.private;
    input r2 as Description.private;
    input r3 as u128.private;
    input r4 as u128.private;
    input r5 as u128.private;
    input r6 as u128.private;
    input r7 as u128.private;
    input r8 as u64.private;
    input r9 as u64.private;
    input r10 as boolean.private;
    input r11 as boolean.private;
    add 10_000_000u64 r9 into r12;
    call credits.aleo/transfer_public aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl r12;
    gt r6 0u128 into r13;
    assert.eq r13 true;
    cast self.caller r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 false into r14 as Quest;
    async quest_creation_public r14 into r15;
    output r14 as Quest.private;
    output r15 as hikuru_quests_factory.aleo/quest_creation_public.future;

finalize quest_creation_public:
    input r0 as Quest.public;
    get.or_use factory_settings[0u8] 0u64 into r1;
    and r1 1u64 into r2;
    assert.eq r2 1u64;
    get.or_use factory_settings[2u8] 0u64 into r3;
    add r3 1u64 into r4;
    set r4 into factory_settings[2u8];
    set r0 into quests[r4];


function quest_creation_private:
    input r0 as address.private;
    input r1 as Title.private;
    input r2 as Description.private;
    input r3 as u128.private;
    input r4 as u128.private;
    input r5 as u128.private;
    input r6 as u128.private;
    input r7 as u128.private;
    input r8 as u64.private;
    input r9 as u64.private;
    input r10 as boolean.private;
    input r11 as boolean.private;
    input r12 as credits.aleo/credits.record;
    add 10_000_000u64 r9 into r13;
    call credits.aleo/transfer_private_to_public r12 aleo1geqft8epz9kurdv7fqfrwe4l75dw240jvhmt9x7ennftz9gt2q8q86hzjl r13 into r14;
    cast self.caller r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 false into r15 as Quest;
    async quest_creation_private r15 into r16;
    output r15 as Quest.private;
    output r14 as credits.aleo/credits.record;
    output r16 as hikuru_quests_factory.aleo/quest_creation_private.future;

finalize quest_creation_private:
    input r0 as Quest.public;
    get.or_use factory_settings[0u8] 0u64 into r1;
    and r1 1u64 into r2;
    assert.eq r2 1u64;
    get.or_use factory_settings[2u8] 0u64 into r3;
    add r3 1u64 into r4;
    set r4 into factory_settings[2u8];
    set r0 into quests[r4];




function select_random_winners:
    input r0 as u64.private;
    input r1 as u128.private;
    async select_random_winners r0 r1 self.caller into r2;
    output r2 as hikuru_quests_factory.aleo/select_random_winners.future;

finalize select_random_winners:
    input r0 as u64.public;
    input r1 as u128.public;
    input r2 as address.public;
    get.or_use owners[r2] false into r3;
    assert.eq r3 true;
    get.or_use factory_settings[0u8] 0u64 into r4;
    and r4 1u64 into r5;
    assert.eq r5 1u64;
    contains quests[r0] into r6;
    assert.eq r6 true;
    get quests[r0] into r7;
    lte r7.end_time r1 into r8;
    assert.eq r8 false;
    cast r7.creator r7.reward_contract r7.title r7.description r7.quests_reward_type r7.end_time r7.hikuru_qid r7.max_participation r7.participants_count r7.max_reward_per_user r7.total_reward_pool true r7.with_reward r7.referral_system into r9 as Quest;
    rand.chacha into r10 as u128;
    rem r10 r9.participants_count into r11;
    cast r0 r9.hikuru_qid r11 into r12 as QuestParticipant;
    hash.bhp256 r12 into r13 as field;
    set r9 into quests[r0];
    get quests_participants[r13] into r14;
    call credits.aleo/transfer_public r14 r9.max_reward_per_user;


function acceptance_participation:
    input r0 as u64.private;
    async acceptance_participation r0 self.caller into r1;
    output r1 as hikuru_quests_factory.aleo/acceptance_participation.future;

finalize acceptance_participation:
    input r0 as u64.public;
    input r1 as address.public;
    get.or_use factory_settings[0u8] 0u64 into r2;
    and r2 1u64 into r3;
    assert.eq r3 1u64;
    contains quests[r0] into r4;
    assert.eq r4 true;
    get quests[r0] into r5;
    assert.eq r5.is_completed false;
    lt r5.participants_count r5.max_participation into r6;
    assert.eq r6 true;
    cast r0 r5.hikuru_qid r5.participants_count into r7 as QuestParticipant;
    hash.bhp256 r7 into r8 as field;
    add r5.participants_count 1u128 into r9;
    cast r5.creator r5.reward_contract r5.title r5.description r5.quests_reward_type r5.end_time r5.hikuru_qid r5.max_participation r9 r5.max_reward_per_user r5.total_reward_pool r5.is_completed r5.with_reward r5.referral_system into r10 as Quest;
    set r1 into quests_participants[r8];
    set r10 into quests[r0];
