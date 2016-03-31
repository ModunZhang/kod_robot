local Localize = import("..utils.Localize")
local GameUIWatchTower = UIKit:createUIClass('GameUIWatchTower',"GameUIWithCommonHeader")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UILib = import(".UILib")
local GameUIAllianceWatchTowerTroopDetail = import(".GameUIAllianceWatchTowerTroopDetail")
local WidgetUseItems = import("..widget.WidgetUseItems")
local config_day14 = GameDatas.Activities.day14
local SpriteConfig = import("..sprites.SpriteConfig")
local unlockPlayerSecondMarchQueue_price = GameDatas.PlayerInitData.intInit.unlockPlayerSecondMarchQueue.value
local GameUIActivityRewardNew = import(".GameUIActivityRewardNew")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")


function GameUIWatchTower:ctor(city,default_tab)
    local bn = Localize.building_name
    GameUIWatchTower.super.ctor(self,city,_("瞭望塔"))
    self.default_tab = default_tab
end

function GameUIWatchTower:OnMoveInStage()
    self:ResetTimerNodeTable()
    GameUIWatchTower.super.OnMoveInStage(self)
    self:AddOrRemoveListener(true)
    Alliance_Manager:AddHandle(self)
    self:CreateUI()
end

function GameUIWatchTower:GetTabButton()
    return self.tabButton
end

function GameUIWatchTower:CreateUI()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0,0,window.width - 70, window.betweenHeaderAndTab - 10),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    },false)
    list_node:addTo(self:GetView())
    list_node:pos(window.left+35, window.bottom_top+20)
    self.list_node = list_node
    self.listView  = list
    self.tabButton = self:CreateTabButtons({
        {
            label = _("来袭"),
            tag = "comming",
            default = self.default_tab == 'comming'
        },
        {
            label = _("进军"),
            tag = "march",
            default = self.default_tab == 'march'
        }
    },
    function(tag)
        self:TabButtonsAction(tag)
    end):pos(window.cx, window.bottom + 34)
end

function GameUIWatchTower:TabButtonsAction(tag)
    if tag == 'comming'
        or tag == 'march' then
        self.list_node:show()
        self:RefreshListView(tag)
    else
        self.list_node:hide()
    end
end

function GameUIWatchTower:AddOrRemoveListener(isAdd)
    local my_allaince = Alliance_Manager:GetMyAlliance()
    if isAdd then
        my_allaince:AddListenOnType(self, "marchEvents")
        Alliance_Manager:AddHandle(self)
    else
        my_allaince:RemoveListenerOnType(self, "marchEvents")
        Alliance_Manager:RemoveHandle(self)
    end
end

function GameUIWatchTower:OnEnterMapIndex()
end
function GameUIWatchTower:OnMapDataChanged()
    self:RefreshCurrentList()
end
function GameUIWatchTower:OnMapAllianceChanged()
end

--ui
function GameUIWatchTower:RefreshListView(tag)
    self:ResetTimerNodeTable()
    self.listView:removeAllItems()
    if tag == 'march' then
        self:RefreshMyEvents()
    else
        self:RefreshOtherEvents()
    end
    self.listView:reload()
end

function GameUIWatchTower:ResetTimerNodeTable()
    -- self.village_process = {}
    self.village_labels  = {}
    -- self.march_timer_label={}
    -- self.shrine_timer_label={}
end


function GameUIWatchTower:RefreshMyEvents()
    local my_events = UtilsForEvent:GetAllMyMarchEvents()
    LuaUtils:outputTable("my_events", my_events)
    for index = 1,2 do
        local item
        if index == 1 then
            if my_events[1] then
                item = self:GetMyEventItemWithIndex(1,true,my_events[1])
            else
                item = self:GetMyEventItemWithIndex(1,true)
            end
        else
            if User.basicInfo.marchQueue == 1 then -- 只有一条队列
                item = self:GetMyEventItemWithIndex(2,false)
            else
                if my_events[2] then
                    item = self:GetMyEventItemWithIndex(2,true,my_events[2])
                else
                    item = self:GetMyEventItemWithIndex(2,true,nil)
                end
            end
        end
        self.listView:addItem(item)
    end
