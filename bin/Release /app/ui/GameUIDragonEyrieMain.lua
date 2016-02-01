--
-- Author: Danny He
-- Date: 2014-10-28 16:14:06
--
local GameUIDragonEyrieMain = UIKit:createUIClass("GameUIDragonEyrieMain","GameUIUpgradeBuilding")
local GameUtils = GameUtils
local window = import("..utils.window")
local GameUINpc = import(".GameUINpc")
local TutorialLayer = import(".TutorialLayer")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local StarBar = import(".StarBar")
local DragonManager = import("..entity.DragonManager")
local WidgetDragons = import("..widget.WidgetDragons")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetProgress = import("..widget.WidgetProgress")
local DragonSprite = import("..sprites.DragonSprite")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUseItems = import("..widget.WidgetUseItems")
local GameUIDragonDeathSpeedUp = import(".GameUIDragonDeathSpeedUp")
local UICheckBoxButton = import(".UICheckBoxButton")

-- lockDragon: 是否锁定选择龙的操作,默认不锁定
function GameUIDragonEyrieMain:ctor(city,building,default_tab,lockDragon,fte_dragon_type)
    GameUIDragonEyrieMain.super.ctor(self,city,_("龙巢"),building,default_tab)
    self.building = building
    self.city = city
    self.draong_index = 1
    self.dragon_manager = building:GetDragonManager()
    if type(lockDragon) ~= "boolean" then lockDragon = false end
    self.lockDragon = lockDragon
    self.fte_dragon_type = fte_dragon_type
end

function GameUIDragonEyrieMain:IsDragonLock()
    return self.lockDragon
end

-- event
------------------------------------------------------------------
function GameUIDragonEyrieMain:OnHPChanged()
    local dragon = self:GetCurrentDragon()
    if not dragon:Ishated() then return end
    if self.dragon_hp_label and self.dragon_hp_label:isVisible() then
        self.dragon_hp_label:setString(string.formatnumberthousands(dragon:Hp()) .. "/" .. string.formatnumberthousands(dragon:GetMaxHP()))
        self.progress_hated:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
    end
end

function GameUIDragonEyrieMain:OnDragonHatched(dragon)
    local dragon_index = self.dragon_manager:GetDragonIndexByType(dragon:Type())
    local localIndex = dragon_index - 1
    local eyrie = self.draongContentNode:GetItemByIndex(localIndex)
    eyrie.dragon_image:hide()
    eyrie.armature:show()
    eyrie.armature:Resume()
    self:RefreshUI()
end

function GameUIDragonEyrieMain:OnBasicChanged(dragon)
    self:RefreshUI()
end
function GameUIDragonEyrieMain:OnUserDataChanged_buildings(userData, deltaData)
    local ok,value = deltaData("buildings.location_4")
    if ok then
        self.hate_button:setButtonEnabled(self.building:CheckIfHateDragon())
    end
end
-- function GameUIDragonEyrieMain:OnDragonEventChanged()
--     local dragonEvent = self.dragon_manager:GetDragonEventByDragonType(self:GetCurrentDragon():Type())
--     if dragonEvent then
--         self:RefreshUI()
--     end
-- end
function GameUIDragonEyrieMain:OnDragonDeathEventChanged()
    local dragonDeathEvent = self.dragon_manager:GetDragonDeathEventByType(self:GetCurrentDragon():Type())
    if dragonDeathEvent then
        self:RefreshUI()
    end
end

function GameUIDragonEyrieMain:OnDragonDeathEventRefresh(dragonDeathEvents)
    self:RefreshUI()
end

function GameUIDragonEyrieMain:OnDragonDeathEventTimer(dragonDeathEvent)
    if self:GetCurrentDragon():Type() == dragonDeathEvent:DragonType()
        and self.progress_content_death
        and self.progress_content_death:isVisible()
    then
        self.progress_death:setPercentage(dragonDeathEvent:GetPercent())
        self.dragon_death_label:setString(GameUtils:formatTimeStyleDayHour(dragonDeathEvent:GetTime()))
    end
end

