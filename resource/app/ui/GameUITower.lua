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
    self.city:GetUser():AddListenOnType(self, "buildings")
    self.city:GetUser():AddListenOnType(self, "buildingEvents")
end
function GameUITower:onExit()
    self.city:GetUser():RemoveListenerOnType(self, "buildings")
    self.city:GetUser():RemoveListenerOnType(self, "buildingEvents")
    GameUITower.super.onExit(self)
end
function GameUITower:OnUserDataChanged_buildingEvents()
    self.infos:CreateInfoItems(self:GetInfos())
end
function GameUITower:OnUserDataChanged_buildings()
    self.infos:CreateInfoItems(self:GetInfos())
end
function GameUITower:CreateBetweenBgAndTitle()
    GameUITower.super.CreateBetweenBgAndTitle(self)

    -- 加入城堡info_layer
    self.info_layer = display.newLayer():addTo(self:GetView())
end
function GameUITower:GetInfos()

    local config = UtilsForBuilding:GetFunctionConfigBy(self.city:GetUser(), "tower")
    local atkinfs,atkarcs,atkcavs,atkcats,defencePower = config.infantry, config.archer, config.cavalry, config.siege, config.defencePower
    local current_wall_hp = User:GetResValueByType("wallHp")
    local eff = self.city:GetUser():GetProductionTechEff(8) -- 高级箭塔科技buff
    return {
        {
            _("对步兵攻击"),
            string.formatnumberthousands(current_wall_hp * atkinfs),
            math.floor(atkinfs * (1 + eff)) > atkinfs and {"+".. string.formatnumberthousands(math.floor(atkinfs * (1 + eff)) * current_wall_hp - current_wall_hp * atkinfs),0x068329}
        },
        {
            _("对骑兵攻击"),
            string.formatnumberthousands(current_wall_hp * atkcavs),
            math.floor(atkcavs * (1 + eff)) > atkcavs and {"+".. string.formatnumberthousands(math.floor(atkcavs * (1 + eff)) * current_wall_hp - current_wall_hp * atkcavs),0x068329}
        },
        {
            _("对弓箭手攻击"),
            string.formatnumberthousands(current_wall_hp * atkarcs),
            math.floor(atkarcs * (1 + eff)) > atkarcs and {"+".. string.formatnumberthousands(math.floor(atkarcs * (1 + eff)) * current_wall_hp - current_wall_hp * atkarcs),0x068329}
        },
        {
            _("对投石车攻击"),
            string.formatnumberthousands(current_wall_hp * atkcats),
            math.floor(atkcats * (1 + eff)) > atkcats and {"+".. string.formatnumberthousands(math.floor(atkcats * (1 + eff)) * current_wall_hp - current_wall_hp * atkcats),0x068329}
        },
        {
            _("防御力"),
            string.formatnumberthousands(current_wall_hp * defencePower),
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