end
--data === nil and isOpen == true --->待命
function GameUIWatchTower:GetMyEventItemWithIndex(index,isOpen,entity)
    local item = self.listView:newItem()
    local bg = WidgetUIBackGround.new({width = 568,height = 204},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg  = display.newSprite("title_blue_554x34.png")
        :align(display.TOP_CENTER,284, 198)
        :addTo(bg)
    if entity then
        display.newSprite("info_16x33.png"):align(display.RIGHT_CENTER,540, 17):addTo(title_bg):scale(26/33)
        WidgetPushTransparentButton.new(cc.rect(0,0,558,34))
            :addTo(title_bg):align(display.LEFT_BOTTOM, 0, 0)
            :onButtonClicked(function()
                UIKit:newGameUI("GameUIWatchTowerMyTroopsDetail",entity,entity.eventType):AddToCurrentScene(true)
            end)
    end
    local tile_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0xffedae,
    }):addTo(title_bg):align(display.LEFT_CENTER, 20, 17)
    local event_bg = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(134,134)
        :addTo(bg)
        :align(display.LEFT_BOTTOM, 10, 19)
    if not isOpen then
        local countInfo = User.countInfo
        tile_label:setString(string.format(_("行军队列 %d - "),index).._("未解锁"))
        WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:commonButtonLable({
                    text = _("签到")
                })
            )
            :align(display.RIGHT_BOTTOM,555,18)
            :onButtonClicked(function(event)
                self:OnSignButtonClikced()
            end)
            :addTo(bg)


        local button = WidgetPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:ttfLabel({
                    text = _("立即解锁"),
                    size = 18,
                    color = 0xffedae,
                    shadow = true
                })
            )
            :setButtonLabelOffset(0, 16)
            :align(display.RIGHT_BOTTOM,310,18)
            :onButtonClicked(function(event)
                if self:GetUnlockPlayerSecondMarchQueuePrice() > User:GetGemValue() then
                    UIKit:showMessageDialog(_("提示"),_("金龙币不足"))
                        :CreateOKButton(
                            {
                                listener = function ()
                                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                end,
                                btn_name= _("前往商店")
                            }
                        )
                else
                    NetManager:getUnlockPlayerSecondMarchQueuePromise():done(function (response)
                        GameGlobalUI:showTips(_("提示"),_("永久行军队列+1"))
                        self:LeftButtonClicked()
                        return response
                    end)
                end
            end)
            :addTo(bg)
        -- 立即解锁所需金龙币
        local num_bg = display.newScale9Sprite("back_ground_124x28.png",0,0,cc.size(124,26),cc.rect(5,5,114,18)):addTo(button):align(display.CENTER, -74, 19)
        -- gem icon
        local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(num_bg):align(display.CENTER, 20, num_bg:getContentSize().height/2):scale(0.6)
        local price = UIKit:ttfLabel({
            text = self:GetUnlockPlayerSecondMarchQueuePrice() >= 0 and self:GetUnlockPlayerSecondMarchQueuePrice() or 0,
            size = 18,
            color = 0xffd200,
        }):align(display.LEFT_CENTER, 50 , num_bg:getContentSize().height/2)
            :addTo(num_bg)

        UIKit:ttfLabel({
            text =  string.format(_("累计签到%s天，永久+1进攻队列"), 7),
            size = 22,
            color= 0x403c2f,
            dimensions = cc.size(360,0)
        }):addTo(bg):align(display.LEFT_TOP, 164, event_bg:getPositionY() + 120)
        display.newSprite(string.format("player_queue_seq_%d_112x112.png",index), 67, 67):addTo(event_bg)
    else
        if not entity then
            tile_label:setString(string.format(_("行军队列 %d - "),index).._("待命中"))
            WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
                :setButtonLabel(
                    UIKit:commonButtonLable({
                        text = _("前往")
                    })
                )
                :align(display.RIGHT_BOTTOM,555,10)
                :onButtonClicked(function(event)
                    app:EnterMyAllianceScene()
                end)
                :addTo(bg)
            UIKit:ttfLabel({
                text = _("去联盟领地搜索目标"),
                size = 22,
                color= 0x403c2f
            }):addTo(bg):align(display.LEFT_TOP, 164, event_bg:getPositionY() + 104)
            display.newSprite(string.format("player_queue_seq_%d_112x112.png",index), 67, 67):addTo(event_bg)
        else
            local desctition_label = UIKit:ttfLabel({
                text = _("目的地"),
                size = 20,
                color= 0x615b44
            }):align(display.LEFT_TOP,164,153):addTo(bg)
            local line_1 = display.newScale9Sprite("dividing_line.png"):size(390,2):addTo(bg):align(display.LEFT_TOP,164, 125)
            local desctition_label_val =  UIKit:ttfLabel({
                text = UtilsForEvent:GetDestination(entity),
                size = 20,
                color= 0x403c2f
            }):align(display.RIGHT_TOP,554,153):addTo(bg)
            local localtion_label = UIKit:ttfLabel({
                text = _("坐标"),
                size = 20,
                color= 0x615b44
            }):align(display.LEFT_TOP,164,115):addTo(bg)
            local line_2 = display.newScale9Sprite("dividing_line.png"):size(390,2):addTo(bg):align(display.LEFT_TOP,164, 87)
            local localtion_label_val =  UIKit:ttfLabel({
                text = UtilsForEvent:GetDestinationLocation(entity),
                size = 20,
                color= 0x403c2f
            }):align(display.RIGHT_TOP,554,115):addTo(bg)
            tile_label:setString(string.format(_("行军队列 %d - "),index)..UtilsForEvent:GetMarchEventPrefix(entity, entity.eventType))
            if entity.eventType == "helpToTroops" then
                local button = self:GetYellowRetreatButton():pos(558,15):addTo(bg)
                    :onButtonClicked(function(event)
                        self:OnRetreatButtonClicked(entity,function(success)
                            if success then
                                self:RefreshListView('march')
                            end
                        end)
                    end)
                local dragon_png = UILib.dragon_head[UtilsForEvent:GetDragonType(entity)]
                if dragon_png then
                    local icon_bg = display.newSprite("dragon_bg_114x114.png", 67, 67):addTo(event_bg)
                    display.newSprite(dragon_png, 57, 60):addTo(icon_bg)
                else
                    display.newSprite("unknown_dragon_icon_112x112.png", 67, 67):addTo(event_bg)
                end
            elseif entity.eventType == "villageEvents" then
                self:GetYellowRetreatButton():pos(558,15):addTo(bg)
                    :onButtonClicked(function(event)
                        self:OnRetreatButtonClicked(entity,function(success)
                            if success then
                                self:RefreshListView('march')
                            end
                        end)
                    end)
                local image = SpriteConfig[entity.villageData.name]:GetConfigByLevel(entity.villageData.level).png
                local icon = display.newSprite(image, 67, 67):addTo(event_bg)
                icon:setScale(120/150)
                local process_bg = display.newSprite("process_bg_village_collect_326x40.png"):align(display.LEFT_BOTTOM,164, 20):addTo(bg)
                local progress_timer = UIKit:commonProgressTimer("process_color_village_collect_326x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(process_bg)
                -- local collectCount, collectPercent = UtilsForEvent:GetCollectPercent(entity)
                -- progress_timer:setPercentage(collectPercent)
                local process_label = UIKit:ttfLabel({
                    -- text = string.format("%s/%s",string.formatnumberthousands(math.floor(collectCount)),string.formatnumberthousands(entity.villageData.collectTotal)),
                    size = 20,
                    color= 0xfff3c7,
                    shadow= true
                }):align(display.LEFT_CENTER, 20, 20):addTo(process_bg)
                scheduleAt(item,function ()
                    local collectCount, collectPercent = UtilsForEvent:GetCollectPercent(entity)
                    progress_timer:setPercentage(collectPercent)
                    process_label:setString(string.format("%s/%s",string.formatnumberthousands(math.floor(collectCount)),string.formatnumberthousands(entity.villageData.collectTotal)))
                end)
                -- self.village_process[entity:WithObject():Id()] = progress_timer
                -- self.village_labels[entity:WithObject():Id()] = process_label
            elseif entity.eventType == "attackMarchEvents"
                or entity.eventType == "attackMarchReturnEvents"
                or entity.eventType == "strikeMarchEvents"
                or entity.eventType == "strikeMarchReturnEvents"
                or entity.eventType == "shrineEvents"
            then
                local dragon_png = UILib.dragon_head[UtilsForEvent:GetDragonType(entity)]
                if dragon_png then
                    local icon_bg = display.newSprite("dragon_bg_114x114.png", 67, 67):addTo(event_bg)
                    display.newSprite(dragon_png, 57, 60):addTo(icon_bg)
                else
                    display.newSprite("unknown_dragon_icon_112x112.png", 67, 67):addTo(event_bg)
                end
                local icon_bg = display.newSprite("back_ground_43x43.png")
                    :align(display.LEFT_BOTTOM,164, 20):addTo(bg):scale(0.7)
                display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg)

                local timer_label = UIKit:ttfLabel({
                    -- text = GameUtils:formatTimeStyle1(entity:WithObject():GetTime()),
                    size = 22,
                    color= 0x403c2f
                }):addTo(bg):align(display.LEFT_BOTTOM,164+ icon_bg:getCascadeBoundingBox().width+8, 20)
                scheduleAt(item,function ()
                    timer_label:setString(UtilsForEvent:GetEventTime(entity))
                end)

                if entity.eventType ~= "shrineEvents" then
                    -- self.march_timer_label[entity:WithObject():Id()] = timer_label
                    WidgetPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}):setButtonLabel(
                        UIKit:commonButtonLable({
                            text = _("加速")
                        }))
                        :align(display.RIGHT_BOTTOM,555,10):addTo(bg)
                        :onButtonClicked(function(event)
                            self:OnSpeedUpButtonClicked(entity)
                        end)
                    -- else
                    -- self.shrine_timer_label[entity:WithObject():Id()] = timer_label
                end
                if entity.eventType ~= "attackMarchReturnEvents" and entity.eventType ~= "strikeMarchReturnEvents" and entity.eventType ~= "shrineEvents" then
                    self:GetRedRetreatButton():pos(397,10):addTo(bg)
                        :onButtonClicked(function(event)
                            self:OnRetreatButtonClicked(entity,function(success)
                                end)
                        end)
                end
            end
        end
    end
    item:addContent(bg)
    item:setItemSize(568, 204)
    return item
