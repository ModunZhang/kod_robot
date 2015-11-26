local SERVER_ERRORS = {
    [500] = _("请求出错"),
    [501] = _("设备不存在"),
    [502] = _("用户不存在"),
    [503] = _("玩家不存在"),
    [504] = _("对象被锁定"),
    [505] = _("需要重新登录"),
    [506] = _("玩家已经登录"),
    [507] = _("联盟不存在"),
    [508] = _("服务器维护中"),
    [509] = _("建筑不存在"),
    [510] = _("建筑正在升级"),
    [511] = _("建筑坑位不合法"),
    [512] = _("建造数量已达建造上限"),
    [513] = _("建筑已达到最高等级"),
    [514] = _("建筑升级前置条件未满足"),
    [515] = _("宝石不足"),
    [516] = _("只有生产建筑才能转换"),
    [517] = _("小屋数量过多"),
    [518] = _("主体建筑必须大于等于1级"),
    [519] = _("小屋类型不存在"),
    [520] = _("小屋数量超过限制"),
    [521] = _("建筑周围不允许建造小屋"),
    [522] = _("小屋坑位不合法"),
    [523] = _("建造小屋会造成可用城民小于0"),
    [524] = _("小屋升级前置条件未满足"),
    [525] = _("小屋不存在"),
    [526] = _("小屋正在升级"),
    [527] = _("小屋已达到最高等级"),
    [528] = _("升级小屋会造成可用城民小于0"),
    [529] = _("玩家事件不存在"),
    [530] = _("还不能进行免费加速"),
    [531] = _("建筑还未建造"),
    [532] = _("同类型的材料正在制造"),
    [533] = _("同类型的材料制作完成后还未领取"),
    [534] = _("不同类型的材料正在制造"),
    [535] = _("材料事件不存在或者正在制作"),
    [536] = _("此士兵还处于锁定状态"),
    [537] = _("招募数量超过单次招募上限"),
    [538] = _("士兵招募材料不足"),
    [539] = _("龙装备制造事件已存在"),
    [540] = _("制作龙装备材料不足"),
    [541] = _("士兵不存在或士兵数量不合法"),
    [542] = _("龙蛋早已成功孵化"),
    [543] = _("龙蛋孵化事件已存在"),
    [544] = _("龙还未孵化"),
    [545] = _("装备与龙的星级不匹配"),
    [546] = _("龙装备数量不足"),
    [547] = _("龙身上已经存在相同类型的装备"),
    [548] = _("此分类还没有配置装备"),
    [549] = _("装备已到最高星级"),
    [550] = _("被牺牲的装备不存在或数量不足"),
    [551] = _("龙技能不存在"),
    [552] = _("此龙技能还未解锁"),
    [553] = _("龙技能已达最高等级"),
    [554] = _("英雄之血不足"),
    [555] = _("龙的星级已达最高"),
    [556] = _("龙的等级未达到晋级要求"),
    [557] = _("龙的装备未达到晋级要求"),
    [558] = _("每日任务不存在"),
    [559] = _("每日任务已达最高星级"),
    [560] = _("每日任务事件已存在"),
    [561] = _("每日任务事件不存在"),
    [562] = _("每日任务事件还未完成"),
    [563] = _("邮件不存在"),
    [564] = _("战报不存在"),
    [565] = _("龙未处于空闲状态"),
    [566] = _("所选择的龙已经阵亡"),
    [567] = _("没有龙驻防在城墙"),
    [568] = _("没有足够的出售队列"),
    [569] = _("玩家资源不足"),
    [570] = _("马车数量不足"),
    [571] = _("商品不存在"),
    [572] = _("商品还未卖出"),
    [573] = _("您未出售此商品"),
    [574] = _("商品已经售出"),
    [575] = _("科技已达最高等级"),
    [576] = _("前置科技条件不满足"),
    [577] = _("所选择的科技正在升级"),
    [578] = _("士兵已达最高星级"),
    [579] = _("科技点不足"),
    [580] = _("此兵种正在升级中"),
    [581] = _("此道具未出售"),
    [582] = _("道具不存在"),
    [583] = _("小屋当前不能被移动"),
    [584] = _("不能修改为相同的玩家名称"),
    [585] = _("玩家名称已被其他玩家占用"),
    [586] = _("玩家未加入联盟"),
    [587] = _("行军事件不存在"),
    [588] = _("联盟正处于战争期"),
    [589] = _("玩家有部队正在行军中"),
    [590] = _("不能移动到目标点位"),
    [591] = _("此道具不允许直接使用"),
    [592] = _("赌币不足"),
    [593] = _("今日登陆奖励已领取"),
    [594] = _("在线时间不足,不能领取"),
    [595] = _("此时间节点的在线奖励已经领取"),
    [596] = _("今日王城援军奖励已领取"),
    [597] = _("冲级奖励时间已过"),
    [598] = _("当前等级的冲级奖励已经领取"),
    [599] = _("玩家城堡等级不足以领取当前冲级奖励"),
    [600] = _("玩家还未进行首次充值"),
    [601] = _("首次充值奖励已经领取"),
    [602] = _("日常任务奖励已经领取"),
    [603] = _("日常任务还未完成"),
    [604] = _("成长任务不存在"),
    [605] = _("成长任务奖励已经领取"),
    [606] = _("前置任务奖励未领取"),
    [607] = _("重复的订单号"),
    [608] = _("订单商品不存在"),
    [609] = _("订单验证失败"),
    [610] = _("IAP服务器通讯出错"),
    [611] = _("IAP服务器关闭"),
    [612] = _("玩家已加入了联盟"),
    [613] = _("联盟名称已经存在"),
    [614] = _("联盟标签已经存在"),
    [615] = _("联盟操作权限不足"),
    [616] = _("联盟荣耀值不足"),
    [617] = _("联盟没有此玩家"),
    [618] = _("联盟正在战争准备期或战争期,不能将玩家踢出联盟"),
    [619] = _("不能将职级高于或等于自己的玩家踢出联盟"),
    [620] = _("别逗了,你是不盟主好么"),
    [621] = _("别逗了,仅当联盟成员为空时,盟主才能退出联盟"),
    [622] = _("联盟正在战争准备期或战争期,不能退出联盟"),
    [623] = _("联盟不允许直接加入"),
    [624] = _("联盟申请已满,请撤消部分申请后再来申请"),
    [625] = _("对此联盟的申请已发出,请耐心等候审核"),
    [626] = _("此联盟的申请信息已满,请等候其处理后再进行申请"),
    [627] = _("联盟申请事件不存在"),
    [628] = _("玩家已经取消对此联盟的申请"),
    [629] = _("此玩家的邀请信息已满,请等候其处理后再进行邀请"),
    [630] = _("联盟邀请事件不存在"),
    [631] = _("玩家已经是盟主了"),
    [632] = _("盟主连续7天不登陆时才能购买盟主职位"),
    [633] = _("此事件已经发送了加速请求"),
    [634] = _("帮助事件不存在"),
    [635] = _("不能帮助自己加速建造"),
    [636] = _("您已经帮助过此事件了"),
    [637] = _("联盟建筑已达到最高等级"),
    [638] = _("此联盟事件已经激活"),
    [639] = _("联盟感知力不足"),
    [640] = _("所选择的龙领导力不足"),
    [641] = _("没有空闲的行军队列"),
    [642] = _("关卡激活事件不存在"),
    [643] = _("此联盟圣地关卡还未解锁"),
    [644] = _("玩家已经对此关卡派出了部队"),
    [645] = _("联盟正处于战争准备期或战争期"),
    [646] = _("已经发送过开战请求"),
    [647] = _("未能找到战力相匹配的联盟"),
    [648] = _("联盟战报不存在"),
    [649] = _("联盟战胜利方不能发起复仇"),
    [650] = _("超过最长复仇期限"),
    [651] = _("目标联盟未处于和平期,不能发起复仇"),
    [652] = _("玩家已经对目标玩家派出了协防部队"),
    [653] = _("目标玩家协防部队数量已达最大"),
    [654] = _("玩家没有协防部队驻扎在目标玩家城市"),
    [655] = _("联盟未处于战争期"),
    [656] = _("玩家不在敌对联盟中"),
    [657] = _("玩家处于保护状态"),
    [658] = _("目标联盟非当前匹配的敌对联盟"),
    [659] = _("村落不存在"),
    [660] = _("村落采集事件不存在"),
    [661] = _("没有此玩家的协防部队"),
    [662] = _("此道具未在联盟商店出售"),
    [663] = _("普通道具不需要进货补充"),
    [664] = _("玩家级别不足,不能购买高级道具"),
    [665] = _("道具数量不足"),
    [666] = _("玩家忠诚值不足"),
    [667] = _("联盟事件不存在"),
    [668] = _("非法的联盟状态"),
    [669] = _("玩家GameCenter账号已经绑定"),
    [670] = _("此GameCenter账号已被其他玩家绑定"),
    -- [671] = _("此GameCenter账号未被其他玩家绑定"),
    -- [672] = _("当前玩家还未绑定GameCenter账号"),
    [673] = _("此GameCenter账号已绑定当前玩家"),
    [674] = _("pushId已经设置"),
    [675] = _("此联盟建筑不允许移动"),
    [676] = _("不能移动到目标点位"),
    [677] = _("礼品不存在"),
    [678] = _("服务器不存在"),
    [679] = _("不能切换到相同的服务器"),
    [680] = _("玩家未在当前服务器"),
    [681] = _("没有事件需要协助加速"),
    [682] = _("联盟人数已达最大"),
    [683] = _("服务器繁忙"),
    [684] = _("玩家第二条队列已经解锁"),
    [685] = _("非法的请求"),
    [686] = _("玩家数据已经初始化"),
    [687] = _("设备禁止登陆"),
    [688] = _("玩家禁止登录"),
    [689] = _("首次加入联盟奖励已经领取"),
    [690] = _("新手引导已经完成"),
    [691] = _("版本验证失败"),
    [692] = _("版本不匹配"),
    [693] = _("此联盟不需要申请加入"),
    [694] = _("野怪不存在"),
    [695] = _("不能购买自己出售的商品"),
    [696] = _("孵化条件不满足"),
    [697] = _("关卡未解锁"),
    [698] = _("还不能领取PvE星级奖励"),
    [699] = _("Pve星级奖励已经领取"),
    [700] = _("当前关卡已达最大战斗次数"),
    [701] = _("玩家体力值不足"),
    [702] = _("当前PvE关卡还不能被扫荡"),
    [703] = _("此邮件未包含奖励信息"),
    [704] = _("此邮件的奖励已经领取"),
    [705] = _("玩家被禁言"),
    [706] = _("不能观察自己的联盟"),
    [707] = _("没有空闲的地图区域"),
    [708] = _("玩家未观察此地块"),
    [709] = _("当前还不能移动联盟"),
    [710] = _("不能移动到目标地块"),
    [711] = _("玩家将被攻打,不能退出联盟"),
    [712] = _("您有商品正在出售,不能切换服务器"),
    [713] = _("联盟宫殿等级过低,不能移动联盟"),
    [714] = _("玩家还未绑定GC"),
}

