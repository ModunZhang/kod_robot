local UILib = import(".UILib")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local GameUIPveSweep = UIKit:createUIClass("GameUIPveSweep", "UIAutoClose")
function GameUIPveSweep:ctor(rewards)
    GameUIPveSweep.super.ctor(self)
    self:DisableAutoClose(true)

    local bg = cc.ui.UIPushButton.new(
        {normal = "pve_reward_bg.png", pressed = "pve_reward_bg.png", disabled = "pve_reward_bg.png"},
        {scale9 = false},
        {}
    ):pos(display.cx, display.cy):onButtonClicked(function()
        self:LeftButtonClicked()
    end)
    local h = 378
    local size = bg:getContentSize()
    local reward_bg = display.newScale9Sprite("pve_reward_bg1.png", nil, nil, cc.size(536,h))
        :addTo(bg):pos(0, 32)

    UIKit:ttfLabel({
        text = _("确定"),
        size = 22,
        color = 0xffedae,
    }):addTo(bg):align(display.CENTER, 0, -190)

    local list = UIListView.new{
        viewRect = cc.rect(0,0,536,h - 4),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(reward_bg)
    -- list.touchNode_:setTouchEnabled(false)
    for i,v in ipairs(rewards) do
        self:InsertItem(list, i, rewards[i])
    end
    list:reload()
    local dt = 0.5
    local acts = {}
    for i,v in ipairs(rewards) do
        table.insert(acts, cc.CallFunc:create(function() 
            list.items_[i]:show()
            app:GetAudioManager():PlayeEffectSoundWithKey("PVE_SWEEP")
         end))
        table.insert(acts, cc.DelayTime:create(dt))
        if i >= 5 and i ~= #rewards then
            table.insert(acts, cc.CallFunc:create(function() list:getScrollNode():moveBy(dt, 0, 74) end))
            table.insert(acts, cc.DelayTime:create(dt))
        else
            table.insert(acts, cc.DelayTime:create(dt))
        end
    end
    -- table.insert(acts, cc.CallFunc:create(function() list.touchNode_:setTouchEnabled(true) end))
    self:runAction(transition.sequence(acts))
    

    self:addTouchAbleChild(bg)
    bg:scale(0.5)
    transition.scaleTo(bg,
        {scaleX = 1, scaleY = 1, time = 0.3,
            easing = "backout",
        })
end
function GameUIPveSweep:InsertItem(list, index, reward)
    local item = list:newItem()
    local content = self:GetListItem(index,reward)
    item:addContent(content)
    item:setItemSize(528,74)
    item:hide()
    list:addItem(item)
end
function GameUIPveSweep:GetListItem(index,reward)
    local bg = display.newSprite("pve_reward_item.png")
    local size = bg:getContentSize()
    local png, txt
    if reward.type == "resources" then
        png = UILib.resource[reward.name]
        txt = Localize.fight_reward[reward.name]
    elseif reward.type == "soldierMaterials" then
        png = UILib.soldier_metarial[reward.name]
        txt = Localize.soldier_material[reward.name]
    end


    UIKit:ttfLabel({
        text = string.format(_("第%d战"), index),
        size = 22,
        color = 0xffedae,
    }):addTo(bg):align(display.LEFT_CENTER, 50, size.height/2)

    UIKit:ttfLabel({
        text = txt,
        size = 22,
        color = 0xffedae,
    }):addTo(bg):align(display.LEFT_CENTER, size.width - 120, size.height*3/4)

    UIKit:ttfLabel({
        text = "X"..GameUtils:formatNumber(reward.count),
        size = 22,
        color = 0xffedae,
    }):addTo(bg):align(display.LEFT_CENTER, size.width - 120, size.height*2/5)

    display.newSprite(png):addTo(
        display.newSprite("box_118x118.png"):addTo(bg):pos(size.width - 150, size.height/2):scale(0.5)
    ):pos(118/2, 118/2):scale(100/128)
    return bg
end



return GameUIPveSweep
























