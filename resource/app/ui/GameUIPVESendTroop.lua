--
-- Author: Kenny Dai
-- Date: 2015-02-03 16:58:16
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIScrollView = import(".UIScrollView")
local Localize = import("..utils.Localize")
local StarBar = import(".StarBar")
local UIListView = import(".UIListView")
local WidgetSlider = import("..widget.WidgetSlider")
local WidgetSelectDragon = import("..widget.WidgetSelectDragon")
local WidgetInput = import("..widget.WidgetInput")
local DragonManager = import("..entity.DragonManager")


local UILib = import(".UILib")
local window = import("..utils.window")
local normal = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special

local GameUIPVESendTroop = UIKit:createUIClass("GameUIPVESendTroop","GameUIWithCommonHeader")
GameUIPVESendTroop.dragonType = nil

function GameUIPVESendTroop:ctor(pve_soldiers,march_callback)
    GameUIPVESendTroop.super.ctor(self,City,_("准备进攻"))
    self.march_callback = march_callback
    self.pve_soldiers = pve_soldiers
    dump(pve_soldiers,"pve_soldiers")
    self.dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    self.soldiers_table = {}
    -- 默认选中最强的并且可以出战的龙,如果都不能出战，则默认最强龙
    self.dragon = self.dragon_manager:GetDragon(GameUIPVESendTroop.dragonType or self.dragon_manager:GetCanFightPowerfulDragonType()) or self.dragon_manager:GetDragon(self.dragon_manager:GetPowerfulDragonType())
    GameUIPVESendTroop.dragonType = self.dragon:Type()
end

function GameUIPVESendTroop:OnMoveInStage()

    self:SelectDragonPart()
    self:SelectSoldiers()

    local function __getSoldierConfig(name,level)
        local level = level or 1
        return normal[name.."_"..level] or SPECIAL[name]
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
                    local name,level,_,max_num = item:GetSoldierInfo()
                    max_soldiers_citizen=max_soldiers_citizen+max_num*__getSoldierConfig(name,level).citizen
                end
                if self.dragon:LeadCitizen()<max_soldiers_citizen then
                    -- 拥有士兵数量大于派兵数量上限时，首先选取power最高的兵种，依次到达最大派兵上限为止
                    local s_table = self.soldiers_table
                    table.sort(s_table, function(a, b)
                        local name,level = a:GetSoldierInfo()
                        local a_power = __getSoldierConfig(name,level).power
                        local name,level = b:GetSoldierInfo()
                        local b_power = __getSoldierConfig(name,level).power
                        return a_power > b_power
                    end)
                    local max_troop_num = self.dragon:LeadCitizen()
                    for k,item in ipairs(s_table) do
                        local name,level,_,max_num = item:GetSoldierInfo()
                        local max_citizen = __getSoldierConfig(name,level).citizen*max_num
                        if max_citizen<=max_troop_num then
                            max_troop_num = max_troop_num - max_citizen
                            item:SetSoldierCount(max_num)
                        else
                            local num = math.floor(max_troop_num/__getSoldierConfig(name,level).citizen)
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

    self.march_btn = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("进攻"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                assert(tolua.type(self.march_callback)=="function")
                if not self.dragon then
                    UIKit:showMessageDialog(_("主人"),_("快去孵化一只巨龙吧"))
                    return
                end
                local dragonType = self.dragon:Type()
                local soldiers = self:GetSelectSoldier()
                if not self.dragon:IsFree() and not self.dragon:IsDefenced() then
                    UIKit:showMessageDialog(_("主人"),_("龙未处于空闲状态"))
                    return
                elseif self.dragon:IsDead() then
                    UIKit:showMessageDialog(_("提示"),_("选择的龙已经死亡")):CreateCancelButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIDragonEyrieMain", City, City:GetFirstBuildingByType("dragonEyrie"), "dragon", false, self.dragon:Type()):AddToCurrentScene(true)
                                self:LeftButtonClicked()
                            end,
                            btn_name= _("复活"),
                            btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"}
                        }
                    )
                    return
                elseif #soldiers == 0 then
                    UIKit:showMessageDialog(_("主人"),_("请选择要派遣的部队"))
                    return
                end
                local has_special_soldier = false
                for k,v in pairs(self.pve_soldiers) do
                    if SPECIAL[v.name] then
                        has_special_soldier = true
                        break
                    end
                end
                UIKit:showSendTroopMessageDialog(function ()
                    self.march_callback(dragonType,soldiers)
                    -- 确认派兵后关闭界面
                    self:LeftButtonClicked()
                end, "soldierMaterials", _("士兵"), not has_special_soldier)
            end
        end):align(display.RIGHT_CENTER,window.right-50,window.top-910):addTo(self:GetView())


    User:AddListenOnType(self, "soldiers")
    City:GetDragonEyrie():GetDragonManager():AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)

    GameUIPVESendTroop.super.OnMoveInStage(self)
