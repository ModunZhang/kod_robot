local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    self.ui = UIKit:newGameUI('GameUILoginBeta')
    -- showMemoryUsage()
    -- local count = 1
    -- for k,v in pairs(plist_texture_data_sd) do
    -- 	display.newSprite(k):addTo(self):pos(display.cx, display.cy)
    -- 	count = count + 1
    -- 	if count > 40 then
    -- 		break
    -- 	end
    -- end
    
end

function MainScene:onEnter()
    self.ui:AddToScene(self,false)
end

function MainScene:onExit()
    self.ui:removeFromParent()
end
return MainScene
