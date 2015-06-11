--
-- Author: Danny He
-- Date: 2014-12-29 16:28:23
--
local GameUIAllianceCityEnter = UIKit:createUIClass("GameUIAllianceCityEnter","GameUIAllianceEnterBase")
local config_wall = GameDatas.BuildingFunction.wall
local GameUIWriteMail = import(".GameUIWriteMail")
local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetAllianceEnterButtonProgress = import("..widget.WidgetAllianceEnterButtonProgress")
local Alliance = import("..entity.Alliance")
local UILib = import(".UILib")

function GameUIAllianceCityEnter:ctor(building,isMyAlliance,my_alliance,enemy_alliance)
    GameUIAllianceCityEnter.super.ctor(self,building,isMyAlliance,my_alliance)
    self.enemy_alliance = enemy_alliance

    local id = self:GetBuilding():Id()
    for k,v in pairs(self:GetCurrentAlliance():GetAllMembers()) do
        if v:MapId() == id then
            self.member = v
            break
        end
    end
    assert(self.member)
end

function GameUIAllianceCityEnter:GetMember()
    return self.member
end

function GameUIAllianceCityEnter:GetLevelLabelText()
    return _("等级") .. self:GetMember():KeepLevel()
end

function GameUIAllianceCityEnter:GetProcessLabelText()
    -- return self:GetMember():WallHp() .. "/" .. config_wall[self:GetMember():WallLevel()].wallHp
    return ""
end
function GameUIAllianceCityEnter:GetCurrentAlliance()
    return self.isMyAlliance and self:GetMyAlliance() or self:GetEnemyAlliance()
end

function GameUIAllianceCityEnter:onEnter()
    GameUIAllianceCityEnter.super.onEnter(self)
    self:GetProgressTimer():setPercentage(0)
    Alliance_Manager:GetMyAlliance():AddListenOnType(self,Alliance.LISTEN_TYPE.BASIC)
    NetManager:getPlayerWallInfoPromise(self:GetMember():Id()):done(function(response)
        if response.msg.wallInfo then
            local current_wall_hp = response.msg.wallInfo.wallHp
            local maxWallHp = config_wall[response.msg.wallInfo.wallLevel].wallHp
            self:GetProgressTimer():setPercentage(current_wall_hp/maxWallHp*100)
            self:GetProcessLabel():setString(string.format("%d/%d",current_wall_hp,maxWallHp))
        end
    end)
end
function GameUIAllianceCityEnter:onExit()
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self,Alliance.LISTEN_TYPE.BASIC)
    GameUIAllianceCityEnter.super.onExit(self)
end
function GameUIAllianceCityEnter:OnAllianceBasicChanged( alliance,changed_map )
    if changed_map.status and not self:IsMyAlliance() then
        self:GetEnterButtonByIndex(1):setButtonEnabled(changed_map.status.new == "fight")
        self:GetEnterButtonByIndex(2):setButtonEnabled(changed_map.status.new == "fight")
    end
end

function GameUIAllianceCityEnter:GetBuildingInfoOriginalY()
    return self.process_bar_bg:getPositionY()-self.process_bar_bg:getContentSize().height-40
end
function GameUIAllianceCityEnter:FixedUI()
    self:GetDescLabel():hide()
    self:GetHonourIcon():hide()
    self:GetHonourLabel():hide()
end

function GameUIAllianceCityEnter:GetEnemyAlliance()
    return self.enemy_alliance
end

function GameUIAllianceCityEnter:GetUIHeight()
    return 311
end

function GameUIAllianceCityEnter:GetUITitle()
    return self:GetMember():Name()
end

function GameUIAllianceCityEnter:GetBuildingImage()
    return ""
end

function GameUIAllianceCityEnter:GetBuildImageSprite()
    local sprite_config_key = self:IsMyAlliance() and "my_keep" or "other_keep"
    local build_png = SpriteConfig[sprite_config_key]:GetConfigByLevel(self:GetMember():KeepLevel()).png
    local bg_png = UILib.city_terrain_icon[self:GetMember():Terrain()]
    local bg_sprite = display.newSprite(bg_png)
    local build_sprite = display.newSprite(build_png):addTo(bg_sprite):pos(71,71)
    local size = build_sprite:getContentSize()
    build_sprite:scale(110/math.max(size.width,size.height))
    return bg_sprite
end

function GameUIAllianceCityEnter:GetBuildImageInfomation(sprite)
    return 0.9,97,self:GetUIHeight() - 90 
end

function GameUIAllianceCityEnter:IsShowBuildingBox()
    return false
end

function GameUIAllianceCityEnter:GetBuildingType()
    return 'member'
end

function GameUIAllianceCityEnter:GetBuildingDesc()
    return ""
end


function GameUIAllianceCityEnter:GetBuildingInfo()
    local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local player_name = {
        {_("玩家"),0x615b44},
        {self:GetMember().name,0x403c2f},
    }

    local help_count = {
        {_("协防玩家"),0x615b44},
        {self:GetMember().helpedByTroopsCount,0x403c2f},
    }
    return {location,player_name,help_count}
end

