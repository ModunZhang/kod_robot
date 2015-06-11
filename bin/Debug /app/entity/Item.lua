--
-- Author: Kenny Dai
-- Date: 2015-01-22 12:07:37
--
local ITEMS = GameDatas.Items
local BUFF = ITEMS.buff
local RESOURCE = ITEMS.resource
local SPECIAL = ITEMS.special
local SPEEDUP = ITEMS.speedup
local Enum = import("..utils.Enum")
local Localize_item = import("..utils.Localize_item")

local Item = class("Item")
local property = import("..utils.property")
Item.CATEGORY = Enum("BUFF",
    "RESOURCE",
    "SPECIAL",
    "SPEEDUP")



local function get_config(name)
    if BUFF[name] then
        return BUFF[name]
    elseif RESOURCE[name] then
        return RESOURCE[name]
    elseif SPECIAL[name] then
        return SPECIAL[name]
    elseif SPEEDUP[name] then
        return SPEEDUP[name]
    end
end

local function get_category(name)
    if BUFF[name] then
        return Item.CATEGORY.BUFF
    elseif RESOURCE[name] then
        return Item.CATEGORY.RESOURCE
    elseif SPECIAL[name] then
        return Item.CATEGORY.SPECIAL
    elseif SPEEDUP[name] then
        return Item.CATEGORY.SPEEDUP
    end
end
property(Item,"name","")
property(Item,"category","")
property(Item,"buffType","")
property(Item,"count",0)
property(Item,"effect",0)
property(Item,"order",0)
property(Item,"isSell",false)
property(Item,"price",0)
property(Item,"sellPriceInAlliance",0)
property(Item,"buyPriceInAlliance",0)
property(Item,"isAdvancedItem",false)

function Item:UpdateData(json_data)
    local name = json_data.name
    self:SetName(name)
    self:SetCount(tonumber(json_data.count))
    local config = get_config(name)
    local category = get_category(name)
    self:SetCategory(category)
    self:SetEffect(config.effect)
    self:SetOrder(config.order)
    self:SetIsSell(config.isSell)
    self:SetPrice(config.price)
    self:SetSellPriceInAlliance(config.sellPriceInAlliance)
    self:SetBuyPriceInAlliance(config.buyPriceInAlliance)
    self:SetIsAdvancedItem(config.isAdvancedItem)
    if category == Item.CATEGORY.BUFF then
        self:SetBuffType(config.type)
    end
end
function Item:GetLocalizeName()
    return Localize_item.item_name[self.name]
end
function Item:GetLocalizeDesc()
    return Localize_item.item_desc[self.name]
end
function Item:OnPropertyChange()
end

return Item



