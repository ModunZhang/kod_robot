--
-- Author: Danny He
-- Date: 2014-10-24 11:41:10
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameAllianceApproval = class("GameAllianceApproval", WidgetPopDialog)
local window = import("..utils.window")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
--异步列表按钮事件修复
function GameAllianceApproval:ctor()
    GameAllianceApproval.super.ctor(self,754,_("申请审批"),window.top_bottom)
end


function GameAllianceApproval:onEnter()
    GameAllianceApproval.super.onEnter(self)
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,568,687),
        direction = UIScrollView.DIRECTION_VERTICAL,
        async = true
    })
    list:setDelegate(handler(self, self.sourceDelegate))
    list_node:addTo(self:GetBody()):pos(20,30)
    self.listView = list

    if Alliance_Manager:GetMyAlliance():JoinRequestEvents() == nil then
        NetManager:getJoinRequestEventsPromise(
            Alliance_Manager:GetMyAlliance():Id()
        ):done(function()
            self:RefreshListView()
        end)
    else
        self:RefreshListView()
    end
end

function GameAllianceApproval:RefreshListView()
    self.dataSource_ = Alliance_Manager:GetMyAlliance():JoinRequestEvents()
    self.listView:reload()
end

function GameAllianceApproval:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.dataSource_
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.dataSource_[idx]
        item = self.listView:dequeueItem()
        if not item then
            item = self.listView:newItem()
            content = self:GetListItemContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:RefreshListItemContent(content,data,idx)
        item:setItemSize(568,152)
        return item
    else
    end
end


function GameAllianceApproval:OnPlayerDetailButtonClicked(idx)
    local player = self.dataSource_[idx]
    if player then
        UIKit:newGameUI('GameUIAllianceMemberInfo',false,player.id,function()end):AddToCurrentScene(true)
    end
end

function GameAllianceApproval:RefreshListItemContent(content,player,idx)
    content.idx = idx
    content.name_label:setString(player.name or " ")
    content.power_label:setString(string.formatnumberthousands(player.power))
    content.player_icon.icon:setTexture(UIKit:GetPlayerIconImage(player.icon))
    if content.rejectButton then
        content.rejectButton:removeSelf()
        content.argreeButton:removeSelf()
    end
    content.rejectButton = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"}):setButtonLabel(UIKit:commonButtonLable({
                color = 0xfff3c7,
                text  = _("拒绝")
        })):align(display.LEFT_TOP,141, 73):onButtonClicked(function(event)
            self:OnRefuseButtonClicked(content.idx)
        end):addTo(content)
    content.argreeButton = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}):setButtonLabel(UIKit:commonButtonLable({
                text = _("同意"),
                color = 0xfff3c7
        })):align(display.LEFT_TOP,401,73):onButtonClicked(function(event)
            self:OnAgreeButtonClicked(content.idx)
        end):addTo(content)
end

function GameAllianceApproval:GetListItemContent()
    local content = WidgetUIBackGround.new({width = 568,height = 152},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local icon_box = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_BOTTOM, 10,15):addTo(content)
    local player_icon = self:GetPlayerIconSprite():addTo(icon_box):pos(63,63)
    WidgetPushTransparentButton.new(cc.rect(0,0,126,126))
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(icon_box)
        :onButtonClicked(function()
            self:OnPlayerDetailButtonClicked(content.idx)
        end)
    local line = display.newScale9Sprite("dividing_line.png")
        :align(display.LEFT_CENTER,icon_box:getPositionX()+icon_box:getContentSize().width + 5,icon_box:getPositionY() + icon_box:getContentSize().height/2)
        :addTo(content)
        :size(416,2)
    local name_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_BOTTOM,line:getPositionX(),line:getPositionY() + 20):addTo(content)
    local power_icon = display.newSprite("dragon_strength_27x31.png")
        :align(display.LEFT_BOTTOM, line:getPositionX() + 260,line:getPositionY() + 20)
        :addTo(content)
    local power_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM,power_icon:getPositionX()+power_icon:getContentSize().width + 2,power_icon:getPositionY()):addTo(content)

   
    content.player_icon = player_icon
    content.name_label = name_label
    content.power_label = power_label
    return content
end


function GameAllianceApproval:GetPlayerIconSprite()
    local bg = display.newSprite("chat_hero_background.png", nil, nil, {class=cc.FilteredSpriteWithOne})
    local icon = display.newSprite(UIKit:GetPlayerIconImage(1), nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(bg):align(display.CENTER,56,65)
    bg.icon = icon
    return bg
end

function GameAllianceApproval:OnRefuseButtonClicked(idx)
    local player = self.dataSource_[idx]
    if player then
        NetManager:getRemoveJoinAllianceReqeustsPromise({player.id}):done(function(result)
            self:RefreshListView()
        end)
    end
end

function GameAllianceApproval:OnAgreeButtonClicked(idx)
    local player = self.dataSource_[idx]
    if player then
        NetManager:getApproveJoinAllianceRequestPromise(player.id):done(function(result)
            self:RefreshListView()
        end):fail(function(msg)
            local code = msg.errcode and msg.errcode[1].code or nil
            if code then
                if UIKit:getErrorCodeKey(code) == 'playerCancelTheJoinRequestToTheAlliance' then
                    self:OnRefuseButtonClicked(player.id)
                end
            end
        end)
    end
end

return GameAllianceApproval