-- function GameUIDragonEyrieMain:OnDragonEventTimer(dragonEvent)
--     if self:GetCurrentDragon():Type() == dragonEvent:DragonType() and self.hate_event_node then
--         local timer_text = GameUtils:formatTimeStyleDayHour(dragonEvent:GetTime())
--         self.hate_event_node:SetProgressInfo(timer_text,dragonEvent:GetPercent())
--     end
-- end

------------------------------------------------------------------

function GameUIDragonEyrieMain:CreateBetweenBgAndTitle()
    GameUIDragonEyrieMain.super.CreateBetweenBgAndTitle(self)
    self.dragonNode = display.newNode():size(window.width,window.height):addTo(self:GetView())
end


function GameUIDragonEyrieMain:OnMoveInStage()
    self:CreateUI()
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnHPChanged)
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonHatched)
    -- self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonEventTimer)
    -- self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonEventChanged)
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventChanged)
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventRefresh)
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventTimer)
    User:AddListenOnType(self, "buildings")
    GameUIDragonEyrieMain.super.OnMoveInStage(self)
end

-- if building:GetType() == self:GetBuilding():GetType() then
--     if self.dragon_hp_recovery_count_label then
--         local dragon_hp_recovery = self:GetBuilding():GetTotalHPRecoveryPerHour(self:GetCurrentDragon():Type())
--         self.dragon_hp_recovery_count_label:setString(string.format("+%s/h",string.formatnumberthousands(dragon_hp_recovery)))
--     end
--     self.hate_button:setButtonEnabled(self.building:CheckIfHateDragon())
-- end


function GameUIDragonEyrieMain:OnMoveOutStage()
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnHPChanged)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonHatched)
    -- self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonEventTimer)
    -- self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonEventChanged)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventChanged)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventRefresh)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventTimer)
    User:RemoveListenerOnType(self, "buildings")
    GameUIDragonEyrieMain.super.OnMoveOutStage(self)
end

function GameUIDragonEyrieMain:CreateUI()
    self.tabButton = self:CreateTabButtons({
        {
            label = _("龙"),
            tag = "dragon",
        }
    },
    function(tag)
        self:TabButtonsAction(tag)
    end):pos(window.cx, window.bottom + 34)
end

function GameUIDragonEyrieMain:TabButtonsAction(tag)
    if tag == 'dragon' then
        self:CreateDragonContentNodeIf()
        self:RefreshUI()
        self.dragonNode:show()
    else
        self.dragonNode:hide()
    end
end

