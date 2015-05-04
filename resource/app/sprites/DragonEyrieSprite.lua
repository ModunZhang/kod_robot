local DragonSprite = import(".DragonSprite")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local DragonEyrieSprite = class("DragonEyrieSprite", FunctionUpgradingSprite)
local DragonManager = import("..entity.DragonManager")
local DRAGON_ZORDER = 1


function DragonEyrieSprite:ctor(...)
    DragonEyrieSprite.super.ctor(self, ...)
    local dragon_manget = self:GetEntity():BelongCity():GetDragonEyrie():GetDragonManager()
    dragon_manget:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDefencedDragonChanged)
    self:ReloadSpriteCaseDragonDefencedChanged(dragon_manget:GetDefenceDragon())
end

function DragonEyrieSprite:ReloadSpriteCauseTerrainChanged()
end

function DragonEyrieSprite:ReloadSpriteCaseDragonDefencedChanged(dragon)
	if self.dragon_sprite and not dragon then
		self.dragon_sprite:removeSelf()
		self.dragon_sprite = nil
	elseif dragon then
		if not self.dragon_sprite then
		    local x, y = self:GetSpriteOffset()
		    self.dragon_sprite = DragonSprite.new(self:GetMapLayer(),dragon:GetTerrain()):addTo(self, DRAGON_ZORDER):scale(0.5):pos(x, y+80)
		else
			self.dragon_sprite:ReloadSpriteCauseTerrainChanged(dragon:GetTerrain())
		end
	end
end

function DragonEyrieSprite:OnDefencedDragonChanged(dragon)
	self:ReloadSpriteCaseDragonDefencedChanged(dragon)
end


function DragonEyrieSprite:onCleanup()
	self:GetEntity():BelongCity():GetDragonEyrie():GetDragonManager():RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDefencedDragonChanged)
	if DragonEyrieSprite.super.onCleanup then
		DragonEyrieSprite.super.onCleanup(self)
	end
end

return DragonEyrieSprite


















