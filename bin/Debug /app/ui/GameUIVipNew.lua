--
-- Author: Kenny Dai
-- Date: 2015-09-01 21:31:31
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPlayerNode = import("..widget.WidgetPlayerNode")
local UIAutoClose = import(".UIAutoClose")
local UIListView = import(".UIListView")
local UIPageView = import(".UIPageView")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetPages = import("..widget.WidgetPages")
local WidgetInfoNotListView = import("..widget.WidgetInfoNotListView")
local WidgetVIPInfo = import("..widget.WidgetVIPInfo")
local WidgetUseItems = import("..widget.WidgetUseItems")
local Enum = import("..utils.Enum")
local UILib = import(".UILib")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local light_gem = import("..particles.light_gem")
local loginDays = GameDatas.Vip.loginDays
local VIP_LEVEL = GameDatas.Vip.level
local config_store = GameDatas.StoreItems.items

local GameUIVipNew = UIKit:createUIClass('GameUIVipNew',"GameUIWithCommonHeader")

local VIP_MAX_LEVEL = 10

local VIP_EFFECIVE_ALL_TYPE = Enum(
    "freeSpeedup",
    "helpSpeedup",
    "woodProductionAdd",
    "stoneProductionAdd",
    "ironProductionAdd",
    "foodProductionAdd",
    "citizenRecoveryAdd",
    "marchSpeedAdd",
    "normalGachaAdd",
    "storageProtectAdd",
    "wallHpRecoveryAdd",
    "dragonHpRecoveryAdd",
    "dragonExpAdd",
    "soldierAttackPowerAdd",
    "soldierHpAdd",
    "dragonLeaderShipAdd",
    "soldierConsumeSub"
)

-- VIP 效果总览
local VIP_EFFECIVE_ALL = {
    freeSpeedup = _("立即完成建筑时间"),
    helpSpeedup = _("协助加速效果提升"),
    woodProductionAdd = _("木材产量增加"),
    stoneProductionAdd = _("石料产量增加"),
    ironProductionAdd = _("铁矿产量增加"),
    foodProductionAdd = _("粮食产量增加"),
    citizenRecoveryAdd = _("城民增长速度"),
    marchSpeedAdd = _("提升行军速度"),
    normalGachaAdd = _("每日游乐场免费抽奖次数"),
    storageProtectAdd = _("暗仓保护上限提升"),
    wallHpRecoveryAdd = _("城墙修复速度提升"),
    dragonExpAdd =  _("巨龙获得经验值加成"),
    dragonHpRecoveryAdd =  _("巨龙体力恢复速度"),
    soldierAttackPowerAdd = _("所有军事单位攻击力提升"),
    soldierHpAdd = _("所有军事单位防御力提升"),
    dragonLeaderShipAdd = _("提升带兵上限"),
    soldierConsumeSub = _("维护费用减少"),
}

function GameUIVipNew:ctor(city,default_tag)
    GameUIVipNew.super.ctor(self,city,_("玩家信息"))
    self.default_tag = default_tag
end

function GameUIVipNew:RefreshListView()
    self.player_node:RefreshUI()
end

function GameUIVipNew:AdapterPlayerList()
    local infos = {}
    local alliance = Alliance_Manager:GetMyAlliance()
    local member
    if not alliance:IsDefault() then
        member = alliance:GetMemeberById(User:Id())
    end
    table.insert(infos,{_("防御胜利"),User.basicInfo.defenceWin})
    table.insert(infos,{_("进攻胜利"),User.basicInfo.attackWin})
    table.insert(infos,{_("胜率"), User.basicInfo.attackTotal ~= 0 and
        string.format("%.2f%%",(
            User.basicInfo.attackWin/User.basicInfo.attackTotal)*100
        ) or 0
    })
    table.insert(infos,{_("击杀"),string.formatnumberthousands(User.basicInfo.kill)})
    table.insert(infos,{_("忠诚值"),GameUtils:formatNumber(User:Loyalty())})
    table.insert(infos,{_("联盟"),alliance and alliance.basicInfo.name or ""})
    table.insert(infos,{_("职位"),member and Localize.alliance_title[member:Title()] or ""})
    return infos
end

--WidgetPlayerNode的回调方法
--点击勋章
function GameUIVipNew:WidgetPlayerNode_OnMedalButtonClicked(index)
    print("OnMedalButtonClicked-->",index)
