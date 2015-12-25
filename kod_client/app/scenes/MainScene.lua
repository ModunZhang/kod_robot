local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    self.ui = UIKit:newGameUI('GameUILoginBeta')
    showMemoryUsage()
end

function MainScene:onEnter()
    self.ui:AddToScene(self,false)
end

function MainScene:onExit()
    self.ui:removeFromParent()
end
return MainScene
