--
-- Author: Danny He
-- Date: 2014-11-19 10:49:43
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIShrineReport = class("GameUIShrineReport",WidgetPopDialog)
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local StarBar = import(".StarBar")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local User = User
local config_shrineStage = GameDatas.AllianceInitData.shrineStage
local UILib = import(".UILib")
local UIKit = UIKit
local config_soldiers_normal = GameDatas.Soldiers.normal
local config_soldiers_special = GameDatas.Soldiers.special

GameUIShrineReport.LABEL_COLOR = {
    WIN = UIKit:hex2c3b(0x007c23),LOSE = UIKit:hex2c3b(0x980101),
    ME  = UIKit:hex2c3b(0xffedae),OTHER = UIKit:hex2c3b(0x403c2f)
}


function GameUIShrineReport:GetSoldierKillScore(soldier_name,star,count)
    count = count or 0
    star  = star or 1
    local key = string.format("%s_%d",soldier_name,star)
    local config = config_soldiers_normal[key]
    if not config then
        config = config_soldiers_special[key]
    end
    if not config  or  not config.killScore then return 0 end
    return config.killScore * count
end

function GameUIShrineReport:ctor(shrineReport)
    GameUIShrineReport.super.ctor(self,750,_("事件详情"),window.top - 82)
    self.shrineReport_ = shrineReport
    self:adapterFightDataToListView()
    self.stageConfig = config_shrineStage[self:GetShrineReport().stageName]
end

function GameUIShrineReport:onEnter()
    GameUIShrineReport.super.onEnter(self)
    self:BuildUI()
end

function GameUIShrineReport:GetShrineReport()
    return self.shrineReport_
end

function GameUIShrineReport:GetPlayerRewardLevel(playerKill)
    playerKill = tonumber(playerKill)
    for i = 3,1,-1 do
        local killNeed = self.stageConfig["playerKill_" .. i]
        if playerKill >= killNeed then
            return i
        end
    end
    return 0
end

function GameUIShrineReport:BuildUI()
    local background = self:GetBody()
    self.tab_buttons = WidgetRoundTabButtons.new({
        {tag = "data_statistics",label = _("数据统计"),default = true},
        {tag = "fight_detail",label = _("战斗详情")},
    }, function(tag)
        self:OnTabButtonClicked(tag)
    end,1):align(display.BOTTOM_CENTER,background:getContentSize().width/2,16):addTo(background)
end

function GameUIShrineReport:OnTabButtonClicked(tag)
    if self["CreateIf_" .. tag] then
        if self.current_node then
            self.current_node:hide()
        end
        self.current_node = self["CreateIf_" .. tag](self)
        self.current_node:show()
    end
    self:RefreshUI(tag)
end

function GameUIShrineReport:CreateIf_fight_detail()
    if self.fight_detail_list_node then return self.fight_detail_list_node end
    local viewRect = cc.rect(10,12,548,595)
    local list_node = display.newScale9Sprite("background_568x120.png",0,0,cc.size(viewRect.width+20,viewRect.height+24),cc.rect(10,10,548,100))
    local list = cc.ui.UIListView.new({
        viewRect = viewRect,
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
        async = true,
        -- bgColor = UIKit:hex2c4b(0x7a000000),
    }):addTo(list_node)
    list_node:addTo(self:GetBody()):align(display.BOTTOM_CENTER, self:GetBody():getContentSize().width/2,100)
    self.fight_detail_list = list
    self.fight_detail_list_node = list_node
    self.fight_detail_list:setDelegate(handler(self, self.sourceDelegate))
    return self.fight_detail_list_node
end

