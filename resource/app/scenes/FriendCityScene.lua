local GameUIWatchTowerTroopDetail = import("..ui.GameUIWatchTowerTroopDetail")
local CityScene = import(".CityScene")
local FriendCityScene = class("FriendCityScene", CityScene)
function FriendCityScene:ctor(user, city)
    FriendCityScene.super.ctor(self, city)
    self.user = user
    self.city = city
end
function FriendCityScene:onEnter()
    FriendCityScene.super.onEnter(self)
    UIKit:newGameUI('GameUICityInfo', self.user):AddToScene(self):setTouchSwallowEnabled(false)
end

function FriendCityScene:OnTouchClicked(pre_x, pre_y, x, y)
	local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        if iskindof(building, "HelpedTroopsSprite") then
            local type_ = GameUIWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE
            local helped = self.city:GetHelpedByTroops()[building:GetIndex()]
            UIKit:newGameUI("GameUIWatchTowerTroopDetail", type_, helped, self.user:Id()):AddToCurrentScene(true)
        end
    end
end

return FriendCityScene
