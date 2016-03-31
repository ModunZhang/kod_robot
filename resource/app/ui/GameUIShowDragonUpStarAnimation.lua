--
-- Author: Danny He
-- Date: 2015-05-03 10:03:02
--
local promise = import("..utils.promise")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UILib = import(".UILib")
local GameUIShowDragonUpStarAnimation = UIKit:createUIClass("GameUIShowDragonUpStarAnimation","UIAutoClose")
--
-- Kenny Dai
-- 增加龙升级时也可条用此UI
--
function GameUIShowDragonUpStarAnimation:ctor(dragon,isLevelUp)
    self:DisableAutoClose()
    self.isLevelUp = isLevelUp
    GameUIShowDragonUpStarAnimation.super.ctor(self)
    app:GetAudioManager():PlayeEffectSoundWithKey("HOORAY")
    local old_strenth,old_vitality,old_leadershiip
    if isLevelUp then
        old_strenth,old_vitality,old_leadershiip = dragon:GetLevelPromotionedOldVal()
    else
        old_strenth,old_vitality,old_leadershiip = dragon:GetPromotionedOldVal()
    end
    self.buff_value = {
        {dragon:Strength(),old_strenth},
        {dragon:GetBasicMaxHP() ,old_vitality},
        {dragon:LeadBasicCitizen() ,old_leadershiip},
    }
    self.dragon_iamge = UILib.dragon_head[dragon:Type()]
    self:setNodeEventEnabled(true)
    self.star_val = dragon:Star()
end

function GameUIShowDragonUpStarAnimation:onEnter()
    GameUIShowDragonUpStarAnimation.super.onEnter(self)
    self:DisableAutoClose()
    --构建UI
    local node = display.newNode()
    self:addTouchAbleChild(node)
    local bg = ccs.Armature:create("jinjichenggong"):addTo(node):center() -- 201
    local juhua = ccs.Armature:create("jinjichenggong"):addTo(node):center()
    local header = ccs.Armature:create("jinjichenggong"):addTo(node):center() -- 301
    local star = ccs.Armature:create("jinjichenggong"):addTo(node):center()
    self.dragon_icon = display.newSprite(self.dragon_iamge):pos(0,202):addTo(header):zorder(100):hide()
    self.title_label = UIKit:ttfLabel({
        text = self.isLevelUp and _("升级成功") or _("晋级成功"),
        color= 0xffffff,
        size = 38
    }):addTo(header):align(display.CENTER_BOTTOM, 0, 50):hide()

    self.ok_button = WidgetPushButton.new({normal = "transparent_1x1.png"}):setButtonLabel("normal", UIKit:commonButtonLable({
        text = _("确定"),
        size = 22,
        color= 0xfff3c7,
    })):addTo(header):align(display.CENTER_BOTTOM, 0, -140):onButtonClicked(function()
        self:removeSelf()
    end):hide()

    self.strength_title_label = UIKit:ttfLabel({
        text = _("攻击力"),
        size = 20,
        color= 0xffedae
    }):addTo(header):align(display.LEFT_CENTER, -200, 15):hide()

    self.strength_val_label = self:CreateValueNode(self.buff_value[1]):addTo(header):align(display.CENTER, 130, 15):hide()

    self.vitality_title_label = UIKit:ttfLabel({
        text = _("生命值"),
        size = 20,
        color= 0xffedae
    }):addTo(header):align(display.LEFT_CENTER, -200, -35):hide()

    self.vitality_val_label =self:CreateValueNode(self.buff_value[2]):addTo(header):align(display.CENTER, 130, -35):hide()

    self.leadship_title_label = UIKit:ttfLabel({
        text = _("带兵量"),
        size = 20,
        color= 0xffedae
    }):addTo(header):align(display.LEFT_CENTER, -200, -85):hide()

    self.leadship_val_label = self:CreateValueNode(self.buff_value[3]):addTo(header):align(display.CENTER, 130, -85):hide()
    -- 开始播放
    juhua:getAnimation():play("ceng_2", -1, -1)
    self:PlayAnimationWithFrameEventCallFunc(header,"ceng_1",301):next(function() -- 301 时出现龙头
        self.dragon_icon:show()
    end)
    self:PlayAnimationWithFrameEventCallFunc(bg,"ceng_3",201):next(function() -- 201时出现文字
        self.title_label:show()
        self.ok_button:show()
        self.strength_title_label:show()
        self.vitality_title_label:show()
        self.leadship_title_label:show()
        self.strength_val_label:show()
        self.vitality_val_label:show()
        self.leadship_val_label:show()
        self:DisableAutoClose(false)
    end)
    self:PlayStarPromise(star,tonumber(self.star_val))
end

function GameUIShowDragonUpStarAnimation:onCleanup()
    GameUIShowDragonUpStarAnimation.super.onCleanup(self)
end
function GameUIShowDragonUpStarAnimation:CreateValueNode(values)
    local node = display.newNode()
    local old_value = UIKit:ttfLabel({
        text = string.formatnumberthousands(values[2]),
        size = 22,
        color= 0xffedae
    }):addTo(node)
    local green_icon = display.newSprite("upgrade_icon_14x16.png"):addTo(node)
    local cur_value = UIKit:ttfLabel({
        text = string.formatnumberthousands(values[1]),
        size = 22,
        color= 0x7eff00
    }):addTo(node)
    node:setContentSize(cc.size(old_value:getContentSize().width + cur_value:getContentSize().width + green_icon:getContentSize().width + 13,22))
    local n_size = node:getContentSize()
    green_icon:align(display.CENTER, n_size.width/2, n_size.height/2)
    old_value:align(display.RIGHT_CENTER, green_icon:getPositionX() - 20, n_size.height/2)
    cur_value:align(display.LEFT_CENTER, green_icon:getPositionX() + 20, n_size.height/2)
    return node
end

function GameUIShowDragonUpStarAnimation:PlayStarPromise(armature,star)
    local p = promise.new()
    local animation = armature:getAnimation()
    animation:play("ceng_4", -1, 0)
    animation:setFrameEventCallFunc(function(bone,frameEventName,originFrameIndex,currentFrameIndex)
        if tonumber(frameEventName) - 100 == star then -- 101 ～ 105 表示每一颗星级
            animation:stop()
            p:resolve()
        end
    end)
    return p
end

function GameUIShowDragonUpStarAnimation:PlayAnimationWithFrameEventCallFunc(armature,name,frameIndex)
    frameIndex = tonumber(frameIndex)
    local p = promise.new()
    local animation = armature:getAnimation()
    animation:play(name, -1, 0)
    animation:setFrameEventCallFunc(function(bone,frameEventName,originFrameIndex,currentFrameIndex)
        if tonumber(frameEventName) == frameIndex then
            animation:stop()
            p:resolve()
        end
    end)
    return p
end

return GameUIShowDragonUpStarAnimation

