--
-- Author: Danny He
-- Date: 2015-02-24 15:14:22
--
local GameUISettingServer = UIKit:createUIClass("GameUISettingServer","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local User = User
local config_fightRewards = GameDatas.AllianceInitData.fightRewards
local intInit = GameDatas.PlayerInitData.intInit
local Localize = import("..utils.Localize")
local UILib = import(".UILib")

function GameUISettingServer:onEnter()
    GameUISettingServer.super.onEnter(self)
    self.current_code = User.serverId
    self.server_code = self.current_code
    self.HIGH_COLOR = UIKit:hex2c3b(0x970000)
    self.LOW_COLOR = UIKit:hex2c3b(0x1d8a00)
    self:BuildUI()
end

function GameUISettingServer:BuildUI()
    local bg_height = 722
    local bg = WidgetUIBackGround.new({height= bg_height})
    self:addTouchAbleChild(bg)
    self.bg = bg
    bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
    local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,bg_height - 15):addTo(bg)
    local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
        :addTo(titleBar)
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    UIKit:ttfLabel({
        text = _("选择服务器"),
        size = 22,
        shadow = true,
        color = 0xffedae
    }):addTo(titleBar):align(display.CENTER,300,28)

    local couldChangeFree = City:GetFirstBuildingByType("keep"):GetLevel() < intInit.switchServerFreeKeepLevel.value
    local btn_images = couldChangeFree and {normal = 'yellow_btn_up_186x66.png',pressed = 'yellow_btn_down_186x66.png',disabled = "grey_btn_186x66.png"}
        or {normal = 'green_btn_up_148x76.png',pressed = 'green_btn_down_148x76.png',disabled = "grey_btn_148x78.png"}

    self.select_button = WidgetPushButton.new(btn_images)
        :align(display.BOTTOM_CENTER, bg:getContentSize().width/2, 20)
        :addTo(bg)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("传送"),
        }))
        :onButtonClicked(function()
                if not Alliance_Manager:GetMyAlliance():IsDefault() then
                    UIKit:showMessageDialog(_("错误"),_("你已加入联盟不能切换服务器，退出联盟后重试。"))
                    return
                end
                if not couldChangeFree and User:GetGemValue() < intInit.switchServerGemUsed.value then
                    UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            end,
                            btn_name= _("前往商店")
                        })
                    return
                end
                if (self.server.openAt - intInit.switchServerLimitDays.value * 24 * 60 * 60 * 1000) > User.countInfo.registerTime  then
                    UIKit:showMessageDialog(_("错误"),_("不能迁移到选定的服务器"))
                    return
                end
                if User:GetMyDeals() and #User:GetMyDeals() > 0 then
                    UIKit:showMessageDialog(_("错误"),_("您有商品正在出售,不能切换服务器"))
                    return
                end

                UIKit:showMessageDialog(_("提示"),string.format(_("是否确认将该账号迁移至服务器 %s ？（你的游戏进度将不会丢失）"),self.server.name)):CreateOKButton(
                    {
                        listener = function ()
                            if self.server_code ~= User.serverId then
                                NetManager:getSwitchServer(self.server_code)
                            end
                        end
                    })
        end)
    -- 切换服务器需要花费的金龙币
    if not couldChangeFree then
        self.select_button:setButtonLabelOffset(0, 16)
        local num_bg = display.newSprite("back_ground_124x28.png", nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(self.select_button):align(display.CENTER, 0, 22):setTag(1)
        -- gem icon
        local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(num_bg):align(display.CENTER, 20, num_bg:getContentSize().height/2):scale(0.6)
        local price = UIKit:ttfLabel({
            text = string.formatnumberthousands(intInit.switchServerGemUsed.value),
            size = 18,
            color = 0xffd200,
        }):align(display.LEFT_CENTER, 50 , num_bg:getContentSize().height/2)
            :addTo(num_bg)
    end
    local list_view ,list_node = UIKit:commonListView({
        viewRect = cc.rect(0,0,568,460),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        async = true,
    })
    list_node:addTo(bg):pos(20,118)
    list_view:onTouch(handler(self, self.listviewListener))
    list_view:setDelegate(handler(self, self.sourceDelegate))
    self.list_view = list_view
    local tips_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 88}):addTo(bg):align(display.TOP_CENTER, 304, bg_height - 22)
    UIKit:ttfLabel({
        text = string.format(_("城堡等级 Lv%s"),City:GetFirstBuildingByType("keep"):GetLevel()),
        size = 22,
        color= 0x403c2f,
    }):align(display.LEFT_CENTER, 20, 60):addTo(tips_bg)
    UIKit:ttfLabel({
        text = Alliance_Manager:GetMyAlliance():IsDefault() and _("不在联盟中") or _("在联盟当中"),
        size = 20,
        color= Alliance_Manager:GetMyAlliance():IsDefault() and 0x1d8a00 or 0x970000,
    }):align(display.LEFT_CENTER, 20, 30):addTo(tips_bg)
    local info_icon = display.newSprite("info_26x26.png"):addTo(tips_bg):align(display.LEFT_CENTER, tips_bg:getContentSize().width - 40, tips_bg:getContentSize().height/2)
    local ruls =UIKit:ttfLabel({
        text = _("传送规则"),
        size = 22,
        color= 0x076886,
    }):align(display.RIGHT_CENTER, info_icon:getPositionX() - 10, tips_bg:getContentSize().height/2):addTo(tips_bg)
    UIKit:addTipsToNode(ruls,{_("你只能在未加入联盟的情况传送到新的服务器。"),
        _("城堡在Lv10一下(不包括Lv10)可免费传送。"),
        _("城堡在Lv10一下(城堡在Lv10以上(包括Lv10)不能传送到新服。)可免费传送。"),
    },tips_bg,cc.size(420,0),-200,-200)
     UIKit:addTipsToNode(info_icon,{_("你只能在未加入联盟的情况传送到新的服务器。"),
        _("城堡在Lv10一下(不包括Lv10)可免费传送。"),
        _("城堡在Lv10一下(城堡在Lv10以上(包括Lv10)不能传送到新服。)可免费传送。"),
    },tips_bg,cc.size(420,0),-200,-200)
    self:FetchServers()