function GameUIDragonEyrieMain:RefreshUI()
    local dragon = self:GetCurrentDragon()
    if not self.dragon_info then return end
    if not self:GetCurrentDragon():Ishated() then
        self.garrison_button:setButtonSelected(false)
        self.dragon_info:hide()
        self.death_speed_button:hide()
        self.progress_content_death:hide()
        -- local dragonEvent = self.dragon_manager:GetDragonEventByDragonType(self:GetCurrentDragon():Type())
        self.progress_content_hated:hide()
        self.info_panel:hide()
        self.draogn_hate_node:show()
        self.star_bar:hide()
        -- if dragonEvent then
        -- local timer_text = GameUtils:formatTimeStyleDayHour(dragonEvent:GetTime())
        -- self.hate_timer_label:hide()
        -- self.hate_button:hide()
        -- self.hate_event_node:show()
        -- self.hate_event_node:SetProgressInfo(timer_text,dragonEvent:GetPercent())
        -- else
        self.hate_button:show()
        -- self.hate_event_node:hide()
        -- local timer_text = GameUtils:formatTimeStyleDayHour(self.dragon_manager:GetHateNeedMinutes(self:GetCurrentDragon():Type()) * 60)
        -- self.hate_timer_label:setString(string.format(_("需要时间: %s"),timer_text))
        -- end
    else
        self.star_bar:setNum(dragon:Star())
        self.star_bar:show()
        self.draogn_hate_node:hide()
        self.garrison_button:setButtonSelected(dragon:IsDefenced())
        self.info_panel:show()
        self.strength_val_label:setString(string.formatnumberthousands(dragon:TotalStrength()))
        self.vitality_val_label:setString(string.formatnumberthousands(dragon:TotalVitality()))
        self.leadership_val_label:setString(string.formatnumberthousands(dragon:TotalLeadership()))
        if dragon:IsDead() then
            local dragonDeathEvent = self.dragon_manager:GetDragonDeathEventByType(self:GetCurrentDragon():Type())
            if dragonDeathEvent then
                self.progress_death:setPercentage(dragonDeathEvent:GetPercent())
                self.dragon_death_label:setString(GameUtils:formatTimeStyleDayHour(dragonDeathEvent:GetTime()))
            end
            self.death_speed_button:show()
            self.progress_content_death:show()
            self.progress_content_hated:hide()
            self.state_label:setString(Localize.dragon_status['dead'])
            self.state_label:setColor(UIKit:hex2c3b(0x7e0000))

        else
            self.dragon_info:show()
            self.progress_content_hated:show()
            local dragon_hp_recovery = self:GetBuilding():GetTotalHPRecoveryPerHour(dragon:Type())
            self.dragon_hp_recovery_count_label:setString(string.format("+%s/h", dragon:Status()~= "march" and string.formatnumberthousands(dragon_hp_recovery) or 0))
            self.dragon_hp_label:setString(string.formatnumberthousands(dragon:Hp()) .. "/" .. string.formatnumberthousands(dragon:GetMaxHP()))
            self.progress_hated:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
            self.state_label:setString(Localize.dragon_status[dragon:Status()])
            if dragon:IsDefenced() or dragon:IsFree() then
                self.state_label:setColor(UIKit:hex2c3b(0x07862b))
            else
                self.state_label:setColor(UIKit:hex2c3b(0x7e0000))
            end
            self.death_speed_button:hide()
            self.progress_content_death:hide()
        end
        self.draong_info_lv_label:setString("LV " .. dragon:Level() .. "/" .. dragon:GetMaxLevel())
        self.draong_info_xp_label:setString(string.formatnumberthousands(dragon:Exp()) .. "/" .. string.formatnumberthousands(dragon:GetMaxExp()))
        -- self.expIcon:setPositionX(self.draong_info_xp_label:getPositionX() - self.draong_info_xp_label:getContentSize().width/2 - 10)
        -- self.exp_add_button:setPositionX(self.draong_info_xp_label:getPositionX() + self.draong_info_xp_label:getContentSize().width/2 + 10)
    end
    self.nameLabel:setString(dragon:GetLocalizedName())
end

function GameUIDragonEyrieMain:CreateProgressTimer()
    local bg,progressTimer = nil,nil
    bg = display.newSprite("process_bar_540x40.png")
    progressTimer = UIKit:commonProgressTimer("progress_bar_540x40_2.png"):addTo(bg):align(display.LEFT_CENTER,0,20)
    progressTimer:setPercentage(0)
    local iconbg = display.newSprite("drgon_process_icon_bg.png")
        :addTo(bg)
        :align(display.LEFT_BOTTOM, -13,-2)
    display.newSprite("dragon_lv_icon.png")
        :addTo(iconbg)
        :pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
    self.dragon_hp_label = UIKit:ttfLabel({
        text = "",
        color = 0xfff3c7,
        shadow = true,
        size = 20
    }):addTo(bg):align(display.LEFT_CENTER, 40, 20)

    self.dragon_hp_recovery_count_label = UIKit:ttfLabel({
        text =  "",
        color = 0xfff3c7,
        shadow = true,
        size = 20
    }):addTo(bg):align(display.RIGHT_CENTER, bg:getContentSize().width - 50, 20)
    local add_button = WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
        :addTo(bg)
        :align(display.CENTER_RIGHT,bg:getContentSize().width+10,20)
        :onButtonClicked(function()
            self:OnDragonHpItemUseButtonClicked()
        end)
    return bg,progressTimer
end

function GameUIDragonEyrieMain:CreateDeathEventProgressTimer()
    local bg,progressTimer = nil,nil
    bg = display.newSprite("progress_bar_364x40_1.png")
    progressTimer = UIKit:commonProgressTimer("progress_bar_yellow_364x40.png"):addTo(bg):align(display.LEFT_CENTER,0,20)
    progressTimer:setPercentage(0)
    local icon_bg = display.newSprite("back_ground_43x43.png"):align(display.LEFT_CENTER, -20, 20):addTo(bg)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg):scale(0.8)
    self.dragon_death_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0xfff3c7,
        shadow= true
    }):addTo(bg):align(display.LEFT_CENTER, 50,20)
    return bg,progressTimer
