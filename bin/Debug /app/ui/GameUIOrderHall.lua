local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local SpriteConfig = import("..sprites.SpriteConfig")
local UIListView = import(".UIListView")
local UILib = import(".UILib")
local Alliance = import("..entity.Alliance")
local Localize = import("..utils.Localize")
local AllianceVillage = GameDatas.AllianceVillage

local collect_type  = {_("木材"),
    _("石料"),
    _("铁矿"),
    _("粮食"),
    _("银币"),
}
local GameUIOrderHall = UIKit:createUIClass('GameUIOrderHall', "GameUIAllianceBuilding")

function GameUIOrderHall:ctor(city,default_tab,building)
    GameUIOrderHall.super.ctor(self, city, _("秩序大厅"),default_tab,building)
    self.default_tab = default_tab
    self.building = building
    self.alliance = Alliance_Manager:GetMyAlliance()
end

function GameUIOrderHall:OnMoveInStage()
    GameUIOrderHall.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("村落管理"),
            tag = "village",
            default = "village" == self.default_tab,
        },
        -- {
        --     label = _("熟练度"),
        --     tag = "proficiency",
        --     default = "proficiency" == self.default_tab,
        -- },
    }, function(tag)
        if tag == 'village' then
            self.village_layer:setVisible(true)
            self:InitVillagePart()
        else
            self.village_layer:Reset()
            self.village_layer:setVisible(false)
        end
        -- if tag == 'proficiency' then
        --     self.proficiency_layer:setVisible(true)
        --     self:InitProficiencyPart()
        -- else
        --     self.proficiency_layer:Reset()
        --     self.proficiency_layer:setVisible(false)
        -- end
    end):pos(window.cx, window.bottom + 34)


    self.alliance:AddListenOnType(self, "villageLevels")
end
function GameUIOrderHall:CreateBetweenBgAndTitle()
    GameUIOrderHall.super.CreateBetweenBgAndTitle(self)

    -- village_layer
    local village_layer = display.newLayer():addTo(self:GetView())
    self.village_layer = village_layer
    function village_layer:Reset()
        self.village_listview = nil
        self.village_items = {}
        self:removeAllChildren()
    end
    -- proficiency_layer
    -- local proficiency_layer = display.newLayer():addTo(self:GetView())
    -- self.proficiency_layer = proficiency_layer
    -- function proficiency_layer:Reset()
    --     self.proficiency_listview = nil
    --     self.proficiency_drop_list = nil
    --     self:removeAllChildren()
    -- end
end

