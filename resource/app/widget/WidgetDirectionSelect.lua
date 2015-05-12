local WidgetDirectionSelect = class("WidgetDirectionSelect", function()
    return display.newNode()
end)



function WidgetDirectionSelect:ctor()
	self.left = display.newSprite("pve_move_icon_locked.png"):addTo(self):rotation(-90)
	self.right = display.newSprite("pve_move_icon_locked.png"):addTo(self):rotation(90)
	self.up = display.newSprite("pve_move_icon_locked.png"):addTo(self)
	self.down = display.newSprite("pve_move_icon_locked.png"):addTo(self):rotation(180)
end
function WidgetDirectionSelect:EnableDirection(left, right, up, down)
	self.left:zorder(left and 1 or 0)
	:setTexture(left and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")

	self.right:zorder(right and 1 or 0)
	:setTexture(right and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")

	self.up:zorder(up and 1 or 0)
	:setTexture(up and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")
	
	self.down:zorder(down and 1 or 0)
	:setTexture(down and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")
	return self
end





return WidgetDirectionSelect