local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIScrollView = import(".UIScrollView")
local Localize = import("..utils.Localize")
local UIListView = import(".UIListView")
local WidgetSlider = import("..widget.WidgetSlider")
local WidgetSelectDragon = import("..widget.WidgetSelectDragon")
local WidgetInput = import("..widget.WidgetInput")
local SoldierManager = import("..entity.SoldierManager")

local Corps = import(".Corps")
local UILib = import(".UILib")
local window = import("..utils.window")
local normal = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special

local GameUIAllianceSendTroops = UIKit:createUIClass("GameUIAllianceSendTroops","GameUIWithCommonHeader")
local soldier_arrange = {
    swordsman = {row = 4, col = 2},
    ranger = {row = 4, col = 2},
    lancer = {row = 3, col = 1},
    catapult = {row = 2, col = 1},

    horseArcher = {row = 3, col = 1},
    ballista = {row = 2, col = 1},
    skeletonWarrior = {row = 4, col = 2},
    skeletonArcher = {row = 4, col = 2},

    deathKnight = {row = 3, col = 1},
    meatWagon = {row = 2, col = 1},
    priest = {row = 3, col = 1},
    demonHunter = {row = 3, col = 1},

    paladin = {row = 4, col = 2},
    steamTank = {row = 2, col = 1},
    sentinel = {row = 4, col = 2},
    crossbowman = {row = 4, col = 2},
}
local soldier_ani_width = {
    swordsman = 180,
    ranger = 180,
    lancer = 180,
    catapult = 180,

    sentinel = 180,
    crossbowman = 180,
    horseArcher = 180,
    ballista = 180,

    skeletonWarrior = 180,
    skeletonArcher = 180,
    deathKnight = 180,
    meatWagon = 180,
}


function GameUIAllianceSendTroops:GetMyAlliance()
    return Alliance_Manager:GetMyAlliance()
end

function GameUIAllianceSendTroops:GetEnemyAlliance()
    return Alliance_Manager:GetEnemyAlliance()
end

function GameUIAllianceSendTroops:GetMarchTime(soldier_show_table)
    local mapObject = self:GetMyAlliance():GetAllianceMap():FindMapObjectById(self:GetMyAlliance():GetSelf():MapId())
    local fromLocation = mapObject.location
    local target_alliance = self.targetIsMyAlliance and self:GetMyAlliance() or self:GetEnemyAlliance()
    local time = DataUtils:getPlayerSoldiersMarchTime(soldier_show_table,self:GetMyAlliance(),fromLocation,target_alliance,self.toLocation)
    local buffTime = DataUtils:getPlayerMarchTimeBuffTime(time)
    return time,buffTime
end

function GameUIAllianceSendTroops:RefreshMarchTimeAndBuff(soldier_show_table)
    local time,buffTime = self:GetMarchTime(soldier_show_table)
    self.march_time:setString(GameUtils:formatTimeStyle1(time))
    self.buff_reduce_time:setString(string.format("-(%s)",GameUtils:formatTimeStyle1(buffTime)))
    self.total_march_time = time - buffTime
end

function GameUIAllianceSendTroops:ctor(march_callback,params)
    checktable(params)
    self.isPVE = type(params.isPVE) == 'boolean' and params.isPVE or false
    self.returnCloseAction = type(params.returnCloseAction) == 'boolean' and params.returnCloseAction or false
    self.toLocation = params.toLocation or cc.p(0,0)
    self.targetIsMyAlliance = type(params.targetIsMyAlliance) == 'boolean' and params.targetIsMyAlliance or true
    self.terrain = User:Terrain()
    GameUIAllianceSendTroops.super.ctor(self,City,_("准备进攻"))
    local manager = ccs.ArmatureDataManager:getInstance()
    for _, anis in pairs(UILib.soldier_animation_files) do
        for _, v in pairs(anis) do
            manager:addArmatureFileInfo(v)
        end
    end
    self.alliance = Alliance_Manager:GetMyAlliance()
    self.soldier_manager = City:GetSoldierManager()
    self.dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    self.soldiers_table = {}
    self.march_callback = march_callback

    -- 默认选中最强的并且可以出战的龙,如果都不能出战，则默认最强龙
    self.dragon = self.dragon_manager:GetDragon(self.dragon_manager:GetCanFightPowerfulDragonType()) or self.dragon_manager:GetDragon(self.dragon_manager:GetPowerfulDragonType())