end
-- 点击头衔
function GameUIVipNew:WidgetPlayerNode_OnTitleButtonClicked()
    print("OnTitleButtonClicked-->")
end
--修改头像
function GameUIVipNew:WidgetPlayerNode_OnPlayerIconCliked()
    print("WidgetPlayerNode_OnPlayerIconCliked-->")
    UIKit:newWidgetUI("WidgetSelectPlayerHeadIcon"):AddToCurrentScene(true)
end
--修改玩家名
function GameUIVipNew:WidgetPlayerNode_OnPlayerNameCliked()
    WidgetUseItems.new():Create({
        item_name = "changePlayerName"
    }):AddToCurrentScene()
end
--决定按钮是否可以点击
function GameUIVipNew:WidgetPlayerNode_PlayerCanClickedButton(name,args)
    print("WidgetPlayerNode_PlayerCanClickedButton-->",name)
    if name == 'Medal' then --点击勋章
        return false
    elseif name == 'PlayerIcon' then --修改头像
        return true
    elseif name == 'PlayerTitle' then -- 点击头衔
        return false
    elseif name == 'PlayerName' then --修改玩家名
        return true
    end

end
--数据回调
function GameUIVipNew:WidgetPlayerNode_DataSource(name)
    if name == 'BasicInfoData' then
        local exp_config = GameDatas.PlayerInitData.playerLevel[User:GetLevel()]
        return {
            name = User.basicInfo.name,
            lv = User:GetLevel(),
            currentExp = User.basicInfo.levelExp - exp_config.expFrom,
            maxExp = exp_config.expTo - exp_config.expFrom,
            power = User.basicInfo.power,
            playerId = User._id,
            playerIcon = User.basicInfo.icon,
            vip = User:GetVipLevel()
        }
    elseif name == "MedalData"  then
        return {} -- {"xx.png","xx.png"}
    elseif name == "TitleData"  then
        return {} -- {image = "xxx.png",desc = "我是头衔"}
    elseif name == "DataInfoData"  then
        return self:AdapterPlayerList() -- {{"职位","将军"},{"职位","将军"},{"职位","将军"}}
    end
end
function GameUIVipNew:OnMoveInStage()
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "info",
            default = self.default_tag == "info"
        },
        {
            label = _("VIP"),
            tag = "VIP",
            default = self.default_tag == "VIP"
        },
    }, function(tag)
        if tag == 'info' then
            if not self.player_node then
                self.player_node = WidgetPlayerNode.new(cc.size(564,760),self)
                    :addTo(self:GetView()):pos(window.cx-564/2,window.bottom_top+30)
                self:RefreshListView()
            end
            self.player_node:setVisible(true)
        else
            if self.player_node then
                self.player_node:setVisible(false)
            end
        end
        if tag == 'VIP' then
            if not self.vip_layer then
                self.vip_layer = display.newLayer():addTo(self:GetView())
                self:InitVip()
                self.vip_layer:scheduleAt(function()
                    self:OnVipEventTimer()
                end)
            end
            self.vip_layer:setVisible(true)
        else
            if self.vip_layer then
                self.vip_layer:setVisible(false)
            end
        end
    end):pos(window.cx, window.bottom + 34)
    User:AddListenOnType(self, "basicInfo")
    GameUIVipNew.super.OnMoveInStage(self)
end
function GameUIVipNew:onExit()
    User:RemoveListenerOnType(self, "basicInfo")
    GameUIVipNew.super.onExit(self)
end
function GameUIVipNew:InitVip()
    self:InitVipTop()
    self:CreateVipEff()
