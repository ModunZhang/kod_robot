--
-- Author: Danny He
-- Date: 2015-04-21 14:57:48
--
local GameUIWathTowerRegion = UIKit:createUIClass('GameUIWathTowerRegion',"GameUIWithCommonHeader")
local Localize = import("..utils.Localize")
local AllianceBelvedere = import("..entity.AllianceBelvedere")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UILib = import(".UILib")
local GameUIWatchTowerTroopDetail = import(".GameUIWatchTowerTroopDetail")
local WidgetUseItems = import("..widget.WidgetUseItems")
local config_day14 = GameDatas.Activities.day14
local SpriteConfig = import("..sprites.SpriteConfig")
local unlockPlayerSecondMarchQueue_price = GameDatas.PlayerInitData.intInit.unlockPlayerSecondMarchQueue.value
local GameUIActivityRewardNew = import(".GameUIActivityRewardNew")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")

function GameUIWathTowerRegion:ctor(city,default_tab)
    default_tab = default_tab or 'march'
    GameUIWathTowerRegion.super.ctor(self,city,_("战斗"))
    self.belvedere = Alliance_Manager:GetMyAlliance():GetAllianceBelvedere()
    self.default_tab = default_tab
    self.building = self:GetCity():GetFirstBuildingByType("watchTower")
end

function GameUIWathTowerRegion:GetBuilding()
    return self.building
end

function GameUIWathTowerRegion:GetCity()
    return self.city
end

function GameUIWathTowerRegion:OnMoveInStage()
    GameUIWathTowerRegion.super.OnMoveInStage(self)
    self:ResetTimerNodeTable()
    self:CreateUI()
    self:AddOrRemoveListener(true)
end

function GameUIWathTowerRegion:CreateUI()
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

function GameUIWathTowerRegion:TabButtonsAction(tag)
    if tag == 'comming'
        or tag == 'march' then
        self.list_node:show()
        self:RefreshListView(tag)
    else
        self.list_node:hide()
    end
end

