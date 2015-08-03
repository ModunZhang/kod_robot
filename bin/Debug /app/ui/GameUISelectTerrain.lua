local promise = import("..utils.promise")
local window = import("..utils.window")
local UILib = import("..ui.UILib")
local UICanCanelCheckBoxButtonGroup = import('.UICanCanelCheckBoxButtonGroup')
local UICheckBoxButton = import(".UICheckBoxButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUISelectTerrain = class("GameUISelectTerrain", WidgetPopDialog)


    

function GameUISelectTerrain:ctor()
    GameUISelectTerrain.super.ctor(self, 776, _("我们应该去哪儿?"), display.top - 100)
    self:DisableCloseBtn()
    self:DisableAutoClose()
    self.__type  = UIKit.UITYPE.BACKGROUND
end
function GameUISelectTerrain:OnMoveInStage()
    GameUISelectTerrain.super.OnMoveInStage(self)
    self.ui_map = self:BuildUI()
    self.ui_map.check_box_group:setCheckButtonStateChangeFunction(function(group, selectIndex, oldIndex)
        if selectIndex == oldIndex then return false end
        if selectIndex == 1 then
            self:RefreshDragon("grassLand")
        elseif selectIndex == 2 then
            self:RefreshDragon("desert")
        elseif selectIndex == 3 then
            self:RefreshDragon("iceField")
        end
        return true
    end)
    self:RefreshDragon("grassLand")

    self.ui_map.select:onButtonClicked(function(event)
        self.ui_map.select:setButtonEnabled(false)
        if DataManager:getUserData().basicInfo.terrain ~= "__NONE__" then
            DataManager:getFteData().basicInfo.terrain = DataManager:getUserData().basicInfo.terrain
            DataManager:setFteUserDeltaData()
            self.select_promise:resolve()
        else
            NetManager:initPlayerData(self.terrainType):done(function()
                DataManager:getFteData().basicInfo.terrain = DataManager:getUserData().basicInfo.terrain
                DataManager:setFteUserDeltaData()
                self.select_promise:resolve()
            end):fail(function()
                self.ui_map.select:setButtonEnabled(true)
            end)
        end
    end)
end
local terrain_map = {
    grassLand = {"green_long", 0, 50},
    desert = {"red_long", 20, 50},
    iceField = {"blue_long", 0, 50},
}
local desc_map = {
    grassLand = {
        title = _("草地"),
        desc1 = _("绿龙的聚集地"),
        desc2 = _("绿龙生命恢复速度+10%"),
        desc3 = _("战斗中, 绿龙力量+10%"),
    },
    desert = {
        title = _("沙漠"),
        desc1 = _("红龙的聚集地"),
        desc2 = _("红龙生命恢复速度+10%"),
        desc3 = _("战斗中, 红龙力量+10%"),
    },
    iceField = {
        title = _("雪地"),
        desc1 = _("蓝龙的聚集地"),
        desc2 = _("蓝龙生命恢复速度+10%"),
        desc3 = _("战斗中, 蓝龙力量+10%"),
    },
}
function GameUISelectTerrain:RefreshDragon(terrainType)
    UILib.loadDragonAnimation()
    self.ui_map.dragon_background:setTexture(string.format("fte_select_dragon_%s.jpg", terrainType))
    self.ui_map.dragon_background:removeAllChildren()
    local ani_name, ox, oy = unpack(terrain_map[terrainType])
    local s1 = self.ui_map.dragon_background:getContentSize()
    local dragon = ccs.Armature:create(ani_name)
        :addTo(self.ui_map.dragon_background)
        :pos(s1.width / 2 + ox, s1.height / 2 + oy)
    dragon:setScaleX(-0.5)
    dragon:setScaleY(0.5)
    dragon:getAnimation():play("idle")
    self.ui_map.title:setString(desc_map[terrainType].title)
    self.ui_map.desc1:setString(desc_map[terrainType].desc1)
    self.ui_map.desc2:setString(desc_map[terrainType].desc2)
    self.ui_map.desc3:setString(desc_map[terrainType].desc3)
    self.terrainType = terrainType
end
function GameUISelectTerrain:PromiseOfSelectDragon()
    self.select_promise = promise.new()
    return self.select_promise
end


function GameUISelectTerrain:BuildUI()
    local ui_map = {}
    local s = self:GetBody():getContentSize()
    local clip = display.newClippingRegionNode(cc.rect(0,0, 556, 341))
        :addTo(self:GetBody()):pos(25, s.height - 365)
    ui_map.dragon_background = display.newSprite("fte_select_dragon_grassLand.jpg")
        :addTo(clip):align(display.LEFT_BOTTOM)

    local s1 = ui_map.dragon_background:getContentSize()
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",
    }
    ui_map.check_box_group = UICanCanelCheckBoxButtonGroup.new(display.LEFT_TO_RIGHT):addButton(
        UICheckBoxButton.new(checkbox_image)
            -- :setButtonLabel(UIKit:ttfLabel({text = _("草地"),size = 20,color = 0x5c553f}))
            -- :setButtonLabelOffset(40, 0)
            :setButtonSelected(true)
    ):addButton(
        UICheckBoxButton.new(checkbox_image)
            -- :setButtonLabel(UIKit:ttfLabel({text = _("沙漠"),size = 20,color = 0x5c553f}))
            -- :setButtonLabelOffset(40, 0)
    ):addButton(
        UICheckBoxButton.new(checkbox_image)
            -- :setButtonLabel(UIKit:ttfLabel({text = _("雪地"),size = 20,color = 0x5c553f}))
            -- :setButtonLabelOffset(40, 0)
    ):addTo(self:GetBody()):pos(40, s.height - 430)
        :setButtonsLayoutMargin(0,130,0,0)
        :setIsSwitchModel(false)

    UIKit:ttfLabel({text = _("草地"),size = 20,color = 0x5c553f}):addTo(self:GetBody()):pos(100, s.height - 400)
    UIKit:ttfLabel({text = _("沙漠"),size = 20,color = 0x5c553f}):addTo(self:GetBody()):pos(290, s.height - 400)
    UIKit:ttfLabel({text = _("雪地"),size = 20,color = 0x5c553f}):addTo(self:GetBody()):pos(480, s.height - 400)

    local list_bg = display.newScale9Sprite("back_ground_540x64.png", s.width/2, s.height - 490, cc.size(540, 156))
        :align(display.TOP_CENTER):addTo(self:GetBody())
    local s3 = list_bg:getContentSize()
    local title_bg = display.newSprite("alliance_evnets_title_548x50.png")
        :addTo(list_bg):pos(s3.width/2, s3.height + 25)
    local bar1 = display.newScale9Sprite("back_ground_548x40_1.png"):addTo(list_bg):pos(s3.width/2, s3.height-30):size(520,46)
    local bar2 = display.newScale9Sprite("back_ground_548x40_2.png"):addTo(list_bg):pos(s3.width/2, s3.height-30 - 46 * 1):size(520,46)
    local bar3 = display.newScale9Sprite("back_ground_548x40_1.png"):addTo(list_bg):pos(s3.width/2, s3.height-30 - 46 * 2):size(520,46)

    local s4 = title_bg:getContentSize()
    ui_map.title = UIKit:ttfLabel({size = 22,color = 0xffedae})
        :align(display.CENTER, s4.width/2, s4.height/2):addTo(title_bg)
    ui_map.desc1 = UIKit:ttfLabel({size = 20,color = 0x403c2f})
        :align(display.LEFT_CENTER, 20, 23):addTo(bar1)
    ui_map.desc2 = UIKit:ttfLabel({size = 20,color = 0x403c2f})
        :align(display.LEFT_CENTER, 20, 23):addTo(bar2)
    ui_map.desc3 = UIKit:ttfLabel({size = 20,color = 0x403c2f})
        :align(display.LEFT_CENTER, 20, 23):addTo(bar3)


    ui_map.select = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",
            pressed = "yellow_btn_down_148x58.png"}
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("选择"),
        size = 24,
        color = 0xffedae,
        shadow= true
    })):addTo(self:GetBody()):pos(s.width/2, 60)
    return ui_map
end

return GameUISelectTerrain