local MATERIALS_DESC_MAP = {
    blueprints =  _("用于建造高等级建筑和研发高级科技"),
    tools =  _("用于建造高等级建筑和研发高级科技"),
    tiles =  _("用于建造高等级建筑和研发高级科技"),
    pulley =  _("用于建造高等级建筑和研发高级科技"),
    trainingFigure =   _("用于在训练营地提升步兵的属性"),
    bowTarget = _("用于在猎手大厅提升弓手的属性"),
    saddle =  _("用于在马厩提升骑兵的属性"),
    ironPart =   _("用于在马厩提升骑兵的属性"),
}

local EQUIP_MATERIAL_DESC_LOCALIZE = {
    ["ingo_1"] = _("打造红龙，蓝龙和绿龙1星装备所必须的材料"),
    ["ingo_2"] = _("打造红龙，蓝龙和绿龙2星装备所必须的材料"),
    ["ingo_3"] = _("打造红龙，蓝龙和绿龙3星装备所必须的材料"),
    ["ingo_4"] = _("打造红龙，蓝龙和绿龙4星装备所必须的材料"),
    ["redSoul_2"] = _("打造红龙2星装备所必须的材料"),
    ["redSoul_3"] = _("打造红龙3星装备所必须的材料"),
    ["redSoul_4"] = _("打造红龙4星装备所必须的材料"),
    ["blueSoul_2"] = _("打造蓝龙2星装备所必须的材料"),
    ["blueSoul_3"] = _("打造蓝龙3星装备所必须的材料"),
    ["blueSoul_4"] = _("打造蓝龙4星装备所必须的材料"),
    ["greenSoul_2"] = _("打造绿龙2星装备所必须的材料"),
    ["greenSoul_3"] = _("打造绿龙3星装备所必须的材料"),
    ["greenSoul_4"] = _("打造绿龙4星装备所必须的材料"),
    ["redCrystal_1"] = _("打造红龙1星装备所必须的材料"),
    ["redCrystal_2"] = _("打造红龙2星装备所必须的材料"),
    ["redCrystal_3"] = _("打造红龙3星装备所必须的材料"),
    ["redCrystal_4"] = _("打造红龙4星装备所必须的材料"),
    ["blueCrystal_1"] = _("打造蓝龙1星装备所必须的材料"),
    ["blueCrystal_2"] = _("打造蓝龙2星装备所必须的材料"),
    ["blueCrystal_3"] = _("打造蓝龙3星装备所必须的材料"),
    ["blueCrystal_4"] = _("打造蓝龙4星装备所必须的材料"),
    ["greenCrystal_1"] = _("打造绿龙1星装备所必须的材料"),
    ["greenCrystal_2"] = _("打造绿龙2星装备所必须的材料"),
    ["greenCrystal_3"] = _("打造绿龙3星装备所必须的材料"),
    ["greenCrystal_4"] = _("打造绿龙4星装备所必须的材料"),
    ["runes_1"] = _("打造红龙，蓝龙和绿龙1星装备所必须的材料"),
    ["runes_2"] = _("打造红龙，蓝龙和绿龙2星装备所必须的材料"),
    ["runes_3"] = _("打造红龙，蓝龙和绿龙3星装备所必须的材料"),
    ["runes_4"] = _("打造红龙，蓝龙和绿龙4星装备所必须的材料"),
}

local SOLDIER_DESC_MATERIAL = {
    ["deathHand"] = _("用于招募亡灵兵种的材料。在探险过程中有一定几率会遭遇亡灵部队，击败他们后获得"),
    ["heroBones"] = _("用于招募亡灵兵种的材料。在探险过程中有一定几率会遭遇亡灵部队，击败他们后获得"),
    ["soulStone"] = _("用于招募亡灵兵种的材料。在探险过程中有一定几率会遭遇亡灵部队，击败他们后获得"),
    ["magicBox"] = _("用于招募亡灵兵种的材料。在探险过程中有一定几率会遭遇亡灵部队，击败他们后获得"),
    ["confessionHood"] = _("士兵材料"),
    ["brightRing"] = _("士兵材料"),
    ["holyBook"] = _("士兵材料"),
    ["brightAlloy"] = _("士兵材料")
}


