local window = import("..utils.window")
local UIListView = import("..ui.UIListView")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetPushButton = import(".WidgetPushButton")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetPVESelectStage = class("WidgetPVESelectStage", WidgetPopDialog)




function WidgetPVESelectStage:ctor(user)
    self.user = user
    self.pve_database = user:GetPVEDatabase()
    WidgetPVESelectStage.super.ctor(self, 674, _("选择关卡"), display.cy + 350)
    local back =display.newScale9Sprite("background_568x120.png", 0,0,cc.size(568,612),cc.rect(15,10,538,100)):addTo(self:GetBody())
        :pos(self:GetBody():getContentSize().width/2, 674/2)
    local list_view = UIListView.new({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 549, 589),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    list_view:addTo(back):pos(10, 13)

    for i = 1, self.pve_database:MapLen() do
        list_view:addItem(self:CreateItemWithListView(list_view, i))
    end
    list_view:reload()
end


function WidgetPVESelectStage:CreateItemWithListView(list_view, level)
    local item = list_view:newItem()
    local back_ground = display.newScale9Sprite(level % 2 == 0 and "back_ground_548x40_1.png" or "back_ground_548x40_2.png",0,0,cc.size(547,97),cc.rect(10,10,528,20))
    local size = back_ground:getContentSize()
    local w = size.width
    local h = size.height
    item:addContent(back_ground)
    item:setItemSize(w, h)

    local cur_map = self.pve_database:GetMapByIndex(level)
    cc.ui.UILabel.new({
        size = 24,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x403c2f),
        text = string.format("%d, %s", cur_map:GetIndex(), cur_map:Name()),
    }):addTo(back_ground, 2):align(display.LEFT_CENTER, 10, h - 30)

    cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x403c2f),
        text = string.format("探索度 %.2f%%", cur_map:ExploreDegree() * 100)
    }):addTo(back_ground, 2):align(display.LEFT_CENTER, 10, 20)

    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(back_ground)
        :align(display.CENTER, w - 90, 40)
        :setButtonLabel(cc.ui.UILabel.new({
            text = _("传送"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xffedae)}))
        :onButtonClicked(function(event)
            self.user:ResetPveData()
            local point = self.user:GetPVEDatabase():GetMapByIndex(level):GetStartPoint()
            self.user:GetPVEDatabase():SetCharPosition(point.x, point.y, level)
            NetManager:getSetPveDataPromise(
                self.user:EncodePveDataAndResetFightRewardsData()
            ):done(function()
                self:removeFromParent()
                app:EnterPVEScene(level)
            end):fail(function()
                -- 回滚
                local location = DataManager:getUserData().pve.location
                self.user:GetPVEDatabase():SetCharPosition(location.x, location.y, location.z)
            end)
        end):setButtonEnabled(cur_map:IsAvailable() and self.user:GetCurrentPVEMap():GetIndex() ~= level)
    return item
end


return WidgetPVESelectStage




