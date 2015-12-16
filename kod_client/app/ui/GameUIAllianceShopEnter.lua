--
-- Author: Danny He
-- Date: 2014-12-29 16:10:25
--
local UILib = import(".UILib")
local GameUIAllianceShopEnter = UIKit:createUIClass("GameUIAllianceShopEnter","GameUIAllianceShrineEnter")
local Localize = import("..utils.Localize")

function GameUIAllianceShopEnter:GetUIHeight()
    return 261
end

function GameUIAllianceShopEnter:GetUITitle()
    return _("商店")
end

function GameUIAllianceShopEnter:GetBuildingImage()
    return self.isMyAlliance and UILib.alliance_building.shop or UILib.other_alliance_building.shop
end

function GameUIAllianceShopEnter:GetBuildingType()
    return 'shop'
end

function GameUIAllianceShopEnter:GetBuildingDesc()
    return Localize.building_description.shop
end


function GameUIAllianceShopEnter:GetBuildingInfo()
    if self:IsMyAlliance() then
        local location = {
            {_("坐标"),0x615b44},
            {self:GetLocation(),0x403c2f},
        }
        local label_2 = {
            {_("高级道具数量"),0x615b44},
            {"50",0x403c2f},
        }

        if Alliance_Manager:GetMyAlliance().isNewGoodsCome then
            local label_3 =
                {
                    {_("有新的货物补充"),0x007c23}
                }
            return {location,label_2,label_3}
        end
        return {location,label_2}
    else
        local location = {
            {_("坐标"),0x615b44},
            {self:GetLocation(),0x403c2f},
        }
        local label_2 = {
            {_("高级道具数量"),0x615b44},
            {_("未知"),0x403c2f},
        }
        return {location,label_2}
    end
end

function GameUIAllianceShopEnter:GetNormalButton()
    local info_button = self:BuildOneButton("icon_info_56x56.png",_("商店记录")):onButtonClicked(function()
            UIKit:newGameUI('GameUIAllianceShop',City,"record",self:GetBuilding()):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
    local stock_button = self:BuildOneButton("icon_stock.png",_("进货")):onButtonClicked(function()
        UIKit:newGameUI('GameUIAllianceShop',City,"stock",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    local tax_button = self:BuildOneButton("icon_buy_goods_72x60.png",_("购买商品")):onButtonClicked(function()
        UIKit:newGameUI('GameUIAllianceShop',City,"goods",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    local upgrade_button = self:BuildOneButton("icon_upgrade_1.png",_("升级")):onButtonClicked(function()
        UIKit:newGameUI('GameUIAllianceShop',City,"upgrade",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    return {info_button,stock_button,tax_button,upgrade_button}
end

return GameUIAllianceShopEnter