local EQUIP_MATERIAL_LOCALIZE = {
    ["ingo_1"] = _("铁锭"),
    ["ingo_2"] = _("钢锭"),
    ["ingo_3"] = _("秘银锭"),
    ["ingo_4"] = _("黑铁锭"),
    ["redSoul_2"] = _("炽热之魂1阶"),
    ["redSoul_3"] = _("炽热之魂2阶"),
    ["redSoul_4"] = _("炽热之魂3阶"),
    ["blueSoul_2"] = _("冰霜之魂1阶"),
    ["blueSoul_3"] = _("冰霜之魂2阶"),
    ["blueSoul_4"] = _("冰霜之魂3阶"),
    ["greenSoul_2"] = _("森林之魂1阶"),
    ["greenSoul_3"] = _("森林之魂2阶"),
    ["greenSoul_4"] = _("森林之魂3阶"),
    ["redCrystal_1"] = _("瑕疵红水晶"),
    ["redCrystal_2"] = _("红水晶"),
    ["redCrystal_3"] = _("无暇的红水晶"),
    ["redCrystal_4"] = _("完美的红水晶"),
    ["blueCrystal_1"] = _("瑕疵蓝水晶"),
    ["blueCrystal_2"] = _("蓝水晶"),
    ["blueCrystal_3"] = _("无暇的蓝水晶"),
    ["blueCrystal_4"] = _("完美的蓝水晶"),
    ["greenCrystal_1"] = _("瑕疵绿水晶"),
    ["greenCrystal_2"] = _("绿水晶"),
    ["greenCrystal_3"] = _("无暇的绿水晶"),
    ["greenCrystal_4"] = _("完美的绿水晶"),
    ["runes_1"] = _("远古符文"),
    ["runes_2"] = _("元素符文"),
    ["runes_3"] = _("纯粹符文"),
    ["runes_4"] = _("泰坦符文"),
}
local EQUIP_LOCALIZE = {
    ["redCrown_s1"] = _("巨人头冠"),
    ["redCrown_s2"] = _("熔岩头冠"),
    ["redCrown_s3"] = _("狂怒头冠"),
    ["redCrown_s4"] = _("撒旦头冠"),
    ["blueCrown_s1"] = _("原力头冠"),
    ["blueCrown_s2"] = _("奥术头冠"),
    ["blueCrown_s3"] = _("飓风头冠"),
    ["blueCrown_s4"] = _("风暴头冠"),
    ["greenCrown_s1"] = _("欢欣头冠"),
    ["greenCrown_s2"] = _("洞察头冠"),
    ["greenCrown_s3"] = _("神秘头冠"),
    ["greenCrown_s4"] = _("虚灵头冠"),
    ["redChest_s2"] = _("熔岩胸甲"),
    ["redChest_s3"] = _("狂怒胸甲"),
    ["redChest_s4"] = _("撒旦胸甲"),
    ["blueChest_s2"] = _("奥术胸甲"),
    ["blueChest_s3"] = _("飓风胸甲"),
    ["blueChest_s4"] = _("风暴胸甲"),
    ["greenChest_s2"] = _("洞察胸甲"),
    ["greenChest_s3"] = _("神秘胸甲"),
    ["greenChest_s4"] = _("虚灵胸甲"),
    ["redSting_s2"] = _("熔岩尾刺"),
    ["redSting_s3"] = _("狂怒尾刺"),
    ["redSting_s4"] = _("撒旦尾刺"),
    ["blueSting_s2"] = _("奥术尾刺"),
    ["blueSting_s3"] = _("飓风尾刺"),
    ["blueSting_s4"] = _("风暴尾刺"),
    ["greenSting_s2"] = _("洞察尾刺"),
    ["greenSting_s3"] = _("神秘尾刺"),
    ["greenSting_s4"] = _("虚灵尾刺"),
    ["redOrd_s2"] = _("熔岩法球"),
    ["redOrd_s3"] = _("狂怒法球"),
    ["redOrd_s4"] = _("撒旦法球"),
    ["blueOrd_s2"] = _("奥术法球"),
    ["blueOrd_s3"] = _("飓风法球"),
    ["blueOrd_s4"] = _("风暴法球"),
    ["greenOrd_s2"] = _("洞察法球"),
    ["greenOrd_s3"] = _("神秘法球"),
    ["greenOrd_s4"] = _("虚灵法球"),
    ["redArmguard_s1"] = _("巨人护臂"),
    ["redArmguard_s2"] = _("熔岩护臂"),
    ["redArmguard_s3"] = _("狂怒护臂"),
    ["redArmguard_s4"] = _("撒旦护臂"),
    ["blueArmguard_s1"] = _("原力护臂"),
    ["blueArmguard_s2"] = _("奥术护臂"),
    ["blueArmguard_s3"] = _("飓风护臂"),
    ["blueArmguard_s4"] = _("风暴护臂"),
    ["greenArmguard_s1"] = _("欢欣护臂"),
    ["greenArmguard_s2"] = _("洞察护臂"),
    ["greenArmguard_s3"] = _("神秘护臂"),
    ["greenArmguard_s4"] = _("虚灵护臂"),
}

local EQUIP_SUIT = {
    redDragon = {
        _("巨人套装"),
        _("熔岩套装"),
        _("狂怒套装"),
        _("撒旦套装"),
    },
    blueDragon = {
        _("原力套装"),
        _("奥术套装"),
        _("飓风套装"),
        _("风暴套装"),
    },
    greenDragon = {
        _("欢欣套装"),
        _("洞察套装"),
        _("神秘套装"),
        _("虚灵套装"),
    }
}

local EQUIP_LOCALIZE_MAKE = {
    ["redCrown_s1"] = _("已在制造巨人头冠"),
    ["redCrown_s2"] = _("已在制造熔岩头冠"),
    ["redCrown_s3"] = _("已在制造狂怒头冠"),
    ["redCrown_s4"] = _("已在制造撒旦头冠"),
    ["blueCrown_s1"] = _("已在制造原力头冠"),
    ["blueCrown_s2"] = _("已在制造奥术头冠"),
    ["blueCrown_s3"] = _("已在制造飓风头冠"),
    ["blueCrown_s4"] = _("已在制造风暴头冠"),
    ["greenCrown_s1"] = _("已在制造欢欣头冠"),
    ["greenCrown_s2"] = _("已在制造洞察头冠"),
    ["greenCrown_s3"] = _("已在制造神秘头冠"),
    ["greenCrown_s4"] = _("已在制造虚灵头冠"),
    ["redChest_s2"] = _("已在制造熔岩胸甲"),
    ["redChest_s3"] = _("已在制造狂怒胸甲"),
    ["redChest_s4"] = _("已在制造撒旦胸甲"),
    ["blueChest_s2"] = _("已在制造奥术胸甲"),
    ["blueChest_s3"] = _("已在制造飓风胸甲"),
    ["blueChest_s4"] = _("已在制造风暴胸甲"),
    ["greenChest_s2"] = _("已在制造洞察胸甲"),
    ["greenChest_s3"] = _("已在制造神秘胸甲"),
    ["greenChest_s4"] = _("已在制造虚灵胸甲"),
    ["redSting_s2"] = _("已在制造熔岩尾刺"),
    ["redSting_s3"] = _("已在制造狂怒尾刺"),
    ["redSting_s4"] = _("已在制造撒旦尾刺"),
    ["blueSting_s2"] = _("已在制造奥术尾刺"),
    ["blueSting_s3"] = _("已在制造飓风尾刺"),
    ["blueSting_s4"] = _("已在制造风暴尾刺"),
    ["greenSting_s2"] = _("已在制造洞察尾刺"),
    ["greenSting_s3"] = _("已在制造神秘尾刺"),
    ["greenSting_s4"] = _("已在制造虚灵尾刺"),
    ["redOrd_s2"] = _("已在制造熔岩法球"),
    ["redOrd_s3"] = _("已在制造狂怒法球"),
    ["redOrd_s4"] = _("已在制造撒旦法球"),
    ["blueOrd_s2"] = _("已在制造奥术法球"),
    ["blueOrd_s3"] = _("已在制造飓风法球"),
    ["blueOrd_s4"] = _("已在制造风暴法球"),
    ["greenOrd_s2"] = _("已在制造洞察法球"),
    ["greenOrd_s3"] = _("已在制造神秘法球"),
    ["greenOrd_s4"] = _("已在制造虚灵法球"),
    ["redArmguard_s1"] = _("已在制造巨人护臂"),
    ["redArmguard_s2"] = _("已在制造熔岩护臂"),
    ["redArmguard_s3"] = _("已在制造狂怒护臂"),
    ["redArmguard_s4"] = _("已在制造撒旦护臂"),
    ["blueArmguard_s1"] = _("已在制造原力护臂"),
    ["blueArmguard_s2"] = _("已在制造奥术护臂"),
    ["blueArmguard_s3"] = _("已在制造飓风护臂"),
    ["blueArmguard_s4"] = _("已在制造风暴护臂"),
    ["greenArmguard_s1"] = _("已在制造欢欣护臂"),
    ["greenArmguard_s2"] = _("已在制造洞察护臂"),
    ["greenArmguard_s3"] = _("已在制造神秘护臂"),
    ["greenArmguard_s4"] = _("已在制造虚灵护臂"),
}

local MATERIALS_MAP = {
    blueprints =  _("建筑图纸"),
    tools =  _("建筑工具"),
    tiles =  _("砖石瓦片"),
    pulley =  _("滑轮组"),
    trainingFigure = _("木人桩"),
    bowTarget = _("箭靶"),
    saddle =  _("马鞍"),
    ironPart =   _("精铁零件"),
}
local DRAGON_LOCALIZE = {
    ["redDragon"] = _("红龙"),
    ["blueDragon"] = _("蓝龙"),
    ["greenDragon"] = _("绿龙"),
    ["blackDragon"] = _("黑龙"),
}
local DRAGON_ONLY = {
    ["redDragon"] = _("仅供红龙装备"),
    ["blueDragon"] = _("仅供蓝龙装备"),
    ["greenDragon"] = _("仅供绿龙装备"),
    ["blackDragon"] = _("仅供黑龙装备"),
}
local BODY_LOCALIZE = {
    ["crown"] = _("头部"),
    ["chest"] = _("胸部"),
    ["sting"] = _("尾部"),
    ["orb"] = _("法球"),
    ["armguardLeft,armguardRight"] = _("护臂"),
    ["armguardRight"] = _("右护臂"),
    ["armguardLeft"] = _("左护臂"),
}

