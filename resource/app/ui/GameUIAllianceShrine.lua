--
-- Author: Danny He
-- Date: 2014-11-08 15:13:13
local GameUIAllianceShrine = UIKit:createUIClass("GameUIAllianceShrine","GameUIAllianceBuilding")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local StarBar = import(".StarBar")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UILib = import(".UILib")
local GameUtils = GameUtils
--异步列表按钮事件修复
function GameUIAllianceShrine:ctor(city,default_tab,building)
    GameUIAllianceShrine.super.ctor(self, city, _("联盟圣地"),default_tab,building)
    self.default_tab = default_tab
    self.my_alliance = Alliance_Manager:GetMyAlliance()
end
function GameUIAllianceShrine:OnAllianceDataChanged_shrineReports()
    self:RefreshUI()
end
function GameUIAllianceShrine:OnAllianceDataChanged_shrineDatas()
    if self:GetSelectedButtonTag() == "stage" then
        self:RefreshStageListView()
    end
end
function GameUIAllianceShrine:OnAllianceDataChanged_shrineEvents(alliance, deltaData)
    if self:GetSelectedButtonTag() == "fight_event" and
    (deltaData("shrineEvents.add") or
    deltaData("shrineEvents.remove")) then
        self:RefreshFightListView()
    end
    if self:GetSelectedButtonTag() == "stage" then
        self:RefreshStageListView()
    end
    self.tab_buttons:SetButtonTipNumber("fight_event", #Alliance_Manager:GetMyAlliance().shrineEvents)
end
function GameUIAllianceShrine:OnMoveOutStage()
    GameUIAllianceShrine.super.OnMoveOutStage(self)
end
function GameUIAllianceShrine:onCleanup()
    self.my_alliance:RemoveListenerOnType(self, "shrineDatas")
    self.my_alliance:RemoveListenerOnType(self, "shrineReports")
    self.my_alliance:RemoveListenerOnType(self, "shrineEvents")
    GameUIAllianceShrine.super.onCleanup(self)
end


function GameUIAllianceShrine:OnMoveInStage()
    GameUIAllianceShrine.super.OnMoveInStage(self)
    self.tab_buttons = self:CreateTabButtons(
        {
            {
                label = _("联盟危机"),
                tag = "stage",
                default = "stage" == self.default_tab,
            },
            {
                label = _("战斗事件"),
                tag = "fight_event",
                default = "fight_event" == self.default_tab,
            },
            {
                label = _("事件记录"),
                tag = "events_history",
                default = "events_history" == self.default_tab,
            },
        },
        function(tag)
            --call common tabButtons event
            if self["TabEvent_" .. tag] then
                if self.currentContent then
                    self.currentContent:hide()
                end
                self.currentContent = self["TabEvent_" .. tag](self)
                assert(self.currentContent)
                self.currentContent:show()
                self:RefreshUI()
            else
                if self.currentContent then
                    self.currentContent:hide()
                end
            end
        end
    ):pos(window.cx, window.bottom + 34)
    self.tab_buttons:SetButtonTipNumber("fight_event", #Alliance_Manager:GetMyAlliance().shrineEvents)
    self.my_alliance:AddListenOnType(self, "shrineDatas")
    self.my_alliance:AddListenOnType(self, "shrineReports")
    self.my_alliance:AddListenOnType(self, "shrineEvents")

    scheduleAt(self, function()
        local aln = Alliance_Manager:GetMyAlliance()
        if self:GetSelectedButtonTag() == "stage" then 
            local res = aln:GetPerceptionRes()
            local value = aln:GetPerception()
            local display_str = string.format(_("感知力:%s"),value .. "/" .. res.limit)
            if self.stage_ui and self.stage_ui.insight_label:getString() ~= display_str then
                self.stage_ui.insight_label:setString(display_str)
                self.stage_ui.progressBar:setPercentage(value/res.limit*100)
            end
            if self.stage_ui and self.stage_ui.perHour_label then
                self.stage_ui.perHour_label:setString(string.format("+%s/h", res.output))
            end
        elseif self:GetSelectedButtonTag() == "fight_event" then
            for i,v in ipairs(self.fight_list:getItems()) do
                local event = v:getContent().event
                if event then
                    local time = event.startTime/1000 - app.timer:GetServerTime()
                    v:getContent().time_label:setString(GameUtils:formatTimeStyle1(time))
                end
            end
        end
    end)
end

function GameUIAllianceShrine:CreateBetweenBgAndTitle()
    GameUIAllianceShrine.super.CreateBetweenBgAndTitle(self)
    self.main_content = display.newNode():addTo(self:GetView()):pos(window.left,window.bottom_top)
end

function GameUIAllianceShrine:GetSelectedButtonTag()
    local tag = ""
    if self.tab_buttons then
        tag = self.tab_buttons:GetSelectedButtonTag()
    elseif self.default_tab then
        tag = self.default_tab
    end
    return tag
end

function GameUIAllianceShrine:RefreshUI()
    local tag = self:GetSelectedButtonTag()
    if tag == 'stage' then
        self:RefreshStageListView()
        local current,total = Alliance_Manager:GetMyAlliance():GetStarInfoBy(self:GetStagePage())
        self.stage_ui.percentLabel:setString(current .. "/" .. total)
    elseif tag == 'fight_event' then
        self:RefreshFightListView()
    elseif tag == 'events_history' then
        if not DataManager:getUserAllianceData().shrineReports then
            NetManager:getShrineReportsPromise():done(function()
                self:RefreshEventsListView()
            end)
        else
            self:RefreshEventsListView()
        end
    end
end
function GameUIAllianceShrine:GetStagePage()
    return self.state_page_ or 1
end
function GameUIAllianceShrine:SetStagePage(num)
    self.state_page_ = num
end
function GameUIAllianceShrine:ChangeStagePage(offset)
    local targetPage = self:GetStagePage() + offset
    if targetPage  > self.my_alliance:GetMaxStage() then
        return
    elseif  targetPage < 1 then
        return
    end
    self:SetStagePage(targetPage)
    local desc = Localize.shrine_desc[string.format("main_stage_%s",self:GetStagePage())]
    self.stage_ui.stage_label:setString(desc)
    self:RefreshUI()
end

function GameUIAllianceShrine:TabEvent_stage()
    if self.stage_node then return self.stage_node end
    self:SetStagePage(1)
    self.stage_ui = {}
    local stage_node = display.newNode()
    local bar_bg = display.newSprite("process_bar_540x40.png")
        :align(display.LEFT_BOTTOM,60,20)
        :addTo(stage_node)
    local progressBar = UIKit:commonProgressTimer("bar_color_540x40.png"):align(display.LEFT_BOTTOM,0,1):addTo(bar_bg)
    local insight_bg = display.newSprite("back_ground_43x43.png")
        :addTo(bar_bg)
        :align(display.RIGHT_CENTER, 30, 20)
    display.newScale9Sprite("insight_icon_40x44.png")
        :addTo(insight_bg)
        :align(display.CENTER,24,18)
    local aln = Alliance_Manager:GetMyAlliance()
    local res = aln:GetPerceptionRes()
    local value = aln:GetPerception()
    local display_str = string.format(_("感知力:%s"), value .. "/" .. res.limit)
    local insight_label = UIKit:ttfLabel({
        text = display_str,
        size = 20,
        color = 0xfff3c7
    }):align(display.LEFT_CENTER,40,20):addTo(bar_bg)
    progressBar:setPercentage(value/res.limit*100)
    local perHour_label = UIKit:ttfLabel({
        text = string.format("+%s/h", res.output),
        size = 20,
        color= 0xfff3c7,
        align = cc.TEXT_ALIGNMENT_RIGHT
    }):addTo(bar_bg):align(display.RIGHT_CENTER,530,20)
    self.stage_ui.insight_label = insight_label
    self.stage_ui.perHour_label = perHour_label
    self.stage_ui.progressBar = progressBar
    --title

    local title_bg = display.newSprite("shire_stage_title_564x58.png")
        :align(display.LEFT_TOP,40,window.betweenHeaderAndTab)
        :addTo(stage_node)

    local left_button = WidgetPushButton.new(
        {normal = "shrine_page_btn_normal_52x44.png",pressed = "shrine_page_btn_light_52x44.png"},
        {scale9 = false}
    ):addTo(title_bg):align(display.LEFT_CENTER,9,31)
        :onButtonClicked(function()
            self:ChangeStagePage(-1)
        end)
    local icon = display.newSprite("shrine_page_control_26x34.png")
    icon:setFlippedX(true)
    icon:addTo(left_button):pos(26,0)


    local right_button = WidgetPushButton.new(
        {normal = "shrine_page_btn_normal_52x44.png",pressed = "shrine_page_btn_light_52x44.png"},
        {scale9 = false}
    ):addTo(title_bg):align(display.RIGHT_CENTER,559,31)
        :onButtonClicked(function()
            self:ChangeStagePage(1)
        end)
    display.newSprite("shrine_page_control_26x34.png")
        :addTo(right_button)
        :pos(-26,0)

    local stage_label = UIKit:ttfLabel({
        text = Localize.shrine_desc[string.format("main_stage_%s",self:GetStagePage())],
        size = 20,
        color = 0xffedae
    })
        :align(display.LEFT_CENTER,70,29)
        :addTo(title_bg)
    self.stage_ui.stage_label = stage_label
    local star_bar = StarBar.new({
        max = 1,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = 1,
    }):addTo(title_bg):align(display.RIGHT_CENTER,430,29)

    local current,total = Alliance_Manager:GetMyAlliance():GetStarInfoBy(self:GetStagePage())
    local percentLabel = UIKit:ttfLabel({
        color = 0xffedae,
        size = 20,
        text = current .. "/" .. total
    }):align(display.LEFT_CENTER,431,29):addTo(title_bg)
    self.stage_ui.percentLabel = percentLabel
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0,0,568,630),
    -- bgColor = UIKit:hex2c4b(0x7a000000),
    })
    self.stage_list = list
    list_node:addTo(stage_node):pos(35,80)
    self.stage_node = stage_node
    self.stage_node:addTo(self.main_content)
    return self.stage_node
