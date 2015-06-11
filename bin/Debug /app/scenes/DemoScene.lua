local window = import("..utils.window")
local DemoLayer = import("..layers.DemoLayer")
local MapScene = import(".MapScene")
local DemoScene = class("DemoScene", MapScene)

function DemoScene:ctor()
    DemoScene.super.ctor(self)
end
function DemoScene:onEnter()
    DemoScene.super.onEnter(self)
    -- self.touch_layer:removeFromParent()
    -- self.touch_layer = nil
end
function DemoScene:CreateSceneLayer()
    return DemoLayer.new():addTo(self):ZoomTo(1)
end
return DemoScene



