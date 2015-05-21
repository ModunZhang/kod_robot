local Sprite = import("..sprites.Sprite")
local CityScene = import(".CityScene")
local OtherCityScene = class("OtherCityScene", CityScene)
function OtherCityScene:ctor(user, city, location)
    OtherCityScene.super.ctor(self, city)
    self.user = user
    self.city = city
    self.location = location
end
function OtherCityScene:onEnter()
    OtherCityScene.super.onEnter(self)
    UIKit:newGameUI('GameUICityInfo', self.user, self.location):AddToScene(self):setTouchSwallowEnabled(false)
end
--不处理任何场景建筑事件
function OtherCityScene:OnTouchClicked(pre_x, pre_y, x, y)
	local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true);self:performWithDelay(function()app:lockInput()end,0.3)
        Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building)))
    end
end

return OtherCityScene
