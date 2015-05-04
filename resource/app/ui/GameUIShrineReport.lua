--
-- Author: Danny He
-- Date: 2014-11-19 10:49:43
--
local GameUIShrineReport = UIKit:createUIClass("GameUIShrineReport")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetDropList = import("..widget.WidgetDropList")
local window = import("..utils.window")
local content_height = 738
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local StarBar = import(".StarBar")

function GameUIShrineReport:ctor(shrineReport)
    GameUIShrineReport.super.ctor(self)
    self.shrineReport_ = shrineReport
end

function GameUIShrineReport:onEnter()
    GameUIShrineReport.super.onEnter(self)
    self:BuildUI()
end

function GameUIShrineReport:GetShrineReport()
    return self.shrineReport_
end

function GameUIShrineReport:BuildUI()
    local shadowLayer = UIKit:shadowLayer()
        :addTo(self)
    local bg_node = WidgetUIBackGround.new({height=content_height}):addTo(shadowLayer):pos(window.left+20,window.bottom+140)
    self.bg_node = bg_node
    local titleBar = display.newScale9Sprite("title_blue_600x52.png")
        :align(display.CENTER_BOTTOM, 304,content_height - 15)
        :addTo(bg_node)
    local titleLabel = UIKit:ttfLabel({
        text = _("事件详情"),
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,300,21):addTo(titleBar)
    local closeButton = UIKit:closeButton():addTo(titleBar)
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width, 0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    self.drop_list = WidgetDropList.new(
        {
            {
                tag = "fight_detail",
                label = _("战斗详情"),
                default = true
            },
            {
                tag = "data_statistics",
                label = _("数据统计")
            }
        },
        function(tag)
            self:OnDropListSelected(tag)
        end
    ):align(display.LEFT_TOP,20, titleBar:getPositionY()-10):addTo(bg_node):zorder(20)
end

function GameUIShrineReport:CreateIf_fight_detail()
    if self.fight_detail_list then return self.fight_detail_list end
    local list = UIListView.new({
        -- bgColor = UIKit:hex2c4b(0x7a000000),
        viewRect = cc.rect(10,10,590,640),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
    }):addTo(self.bg_node)
    self.fight_detail_list = list
    return self.fight_detail_list
end

function GameUIShrineReport:RefreshFightListView()
    self.fight_detail_list:removeAllItems()
    for i,v in ipairs(self:GetShrineReport():FightDatas()) do
        local item = self.fight_detail_list:newItem()
        local content = self:GetFightItem(i,v.roundDatas)
        item:addContent(content)
        content:size(content:getCascadeBoundingBox().width,content:getCascadeBoundingBox().height)
        item:setItemSize(content:getCascadeBoundingBox().width,content:getCascadeBoundingBox().height)
        self.fight_detail_list:addItem(item)
    end
    self.fight_detail_list:reload()
end
-- 1 = win 2 = failed
function GameUIShrineReport:GetResultLabel( label_type )
    local text  = label_type == 1 and _("胜利") or _("失败")
    local color = label_type == 1 and 0x007c23 or 0x7e0000
    return UIKit:ttfLabel({
        text = text,
        size = 20,
        color = color,
    })
end

function GameUIShrineReport:GetOnePlayerItem(roundData)
    local bg = WidgetPushButton.new({normal = "report_back_ground.png"})
        :onButtonClicked(function ()
            self:OnRePlayClicked(roundData)
        end)
    local vs = display.newSprite("shrine_VS_43x23.png")
        :align(display.CENTER,292,46)
        :addTo(bg)
    local attack_label,defence_label = "",""
    if roundData.fightResult == "attackWin" then
        attack_label = self:GetResultLabel(1)
        defence_label = self:GetResultLabel(2)
    else
        attack_label = self:GetResultLabel(2)
        defence_label = self:GetResultLabel(1)
    end
    attack_label:align(display.RIGHT_BOTTOM, vs:getPositionX() - 100, vs:getPositionY()):addTo(bg)
    local playerNameLabel = UIKit:ttfLabel({
        text = roundData.playerName,
        size = 22,
        color = 0x403c2f
    }):align(display.RIGHT_BOTTOM, attack_label:getPositionX(), attack_label:getPositionY()-30):addTo(bg)
    defence_label:align(display.LEFT_BOTTOM, vs:getPositionX() + 100, vs:getPositionY()):addTo(bg)
    local npcNameLabel =  UIKit:ttfLabel({
        text = "NPC",
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_BOTTOM, defence_label:getPositionX(), defence_label:getPositionY()-30):addTo(bg)
    return bg
end

function GameUIShrineReport:GetFightItem(index,roundDatas)
    local node = display.newNode()
    local x,y = 0,0
    for i=#roundDatas,1,-1 do
        self:GetOnePlayerItem(roundDatas[i]):addTo(node):align(display.LEFT_BOTTOM, x, y)
        y = y + 92
    end
    UIKit:ttfLabel({
        text = _("回合") .. index,
        size = 22,
        color =  0x403c2f
    }):align(display.CENTER,292, y+20):addTo(node)
    return node
end

function GameUIShrineReport:OnDropListSelected( tag )
    if self["CreateIf_" .. tag] then
        if self.current_node then
            self.current_node:hide()
        end
        self.current_node = self["CreateIf_" .. tag](self)
        self.current_node:show()
    end
    self:RefreshUI(tag)
end

function GameUIShrineReport:OnRePlayClicked(roundData)
    UIKit:newGameUI("GameUIReplayNew",self:GetShrineReport():GetFightReportObjectWithJson(roundData)):AddToCurrentScene(true)
end

function GameUIShrineReport:RefreshUI(tag)
    if tag == 'data_statistics' then
        self:RefreshDataStatisticsListView()
    elseif tag == 'fight_detail' then
        self:RefreshFightListView()
    end
end

function GameUIShrineReport:CreateIf_data_statistics()
    if self.data_statistics_node then return self.data_statistics_node end
    local data_statistics_node = display.newNode():addTo(self.bg_node)

    local logo = display.newSprite("shrine_report_logo_572x116.png"):align(display.LEFT_TOP, 20, 640):addTo(data_statistics_node)
    local honour_icon = display.newSprite("honour_128x128.png"):addTo(logo):pos(286,15):scale(42/128)
    UIKit:ttfLabel({
        text = _("联盟获得"),
        size = 18,
        color = 0xffedae
    }):align(display.RIGHT_CENTER,honour_icon:getPositionX()-20,honour_icon:getPositionY()):addTo(logo)
    UIKit:ttfLabel({
        text = self:GetShrineReport():GetHonour() or 0,
        size = 20,
        color = 0xffedae
    }):align(display.LEFT_CENTER, honour_icon:getPositionX()+20, honour_icon:getPositionY()):addTo(logo)
    local star_bar = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = self:GetShrineReport():Star(),
    }):addTo(logo):align(display.CENTER,honour_icon:getPositionX(),honour_icon:getPositionY()+40)
    self.data_statistics_node = data_statistics_node
    self.data_statistics_list = UIListView.new({
        -- bgColor = UIKit:hex2c4b(0x7a000000),
        viewRect = cc.rect(10,10,590,500),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
    }):addTo(data_statistics_node)
    local line = display.newScale9Sprite("dividing_line_594x2.png"):size(590,1):align(display.LEFT_BOTTOM,10,510):addTo(data_statistics_node)
    return data_statistics_node
