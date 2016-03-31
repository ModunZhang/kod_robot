local GameUISearchPlayer = UIKit:createUIClass("GameUISearchPlayer","GameUIWithCommonHeader")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIScrollView = import(".UIScrollView")

local function rank_filter(response)
    local data = response.msg
    local is_not_nil = data.myData.rank ~= json.null
    if is_not_nil then
        data.myData.rank = data.myData.rank + 1
    end
    return response
end
function GameUISearchPlayer:ctor(city)
    GameUISearchPlayer.super.ctor(self,city, _("搜索玩家"))
    self.fromIndex = 0
    self.canLoadMore = false
    self.player_datas = {}
end

function GameUISearchPlayer:onEnter()
    GameUISearchPlayer.super.onEnter(self)
    local view = self:GetView()
    local searchButton = WidgetPushButton.new({
        normal = "chat_button_n_68x50.png",
        pressed= "chat_button_h_68x50.png",
    }):onButtonClicked(function(event)
        self:SearchPlayerAction(self.editbox_tag_search:getText())
    end):addTo(self:GetView()):align(display.RIGHT_TOP, window.right-40, window.top - 100)
    display.newSprite("alliacne_search_29x33.png"):addTo(searchButton):pos(-34,-25)
    local function onEdit(event, editbox)
        if event == "return" then
            self:SearchPlayerAction(self.editbox_tag_search:getText())
        end
    end

    local editbox_tag_search = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(468,48),
        listener = onEdit,
    })

    editbox_tag_search:setPlaceHolder(_("请填写本服玩家姓名"))
    editbox_tag_search:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox_tag_search:setMaxLength(12)
    editbox_tag_search:setFont(UIKit:getEditBoxFont(),18)
    editbox_tag_search:setFontColor(cc.c3b(0,0,0))
    editbox_tag_search:setReturnType(cc.KEYBOARD_RETURNTYPE_SEARCH)
    editbox_tag_search:setInputMode(cc.EDITBOX_INPUT_MODE_ASCII_CAPABLE)
    editbox_tag_search:align(display.LEFT_TOP,window.left + 40,window.top - 100):addTo(view)
    self.editbox_tag_search = editbox_tag_search
    local list,list_node = UIKit:commonListView({
        direction = UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,568,760),
        async = true,
    })
    list_node:addTo(view):align(display.BOTTOM_CENTER,window.cx,window.bottom+30)
    list:onTouch(handler(self, self.listviewListener))
    list:setDelegate(handler(self, self.playerDelegate))
    NetManager:getPlayerRankPromise("power"):done(function(response)
        self.player_datas = rank_filter(response).msg.datas
        list:reload()
    end)
    self.player_list = list
end
function GameUISearchPlayer:playerDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.player_datas
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreatePlayerContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetPlayerData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        -- 当取到客户端本地最后一个玩家信息，并且可能还有更多模糊查找到的玩家则获取更多玩家信息 
        if idx == #self.player_datas and self.canLoadMore then
            NetManager:getSearchPlayerByNamePromise(self.search_key,self.fromIndex):done(function (response)
                dump(response.msg.playerDatas)
                local limit = response.msg.limit
                local playerDatas = response.msg.playerDatas
				self:InsertMorePlayers(playerDatas)
                self.canLoadMore = #playerDatas >= limit
                self.fromIndex = self.fromIndex + limit
            end)
        end
        return item
    end
end
function GameUISearchPlayer:CreatePlayerContent()
    local item_width, item_height = 558,72
    local content = display.newNode()
    content:setContentSize(cc.size(item_width, item_height))
    WidgetUIBackGround.new({width = item_width,height = 66},WidgetUIBackGround.STYLE_TYPE.STYLE_4):align(display.CENTER,item_width/2,item_height/2):addTo(content)
    local bg = display.newSprite("background_57x57.png"):addTo(content):pos(60, item_height/2)
    local point = bg:getAnchorPointInPoints()
    local player_head_icon = UIKit:GetPlayerIconOnly():addTo(bg)
        :scale(0.5):pos(point.x, point.y+5)

    display.newSprite("dragon_strength_27x31.png"):addTo(content):pos(360, item_height/2)

    local name = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 120, 40):addTo(content)

    local value = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 360 + 20, 40):addTo(content)
    display.newSprite("alliacne_search_29x33.png"):addTo(content):pos(528,item_height/2)
    local parent = self
    function content:SetPlayerData(idx)
        local data = parent.player_datas[idx]
        player_head_icon:setTexture(UIKit:GetPlayerIconImage(data.icon))
        name:setString(data.name)
        value:setString(string.formatnumberthousands(data.value or data.power or 0))
    end

    return content
end
function GameUISearchPlayer:SearchPlayerAction(search_key)
    if not search_key or search_key == "" then
        return
    end
    self.player_datas = {}
    self.fromIndex = 0 
    NetManager:getSearchPlayerByNamePromise(search_key,self.fromIndex):done(function (response)
        dump(response.msg.playerDatas)
        local limit = response.msg.limit
        local playerDatas = response.msg.playerDatas
		self:InsertMorePlayers(playerDatas)
        self.canLoadMore = #playerDatas >= limit
        self.fromIndex = self.fromIndex + limit
        self.search_key = search_key
        self.player_list:reload()
    end)
end
function GameUISearchPlayer:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local item = event.item
        if not item then return end
        local player_data = self.player_datas[item.idx_]
        if not player_data then return end
        UIKit:newGameUI("GameUIAllianceMemberInfo",false,player_data.id,nil,User.serverId):AddToCurrentScene(true)
    end
end
function GameUISearchPlayer:InsertMorePlayers(playerDatas)
    for i,v in ipairs(playerDatas) do
        table.insert(self.player_datas, v)
    end
end
return GameUISearchPlayer