end

function GameUIAllianceShrine:GetStageListItem(index,stage_obj)
    local alliance = Alliance_Manager:GetMyAlliance()
    local item = self.stage_list:newItem()
    local is_locked = not alliance:IsSubStageUnlock(stage_obj.stageName)
    local troop = UtilsForShrine:FormatShrineTroops(stage_obj)[2]

    local desc_color = 0xffffff
    local logo_file = "alliance_shire_stage_bg_554x130_black.png"
    if not is_locked then
        if troop.type == 'sentinel' or troop.type == 'crossbowman' or troop.type == 'horseArcher' or troop.type == 'ballista' then
            logo_file = "alliance_shire_stage_bg_554x130_red.png"
            desc_color = 0xf6b304
        else
            desc_color = 0x00d2ff
            logo_file = "alliance_shire_stage_bg_554x130_blue.png"
        end
    end
    local bg = WidgetUIBackGround.new({width = 568,height = 216},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local logo_bg = display.newSprite(logo_file)
    logo_bg:align(display.TOP_CENTER, 284, 210):addTo(bg)
    local title_label = UIKit:ttfLabel({
        text = Localize.shrine_desc[stage_obj.stageName][1],
        size = 25,
        color=  is_locked and 0xffffff or 0xffedae,
    }):align(display.LEFT_BOTTOM, 10, 94):addTo(logo_bg)
    if is_locked then
        display.newSprite("alliance_stage_lock_icon.png")
            :align(display.LEFT_BOTTOM, title_label:getPositionX()+title_label:getContentSize().width + 10, 96)
            :addTo(logo_bg)
    end
    UIKit:ttfLabel({
        text = Localize.shrine_desc[stage_obj.stageName][2],
        size = 18,
        color=  desc_color,
        dimensions = cc.size(400,74)
    }):align(display.LEFT_TOP, 10, 82):addTo(logo_bg)

    local stage_star = alliance:GetSubStageStar(stage_obj.stageName)
    local x,y = 14,15
    for star_index = 1,3 do
        local image_file = "alliance_shire_star_60x58_0.png"
        if star_index <= stage_star then
            image_file = "alliance_shire_star_60x58_1.png"
        end
        display.newSprite(image_file):align(display.LEFT_BOTTOM, x, y):addTo(bg)
        x = x + 70
    end

    local troop_image = UILib.soldier_image[troop.type][troop.star]
    if is_locked then
        local sp = display.newFilteredSprite(troop_image, "CUSTOM", json.encode({frag = "shaders/ps_discoloration.fs",shaderName = "ps_discoloration"}))
            :align(display.RIGHT_BOTTOM, 550, 0)
            :addTo(logo_bg)
        sp:setFlippedX(true)
        display.newSprite("alliance_shire_stage_soldier_shadow_128x107.png"):addTo(sp):align(display.LEFT_BOTTOM, 0, 0)
    else
        local power_bg = display.newSprite("shrie_power_bg_146x26.png"):align(display.LEFT_BOTTOM, 260, 30):addTo(bg)
        display.newSprite("dragon_strength_27x31.png")
            :align(display.LEFT_CENTER,-10,13)
            :addTo(power_bg)
        UIKit:ttfLabel({
            text = string.formatnumberthousands(stage_obj.enemyPower),
            size = 20,
            color = 0xfff3c7
        }):align(display.LEFT_CENTER,20,13):addTo(power_bg)
        local event = Alliance_Manager:GetMyAlliance():GetShrineEventByStageName(stage_obj.stageName)
        if event then
            UIKit:ttfLabel({
                text = _("已激活"),
                size = 22,
                color= 0x930000,
                align = cc.TEXT_ALIGNMENT_RIGHT,
            }):addTo(bg):align(display.CENTER, 486, 44)
        else
            local button = WidgetPushButton.new({
                normal = "blue_btn_up_148x58.png",
                pressed = "blue_btn_down_148x58.png"
            }):align(display.RIGHT_BOTTOM, 560, 15)
                :addTo(bg)
                :setButtonLabel("normal",UIKit:commonButtonLable({
                    text = _("调查"),
                    size = 20,
                    color = 0xfff3c7
                }))
            button:onButtonClicked(function(event)
                self:OnResearchButtonClick(stage_obj,button)
            end)
        end
        local sp = display.newSprite(troop_image):align(display.RIGHT_BOTTOM, 550, 0):addTo(logo_bg)
        if troop.type == "catapult" then
            sp:setFlippedX(true)
        end
        display.newSprite("alliance_shire_stage_soldier_shadow_128x107.png"):addTo(sp):align(display.LEFT_BOTTOM, 0, 0)
    end
    item:addContent(bg)
    item:setItemSize(568,216)
    return item
end

function GameUIAllianceShrine:RefreshStageListView()
    self.stage_list:removeAllItems()
    for i,stage_obj in ipairs(Alliance_Manager:GetMyAlliance():GetSubStagesInfoBy(self:GetStagePage())) do
        local item = self:GetStageListItem(i,stage_obj)
        self.stage_list:addItem(item)
    end
    self.stage_list:reload()
end

function GameUIAllianceShrine:OnResearchButtonClick(stage_obj,sender)
    UIKit:newGameUI("GameUIAllianceShrineDetail",stage_obj,true):AddToCurrentScene(true)
end

--战斗事件
function GameUIAllianceShrine:TabEvent_fight_event()
    if self.fight_event_node then return self.fight_event_node end
    local fight_event_node = display.newNode()

    self.fight_list = UIListView.new({
        viewRect = cc.rect((window.width - 568)/2,0,568,window.betweenHeaderAndTab),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }):addTo(fight_event_node)
    fight_event_node:addTo(self.main_content)
    self.fight_event_node = fight_event_node
    return self.fight_event_node
end
local shrineStage = GameDatas.AllianceInitData.shrineStage
function GameUIAllianceShrine:BuildFightItemBox(event)
    local box = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(380,102),cc.rect(15,10,538,100))
    local player_strengh_bg = display.newScale9Sprite("back_ground_548x40_1.png"):size(356,39):addTo(box):align(display.LEFT_BOTTOM, 12,12)
    local player_count_bg = display.newScale9Sprite("back_ground_548x40_2.png")
        :size(356,39):addTo(box)
        :align(display.LEFT_BOTTOM, 12,player_strengh_bg:getPositionY()+39)
    display.newSprite("res_citizen_88x82.png"):scale(0.35):align(display.LEFT_CENTER,5,19):addTo(player_count_bg)
    display.newSprite("dragon_strength_27x31.png"):align(display.LEFT_CENTER,5,19):addTo(player_strengh_bg)
    UIKit:ttfLabel({
        text = _("建议玩家数量"),
        size = 18,
        color = 0x5d563f
    }):align(display.LEFT_CENTER, 40, 19):addTo(player_count_bg)

    local stageInfo = shrineStage[event.stageName]
    UIKit:ttfLabel({
        text = string.format("%s/%s",#event.playerTroops, stageInfo.suggestPlayer),
        size = 20,
        color = 0x403c2f
    }):align(display.RIGHT_CENTER, 340, 19):addTo(player_count_bg)
    UIKit:ttfLabel({
        text = _("建议部队战斗力"),
        size = 18,
        color = 0x5d563f
    }):align(display.LEFT_CENTER, 40, 19):addTo(player_strengh_bg)
    UIKit:ttfLabel({
        text = "> " .. string.formatnumberthousands(stageInfo.suggestPower),
        size = 20,
        color = 0x403c2f
    }):align(display.RIGHT_CENTER, 340, 19):addTo(player_strengh_bg)
    return box
end

function GameUIAllianceShrine:GetFight_List_Item(event)
    local bg = WidgetUIBackGround.new({width = 568,height = 172},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg =  display.newSprite("title_blue_554x34.png"):align(display.TOP_CENTER, 284, 168):addTo(bg)
    UIKit:ttfLabel({
        text = Localize.shrine_desc[event.stageName][1],
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 10, 17):addTo(title_bg)
    UIKit:ttfLabel({
        text = _("进行中"),
        size = 22,
        color = 0xffedae,
        align = cc.TEXT_ALIGNMENT_RIGHT
    }):align(display.RIGHT_CENTER, 522, 17):addTo(title_bg)
    local box = self:BuildFightItemBox(event)
        :addTo(bg)
        :align(display.LEFT_BOTTOM,8,18)
    local button = WidgetPushButton.new({
        normal = "blue_btn_up_148x58.png",
        pressed = "blue_btn_down_148x58.png"
    })
        :align(display.RIGHT_BOTTOM,558, 16):addTo(bg)
        :setButtonLabel("normal",UIKit:commonButtonLable({
            text = _("派兵"),
            size = 20,
            color = 0xfff3c7
        }))
        :onButtonClicked(function()
            -- if self.my_alliance:GetSelf():IsProtected() then
            --     UIKit:showMessageDialog(_("提示"),_("进攻该目标将失去保护状态，确定继续派兵?"),function()
            --         self:OnDispatchSoliderButtonClicked(event)
            --     end)
            -- else
                self:OnDispatchSoliderButtonClicked(event)
            -- end
        end)

    local time_label = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(event.startTime/1000 - app.timer:GetServerTime()),
        color = 0x7e0000,
        size = 20,
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.BOTTOM_CENTER,button:getPositionX()- button:getCascadeBoundingBox().width/2,88):addTo(bg)
    bg.time_label = time_label
    bg.event = event
    return bg
end

function GameUIAllianceShrine:RefreshFightListView()
    self.fight_list:removeAllItems()
    for i,event in ipairs(self.my_alliance:GetShrineEventsBySeq()) do
        local item = self.fight_list:newItem()
        local content = self:GetFight_List_Item(event)
        item:addContent(content)
        item:setItemSize(568,178)
        self.fight_list:addItem(item)
    end
    self.fight_list:reload()
end

function GameUIAllianceShrine:OnDispatchSoliderButtonClicked(event)
    UIKit:newGameUI("GameUIShireFightEvent",event):AddToCurrentScene(true)
end

--事件记录
function GameUIAllianceShrine:TabEvent_events_history()
    if self.events_history then return self.events_history end
    local events_history = display.newNode()
    self.events_list = UIListView.new({
        viewRect = cc.rect((window.width - 568)/2,0,568,window.betweenHeaderAndTab),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        async = true,
    }):addTo(events_history)
    self.events_list:setDelegate(handler(self, self.reportsSouceDelegate))
    events_history:addTo(self.main_content)
    self.events_history = events_history
    return self.events_history
end

function GameUIAllianceShrine:reportsSouceDelegate(listView, tag, idx)
    if listView == self.events_list then
        if cc.ui.UIListView.COUNT_TAG == tag then
            return #self.report_datas
        elseif cc.ui.UIListView.CELL_TAG == tag then
            local item
            local content
            item = self.events_list:dequeueItem()
            if not item then
                item = self.events_list:newItem()
                content = self:GetReportsItem()
                item:addContent(content)
            else
                content = item:getContent()
            end
            local report = self.report_datas[idx]
            self:fillReportItemContent(content,report,idx)
            item:setItemSize(568,172)
            return item
        end
    end
end
function GameUIAllianceShrine:RefreshEventsListView()
    -- self.events_list:removeAllItems()
    local data = clone(Alliance_Manager:GetMyAlliance().shrineReports)
    table.sort( data, function(a,b)
        return a.time > b.time
    end)
    self.report_datas = data
    self.events_list:reload()
end

function GameUIAllianceShrine:BuildReportItemBox(report)
    local box = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(380,102),cc.rect(15,10,538,100))
    local player_strengh_bg = display.newScale9Sprite("back_ground_548x40_1.png"):size(356,39):addTo(box):align(display.LEFT_BOTTOM, 12,12)
    local player_count_bg = display.newScale9Sprite("back_ground_548x40_2.png")
        :size(356,39):addTo(box)
        :align(display.LEFT_BOTTOM, 12,player_strengh_bg:getPositionY()+39)
    display.newSprite("res_citizen_88x82.png"):scale(0.35):align(display.LEFT_CENTER,5,19):addTo(player_count_bg)
    display.newSprite("dragon_strength_27x31.png"):align(display.LEFT_CENTER,5,19):addTo(player_strengh_bg)
    UIKit:ttfLabel({
        text = _("参与玩家"),
        size = 18,
        color = 0x5d563f
    }):align(display.LEFT_CENTER, 40, 19):addTo(player_count_bg)
    local player_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x403c2f
    }):align(display.RIGHT_CENTER, 340, 19):addTo(player_count_bg)
    UIKit:ttfLabel({
        text = _("人均战斗力"),
        size = 18,
        color = 0x5d563f
    }):align(display.LEFT_CENTER, 40, 19):addTo(player_strengh_bg)
    local power_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x403c2f
    }):align(display.RIGHT_CENTER, 340, 19):addTo(player_strengh_bg)
    box.player_label = player_label
    box.power_label = power_label
    return box