end

function GameUIAllianceSendTroops:OnMoveInStage()
    GameUIAllianceSendTroops.super.OnMoveInStage(self)

    self:SelectDragonPart()
    self:SelectSoldiers()

    local function __getSoldierConfig(soldier_type,level)
        local level = level or 1
        return normal[soldier_type.."_"..level] or SPECIAL[soldier_type]
    end

    local max_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("最大"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
    max_btn:onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            if self.is_now_max then
                self:AdapterMaxButton()
                for k,item in pairs(self.soldiers_table) do
                    item:SetSoldierCount(0)
                end
            else
                for k,item in pairs(self.soldiers_table) do
                    item:SetSoldierCount(0)
                end
                self:AdapterMaxButton()
                local max_soldiers_citizen = 0
                for k,item in pairs(self.soldiers_table) do
                    local soldier_type,level,_,max_num = item:GetSoldierInfo()
                    max_soldiers_citizen=max_soldiers_citizen+max_num*__getSoldierConfig(soldier_type,level).citizen
                end
                if self.dragon:LeadCitizen()<max_soldiers_citizen then
                    -- 拥有士兵数量大于派兵数量上限时，首先选取power最高的兵种，依次到达最大派兵上限为止
                    local s_table = self.soldiers_table
                    table.sort(s_table, function(a, b)
                        local soldier_type,level = a:GetSoldierInfo()
                        local a_power = __getSoldierConfig(soldier_type,level).power
                        local soldier_type,level = b:GetSoldierInfo()
                        local b_power = __getSoldierConfig(soldier_type,level).power
                        return a_power > b_power
                    end)
                    local max_troop_num = self.dragon:LeadCitizen()
                    for k,item in ipairs(s_table) do
                        local soldier_type,level,_,max_num = item:GetSoldierInfo()
                        local max_citizen = __getSoldierConfig(soldier_type,level).citizen*max_num
                        if max_citizen<=max_troop_num then
                            max_troop_num = max_troop_num - max_citizen
                            item:SetSoldierCount(max_num)
                        else
                            local num = math.floor(max_troop_num/__getSoldierConfig(soldier_type,level).citizen)
                            item:SetSoldierCount(num)
                            break
                        end
                    end
                else
                    for k,item in pairs(self.soldiers_table) do
                        local _,_,_,max_num = item:GetSoldierInfo()
                        item:SetSoldierCount(max_num)
                    end
                end
            end
            self:RefreashSoldierShow()
        end
    end):align(display.LEFT_CENTER,window.left+50,window.top-910):addTo(self:GetView())
    self.max_btn = max_btn

    local march_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},nil,nil)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("行军"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                assert(tolua.type(self.march_callback)=="function")
                if not self.dragon then
                    UIKit:showMessageDialog(_("提示"),_("您还没有龙,快去孵化一只巨龙吧"))
                    return
                end
                local dragonType = self.dragon:Type()
                local soldiers = self:GetSelectSoldier()

                if not self.dragon:IsFree() and not self.dragon:IsDefenced() then
                    UIKit:showMessageDialog(_("提示"),_("龙未处于空闲状态"))
                    return
                elseif self.dragon:Hp()<1 then
                    UIKit:showMessageDialog(_("提示"),_("选择的龙已经死亡"))
                    return
                elseif self.show:IsExceed() then
                    UIKit:showMessageDialog(_("提示"),_("派出的部队超过了所选龙的带兵上限"))
                    return
                elseif #soldiers == 0 then
                    UIKit:showMessageDialog(_("提示"),_("请选择要派遣的部队"))
                    return
                elseif self.alliance:GetAllianceBelvedere():IsReachEventLimit() then
                    local dialog = UIKit:showMessageDialog(_("提示"),_("没有空闲的行军队列"))
                    if self.alliance:GetAllianceBelvedere():GetMarchLimit() < 2 then
                        dialog:CreateOKButton(
                            {
                                listener = function ()
                                    UIKit:newGameUI('GameUIWathTowerRegion',City,'march'):AddToCurrentScene(true)
                                    self:LeftButtonClicked()
                                end,
                                btn_name= _("前往解锁")
                            }
                        )
                    end
                    return
                end
                if self.dragon:IsHpLow() then
                    UIKit:showMessageDialog(_("行军"),_("您的龙的HP低于20%,有很大几率阵亡,确定要派出吗?"))
                        :CreateOKButton(
                            {
                                listener =  function ()
                                    if self.dragon:IsDefenced() then
                                        NetManager:getCancelDefenceDragonPromise():done(function()
                                            -- self.march_callback(dragonType,soldiers)
                                            -- -- 确认派兵后关闭界面
                                            -- self:LeftButtonClicked()
                                            self:CallFuncMarch_Callback(dragonType,soldiers)
                                        end)
                                    else
                                        -- self.march_callback(dragonType,soldiers)
                                        -- -- 确认派兵后关闭界面
                                        -- self:LeftButtonClicked()
                                        self:CallFuncMarch_Callback(dragonType,soldiers)
                                    end
                                end
                            }
                        )
                else
                    if self.dragon:IsDefenced() then
                        NetManager:getCancelDefenceDragonPromise():done(function()
                            -- self.march_callback(dragonType,soldiers)
                            -- -- 确认派兵后关闭界面
                            -- self:LeftButtonClicked()
                            self:CallFuncMarch_Callback(dragonType,soldiers)
                        end)
                    else
                        -- self.march_callback(dragonType,soldiers)
                        -- 确认派兵后关闭界面
                        -- self:LeftButtonClicked()
                        self:CallFuncMarch_Callback(dragonType,soldiers)
                    end
                end
            end

        end):align(display.RIGHT_CENTER,window.right-50,window.top-910):addTo(self:GetView())
    if not self.isPVE then
        --行军所需时间
        display.newSprite("hourglass_30x38.png", window.cx, window.top-910)
            :addTo(self):scale(0.6)
        self.march_time = UIKit:ttfLabel({
            text = "00:00:00",
            size = 18,
            color = 0x403c2f
        }):align(display.LEFT_CENTER,window.cx+20,window.top-900):addTo(self:GetView())

        -- 科技减少行军时间
        self.buff_reduce_time = UIKit:ttfLabel({
            text = "-(00:00:00)",
            size = 18,
            color = 0x068329
        }):align(display.LEFT_CENTER,window.cx+20,window.top-920):addTo(self:GetView())
    end
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
end