end

function GameUIShrineReport:RefreshDataStatisticsListView()
    self.data_statistics_list:removeAllItems()
    for i,playerData in ipairs(self:GetShrineReport():PlayerDatas()) do
        local item  = self.data_statistics_list:newItem()
        local content = self:GetPlayerDataItem(playerData)
        item:addContent(content)
        content:size(590,content:getCascadeBoundingBox().height)
        item:setItemSize(590,content:getCascadeBoundingBox().height)
        self.data_statistics_list:addItem(item)
    end
    self.data_statistics_list:reload()
end

function GameUIShrineReport:GetPlayerDataItem(playerData)
    local node = display.newNode()
    local line = display.newScale9Sprite("dividing_line_594x2.png"):size(590,1):align(display.LEFT_BOTTOM,0,0):addTo(node)
    local strength_icon = display.newSprite("dragon_strength_27x31.png")
        :align(display.LEFT_BOTTOM,10,10)
        :addTo(node)
    UIKit:ttfLabel({
        text = playerData.kill,
        size = 22,
        color = 0x403c2f
    }):addTo(node):align(display.LEFT_BOTTOM,strength_icon:getPositionX()+strength_icon:getContentSize().width+5,strength_icon:getPositionY())
    local label = UIKit:ttfLabel({
        text = playerData.name,
        size = 22,
        color = 0x403c2f
    }):addTo(node):align(display.LEFT_BOTTOM,strength_icon:getPositionX(),strength_icon:getPositionY()+strength_icon:getContentSize().height+15)
    local x,y = strength_icon:getPositionX()+strength_icon:getContentSize().width+280,95
    for i,v in ipairs(playerData.rewards) do
        local item = display.newSprite("shire_reward_70x70.png")
            :align(display.LEFT_TOP,x,y)
            :addTo(node)
        UIKit:ttfLabel({
            text = "x" .. v.count,
            size = 22,
            color = 0x403c2f
        }):addTo(item):align(display.TOP_CENTER,35,2)
        x = x + 70 + 20
    end
    return node
end

return GameUIShrineReport