end

function GameUIDragonEyrieMain:CreateDragonContentNodeIf()
    if not self.draongContentNode then
        self:CreateDragonHateNodeIf()
        local dragonAnimateNode,draongContentNode = self:CreateDragonScrollNode()
        self.draongContentNode = draongContentNode
        self.draongContentNode:SetScrollable(not self:IsDragonLock())
        dragonAnimateNode:addTo(self.dragonNode):pos(window.cx - 310,window.top_bottom - 576)
        -- 阻挡滑动龙超出的区域
        display.newLayer():addTo(self.dragonNode):pos(window.cx - 310,window.top_bottom - 676):size(620,100)
        --info
        local info_bg = display.newSprite("dragon_info_bg_290x92.png")
            :align(display.BOTTOM_CENTER, 309, 50)
            :addTo(dragonAnimateNode)
        local lv_bg = display.newSprite("dragon_lv_bg_270x30.png")
            :addTo(info_bg)
            :align(display.TOP_CENTER,info_bg:getContentSize().width/2,info_bg:getContentSize().height-10)
        info_bg:setTouchEnabled(true)
        self.dragon_info = info_bg
        self.draong_info_lv_label = UIKit:ttfLabel({
            text = "LV " .. self:GetCurrentDragon():Level() .. "/" .. self:GetCurrentDragon():GetMaxLevel(),
            color = 0xffedae,
            size = 20
        }):addTo(lv_bg):align(display.CENTER,lv_bg:getContentSize().width/2,lv_bg:getContentSize().height/2)
        self.draong_info_xp_label = UIKit:ttfLabel({
            text = self:GetCurrentDragon():Exp() .. "/" .. self:GetCurrentDragon():GetMaxExp(),
            color = 0x403c2f,
            size = 20,
            align = cc.TEXT_ALIGNMENT_CENTER,
        }):align(display.CENTER_BOTTOM, 145, 20):addTo(info_bg)
        local expIcon = display.newSprite("upgrade_experience_icon.png")
            :addTo(info_bg)
            :scale(0.7)
            :align(display.BOTTOM_LEFT, 10,9)
        self.expIcon = expIcon
        local add_button = WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
            :addTo(info_bg)
            :scale(0.8)
            :align(display.RIGHT_CENTER,info_bg:getContentSize().width - 10,9 + expIcon:getCascadeBoundingBox().height/2)
            :onButtonClicked(function()
                self:OnDragonExpItemUseButtonClicked()
            end)
        self.exp_add_button = add_button
        -- info end
        self.nextButton = cc.ui.UIPushButton.new({
            normal = "dragon_next_icon_28x31.png"
        })
            :addTo(dragonAnimateNode)
            :align(display.BOTTOM_CENTER, 306+170,80)
            :onButtonClicked(function()
                self:ChangeDragon('next')
            end)
        self.preButton = cc.ui.UIPushButton.new({
            normal = "dragon_next_icon_28x31.png"
        })
            :addTo(dragonAnimateNode)
            :align(display.TOP_CENTER, 306-170,80)
            :onButtonClicked(function()
                self:ChangeDragon('pre')
            end)
        self.preButton:setRotation(180)

        local info_layer = UIKit:shadowLayer():size(619,40):pos(window.left+10,dragonAnimateNode:getPositionY()):addTo(self.dragonNode)
        display.newSprite("line_624x58.png"):align(display.LEFT_TOP,0,20):addTo(info_layer)
        local nameLabel = UIKit:ttfLabel({
            text = "",
            color = 0xffedae,
            size  = 24
        }):addTo(info_layer):align(display.LEFT_CENTER,20, 20)
        local star_bar = StarBar.new({
            max = self:GetCurrentDragon():MaxStar(),
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = self:GetCurrentDragon():Star(),
            margin = 0,
        }):addTo(info_layer):align(display.RIGHT_CENTER, 610,20)
        self.nameLabel = nameLabel
        self.star_bar = star_bar
        --驻防
        local checkbox_image = {on = "draon_garrison_btn_d_82x86.png",off = "draon_garrison_btn_n_82x86.png",}
        local dragon = self:GetCurrentDragon()
        self.garrison_button = UICheckBoxButton.new(checkbox_image)
            :addTo(dragonAnimateNode):align(display.LEFT_BOTTOM, 25, 310)
            :setButtonSelected(dragon:IsDefenced())
            :onButtonClicked(function()
                local target = self.garrison_button:isButtonSelected()
                self.garrison_button:setButtonSelected(false)
                local dragon = self:GetCurrentDragon()
                if target then
                    if not dragon:Ishated() then
                        UIKit:showMessageDialog(nil,_("龙还未孵化"))
                        self.garrison_button:setButtonSelected(not target,false)
                        return
                    end
                    if dragon:IsDead() then
                        UIKit:showMessageDialog(nil,_("选择的龙已经死亡"))
                        self.garrison_button:setButtonSelected(not target,false)
                        return
                    end
                    if dragon:IsFree() then
                        -- local total_soldiers = {}
                        -- local final_soldiers = {}
                        -- local max_soldiers_citizen = 0
                        -- for soldier_name,count in pairs(User.soldiers) do
                        --     max_soldiers_citizen = max_soldiers_citizen + User:GetSoldierConfig(soldier_name).citizen * count
                        --     table.insert(total_soldiers, {name = soldier_name,count = count})
                        -- end
                        -- if User.defenceTroop and User.defenceTroop ~= json.null then
                        --     for __,soldier in ipairs(User.defenceTroop.soldiers) do
                        --         max_soldiers_citizen = max_soldiers_citizen + User:GetSoldierConfig(soldier.name).citizen * soldier.count
                        --         for i,t_soldier in ipairs(total_soldiers) do
                        --             if soldier.name == t_soldier.name then
                        --                 t_soldier.count = t_soldier.count + count
                        --             end
                        --         end
                        --     end
                        -- end

                        -- if dragon:LeadCitizen()<max_soldiers_citizen then
                        --     -- 拥有士兵数量大于派兵数量上限时，首先选取power最高的兵种，依次到达最大派兵上限为止
                        --     table.sort(total_soldiers, function(a, b)
                        --         return User:GetSoldierConfig(a.name).power > User:GetSoldierConfig(b.name).power
                        --     end)
                        --     local max_troop_num = dragon:LeadCitizen()
                        --     for k,item in ipairs(total_soldiers) do
                        --         local max_citizen = User:GetSoldierConfig(item.name).citizen * item.count
                        --         if max_citizen <= max_troop_num then
                        --             max_troop_num = max_troop_num - max_citizen
                        --             table.insert(final_soldiers, item)
                        --         else
                        --             local num = math.floor(max_troop_num/User:GetSoldierConfig(item.name).citizen)
                        --             table.insert(final_soldiers, {name = item.name,count = num})
                        --             break
                        --         end
                        --     end
                        -- else
                        --     final_soldiers = total_soldiers
                        -- end
                        -- NetManager:getSetDefenceTroopPromise(dragon:Type(),final_soldiers):done(function()
                        --     GameGlobalUI:showTips(_("提示"),_("设置驻防成功"))
                        -- end)
                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                            if self.dragon_manager:GetDragon(dragonType):IsDead() then
                                UIKit:showMessageDialog(nil,_("选择的龙已经死亡"))
                                return
                            end
                            NetManager:getSetDefenceTroopPromise(dragonType,soldiers):done(function ()
                                self.garrison_button:setButtonSelected(true)
                            end)    
                        end,{isMilitary = true,terrain = Alliance_Manager:GetMyAlliance().basicInfo.terrain,title = _("驻防部队")}):AddToCurrentScene(true)
                    else
                        UIKit:showMessageDialog(nil,_("龙未处于空闲状态"))
                        self.garrison_button:setButtonSelected(not target,false)
                    end
                else
                    if dragon:IsDefenced() then
                        NetManager:getCancelDefenceTroopPromise():done(function()
                            GameGlobalUI:showTips(_("提示"),_("取消驻防成功"))
                        end)
                    else
                        UIKit:showMessageDialog(nil,_("还没有驻防"))
                        self.garrison_button:setButtonSelected(not target,false)
                    end
                end
            end)

        --
        self.progress_content_hated,self.progress_hated = self:CreateProgressTimer()
        self.progress_content_hated:align(display.CENTER_TOP,window.cx,info_layer:getPositionY()-18):addTo(self.dragonNode)
        --
        self.progress_content_death,self.progress_death = self:CreateDeathEventProgressTimer()
        self.progress_content_death:align(display.LEFT_TOP,window.left+60,info_layer:getPositionY()-20):addTo(self.dragonNode)

        self.death_speed_button = WidgetPushButton.new({normal = 'green_btn_up_148x58.png',pressed = 'green_btn_down_148x58.png'})
            :setButtonLabel("normal",UIKit:commonButtonLable({
                text = _("加速")
            })):addTo(self.dragonNode)
            :align(display.LEFT_TOP,self.progress_content_death:getPositionX()+self.progress_content_death:getContentSize().width+18,
                self.progress_content_death:getPositionY()+7)
            :onButtonClicked(handler(self, self.OnDragonDeathSpeedUpClicked))
        local info_panel = UIKit:CreateBoxPanel9({width = 548, height = 114})
            :addTo(self.dragonNode)
            :align(display.CENTER_TOP,window.cx,self.progress_content_hated:getPositionY() - self.progress_content_hated:getContentSize().height - 32)
        self.info_panel = info_panel
        local strength_title_label =  UIKit:ttfLabel({
            text = _("力量"),
            color = 0x615b44,
            size  = 20
        }):addTo(info_panel):align(display.LEFT_BOTTOM,10,80)--  10 45
        self.strength_val_label =  UIKit:ttfLabel({
            text = "",
            color = 0x403c2f,
            size  = 20
        }):addTo(info_panel):align(display.LEFT_BOTTOM, 114, 80) -- 活力

        local vitality_title_label =  UIKit:ttfLabel({
            text = _("活力"),
            color = 0x615b44,
            size  = 20
        }):addTo(info_panel):align(display.LEFT_BOTTOM,10,45) -- 领导力 10

        self.vitality_val_label =  UIKit:ttfLabel({
            text = "",
            color = 0x403c2f,
            size  = 20
        }):addTo(info_panel):align(display.LEFT_BOTTOM, 114, 45)

        local leadership_title_label =  UIKit:ttfLabel({
            text = _("领导力"),
            color = 0x615b44,
            size  = 20
        }):addTo(info_panel):align(display.LEFT_BOTTOM,10,10) -- 力量

        self.leadership_val_label =  UIKit:ttfLabel({
            text = "",
            color = 0x403c2f,
            size  = 20
        }):addTo(info_panel):align(display.LEFT_BOTTOM, 114, 10)

        self.state_label = UIKit:ttfLabel({
            text = "",
            color = 0x07862b,
            size  = 20
        }):addTo(info_panel):align(display.CENTER_BOTTOM,540 - 74,75)
        local detailButton = WidgetPushButton.new({
            normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"
        }):setButtonLabel("normal",UIKit:ttfLabel({
            text = _("详情"),
            size = 24,
            color = 0xffedae,
            shadow = true
        })):addTo(info_panel):align(display.RIGHT_BOTTOM,540,5):onButtonClicked(function()
            UIKit:newGameUI("GameUIDragonEyrieDetail",self.city,self.building,self:GetCurrentDragon():Type()):AddToCurrentScene(false)
        end)
        self.detailButton = detailButton
        self.draongContentNode:OnEnterIndex(math.abs(0))
    end