function GameUIAllianceSendTroops:CallFuncMarch_Callback(dragonType,soldiers)
    if not self.returnCloseAction then
        self.march_callback(dragonType,soldiers,self.total_march_time)
        self:LeftButtonClicked()
    else
        self.march_callback(dragonType,soldiers,self.total_march_time,self)
    end
end

function GameUIAllianceSendTroops:AdapterMaxButton(max)
    local btn_labe = max and _("最大") or self.is_now_max and _("最大") or _("最小")
    if max then
        self.is_now_max = false
    else
        self.is_now_max = not self.is_now_max
    end
    self.max_btn:setButtonLabel(UIKit:ttfLabel({
        text = btn_labe,
        size = 24,
        color = 0xffedae,
        shadow= true
    }))

end
function GameUIAllianceSendTroops:SelectDragonPart()
    if not self.dragon then return end
    local dragon = self.dragon

    local dragon_frame = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_CENTER, window.left+47,window.top-425)
        :addTo(self:GetView())

    local dragon_bg = display.newSprite("chat_hero_background.png")
        :align(display.LEFT_CENTER, 7,dragon_frame:getContentSize().height/2)
        :addTo(dragon_frame)
    self.dragon_img = cc.ui.UIImage.new(dragon:Type()..".png")
        :align(display.CENTER, dragon_bg:getContentSize().width/2, dragon_bg:getContentSize().height/2+5)
        :addTo(dragon_bg)
    local box_bg = display.newSprite("box_426X126.png")
        :align(display.LEFT_CENTER, dragon_frame:getContentSize().width, dragon_frame:getContentSize().height/2)
        :addTo(dragon_frame)
    -- 龙，等级
    self.dragon_name = UIKit:ttfLabel({
        text = Localize.dragon[dragon:Type()].."（LV ".. dragon:Level()..")",
        size = 22,
        color = 0x514d3e,
    }):align(display.LEFT_CENTER,20,80)
        :addTo(box_bg)
    -- 龙活力
    self.dragon_vitality = UIKit:ttfLabel({
        text = _("生命值")..dragon:Hp().."/"..dragon:GetMaxHP(),
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_CENTER,20,30)
        :addTo(box_bg)

    local send_troops_btn = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("选择"),
            size = 22,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SelectDragon()
            end
        end):align(display.CENTER,340,40):addTo(box_bg)