end
function GameUIVipNew:InitVipTop()
    local vip_layer = self.vip_layer
    local shadow = display.newColorLayer(UIKit:hex2c4b(0xff000000))
    shadow:setContentSize(cc.size(620,164))
    shadow:pos((display.width - 620) / 2, window.top_bottom - 146):addTo(vip_layer)
    local top_bg = display.newSprite("back_ground_vip_608x164.jpg"):align(display.TOP_CENTER, window.cx, window.top_bottom + 16):addTo(vip_layer)
    local bg_size = top_bg:getContentSize()
    local line = display.newSprite("line_624x58.png"):align(display.TOP_CENTER, bg_size.width/2, 16):addTo(top_bg)


    -- 激活VIP按钮
    local active_button = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x60.png", pressed = "yellow_btn_down_148x60.png"},
        {scale9 = false},
        {
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("激活VIP"),
        size = 20,
        color = 0xfff3c7,
        shadow = true
    }))
        :addTo(top_bg):align(display.CENTER, 90, bg_size.height-56)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                WidgetUseItems.new():Create({
                    item_name = "vipActive_1"
                }):AddToCurrentScene()
            end
        end)
    local isactive, leftTime = User:IsVIPActived()
    local status_text = isactive and _("已激活").." "..GameUtils:formatTimeStyle1(leftTime) or _("未激活VIP")
    self.vip_status_label = UIKit:ttfLabel({
        text = status_text,
        size = 20,
        color = 0xffd200,
    }):align(display.LEFT_CENTER, 18, active_button:getPositionY() - 46)
        :addTo(top_bg)

    local process_bg = display.newSprite("process_bar_540x40.png")
        :align(display.CENTER_BOTTOM,bg_size.width/2 - 18,5)
        :addTo(top_bg)
    local progressTimer_vip_exp = UIKit:commonProgressTimer("bar_color_540x40.png"):addTo(process_bg):align(display.LEFT_BOTTOM,0,0)
    local vip_level,percent,exp = User:GetVipLevel()
    progressTimer_vip_exp:setPercentage(percent)
    self.vip_exp_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(exp - User:GetSpecialVipLevelExp(vip_level)).."/"..string.formatnumberthousands(User:GetSpecialVipLevelExpTo(vip_level)),
        size = 20,
        color = 0xfff3c7,
        shadow = true
    }):addTo(process_bg,2):align(display.LEFT_CENTER,10 , process_bg:getContentSize().height/2)

    self.progressTimer_vip_exp = progressTimer_vip_exp

    WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
        :addTo(process_bg)
        :align(display.CENTER_RIGHT,580,20)
        :onButtonClicked(function()
            WidgetUseItems.new():Create({
                item_name = "vipPoint_1"
            }):AddToCurrentScene()
        end)

    -- 当前vip等级
    -- 是否激活
    if User:IsVIPActived() then
        btn_pic = "vip_unlock_normal.png"
    else
        btn_pic = "vip_lock.png"
    end

    local current_level = display.newSprite(btn_pic):align(display.CENTER, bg_size.width/2,bg_size.height - 55):addTo(top_bg)

    self.vip_level_pic = display.newSprite("VIP_"..vip_level.."_46x32.png"):addTo(current_level)
        :align(display.CENTER,52,45)
    self.vip_level_bg = current_level

    -- 连续登陆，明日登陆
    local vipLoginDaysCount = User.countInfo.vipLoginDaysCount
    local tomorrow_add = UIKit:ttfLabel({
        text = _("+ "..loginDays[ (vipLoginDaysCount + 1 ) > #loginDays and #loginDays or (vipLoginDaysCount + 1 )].expAdd),
        size = 22,
        color = 0x7eff00,
    }):align(display.RIGHT_CENTER, bg_size.width - 15, active_button:getPositionY())
        :addTo(top_bg)

    UIKit:ttfLabel({
        text = _("明日"),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER, tomorrow_add:getPositionX() - tomorrow_add:getContentSize().width - 10, active_button:getPositionY())
        :addTo(top_bg)

    local label_1 = UIKit:ttfLabel({
        text = _("天)"),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER, bg_size.width - 15, tomorrow_add:getPositionY() - 30)
        :addTo(top_bg)
    local continuous_login = UIKit:ttfLabel({
        text = vipLoginDaysCount,
        size = 22,
        color = 0x7eff00,
    }):align(display.RIGHT_CENTER, label_1:getPositionX() - label_1:getContentSize().width - 10, label_1:getPositionY())
        :addTo(top_bg)
    local label_2 = UIKit:ttfLabel({
        text = _("(连续登录"),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER, continuous_login:getPositionX() - continuous_login:getContentSize().width - 10, label_1:getPositionY())
        :addTo(top_bg)
end
function GameUIVipNew:CreateVipEff()
    local vip_layer = self.vip_layer
    local line = display.newScale9Sprite("dividing_line.png",0,0,cc.size(552,2),cc.rect(10,2,382,2)):align(display.CENTER, window.cx, window.top - 568):addTo(vip_layer)
    line:rotation(90)
    local level_bg = display.newSprite("tmp_back_ground_vip_560x66.png"):align(display.CENTER, window.cx, window.top - 280):addTo(vip_layer)
    -- 当前vip等级
    local vip_level,percent,exp = User:GetVipLevel()
    self.current_vip_level = vip_level
    self.right_level = (self.current_vip_level + 1) <= VIP_MAX_LEVEL and (self.current_vip_level + 1) or (self.current_vip_level - 1)
    local current_level_label = UIKit:ttfLabel({
        text = "VIP "..self.current_vip_level,
        size = 26,
        color = 0xffd200,
    }):align(display.CENTER, 160,42)
        :addTo(level_bg)
    -- local right_level_label = UIKit:ttfLabel({
    --     text = "VIP "..self.right_level,
    --     size = 26,
    --     color = 0xffd200,
    -- }):align(display.CENTER, 400,42)
    --     :addTo(level_bg)

    local bottom_vip_level_node = display.newNode()
    bottom_vip_level_node:setContentSize(cc.size(292,22))
    bottom_vip_level_node:align(display.CENTER, window.cx, window.bottom_top + 20):addTo(vip_layer)
    local parent = self
    function bottom_vip_level_node:InitLevelNode()
        self:removeAllChildren()
        for i=1,VIP_MAX_LEVEL do
            display.newSprite(parent.right_level == i and "vip_icon_22x22_1.png" or "vip_icon_22x22_2.png"):align(display.LEFT_CENTER, (i - 1) * 30, 11):addTo(self)
        end
    end

    local bg_width, bg_height = 250 , 534
    local left_eff_bg = WidgetUIBackGround.new({width = bg_width,height = bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_6):addTo(vip_layer):align(display.LEFT_TOP,window.left + 50,window.top - 314)
    local right_eff_bg = WidgetUIBackGround.new({width = bg_width,height = bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_6):addTo(vip_layer):align(display.RIGHT_TOP,window.right - 50,window.top - 314)

    local listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a10aaee),
        viewRect = cc.rect(0, 0, 520 , 514),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(vip_layer):pos(window.left + 60,window.bottom_top + 44)

    local clipeNode = display.newClippingRegionNode(cc.rect(window.left + 60 + 520 - bg_width + 20 - 12, window.top - 310  , bg_width - 20 - 12, 70)):addTo(vip_layer)
    local pv_right_level = UIPageView.new {
        viewRect = cc.rect(window.left + 60 + 520 - bg_width + 20, window.bottom_top + 44  , bg_width - 20, bg_height + 56),
        row = 1,
        padding = {left = 0, right = 0, top = 10, bottom = 0},
        nBounce = true,
        continuous_touch = true
    }:addTo(clipeNode,2)
    pv_right_level:setTouchSwallowEnabled(false)
    local cover_layer = display.newLayer():addTo(vip_layer,3):pos(window.left + 60 + 520 - bg_width + 20 , window.top - 310)
    cover_layer:setContentSize(cc.size(bg_width - 20, 70))
    local function showNode()
        listview:removeAllItems()
        pv_right_level:removeAllItems()
        local all_node = display.newNode()
        local max_level = math.max(self.current_vip_level,(self.right_level + 1) <= VIP_MAX_LEVEL and (self.right_level + 1) or self.right_level)
        local available_count = 0
        for k,v in ipairs(VIP_EFFECIVE_ALL_TYPE) do
            local effect = VIP_LEVEL[max_level][v]
            if effect > 0 then
                available_count = available_count + 1
            end
        end
        all_node:setContentSize(cc.size(520,available_count * 86))
        local current_vip_node = self:CreateVipEffNodeByLevel(self.current_vip_level,available_count):addTo(all_node):pos(0,0)
        local function changeIndex( isAdd )
            local change
            if isAdd then
                change = self.right_level + 1
                if change == self.current_vip_level then
                    change = change + 1
                end
            else
                change = self.right_level - 1
                if change == self.current_vip_level then
                    change = change - 1
                end
            end
            return change
        end
        local pv = UIPageView.new {
            viewRect = cc.rect(520 - bg_width + 20, 0 , bg_width - 20, available_count * 86),
            row = 1,
            padding = {left = 0, right = 0, top = 10, bottom = 0},
            nBounce = true,
            continuous_touch = true
        }
        pv:onTouch(function (event)
            if event.name == "pageChange" then
                local total_pages = pv:getPageCount()
                if total_pages == 2 then
                    if self.right_level == (VIP_MAX_LEVEL - 1) or self.right_level == VIP_MAX_LEVEL then
                        if event.pageIdx == 1 then
                            self.right_level = changeIndex(false)
                            self.last_list_position_y = listview.container:getPositionY()
                            showNode()
                        end
                    elseif self.right_level == 1 or self.right_level == 2 then
                        if event.pageIdx == 2 then
                            self.right_level = changeIndex(true)
                            self.last_list_position_y = listview.container:getPositionY()
                            showNode()
                        end
                    end
                elseif total_pages == 3 then
                    if event.pageIdx == 1 then
                        self.right_level = changeIndex(false)
                        self.last_list_position_y = listview.container:getPositionY()
                        showNode()
                    elseif event.pageIdx == 3 then
                        self.right_level = changeIndex(true)
                        self.last_list_position_y = listview.container:getPositionY()
                        showNode()
                    end
                end
                -- right_level_label:setString("VIP "..self.right_level)
                bottom_vip_level_node:InitLevelNode()
            end
        end):addTo(all_node)
        pv:setTouchSwallowEnabled(false)

        local begin_index,end_index
        local re_r , add_r= self.right_level - 1,self.right_level + 1
        if re_r == self.current_vip_level  then
            if re_r == 1 then
                begin_index = self.right_level
            else
                begin_index = re_r - 1
            end
        else
            begin_index = re_r < 1 and 1 or re_r
        end
        if add_r == self.current_vip_level then
            if add_r == VIP_MAX_LEVEL then
                end_index = self.right_level
            else
                end_index = add_r + 1
            end
        else
            end_index = add_r > VIP_MAX_LEVEL and (add_r - 1) or add_r
        end
        local page_index = 0
        local right_index
        for i= begin_index,end_index do
            if i ~= self.current_vip_level then
                page_index = page_index + 1
                local item = pv:newItem()
                local content_node = self:CreateVipEffNodeByLevel(i,available_count)
                item:addChild(content_node)
                pv:addItem(item)
                if self.right_level == i then
                    right_index = page_index
                end
            end
        end
        pv:reload()
        pv:gotoPage(right_index)
        local item = listview:newItem()
        item:setItemSize(520,available_count * 86)
        item:addContent(all_node)
        listview:addItem(item)
        listview:reload()
        if self.last_list_position_y then
            listview.container:setPositionY(self.last_list_position_y + (self.available_count - available_count) * 86)
        end
        self.available_count = available_count


        local page_index_2 = 0,right_index_2
        for i= begin_index,end_index do
            if i ~= self.current_vip_level then
                page_index_2 = page_index_2 + 1
                local item = pv_right_level:newItem()
                -- local content_node = display.newColorLayer(UIKit:hex2c4b(0x7a0aa000))
                local content_node = display.newNode()
                content_node:setContentSize(cc.size(bg_width - 20, bg_height + 86))
                UIKit:ttfLabel({
                    text = "VIP "..i,
                    size = 26,
                    color = 0xffd200,
                }):align(display.CENTER, (bg_width - 20)/2 - 20, bg_height + 86 - 54):addTo(content_node)
                item:addChild(content_node)
                pv_right_level:addItem(item)
                if self.right_level == i then
                    right_index_2 = page_index_2
                end
            end
        end
        pv_right_level:reload()
        pv_right_level:gotoPage(right_index_2)
    end
    showNode()
end
function GameUIVipNew:CreateVipEffNodeByLevel(level,available_count)
    local node = display.newNode()
    local width,height = 230,available_count * 86
    node:setContentSize(cc.size(width,height))
    local flag = true
    local none_eff_count = 0
    local add_count = 0
    dump(VIP_LEVEL[level],level)
    for k,v in ipairs(VIP_EFFECIVE_ALL_TYPE) do
        local effect = VIP_LEVEL[level][v]
        if effect > 0 then
            add_count = add_count + 1
            if effect<1 and v ~="helpSpeedup" then
                effect = tonumber(effect*100).."%"
            end
            -- 特殊处理下 freeSpeedup
            if v == "freeSpeedup" then
                effect = effect .. _("分钟")
            end
            if v == "helpSpeedup" then
                effect = effect .. "%"
            end
            local title = VIP_EFFECIVE_ALL[v]
            local booty_item_bg_image = flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
            local booty_item_bg = display.newScale9Sprite(booty_item_bg_image):size(230,86):align(display.TOP_CENTER,width/2, height - (k - 1) * 86):addTo(node)

            UIKit:ttfLabel({
                text = title,
                size = 20,
                color = 0x403c2f,
            }):align(display.CENTER, 115,60)
                :addTo(booty_item_bg)
            UIKit:ttfLabel({
                text = "+"..effect,
                size = 20,
                color = 0x007c23,
            }):align(display.CENTER, 115,30)
                :addTo(booty_item_bg)

            flag = not flag
        else
            none_eff_count = none_eff_count + 1
        end
    end
    if (add_count+1) < available_count then
        local count = 1
        for i = (add_count+1),available_count do
            -- local balck_node = WidgetUIBackGround.new({width = width,height = 86},WidgetUIBackGround.STYLE_TYPE.STYLE_6):align(display.TOP_CENTER,width/2, height - (add_count + count - 1) * 86):addTo(node)
            local balck_node = display.newNode()
            balck_node:setContentSize(cc.size(width,86)):align(display.TOP_CENTER,width/2, height - (add_count + count - 1) * 86):addTo(node)
            count = count + 1
        end
    end
    return node
end
function GameUIVipNew:CreateVipEffListByLevel(level)
    local bg_width, bg_height = 250 , 534
    local listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a10aaee),
        viewRect = cc.rect(0, 0, bg_width - 20 , bg_height - 20),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }

    local flag = true
    local none_eff_count = 0
    for k,v in ipairs(VIP_EFFECIVE_ALL_TYPE) do
        local effect = VIP_LEVEL[level][v]
        if effect > 0 then
            if effect<1 and v ~="helpSpeedup" then
                effect = tonumber(effect*100).."%"
            end
            -- 特殊处理下 freeSpeedup
            if v == "freeSpeedup" then
                effect = effect .. _("分钟")
            end
            if v == "helpSpeedup" then
                effect = effect .. "%"
            end
            local title = VIP_EFFECIVE_ALL[v]
            local booty_item_bg_image = flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
            local booty_item_bg = display.newScale9Sprite(booty_item_bg_image):size(230,86)

            UIKit:ttfLabel({
                text = title,
                size = 20,
                color = 0x403c2f,
            }):align(display.CENTER, 115,60)
                :addTo(booty_item_bg)
            UIKit:ttfLabel({
                text = "+"..effect,
                size = 20,
                color = 0x007c23,
            }):align(display.CENTER, 115,30)
                :addTo(booty_item_bg)


            local item = listview:newItem()
            item:setItemSize(230,86)
            item:addContent(booty_item_bg)
            listview:addItem(item)
            flag = not flag
        else
            none_eff_count = none_eff_count + 1
        end
    end
    for i=1,none_eff_count do
        local item = listview:newItem()
        item:setItemSize(230,86)
        -- local balck_node = WidgetUIBackGround.new({width = 230,height = 86},WidgetUIBackGround.STYLE_TYPE.STYLE_6)

        local balck_node = display.newNode()

        balck_node:setContentSize(cc.size(230,86))
        item:addContent(balck_node)
        listview:addItem(item)
    end
    listview:reload()
    return listview
end
function GameUIVipNew:OnUserDataChanged_basicInfo(userData, deltaData)
    if self.player_node and
        (deltaData("basicInfo.name") or deltaData("basicInfo.icon")) then
        self.player_node:RefreshUI()
    end

    if self.vip_layer and deltaData("basicInfo.vipExp") then
        self.vip_layer:removeAllChildren()
        self:InitVip()
    end
end
function GameUIVipNew:OnVipEventTimer()
    local isactive, time = User:IsVIPActived()
    if time > 0 then
        self.vip_status_label:setString(_("已激活").." "..GameUtils:formatTimeStyle1(time))
        self.vip_level_bg:setTexture("vip_unlock_normal.png")
    else
        self.vip_status_label:setString(_("未激活VIP"))
        self.vip_level_bg:setTexture("vip_lock.png")
    end
end
return GameUIVipNew















