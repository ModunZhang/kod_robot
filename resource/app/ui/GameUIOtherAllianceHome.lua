--
-- Author: Danny He
-- Date: 2014-11-21 09:57:42
--
local GameUIOtherAllianceHome = UIKit:createUIClass("GameUIOtherAllianceHome", "GameUIAllianceHome")
local WidgetPushButton = import("..widget.WidgetPushButton")
local window = import("..utils.window")
local Alliance = import("..entity.Alliance")
local WidgetChangeMap = import("..widget.WidgetChangeMap")


function GameUIOtherAllianceHome:OnSceneMove(logic_x, logic_y, alliance_view)
    local coordinate_str = string.format("%d, %d", logic_x, logic_y)
    local is_mine
    if alliance_view then
        is_mine = alliance_view:GetAlliance().id == self.alliance.id and "["..self.alliance.basicInfo.tag.."]" or "["..Alliance_Manager:GetEnemyAlliance().basicInfo.tag.."]"
    else
        is_mine = _("坐标")
    end
    self.coordinate_label:setString(coordinate_str)
    self.coordinate_title_label:setString(is_mine)
end
function GameUIOtherAllianceHome:TopBg()
    local top_bg = display.newSprite("alliance_home_top_bg_768x116.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    if display.width >640 then
        top_bg:scale(display.width/768)
    end
    top_bg:setTouchEnabled(true)
    local t_size = top_bg:getContentSize()
    self.top_bg = top_bg
    -- 顶部背景,为按钮
    local top_self_bg = WidgetPushButton.new({normal = "button_blue_normal_314X88.png",
        pressed = "button_blue_normal_314X88.png"})
        :align(display.TOP_CENTER, t_size.width/2-160, t_size.height-4)
        :addTo(top_bg)
    top_self_bg:setTouchEnabled(true)
    top_self_bg:setTouchSwallowEnabled(true)
    local top_enemy_bg = WidgetPushButton.new({normal = "button_red_normal_314X88.png",
        pressed = "button_red_normal_314X88.png"})
        :align(display.TOP_CENTER, t_size.width/2+160, t_size.height-4)
        :addTo(top_bg)
    top_enemy_bg:setTouchEnabled(true)
    top_enemy_bg:setTouchSwallowEnabled(true)

    return top_self_bg,top_enemy_bg
end

function GameUIOtherAllianceHome:TopTabButtons()
    -- 坐标按钮
    local coordinate_btn = WidgetPushButton.new({normal = "btn_100x52.png",
        pressed = "btn_100x52.png"})
        :onButtonClicked(function ( event )
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI('GameUIAlliancePosition'):AddToCurrentScene(true)
            end
        end)
        :align(display.TOP_CENTER, window.cx,window.top-94)
        :addTo(self)
    -- 坐标
   local size = coordinate_btn:getCascadeBoundingBox().size
    self.coordinate_title_label = UIKit:ttfLabel(
        {
            text = _("坐标"),
            size = 14,
            color = 0xbdb582
        }):align(display.CENTER, 0,  -size.height/2+10)
        :addTo(coordinate_btn)
    self.coordinate_label = UIKit:ttfLabel(
        {
            text = "23,21",
            size = 18,
            color = 0xf5e8c4
        }):align(display.CENTER,0, -size.height/2-10)
        :addTo(coordinate_btn)

end

function GameUIOtherAllianceHome:CreateOperationButton()
    local first_row = 220
    local first_col = 177
    local label_padding = 100
    for i, v in ipairs({
        {"help_64x72.png", _("帮助")},
        {"fight_62x70.png", _("战斗")},
    }) do
        local col = i - 1
        local y =  first_row + col*label_padding
        local button = WidgetPushButton.new({normal = v[1]})
            :onButtonClicked(handler(self, self.OnMidButtonClicked))
            :setButtonLabel("normal",cc.ui.UILabel.new({text = v[2],
                size = 16,
                font = UIKit:getFontFilePath(),
                color = UIKit:hex2c3b(0xf5e8c4)}
            )
            )
            :setButtonLabelOffset(0, -40)
            :addTo(self):pos(window.right-50, y)
        button:setTag(i)
        button:setTouchSwallowEnabled(true)
    end
end

function GameUIOtherAllianceHome:AddMapChangeButton()
    local map_node = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OTHER_ALLIANCE):addTo(self)
end

return GameUIOtherAllianceHome




