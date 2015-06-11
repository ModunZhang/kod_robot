local WidgetMaskFilter = class("WidgetMaskFilter", function()
    return display.newSprite("click_empty.png",nil,nil,{class=cc.FilteredSpriteWithOne})
end)

function WidgetMaskFilter:ctor()
    local s = self:getContentSize()
    self:setScale(display.width/s.width)
    self:setScaleY(display.height/s.height)
    self:FocusOnRect()
end
local min = math.min
local max = math.max
local function clamp(s,e,n)
    return n < s and s or (n > e and e or n)
end
function WidgetMaskFilter:FocusOnRect(rect)
    if not rect then
        self:clearFilter()
        self:setFilter(filter.newFilter("CUSTOM", json.encode({
            frag = "shaders/mask.fs",
            shaderName = "mask1",
            rect = { 0,0,0,0 },
            enable = 0,
        })))
        return
    end
    self:setFilter(filter.newFilter("CUSTOM", json.encode({
        frag = "shaders/mask.fs",
        shaderName = "mask2",
        rect = {
            clamp(0, display.width, rect.x) / display.width,
            1 - clamp(0, display.height, rect.y + rect.height) / display.height,
            clamp(0, display.width, rect.width) / display.width,
            clamp(0, display.height, rect.height) / display.height,
        },
        enable = 1,
    })))
end

return WidgetMaskFilter