function GameUIOrderHall:InitVillagePart()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,608, 786),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    },false)
    list_node:addTo(self.village_layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.village_listview = list
    self:ResetVillageList()
end
-- 重置村落list
function GameUIOrderHall:ResetVillageList()
    self.village_listview:removeAllItems()
    self.village_items = {}
    local villageLevels = self.alliance:GetVillageLevels()
    for k,v in ipairs({
        "woodVillage",
        "stoneVillage",
        "ironVillage",
        "foodVillage",
        "coinVillage",
    }) do
        self.village_items[v] = self:CreateVillageItem(v,villageLevels[v])
    end
    self.village_listview:reload()
end

function GameUIOrderHall:CreateVillageItem(village_type,village_level)
    local alliance = self.alliance
    local item = self.village_listview:newItem()
    local item_width,item_height = 568 , 200
    item:setItemSize(item_width, item_height)
    local content = WidgetUIBackGround.new({width=item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)

    -- 建筑图片 放置区域左右边框
    display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_BOTTOM, 10, 16)
        :scale(136/126)
        :addTo(content)

    local build_png = SpriteConfig[village_type]:GetConfigByLevel(village_level).png

    local building_image = display.newSprite(build_png)
        :addTo(content):pos(75, 70)
    building_image:setAnchorPoint(cc.p(0.5,0.5))
    building_image:setScale(113/math.max(building_image:getContentSize().width,building_image:getContentSize().height))
    -- 村落名字
    local title_bg = display.newScale9Sprite("title_blue_430x30.png", item_width/2, 175,cc.size(550,30),cc.rect(15,10,400,10))
        :align(display.CENTER):addTo(content)
    UIKit:ttfLabel({
        text = Localize.village_name[village_type],
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20 , title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local config = AllianceVillage[village_type]

    local total_resource = UIKit:createLineItem(
        {
            width = 396,
            text_1 = _("资源总量"),
            text_2 = string.formatnumberthousands(config[village_level].production),
        }
    ):align(display.RIGHT_CENTER,item_width - 10 , 120)
        :addTo(content)
    local current_level = UIKit:createLineItem(
        {
            width = 396,
            text_1 = _("当前等级"),
            text_2 = _("等级")..village_level,
        }
    ):align(display.RIGHT_CENTER,item_width - 10 , 80)
        :addTo(content)


    if alliance:GetSelf():CanUpgradeAllianceBuilding() and village_level<#AllianceVillage[village_type] then
        -- 荣耀值
        item.honour_icon = display.newSprite("honour_128x128.png"):align(display.CENTER, 250, 40):addTo(content):scale(42/128)
        local honour_bg = display.newSprite("back_ground_114x36.png"):align(display.CENTER, 330, 40):addTo(content)
        local need_honour = config[village_level+1>#config and #config or village_level+1].needHonour
        item.honour_label = UIKit:ttfLabel({
            text = string.formatnumberthousands(need_honour),
            size = 20,
            color = 0x403c2f,
        }):addTo(honour_bg):align(display.CENTER,honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
        item.honour_bg = honour_bg
        -- 升级按钮
        item.upgrade_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("升级"),
                size = 22,
                color = 0xffedae,
                shadow= true
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    if alliance.basicInfo.honour < need_honour then
                        UIKit:showMessageDialog(_("提示"),_("荣耀点不足"))
                    else
                        NetManager:getUpgradeAllianceVillagePromise(village_type):done(function ( response )
                            GameGlobalUI:showTips(_("升级成功"),_("新的村落将会在下次系统刷新时出现"))
                            return response
                        end)
                    end
                end
            end):align(display.CENTER, 480, 40):addTo(content)
    end
    item:addContent(content)
    self.village_listview:addItem(item)

    function item:LevelUpRefresh(village_type,village_level)
        current_level:SetValue(_("等级")..village_level)
        local build_png = SpriteConfig[village_type]:GetConfigByLevel(village_level).png
        building_image:setTexture(build_png)
        total_resource:SetValue(string.formatnumberthousands(config[village_level].production))
        if self.honour_label and village_level <#config then
            local need_honour = config[village_level+1].needHonour
            self.honour_label:setString(string.formatnumberthousands(need_honour))
        else
            if self.honour_icon then
                self.honour_icon:hide()
            end
            if self.honour_label then
                self.honour_label:hide()
            end
            if self.honour_bg then
                self.honour_bg:hide()
            end
            if self.upgrade_btn then
                self.upgrade_btn:hide()
            end
        end
    end

    return item
end

function GameUIOrderHall:InitProficiencyPart()
    local layer = self.proficiency_layer
    local list,list_node = UIKit:commonListView({
        async = true, --异步加载
        viewRect = cc.rect(0, 0,568, 500),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list:setRedundancyViewVal(100)
    list:setDelegate(handler(self, self.DelegateProficiency))
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.proficiency_listview = list
    local my_ranking_bg = display.newScale9Sprite("back_ground_166x84.png", window.cx, window.top_bottom - 210,cc.size(548,52),cc.rect(15,10,136,64))
        :addTo(layer)
    self.my_ranking_label = UIKit:ttfLabel({
        size = 22,
        color = 0x403c2f,
    }):align(display.CENTER, my_ranking_bg:getContentSize().width/2 , my_ranking_bg:getContentSize().height/2)
        :addTo(my_ranking_bg)
    self.proficiency_drop_list =  WidgetRoundTabButtons.new(
        {
            {tag = "1",label = _("木材"),default = true},
            {tag = "2",label = _("石料")},
            {tag = "3",label = _("铁矿")},
            {tag = "4",label = _("粮食")},
            {tag = "5",label = _("银币")},
        },
        function(tag)
            self:ChangeProficiencyOption(tonumber(tag))
        end
    )
    self.proficiency_drop_list:align(display.TOP_CENTER,window.cx,window.top-80):addTo(layer,2)



    local desc_bg = display.newScale9Sprite("back_ground_398x97.png", window.cx, window.top_bottom - 120,cc.size(556,110),cc.rect(15,10,368,77))
        :addTo(layer)

    UIKit:ttfLabel({
        text = _("显示联盟成员的村落采集资源熟练度,每采集一定的村落资源,就会增加一定的熟练度,熟练度越高,采集相应村落资源的速度就会越快"),
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(500,0)
    }):align(display.CENTER, desc_bg:getContentSize().width/2 , desc_bg:getContentSize().height/2)
        :addTo(desc_bg)
end
function GameUIOrderHall:ChangeProficiencyOption(option)
    self.option = option
    local sortByProficiencyMember = {}
    self.alliance:IteratorAllMembers(function ( member )
        table.insert(sortByProficiencyMember, member)
    end)
    table.sort( sortByProficiencyMember, function ( a,b )
        return a:GetCollectExpsByType(option)>b:GetCollectExpsByType(option)
    end)
    self.sortByProficiencyMember = sortByProficiencyMember
    self.proficiency_listview:reload()

    -- 更新我的对应排名
    for i,v in ipairs(sortByProficiencyMember) do
        if v:Id() == User:Id() then
            self.my_ranking_label:setString(string.format(_("我的%s熟练度排名:"),collect_type[option]) ..i)
        end
    end
end
function GameUIOrderHall:DelegateProficiency(listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local count = 0
        if self.sortByProficiencyMember then
            count = #self.sortByProficiencyMember
        end
        return count
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateProficiencyContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    else
    end
end
function GameUIOrderHall:CreateProficiencyContent()
    local item_width,item_height = 568 , 100
    local content = WidgetUIBackGround.new({
        width = item_width,
        height = item_height,
    },WidgetUIBackGround.STYLE_TYPE.STYLE_2)

    local index_label = UIKit:ttfLabel({
        size = 22,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 10 , item_height/2)
        :addTo(content)
    -- 成员职位，名字
    local title_bg = display.newScale9Sprite("back_ground_166x84.png",114,item_height/2,cc.size(162,78),cc.rect(15,10,136,64))
        :addTo(content)
    -- 职位对应icon
    local title_icon = display.newSprite("back_ground_166x84.png")
        :align(display.CENTER, title_bg:getContentSize().width/2, title_bg:getContentSize().height-20)
        :addTo(title_bg)
    -- 名字
    local name_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, title_bg:getContentSize().width/2 , 20)
        :addTo(title_bg)
    -- 等级经验
    local level_bg = display.newScale9Sprite("back_ground_166x84.png",290,item_height/2,cc.size(162,78),cc.rect(15,10,136,64))
        :addTo(content)
    -- 等级
    local level_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, level_bg:getContentSize().width/2 , level_bg:getContentSize().height-20)
        :addTo(level_bg)
    -- 经验
    local exp_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, level_bg:getContentSize().width/2 , 20)
        :addTo(level_bg)
    -- 采集速度
    local speed_bg = display.newScale9Sprite("back_ground_166x84.png",466,item_height/2,cc.size(162,78),cc.rect(15,10,136,64))
        :addTo(content)
    UIKit:ttfLabel({
        text = _("采集速度"),
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, speed_bg:getContentSize().width/2 , speed_bg:getContentSize().height-20)
        :addTo(speed_bg)

    local speed_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, speed_bg:getContentSize().width/2 , 20)
        :addTo(speed_bg)

    local parent = self
    function content:SetData( idx ,member)
        local member = member or parent.sortByProficiencyMember[idx]
        self.member = member
        index_label:setString(idx..".")
        title_icon:setTexture(UILib.alliance_title_icon[member:Title()])
        name_label:setString(member:Name())
        local option = parent.option
        level_label:setString(_("等级")..member:GetCollectLevelByType(option))
        local exp , expTo = member:GetCollectExpsByType(option)
        exp_label:setString(string.formatnumberthousands(exp) .."/".. string.formatnumberthousands(expTo))
        speed_label:setString("+"..(member:GetCollectEffectByType(option)*100).."%")
    end
    function content:GetContentData()
        return self.member
    end
    return content
end

function GameUIOrderHall:OnAllianceDataChanged_villageLevels(allianceData, deltaData)
    for k,v in pairs(allianceData.villageLevels) do
        if self.village_items[k] then
            self.village_items[k]:LevelUpRefresh(k,v)
        end
    end
end

function GameUIOrderHall:onExit()
    self.alliance:RemoveListenerOnType(self, "villageLevels")
    GameUIOrderHall.super.onExit(self)
end

return GameUIOrderHall







































