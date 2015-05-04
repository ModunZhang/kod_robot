local SpriteUINode = import("..ui.SpriteUINode")
local Arrow = class("Arrow", SpriteUINode)
function Arrow:InitWidget()
    self.arrow = display.newSprite("arrow.png"):addTo(self):align(display.BOTTOM_CENTER):rotation(90)
end
function Arrow:Set(angle, offset_x, offset_y)
	angle = angle or 0
    offset_x = offset_x or 10
    offset_y = offset_y or 100
	self.arrow:pos(offset_x, offset_y)
	self.arrow:rotation(angle)
	return self
end


return Arrow