local DRAGON_SKILL_EFFECTION = {
    ["dragonBlood"] = _("提升龙的生命值上限"),
    ["infantryEnhance"] = _("提升步兵的攻击和生命"),
    ["dragonBreath"] = _("提升龙的总攻击"),
    ["siegeEnhance"] = _("提升攻城攻击和生命"),
    ["cavalryEnhance"] = _("提升骑兵攻击和生命"),
    ["archerEnhance"] = _("提升弓手攻击和生命"),
    ["rapidity"] = _("增加行军速度"),
    ["frenzied"] = _("增加敌方士气损失"),
    ["insensitive"] = _("减少己方士气损失"),
    ["leadership"] = _("增加带兵量"),
    ["earthquake"] = _("增加对城墙的伤害"),
    ["greedy"] = _("减少敌方的暗仓保护比例"),
    ["scheme"] = _("增加捕获敌军几率"),
    ["recover"] = _("提升阵亡士兵的治愈率"),
    ["battleHunger"] = _("提升一定比例的英雄之血获得量"),
}

local DRAGON_SKILL = {
    ["dragonBlood"] = _("龙之血脉"),
    ["infantryEnhance"] = _("步兵强化"),
    ["dragonBreath"] = _("龙之吐息"),
    ["siegeEnhance"] = _("攻城强化"),
    ["cavalryEnhance"] = _("骑兵强化"),
    ["archerEnhance"] = _("弓手强化"),
    ["rapidity"] = _("迅捷之力"),
    ["frenzied"] = _("狂乱"),
    ["insensitive"] = _("忘却痛苦"),
    ["leadership"] = _("统帅之力"),
    ["earthquake"] = _("山崩地裂"),
    ["greedy"] = _("贪婪"),
    ["scheme"] = _("暗算"),
    ["recover"] = _("恢复"),
    ["battleHunger"] = _("饥渴"),
}