function GameUIShrineReport:sourceDelegate(listView, tag, idx)
    if listView == self.fight_detail_list then
        if cc.ui.UIListView.COUNT_TAG == tag then
            return #self.data_source
        elseif cc.ui.UIListView.CELL_TAG == tag then
            local item
            local content
            item = self.fight_detail_list:dequeueItem()
            if not item then
                item = self.fight_detail_list:newItem()
                content = self:GetFightItemContent()
                item:addContent(content)
            else
                content = item:getContent()
            end
            local list_data = self.data_source[idx]
            self:fillFightItemContent(content,list_data,item,idx)
            return item
        end
    elseif self.data_statistics_list == listView then
         if cc.ui.UIListView.COUNT_TAG == tag then
            return #self.player_data_source
        elseif cc.ui.UIListView.CELL_TAG == tag then
            local item
            local content
            item = self.data_statistics_list:dequeueItem()
            if not item then
                item = self.data_statistics_list:newItem()
                content = self:GetPlayerDataItemContent()
                item:addContent(content)
            else
                content = item:getContent()
            end
            local list_data = self.player_data_source[idx]
            self:fillPlayerDataItemContent(content,list_data,item,idx)
            return item
        end
    end
end

function GameUIShrineReport:GetFightItemContent()
    local content = display.newNode()
    --标题ui
    local title_part = display.newSprite("alliance_member_title_548x38.png"):align(display.LEFT_BOTTOM,0,0):addTo(content)
    local title_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0xffedae,
         align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.CENTER, 274, 19):addTo(title_part)
    title_part.title_label = title_label
    --内容
    local content_part = display.newNode()
    local bg0 = display.newScale9Sprite("back_ground_548x40_1.png"):size(548,92):align(display.LEFT_BOTTOM,0,0):addTo(content_part)
    local bg1 = display.newScale9Sprite("back_ground_548x40_2.png"):size(548,92):align(display.LEFT_BOTTOM,0,0):addTo(content_part)
    content_part.bg0 = bg0
    content_part.bg1 = bg1
    content_part:addTo(content)
    content.title_part = title_part
    content.content_part = content_part
    local player_icon = self:GetChatIcon():addTo(content_part):align(display.LEFT_CENTER, 4,46):scale(0.7)
    local kill_icon = display.newSprite("battle_33x33.png"):align(display.LEFT_BOTTOM, 94, 8):addTo(content_part):scale(0.8)
    local name_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0x403c2f
    }):align(display.LEFT_TOP,94, 80):addTo(content_part)
    local kill_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM,122, 8):addTo(content_part)
    
    local result_label = UIKit:ttfLabel({
        text = "",
        size = 24,
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.CENTER_BOTTOM, 464,30):addTo(content_part)
    content_part.name_label = name_label
    content_part.kill_label = kill_label
    content_part.result_label = result_label
    content_part.player_icon = player_icon
    return content
end


function GameUIShrineReport:GetChatIcon(icon)
    local bg = display.newSprite("dragon_bg_114x114.png")
    local icon = UIKit:GetPlayerIconOnly(icon):addTo(bg):align(display.LEFT_BOTTOM,-5, 1)
    bg.icon = icon
    return bg
end

function GameUIShrineReport:fillFightItemContent(item_content,list_data,item,item_idx)
    dump(list_data,"list_data")
    if list_data.type == 1 then
        item_content.content_part:hide()
        local content = item_content.title_part
        content:show()
        content.title_label:setString(string.format(_("回合%s"),list_data.index))
        item_content:size(548,38)
        item:setItemSize(548,38)
    elseif list_data.type == 2 then
        item_content.title_part:hide()
        local content = item_content.content_part
        local real_data = list_data.data
        --data
        content.name_label:setString(real_data.playerName or "")
        content.kill_label:setString(string.formatnumberthousands(real_data.killScore or 0))
        content.player_icon.icon:setTexture(UIKit:GetPlayerIconImage(real_data.playerIcon))
        local isWin = real_data.fightResult == "attackWin" 
        content.result_label:setColor(isWin and self.LABEL_COLOR.WIN or self.LABEL_COLOR.LOSE)
        content.result_label:setString(isWin and _("胜利") or _("失败"))
        --
        local num_for_bg = list_data.index % 2
        if num_for_bg == 0 then
            content.bg0:show()
            content.bg1:hide()
        else
            content.bg0:hide()
            content.bg1:show()
        end
        content:show()
        content.idx = item_idx
        if content.button then
            content.button:removeSelf()
        end
        content.button = button
        item_content:size(548,92)
        item:setItemSize(548,92)
    end
end
function GameUIShrineReport:adapterFightDataToListView()
    local data_source = {}
    for i,rounds in ipairs(self:GetShrineReport().fightDatas) do
        table.insert(data_source,{type = 1,data = i,index = i})
        for j,r_data in ipairs(rounds.roundDatas) do
            local data = r_data
            data.killScore = r_data.playerKill
            data.playerIcon = r_data.playerIcon
            local normal_data = {type = 2,data = data,index = j}
            table.insert(data_source,normal_data)
        end
    end
    self.data_source = data_source
    self.player_data_source = clone(self:GetShrineReport().playerDatas)
end

function GameUIShrineReport:OnRePlayClicked(idx)
    local list_data = self.data_source[idx]
    if list_data and list_data.type == 2 then
        local roundData = list_data.data
        UIKit:newGameUI("GameUIReplayNew", UtilsForShrine:GetFightReport(roundData)):AddToCurrentScene(true)
    end
end

function GameUIShrineReport:RefreshUI(tag)
    if tag == 'data_statistics' then
        self.data_statistics_list:reload()
    elseif tag == 'fight_detail' then
        self.fight_detail_list:reload()
    end
end

function GameUIShrineReport:CreateIf_data_statistics()
    if self.data_statistics_node then return self.data_statistics_node end
    local data_statistics_node = display.newNode():addTo(self:GetBody())
    local image = self:GetShrineReport().star > 0 and "report_victory_590x137.png" or "report_failure_590x137.png"
    local logo = display.newSprite(image):align(display.LEFT_TOP, 20, 727):addTo(data_statistics_node)
    local layer = UIKit:shadowLayer():size(590,30):addTo(logo)
    logo:scale(0.96)
    local honour_icon = display.newSprite("honour_128x128.png"):addTo(layer):pos(295,15):scale(0.2)
    UIKit:ttfLabel({
        text = _("联盟获得"),
        size = 18,
        color = 0xffedae,
        shadow= true,
    }):align(display.
    RIGHT_CENTER,honour_icon:getPositionX()-20,honour_icon:getPositionY()):addTo(layer)
    local shrineStage = GameDatas.AllianceInitData.shrineStage
    local key = string.format("star%dHonour", self:GetShrineReport().star)
    
    UIKit:ttfLabel({
        text = shrineStage[self:GetShrineReport().stageName][key] or 0,
        size = 20,
        color = 0xffedae,
        shadow= true,
    }):align(display.LEFT_CENTER, honour_icon:getPositionX()+20, honour_icon:getPositionY()):addTo(layer)
    local star_bar = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = self:GetShrineReport().star,
    }):addTo(logo):align(display.CENTER,295,120)
    self.data_statistics_node = data_statistics_node
    local viewRect = cc.rect(10,12,548,464)
    local list_node = display.newScale9Sprite("background_568x120.png",0,0,cc.size(viewRect.width+20,viewRect.height+24),cc.rect(10,10,548,100))
    local list = cc.ui.UIListView.new({
        viewRect = viewRect,
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
        async = true,
        -- bgColor = UIKit:hex2c4b(0x7a000000),
    }):addTo(list_node)
    list_node:addTo(data_statistics_node):align(display.BOTTOM_CENTER, self:GetBody():getContentSize().width/2,100)
    self.data_statistics_list = list
    self.data_statistics_list:setDelegate(handler(self, self.sourceDelegate))
    return data_statistics_node