function GameUIWathTowerRegion:AddOrRemoveListener(isAdd)
    if isAdd then
        City:AddListenOnType(self,City.LISTEN_TYPE.HELPED_TO_TROOPS)
        self:GetAllianceBelvedere():AddListenOnType(self, AllianceBelvedere.LISTEN_TYPE.CheckNotHaveTheEventIf)
        self:GetAllianceBelvedere():AddListenOnType(self, AllianceBelvedere.LISTEN_TYPE.OnCommingDataChanged)
        self:GetAllianceBelvedere():AddListenOnType(self, AllianceBelvedere.LISTEN_TYPE.OnMarchDataChanged)
        self:GetAllianceBelvedere():AddListenOnType(self, AllianceBelvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
        self:GetAllianceBelvedere():AddListenOnType(self, AllianceBelvedere.LISTEN_TYPE.OnVillageEventTimer)
        self:GetAllianceBelvedere():AddListenOnType(self, AllianceBelvedere.LISTEN_TYPE.OnFightEventTimerChanged)
    else
        City:RemoveListenerOnType(self,City.LISTEN_TYPE.HELPED_TO_TROOPS)
        self:GetAllianceBelvedere():RemoveListenerOnType(self, AllianceBelvedere.LISTEN_TYPE.CheckNotHaveTheEventIf)
        self:GetAllianceBelvedere():RemoveListenerOnType(self, AllianceBelvedere.LISTEN_TYPE.OnCommingDataChanged)
        self:GetAllianceBelvedere():RemoveListenerOnType(self, AllianceBelvedere.LISTEN_TYPE.OnMarchDataChanged)
        self:GetAllianceBelvedere():RemoveListenerOnType(self, AllianceBelvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
        self:GetAllianceBelvedere():RemoveListenerOnType(self, AllianceBelvedere.LISTEN_TYPE.OnVillageEventTimer)
        self:GetAllianceBelvedere():RemoveListenerOnType(self, AllianceBelvedere.LISTEN_TYPE.OnFightEventTimerChanged)
    end
end

--ui
function GameUIWathTowerRegion:RefreshListView(tag)
    self:ResetTimerNodeTable()
    self.listView:removeAllItems()
    if tag == 'march' then
        self:RefreshMyEvents()
    else
        self:RefreshOtherEvents()
    end
    self.listView:reload()
end

function GameUIWathTowerRegion:ResetTimerNodeTable()
    self.village_process = {}
    self.village_labels  = {}
    self.march_timer_label={}
    self.shrine_timer_label={}
end


function GameUIWathTowerRegion:RefreshMyEvents()
    local my_events = self:GetAllianceBelvedere():GetMyEvents()
    for index = 1,2 do
        local item
        if index == 1 then
            if my_events[1] then
                item = self:GetMyEventItemWithIndex(1,true,my_events[1])
            else
                item = self:GetMyEventItemWithIndex(1,true)
            end
        else
            if self:GetAllianceBelvedere():GetMarchLimit() == 1 then -- 只有一条队列
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
function GameUIWathTowerRegion:GetMyEventItemWithIndex(index,isOpen,entity)
    local item = self.listView:newItem()
    local bg = WidgetUIBackGround.new({width = 568,height = 204},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg  = display.newSprite("title_blue_558x34.png")
        :align(display.TOP_CENTER,284, 198)
        :addTo(bg)
    if entity then
        display.newSprite("info_16x33.png"):align(display.RIGHT_CENTER,540, 17):addTo(title_bg):scale(26/33)
        WidgetPushTransparentButton.new(cc.rect(0,0,558,34))
            :addTo(title_bg):align(display.LEFT_BOTTOM, 0, 0)
            :onButtonClicked(function()
                UIKit:newGameUI("GameUIWatchTowerMyTroopsDetail",entity):AddToCurrentScene(true)
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
        local countInfo = User:GetCountInfo()
        tile_label:setString(_("未解锁"))
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
                if unlockPlayerSecondMarchQueue_price > User:GetGemResource():GetValue() then
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
                        GameGlobalUI:showTips(_("提示"),_("永久行军队列+1"),name,event_name)
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
            text = unlockPlayerSecondMarchQueue_price,
            size = 18,
            color = 0xffd200,
        }):align(display.LEFT_CENTER, 50 , num_bg:getContentSize().height/2)
            :addTo(num_bg)

        UIKit:ttfLabel({
            text = string.format(_("累计签到%s天，永久+1进攻队列"),#config_day14 ),
            size = 22,
            color= 0x403c2f
        }):addTo(bg):align(display.LEFT_TOP, 164, event_bg:getPositionY() + 118)
        display.newSprite(string.format("player_queue_seq_%d_112x112.png",index), 67, 67):addTo(event_bg)
    else
        if not entity then
            tile_label:setString(_("待命中"))
            WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
                :setButtonLabel(
                    UIKit:commonButtonLable({
                        text = _("前往")
                    })
                )
                :align(display.RIGHT_BOTTOM,555,10)
                :onButtonClicked(function(event)
                    self:LeftButtonClicked()
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
                text = entity:GetDestination(),
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
                text = entity:GetDestinationLocation(),
                size = 20,
                color= 0x403c2f
            }):align(display.RIGHT_TOP,554,115):addTo(bg)
            tile_label:setString(entity:GetTitle())
            if entity:GetTypeStr() == 'HELPTO' then
                local button = self:GetYellowRetreatButton():pos(558,15):addTo(bg)
                    :onButtonClicked(function(event)
                        self:OnRetreatButtonClicked(entity,function(success)
                            if success then
                                self:RefreshListView('march')
                            end
                        end)
                    end)
                local dragon_png = UILib.dragon_head[entity:GetDragonType()]
                if dragon_png then
                    local icon_bg = display.newSprite("dragon_bg_114x114.png", 67, 67):addTo(event_bg)
                    display.newSprite(dragon_png, 57, 60):addTo(icon_bg)
                else
                    display.newSprite("unknown_dragon_icon_112x112.png", 67, 67):addTo(event_bg)
                end
            elseif entity:GetTypeStr() == 'COLLECT' then
                self:GetYellowRetreatButton():pos(558,15):addTo(bg)
                    :onButtonClicked(function(event)
                        self:OnRetreatButtonClicked(entity,function(success)
                            if success then
                                self:RefreshListView('march')
                            end
                        end)
                    end)
                local image = SpriteConfig[entity:WithObject():VillageData().name]:GetConfigByLevel(entity:WithObject():VillageData().level).png
                local icon = display.newSprite(image, 67, 67):addTo(event_bg)
                icon:setScale(120/150)
                local process_bg = display.newSprite("process_bg_village_collect_326x40.png"):align(display.LEFT_BOTTOM,164, 20):addTo(bg)
                local progress_timer = UIKit:commonProgressTimer("process_color_village_collect_326x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(process_bg)
                progress_timer:setPercentage(entity:WithObject():CollectPercent())
                local process_label = UIKit:ttfLabel({
                    text =  math.floor(entity:WithObject():CollectCount()) .. "/" .. entity:WithObject():VillageData().collectTotal,
                    size = 20,
                    color= 0xfff3c7,
                    shadow= true
                }):align(display.LEFT_CENTER, 20, 20):addTo(process_bg)
                self.village_process[entity:WithObject():Id()] = progress_timer
                self.village_labels[entity:WithObject():Id()] = process_label
            elseif entity:GetTypeStr() == 'MARCH_OUT'
                or entity:GetTypeStr() == 'MARCH_RETURN'
                or entity:GetTypeStr() == 'STRIKE_OUT'
                or entity:GetTypeStr() == 'STRIKE_RETURN'
                or entity:GetTypeStr() == 'SHIRNE'
            then
                local dragon_png = UILib.dragon_head[entity:GetDragonType()]
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
                    text = GameUtils:formatTimeStyle1(entity:WithObject():GetTime()),
                    size = 22,
                    color= 0x403c2f
                }):addTo(bg):align(display.LEFT_BOTTOM,164+ icon_bg:getCascadeBoundingBox().width+8, 20)
                if "SHIRNE" ~= entity:GetTypeStr() then
                    self.march_timer_label[entity:WithObject():Id()] = timer_label
                    WidgetPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}):setButtonLabel(
                        UIKit:commonButtonLable({
                            text = _("加速")
                        }))
                        :align(display.RIGHT_BOTTOM,555,10):addTo(bg)
                        :onButtonClicked(function(event)
                            self:OnSpeedUpButtonClicked(entity)
                        end)
                else
                    self.shrine_timer_label[entity:WithObject():Id()] = timer_label
                end
                if entity:GetTypeStr() ~= "MARCH_RETURN" and "STRIKE_RETURN" ~= entity:GetTypeStr() and entity:GetTypeStr() ~= 'SHIRNE' then
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