end

function GameUIDragonEyrieMain:CreateDragonHateNodeIf()
    if not self.draogn_hate_node then
        local node = display.newNode():size(window.width,210):addTo(self.dragonNode):pos(0,window.bottom_top)
        self.draogn_hate_node = node
        WidgetUIBackGround.new({width = 554, height = 100},WidgetUIBackGround.STYLE_TYPE.STYLE_3):addTo(node):align(display.CENTER_TOP, window.cx, 210)
        local tip_label = UIKit:ttfLabel({
            text = Localize.dragon_buffer[self:GetCurrentDragon():Type()],
            size = 20,
            color= 0x403c2f,
            align= cc.TEXT_ALIGNMENT_CENTER
        }):addTo(node):align(display.CENTER_TOP, window.cx, 200)
        self.dragon_hate_tips_label = tip_label
        local hate_label = UIKit:ttfLabel({
            text = self.building:GetNextHateLevel() and string.format(_("龙巢%d级时可孵化新的巨龙"),self.building:GetNextHateLevel()) or "",
            size = 20,
            color= 0x403c2f,
            align= cc.TEXT_ALIGNMENT_CENTER,
            dimensions = cc.size(520,0)
        }):addTo(node):align(display.CENTER, window.cx, 150)
        self.hate_label = hate_label
        local hate_button = WidgetPushButton.new({ normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png", disabled = "grey_btn_186x66.png"})
            :setButtonLabel("normal",UIKit:commonButtonLable({
                text = _("开始孵化"),
                size = 24,
                color = 0xffedae,
            }))
            :addTo(node):align(display.CENTER_BOTTOM,window.cx,35)
            :onButtonClicked(function()
                self:OnEnergyButtonClicked()
            end)
        hate_button:setButtonEnabled(self.building:CheckIfHateDragon())
        self.hate_button = hate_button

        -- local event_node = display.newNode():size(window.width,76):addTo(node):pos(0,0)
        -- local dragonEvent = self.dragon_manager:GetDragonEventByDragonType(self:GetCurrentDragon():Type())
        -- local hate_speed_button = WidgetPushButton.new({ normal = "green_btn_up_148x76.png",pressed = "green_btn_down_148x76.png"})
        --     :setButtonLabel("normal",UIKit:commonButtonLable({
        --         text = _("加速"),
        --         size = 24,
        --         color = 0xffedae,
        --     }))
        --     :addTo(event_node):align(display.CENTER_BOTTOM,window.right - 120,34)
        --     :onButtonClicked(function()
        --         self:OnHateSpeedUpClicked()
        --     end)
        -- local hate_label = UIKit:ttfLabel({
        --     text = _("正在孵化巨龙"),
        --     size = 20,
        --     color= 0x403c2f,
        --     align= cc.TEXT_ALIGNMENT_CENTER
        -- }):addTo(event_node):align(display.LEFT_CENTER, window.left + 60, 95)
        -- local progress = WidgetProgress.new(0xffedae, "progress_bar_364x40_1.png", "progress_bar_364x40_2.png", {
        --     icon_bg = "back_ground_43x43.png",
        --     icon = "hourglass_30x38.png",
        --     bar_pos = {x = 0,y = 0}
        -- }):addTo(event_node):align(display.LEFT_CENTER, window.left + 60, 55)
        -- function event_node:SetProgressInfo(time_label, percent)
        --     progress:SetProgressInfo(time_label, percent)
        -- end
        -- self.hate_event_node = event_node

        -- local hate_timer_label = UIKit:ttfLabel({
        --     text = "",
        --     size = 20,
        --     color= 0x403c2f
        -- }):align(display.BOTTOM_CENTER, window.cx, 18):addTo(node)
        -- self.hate_timer_label = hate_timer_label
    end
    return self.draogn_hate_node
end


-- function GameUIDragonEyrieMain:OnHateSpeedUpClicked()
--     UIKit:newGameUI("GameUIDragonHateSpeedUp", self.dragon_manager,self:GetCurrentDragon():Type()):AddToCurrentScene(true)
-- end


function GameUIDragonEyrieMain:OnEnergyButtonClicked()
    if not self.building:CheckIfHateDragon() then
        UIKit:showMessageDialog(nil, _("当前龙巢等级不能孵化新的巨龙"), function()end)
        return
    end
    return NetManager:getHatchDragonPromise(self:GetCurrentDragon():Type()):done(function ()
        self.hate_label:setString(self.building:GetNextHateLevel() and string.format(_("龙巢%d级时可孵化新的巨龙"),self.building:GetNextHateLevel()) or "")
        self.hate_button:setButtonEnabled(self.building:CheckIfHateDragon())
    end)
end

function GameUIDragonEyrieMain:GetCurrentDragon()
    -- index 1~3
    local dragon = self.dragon_manager:GetDragonByIndex(self.draong_index)
    return dragon
end
function GameUIDragonEyrieMain:CreateDragonScrollNode()
    local clipNode = display.newClippingRegionNode(cc.rect(0,0,620,600))
    local contenNode = WidgetDragons.new(
        {
            OnLeaveIndexEvent = handler(self, self.OnLeaveIndexEvent),
            OnEnterIndexEvent = handler(self, self.OnEnterIndexEvent),
            OnTouchClickEvent = handler(self, self.OnTouchClickEvent),
        }
    ):addTo(clipNode):pos(310,300)
    if self.fte_dragon_type then
        self.dragon_manager:SortWithFirstDragon(self.fte_dragon_type)
    else
        self.dragon_manager:SortDragon()
    end
    for i,v in ipairs(contenNode:GetItems()) do
        local dragon = self.dragon_manager:GetDragonByIndex(i)
        local dragon_image = display.newSprite(string.format("%s_egg_176x192.png",dragon:Type()))
            :align(display.CENTER, 300,355)
            :addTo(v)
        v.dragon_image = dragon_image
        dragon_image.resolution = {dragon_image:getContentSize().width,dragon_image:getContentSize().height}
        local dragon_armature = DragonSprite.new(display.getRunningScene():GetSceneLayer(),dragon:Type())
            :addTo(v)
            :pos(300,350)
            :hide():scale(0.9)
        v.armature = dragon_armature
        v.armature:Pause()
        if dragon:Ishated() then
            v.armature:show()
            v.dragon_image:hide()
        end
    end
    return clipNode,contenNode
end
function GameUIDragonEyrieMain:OnEnterIndexEvent(index)
    if self.draongContentNode then
        self.draong_index = index + 1
        self:RefreshUI()
        local eyrie = self.draongContentNode:GetItemByIndex(index)
        if not self:GetCurrentDragon():Ishated() then
            self.dragon_hate_tips_label:setString(Localize.dragon_buffer[self:GetCurrentDragon():Type()])
            return
        end
        eyrie.dragon_image:hide()
        eyrie.armature:show()
        eyrie.armature:Resume()
    end
end

function GameUIDragonEyrieMain:OnTouchClickEvent(index)
    local localIndex = index + 1
    if self.draong_index == localIndex then
        local dragon = self.dragon_manager:GetDragonByIndex(localIndex)
        if dragon and dragon:Ishated() then
            app:GetAudioManager():PlayBuildingEffectByType('dragonEyrie')
        end
    end
end

function GameUIDragonEyrieMain:OnLeaveIndexEvent(index)
    if self.draongContentNode then
        local eyrie = self.draongContentNode:GetItemByIndex(index)
        if not self:GetCurrentDragon():Ishated() then return end
        eyrie.armature:Pause()
        -- eyrie.armature:hide()
        -- eyrie.dragon_image:show()
    end
end

function GameUIDragonEyrieMain:ChangeDragon(direction)
    if self.isChanging or self:IsDragonLock() then return end
    self.isChanging = true
    if direction == 'next' then
        if self.draong_index + 1 > 3 then
            self.draong_index = 1
        else
            self.draong_index = self.draong_index + 1
        end
        self.draongContentNode:Next()
        self.isChanging = false
    else
        if self.draong_index - 1 == 0 then
            self.draong_index = 3
        else
            self.draong_index = self.draong_index - 1
        end
        self.draongContentNode:Before()
        self.isChanging = false
    end
end
function GameUIDragonEyrieMain:OnDragonHpItemUseButtonClicked()
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "dragonHp_1",
        dragon = self:GetCurrentDragon()
    })
    widgetUseItems:AddToCurrentScene()
end

function GameUIDragonEyrieMain:OnDragonExpItemUseButtonClicked()
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "dragonExp_1",
        dragon = self:GetCurrentDragon()
    })
    widgetUseItems:AddToCurrentScene()
end

function GameUIDragonEyrieMain:OnDragonDeathSpeedUpClicked()
    UIKit:newGameUI("GameUIDragonDeathSpeedUp", self.dragon_manager,self:GetCurrentDragon():Type()):AddToCurrentScene(true)
end


return GameUIDragonEyrieMain





