end
function GameUIPVESendTroop:AdapterMaxButton(max)
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
function GameUIPVESendTroop:SelectDragonPart()
    if not self.dragon then return end
    local dragon = self.dragon

    local dragon_frame = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_CENTER, window.left+47,window.top-415)
        :addTo(self:GetView())

    local dragon_bg = display.newSprite("dragon_bg_114x114.png")
        :align(display.LEFT_CENTER, 7,dragon_frame:getContentSize().height/2)
        :addTo(dragon_frame)
    self.dragon_img = cc.ui.UIImage.new(UILib.dragon_head[dragon:Type()])
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
        text = _("生命值")..string.formatnumberthousands(dragon:Hp()).."/"..string.formatnumberthousands(dragon:GetMaxHP()),
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
        end):align(display.CENTER,330,35):addTo(box_bg)

end
function GameUIPVESendTroop:RefreashDragon(dragon)
    self.dragon_img:setTexture(UILib.dragon_head[dragon:Type()])
    self.dragon_name:setString(Localize.dragon[dragon:Type()].."（LV ".. dragon:Level()..")")
    self.dragon_vitality:setString(_("生命值")..string.formatnumberthousands(dragon:Hp()).."/"..string.formatnumberthousands(dragon:GetMaxHP()))
    self.dragon = dragon
    GameUIPVESendTroop.dragonType = self.dragon:Type()
end

function GameUIPVESendTroop:SelectDragon()
    WidgetSelectDragon.new(
        {
            title = _("选中出战的巨龙"),
            btns = {
                {
                    btn_label = _("确定"),
                    btn_callback = function (selectDragon)
                        if self.dragon:Type() ~= selectDragon:Type() then
                            self.show:ShowOrRefreshTroops()
                            for k,item in pairs(self.soldiers_table) do
                                item:SetSoldierCount(0)
                            end
                            self:AdapterMaxButton(false)
                        end
                        self:RefreashDragon(selectDragon)
                    end,
                },
            },

        }
    ):addTo(self:GetView())
end
function GameUIPVESendTroop:SelectSoldiers()
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
                                self:RefreashSoldierShow()
                                self:AdapterMaxButton(true)
                            end
                        end
                    }
                    UIKit:newWidgetUI("WidgetInput", p):AddToCurrentScene()
                end
            end):align(display.CENTER,  380,90):addTo(content)
        local btn_text = UIKit:ttfLabel({
            text = 0,
            size = 22,
            color = 0x403c2f,
        }):addTo(text_btn):align(display.CENTER)

        slider:onSliderValueChanged(function(event)
            btn_text:setString(math.floor(event.value))
        end)
        slider:addSliderReleaseEventListener(function(event)
            self:AdapterMaxButton(true)
            self:RefreashSoldierShow()
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
            text = string.format("/ %s", string.formatnumberthousands(item.max_soldier)),
            size = 20,
            color = 0x403c2f
        }):addTo(content)
            :align(display.LEFT_CENTER, 440,90)

        -- 士兵头像
        local soldier_ui_config = UILib.soldier_image[name]
        local color_bg = display.newSprite(UILib.soldier_color_bg_images[name]):align(display.CENTER,60,64):addTo(content):scale(104/128)

        local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,60,64):addTo(content):scale(104/128)
        local soldier_head_bg  = display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):pos(soldier_head_icon:getContentSize().width/2,soldier_head_icon:getContentSize().height/2)
        local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_head_icon):align(display.BOTTOM_CENTER,soldier_head_icon:getContentSize().width/2 - 10, 4)
        local soldier_star = StarBar.new({
            max = 3,
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = star,
            margin = 5,
            direction = StarBar.DIRECTION_HORIZONTAL,
            scale = 0.8,
        }):addTo(soldier_star_bg):align(display.CENTER,58, 11)

        item:addContent(content)
        list:addItem(item)
        function item:SetMaxSoldier(max_soldier)
            self.max_soldier = max_soldier
            slider:SetMax(max_soldier)
            soldier_total_count:setString(string.format("/ %s", string.formatnumberthousands(self.max_soldier)))
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
    local soldiers = {}
    local soldier_map = {
        "swordsman_1",
        "ranger_1",
        "lancer_1",
        "catapult_1",
        "sentinel_1",
        "crossbowman_1",
        "horseArcher_1",
        "ballista_1",
        "swordsman_2",
        "ranger_2",
        "lancer_2",
        "catapult_2",
        "sentinel_2",
        "crossbowman_2",
        "horseArcher_2",
        "ballista_2",
        "swordsman_3",
        "ranger_3",
        "lancer_3",
        "catapult_3",
        "sentinel_3",
        "crossbowman_3",
        "horseArcher_3",
        "ballista_3",
        "skeletonWarrior",
        "skeletonArcher",
        "deathKnight",
        "meatWagon",
        -- "priest",
        -- "demonHunter",
        -- "paladin",
        -- "steamTank",
    }
    local User = User
    local map_s = User.soldiers
    for _,name in pairs(soldier_map) do
        local soldier_num = map_s[name]
        if soldier_num > 0 then
            table.insert(soldiers, {
                name = name,
                level = UtilsForSoldier:SoldierStarByName(User, name),
                max_num = soldier_num
            })
        end
    end
    for k,v in pairs(soldiers) do
        table.insert(self.soldiers_table, addListItem(v.name,v.level,v.max_num))
    end
    list:reload()

