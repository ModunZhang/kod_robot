local Sprite = import("..sprites.Sprite")
local CityScene = import(".CityScene")
local GameUIAllianceWatchTowerTroopDetail = import("..ui.GameUIAllianceWatchTowerTroopDetail")
local OtherCityScene = class("OtherCityScene", CityScene)
function OtherCityScene:ctor(user, city, location)
    OtherCityScene.super.ctor(self, city)
    self.user = user
    self.city = city
    self.location = location
end
function OtherCityScene:onEnter()
    OtherCityScene.super.onEnter(self)
    self.home = UIKit:newGameUI('GameUICityInfo', self.user, self.location):AddToScene(self):setTouchSwallowEnabled(false)

    if not self.location.canShowBuildingLevel then
        self:GetSceneLayer():HideLevelUpNode()
    end

    for k,v in pairs(self:GetSceneLayer().soldiers) do
        v:hide()
    end
    for k,v in pairs(self:GetSceneLayer().buildings) do
        if v:GetEntity():GetType() == "dragonEyrie" then
            v:ReloadSpriteCaseDragonDefencedChanged(nil)
        end
    end
end
function OtherCityScene:GetHomePage()
    return self.home
end
--不处理任何场景建筑事件
function OtherCityScene:OnTouchClicked(pre_x, pre_y, x, y)
	local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true);self:performWithDelay(function()app:lockInput()end,0.3)
         Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building))):next(function()
            if iskindof(building, "HelpedTroopsSprite") then
                local User = self.city:GetUser()
                NetManager:getHelpDefenceTroopDetailPromise(User._id):done(function(response)
                     UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.troopDetail,Alliance_Manager:GetMyAlliance():GetAllianceBuildingInfoByName("watchTower").level,true,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.MARCH,true)
                                :AddToCurrentScene(true)
                end)
            end
        end)
    end
end

return OtherCityScene