end

function GameUIShrineReport:GetPlayerDataItemContent()
    local content = display.newNode() -- 548 x 80
    local bg0 = display.newScale9Sprite("back_ground_548x40_1.png"):size(548,80):align(display.LEFT_BOTTOM,0,0):addTo(content)
    local bg1 = display.newScale9Sprite("back_ground_548x40_2.png"):size(548,80):align(display.LEFT_BOTTOM,0,0):addTo(content)
    local bg2 = display.newScale9Sprite("shire_rank_bg_548x66.png"):size(548,80):align(display.LEFT_BOTTOM,0,0):addTo(content)
    local reward3 = display.newSprite("goldKill_icon_76x84.png"):align(display.LEFT_CENTER,12, 40):addTo(content):scale(0.8)
    local reward2 = display.newSprite("silverKill_icon_76x84.png"):align(display.LEFT_CENTER,20, 40):addTo(content):scale(0.8)
    local reward1 = display.newSprite("bronzeKill_icon_76x84.png"):align(display.LEFT_CENTER,20, 40):addTo(content):scale(0.8)

    local name_label = UIKit:ttfLabel({
        text = "name",
        size = 22,
        color= 0xffedae
    }):align(display.LEFT_TOP, 88, 76):addTo(content)
    local kill_icon = display.newSprite("battle_33x33.png"):align(display.LEFT_BOTTOM, 88, 10):addTo(content):scale(0.8)
    local kill_label = UIKit:ttfLabel({
        text = "121321",
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM,120, 10):addTo(content)
    local reward_bg1 = display.newSprite("box_118x118.png"):addTo(content):align(display.LEFT_CENTER, 263, 40)
    local reward_bg2 = display.newSprite("box_118x118.png"):addTo(content):align(display.LEFT_CENTER, 348, 40)
    local reward_bg3 = display.newSprite("box_118x118.png"):addTo(content):align(display.LEFT_CENTER, 432, 40)
    local reward_icon_1 = display.newSprite("dragonHp_1_128x128.png"):scale(0.78):addTo(reward_bg1):pos(59,59)
    local reward_icon_2 = display.newSprite("dragonHp_1_128x128.png"):scale(0.78):addTo(reward_bg2):pos(59,59)
    local reward_icon_3 = display.newSprite("dragonHp_1_128x128.png"):scale(0.78):addTo(reward_bg3):pos(59,59)
    reward_bg1.icon = reward_icon_1
    reward_bg2.icon = reward_icon_2
    reward_bg3.icon = reward_icon_3
    local layer = UIKit:shadowLayer():size(100,30):addTo(reward_bg1):pos(10,10)

    local label = UIKit:ttfLabel({
        text = "x100000",
        size = 14,
        color= 0xffedae,
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.CENTER, 54, 15):addTo(layer):scale(1.54)
    reward_bg1.label = label

    layer = UIKit:shadowLayer():size(100,30):addTo(reward_bg2):pos(10,10)
    label = UIKit:ttfLabel({
        text = "x100000",
        size = 14,
        color= 0xffedae,
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.CENTER, 54, 15):addTo(layer):scale(1.54)

    reward_bg2.label = label
    layer = UIKit:shadowLayer():size(100,30):addTo(reward_bg3):pos(10,10)
    label = UIKit:ttfLabel({
        text = "x100000",
        size = 14,
        color= 0xffedae,
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.CENTER, 54, 15):addTo(layer):scale(1.54)    
    reward_bg3.label = label
    reward_bg1:scale(0.54)
    reward_bg2:scale(0.54)
    reward_bg3:scale(0.54)
   
    content:size(548,80)
    content.bg0 = bg0
    content.bg1 = bg1
    content.bg2 = bg2
    content.name_label = name_label
    content.kill_label = kill_label
    content.reward3 = reward3
    content.reward1 = reward1
    content.reward2 = reward2
    content.reward_bg1 = reward_bg1
    content.reward_bg2 = reward_bg2
    content.reward_bg3 = reward_bg3
    return content
end

function GameUIShrineReport:fillPlayerDataItemContent(content,list_data,item,idx)
    if content.next_button then
        content.next_button:removeSelf()
    end 
    if content.pre_button then
        content.pre_button:removeSelf()
    end

    local next_button = WidgetPushButton.new({normal = "shrine_page_control_26x34.png"}):align(display.RIGHT_CENTER, 540, 40):addTo(content)
        :onButtonClicked(function()
            self:OnRewardPageButtonClicked(1,content)
        end)
    local pre_button = WidgetPushButton.new({normal = "shrine_page_control_26x34.png"},{flipX = true}):align(display.RIGHT_CENTER, 540, 40):addTo(content)
        :onButtonClicked(function() 
            self:OnRewardPageButtonClicked(-1,content)
        end)

    content.pre_button = pre_button
    content.next_button = next_button

    content.name_label:setString(string.format("%d.%s",idx,list_data.name))
    content.kill_label:setString(string.formatnumberthousands(list_data.kill or 0))
    if list_data.id == User:Id() then
        content.bg2:show()
        content.name_label:setColor(self.LABEL_COLOR.ME) 
        content.kill_label:setColor(self.LABEL_COLOR.ME) 
    else
        content.name_label:setColor(self.LABEL_COLOR.OTHER) 
        content.kill_label:setColor(self.LABEL_COLOR.OTHER) 
        content.bg2:hide()
        local bg_num = idx % 2 
        if bg_num == 0 then 
            content.bg0:show()
            content.bg1:hide()
        else
            content.bg0:hide()
            content.bg1:show()
        end
    end
    local player_reward_info = self:GetPlayerRewardLevel(list_data.kill or 0)
    if player_reward_info > 0 then
        for i = 1,3 do
            local node_name = string.format("reward%d",i)
            if i == player_reward_info then
                content[node_name]:show()
            else
                content[node_name]:hide()
            end
        end
    else
        content.reward3:hide()
        content.reward1:hide()
        content.reward2:hide()
    end
    local reward_data = list_data.rewards
    local count = #reward_data
    content.pages = self:GetPageSizeOfReward(count)
    content.page = 1
    content.idx = idx
    for i = 1,3 do
        local reward = reward_data[i]
        local node = content[string.format("reward_bg%d",i)]
        if node and node.icon then
            if reward then
                print("UIKit:GetItemImage(reward.type,reward.name)=",UIKit:GetItemImage(reward.type,reward.name),reward.type,reward.name)
                node.icon:setTexture(UIKit:GetItemImage(reward.type,reward.name))
                node.label:setString(string.format("x%d",reward.count))
                node:show()
            else
                printLog("HIDE", "%s",string.format("reward_bg%d",i))
                node:hide()
            end
        end
    end
    content.pre_button:hide()
    if count > 3 then
        content.next_button:show()
    else
        content.next_button:hide()
    end
    item:setItemSize(548, 80)
end

function GameUIShrineReport:GetPageSizeOfReward(count)
    return math.ceil(count/3)
end

function GameUIShrineReport:OnRewardPageButtonClicked(tag,content)
    local idx = content.idx
    local pages = content.pages
    local current_page = content.page
    if tag == -1 then -- pre
        if current_page ~= 1 then
            local next_page = content.page - 1
            content.page = next_page
             self:ChangeRewardIcon(content,next_page)
        end
    elseif tag == 1 then -- next
        if current_page < pages then
            local next_page = content.page + 1
            content.page = next_page
            self:ChangeRewardIcon(content,next_page)
        end
    end
end

function GameUIShrineReport:GetRewardPageData(idx,page)
    local start_index =  (page - 1) * 3 + 1 -- 3 is page size
    local end_index = page * 3
    local list_data = self.player_data_source[idx]
    if list_data then
        local reward_data = list_data.rewards
        return LuaUtils:table_slice(reward_data,start_index,end_index)
    else
        return {}
    end
end

function GameUIShrineReport:ChangeRewardIcon(content,page)
    printLog("ChangeRewardIcon", "%d",page)
    local idx = content.idx
    local reward_data = self:GetRewardPageData(idx,page)
    for i = 1,3 do
        local reward = reward_data[i]
        local node = content[string.format("reward_bg%d",i)]
        if node and node.icon then
            if reward then
                node.icon:setTexture(UIKit:GetItemImage(reward.type,reward.name))
                node.label:setString(string.format("x%d",reward.count))
                node:show()
            else
                node:hide()
            end
        end
    end
    if page == content.pages then
        content.pre_button:show()
        content.next_button:hide()
    elseif page == 1 then
        if content.pages > 1 then
            content.pre_button:hide()
            content.next_button:show()
        else
            content.pre_button:hide()
            content.next_button:hide()
        end
    end
end
return GameUIShrineReport

