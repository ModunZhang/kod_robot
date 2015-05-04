local GameUIWatiForNetWork = UIKit:createUIClass("GameUIWatiForNetWork")

function GameUIWatiForNetWork:ctor(delay)
    GameUIWatiForNetWork.super.ctor(self)
    self.delay = delay and checkint(delay) or 1
end
function GameUIWatiForNetWork:onEnter()
    GameUIWatiForNetWork.super.onEnter(self)
    display.newColorLayer(cc.c4b(255,255,255,0)):addTo(self):setTouchEnabled(true)

    self.sprite = display.newSprite("batcat_logo_368x390.png", display.cx, display.cy, {class=cc.FilteredSpriteWithOne})
    :addTo(self)

    local size = self.sprite:getContentSize()
    self.sprite:setScaleX(display.width / size.width)
    self.sprite:setScaleY(display.height / size.height)
    local filter = filter.newFilter("CUSTOM",
        json.encode({
            frag = "shaders/mask_layer.fs",
            shaderName = "mask_layer",
            iResolution = {display.widthInPixels, display.heightInPixels}
        })
    )
    self.sprite:setFilter(filter)

    self.loading = display.newSprite("loading_88x86.png"):addTo(self):pos(display.cx, display.cy)
    self.loading:runAction(cc.RepeatForever:create(cc.RotateBy:create(7, 360)))
    self.sprite:hide()
    self.loading:hide()
    
    self:performWithDelay(function()
        self.sprite:show()
        self.loading:show()
    end, self.delay)
end

function GameUIWatiForNetWork:DelayShow(delay)
     self.delay = delay and checkint(delay) or 1
     if not self:isVisible() then
        self:performWithDelay(function()
            self:show()
            self.sprite:show()
            self.loading:show()
        end, self.delay)
     end
end

function GameUIWatiForNetWork:LeftButtonClicked()
    self:hide()
end

return GameUIWatiForNetWork








