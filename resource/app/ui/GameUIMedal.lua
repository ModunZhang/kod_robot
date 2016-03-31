--
-- Author: Kenny Dai
-- Date: 2016-01-25 15:47:31
--
local GameUIMedal = UIKit:createUIClass("GameUIMedal","GameUIWithCommonHeader")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")

local medal_config = {
    -- 勋章
    {
        name = _("帝王之师"),
        effect = _("部队攻击").."+10%，".._("部队生命").."+10%，".._("带兵上限").."+10%",
        isGood = true
    },
    {
        name = _("暗天使"),
        effect = _("木材").."/".._("石料").."/".._("铁矿").."/".._("粮食产量").."+10%，".._("暗仓保护").."+10%",
        isGood = true
    },
    {
        name = _("战争修士"),
        effect = _("建造速度").."+10%，".._("研发速度").."+10%，".._("城墙恢复速度").."+10%",
        isGood = true
    },
    {
        name = _("灰骑士"),
        effect = _("招募速度").."+10%，".._("维护费用").."-10%，".._("带兵上限").."+10%",
        isGood = true
    },
    {
        name = _("钢铁之手"),
        effect = _("部队生命").."+10%，".._("治愈伤兵速度").."+20%",
        isGood = true
    },
    {
        name = _("极限战士"),
        effect = _("部队攻击").."+10%，".._("龙的生命恢复").."+15%",
        isGood = true
    },
    {
        name = _("守望者"),
        effect = _("木材产量").."+10%，".._("石料产量").."+10%，".._("建造速度").."+5%",
        isGood = true
    },
    -- 诅咒
    {
        name = _("恐惧折磨"),
        effect = _("部队攻击").."-10%，".._("部队生命").."-10%，".._("带兵上限").."-10%",
        isGood = false
    },
    {
        name = _("绝望折磨"),
        effect = _("暗仓保护").."-10%，".._("箭塔攻击").."-20%，".._("部队攻击").."-10%",
        isGood = false
    },
    {
        name = _("腐化之种"),
        effect = _("木材").."/".._("石料").."/".._("铁矿").."/".._("粮食产量").."-10%，".._("招募速度").."-10%",
        isGood = false
    },
    {
        name = _("暗影魔咒"),
        effect = _("城墙恢复速度").."-15%，".._("龙的生命恢复").."-15%",
        isGood = false
    },
    {
        name = _("血之诅咒"),
        effect = _("部队生命").."+10%，".._("伤兵转换").."-10%",
        isGood = false
    },
    {
        name = _("丧失神智"),
        effect = _("维护费用增加").."+20%，".._("研发速度").."-10%",
        isGood = false
    },
    {
        name = _("迟缓诅咒"),
        effect = _("木材产量").."-10%，".._("石料产量").."-10%，".._("建造速度").."-5%",
        isGood = false
    },
}

function GameUIMedal:ctor(city)
    GameUIMedal.super.ctor(self,city, _("头衔"))
end

function GameUIMedal:onEnter()
    GameUIMedal.super.onEnter(self)
    local view = self:GetView()
    local  listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(window.left + 36,window.bottom + 20, 568, 860),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(view)
    self.medal_list = listview
    for i,medal in ipairs(medal_config) do
        listview:addItem(self:GetMedalItem(medal,i))
    end
    listview:reload()

    listview:onTouch(handler(self, self.listviewListener))

end
function GameUIMedal:onExit()
    GameUIMedal.super.onExit(self)
end
function GameUIMedal:GetMedalItem(medal,index)
    local item = self.medal_list:newItem()
    local content = WidgetUIBackGround.new({width = 568,height= 154},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local b_size = content:getContentSize()
    local icon_bg = display.newSprite("box_136x136.png"):addTo(content):pos(72,b_size.height/2)
    local icon_img = string.format("icon_%s_%d.png",medal.isGood and "medal" or "curse",medal.isGood and index or (index-7))
    print("icon_img=",icon_img)
    local icon = display.newSprite(icon_img)
        :align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height/2):addTo(icon_bg)
    local title_bg
    if medal.isGood  then
        title_bg = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(412,30), cc.rect(10,10,410,10)):addTo(content):align(display.LEFT_CENTER,140 , b_size.height-28)
    else
        title_bg = display.newScale9Sprite("title_red_166x30.png",0,0, cc.size(412,30), cc.rect(10,10,146,10)):addTo(content):align(display.LEFT_CENTER,140 , b_size.height-28)
    end
    UIKit:ttfLabel({
        text = medal.name,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 15, title_bg:getContentSize().height/2)
        :addTo(title_bg)
    UIKit:ttfLabel({
        text = _("未颁发"),
        size = 20,
        color = 0x7e0000,
    }):align(display.LEFT_CENTER, icon_bg:getPositionX() + icon_bg:getContentSize().width/2 + 16, 90)
        :addTo(content)
    UIKit:ttfLabel({
        text = medal.effect,
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(370,0)
    }):align(display.LEFT_TOP, icon_bg:getPositionX() + icon_bg:getContentSize().width/2 + 16, 70)
        :addTo(content)
    -- display.newSprite("next_32x38.png"):align(display.RIGHT_CENTER, 568, 154/2 - 10):addTo(content)

    item:addContent(content)
    item:setItemSize(568,154)
    return item
end
function GameUIMedal:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local pos = event.itemPos
        if not pos then
            return
        end
        -- app:GetAudioManager():PlayeEffectSoundWithKey("NORMAL_DOWN")
    end
end
return GameUIMedal








