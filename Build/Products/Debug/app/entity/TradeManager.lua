--
-- Author: Kenny Dai
-- Date: 2015-01-13 17:05:03
--
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
local MultiObserver = import(".MultiObserver")
local TradeManager = class("TradeManager", MultiObserver)

TradeManager.LISTEN_TYPE = Enum("MY_DEAL_REFRESH","DEAL_CHANGED")

function TradeManager:ctor()
    TradeManager.super.ctor(self)
    self.my_deals = {}
end
function TradeManager:GetMyDeals()
    return self.my_deals
end
function TradeManager:GetSoldDealsCount()
    local count = 0
    for k,v in pairs(self.my_deals) do
        if v.isSold then
            count = count + 1
        end
    end
    return count
end
function TradeManager:OnUserDataChanged(user_data,deltaData)
    local is_fully_update = deltaData == nil
    if is_fully_update then
        local deals = user_data.deals
        if deals then
            self.my_deals = {}
            for k,v in pairs(deals) do
                table.insert(self.my_deals, v)
            end
            self:NotifyListeneOnType(TradeManager.LISTEN_TYPE.MY_DEAL_REFRESH, function(listener)
                listener:OnMyDealsRefresh()
            end)
        end
    end
    local is_delta_update = not is_fully_update and deltaData.deals ~= nil
    if is_delta_update then
        local __deals = deltaData.deals
        local add = {}
        local edit = {}
        local remove = {}
        if __deals then
            for k,v in pairs(__deals) do
                if k == "add" then
                    for _,deal in pairs(v) do
                        table.insert(self.my_deals, deal)
                        table.insert(add, deal)
                    end
                end
                if k == "edit" then
                    for k,deal in pairs(v) do
                        for index,myDeal in pairs(self.my_deals) do
                            if myDeal.id == deal.id then
                                self.my_deals[index] = deal
                                table.insert(edit,deal)
                            end
                        end
                    end
                end
                if k == "remove" then
                    for _,deal in pairs(v) do
                        for index,myDeal in pairs(self.my_deals) do
                            if myDeal.id == deal.id then
                                self.my_deals[index] = nil
                                table.insert(remove,deal)
                            end
                        end
                    end
                end
            end
            self:NotifyListeneOnType(TradeManager.LISTEN_TYPE.DEAL_CHANGED, function(listener)
                listener:OnDealChanged(
                    {
                        add=add,
                        edit=edit,
                        remove=remove,
                    }
                )
            end)
        end
    end

end

return TradeManager












