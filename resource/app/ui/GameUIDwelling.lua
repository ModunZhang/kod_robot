--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
-- local ResourceManager = import("..entity.ResourceManager")
local GameUIResource = import(".GameUIResource")
local WidgetCitizen = import("..widget.WidgetCitizen")
local GameUIDwelling = class("GameUIDwelling", GameUIResource)

function GameUIDwelling:ctor(building, city,default_tab)
    GameUIDwelling.super.ctor(self, building,default_tab)
    self.dwelling_city = city
    return true
end

function GameUIDwelling:CreateUI()
    self:createTabButtons()
end
function GameUIDwelling:OnMoveOutStage()
    GameUIDwelling.super.OnMoveOutStage(self)
end
function GameUIDwelling:CreateCitizenPanel()
    return WidgetCitizen.new(self.city):addTo(self:GetView())
end

function GameUIDwelling:createTabButtons()
    self:CreateTabButtons({
        {
            label = _("城民"),
            tag = "citizen",
        },
        {
            label = _("信息"),
            tag = "infomation",
        }
    },
    function(tag)
        if tag == 'infomation' then
            if self.citizen_panel then
                self.citizen_panel:removeFromParent()
                self.citizen_panel = nil
            end
            if not self.infomationLayer then
                self:CreateInfomation()
            end
            self:RefreshListView()
        elseif tag == "citizen" then
            if self.infomationLayer then
                self.infomationLayer:removeFromParent()
                self.infomationLayer = nil
            end
            if not self.citizen_panel then
                self.citizen_panel = self:CreateCitizenPanel()
            end
            self.citizen_panel:UpdateData()
        else
            if self.infomationLayer then
                self.infomationLayer:removeFromParent()
                self.infomationLayer = nil
            end
            if self.citizen_panel then
                self.citizen_panel:removeFromParent()
                self.citizen_panel = nil
            end
        end
    end):pos(window.cx, window.bottom + 34)
end

return GameUIDwelling













