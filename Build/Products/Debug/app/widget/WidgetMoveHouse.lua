--
-- Author: Kenny Dai
-- Date: 2015-02-02 16:19:41
--
local SpriteConfig = import("..sprites.SpriteConfig")

local WidgetMoveHouse = class("WidgetMoveHouse",function ( )
    return display.newSprite("back_ground_256x207.png")
end)

WidgetMoveHouse.ADD_TAG =989

function WidgetMoveHouse:ctor(house)
    local running_scene = display.getRunningScene()
    if running_scene.__cname == "MyCityScene" then
        running_scene:EnterEditMode()
        self.house = house
        self.scene_layer = running_scene:GetSceneLayer()
        running_scene:GetSceneUILayer():addChild(self, 1, WidgetMoveHouse.ADD_TAG)
        local ok_btn = cc.ui.UIPushButton.new(
            {normal = "green_btn_up_58x58.png", pressed = "green_btn_down_58x58.png"}
        )
            :addTo(self):pos(224,108)
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    local from_house_tile = City:GetTileWhichBuildingBelongs(house)
                    local _fromBuildingLocation = from_house_tile.location_id
                    local _fromHouseLocation = from_house_tile:GetBuildingLocation(house)
                    local to_house_tile = City:GetTileWhichBuildingBelongs(self.move_to_ruins:GetEntity())
                    local _toBuildingLocation = to_house_tile.location_id
                    local _toHouseLocation = to_house_tile:GetBuildingLocation(self.move_to_ruins:GetEntity())
                    NetManager:getUseItemPromise("movingConstruction",{
                        movingConstruction = {
                            fromBuildingLocation = _fromBuildingLocation,
                            fromHouseLocation = _fromHouseLocation,
                            toBuildingLocation = _toBuildingLocation,
                            toHouseLocation = _toHouseLocation,
                        }
                    }):always(function()
                        running_scene:LeaveEditMode()
                    end)
                end
            end)
        display.newSprite("icon_v_37x30.png"):addTo(ok_btn)
        local cancel_btn = cc.ui.UIPushButton.new(
            {normal = "red_btn_up_58x58.png", pressed = "red_btn_down_58x58.png"}
        )
            :addTo(self):pos(30,108)
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    running_scene:LeaveEditMode()
                end
            end)
        display.newSprite("icon_x_25x23.png"):addTo(cancel_btn)
        -- 小屋图片
        local build_png = SpriteConfig[house:GetType()]:GetConfigByLevel(house:GetLevel()).png
        local building_image = display.newSprite(build_png, 0, 0)
            :addTo(self):pos(self:getContentSize().width/2,self:getContentSize().height/2+20)
        building_image:setOpacity(180)
        building_image:scale(self.scene_layer:getScale())
        self.building_image = building_image
    end
    self:hide()
end
function WidgetMoveHouse:SetMoveToRuins( ruins )
    if ruins:GetEntity() == self.house then
        return
    end
    self.move_to_ruins=ruins

    self:show()

    local world_pos = ruins:GetWorldPosition()
    self:setPosition(world_pos.x, world_pos.y)
end
function WidgetMoveHouse:GetRuins( )
    return self.move_to_ruins
end
return WidgetMoveHouse






