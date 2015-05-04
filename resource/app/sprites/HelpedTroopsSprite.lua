local Sprite = import(".Sprite")
local HelpedTroopsSprite = class("HelpedTroopsSprite", Sprite)


function HelpedTroopsSprite:ctor(city_layer, index, x, y)
    self.index, self.x, self.y = index, x, y
    local ax, ay = city_layer:GetLogicMap():ConvertToMapPosition(x, y)
    HelpedTroopsSprite.super.ctor(self, city_layer, nil, ax, ay)
end
function HelpedTroopsSprite:GetSpriteFile()
    return "armyCamp.png"
end
function HelpedTroopsSprite:GetIndex()
	return self.index
end
function HelpedTroopsSprite:GetLogicPosition()
    return self.x, self.y
end
function HelpedTroopsSprite:GetMidLogicPosition()
    return self.x, self.y
end


return HelpedTroopsSprite


