function GameUIWathTowerRegion:GetOtherEventItem(entity)
    local item = self.listView:newItem()
    local bg = WidgetUIBackGround.new({width = 568,height = 204},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_image = entity:WithObject():MarchType() == 'helpDefence' and 'title_green_558x34.png' or 'title_red_558x34.png'
    local title_bg  = display.newSprite(title_image)
        :align(display.TOP_CENTER,284, 198)
        :addTo(bg)
    local tile_label = UIKit:ttfLabel({
        text = entity:GetTitle(),
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
        text = self:GetEntityFromCityName(entity),
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
        text = GameUtils:formatTimeStyle1(entity:WithObject():GetTime()),
        size = 22,
        color= 0x403c2f
    }):addTo(bg):align(display.LEFT_BOTTOM,164+ icon_bg:getCascadeBoundingBox().width+8, 20)
    self.march_timer_label[entity:WithObject():Id()] = timer_label
    --如果瞭望塔达到等级或者是盟友对我的协助
    if self:CanViewEventDetail() or (entity:GetTypeStr() == 'MARCH_OUT' and entity:WithObject():MarchType() == 'helpDefence') then
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

function GameUIWathTowerRegion:OnEventDetailButtonClicked(entity)
    local strEntityType = entity:GetType()
    if strEntityType == entity.ENTITY_TYPE.MARCH_OUT then
        if entity:WithObject():MarchType() == "helpDefence" then
            NetManager:getHelpDefenceMarchEventDetailPromise(entity:WithObject():Id(),Alliance_Manager:GetMyAlliance():Id()):done(function(response)
                UIKit:newGameUI("GameUIWatchTowerTroopDetail",GameUIWatchTowerTroopDetail.DATA_TYPE.MARCH,response.msg.eventDetail,User:Id())
                    :AddToCurrentScene(true)
            end)
        else
            local my_status = Alliance_Manager:GetMyAlliance():Status()
            if my_status == "prepare" or  my_status == "fight" then
                local __,alliance_id = entity:WithObject():FromLocation()
                NetManager:getAttackMarchEventDetailPromise(entity:WithObject():Id(),alliance_id):done(function(response)
                    UIKit:newGameUI("GameUIWatchTowerTroopDetail",GameUIWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE,response.msg.eventDetail,User:Id())
                        :AddToCurrentScene(true)
                end)
            else
                UIKit:showMessageDialog(_("错误"),_("联盟未处于战争期"),function()end)
            end
        end
    elseif strEntityType == entity.ENTITY_TYPE.STRIKE_OUT then
        local my_status = Alliance_Manager:GetMyAlliance():Status()
        if my_status == "prepare" or  my_status == "fight" then
            local __,alliance_id = entity:WithObject():FromLocation()
            NetManager:getStrikeMarchEventDetailPromise(entity:WithObject():Id(),alliance_id):done(function(response)
                UIKit:newGameUI("GameUIWatchTowerTroopDetail",GameUIWatchTowerTroopDetail.DATA_TYPE.STRIKE,response.msg.eventDetail,User:Id())
                    :AddToCurrentScene(true)
            end)
        else
            UIKit:showMessageDialog(_("错误"),_("联盟未处于战争期"),function()end)
        end
    end
end

function GameUIWathTowerRegion:GetYellowRetreatButton()
    local button = WidgetPushButton.new({normal = "retreat_yellow_button_n_52x50.png",pressed = "retreat_yellow_button_h_52x50.png"})
        :align(display.RIGHT_BOTTOM,0,0)
    display.newSprite("retreat_button_icon_22x18.png", -26,25):addTo(button)
    return button
end

function GameUIWathTowerRegion:GetRedRetreatButton()
    local button = WidgetPushButton.new({normal = "retreat_red_button_n_52x50.png",pressed = "retreat_red_button_h_52x50.png"})
        :align(display.RIGHT_BOTTOM,0,0)
    display.newSprite("retreat_button_icon_22x18.png", -26,25):addTo(button)
    return button
end

function GameUIWathTowerRegion:RefreshOtherEvents()
    local other_events = self:GetAllianceBelvedere():GetOtherEvents()
    for _,entity in ipairs(other_events) do
        local item = self:GetOtherEventItem(entity)
        self.listView:addItem(item)
    end
end

function GameUIWathTowerRegion:GetTabButton()
    return self.tabButton
end

function GameUIWathTowerRegion:RefreshCurrentList()
    local tag = self:GetTabButton():GetSelectedButtonTag()
    if tag == 'comming' or tag == 'march' then
        self:RefreshListView(tag)
    end
end

--Observer Methods
function GameUIWathTowerRegion:CheckNotHaveTheEventIf(event)
    return self.march_timer_label[event:Id()] == nil
end

function GameUIWathTowerRegion:OnHelpToTroopsChanged(changed_map)
    self:RefreshCurrentList()
end

function GameUIWathTowerRegion:OnCommingDataChanged()
    self:RefreshCurrentList()
end

function GameUIWathTowerRegion:OnMarchDataChanged()
    self:RefreshCurrentList()
end

function GameUIWathTowerRegion:OnFightEventTimerChanged(fightEvent)
    if self.shrine_timer_label[fightEvent:Id()] then
        self.shrine_timer_label[fightEvent:Id()]:setString(GameUtils:formatTimeStyle1(fightEvent:GetTime()))
    end
end
function GameUIWathTowerRegion:OnAttackMarchEventTimerChanged(attackMarchEvent)
    if self.march_timer_label[attackMarchEvent:Id()] then
        self.march_timer_label[attackMarchEvent:Id()]:setString(GameUtils:formatTimeStyle1(attackMarchEvent:GetTime()))
    end
end

function GameUIWathTowerRegion:OnVillageEventTimer(villageEvent)
    if self.village_process[villageEvent:Id()] then
        self.village_process[villageEvent:Id()]:setPercentage(villageEvent:CollectPercent())
    end
    if self.village_labels[villageEvent:Id()] then
        self.village_labels[villageEvent:Id()]:setString(math.floor(villageEvent:CollectCount()) .. "/" .. villageEvent:VillageData().collectTotal)
    end
end

function GameUIWathTowerRegion:onCleanup()
    self:AddOrRemoveListener(false)
    GameUIWathTowerRegion.super.onCleanup(self)
end

function GameUIWathTowerRegion:GetAllianceBelvedere()
    return self.belvedere
end

--event
--签到按钮
function GameUIWathTowerRegion:OnSignButtonClikced()
    UIKit:newGameUI("GameUIActivityRewardNew",GameUIActivityRewardNew.REWARD_TYPE.CONTINUITY):AddToCurrentScene()
end

--内容过滤
function GameUIWathTowerRegion:GetEntityFromCityName(entity)
    if entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT and entity:WithObject():MarchType() == "helpDefence" then
        return entity:GetDestinationLocation()
    end
    return entity:GetDestinationLocation()
end

function GameUIWathTowerRegion:GetEntityAttackPlayerName(entity)
    if entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT and entity:WithObject():MarchType() == "helpDefence" then
        return entity:GetAttackPlayerName()
    end
    local level = self:GetBuilding():GetLevel()
    if not self:GetAllianceBelvedere():CanDisplayCommingPlayerName(level) then
        return '?'
    else
        return entity:GetAttackPlayerName()
    end
end

function GameUIWathTowerRegion:GetEntityDragonType(entity)
    if entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT and entity:WithObject():MarchType() == "helpDefence" then
        return entity:GetDragonType()
    end
    local level = self:GetBuilding():GetLevel()
    if not self:GetAllianceBelvedere():CanDisplayCommingDragonType(level) then
        return '?'
    else
        return entity:GetDragonType()
    end
end

function GameUIWathTowerRegion:CanViewEventDetail()
    local level = self:GetBuilding():GetLevel()
    return self:GetAllianceBelvedere():CanViewEventDetail(level)
end
function GameUIWathTowerRegion:OnSpeedUpButtonClicked(entity)
    local widgetUseItems = WidgetUseItems.new():Create({
        item_type = WidgetUseItems.USE_TYPE.WAR_SPEEDUP_CLASS,
        event = entity
    })
    widgetUseItems:AddToCurrentScene()
end

function GameUIWathTowerRegion:OnRetreatButtonClicked(entity,cb)
    if entity:GetType() == entity.ENTITY_TYPE.HELPTO then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromHelpedAllianceMemberPromise(entity:WithObject().beHelpedPlayerData.id)
                :done(function()
                    cb(true)
                end)
                :fail(function()
                    cb(false)
                end)
        end)
    elseif entity:GetType() == entity.ENTITY_TYPE.COLLECT then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromVillagePromise(entity:WithObject():VillageData().alliance.id,entity:WithObject():Id())
                :done(function()
                    cb(true)
                end):fail(function()
                cb(false)
                end)
        end)
    elseif entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT  or entity:GetType() == entity.ENTITY_TYPE.STRIKE_OUT then
        local widgetUseItems = WidgetUseItems.new():Create({
            item_type = WidgetUseItems.USE_TYPE.RETREAT_TROOP,
            event = entity
        })
        widgetUseItems:AddToCurrentScene()
    end
end

return GameUIWathTowerRegion

