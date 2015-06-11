--
-- Author: Kenny Dai
-- Date: 2015-06-02 11:22:39
--
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local window = import("..utils.window")
local GameUIChest = UIKit:createUIClass("GameUIChest")

function GameUIChest:ctor(item,awards,tips,ani)
    GameUIChest.super.ctor(self)
    self.item = item
    self.awards = awards
    self.tips = tips
    self.ani = ani
end

function GameUIChest:onEnter()
    GameUIChest.super.onEnter(self)
    local box = ccs.Armature:create(self.ani):addTo(self):align(display.CENTER, display.cx-50, display.cy+35)
        :scale(0.65)
    box:getAnimation():setMovementEventCallFunc(function (armatureBack, movementType, movementID)
        if movementType == ccs.MovementEventType.start then
        elseif movementType == ccs.MovementEventType.complete then
        elseif movementType == ccs.MovementEventType.loopComplete then
        end
    end)

    box:getAnimation():play("Animation1", -1, 0)

    local guang_box = ccs.Armature:create("Box_guang"):addTo(self):align(display.CENTER, display.cx, display.cy+100)
        :scale(0.65)

    guang_box:getAnimation():setMovementEventCallFunc(function (armatureBack, movementType, movementID)
        if movementType == ccs.MovementEventType.start then
        elseif movementType == ccs.MovementEventType.complete then
            self:ShowAwards()
        elseif movementType == ccs.MovementEventType.loopComplete then
        end
    end)
    guang_box:getAnimation():play("Animation1", -1, 0)
    self.guang_box = guang_box
end

function GameUIChest:onExit()
    GameUIChest.super.onExit(self)
end

function GameUIChest:ShowAwards()
    local awards = self.awards
    local award_count = #awards
    local total_width = 400
    local gap_x = 50
    local icon_width = 118 * 0.8
    local origin_x = display.cx - ((award_count > 1 and award_count or 0) * icon_width + gap_x * (award_count > 1 and award_count -1 or 0)) / 2 +  (award_count > 1 and icon_width/2 or 0)
    for i,v in ipairs(self.awards) do
        local icon_bg = display.newSprite("box_118x118.png"):align(display.CENTER, origin_x + (i -1) * (icon_width + gap_x), display.cy + 60):addTo(self):scale(3)
        local icon = display.newSprite(UILib.item[v.name] or UILib.dragon_material_pic_map[v.name]):align(display.CENTER,icon_bg:getContentSize().width/2,icon_bg:getContentSize().height/2):addTo(icon_bg)
        icon:scale(100/math.max(icon:getContentSize().width,icon:getContentSize().height))
        transition.scaleTo(icon_bg, {scale =2.5,time =0.05,onComplete = function ()
            transition.scaleTo(icon_bg, {scale =1.8,time =0.05,onComplete = function ()
                transition.scaleTo(icon_bg, {scale =0.4,time =0.02,onComplete = function ()
                    transition.scaleTo(icon_bg, {scale =0.8,time =0.1,onComplete = function ()
                        UIKit:ttfLabel({
                            text = string.format(_(" X %d"),v.count),
                            size = 24,
                            color = 0xffedae
                        }):align(display.CENTER,  origin_x + (i -1) * (icon_width + gap_x), display.cy)
                            :addTo(self)
                        if i == award_count then
                            GameGlobalUI:showTips(_("提示"),self.tips)
                            self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
                                if event.name == "ended" then
                                    self:LeftButtonClicked()
                                end
                                return true
                            end)
                        end
                    end})
                end})
            end})
        end})
    end
end

return GameUIChest
