local DRAGON_BUFF_EFFECTION = {
    ["infantryAtkAdd"] = _("步兵攻击加成"),
    ["infantryHpAdd"] = _("步兵生命值加成"),
    ["infantryLoadAdd"] = _("提升步兵负重加成"),
    ["infantryMarchAdd"] = _("步兵行军速度加成"),

    ["archerAtkAdd"] = _("弓手攻击加成"),
    ["archerHpAdd"] = _("弓手生命值加成"),
    ["archerLoadAdd"] = _("弓手负重加成"),
    ["archerMarchAdd"] = _("弓手行军速度加成"),

    ["cavalryAtkAdd"] = _("骑兵攻击加成"),
    ["cavalryHpAdd"] = _("骑兵生命值加成"),
    ["cavalryLoadAdd"] = _("骑兵负重加成"),
    ["cavalryMarchAdd"] = _("骑兵行军速度加成"),

    ["siegeAtkAdd"] = _("攻城系攻击加成"),
    ["siegeHpAdd"] = _("攻城系生命值加成"),
    ["siegeLoadAdd"] = _("攻城系负重加成"),
    ["siegeMarchAdd"] = _("攻城系行军速度加成"),

    ["troopSizeAdd"] = _("带兵上限加成"),
    ["recoverAdd"] = _("可治愈伤兵几率加成"),
}
local BUILDING_DESCRIPTION = {
    ["keep"] = _("城堡是权力的象征，城市的核心建筑，升级能够解锁更多地块，提供更高的建筑等级"),
    ["unlock"] = _("可解锁的地块"),
    ["beHelpCount"] = _("被协助加速次数"),
    ["power"] = _("战斗力"),

    ["watchTower"] = _("瞭望塔显示部队在联盟领地上的行军情况，同时也能预警敌方部队来袭，并提供相关信息"),
    ["watchTower_1"] = _("提供来袭部队的玩家名称，来袭部队的出发点和目的地，剩余行军时间"),
    ["watchTower_2"] = _("提供来袭部队的龙的类型，等级和星级"),
    ["watchTower_3"] = _("可以查看其他玩家的城市布局"),
    ["watchTower_4"] = _("提供详情按钮，提供：龙的当前生命值和生命值上限，龙的力量"),
    ["watchTower_5"] = _("提供详情按钮，提供：显示兵种的名称，排序"),
    ["watchTower_6"] = _("提供详情按钮，提供：显示兵种的星级"),
    ["watchTower_7"] = _("提供详情按钮，提供：显示兵种的模糊数量"),
    ["watchTower_8"] = _("提供详情按钮，提供：显示龙的装备及其星级"),
    ["watchTower_9"] = _("提供详情按钮，提供：显示龙的技能等级"),
    ["watchTower_10"] = _("提供详情按钮，提供：显示敌方军事科技水平和战争增益"),
    ["watchTower_11"] = _("提供详情按钮，提供：显示敌方单位的具体数量"),
    ["watchTower_12"] = _("可以查看其他玩家的城市的具体建筑等级"),
    ["watchTower_13"] = _("可以查看目标城市协防部队的详细信息：龙的类型，等级和星级"),
    ["watchTower_14"] = _("可以查看目标城市协防部队的详细信息：龙的力量，当前生命值和生命值上限"),
    ["watchTower_15"] = _("可以查看目标城市协防部队的详细信息：显示兵种的名称，排序"),
    ["watchTower_16"] = _("可以查看目标城市协防部队的详细信息：显示兵种的星级"),
    ["watchTower_17"] = _("可以查看目标城市协防部队的详细信息：显示兵种的模糊数量"),
    ["watchTower_18"] = _("可以查看目标城市协防部队的详细信息：显示龙的装备及其星级"),
    ["watchTower_19"] = _("可以查看目标城市协防部队的详细信息：显示龙的技能等级"),
    ["watchTower_20"] = _("可以查看目标城市协防部队的详细信息：显示敌方单位的具体数量"),
    -- ["watchTower_21"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_22"] = _("可以查看敌军的详细信息：显示敌方部队的星级和模糊数量，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_23"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_24"] = _("可以在敌方领地，查看其他联盟领地的玩家的城市建筑具体等级，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_25"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_26"] = _("显示敌方激活的战争增益，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_27"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_28"] = _("可以查看敌军的详细信息：显示龙的技能等级，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_29"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_30"] = _("可以查看敌军的详细信息：显示敌方部队的具体数量，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_31"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_32"] = _("可以查看敌方城市中得协防部队的详细信息：龙的详细信息，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_33"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_34"] = _("可以查看敌方城市中得协防部队的详细信息：显示敌方部队的兵种名称，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_35"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_36"] = _("可以查看敌方城市中得协防部队的详细信息：龙的装备情况和龙的力量，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_37"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_38"] = _("可以查看敌军的详细信息：显示敌方部队的星级和模糊数量，预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_39"] = _("预警%.1f分钟内的敌方行军事件"),
    -- ["watchTower_40"] = _("可以查看敌军的详细信息：显示龙的技能等级，预警%.1f分钟内的敌方行军事件"),


    ["academy"] = _("学院提供的众多科技。研发科技能够提升城市的资源产出效率和防御能力，学院等级越高研发速度越快"),
    ["acdemy_efficiency"] = _("研发速度"),


    ["trainingGround"] = _("训练营地提供步兵的相关科技，增强步兵的各方面属性，建筑等级越高招募步兵的速度越快"),
    ["trainingGround_efficiency"] = _("步兵招募速度"),


    ["hunterHall"] = _("猎手大厅提供弓手的相关科技，增强弓手的各方面属性，建筑等级越高招募弓手的速度越快"),
    ["hunterhall_efficiency"] = _("弓手招募速度"),

    ["stable"] = _("马厩提供骑兵的相关科技，增强骑兵的各方面属性，建筑等级越高招募骑兵的速度越快"),
    ["hunterhall_efficiency"] = _("骑兵招募速度"),


    ["workshop"] = _("车间提供攻城器械的相关科技，增强攻城器械的各方面属性，建筑等级越高招募攻城器械的速度越快"),
    ["workshop_efficiency"] = _("攻城器械招募速度"),

    ["wall"] = _("城墙能够有效抵御敌方的进攻，当敌方部队来袭时会自动将城内的部队驻防，升级建筑能够提升城墙的耐久度"),
    ["wallHp"] = _("城墙生命值"),
    ["wallRecovery"] = _("城墙恢复"),

    ["tower"] = _("塔楼提升城墙攻击和防御的能力，塔楼等级越高，城墙每耐久度的攻击力和生命值就越高"),
    ["atk"] = _("提供城墙攻击力"),

    ["dragonEyrie"] = _("龙巢可以查看龙的信息并强化巨龙，升级龙巢能够提升在城市中的巨龙生命值的恢复速度"),
    ["vitalityRecoveryPerHour"] = _("每小时恢复龙的生命值"),

    ["hospital"] = _("医院提供治愈伤兵的功能，每次进攻或防守都能将一部分阵亡的士兵转化为伤兵并治愈，升级建筑能够提升伤兵的最大容量上限"),
    ["maxCasualty"] = _("容纳伤兵上限"),

    ["prison"] = _("监狱有一定的几率捕获来袭的敌军，并能够使用特殊的道具折磨敌军，升级建筑能够获得更多的敌军关押时间"),
    ["imprisonRate"] = _("抓获几率"),
    ["imprisonTime"] = _("囚禁时间"),

    ["toolShop"] = _("工具作坊提供建筑材料和科技材料的制作，每次制作都能随机获得一些材料，升级建筑能够提升每次制作材料的数量"),
    ["poduction"] = _("一次随机生产道具"),

    ["barracks"] = _("兵营提供军事单位的招募。招募的部队可用于进攻敌方城市，村落采集资源，防御城市。升级建筑能够提升每次招募的最大数量"),
    ["maxRecruit"] = _("最大招募人口数量"),

    ["tradeGuild"] = _("贸易行会提供玩家之间资源和材料的交易，升级建筑能够提升运输车的总量和生产速度"),
    ["maxCart"] = _("最大运输小车数量"),
    ["cartRecovery"] = _("每小时运输小车"),

    ["blackSmith"] = _("铁匠铺能够将平时收集到的特殊材料打造成龙的装备，升级建筑能够提升装备打造的速度"),
    ["blackSmith_efficiency"] = _("打造装备速度"),

    ["lumbermill"] = _("锯木工坊能够提升可建造的木工小屋数，并防止木材被敌方掠夺。周围建造木材小屋还可提升木材生产效率"),
    ["lumbermill_woodcutter"] = _("木工小屋数量"),
    ["lumbermill_protection"] = _("木材保护"),

    ["mill"] = _("磨坊能够提升可建造的农夫小屋数，并防止粮食被敌方掠夺。周围建造农夫小屋还可提升粮食生产效率"),
    ["mill_farmer"] = _("农夫小屋数量"),
    ["mill_protection"] = _("粮食保护"),

    ["stoneMason"] = _("石匠工坊能够提升可建造的石料小屋数，并防止石料被敌方掠夺。周围建造石匠小屋还可提升石料生产效率"),
    ["stoneMason_quarrier"] = _("石匠小屋数量"),
    ["stoneMason_protection"] = _("石料保护"),

    ["foundry"] = _("铸造工坊能够提升可建造的矿工小屋数，并防止铁矿被敌方掠夺。周围建造矿工小屋还可提升铁矿生产效率"),
    ["foundry_miner"] = _("矿工小屋数量"),
    ["foundry_protection"] = _("铁矿保护"),

    ["townHall"] = _("市政厅能够提升可建造的住宅数量。在市政厅完成政务可以获得额外的资源奖励。市政厅等级越高，奖励越高。"),
    ["townHall_dwelling"] = _("住宅数量"),
    ["totalTax"] = _("每次征收银币"),

    ["warehouse"] = _("资源仓库存放木材，石料，铁矿，粮食。建筑等级越高，每种资源存放的上限越大"),
    ["warehouse_max"] = _("资源存储上限"),

    ["materialDepot"] = _("材料库房能够存储各种材料。建筑等级越高，每种材料的存放上限越高。"),
    ["maxMaterial"] = _("材料存储上限"),

    ["armyCamp"] = _("军帐提供出兵时的带兵上限，建筑等级越高，每次出兵和防御时可派出的部队人口上限越大。"),
    ["armyCamp_troopPopulation"] = _("部队人口上限"),


    ["dwelling"] = _("住宅能够容纳城民并产出银币。升级建筑提升城民的最大上限和银币增长速度"),
    ["dwelling_citizen"] = _("提供城民上限"),
    ["dwelling_poduction"] = _("每小时银币产量"),
    ["recoveryCitizen"] = _("每小时城民恢复速度"),

    ["woodcutter"] = _("将城民派往木工小屋获得持续的木材产出。建筑等级越高需要更多的城民，木材产出也会更高。"),
    ["woodcutter_poduction"] = _("每小时木材产量"),

    ["farmer"] = _("将城民派往农夫小屋获得持续的粮食产出。建筑等级越高需要更多的城民，粮食产出也会更高。"),
    ["farmer_poduction"] = _("每小时粮食产量"),

    ["quarrier"] = _("将城民派往石匠小屋获得持续的石料产出。建筑等级越高需要更多的城民，石料产出也会更高。"),
    ["quarrier_poduction"] = _("每小时石料产量"),

    ["miner"] = _("将城民派往矿工小屋获得持续的铁矿产出。建筑等级越高需要更多的城民，铁矿产出也会更高。"),
    ["miner_poduction"] = _("每小时铁矿产量"),

    -- 联盟建筑

    ["shop"] = _("联盟商店能够提供部分商城售卖的道具，联盟成员可以通过忠诚值来兑换。部分高级道具需要花费荣耀值购买后，才能兑换。提升建筑等级能解锁更多高级道具。"),
    ["orderHall"] = _("秩序大厅管理着联盟领地上的村落，并可以消耗荣耀值提升村落的等级。建筑等级越高，定期刷新的村落越多。"),
    ["watchTower"] = _("巨石阵能够预警即将遭受攻击的己方玩家。巨石阵等级越高，能够提供的进攻部队的信息越详细。"),
    ["shrine"] = _("圣地消耗感知力预知联盟将要发生的危机，解决这些危机能够获得丰厚奖励。提升圣地等级能够提升感知力上限和恢复速度。"),
    ["palace"] = _("联盟宫殿是联盟的核心建筑,联盟盟主可以在这里给忠诚的拥护者颁发奖励.建筑等级越高,联盟的成员就越多。"),
}
--圣地本地化
local SHRINE_DESC = {
    ['main_stage_1'] = _("分裂的王国"),
    ['main_stage_2'] = _("叛军的愤怒"),
    ['main_stage_3'] = _("黑暗契约"),
    ['main_stage_4'] = _("荣耀的火焰"),

    ['1_1'] = {"1-1".._("邪恶苏醒"),_("黑龙带来的灾难还没有结束，一批强盗又在四处作乱，我们需要控制局势")},
    ['1_2'] = {"1-2".._("寻找线索"),_("这批强盗一定是有备而来，我们必须找到他们的老巢才能一举消灭他们")},
    ['1_3'] = {"1-3".._("抓活口"),_("我们抓到活口来为我们带路，设下圈套等他们自投罗网")},
    ['1_4'] = {"1-4".._("搜索边境"),_("被捕的强盗已经招认他们的老巢就在边境附近的一处洞穴，我们必须尽快行动")},
    ['1_5'] = {"1-5".._("地底深处"),_("这个洞穴居然还通往别处，紧跟着这些恶徒，找出他们的幕后主使")},
    ['1_6'] = {"1-6".._("背叛者的秘密"),_("原来这一切都是叛军搞的鬼，为了联盟的安定，我们必须粉碎这个阴谋")},

    ['2_1'] = {"2-1".._("强敌来袭"),_("我们的行动惹怒了叛军的首领，一支叛军的先锋正在赶往这里，做好战斗准备")},
    ['2_2'] = {"2-2".._("坚守"),_("敌人进攻虽然猛烈，但他们长途奔袭不可能持续进攻，坚守过这波进攻就有希望")},
    ['2_3'] = {"2-3".._("毫无防备"),_("正面战场敌方无法占到优势，一定会趁乱偷袭，我们得防着他们的小伎俩")},
    ['2_4'] = {"2-4".._("主动出击"),_("叛军的主力依然疲惫，我们主动出击一定能打他们一个措手不及")},
    ['2_5'] = {"2-5".._("前后夹击"),_("如果我们能分出一股部队从侧面猛攻敌方，那么击败叛军就是迟早的事")},
    ['2_6'] = {"2-6".._("暗黑之心"),_("虽然隐隐中不安，但叛军已然溃逃，我们还是尽可能的消弱叛军的力量")},

    ['3_1'] = {"3-1".._("黑龙军团"),_("叛军的头目尽然已经向黑龙效忠，我们不是他们的对手必须尽快撤离")},
    ['3_2'] = {"3-2".._("生死搏斗"),_("已经没有别的选择，必须全力一搏，或许才有一线生机")},
    ['3_3'] = {"3-3".._("逃出生天"),_("穿过这片峡谷并守住谷口，任由敌方有千军万马也无法发挥作用，冲啊")},
    ['3_4'] = {"3-4".._("地狱之门"),_("我们需要更多援军，这将是一场血腥的厮杀。英勇的领主们，胜败在此一举")},
    ['3_5'] = {"3-5".._("扭住局势"),_("敌方所有主力都派出了，如果能够击杀这支部队，那么局势将被我们扭转啊")},
    ['3_6'] = {"3-6".._("贪婪者"),_("我们赢得了暂时的胜利，但黑龙军团留下的战利品却成为了其他领主争夺的目标，我们必须防止事态恶化")},

    ['4_1'] = {"4-1".._("纷争又起"),_("大战刚刚结束，这些贪婪的领主就不顾联盟之约，公然抢夺战利品，这样的行为必须受到惩罚")},
    ['4_2'] = {"4-2".._("旧仇恨"),_("原来我们的强大早就遭来其他领主的不满，既然他们不顾联盟之约，我们也无需手下留情")},
    ['4_3'] = {"4-3".._("抉择"),_("公正终将得到伸张，如果他们放弃那些抢夺的财宝，那么我们就主动出击，给他们点教训")},
    ['4_4'] = {"4-4".._("大敌当前"),_("这些叛徒知道单打独斗不是我们的对手，竟然联合起来对抗我们。若想要得到联盟的统治权，必须要付出惨痛的代价")},
    ['4_5'] = {"4-5".._("命运的火与悲"),_("曾经的战友竟然也会倒戈相向，胜者即是正义，拿起手中的武器准备出击")},
    ['4_6'] = {"4-6".._("混乱之王"),_("混乱的联盟需要新的王者，如果这是命运的安排，那我们只有接受这个挑战")},
}

local BUILDING_NAME = {
    ["keep"] = _("城堡"),
    ["academy"] = _("学院"),
    ["trainingGround"] = _("训练营地"),
    ["hunterHall"] = _("猎手大厅"),
    ["stable"] = _("马厩"),
    ["workshop"] = _("车间"),
    ["wall"] = _("城墙"),
    ["tower"] = _("防御塔"),
    ["dragonEyrie"] = _("龙巢"),
    ["hospital"] = _("医院"),
    ["prison"] = _("监狱"),
    ["toolShop"] = _("工具作坊"),
    ["barracks"] = _("兵营"),
    ["tradeGuild"] = _("贸易行会"),
    ["blackSmith"] = _("铁匠铺"),
    ["lumbermill"] = _("锯木坊"),
    ["mill"] = _("磨坊"),
    ["stoneMason"] = _("石匠工坊"),
    ["foundry"] = _("铸造坊"),
    ["townHall"] = _("市政厅"),
    ["warehouse"] = _("资源仓库"),
    ["materialDepot"] = _("材料库房"),
    ["armyCamp"] = _("军帐"),
    ["dwelling"] = _("住宅"),
    ["woodcutter"] = _("木工小屋"),
    ["farmer"] = _("农夫小屋"),
    ["quarrier"] = _("石匠小屋"),
    ["miner"] = _("矿工小屋"),
    ["shop"] = _("联盟商店"),
    ["orderHall"] = _("秩序大厅"),
    ["shrine"] = _("圣地"),
    ["watchTower"] = _("巨石阵"),
    ["palace"] = _("联盟宫殿"),
}
local ALLIANCE_TITLE = {
    ["archon"] = _("联盟盟主"),
    ["general"] = _("将军"),
    ["quartermaster"] = _("军需官"),
    ["supervisor"] = _("监事"),
    ["elite"] = _("精英"),
    ["member"] = _("成员"),
}

local SOLDIER_CATEGORY_MAP = {
    ["wall"] = "wall"
}
for k,v in pairs(GameDatas.Soldiers.normal) do
    SOLDIER_CATEGORY_MAP[v.name] = v.type
end
for k,v in pairs(GameDatas.Soldiers.special) do
    SOLDIER_CATEGORY_MAP[v.name] = v.type
end


local ALLIANCE_EVENTS = {
    donate = _("向联盟慷慨捐赠，提升荣耀值%s"),
    promotionDown = _("的联盟职位被%s降级为%s"),
    join = _("一个新成员加入联盟"),
    kick = _("被%s踢出了联盟"),
    quit = _("退出联盟"),
    request = _("一个玩家申请加入我们的联盟"),
    notice = _("一个新的联盟公告发布"),
    desc = _("一个新的联盟宣言发布"),
    handover = _("将盟主移交给了%s！"),
    tools = _("向联盟商店补充了一批新的高级道具"),
    upgrade = _("%s 升级到 %s"),
    name = _("最近更改联盟的名称为%s"),
    tag = _("最近更改联盟的标签"),
    flag = _("修改联盟旗帜"),
    terrain = _("修改联盟地形为%s"),
    country = _("国家更改为%s"),
    gve = _("激活了圣地的神秘事件"),
    promotionUp = _("的联盟职位被%s晋级为%s"),
    shrine = _("开启了联盟圣地%s关卡"),
    fight = _("开启了联盟战"),
    buildingUpgrade = _("升级了%s"),
    villageUpgrade = _("升级了%s"),
    moveAlliance = _("迁移了联盟"),
}
local ALLIANCE_NOTICE = {
    attackVillage = _("%s正在前往占领Lv%d %s"),
    attackMonster = _("%s正在前往攻打Lv%d %s"),
    strikePlayer = _("%s向%s发起了侦察"),
    attackPlayer = _("%s向%s发起了进攻"),
    helpDefence = _("%s正在前往协防%s"),
}

local SOLDIER_CATEGORY = {
    ["infantry"] = _("步兵"),
    ["archer"] = _("弓手"),
    ["cavalry"] = _("骑兵"),
    ["siege"] = _("攻城"),
    ["hpAdd"] = _("攻城"),
    ["wall"] = _("城墙"),
}
local SOLDIER_NAME = {
    ["swordsman"] = _("剑士"),
    ["sentinel"] = _("哨兵"),
    ["ranger"] = _("弓箭手"),
    ["crossbowman"] = _("弩弓手"),
    ["lancer"] = _("枪骑兵"),
    ["horseArcher"] = _("弓骑兵"),
    ["catapult"] = _("投石车"),
    ["ballista"] = _("弩车"),

    ["skeletonWarrior"] = _("骷髅勇士"),
    ["skeletonArcher"] = _("骷髅射手"),
    ["deathKnight"] = _("死亡骑士"),
    ["meatWagon"] = _("绞肉机"),
    ["priest"] = _("牧师"),
    ["demonHunter"] = _("猎魔人"),
    ["paladin"] = _("圣骑士"),
    ["steamTank"] = _("蒸汽坦克"),

    ["wall"] = _("城墙"),
}
local SOLDIER_STATUS = {
    ["waiting"] = _("等待"),
    ["fighting"] = _("战斗中"),
    ["defeated"] = _("击溃!"),
}


local SOLDIER_MATERIAL = {
    ["deathHand"] = _("死亡之手"),
    ["heroBones"] = _("英雄枯骨"),
    ["soulStone"] = _("灵魂石"),
    ["magicBox"] = _("魔能之盒"),
    ["confessionHood"] = _("士兵材料"),
    ["brightRing"] = _("士兵材料"),
    ["holyBook"] = _("士兵材料"),
    ["brightAlloy"] = _("士兵材料")
}

local DRAGON_STATUS = {
    free = _("空闲中"),
    march = _("出征中"),
    defence = _("驻防中"),
    dead = _("已阵亡")
}
local FIGHT_REWARD = {
    blood = _("英雄之血"),
    food = _("粮食"),
    wood = _("木材"),
    stone = _("石料"),
    iron = _("铁矿"),
    coin = _("银币"),
    wallHp = _("城墙血量"),
    exp = _("经验值"),
    gem = _("金龙币"),
}
local SELL_TYPE = {
    food = _("粮食"),
    wood = _("木材"),
    stone = _("石料"),
    iron = _("铁矿"),

    blueprints = _("建筑图纸"),
    tools = _("建筑工具"),
    tiles = _("砖石瓦片"),
    pulley = _("滑轮组"),

    trainingFigure = _("木人桩"),
    bowTarget = _("箭靶"),
    saddle = _("马鞍"),
    ironPart = _("精铁零件"),
}
local ALLIANCE_AUTHORITY_LIST = {
    {
        _("购买联盟商店内的低级道具"),
        _("接受联盟礼物"),
        _("向联盟捐赠资源"),
    },
    {
        _("购买联盟商店内的高级道具"),
    }, -- 2
    {
        _("发送联盟邀请"),
        _("管理联盟申请"),
        _("踢出成员"),
        _("提升成员职位"),
        _("降职成员职位"),
        _("修改联盟描述"),
        _("修改联盟加入方式"),
    }, -- 3
    {
        _("补充联盟商店内的高级道具"),
        _("修改联盟公告"),
        _("发送联盟群邮件"),
        _("升级联盟建筑"),
    }, -- 4
    {
        _("移动联盟中的树林/山脉/湖泊"),
        _("激活圣地联盟危机"),
        _("激活联盟会战"),
    }, -- 5
    {
        _("更改联盟名称/联盟标签"),
        _("更改联盟旗帜"),
        _("更改联盟地形"),
        _("设置联盟语言"),
        _("移交盟主职位"),
        _("更改职位名称"),
    }, --
}

local VILLAGE_NAME = {
    woodVillage = _("木材村落"),
    stoneVillage= _("矿石村落"),
    ironVillage = _("铁矿村落"),
    foodVillage = _("粮食村落"),
    coinVillage = _("硬币村落"),
}
local TERRAIN = {
    grassLand = _("草地"),
    desert= _("沙漠"),
    iceField = _("雪地"),
}
local HATE_DRAGON = {
    ["redDragon"] = _("孵化红龙"),
    ["blueDragon"] = _("孵化蓝龙"),
    ["greenDragon"] = _("孵化绿龙"),
}
local DRAGON_BUFFER = {
    ["redDragon"] = _("红龙能提升部队在草地上的作战能力。"),
    ["blueDragon"] = _("蓝龙能提升部队在草地上的作战能力。"),
    ["greenDragon"] = _("绿龙能提升部队在草地上的作战能力。"),
}
local PRODUCTIONTECHNOLOGY_NAME = {
    crane = _("起重机"),
    fastFix = _("快速维修"),
    reinforcing = _("钢筋加固"),
    rescueTent = _("急救帐篷"),
    colonization = _("殖民地"),
    recruitment = _("募兵术"),
    stoneCarving = _("石雕技巧"),
    ironSmelting = _("冶炼技巧"),
    seniorTower = _("高级箭塔"),
    trap = _("陷阱"),
    hideout = _("暗仓建设"),
    logistics = _("后勤学"),
    forestation = _("造林技巧"),
    cropResearch = _("种植技巧"),
    beerSupply = _("啤酒供应"),
    healingAgent = _("再生药剂"),
    sketching = _("工程绘图"),
    mintedCoin = _("铸造钱币"),
}

local PRODUCTIONTECHNOLOGY_BUFFER = {
    crane = _("增加建筑速度"),
    fastFix = _("增加城墙维修速度"),
    reinforcing = _("增加城墙的单位血量防御值"),
    rescueTent = _("增加医院的伤兵容量"),
    colonization = _("增加村落的资源采集速度"),
    recruitment = _("减少招募普通士兵资源消耗"),
    stoneCarving = _("增加石料产量"),
    ironSmelting = _("增加铁矿产量"),
    seniorTower = _("增加防御箭塔的攻击力"),
    trap = _("增加敌方攻城后的返程时间"),
    hideout = _("增加资源保护比例"),
    logistics = _("提示资源小车数量上限"),
    forestation = _("增加木材产量"),
    cropResearch = _("增加粮食产量"),
    beerSupply = _("住宅城民上限加成"),
    healingAgent = _("减少治愈伤兵的时间"),
    sketching = _("增加生产材料速度"),
    mintedCoin = _("提升银币产量"),
}
local PRODUCTIONTECHNOLOGY_BUFFER_COMPLETE = {
    crane = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.crane),
    fastFix = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.fastFix),
    reinforcing = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.reinforcing),
    rescueTent = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.rescueTent),
    colonization = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.colonization),
    recruitment = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.recruitment),
    stoneCarving = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.stoneCarving),
    ironSmelting = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.ironSmelting),
    seniorTower = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.seniorTower),
    trap = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.trap),
    hideout = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.hideout),
    logistics = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.logistics),
    forestation = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.forestation),
    cropResearch = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.cropResearch),
    beerSupply = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.beerSupply),
    healingAgent = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.healingAgent),
    sketching = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.sketching),
    mintedCoin = string.format(_("研发%s完成"),PRODUCTIONTECHNOLOGY_NAME.mintedCoin),
}
local WONDER_NAME = {
    highcastle = _("高庭"),
    corona = _("圣冠堡"),
    norland = _("诺兰德"),
    rainhaven = _("雨城"),
    dunwall = _("顿沃城"),
    rockwarren = _("洛克瓦伦"),
    kanan = _("卡纳"),
    blackiron = _("黑铁堡"),
    lostmoor = _("洛斯摩尔"),
    gateway = _("边关城"),
    whitemoon = _("明月城"),
    coldcastle = _("寒冰城"),
    silverden = _("银登城"),
    greygriffin = _("灰格里芬"),
    scar = _("孤崖"),
}
local WONDER_TITLE_NAME = {
    medal_1 = _("帝王之师"),
    medal_2 = _("暗天使"),
    medal_3 = _("战争修士"),
    medal_4 = _("灰骑士"),
    medal_5 = _("钢铁之手"),
    medal_6 = _("极限战士"),
    medal_7 = _("守望者"),
    curse_1 = _("恐惧折磨"),
    curse_2 = _("瘟疫之源"),
    curse_3 = _("腐化之种"),
    curse_4 = _("暗影魔咒"),
    curse_5 = _("血之祭祀"),
    curse_6 = _("丧失神智"),
    curse_7 = _("寒霜之触"),
}
local WONDER_TITLE_BUFF = {
    medal_1 = _("部队攻击+10%，部队防御+10%，带兵上限+10%"),
    medal_2 = _("木材/石料/铁矿/粮食产量+10%，暗仓保护+10%"),
    medal_3 = _("建造速度+10%，研发速度+10%，城墙恢复速度+20%"),
    medal_4 = _("招募速度+10%，维护费用-10%，带兵上限+10%"),
    medal_5 = _("部队防御+10%，铁矿产量+10%，粮食产量+10%"),
    medal_6 = _("部队攻击+5%，龙的生命恢复+10%"),
    medal_7 = _("木材产量+10%，石料产量+10%，建造速度+5%"),
    curse_1 = _("部队攻击-10%，部队防御-10%，带兵上限-10%"),
    curse_2 = _("暗仓保护-10%，行军速度-10%，治疗伤兵速度-20%"),
    curse_3 = _("木材/石料/铁矿/粮食产量-10%，招募速度-10%"),
    curse_4 = _("城墙恢复速度-10%，龙的生命恢复-10%"),
    curse_5 = _("铁矿产量-10%，粮食产量-10%，招募速度-5%"),
    curse_6 = _("维护费用增加+10%，研发速度-10%"),
    curse_7 = _("木材产量-10%，石料产量-10%，建造速度-5%"),
}

