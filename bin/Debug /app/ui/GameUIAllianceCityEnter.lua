--
-- Author: Danny He
-- Date: 2014-12-29 16:28:23
--
local GameUIAllianceCityEnter = UIKit:createUIClass("GameUIAllianceCityEnter","GameUIAllianceEnterBase")
local config_wall = GameDatas.BuildingFunction.wall
local GameUIWriteMail = import(".GameUIWriteMail")
local SpriteConfig = import("..sprites.SpriteConfig")
local Alliance = import("..entity.Alliance")
local UILib = import(".UILib")

function GameUIAllianceCityEnter:ctor(mapObj,alliance)
    GameUIAllianceCityEnter.super.ctor(self,mapObj,alliance)
    self.member = alliance:GetMemberByMapObjectsId(self:GetBuilding().id)
    assert(self.member)
end

function GameUIAllianceCityEnter:GetMember()
    return self.member
end

function GameUIAllianceCityEnter:GetLevelLabelText()
    return _("等级") .. self:GetMember().keepLevel
end

function GameUIAllianceCityEnter:GetProcessLabelText()
    -- return self:GetMember():WallHp() .. "/" .. config_wall[self:GetMember():WallLevel()].wallHp
    return ""
end
function GameUIAllianceCityEnter:GetCurrentAlliance()
    return self:GetFocusAlliance()
end

function GameUIAllianceCityEnter:onEnter()
    GameUIAllianceCityEnter.super.onEnter(self)
    self:GetProgressTimer():setPercentage(0)
    NetManager:getPlayerWallInfoPromise(self:GetMember().id):done(function(response)
        if response.msg.wallInfo then
            local current_wall_hp = response.msg.wallInfo.wallHp
            local maxWallHp = config_wall[response.msg.wallInfo.wallLevel].wallHp
            self:GetProgressTimer():setPercentage(0)
            self:GetProgressTimer():runAction(cc.ProgressTo:create(0.5, current_wall_hp/maxWallHp*100))
            self:GetProcessLabel():setString(string.format("%d/%d",current_wall_hp,maxWallHp))
        end
    end)
end
function GameUIAllianceCityEnter:onExit()
    GameUIAllianceCityEnter.super.onExit(self)
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
    return self:GetMember().name
end

function GameUIAllianceCityEnter:GetBuildingImage()
    return ""
end