end

function GameUIWatchTower:GetOtherEventItem(entity)
    local item = self.listView:newItem()
    local bg = WidgetUIBackGround.new({width = 568,height = 204},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_image = entity.marchType == 'helpDefence' and 'title_green_558x34.png' or 'title_red_556x34.png'
    local title_bg  = display.newSprite(title_image)
        :align(display.TOP_CENTER,284, 198)
        :addTo(bg)
    local tile_label = UIKit:ttfLabel({
        text = UtilsForEvent:GetMarchEventPrefix(entity, entity.eventType),
        size = 20,
        color= 0xffedae,
    }):addTo(title_bg):align(display.LEFT_CENTER, 20, 17)
    local event_bg = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(134,134)
        :addTo(bg)
        :align(display.LEFT_BOTTOM, 10, 19)

    local desctition_label = UIKit:ttfLabel({
        text = _("来自"),
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_TOP,164,153):addTo(bg)
    local line_1 = display.newScale9Sprite("dividing_line.png"):size(390,2):addTo(bg):align(display.LEFT_TOP,164, 125)
    local desctition_label_val =  UIKit:ttfLabel({
        text = UtilsForEvent:GetDestinationLocation(entity),
        size = 20,
        color= 0x615b44
    }):align(display.RIGHT_TOP,554,153):addTo(bg)
    local localtion_label = UIKit:ttfLabel({
        text = _("玩家"),
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_TOP,164,115):addTo(bg)
    local line_2 = display.newScale9Sprite("dividing_line.png"):size(390,2):addTo(bg):align(display.LEFT_TOP,164, 87)
    local localtion_label_val =  UIKit:ttfLabel({
        text = self:GetEntityAttackPlayerName(entity),
        size = 20,
        color= 0x615b44
    }):align(display.RIGHT_TOP,554,115):addTo(bg)
    local dragon_png = UILib.dragon_head[self:GetEntityDragonType(entity)]
    if dragon_png then
        local icon_bg = display.newSprite("dragon_bg_114x114.png", 67, 67):addTo(event_bg)
        display.newSprite(dragon_png, 57, 60):addTo(icon_bg)
    else
        display.newSprite("unknown_dragon_icon_112x112.png", 67, 67):addTo(event_bg)
    end
    local icon_bg = display.newSprite("back_ground_43x43.png")
        :align(display.LEFT_BOTTOM,164, 20):addTo(bg):scale(0.7)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg)

    local timer_label = UIKit:ttfLabel({
        -- text = UtilsForEvent:GetEventTime(entity),
        size = 22,
        color= 0x403c2f
    }):addTo(bg):align(display.LEFT_BOTTOM,164+ icon_bg:getCascadeBoundingBox().width+8, 20)
    scheduleAt(item,function ()
        timer_label:setString(UtilsForEvent:GetEventTime(entity))
    end)
    -- self.march_timer_label[entity:WithObject():Id()] = timer_label
    --如果瞭望塔达到等级或者是盟友对我的协助
    local watchTowerLevel = Alliance_Manager:GetMyAlliance():GetAllianceBuildingInfoByName("watchTower").level
    if watchTowerLevel >= 3 and (entity.eventType == "attackMarchEvents" or entity.marchType == 'helpDefence' or entity.eventType ==  "strikeMarchEvents") then
        WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
            :setButtonLabel(UIKit:commonButtonLable({text = _("详情")}))
            :align(display.RIGHT_BOTTOM,555,10):addTo(bg)
            :onButtonClicked(function(event)
                self:OnEventDetailButtonClicked(entity)
            end)
    end
    item:addContent(bg)
    item:setItemSize(568, 204)
    return item
end

function GameUIWatchTower:OnEventDetailButtonClicked(entity)
    local strEntityType = entity.eventType
    local watchTowerLevel = Alliance_Manager:GetMyAlliance():GetAllianceBuildingInfoByName("watchTower").level
    if strEntityType == "attackMarchEvents" then
        if entity.marchType == "helpDefence" then
            NetManager:getHelpDefenceMarchEventDetailPromise(entity.id):done(function(response)
                UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,false,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE)
                    :AddToCurrentScene(true)
            end)
        else
            local my_status = Alliance_Manager:GetMyAlliance().basicInfo.status
            NetManager:getAttackMarchEventDetailPromise(entity.id,entity.fromAlliance.id):done(function(response)
                UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,true,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.MARCH)
                    :AddToCurrentScene(true)
            end)
        end
    elseif strEntityType == "strikeMarchEvents" then
        NetManager:getStrikeMarchEventDetailPromise(entity.id,entity.fromAlliance.id):done(function(response)
            UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,true,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.STRIKE)
                :AddToCurrentScene(true)
        end)
    end
