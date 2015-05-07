local GameUIWithCommonHeader = import('.GameUIWithCommonHeader')
local CommonUpgradeUI = import('.CommonUpgradeUI')
local GameUIUpgradeBuilding = class('GameUIUpgradeBuilding', GameUIWithCommonHeader)

function GameUIUpgradeBuilding:ctor(city, title , building, default_tab)
    GameUIUpgradeBuilding.super.ctor(self,city, title)
    self.upgrade_city = city
    self.default_tab = default_tab
    self.building = building
    app:GetAudioManager():PlayBuildingEffectByType(building:GetType())
end

function GameUIUpgradeBuilding:CreateTabButtons(param, cb)
    local is_default_upgrade = false
    if not self.default_tab or self.default_tab== "upgrade" then
        is_default_upgrade = true
    end
    table.insert(param,1, {
        label = _("升级"),
        tag = "upgrade",
        default = is_default_upgrade,
    })
    for i,v in ipairs(param) do
        if v.tag == self.default_tab then
            v.default = true
        end
    end
    return GameUIUpgradeBuilding.super.CreateTabButtons(self,param,function(tag)
        if tag == "upgrade" then
            if not self.upgrade_layer then
                self.upgrade_layer = CommonUpgradeUI.new(self.upgrade_city, self.building):addTo(self:GetView())
            end
            self.upgrade_layer:setVisible(true)
        else
            if self.upgrade_layer then
                self.upgrade_layer:setVisible(false)
            end
        end
        cb(tag)
    end)
end

function GameUIUpgradeBuilding:GetBuilding()
    return self.building
end

return GameUIUpgradeBuilding