end

function GameUIAllianceShrine:fillReportItemContent(content,report,idx)
    content.idx = idx
    if report.star > 0 then
        content.title_bg_0:show()
        content.title_bg_1:hide()
        content.star_bar:show()
        content.star_bar:setNum(report.star)
        content.faild_label:hide()
    else
        content.title_bg_0:hide()
        content.title_bg_1:show()
        content.star_bar:hide()
        content.faild_label:show()
    end
    local box = content.box
    box.player_label:setString(#report.playerDatas)
    box.power_label:setString(report.playerAvgPower)
    content.date_label:setString(os.date("%Y-%m-%d",report.time/1000))
    content.time_label:setString(os.date("%H:%M:%S",report.time/1000))
    content.title_label:setString(Localize.shrine_desc[report.stageName][1])
    if content.button then
        content.button:removeSelf()
    end
    local button = WidgetPushButton.new({
        normal = "blue_btn_up_148x58.png",
        pressed = "blue_btn_down_148x58.png"
    })
        :align(display.RIGHT_BOTTOM,558, 16):addTo(content)
        :setButtonLabel("normal",UIKit:commonButtonLable({
            text = _("详情"),
            size = 20,
            color = 0xfff3c7
        }))
        :onButtonClicked(function()
            self:OnReportButtonClicked(content.idx )
        end)
    content.button = button
end
function GameUIAllianceShrine:GetReportsItem(report)
    local bg = WidgetUIBackGround.new({width = 568,height = 172},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg_0 = display.newSprite("title_green_558x34.png"):align(display.TOP_CENTER, 284, 168):addTo(bg)
    local title_bg_1 = display.newSprite("title_red_556x34.png"):align(display.TOP_CENTER, 284, 168):addTo(bg)
    local title_label = UIKit:ttfLabel({
        text =  "",--,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 10, title_bg_1:getPositionY() - 17):addTo(bg)
    local star_bar = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
    }):addTo(bg):align(display.RIGHT_CENTER,540,title_bg_1:getPositionY() -17)
    local faild_label = UIKit:ttfLabel({
        text = _("失败"),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER, 540,title_bg_1:getPositionY() - 17):addTo(bg)
    local box = self:BuildReportItemBox(report)
        :addTo(bg)
        :align(display.LEFT_BOTTOM,12,12)

    local date_label = UIKit:ttfLabel({
        text = "",
        size = 18,
        color = 0x403c2f,
    }):align(display.CENTER_TOP, 484, box:getPositionY() + box:getContentSize().height + 4):addTo(bg)

    local time_label = UIKit:ttfLabel({
        text = "",
        size = 18,
        color = 0x403c2f,
    }):align(display.CENTER_TOP, date_label:getPositionX(), box:getPositionY() + box:getContentSize().height - 16):addTo(bg)

    bg.title_bg_0 = title_bg_0
    bg.title_bg_1 = title_bg_1
    bg.title_label = title_label
    bg.star_bar = star_bar
    bg.faild_label = faild_label
    bg.box = box
    bg.date_label = date_label
    bg.time_label = time_label
    return bg
end

function GameUIAllianceShrine:OnReportButtonClicked(idx)
    print(idx)
    local report = self.report_datas[idx]
    if report then
        UIKit:newGameUI("GameUIShrineReport",report):AddToCurrentScene(true)
    end
end
return GameUIAllianceShrine


