local Enum = import("..utils.Enum")

local WidgetPushButton = import(".WidgetPushButton")

local window = import("..utils.window")



local WidgetChangeMap = class("WidgetChangeMap", function ()
    local layer = display.newLayer()
    layer:setNodeEventEnabled(true)
    layer:setTouchSwallowEnabled(false)
    return layer
end)
WidgetChangeMap.MAP_TYPE = Enum("OUR_CITY", "OTHER_CITY", "OUR_ALLIANCE", "OTHER_ALLIANCE", "PVE")

function WidgetChangeMap:ctor(map_type, location)
    -- 设置位置位移参数
    local scale_x = 1
    if display.width >640 then
        scale_x = display.width/768
    end
    self.scale_x = scale_x
    local btn = WidgetPushButton.new(
        {normal = "map_bg_100X100.png", pressed = "map_bg_100X100.png"}
    ):addTo(self)
        :align(display.LEFT_CENTER,window.cx-320*scale_x, 50*scale_x)
        :onButtonClicked(function(event)
            if map_type == WidgetChangeMap.MAP_TYPE.OUR_CITY then
                if Alliance_Manager:GetMyAlliance():IsDefault() then
                    UIKit:showMessageDialog(_("主人"),_("加入联盟后开放此功能!"))
                    return
                end
                app:EnterMyAllianceScene(location)
            elseif map_type == WidgetChangeMap.MAP_TYPE.OTHER_CITY then
                app:EnterMyAllianceSceneOrMyCityScene(location)
            elseif map_type == WidgetChangeMap.MAP_TYPE.OUR_ALLIANCE then
                app:EnterMyCityScene()
            elseif map_type == WidgetChangeMap.MAP_TYPE.OTHER_ALLIANCE then
                app:EnterMyAllianceScene(location)
            elseif map_type == WidgetChangeMap.MAP_TYPE.PVE then
                app:EnterMyCityScene()
            end

        end)
        :onButtonPressed(function(event)
            self.icon:runAction(cc.ScaleTo:create(0.1, 1.2))
        end):onButtonRelease(function(event)
        self.icon:runAction(cc.ScaleTo:create(0.1, 1))
        end)
        :scale(scale_x)
    local change_icon
    if map_type == WidgetChangeMap.MAP_TYPE.OUR_CITY then
        change_icon = "map_alliance_icon_81x98.png"
    elseif map_type == WidgetChangeMap.MAP_TYPE.OTHER_CITY then
        change_icon = "map_alliance_icon_81x98.png"
    elseif map_type == WidgetChangeMap.MAP_TYPE.OUR_ALLIANCE then
        change_icon = "map_city_81x102.png"
    elseif map_type == WidgetChangeMap.MAP_TYPE.OTHER_ALLIANCE then
        change_icon = "map_back_99x88.png"
    elseif map_type == WidgetChangeMap.MAP_TYPE.PVE then
        change_icon = "map_city_81x102.png"
    end
    self.icon = display.newSprite(change_icon):addTo(btn):align(display.CENTER, 50, 10)
    btn:setTouchSwallowEnabled(true)
    self.btn = btn
    self:AddShrineOpenedIcon()
end
function WidgetChangeMap:GetWorldRect()
    return self.btn:getCascadeBoundingBox()
end
function WidgetChangeMap:onEnter()
    local my_allaince = Alliance_Manager:GetMyAlliance()
    my_allaince:AddListenOnType(self, my_allaince.LISTEN_TYPE.BASIC)

end
function WidgetChangeMap:onExit()
    local my_allaince = Alliance_Manager:GetMyAlliance()
    my_allaince:RemoveListenerOnType(self, my_allaince.LISTEN_TYPE.BASIC)
end
function WidgetChangeMap:OnAllianceBasicChanged(alliance, changed_map)
    if Alliance_Manager:GetMyAlliance():IsDefault() then return end
    self:AddShrineOpenedIcon()
end

function WidgetChangeMap:AddShrineOpenedIcon()
    local alliance = Alliance_Manager:GetMyAlliance()
    if alliance:Status() == "fight" or alliance:Status() == "prepare"  then
        if not self.shrine_icon then
            local icon = display.newSprite("tmp_shrine_open_icon_96x96.png"):addTo(self)
                :align(display.LEFT_CENTER,window.cx-320 * self.scale_x, 50 * self.scale_x)
                :scale(self.scale_x)
            icon:setOpacity(122)
            icon:runAction(cc.RepeatForever:create(transition.sequence{
                cc.FadeTo:create(1.5, 255),
                cc.FadeTo:create(1.5, 122),
            }))
            self.shrine_icon = icon
        end
    else
        if self.shrine_icon then
            self.shrine_icon:hide()
        end
    end
end
return WidgetChangeMap




























