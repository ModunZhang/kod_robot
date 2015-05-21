local GameUIWatiForNetWork = UIKit:createUIClass("GameUIWatiForNetWork")
local modf = math.modf
function GameUIWatiForNetWork:ctor(delay)
    GameUIWatiForNetWork.super.ctor(self)
    self.delay = delay and checkint(delay) or 1
end
local loading_map = {
    {
        "loading_bg_yellow.png",
        "loading_circle_yellow.png",
        "loading_icon_yellow.png",
    },
    {
        "loading_bg_green.png",
        "loading_circle_green.png",
        "loading_icon_green.png",
    },
    {
        "loading_bg_blue.png",
        "loading_circle_blue.png",
        "loading_icon_blue.png",
    },
}
function GameUIWatiForNetWork:onEnter()
    GameUIWatiForNetWork.super.onEnter(self)
    display.newColorLayer(cc.c4b(255,255,255,0)):addTo(self):setTouchEnabled(true)

    self.sprite = display.newSprite("click_empty.png", display.cx, display.cy, {class=cc.FilteredSpriteWithOne})
    :addTo(self)
    local size = self.sprite:getContentSize()
    self.sprite:setScaleX(display.width / size.width)
    self.sprite:setScaleY(display.height / size.height)
    self.sprite:setFilter(filter.newFilter("CUSTOM",
        json.encode({
            frag = "shaders/mask_layer.fs",
            shaderName = "mask_layer",
            iResolution = {display.widthInPixels, display.heightInPixels}
        })
    ))

    self.loading = display.newNode():addTo(self)

    math.randomseed(os.time())
    local bg,circle,icon = unpack(loading_map[math.random(#loading_map)])
    display.newSprite(bg):addTo(self.loading)
    :pos(display.cx, display.cy):scale(0.8)
    
    display.newSprite(circle)
    :addTo(self.loading):pos(display.cx, display.cy):scale(0.8)
    :runAction(cc.RepeatForever:create(cc.RotateBy:create(2, -360)))
 
    local icon = display.newSprite(icon, display.cx, display.cy, 
        {class=cc.FilteredSpriteWithOne}):addTo(self.loading):scale(0.8)

    local time, flashTime = 0, 1
    local _,ratio = (modf(time, flashTime) / flashTime)
    icon:setFilter(filter.newFilter("CUSTOM", json.encode({
        frag = "shaders/flash.fs",
        shaderName = "flash1",
        ratio = ratio,
    })))
    icon:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        time = time + dt
        local _,ratio = modf(time, flashTime)
        icon:getFilter():getGLProgramState():setUniformFloat("ratio", ratio / flashTime)
    end)
    icon:scheduleUpdate()


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








