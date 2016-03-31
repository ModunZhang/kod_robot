local Sprite = import("..sprites.Sprite")
local CityScene = import(".CityScene")
local FriendCityScene = class("FriendCityScene", CityScene)
function FriendCityScene:ctor(user, city, location)
    FriendCityScene.super.ctor(self, city)
    self.user = user
    self.city = city
    self.location = location
end
function FriendCityScene:onEnter()
    FriendCityScene.super.onEnter(self)
    self.home = UIKit:newGameUI('GameUICityInfo', self.user, self.location):AddToScene(self):setTouchSwallowEnabled(false)
end
function FriendCityScene:GetHomePage()
    return self.home
end

function FriendCityScene:OnTouchClicked(pre_x, pre_y, x, y)
    local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true);self:performWithDelay(function()app:lockInput()end,0.3)

        Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building))):next(function()
            if iskindof(building, "HelpedTroopsSprite") then
                local User = self.city:GetUser()
                local helped = User.helpedByTroop
                NetManager:getHelpDefenceTroopDetailPromise(User._id):done(function(response)
                    UIKit:newGameUI("GameUIHelpDefence",self.city, helped ,response.msg.troopDetail):AddToCurrentScene(true)
                end)
            end
        end)
    end
end

return FriendCityScene