end
function GameUIAllianceSendTroops:RefreashDragon(dragon)
    self.dragon_img:setTexture(dragon:Type()..".png")
    self.dragon_name:setString(_(dragon:Type()).."（LV "..dragon:Level().."）")
    self.dragon_vitality:setString(_("生命值")..dragon:Hp().."/"..dragon:GetMaxHP())
    self.dragon = dragon
    print("RefreashDragon>>>>",dragon:Type())
    self:RefreashSoldierShow()
end

function GameUIAllianceSendTroops:SelectDragon()
    WidgetSelectDragon.new(
        {
            title = _("选中出战的巨龙"),
            btns = {
                {
                    btn_label = _("确定"),
                    btn_callback = function (selectDragon)
                        self:RefreashDragon(selectDragon)
                    end,
                },
            },

        }
    ):addTo(self,1000)
end
function GameUIAllianceSendTroops:SelectSoldiers()
    local list ,listnode=  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 366),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(self:GetView()):pos(window.cx, window.top-685)
    listnode:align(display.CENTER)

    self.soldier_listview = list
    local function addListItem(name,star,max_soldier)
        if max_soldier<1 then
            return
        end
        local item = list:newItem()
        local w,h = 568,128
        item:setItemSize(w, h)
        local content = display.newSprite("back_ground_568X128.png")
        item.max_soldier = max_soldier
        -- progress
        local slider = WidgetSlider.new(display.LEFT_TO_RIGHT,  {bar = "slider_bg_461x24.png",
            progress = "slider_progress_445x14.png",
            button = "slider_btn_66x66.png"}, {max = item.max_soldier}):addTo(content)
            :align(display.RIGHT_CENTER, w-5, 35)
            :scale(0.95)
        -- soldier name
        local soldier_name_label = UIKit:ttfLabel({
            text = Localize.soldier_name[name],
            size = 24,
            color = 0x403c2f
        }):align(display.LEFT_CENTER,140,90):addTo(content)

        local function getMax()
            local usable_citizen=self.dragon:LeadCitizen()

            for k,item in pairs(self.soldiers_table) do
                local soldier_t,soldier_l,soldier_n =item:GetSoldierInfo()
                local soldier_config = normal[soldier_t.."_"..soldier_l] or SPECIAL[soldier_t]
                if name~=soldier_t then
                    usable_citizen =usable_citizen-soldier_config.citizen*soldier_n
                end
            end
            local soldier_config = normal[name.."_"..star] or SPECIAL[name]
            return math.floor(usable_citizen/soldier_config.citizen)
        end

        local text_btn = WidgetPushButton.new({normal = "back_ground_83x32.png",pressed = "back_ground_83x32.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    local p = {
                        current = math.floor(slider:getSliderValue()),
                        max= math.min(getMax(),max_soldier),
                        min=0,
                        callback = function ( edit_value )
                            if edit_value ~= slider_value then
                                slider:setSliderValue(edit_value)
                                -- 只要改变，就把最大按钮置为最大
                                self:AdapterMaxButton(true)
                                self:RefreashSoldierShow()
                            end
                        end
                    }
                    UIKit:newWidgetUI("WidgetInput", p):AddToCurrentScene()
                end
            end):align(display.CENTER,  340,90):addTo(content)
        local btn_text = UIKit:ttfLabel({
            text = 0,
            size = 22,
            color = 0x403c2f,
        }):addTo(text_btn):align(display.CENTER)

        slider:onSliderValueChanged(function(event)
            btn_text:setString(math.floor(event.value))
        end)
        slider:addSliderReleaseEventListener(function(event)
            self:RefreashSoldierShow()
            -- 只要改变，就把最大按钮置为最大
            self:AdapterMaxButton(true)
        end)
        slider:setDynamicMaxCallBakc(function (value)
            local usable_citizen=self.dragon:LeadCitizen()
            for k,item in pairs(self.soldiers_table) do
                local soldier_t,soldier_l,soldier_n =item:GetSoldierInfo()
                local soldier_config = normal[soldier_t.."_"..soldier_l] or SPECIAL[soldier_t]
                if name~=soldier_t then
                    usable_citizen =usable_citizen-soldier_config.citizen*soldier_n
                end
            end
            local soldier_config = normal[name.."_"..star] or SPECIAL[name]
            if soldier_config.citizen*math.floor(value)< usable_citizen+1 then
                return math.floor(value)
            else
                return math.floor(usable_citizen/soldier_config.citizen)
            end
        end)


        local soldier_total_count = UIKit:ttfLabel({
            text = string.format("/ %d", item.max_soldier),
            size = 20,
            color = 0x403c2f
        }):addTo(content)
            :align(display.LEFT_CENTER, 400,90)

        -- 士兵头像
        local soldier_ui_config = UILib.soldier_image[name][star]
        display.newSprite(UILib.soldier_color_bg_images[name]):addTo(content)
            :align(display.CENTER,60,64):scale(104/128)
        local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,60,64):addTo(content):scale(104/128)
        local soldier_head_bg  = display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):pos(soldier_head_icon:getContentSize().width/2,soldier_head_icon:getContentSize().height/2)

        item:addContent(content)
        list:addItem(item)
        function item:SetMaxSoldier(max_soldier)
            self.max_soldier = max_soldier
            slider:SetMax(max_soldier)
            soldier_total_count:setString(string.format("/ %d", self.max_soldier))
        end

        function item:GetSoldierInfo()
            return name,star,math.floor(slider:getSliderValue()), self.max_soldier
        end
        function item:SetSoldierCount(count)
            btn_text:setString(count)
            slider:setSliderValue(count)
        end
        return item
    end
    local sm = self.soldier_manager
    local soldiers = {}
    local soldier_map = {
        "swordsman",
        "ranger",
        "lancer",
        "catapult",
        "sentinel",
        "crossbowman",
        "horseArcher",
        "ballista",
        "skeletonWarrior",
        "skeletonArcher",
        "deathKnight",
        "meatWagon",
    -- "priest",
    -- "demonHunter",
    -- "paladin",
    -- "steamTank",
    }
    local map_s = sm:GetSoldierMap()
    for _,name in pairs(soldier_map) do
        local soldier_num = map_s[name]
        if soldier_num>0 then
            table.insert(soldiers, {name = name,level = sm:GetStarBySoldierType(name), max_num = soldier_num})
        end
    end
    for k,v in pairs(soldiers) do
        table.insert(self.soldiers_table, addListItem(v.name,v.level,v.max_num))
    end
    list:reload()

