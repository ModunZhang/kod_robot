local WidgetDirectionSelect = class("WidgetDirectionSelect", function()
    return display.newNode()
end)


local L,R = 100, 2.39
function WidgetDirectionSelect:ctor()
	self.left = display.newSprite("pve_move_icon_locked.png"):addTo(self):rotation(-90):pos(-L,0)
	self.right = display.newSprite("pve_move_icon_locked.png"):addTo(self):rotation(90):pos(L,0)
	self.up = display.newSprite("pve_move_icon_locked.png"):addTo(self):pos(0,L)
	self.down = display.newSprite("pve_move_icon_locked.png"):addTo(self):rotation(180):pos(0,-L)
end
function WidgetDirectionSelect:EnableDirection(left, right, up, down)
	self:RefreshTexture(left, right, up, down)
	self.left:show()
	self.right:show()
	self.up:show()
	self.down:show()
	return self
end
function WidgetDirectionSelect:ShowDirection(left, right, up, down)
	self:RefreshTexture(left, right, up, down)
	self.left:setVisible(left)
	self.right:setVisible(right)
	self.up:setVisible(up)
	self.down:setVisible(down)
	return self
end
function WidgetDirectionSelect:RefreshTexture(left, right, up, down)
	self.left:setTexture(left and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")
	self.right:setTexture(right and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")
	self.up:setTexture(up and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")
	self.down:setTexture(down and "pve_move_icon_unlock.png" or "pve_move_icon_locked.png")
	return self
end





return WidgetDirectionSelect