end

function GameUIWatchTower:GetYellowRetreatButton()
    local button = WidgetPushButton.new({normal = "retreat_yellow_button_n_52x50.png",pressed = "retreat_yellow_button_h_52x50.png"})
        :align(display.RIGHT_BOTTOM,0,0)
    display.newSprite("retreat_button_icon_22x18.png", -26,25):addTo(button)
    return button
end

function GameUIWatchTower:GetRedRetreatButton()
    local button = WidgetPushButton.new({normal = "retreat_red_button_n_52x50.png",pressed = "retreat_red_button_h_52x50.png"})
        :align(display.RIGHT_BOTTOM,0,0)
    display.newSprite("retreat_button_icon_22x18.png", -26,25):addTo(button)
    return button
end

function GameUIWatchTower:RefreshOtherEvents()
    local other_events = Alliance_Manager:GetToMineMarchEvents()
    for _,entity in ipairs(other_events) do
        local item = self:GetOtherEventItem(entity)
        self.listView:addItem(item)
    end
end

function GameUIWatchTower:RefreshCurrentList()
    local tag = self:GetTabButton():GetSelectedButtonTag()
    if tag == 'comming' or tag == 'march' then
        self:RefreshListView(tag)
    end
end

--Observer Methods
function GameUIWatchTower:CheckNotHaveTheEventIf(event)
-- return self.march_timer_label[event:Id()] == nil
end