end
function GameUIPVESendTroop:CreateBetweenBgAndTitle()
    GameUIPVESendTroop.super.CreateBetweenBgAndTitle(self)
    self.show = self:CreateTroopsShow()
end
function GameUIPVESendTroop:RefreashSoldierShow()
    local soldier_show_table = {}
    for k,item in pairs(self.soldiers_table) do
        local name,star,soldier_number =item:GetSoldierInfo()
        -- print("--name,star,soldier_number----",name,star,soldier_number)
        local soldier_config = normal[name.."_"..star] or SPECIAL[name]
        if soldier_number>0 then
            table.insert(soldier_show_table, {
                name = name,
                power = soldier_config.power*soldier_number,
                soldier_num = soldier_number,
                soldier_weight = soldier_config.load*soldier_number,
                soldier_citizen = soldier_config.citizen*soldier_number,
                star = star
            })
        end
    end
    self.show:ShowOrRefreshTroops(soldier_show_table)
end

function GameUIPVESendTroop:GetSelectSoldier()
    local soldiers = {}
    for k,item in pairs(self.soldiers_table) do
        local name,star,soldier_number =item:GetSoldierInfo()
        if soldier_number>0 then
            table.insert(soldiers, {
                name = name,
                star = star,
                count = soldier_number,
            })
        end
    end
    local function __getSoldierConfig(name,level)
        local level = level or 1
        return normal[name.."_"..level] or SPECIAL[name]
    end
    -- 按战斗力从大到小排序
    table.sort(soldiers,function ( a,b )
        local power_a = __getSoldierConfig(a.name,a.star).power*a.count
        local power_b = __getSoldierConfig(b.name,b.star).power*b.count
        return power_a > power_b
    end)
    return soldiers
