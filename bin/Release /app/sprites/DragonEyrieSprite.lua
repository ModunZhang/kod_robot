local DragonSprite = import(".DragonSprite")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local DragonEyrieSprite = class("DragonEyrieSprite", FunctionUpgradingSprite)
local DragonManager = import("..entity.DragonManager")
local DRAGON_ZORDER = 1


function DragonEyrieSprite:OnUserDataChanged_dragons(userData, deltaData)
	self:ReloadSpriteCaseDragonDefencedChanged(userData:GetDefenceDragonType())
end

function DragonEyrieSprite:ctor(...)
    DragonEyrieSprite.super.ctor(self, ...)
    local User = self:GetEntity():BelongCity():GetUser()
    self:ReloadSpriteCaseDragonDefencedChanged(User:GetDefenceDragonType())
    User:AddListenOnType(self, "dragons")
end
function DragonEyrieSprite:ReloadSpriteCaseDragonDefencedChanged(dragonType)
	if self.dragon_sprite and not dragonType then
		self.dragon_sprite:removeSelf()
		self.dragon_sprite = nil
	elseif dragonType then
		if not self.dragon_sprite then
		    local x, y = self:GetSpriteOffset()
		    self.dragon_sprite = DragonSprite.new(self:GetMapLayer(),dragonType)
		    			 :addTo(self, DRAGON_ZORDER):scale(0.5):pos(x + 10, y + 40)
		else
			self.dragon_sprite:ReloadSpriteCauseTerrainChanged(dragonType)
		end
	end
end
return DragonEyrieSprite


