function GameUIAllianceCityEnter:GetBuildImageSprite()
    local sprite_config_key = self:IsMyAlliance() and "my_keep" or "other_keep"
    local build_png = SpriteConfig[sprite_config_key]:GetConfigByLevel(self:GetMember().keepLevel).png
    local bg_png = UILib.city_terrain_icon[self:GetMember().terrain]
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
    print("helpedByTroopsCount====,",member.helpedByTroopsCount)
    if self:IsMyAlliance() then --我方玩家
        local alliance = self:GetMyAlliance()
        if User:Id() == member.id then -- me
            local enter_button = self:BuildOneButton("alliance_enter_city_56x68.png",_("进入")):onButtonClicked(function()
                app:EnterMyCityScene()
                self:LeftButtonClicked()
            end)
        buttons = {enter_button}
        else --盟友
            local help_button
            local can_not_help_in_city = User:IsHelpedToPlayer(member.id)
            if can_not_help_in_city then
                help_button = self:BuildOneButton("tmp_retreat_defense_48x58.png",_("撤防")):onButtonClicked(function()
                    UIKit:showMessageDialog(_("提示"),_("是否确认撤防"),function()
                        NetManager:getRetreatFromHelpedAllianceMemberPromise(member.id)
                    end,
                    function()
                    end)
                end)
            else
                help_button = self:BuildOneButton("help_defense_44x56.png",_("协防")):onButtonClicked(function()
                    local function helpDefencePlayer()
                        local playerId = member.id
                        if not alliance:CheckHelpDefenceMarchEventsHaveTarget(playerId) then
                            local toLocation = self:GetLogicPosition()
                            if alliance:GetSelf():IsProtected() then
                                UIKit:showMessageDialog(_("提示"),_("协防盟友将失去保护状态，确定继续派兵?"),function()
                                    local attack_func = function ()
                                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                                            NetManager:getHelpAllianceMemberDefencePromise(dragonType, soldiers, playerId):done(function()
                                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                            end)
                                        end,{targetAlliance = alliance,toLocation = toLocation}):AddToCurrentScene(true)
                                    end
                                    UIKit:showSendTroopMessageDialog(attack_func, "dragonMaterials",_("龙"))
                                end,function()end)
                            else
                                local attack_func = function ()
                                    UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                                        NetManager:getHelpAllianceMemberDefencePromise(dragonType, soldiers, playerId):done(function()
                                            app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                        end)
                                    end,{targetAlliance = alliance,toLocation = toLocation}):AddToCurrentScene(true)
                                end
                                UIKit:showSendTroopMessageDialog(attack_func, "dragonMaterials",_("龙"))
                            end
                        else
                            UIKit:showMessageDialog(_("错误"), _("已有协防部队正在行军"), function()end)
                            self:LeftButtonClicked()
                            return
                        end
                        self:LeftButtonClicked()
                    end
                    if member.helpedByTroopsCount > 0 then
                        UIKit:showMessageDialog(_("提示"),_("目标协防数量已满，是否确认继续派兵？"),helpDefencePlayer,function()end)
                    else
                        helpDefencePlayer()
                    end
                end)
                help_button:setTouchSwallowEnabled(true)
            end
            local enter_button = self:BuildOneButton("alliance_enter_city_56x68.png",_("进入")):onButtonClicked(function()
                local location = self:GetLogicPosition()
                location.id = self:GetCurrentAlliance()._id
                location.mapIndex = self:GetCurrentAlliance().mapIndex
                location.x = self:GetLogicPosition().x
                location.y = self:GetLogicPosition().y
                location.canShowBuildingLevel = self:GetMyAlliance():CanCheckOtherAllianceCityBuildingLevel()
                app:EnterFriendCityScene(member.id, location)
                self:LeftButtonClicked()
            end)
            local mail_button = self:BuildOneButton("mail_56x40.png",_("邮件")):onButtonClicked(function()
                local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,{
                    id = member.id,
                    name = member.name,
                    icon = member.icon,
                    allianceTag = self:GetCurrentAlliance().basicInfo.tag,
                })
                mail:SetTitle(_("个人邮件"))
                mail:SetAddressee(member.name)
                mail:AddToCurrentScene()
                self:LeftButtonClicked()
            end)
            local info_button = self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
                UIKit:newGameUI("GameUIAllianceMemberInfo",true,member.id):AddToCurrentScene(true)
                self:LeftButtonClicked()
            end)
            buttons = {help_button,enter_button,mail_button,info_button}
        end
    else -- 敌方玩家
        local isProtected = self:CheckMeIsProtectedWarinng()
        local toLocation = self:GetLogicPosition()
        local alliance = self.focus_alliance
        local attack_button = self:BuildOneButton("attack_58x56.png",_("进攻")):onButtonClicked(function()
            local final_func = function ()
                local attack_func = function ()
                    UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                        if member.isProtected then
                            UIKit:showMessageDialog(_("提示"),_("目标城市已被击溃并进入保护期，可能无法发生战斗，你是否继续派兵?"), function()
                                NetManager:getAttackPlayerCityPromise(dragonType, soldiers, alliance._id, member.id):done(function()
                                    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                    gameuialliancesendtroops:LeftButtonClicked()
                                end)
                            end,function()end)
                        else
                            NetManager:getAttackPlayerCityPromise(dragonType, soldiers, alliance._id, member.id):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                gameuialliancesendtroops:LeftButtonClicked()
                            end)
                        end
                    end,{targetAlliance = alliance,toLocation = toLocation,returnCloseAction = true}):AddToCurrentScene(true)
                end
                UIKit:showSendTroopMessageDialog(attack_func, "dragonMaterials",_("龙"))
            end

            if isProtected then
                UIKit:showMessageDialog(_("提示"),_("进攻玩家城市将失去保护状态，确定继续派兵?"),final_func)
            else
                final_func()
            end
        end)
        local my_allaince = Alliance_Manager:GetMyAlliance()
        -- attack_button:setButtonEnabled(my_allaince.basicInfo.status == "fight")
        local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
            local toLocation = self:GetLogicPosition()
            if isProtected then
                UIKit:showMessageDialog(_("提示"),_("突袭玩家城市将失去保护状态，确定继续派兵?"),function ()
                    UIKit:newGameUI("GameUIStrikePlayer",1,{memberId = member.id,alliance = alliance, toLocation = toLocation,targetIsProtected = member.isProtected}):AddToCurrentScene(true)
                end)
            else
                UIKit:newGameUI("GameUIStrikePlayer",1,{memberId = member.id,alliance = alliance,toLocation = toLocation,targetIsProtected = member.isProtected}):AddToCurrentScene(true)
            end
        end)
        -- strike_button:setButtonEnabled(my_allaince.basicInfo.status == "fight")

        buttons = {attack_button,strike_button}
        -- if self:GetMyAlliance():GetAllianceBelvedere():CanEnterEnemyCity() then
        local enter_button = self:BuildOneButton("alliance_enter_city_56x68.png",_("进入")):onButtonClicked(function()
            if self:GetMyAlliance():CanCheckOtherAllianceCity() then
                local location = self:GetLogicPosition()
                location.id = self:GetCurrentAlliance()._id
                location.mapIndex = self:GetCurrentAlliance().mapIndex
                location.x = self:GetLogicPosition().x
                location.y = self:GetLogicPosition().y
                location.canShowBuildingLevel = self:GetMyAlliance():CanCheckOtherAllianceCityBuildingLevel()
                app:EnterPlayerCityScene(member.id, location)
            else
                UIKit:showMessageDialog(_("提示"),_("巨石阵等级不足，不能进入其他联盟玩家城市"))
            end
            self:LeftButtonClicked()
        end)
        table.insert(buttons, enter_button)
        -- end
        local info_button = self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
            UIKit:newGameUI("GameUIAllianceMemberInfo",false,member.id):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
        table.insert(buttons,info_button)
    end
    return buttons
end

return GameUIAllianceCityEnter



