-- function GameUIWatchTower:OnHelpToTroopsChanged(changed_map)
--     self:RefreshCurrentList()
-- end

-- function GameUIWatchTower:OnCommingDataChanged()
--     self:RefreshCurrentList()
-- end

-- function GameUIWatchTower:OnMarchDataChanged()
--     self:RefreshCurrentList()
-- end
function GameUIWatchTower:OnAllianceDataChanged_marchEvents(alliance, deltaData)
    self:RefreshCurrentList()
end

function GameUIWatchTower:OnFightEventTimerChanged(fightEvent)
-- if self.shrine_timer_label[fightEvent:Id()] then
--     self.shrine_timer_label[fightEvent:Id()]:setString(GameUtils:formatTimeStyle1(fightEvent:GetTime()))
-- end
end
function GameUIWatchTower:OnAttackMarchEventTimerChanged(attackMarchEvent)
-- if self.march_timer_label[attackMarchEvent:Id()] then
--     self.march_timer_label[attackMarchEvent:Id()]:setString(GameUtils:formatTimeStyle1(attackMarchEvent:GetTime()))
-- end
end

-- function GameUIWatchTower:OnVillageEventTimer(villageEvent)
--     if self.village_process[villageEvent:Id()] then
--         self.village_process[villageEvent:Id()]:setPercentage(villageEvent:CollectPercent())
--     end
--     if self.village_labels[villageEvent:Id()] then
--         local str = string.format("%s/%s",string.formatnumberthousands(math.floor(villageEvent:CollectCount())),string.formatnumberthousands(villageEvent:VillageData().collectTotal))
--         self.village_labels[villageEvent:Id()]:setString(str)
--     end
-- end

