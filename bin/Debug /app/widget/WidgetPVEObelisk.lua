local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVEObelisk = class("WidgetPVEObelisk", WidgetPVEDialog)

function WidgetPVEObelisk:ctor(...)
    WidgetPVEObelisk.super.ctor(self, ...)
end
function WidgetPVEObelisk:GetTitle()
    return string.format(_("方尖碑 等级%d"),self:GetPVEMap():GetIndex())
end
function WidgetPVEObelisk:GetDesc()
    return _("你发现一座用你从未见过的石头雕刻的石碑。你上前仔细观察一番, 石碑上突然闪现一个神秘的符文没入你的身体, 让你感觉身体中充满了力量。")
end
function WidgetPVEObelisk:SetUpButtons()
    return self:GetObject():IsSearched() and
        { { label = _("离开"), icon = "pve_icon_leave.png", } } or
        {
            {
                label = _("探索"), 
                icon = "icon_info_56x56.png",
                callback = function()
                    local rollback = self:Search()
                    self:GetRewardsFromServer():fail(function()
                        rollback()
                    end)
                    self:removeFromParent()
                end
            },
            { label = _("离开"), icon = "pve_icon_leave.png", }
        }
end

return WidgetPVEObelisk




