end
function GameUIPVESendTroop:CreateTroopsShow()
    local TroopsShow = display.newSprite("back_ground_619x270.png"):addTo(self:GetView()):align(display.TOP_CENTER,window.cx, window.top_bottom+18)
    local b_size = TroopsShow:getContentSize()

    local function createInfoItem(title,value)
        local info = display.newLayer()
        local value_label = UIKit:ttfLabel({
            text = value,
            size = 18,
            color = 0xffedae,
        })
        value_label:align(display.BOTTOM_CENTER,value_label:getContentSize().width/2,0)
            :addTo(info)
        UIKit:ttfLabel({
            text = title,
            size = 16,
            color = 0xbbae80,
        }):align(display.BOTTOM_CENTER,value_label:getContentSize().width/2,20)
            :addTo(info)
        info:setContentSize(value_label:getContentSize().width, 45)
        function info:SetValue(value)
            value_label:setString(value)
        end
        return info
    end

    local parent = self
    function TroopsShow:GetCurrentPage()
        return self.current or 1
    end
    function TroopsShow:SetPower(power)
        local info_bg =self.info_bg
        local power_item = createInfoItem(_("战斗力"),string.formatnumberthousands(power))
            :align(display.LEFT_CENTER,50,26)
            :addTo(info_bg)
        return self
    end
    function TroopsShow:SetCitizen(citizen)
        local info_bg =self.info_bg
        local citizen_item = createInfoItem(_("带兵量"),string.formatnumberthousands(citizen).."/"..string.formatnumberthousands(parent.dragon:LeadCitizen()))
        citizen_item:align(display.CENTER,320,26)
            :addTo(info_bg)
        return self
    end
    function TroopsShow:SetWeight(weight)
        local info_bg =self.info_bg
        local weight_item = createInfoItem(_("负重"),string.formatnumberthousands(weight))
        weight_item:align(display.RIGHT_CENTER,590,26)
            :addTo(info_bg)
        return self
    end
    function TroopsShow:SetPVESoldiers(soldiers)
        self.pve_soldiers = soldiers
    end
    function TroopsShow:RefreshPVESoldiers()
        local added_pve_soldiers = self.added_pve_soldiers or {}
        for i,v in ipairs(added_pve_soldiers) do
            self:removeChild(v, true)
        end
        self.added_pve_soldiers = {}
        local current_page = self:GetCurrentPage()
        local soldiers = self.pve_soldiers
        local origin_y = 210
        local box_width = 104
        local gap_x = 8
        local origin_x = (619 - 5 * box_width - 4 * gap_x)/2 +  box_width/2
        for i=(current_page-1)*5+1,(current_page-1)*5+5 do
            if soldiers[i] then
                local name = soldiers[i].name
                local star = soldiers[i].star or 1
                -- 士兵头像
                print("·RefreshPVESoldiers·=",name)
                local soldier_ui_config = UILib.soldier_image[name]
                local color_bg = UILib.soldier_color_bg_images[name]
                local soldier_color_bg = display.newSprite(color_bg):align(display.CENTER,origin_x+ (i-1-(current_page-1)*5)*(box_width+gap_x),origin_y):addTo(self):scale(104/128)
                local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,origin_x+ (i-1-(current_page-1)*5)*(box_width+gap_x),origin_y):addTo(self):scale(104/128)
                local soldier_head_bg  = display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):pos(soldier_head_icon:getContentSize().width/2,soldier_head_icon:getContentSize().height/2)
                -- 附上pve士兵类型 用来判定克制关系
                soldier_head_icon.name = name
                table.insert(self.added_pve_soldiers,soldier_head_icon)
            else
                break
            end
        end
    end
    function TroopsShow:RefreshMySoldiers(soldier_show_table)
        local my_soldiers = soldier_show_table or {}
        self.my_soldiers = my_soldiers
        -- 按兵种战力排序行军
        table.sort(my_soldiers, function(a, b)
            return a.power > b.power
        end)

        local added_my_soldiers = self.added_my_soldiers or {}
        for i,v in ipairs(added_my_soldiers) do
            self:removeChild(v, true)
        end
        self.added_my_soldiers = {}
        local current_page = self:GetCurrentPage()
        local origin_y = 106
        local box_width = 104
        local gap_x = 8
        local origin_x = (619 - 5 * box_width - 4 * gap_x)/2 +  box_width/2
        if not LuaUtils:table_empty(my_soldiers) then
            for i=(current_page-1)*5+1,(current_page-1)*5+5 do
                if my_soldiers[i] then
                    local name = my_soldiers[i].name
                    local star = my_soldiers[i].star
                    -- 士兵头像
                    local soldier_ui_config = UILib.soldier_image[name]
                    local color_bg = UILib.soldier_color_bg_images[name]
                    local soldier_color_bg = display.newSprite(color_bg):align(display.CENTER,origin_x+ (i-1-(current_page-1)*5)*(box_width+gap_x),origin_y):addTo(self):scale(104/128)
                    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,origin_x+ (i-1-(current_page-1)*5)*(box_width+gap_x),origin_y):addTo(self):scale(104/128)
                    local soldier_head_bg  = display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):pos(soldier_head_icon:getContentSize().width/2,soldier_head_icon:getContentSize().height/2)
                    table.insert(self.added_my_soldiers,soldier_head_icon)
                    -- 克制关系框
                    local pve_soldier = self.pve_soldiers[i]
                    if pve_soldier then
                        local forbear =  self:GetForbear(name,pve_soldier.name)
                        if forbear ~= "nil" then
                            local forbear_pic = forbear and "forbear_up.png" or "forbear_down.png"
                            display.newSprite(forbear_pic):addTo(soldier_head_icon):pos(soldier_head_icon:getContentSize().width/2+5,soldier_head_icon:getContentSize().height/2+5):scale(1.22)
                        end
                    end
                else
                    break
                end
            end
        end
    end
    -- 获取两个兵种直间的克制关系
    function TroopsShow:GetForbear(my_soldier,pve_soldier)
        local SOLDIER_VS_MAP = GameDatas.ClientInitGame.soldier_vs
        local my_category = Localize.soldier_category_map[my_soldier]
        local pve_category = Localize.soldier_category_map[pve_soldier]
        local forbear = SOLDIER_VS_MAP[my_category][pve_category]
        return tolua.type(forbear) == "nil" and "nil" or forbear == "strong"
    end
    function TroopsShow:TurnShows( isRight )
        local current_page = self:GetCurrentPage()
        if isRight then
            self.current = current_page + 1 > math.ceil(#self.pve_soldiers/5)  and math.ceil(#self.pve_soldiers/5) or current_page + 1
        else
            self.current = current_page - 1 < 1 and 1 or current_page - 1
        end
        self:RefreshPVESoldiers()
        self:RefreshMySoldiers(self.my_soldiers)
    end
    function TroopsShow:ShowOrRefreshTroops( soldier_show_table )
        local my_soldiers = soldier_show_table or {}
        -- 更新
        self:removeAllChildren()
        self.info_bg = display.newSprite("back_ground_619x52.png"):addTo(self):align(display.BOTTOM_CENTER,b_size.width/2, 0)
        -- 左翻页按钮
        local left_btn = WidgetPushButton.new({normal = "button_normal_28x210.png",pressed = "button_pressed_28x210.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    self:TurnShows(false)
                end
            end):align(display.LEFT_TOP,0,b_size.height-5):addTo(self)
        -- 右翻页按钮
        local right_btn = WidgetPushButton.new({normal = "button_normal_28x210.png",pressed = "button_pressed_28x210.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    self:TurnShows(true)
                end
            end):align(display.LEFT_TOP,b_size.width,b_size.height-5):addTo(self)
        right_btn:setRotationSkewY(180)

        local total_power , total_weight, total_citizen =0,0,0
        for index,v in pairs(my_soldiers) do

            total_power = total_power + v.power
            total_weight = total_weight + v.soldier_weight
            total_citizen = total_citizen + v.soldier_citizen

        end
        self:SetPower(total_power)
        self:SetWeight(total_weight)
        self:SetCitizen(total_citizen)
        self:RefreshPVESoldiers()
        self:RefreshMySoldiers(my_soldiers)
    end
    TroopsShow:SetPVESoldiers(self.pve_soldiers)
    TroopsShow:ShowOrRefreshTroops()
    return TroopsShow
end
function GameUIPVESendTroop:OnUserDataChanged_soldiers(userData, deltaData)
    local ok, value = deltaData("soldiers")
    if ok then
        for i,name in ipairs(value) do
            for _,item in pairs(self.soldiers_table) do
                local item_type = item:GetSoldierInfo()
                if name == item_type then
                    item:SetMaxSoldier(User.soldiers[item_type])
                end
            end
        end
    end
end
function GameUIPVESendTroop:OnBasicChanged()
    self:RefreashDragon(self.dragon)
end
function GameUIPVESendTroop:onExit()
    User:RemoveListenerOnType(self, "soldiers")
    City:GetDragonEyrie():GetDragonManager():RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)

    GameUIPVESendTroop.super.onExit(self)
end

-- fte
local promise = import("..utils.promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIPVESendTroop:PormiseOfFte()
    return self:PromiseOfMax():next(function()
        return self:PromiseOfAttack()
    end)
end
function GameUIPVESendTroop:PromiseOfMax()
    local r = self.max_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.max_btn)

    WidgetFteArrow.new(_("点击最大")):addTo(self:GetFteLayer()):TurnLeft()
        :align(display.LEFT_CENTER, r.x + r.width, r.y + r.height/2)

    local p = promise.new()
    self.max_btn:onButtonClicked(function()
        self:GetFteLayer():removeFromParent()
        p:resolve()
    end)
    return p
end
function GameUIPVESendTroop:PromiseOfAttack()
    local r = self.march_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.march_btn)

    WidgetFteArrow.new(_("点击进攻")):addTo(self:GetFteLayer()):TurnRight()
        :align(display.RIGHT_CENTER, r.x - 20, r.y + r.height/2)

    return UIKit:PromiseOfOpen("GameUIReplay")
end


return GameUIPVESendTroop




