end
function GameUIAllianceSendTroops:CreateBetweenBgAndTitle()
    GameUIAllianceSendTroops.super.CreateBetweenBgAndTitle(self)
    self.show = self:CreateTroopsShow()
end
function GameUIAllianceSendTroops:RefreashSoldierShow()
    local soldier_show_table = {}
    for k,item in pairs(self.soldiers_table) do
        local soldier_type,soldier_level,soldier_number =item:GetSoldierInfo()
        local soldier_config = normal[soldier_type.."_"..soldier_level] or SPECIAL[soldier_type]
        if soldier_number>0 then
            table.insert(soldier_show_table, {
                soldier_type = soldier_type,
                power = soldier_config.power*soldier_number,
                soldier_num = soldier_number,
                soldier_weight = soldier_config.load*soldier_number,
                soldier_citizen = soldier_config.citizen*soldier_number,
                soldier_march = soldier_config.march,
                soldier_star = soldier_level
            })
        end
    end
    self.show:ShowOrRefreasTroops(soldier_show_table)
    if not self.isPVE then
        self:RefreshMarchTimeAndBuff(soldier_show_table)
    end
end

function GameUIAllianceSendTroops:GetSelectSoldier()
    local soldiers = {}
    for k,item in pairs(self.soldiers_table) do
        local soldier_type,soldier_level,soldier_number =item:GetSoldierInfo()
        if soldier_number>0 then
            table.insert(soldiers, {
                name = soldier_type,
                count = soldier_number,
            })
        end
    end
    return soldiers