local MAILS = {
    __system = _("系统邮件"),
    __member = _("成员"),
    __supervisor = _("监事"),
    __quartermaster = _("军需官"),
    __general = _("将军"),
    __archon = _("盟主"),
    __elite = _("精英"),
    __allianceMembers = _("联盟所有成员"),
    __woodVillage = _("木材村落"),
    __ironVillage = _("铁矿村落"),
    __foodVillage = _("粮食村落"),
    __coinVillage = _("硬币村落"),
    __stoneVillage= _("矿石村落"),
    __swordsman = _("剑士"),
    __sentinel = _("哨兵"),
    __ranger = _("弓箭手"),
    __crossbowman = _("弩弓手"),
    __lancer = _("枪骑兵"),
    __horseArcher = _("弓骑兵"),
    __catapult = _("投石车"),
    __ballista = _("弩车"),
}

local  getBuildingLocalizedKeyByBuildingType = function(name)
    local building_config = GameDatas.Buildings.buildings
    for _,v in ipairs(building_config) do
        if v.name == name then
            return v.desc
        end
    end
    local house_config = GameDatas.Houses.houses
    for _,v in pairs(house_config) do
        if v.type == name then
            return v.desc
        end
    end
    return "buidling localized string not found"
end

local  getHouseLocalizedKeyByBuildingType = function(type)
    local house_config = GameDatas.Houses.houses
    for _,v in pairs(house_config) do
        if v.type == type then
            return v.desc
        end
    end
    return "house localized string not found"
