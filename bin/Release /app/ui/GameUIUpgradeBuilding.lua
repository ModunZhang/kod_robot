local GameUIWithCommonHeader = import('.GameUIWithCommonHeader')
local CommonUpgradeUI = import('.CommonUpgradeUI')
local GameUIUpgradeBuilding = class('GameUIUpgradeBuilding', GameUIWithCommonHeader)

function GameUIUpgradeBuilding:ctor(city, title , building, default_tab)
    GameUIUpgradeBuilding.super.ctor(self,city, title)
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
    self.tabs = GameUIUpgradeBuilding.super.CreateTabButtons(self,param,function(tag)
        if tag == "upgrade" then
            if not self.upgrade_layer then
                self.upgrade_layer = CommonUpgradeUI.new(self.city, self.building):addTo(self:GetView())
            end
            self.upgrade_layer:setVisible(true)
        else
            if self.upgrade_layer then
                self.upgrade_layer:setVisible(false)
            end
        end
        cb(tag)
    end)
    return self.tabs
end

function GameUIUpgradeBuilding:GetBuilding()
    return self.building
end



--
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIUpgradeBuilding:Find()
    return self.upgrade_layer.upgrade_btn
end
function GameUIUpgradeBuilding:PromiseOfFte()
    self.tabs:SelectTab("upgrade")
    self.upgrade_layer.acc_layer.acc_button:setButtonEnabled(false)
    self.upgrade_layer.OnBuildingUpgradingBegin = function() end
    self:GetFteLayer():SetTouchObject(self:Find())


    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        self.upgrade_layer.acc_layer.acc_button:setButtonEnabled(false)
        self:Find():setButtonEnabled(false)
        if self.building:IsHouse() then
            local tile = self.building:BelongCity():GetTileWhichBuildingBelongs(self.building)
            mockData.UpgradeHouseTo(tile.location_id, tile:GetBuildingLocation(self.building),
                self.building:GetType(), self.building:GetNextLevel())
        else
            mockData.UpgradeBuildingTo(self.building:GetType(), self.building:GetNextLevel())
        end

        self:LeftButtonClicked()
        self.upgrade_layer.acc_layer.acc_button:setButtonEnabled(false)
    end)

    local r = self:Find():getCascadeBoundingBox()
    self:GetFteLayer().arrow = WidgetFteArrow.new(_("点击升级"))
        :addTo(self:GetFteLayer()):TurnDown():align(display.BOTTOM_CENTER, r.x + r.width/2, r.y + r.height + 10)

    return self.building:BelongCity():PromiseOfUpgradingByLevel(self:GetBuilding():GetType())
end

return GameUIUpgradeBuilding