function GameUIWatchTower:onCleanup()
    self:AddOrRemoveListener(false)
    GameUIWatchTower.super.onCleanup(self)
end
function GameUIWatchTower:GetUnlockPlayerSecondMarchQueuePrice()
    return unlockPlayerSecondMarchQueue_price - (250 * (User.countInfo.day14 - 1))
end
-- function GameUIWatchTower:GetAllianceBelvedere()
--     return self.belvedere
-- end

--event
--签到按钮
function GameUIWatchTower:OnSignButtonClikced()
    UIKit:newGameUI("GameUIActivityRewardNew",GameUIActivityRewardNew.REWARD_TYPE.CONTINUITY):AddToCurrentScene()
end

--内容过滤 这里被更改为显示坐标
function GameUIWatchTower:GetEntityFromCityName(entity)
    if entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT and entity:WithObject():MarchType() == "helpDefence" then
        return entity:GetDestinationLocation()
    end
    return entity:GetDestinationLocation()
end

function GameUIWatchTower:GetEntityAttackPlayerName(entity)
    return entity.attackPlayerData.name
        -- if entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT and entity:WithObject():MarchType() == "helpDefence" then
        --     return entity:GetAttackPlayerName()
        -- end
        -- local level = self:GetBuilding():GetLevel()
        -- if not self:GetAllianceBelvedere():CanDisplayCommingPlayerName(level) then
        --     return '?'
        -- else
        --     return entity:GetAttackPlayerName()
        -- end
end

function GameUIWatchTower:GetEntityDragonType(entity)
    if entity.eventType == "attackMarchEvents" and entity.marchType == "helpDefence" then
        return UtilsForEvent:GetDragonType(entity)
    end
    local level = Alliance_Manager:GetMyAlliance():GetAllianceBuildingInfoByName("watchTower").level
    if level >= 2 then
        return UtilsForEvent:GetDragonType(entity)
    else
        return '?'
    end
end

-- function GameUIWatchTower:CanViewEventDetail()
--     local level = self:GetBuilding():GetLevel()
--     return self:GetAllianceBelvedere():CanViewEventDetail(level)
-- end
function GameUIWatchTower:OnSpeedUpButtonClicked(entity)
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "warSpeedupClass_1",
        event = entity,
        eventType = entity.eventType,
    })
    widgetUseItems:AddToCurrentScene()
end

function GameUIWatchTower:OnRetreatButtonClicked(entity,cb)
    if entity.eventType == "helpToTroops" then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromHelpedAllianceMemberPromise(entity.id)
                :done(function()
                    cb(true)
                end)
                :fail(function()
                    cb(false)
                end)
        end)
    elseif entity.eventType == "villageEvents" then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromVillagePromise(entity.id)
                :done(function()
                    cb(true)
                end):fail(function()
                cb(false)
                end)
        end)
    elseif entity.eventType == "strikeMarchEvents" or entity.eventType == "attackMarchEvents" then
        local widgetUseItems = WidgetUseItems.new():Create({
            item_name = "retreatTroop",
            event = entity,
            eventType = entity.eventType,
        })
        widgetUseItems:AddToCurrentScene()
    end
end

return GameUIWatchTower






