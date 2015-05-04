local GameUIWatchTowerTroopDetail = import("..ui.GameUIWatchTowerTroopDetail")
local CityScene = import(".CityScene")
local OtherCityScene = class("OtherCityScene", CityScene)
function OtherCityScene:ctor(user, city)
    OtherCityScene.super.ctor(self, city)
    self.user = user
    self.city = city
end
function OtherCityScene:onEnter()
    OtherCityScene.super.onEnter(self)
    UIKit:newGameUI('GameUICityInfo', self.user):AddToScene(self):setTouchSwallowEnabled(false)
end
--不处理任何场景建筑事件
function OtherCityScene:OnTouchClicked(pre_x, pre_y, x, y)
end

return OtherCityScene
