local GameUIUnlockBuilding = import("..ui.GameUIUnlockBuilding")
local LockState = class("LockState")
function LockState:ctor(sprite_button)
    self.sprite_button = sprite_button
end
function LockState:OnEnter()
    local sprite_button = self.sprite_button
    sprite_button.lock_button:setVisible(true)
    sprite_button.confirm_button:setVisible(false)
end
function LockState:OnExit()
    self.sprite_button.lock_button:setVisible(false)
end
---
local ConfirmState = class("ConfirmState")
function ConfirmState:ctor(sprite_button)
    self.sprite_button = sprite_button
end
function ConfirmState:OnEnter()
    local sprite_button = self.sprite_button
    self.sprite_button:setLocalZOrder(10)
    sprite_button.lock_button:setVisible(false)
    sprite_button.confirm_button:setVisible(true)
end
function ConfirmState:OnExit()
    local sprite_button = self.sprite_button
    self.sprite_button:setLocalZOrder(-1)
    sprite_button.confirm_button:setVisible(false)
end
---
local UnlockedState = class("UnlockedState")
function UnlockedState:ctor(sprite_button)
    self.sprite_button = sprite_button
end
function UnlockedState:OnEnter()
    local sprite_button = self.sprite_button
    sprite_button.lock_button:setVisible(false)
    sprite_button.confirm_button:setVisible(false)
end
function UnlockedState:OnExit()
    local sprite_button = self.sprite_button
    sprite_button.lock_button:setVisible(false)
    sprite_button.confirm_button:setVisible(false)
end

----
--
local CannotUnlockState = class("CannotUnlockState")
function CannotUnlockState:ctor(sprite_button)
    self.sprite_button = sprite_button
end
function CannotUnlockState:OnEnter()
    local sprite_button = self.sprite_button
    sprite_button.lock_button:setVisible(false)
    sprite_button.confirm_button:setVisible(false)
end
function CannotUnlockState:OnExit()
    local sprite_button = self.sprite_button
    sprite_button.lock_button:setVisible(false)
    sprite_button.confirm_button:setVisible(false)
end
---

local FiniteMachine = import('..utils.FiniteMachine')
local SpriteButton = class("SpriteButton", function(...)
    return FiniteMachine.extend(display.newNode(), ...)
end)
function SpriteButton:OnUpgradingBegin(building, current_time, city)
    self:OnTileChanged(city)
end
function SpriteButton:OnUpgrading(building, current_time, city)
end
function SpriteButton:OnUpgradingFinished(building, city)
    self:OnTileChanged(city)
end
function SpriteButton:OnTileChanged(city)
    local current_tile = self.sprite:GetEntity()
    local building = city:GetBuildingByLocationId(current_tile.location_id)
    if current_tile:IsUnlocked() then
        self:TranslateToSatateByName("unlocked")
    elseif building and building:IsUpgrading() then
        self:TranslateToSatateByName("can_not_unlocked")
    elseif city:IsTileCanbeUnlockAt(current_tile.x, current_tile.y) then
        if city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(city) > 0 then
            self:TranslateToSatateByName("locked")
        else
            self:TranslateToSatateByName("can_not_unlocked")
        end
    else
        self:TranslateToSatateByName("can_not_unlocked")
    end
end
function SpriteButton:OnPositionChanged(x, y)
    self:setPosition(self:GetPositionFromWorld(x, y))
end
function SpriteButton:GetPositionFromWorld(x, y)
    return self:getParent():convertToNodeSpace(cc.p(x, y))
end
function SpriteButton:hitTest(ccpoint)
    return self.lock_button:hitTest(ccpoint)
end
function SpriteButton:ctor(sprite, city)
    self.sprite = sprite
    self.lock_button = cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"}):addTo(self)
    self.confirm_button = cc.ui.UIPushButton.new({normal = "confirm_btn_up.png",pressed = "confirm_btn_down.png"}):addTo(self)

    self:SetLockTouchListener(function()
        local tile = self.sprite:GetEntity()
        local unlock_point = city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(city)
        if tile and unlock_point > 0 and city:IsTileCanbeUnlockAt(tile.x, tile.y) then
             UIKit:newGameUI("GameUIUnlockBuilding", city,tile):AddToCurrentScene(true)
        end
    end)

    self:AddState("locked", LockState.new(self))
    self:AddState("confirm", ConfirmState.new(self))
    self:AddState("unlocked", UnlockedState.new(self))
    self:AddState("can_not_unlocked", CannotUnlockState.new(self))

    self:OnTileChanged(city)
end
function SpriteButton:SetLockTouchListener(func)
    self.lock_button:onButtonClicked(function(event)
        func()
    end)
end
function SpriteButton:SetConfirmTouchListener(func)
    self.confirm_button:onButtonClicked(function(event)
        func()
    end)
end



return SpriteButton





