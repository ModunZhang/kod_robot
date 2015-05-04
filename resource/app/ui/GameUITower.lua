local Localize = import("..utils.Localize")
local window = import("..utils.window")
local WidgetInfoWithTitle = import("..widget.WidgetInfoWithTitle")


local GameUITower = UIKit:createUIClass('GameUITower',"GameUIUpgradeBuilding")
function GameUITower:ctor(city,building)
    local bn = Localize.building_name
    GameUITower.super.ctor(self,city,bn[building:GetType()],building)
end


function GameUITower:OnMoveInStage()
    GameUITower.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "info",
        }
    },
    function(tag)
        if tag == 'info' then
            self.info_layer:show()
        else
            self.info_layer:hide()
        end
    end):pos(window.cx, window.bottom + 34)

    self:InitInfo()
    self.building:AddUpgradeListener(self)
end
function GameUITower:onExit()
    self.building:RemoveUpgradeListener(self)
    GameUITower.super.onExit(self)
end



function GameUITower:OnBuildingUpgradingBegin()
end
function GameUITower:OnBuildingUpgradeFinished()
    self.infos:CreateInfoItems(self:GetInfos())
end
function GameUITower:OnBuildingUpgrading()
end
function GameUITower:CreateBetweenBgAndTitle()
    GameUITower.super.CreateBetweenBgAndTitle(self)

    -- 加入城堡info_layer
    self.info_layer = display.newLayer():addTo(self:GetView())
end
function GameUITower:GetInfos()
    local atkinfs,atkarcs,atkcavs,atkcats,defencePower = self.building:GetAtk()
    return {
        {
            _("对步兵攻击"),
            atkinfs,
        },
        {
            _("对骑兵攻击"),
            atkarcs,
        },
        {
            _("对弓箭手攻击"),
            atkarcs,
        },
        {
            _("对投石车攻击"),
            atkcats,
        },
        {
            _("防御力"),
            defencePower,
        },
    }
end
function GameUITower:InitInfo()
    
    self.infos = WidgetInfoWithTitle.new({
        info = self:GetInfos(),
        title = _("总计"),
        h = 266
        }):addTo(self.info_layer)
    :align(display.TOP_CENTER, window.cx, window.top-140)
end

return GameUITower