end
function GameUIAllianceSendTroops:CreateTroopsShow()
    local parent = self
    local grass_width,grass_height =611,275
    local TroopShow = display.newNode()
    TroopShow:setContentSize(cc.size(grass_width,grass_height))
    TroopShow:align(display.BOTTOM_LEFT, window.cx-304, window.top_bottom-250)
    local land_image = {
        desert = "battle_bg_desert_611x275.png",
        iceField = "battle_bg_iceField_611x275.png",
        grassLand = "battle_bg_grass_611x275.png"
    }
    local land_bg = land_image[self.terrain]
    display.newSprite(land_bg)
        :align(display.LEFT_BOTTOM,window.cx-304, window.top_bottom-250):addTo(self:GetView())
    TroopShow.offset_x = 0
    TroopShow.bound_box_width = grass_width

    local scrollView = UIScrollView.new({
        viewRect = cc.rect(window.cx-304, window.top_bottom-250, 611, 275),
    -- bgColor = UIKit:hex2c4b(0x7a000000),
    }):addScrollNode(TroopShow)
        :setBounceable(false)
        :setDirection(UIScrollView.DIRECTION_HORIZONTAL)
        :addTo(self:GetView())
    -- 战斗力，人口，负重信息展示背景框
    local info_bg = cc.LayerColor:create(UIKit:hex2c4b(0x7a000000))
        :pos(window.left+14, window.top-343)
        :addTo(self:GetView())
    info_bg:setTouchEnabled(false)
    info_bg:setContentSize(620, 46)
    -- line
    local line = display.newSprite("line_624x4.png")
        :align(display.CENTER, window.cx+2, window.top-343)
        :addTo(self:GetView())

    local function createInfoItem(title,value)
        local info = cc.Layer:create()
        local split_str = string.split(value, "/")
        local total_width
        if #split_str > 1 then
            local num_1 = tonumber(split_str[1])
            local num_2 = tonumber(split_str[2])
            local value_label_1 = UIKit:ttfLabel({
                text = num_1,
                size = 18,
                color = num_1 > num_2 and 0x7e0000 or 0xffedae,
            })
            local value_label_2 = UIKit:ttfLabel({
                text = "/"..num_2,
                size = 18,
                color = 0xffedae,
            })
            total_width = value_label_1:getContentSize().width + value_label_2:getContentSize().width
            value_label_1:align(display.BOTTOM_LEFT,0,0)
                :addTo(info)
            value_label_2:align(display.BOTTOM_LEFT,value_label_1:getContentSize().width,0)
                :addTo(info)
            info:setContentSize(total_width, 45)
        else
            local value_label = UIKit:ttfLabel({
                text = value,
                size = 18,
                color = 0xffedae,
            })
            value_label:align(display.BOTTOM_CENTER,value_label:getContentSize().width/2,0)
                :addTo(info)
            total_width = value_label:getContentSize().width
            info:setContentSize(total_width, 45)
        end
        UIKit:ttfLabel({
            text = title,
            size = 16,
            color = 0xbbae80,
        }):align(display.BOTTOM_CENTER,total_width/2,20)
            :addTo(info)
        return info
    end

    function TroopShow:RefreshScrollNode(current_x)
        -- 因为士兵动画的锚点为CENTER，需要的滑动区域的宽度需要多加士兵动画设计宽度180/2
        current_x = current_x - 180/2
        if current_x<grass_width then
            table.insert(self.soldier_crops,display.newSprite(land_bg)
                :align(display.LEFT_BOTTOM,0,0):addTo(self))
        end
        if current_x<0 then
            local need_bg_count = math.ceil(math.abs(current_x)/grass_width)
            for i=1,need_bg_count do
                table.insert(self.soldier_crops,display.newSprite(land_bg)
                    :align(display.LEFT_BOTTOM,-grass_width*i,0):addTo(self))
            end
            self.offset_x = grass_width -(math.abs(current_x)-(need_bg_count-1)*grass_width)
            self.bound_box_width = math.abs(current_x)+grass_width
        else
            self.offset_x = 0
            self.bound_box_width = grass_width
        end
    end
    function TroopShow:getCascadeBoundingBox()
        local rc
        local func = tolua.getcfunction(self, "getCascadeBoundingBox")
        if func then
            rc = func(self)
        end

        rc.origin = {x=rc.x+self.offset_x, y=rc.y}
        rc.size = {width=self.bound_box_width, height=rc.height}
        rc.width=self.bound_box_width
        rc.x=rc.x+self.offset_x
        rc.containsPoint = isPointIn
        return rc
    end
    function TroopShow:SetPower(power)
        local power_item = createInfoItem(_("战斗力"),string.formatnumberthousands(power))
            :align(display.CENTER,30,0)
            :addTo(info_bg)
        return self
    end
    function TroopShow:SetCitizen(citizen)
        local citizen_item = createInfoItem(_("部队容量"),citizen.."/"..parent.dragon:LeadCitizen())
        citizen_item:align(display.CENTER,310-citizen_item:getContentSize().width/2,0)
            :addTo(info_bg)
        self.exceed_lead = citizen > parent.dragon:LeadCitizen()
        return self
    end
    function TroopShow:IsExceed()
        return self.exceed_lead
    end
    function TroopShow:SetWeight(weight)
        local weight_item = createInfoItem(_("负重"),string.formatnumberthousands(weight))
        weight_item:align(display.CENTER,620-weight_item:getContentSize().width-30,0)
            :addTo(info_bg)
        return self
    end
    function TroopShow:NewCorps(soldier,soldier_power,star)
        local arrange = soldier_arrange[soldier]
        local corps = Corps.new(soldier, star , arrange.row, arrange.col)
        local label = display.newSprite("back_ground_122x24.png")
            :align(display.CENTER, 0, -50)
            :addTo(corps)
        display.newSprite("dragon_strength_27x31.png"):pos(10,label:getContentSize().height/2)
            :addTo(label)
        UIKit:ttfLabel({
            text = soldier_power,
            size = 18,
            color = 0xffedae,
        }):align(display.CENTER,label:getContentSize().width/2,label:getContentSize().height/2)
            :addTo(label)
        return corps
    end
    function TroopShow:SetSoldiers(soldiers)
        self.soldiers = soldiers
    end
    function TroopShow:GetSoldiers()
        return self.soldiers
    end
    function TroopShow:RemoveAllSoldierCrops()
        if self.soldier_crops then
            for i,v in ipairs(self.soldier_crops) do
                v:removeFromParent(true)
            end
        end
        self.offset_x = 0
        self.bound_box_width = grass_width
    end
    function TroopShow:ShowOrRefreasTroops(soldiers)
        -- 按兵种战力排序
        table.sort(soldiers, function(a, b)
            return a.power > b.power
        end)

        -- 更新
        self:SetSoldiers(soldiers)
        self:RemoveAllSoldierCrops()
        local y  = 110
        local x = 681
        local total_power , total_weight, total_citizen =0,0,0
        self.soldier_crops = {}
        for index,v in pairs(soldiers) do
            local corp = self:NewCorps(v.soldier_type,v.power,v.soldier_star):addTo(self,2)
            if v.soldier_type ~= "catapult" and v.soldier_type ~= "ballista" and v.soldier_type ~= "meatWagon" then
                corp:PlayAnimation("idle_90")
            else
                corp:PlayAnimation("move_90")
            end
            table.insert(self.soldier_crops,corp)
            x = x - soldier_ani_width[v.soldier_type]

            corp:pos(x,y)
            total_power = total_power + v.power
            total_weight = total_weight + v.soldier_weight
            total_citizen = total_citizen + v.soldier_citizen
        end
        self:RefreshScrollNode(x)
        info_bg:removeAllChildren()
        self:SetPower(total_power)
        self:SetWeight(total_weight)
        self:SetCitizen(total_citizen)
    end

    return TroopShow
end
function GameUIAllianceSendTroops:OnSoliderCountChanged( soldier_manager,changed_map )
    for i,soldier_type in ipairs(changed_map) do
        for _,item in pairs(self.soldiers_table) do
            local item_type = item:GetSoldierInfo()
            if soldier_type == item_type then
                item:SetMaxSoldier(City:GetSoldierManager():GetCountBySoldierType(item_type))
            end
        end
    end
end
function GameUIAllianceSendTroops:onExit()
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)

    GameUIAllianceSendTroops.super.onExit(self)
end

return GameUIAllianceSendTroops
























