function GameUIAllianceCityEnter:GetEnterButtons()
    local buttons = {}
    local member = self:GetMember()
    if self:IsMyAlliance() then --我方玩家
        local alliance = self:GetMyAlliance()
        if User:Id() == self:GetMember():Id() then -- me
            local enter_button = self:BuildOneButton("alliance_enter_city_56x68.png",_("进入")):onButtonClicked(function()
                app:EnterMyCityScene()
                self:LeftButtonClicked()
            end)
            buttons = {enter_button}
        else --盟友
            local help_button
            local can_not_help_in_city = City:IsHelpedToTroopsWithPlayerId(member:Id())
            if can_not_help_in_city then
                help_button = self:BuildOneButton("help_defense_44x56.png",_("撤防")):onButtonClicked(function()
                    NetManager:getRetreatFromHelpedAllianceMemberPromise(member:Id())
                    self:LeftButtonClicked()
                end)
            else
                help_button = self:BuildOneButton("help_defense_44x56.png",_("协防")):onButtonClicked(function()
                    local playerId = member:Id()
                    if not alliance:CheckHelpDefenceMarchEventsHaveTarget(playerId) then
                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                            NetManager:getHelpAllianceMemberDefencePromise(dragonType, soldiers, playerId):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                            end)
                        end,{targetIsMyAlliance = self:IsMyAlliance(),toLocation = self:GetLogicPosition()}):AddToCurrentScene(true)
                        self:LeftButtonClicked()
                    else
                        UIKit:showMessageDialog(_("错误"), _("已有协防部队正在行军"), function()end)
                        self:LeftButtonClicked()
                        return
                    end
                end)
            end
            local enter_button = self:BuildOneButton("alliance_enter_city_56x68.png",_("进入")):onButtonClicked(function()
                local location = self:GetLogicPosition()
                location.id = self:GetCurrentAlliance():Id()
                app:EnterFriendCityScene(member:Id(), location)
                self:LeftButtonClicked()
            end)
            local mail_button = self:BuildOneButton("mail_56x40.png",_("邮件")):onButtonClicked(function()
                local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,{
                    id = member:Id(),
                    name = member:Name(),
                    icon = member:Icon(),
                    allianceTag = self:GetCurrentAlliance():Tag(),
                })
                mail:SetTitle(_("个人邮件"))
                mail:SetAddressee(member:Name())
                mail:AddToCurrentScene()
                self:LeftButtonClicked()
            end)
            local info_button = self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
                UIKit:newGameUI("GameUIAllianceMemberInfo",true,member:Id()):AddToCurrentScene(true)
                self:LeftButtonClicked()
            end)
            buttons = {help_button,enter_button,mail_button,info_button}
        end
    else -- 敌方玩家
        local isProtected = self:CheckMeIsProtectedWarinng()
        local attack_button = self:BuildOneButton("attack_58x56.png",_("进攻")):onButtonClicked(function()
            UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                if isProtected then
                    UIKit:showMessageDialog(_("提示"),_("进攻玩家城市将失去保护状态，确定继续派兵?"),function()
                        NetManager:getAttackPlayerCityPromise(dragonType, soldiers, member:Id()):done(function()
                            app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                            gameuialliancesendtroops:LeftButtonClicked()
                        end)
                    end)
                else
                    if member:IsProtected() then
                        UIKit:showMessageDialog(_("提示"),_("目标城市已被击溃并进入保护期，可能无法发生战斗，你是否继续派兵?"), function()
                            NetManager:getAttackPlayerCityPromise(dragonType, soldiers, member:Id()):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                gameuialliancesendtroops:LeftButtonClicked()
                            end)
                        end,function()end)
                    else
                        NetManager:getAttackPlayerCityPromise(dragonType, soldiers, member:Id()):done(function()
                            app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                            gameuialliancesendtroops:LeftButtonClicked()
                        end)
                    end
                end
            end,{targetIsMyAlliance = self:IsMyAlliance(),toLocation = self:GetLogicPosition(),returnCloseAction = true}):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
    local my_allaince = Alliance_Manager:GetMyAlliance()
    attack_button:setButtonEnabled(my_allaince:Status() == "fight")
    local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
        UIKit:newGameUI("GameUIStrikePlayer",1,{memberId = member:Id(),targetIsMyAlliance = false,toLocation = self:GetLogicPosition(),targetIsProtected = member:IsProtected()}):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    strike_button:setButtonEnabled(my_allaince:Status() == "fight")

    buttons = {attack_button,strike_button}
    if self:GetMyAlliance():GetAllianceBelvedere():CanEnterEnemyCity() then
        local enter_button = self:BuildOneButton("alliance_enter_city_56x68.png",_("进入")):onButtonClicked(function()
            local location = self:GetLogicPosition()
            location.id = self:GetCurrentAlliance():Id()
            app:EnterPlayerCityScene(member:Id(), location)
            self:LeftButtonClicked()
        end)
        table.insert(buttons, enter_button)
    end
    local info_button = self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
        UIKit:newGameUI("GameUIAllianceMemberInfo",false,member:Id()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    table.insert(buttons,info_button)

    -- 准备期做一个progress倒计时按钮可使用时间
    if my_allaince:Status() == "prepare" then
        local progress_1 = WidgetAllianceEnterButtonProgress.new()
            :pos(-68, -54)
            :addTo(attack_button)
        local progress_2 = WidgetAllianceEnterButtonProgress.new()
            :pos(-68, -54)
            :addTo(strike_button)
    end
    end
    return buttons
end

return GameUIAllianceCityEnter