end

--通过type获取建筑或者小屋的本地化名称
local getLocaliedKeyByType = function(type)
    local house_config = GameDatas.Houses.houses
    if house_config[type] then
        return getHouseLocalizedKeyByBuildingType(type)
    else
        return getBuildingLocalizedKeyByBuildingType(type)
    end
end

local GAME_LANGUAGE = {
    en = _("英文"),
    cn = _("简体中文"),
    tw = _("繁体中文"),

}

local DAILY_TASKS = {
    empireRise = {
        title = _("帝国崛起"),
        desc  = _("处理城市中的政务,获得奖励")
    },
    conqueror = {
        title = _("征服者"),
        desc  = _("用武力赢取荣耀和奖励"),
    },
    brotherClub = {
        title = _("兄弟会"),
        desc  = _("为了联盟兄弟两肋插刀"),
    },
    growUp = {
        title = _("超凡之路"),
        desc  = _("使用特殊能力提升成长速度")
    }
}

local SELENAQUESTION_TIPS = {
    _("回答正确"),
    _("答的好"),
    _("大答特答"),
    _("主宰考场"),
    _("答题如麻"),
    _("无题能挡"),
    _("变态答题"),
    _("妖怪般的答题"),
    _("如出题人一般"),
    _("超越出题的人全对"),
}

local ALLIANCE_BUILDINGS = {
    shop = _("联盟商店"),
    watchTower = _("巨石阵"),
    shrine = _("圣地"),
    orderHall = _("秩序大厅"),
    palace = _("联盟宫殿"),
    bloodSpring = _("血泉"),
}

