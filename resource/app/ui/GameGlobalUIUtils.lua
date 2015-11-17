--
-- Author: Danny He
-- Date: 2014-09-10 21:05:17
--
import('app.utils.Minheap')
local Localize = import("..utils.Localize")
local GameGlobalUIUtils = class('GameGlobalUIUtils')
local GameUICommonTips = import(".GameUICommonTips")
local GameUISystemNotice = import(".GameUISystemNotice")

function GameGlobalUIUtils:ctor()
    self.tipsHeap = Minheap.new(function(a,b)
        return a.time < b.time
    end)
    self.increase_index = 0

    self.noticeHeap = Minheap.new(function(a,b)
        return a.time < b.time
    end)
    self.increase_notic_index = 0
    self.enable_tips = true
end

function GameGlobalUIUtils:showTips(title,content,autoCloseTime)
    if self.enable_tips then
        local instance = cc.Director:getInstance():getRunningScene():getChildByTag(1020)
        if not instance then
            self.commonTips = GameUICommonTips.new(self,2)
            assert(self.commonTips)
            cc.Director:getInstance():getRunningScene():addChild(self.commonTips, 1000000, 1020)
            -- self.commonTips:setVisible(false)
        end
        self.commonTips:SetAutoCloseTime(autoCloseTime or 2)
        if self.commonTips:IsOpen() then
            self.increase_index = self.increase_index + 1
            self.tipsHeap:push({title=title,content = content,time = self.increase_index})
        else
            self.increase_index = 0
            self.commonTips:showTips(title,content)
        end
    end
end
function GameGlobalUIUtils:DisableTips()
    self.enable_tips = false
end
function GameGlobalUIUtils:EnableTips()
    self.enable_tips = true
end
function GameGlobalUIUtils:showNotice(notice_type,notice_content)
    local instance = cc.Director:getInstance():getRunningScene():getChildByTag(1030)
    if not instance then
        self.notice = GameUISystemNotice.new(self,notice_type,notice_content)
        assert(self.notice)
        cc.Director:getInstance():getRunningScene():addChild(self.notice, 1000001, 1030)
    end
    if self.notice:IsOpen() then
        self.increase_notic_index = self.increase_notic_index + 1
        self.noticeHeap:push({type = notice_type,content = notice_content,time = self.increase_notic_index})
    else
        self.increase_notic_index = 0
        self.notice:showNotice(notice_type,notice_content)
    end

end
local monsters = GameDatas.AllianceInitData.monsters
function GameGlobalUIUtils:showAllianceNotice(key,params)
    local notice_content = Localize.alliance_notice[key]
    if key == "attackVillage" then
        notice_content = string.format(notice_content,params[1],params[3],Localize.village_name[params[4]])
    elseif key == "attackMonster" then
        local corps = string.split(monsters[params[2]].soldiers, ";")
        local soldiers = string.split(corps[params[3] + 1], ",")
        local monster = Localize.soldier_name[string.split(soldiers[1], "_")[1]]
        notice_content = string.format(notice_content,params[1],params[2],monster)
    elseif key == "strikePlayer" then
        notice_content = string.format(notice_content,params[1],params[2])
    elseif key == "attackPlayer" then
        notice_content = string.format(notice_content,params[1],params[2])
    elseif key == "helpDefence" then
        notice_content = string.format(notice_content,params[1],params[2])
    end
    self:showNotice("info",notice_content)
end

function GameGlobalUIUtils:onTipsMoveOut(tipsUI)
    if not self.tipsHeap:empty() then
        local message = self.tipsHeap:pop()
        tipsUI:showTips(message.title,message.content)
        return true
    end
    return false
end
function GameGlobalUIUtils:onNoticeMoveOut(noticeUI)
    if not self.noticeHeap:empty() then
        local message = self.noticeHeap:pop()
        noticeUI:showNotice(message.type,message.content)
        return true
    end
    return false
end

function GameGlobalUIUtils:showMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button)
    return UIKit:showMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button)
end

function GameGlobalUIUtils:showBuildingLevelUp(msg)
    local buildingName = Localize.getBuildingLocalizedKeyByBuildingType(msg.buildingType)
    self:showTips(_("建筑升级完成"),string.format('%s(LV %d)',_(buildingName),msg.level))
end

function GameGlobalUIUtils:showWallLevelUp(msg)
    local buildingName = Localize.getBuildingLocalizedKeyByBuildingType(msg.buildingType)
    self:showTips(_("建筑升级完成"),string.format('%s(LV %d)',_(buildingName),msg.level))
end

function GameGlobalUIUtils:showHouseLevelUp(msg)
    local houseName = Localize.getHouseLocalizedKeyByBuildingType(msg.houseType)
    self:showTips(_("小屋升级完成"),string.format('%s(LV %d)',_(houseName),msg.level))
end


function GameGlobalUIUtils:clearMessageQueue()
    if self.tipsHeap then self.tipsHeap:clear() end
end
GameGlobalUI = GameGlobalUIUtils.new()