end

function GameUISettingServer:FetchServers()
    NetManager:getServersPromise():done(function(response)
        if response.msg.code == 200 then
            local servers = response.msg.servers
            self.data = servers
            self:RefreshList()
            self:RefreshServerInfo()
        end
    end)
end

function GameUISettingServer:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.data
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.data[idx]
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:GetItemContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:FillDataItem(content,data)
        item:setItemSize(566,149)
        return item
    end
end

function GameUISettingServer:RefreshList()
    self:SortServerData()
    self.list_view:reload()
end

function GameUISettingServer:SortServerData()
    table.sort( self.data, function(a,b)
        return a.openAt > b.openAt
    end )
end

function GameUISettingServer:GetServerLocalizeName(server)
    return Localize.server_name[server.id]
end


function GameUISettingServer:GetStateLableInfoByUserCount(count)
    if count >= 1000 then
        return "HIGH",self.HIGH_COLOR
    elseif count >= 500 then
        return "NORMAL",self.LOW_COLOR
    else
        return "LOW",self.LOW_COLOR
    end
end

function GameUISettingServer:GetItemContent()
    local content_bg_width,content_bg_height = 566,149
    local content = WidgetUIBackGround.new({width = content_bg_width,height=content_bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg = display.newSprite("title_blue_558x34.png")
        :align(display.CENTER_TOP, content_bg_width/2, content_bg_height - 6):addTo(content)
    local title_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0xffedae
    }):align(display.LEFT_CENTER,20, 17):addTo(title_bg)
    local is_new_server_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0x96ff00
    }):align(display.RIGHT_CENTER,538, 17):addTo(title_bg)
    local topAllianceCountry = display.newSprite("icon_unknow_country.png"):align(display.LEFT_BOTTOM, 20, 0):addTo(content)
    local topAlliance = UIKit:ttfLabel({
        text = _("占领者"),
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 132, 76):addTo(content)
    local top_alliance_label = UIKit:ttfLabel({
        text = "DragonFall",
        size = 20,
        color= 0x970000
    }):align(display.LEFT_BOTTOM, topAlliance:getContentSize().width + topAlliance:getPositionX() + 10, 76):addTo(content)
    local desc_label = UIKit:ttfLabel({
        text = _("人口"),
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 132, 48):addTo(content)
    local state_label = UIKit:ttfLabel({
        text = "HIGH",
        size = 20,
        color= 0x970000
    }):align(display.LEFT_BOTTOM, desc_label:getContentSize().width + desc_label:getPositionX() + 10, 48):addTo(content)
    local here_label = UIKit:ttfLabel({
        text = _("你拥有一片领地"),
        size = 20,
        color= 0x076886
    }):align(display.LEFT_BOTTOM, 132, 20):addTo(content)
    local unselected = display.newSprite("checkbox_unselected.png"):addTo(content):align(display.RIGHT_CENTER,544, 65)
    local selected = display.newSprite("checkbox_selectd.png"):addTo(content):align(display.RIGHT_CENTER,544, 65)
    content.title_label = title_label
    content.is_new_server_label = is_new_server_label
    content.topAllianceCountry = topAllianceCountry
    content.top_alliance_label = top_alliance_label
    content.state_label = state_label
    content.unselected = unselected
    content.selected = selected
    content.here_label = here_label
    return content
end

function GameUISettingServer:FillDataItem(content,data)
    content.title_label:setString(self:GetServerLocalizeName(data))
    local isNew = (app.timer:GetServerTime() * 1000 - 7 * 24 * 60 * 60 * 1000) <= data.openAt
    content.is_new_server_label:setString(isNew and "[NEW!]" or "")
    content.topAllianceCountry:setTexture(data.serverInfo.alliance and data.serverInfo.alliance ~= json.null and UILib.alliance_language_frame[data.serverInfo.alliance.country] or "icon_unknow_country.png")
    content.top_alliance_label:setString(data.serverInfo.alliance and data.serverInfo.alliance ~= json.null and "["..data.serverInfo.alliance.tag.."] "..data.serverInfo.alliance.name or _("无"))
    local str,color = self:GetStateLableInfoByUserCount(data.serverInfo.activeCount or 0)
    content.state_label:setString(str)
    content.state_label:setColor(color)
    if data.id == self.server_code then
        content.selected:show()
        content.unselected:hide()
    else
        content.selected:hide()
        content.unselected:show()
    end
    if data.id == self.current_code then
        content.here_label:show()
    else
        content.here_label:hide()
    end
end

function GameUISettingServer:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local server = self.data[event.itemPos]
        if not server then return end
        self.server = server
        self.server_code = server.id
        self:RefreshCurrentPageList()
        self:RefreshServerInfo()
    end
end

function GameUISettingServer:RefreshCurrentPageList()
    local items = self.list_view:getItems()
    for __,v in ipairs(items) do
        local idx = v.idx_
        local server = self.data[idx]
        local content = v:getContent()
        self:FillDataItem(content,server)
    end
end

function GameUISettingServer:RefreshServerInfo()
    local btn_status = self.server_code ~= self.current_code
    self.select_button:setButtonEnabled(btn_status)
    if self.select_button:getChildByTag(1) then
        if btn_status then
            self.select_button:getChildByTag(1):clearFilter()
        else
            self.select_button:getChildByTag(1):setFilter(filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1}))
        end
    end
end

return GameUISettingServer