local IAP_PACKAGE_NAME = {}
IAP_PACKAGE_NAME["com.dragonfall.2500dragoncoins"] = _("新手大礼包")
IAP_PACKAGE_NAME["com.dragonfall.5500dragoncoins"] = _("探险家礼包")
IAP_PACKAGE_NAME["com.dragonfall.12000dragoncoins"] = _("铁血军团礼包")
IAP_PACKAGE_NAME["com.dragonfall.35000dragoncoins"] = _("帝国荣耀礼包")
IAP_PACKAGE_NAME["com.dragonfall.80000dragoncoins"] = _("龙族王朝礼包")

local VIP_IAP_PACKAGE_NAME = {}
VIP_IAP_PACKAGE_NAME["com.dragonfall.2500dragoncoins"] = _("新手")
VIP_IAP_PACKAGE_NAME["com.dragonfall.5500dragoncoins"] = _("探险家")
VIP_IAP_PACKAGE_NAME["com.dragonfall.12000dragoncoins"] = _("铁血军团")
VIP_IAP_PACKAGE_NAME["com.dragonfall.35000dragoncoins"] = _("帝国荣耀")
VIP_IAP_PACKAGE_NAME["com.dragonfall.80000dragoncoins"] = _("龙族王朝")



local DAILY_QUESTS_NAME = {
    [0] = _("修复起重机"),
    _("酿造啤酒"),
    _("植木造林"),
    _("石料开采"),
    _("炼制钢铁"),
    _("收割麦子"),
    _("绘制草图"),
    _("鼓舞士气"),
    _("开拓土地"),
    _("加强戒备"),
}
local PLAYER_ICON = {
    _("初始头像男-1"),
    _("初始头像男-2"),
    _("初始头像男-3"),
    _("初始头像女-1"),
    _("初始头像女-2"),
    _("初始头像女-3"),
    _("刺客"),
    _("将军"),
    _("术士"),
    _("贵妇"),
    _("旧神"),
}
local PLAYER_ICON_UNLOCK = {
    _("默认解锁"),
    _("默认解锁"),
    _("默认解锁"),
    _("默认解锁"),
    _("默认解锁"),
    _("默认解锁"),
    _("击杀累计到达1,000,000后解锁"),
    _("战斗力到达1,000,000后解锁"),
    _("成为VIP10后解锁"),
    _("城堡提升到40级后解锁"),
    _("飞艇探险通关暮光高地第三层后解锁"),
}

local ALLIANCE_LANGUAGE = {
    ALL = _("所有"),
    USA = _("美国"),
    GBR = _("英国"),
    CAN = _("加拿大"),
    FRA = _("法国"),
    ITA = _("意大利"),
    DEU = _("德国"),
    RUS = _("俄罗斯"),
    PRT = _("葡萄牙"),
    CHN = _("中国"),
    TWN = _("台湾"),
    AUS = _("澳大利亚"),
    ESP = _("西班牙"),
    JPN = _("日本"),
    KOR = _("韩国"),
    FIN = _("芬兰"),
}

local ALLIANCE_DECORATE_NAME = {
    decorate_lake = _("湖"),
    decorate_mountain = _("山"),
    decorate_tree = _("树")
}

local SERVER_NAME = {
    bronze = _("青铜级"),
    silver = _("白银级"),
    gold  = _("黄金级"),
    platinum = _("铂金级"),
    diamond = _("钻石级"),
    master = _("大师级"),
}

local PERIOD_TYPE = {
    peace = _("和平期"),
    prepare = _("准备期"),
    fight = _("战争期"),
    protect = _("保护期"),
}
local ALLIANCE_BUFF = {
    ["villageAddPercent"] = _("村落采集速度"),
    ["loyaltyAddPercent"] = _("圣地战玩家获得忠诚值"),
    ["honourAddPercent"] = _("圣地战联盟获得荣耀值"),
    ["dragonExpAddPercent"] = _("巨龙经验值"),
    ["bloodAddPercent"] = _("英雄之血"),
    ["marchSpeedAddPercent"] = _("行军速度"),
    ["dragonStrengthAddPercent"] = _("巨龙力量"),
    ["monsterLevel"] = _("野怪等级"),
}
local TERRAIN_FUNCTION = {
    grassLand = _("草地产出绿龙材料，更容易培养绿龙"),
    desert= _("沙漠产出红龙材料,更容易培养红龙"),
    iceField = _("雪地产出蓝龙材料，更容易培养蓝龙"),
}
local USER_AGREEMENT = {
    agreement = _("Batcatstudio游戏用户使用许可协议本地化ID")
}
return {
    equip_material = EQUIP_MATERIAL_LOCALIZE,
    equip = EQUIP_LOCALIZE,
    equip_suit = EQUIP_SUIT,
    equip_make = EQUIP_LOCALIZE_MAKE,
    dragon = DRAGON_LOCALIZE,
    dragon_only = DRAGON_ONLY,
    materials = MATERIALS_MAP,
    body = BODY_LOCALIZE,
    dragon_skill_effection = DRAGON_SKILL_EFFECTION,
    dragon_skill = DRAGON_SKILL,
    dragon_buff_effection = DRAGON_BUFF_EFFECTION,
    building_description = BUILDING_DESCRIPTION,
    building_name = BUILDING_NAME,
    alliance_title = ALLIANCE_TITLE,
    alliance_events = ALLIANCE_EVENTS,
    alliance_notice = ALLIANCE_NOTICE,
    soldier_name = SOLDIER_NAME,
    soldier_material = SOLDIER_MATERIAL,
    soldier_category = SOLDIER_CATEGORY,
    soldier_status = SOLDIER_STATUS,
    dragon_status = DRAGON_STATUS,
    fight_reward = FIGHT_REWARD,
    soldier_category_map = SOLDIER_CATEGORY_MAP,
    getSoldierCategoryByName = function(soldier_name) return SOLDIER_CATEGORY[SOLDIER_CATEGORY_MAP[soldier_name]] end,
    getMilitaryTechnologyName = function(tech_name)
        local soldier1, soldier2 = unpack(string.split(tech_name, "_"))
        if soldier2 ~= "hpAdd" then
            return string.format(_("%s对%s的攻击"), SOLDIER_CATEGORY[soldier1], SOLDIER_CATEGORY[soldier2])
        end
        return string.format(_("%s血量增加"), SOLDIER_CATEGORY[soldier1])
    end,
    alliance_authority_list = ALLIANCE_AUTHORITY_LIST,
    village_name = VILLAGE_NAME,
    terrain = TERRAIN,
    hate_dragon = HATE_DRAGON,
    dragon_buffer = DRAGON_BUFFER,
    sell_type = SELL_TYPE,
    productiontechnology_name = PRODUCTIONTECHNOLOGY_NAME,
    productiontechnology_buffer = PRODUCTIONTECHNOLOGY_BUFFER,
    productiontechnology_buffer_complete = PRODUCTIONTECHNOLOGY_BUFFER_COMPLETE,
    getBuildingLocalizedKeyByBuildingType = getBuildingLocalizedKeyByBuildingType,
    getHouseLocalizedKeyByBuildingType = getHouseLocalizedKeyByBuildingType,
    getLocaliedKeyByType = getLocaliedKeyByType,
    game_language = GAME_LANGUAGE,
    wonder_name = WONDER_NAME,
    wonder_title_name = WONDER_TITLE_NAME,
    wonder_title_buff = WONDER_TITLE_BUFF,
    daily_tasks = DAILY_TASKS,
    selenaquestion_tips = SELENAQUESTION_TIPS,
    alliance_buildings = ALLIANCE_BUILDINGS,
    iap_package_name = IAP_PACKAGE_NAME,
    vip_iap_package_name = VIP_IAP_PACKAGE_NAME,
    daily_quests_name = DAILY_QUESTS_NAME,
    player_icon = PLAYER_ICON,
    player_icon_unlock = PLAYER_ICON_UNLOCK,
    alliance_language = ALLIANCE_LANGUAGE,
    alliance_decorate_name = ALLIANCE_DECORATE_NAME,
    shrine_desc = SHRINE_DESC,
    server_name = SERVER_NAME,
    equip_material_desc_localize = EQUIP_MATERIAL_DESC_LOCALIZE,
    materials_desc_map = MATERIALS_DESC_MAP,
    equip_material_desc_localize  = EQUIP_MATERIAL_DESC_LOCALIZE,
    soldier_desc_material = SOLDIER_DESC_MATERIAL,
    mails = MAILS,
    server_errors = SERVER_ERRORS,
    terrain_function = TERRAIN_FUNCTION,
    user_agreement = USER_AGREEMENT,
    period_type = PERIOD_TYPE,
    alliance_buff = ALLIANCE_BUFF,
}





