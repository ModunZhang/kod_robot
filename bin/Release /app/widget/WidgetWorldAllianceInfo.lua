--
-- Author: Kenny Dai
-- Date: 2015-10-22 16:49:31
--

local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetInfo = import(".WidgetInfo")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local intInit = GameDatas.AllianceInitData.intInit
local moveLimit = GameDatas.AllianceMap.moveLimit
local WidgetWorldAllianceInfo = class("WidgetWorldAllianceInfo", WidgetPopDialog)

function WidgetWorldAllianceInfo:ctor(object,mapIndex,need_goto_btn)
    self.object = object
    self.mapIndex = mapIndex
    self.need_goto_btn = need_goto_btn
    WidgetWorldAllianceInfo.super.ctor(self,object and 454 or 580,object and  object.alliance.name or _("无主领土"),window.top-120)
    self:setNodeEventEnabled(true)

    self.mask_layer = display.newLayer():addTo(self, 2):hide()

    if object then
        local id = object.alliance.id
        if mapIndex == Alliance_Manager:GetMyAlliance().mapIndex then
            id = Alliance_Manager:GetMyAlliance()._id
        end
        NetManager:getAllianceBasicInfoPromise(id, User.serverId):done(function(response)
            if response.success
                and response.msg.allianceData
                and self.SetAllianceData then
                self:SetAllianceData(response.msg.allianceData)
                self:LoadInfo(response.msg.allianceData)
            end
        end)
    else
        self:LoadMoveAlliance()
    end
end
function WidgetWorldAllianceInfo:SetAllianceData(allianceData)
    self.allianceData = allianceData
end
function WidgetWorldAllianceInfo:GetAllianceData()
    return self.allianceData
end
function WidgetWorldAllianceInfo:onEnter()

end

function WidgetWorldAllianceInfo:onExit()

end
local function EnterIn(mapIndex)
    local worldmap = UIKit:GetUIInstance("GameUIWorldMap")
    local scenelayer = worldmap:GetSceneLayer()
    local sprite = scenelayer.allainceSprites[tostring(mapIndex)]
    local wp
    if sprite then
        wp = sprite:getParent():convertToWorldSpace(cc.p(sprite:getPosition()))
    else
        wp = scenelayer:ConverToWorldSpace(scenelayer:IndexToLogic(mapIndex))
    end
    if wp.x < 0 then
        wp.x = 0
    elseif wp.x > display.width then
        wp.x = display.width
    end
    wp.y = wp.y - (display.width > 640 and (152 * display.width/768) or 152)
    if wp.y < 0 then
        wp.y = 0
    elseif wp.y > display.height then
        wp.y = display.height
    end

    if UIKit:GetUIInstance("GameUIWorldMap") then
        UIKit:GetUIInstance("GameUIWorldMap").mask_layer:show()
        local s = UIKit:GetUIInstance("GameUIWorldMap"):GetSceneLayer():getScale()
        local scene_node = UIKit:GetUIInstance("GameUIWorldMap"):GetSceneLayer().scene_node
        local lp = scene_node:getParent():convertToNodeSpace(wp)
        local size = scene_node:getCascadeBoundingBox()

        local xp = lp.x * s / size.width
        local yp = lp.y * s / size.height
        scene_node:pos(lp.x, lp.y):setAnchorPoint(cc.p(xp, yp))
        scene_node:runAction(transition.sequence{
            cc.ScaleTo:create(0.3, 2.5),
            cc.CallFunc:create(function()
                if UIKit:GetUIInstance("GameUIWorldMap") then
                    UIKit:GetUIInstance("GameUIWorldMap"):LeftButtonClicked()
                end
            end)
        })
    end
end
function WidgetWorldAllianceInfo:Located(mapIndex, x, y)
    self.mask_layer:stopAllActions()
    self.mask_layer:show():performWithDelay(function()
        self.mask_layer:hide()
    end, 2)

    local scene = display.getRunningScene()
    if mapIndex and x and y then
        if scene.__cname ~= 'AllianceDetailScene' then
            app:EnterMyAllianceScene({
                mapIndex = mapIndex,
                x = x,
                y = y,
            })
        else
            local x,y = DataUtils:GetAbsolutePosition(mapIndex, x, y)
            if Alliance_Manager:GetAllianceByCache(mapIndex) then
                scene:GotoPosition(x,y)
                EnterIn(mapIndex)
                self:LeftButtonClicked()
            else
                scene:FetchAllianceDatasByIndex(mapIndex, function()
                    scene:GotoPosition(x,y)
                    EnterIn(mapIndex)
                    self:LeftButtonClicked()
                end)
            end
        end
    else
        if scene.__cname ~= 'AllianceDetailScene' then
            app:EnterMyAllianceScene({mapIndex = mapIndex})
        else
            if Alliance_Manager:GetAllianceByCache(mapIndex) then
                scene:GotoAllianceByXY(scene:GetSceneLayer():IndexToLogic(mapIndex))
                EnterIn(mapIndex)
                self:LeftButtonClicked()
            else
                scene:FetchAllianceDatasByIndex(mapIndex, function()
                    scene:GotoAllianceByXY(scene:GetSceneLayer():IndexToLogic(mapIndex))
                    EnterIn(mapIndex)
                    self:LeftButtonClicked()
                end)
            end
        end
    end
end
-- function WidgetWorldAllianceInfo:EnterIn(mapIndex)
--     local worldmap = UIKit:GetUIInstance("GameUIWorldMap")
--     local scenelayer = worldmap:GetSceneLayer()
--     local sprite = scenelayer.allainceSprites[tostring(mapIndex)]
--     local wp
--     if sprite then
--         wp = sprite:getParent():convertToWorldSpace(cc.p(sprite:getPosition()))
--     else
--         wp = scenelayer:ConverToWorldSpace(scenelayer:IndexToLogic(mapIndex))
--     end
--     if wp.x < 0 then
--         wp.x = 0
--     elseif wp.x > display.width then
--         wp.x = display.width
--     end
--     wp.y = wp.y - (display.width > 640 and (152 * display.width/768) or 152)
--     if wp.y < 0 then
--         wp.y = 0
--     elseif wp.y > display.height then
--         wp.y = display.height
--     end

--     if UIKit:GetUIInstance("GameUIWorldMap") then
--         UIKit:GetUIInstance("GameUIWorldMap").mask_layer:show()
--         local s = UIKit:GetUIInstance("GameUIWorldMap"):GetSceneLayer():getScale()
--         local scene_node = UIKit:GetUIInstance("GameUIWorldMap"):GetSceneLayer().scene_node
--         local lp = scene_node:getParent():convertToNodeSpace(wp)
--         local size = scene_node:getCascadeBoundingBox()

--         local xp = lp.x * s / size.width
--         local yp = lp.y * s / size.height
--         scene_node:pos(lp.x, lp.y):setAnchorPoint(cc.p(xp, yp))
--         scene_node:runAction(transition.sequence{
--             cc.ScaleTo:create(0.3, 2.5),
--             cc.CallFunc:create(function()
--                 if UIKit:GetUIInstance("GameUIWorldMap") then
--                     UIKit:GetUIInstance("GameUIWorldMap"):LeftButtonClicked()
--                 end
--             end)
--         })
--     end
-- end
function WidgetWorldAllianceInfo:LoadInfo(alliance_data)
    local layer = self.body
    local l_size = layer:getContentSize()
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(134,134)
        :addTo(layer)
        :align(display.LEFT_TOP, 30, l_size.height - 30)
    local flag_sprite = WidgetAllianceHelper.new():CreateFlagWithRhombusTerrain(alliance_data.terrain,alliance_data.flag)
    flag_sprite:addTo(flag_box)
    flag_sprite:pos(67,46):scale(1.4)
    local mid_position_x,mid_position_y = DataUtils:GetAbsolutePosition(alliance_data.mapIndex, 16, 16)
    local position_node = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("位置"),
            text_2 = string.format(_("第%d圈(%d,%d)"),DataUtils:getMapRoundByMapIndex(alliance_data.mapIndex) + 1,mid_position_x,mid_position_y),
        }
    ):align(display.RIGHT_TOP,l_size.width-30, l_size.height - 56):addTo(layer)

    local titleBg = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("和平期"),
            text_2 = "00:11:11",
        }
    ):align(display.RIGHT_TOP,l_size.width-30, l_size.height - 96):addTo(layer)

    scheduleAt(self, function()
        titleBg:SetValue(GameUtils:formatTimeStyle1(app.timer:GetServerTime() - alliance_data.statusStartTime/1000.0),Localize.period_type[alliance_data.status])
    end)

    local info_bg = WidgetUIBackGround.new({height=82,width=556},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.LEFT_TOP, flag_box:getPositionX(),l_size.height - 174)
        :addTo(layer)
    local memberTitleLabel = UIKit:ttfLabel({
        text = _("成员"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP,10,info_bg:getContentSize().height - 10)

    local memberValLabel = UIKit:ttfLabel({
        text = string.format("%d/%d",alliance_data.members,alliance_data.membersMax), --count of members
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP,memberTitleLabel:getPositionX() + memberTitleLabel:getContentSize().width + 10, memberTitleLabel:getPositionY())


    local fightingTitleLabel = UIKit:ttfLabel({
        text = _("战斗力"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP, 320, memberTitleLabel:getPositionY())

    local fightingValLabel = UIKit:ttfLabel({
        text = string.formatnumberthousands(alliance_data.power),
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP, fightingTitleLabel:getPositionX() + fightingTitleLabel:getContentSize().width + 10, fightingTitleLabel:getPositionY())


    local languageTitleLabel = UIKit:ttfLabel({
        text = _("国家"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_BOTTOM,memberTitleLabel:getPositionX(),10)

    local languageValLabel = UIKit:ttfLabel({
        text = Localize.alliance_language[alliance_data.country], -- language
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM,languageTitleLabel:getPositionX() + languageTitleLabel:getContentSize().width + 10,10)


    local killTitleLabel = UIKit:ttfLabel({
        text = _("击杀"),
        size = 20,
        color = 0x615b44,
        align = ui.TEXT_ALIGN_RIGHT,
    }):addTo(info_bg):align(display.LEFT_BOTTOM, fightingTitleLabel:getPositionX(),10)

    local killValLabel = UIKit:ttfLabel({
        text = string.formatnumberthousands(alliance_data.kill),
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM, killTitleLabel:getPositionX() + killTitleLabel:getContentSize().width + 10, 10)

    local leaderIcon = display.newSprite("alliance_item_leader_39x39.png")
        :addTo(layer)
        :align(display.LEFT_TOP,titleBg:getPositionX() - titleBg:getContentSize().width, titleBg:getPositionY() - titleBg:getContentSize().height -18)
    local leaderLabel = UIKit:ttfLabel({
        text = self:GetAllianceArchonName() or  "",
        size = 22,
        color = 0x403c2f
    }):addTo(layer):align(display.LEFT_TOP,leaderIcon:getPositionX()+leaderIcon:getContentSize().width+15, leaderIcon:getPositionY()-4)

    local button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(
            UIKit:ttfLabel({
                text = _("定位盟主"),
                size = 20,
                shadow = true,
                color = 0xfff3c7
            })
        )
        :align(display.RIGHT_TOP,titleBg:getPositionX(),titleBg:getPositionY() - titleBg:getContentSize().height -10)
        :addTo(layer)
    button:onButtonClicked(function(event)
        local location = self:GetAllianceData().archon.location
        self:Located(self.mapIndex, location.x, location.y)
    end)

    local desc_bg = WidgetUIBackGround.new({height=158,width=550},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER_TOP, l_size.width/2,info_bg:getPositionY() - 92)
        :addTo(layer)

    local desc = alliance_data.desc
    if not desc or desc == json.null then
        desc = _("联盟未设置联盟描述")
    end
    local killTitleLabel = UIKit:ttfLabel({
        text =  desc,
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(530,0),
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):addTo(desc_bg):align(display.CENTER, desc_bg:getContentSize().width/2,desc_bg:getContentSize().height/2)
    if alliance_data.id == Alliance_Manager:GetMyAlliance()._id then
        self:BuildOneButton("icon_goto_38x56.png",_("定位")):onButtonClicked(function()
            self:Located(self.mapIndex)
        end):addTo(layer):align(display.RIGHT_TOP, l_size.width,10)
    else
        self:BuildOneButton("attack_58x56.png",_("宣战")):onButtonClicked(function()
            if alliance_data.status =="fight" or alliance_data.status=="prepare" then
                UIKit:showMessageDialog(_("提示"),_("联盟正在战争准备期或战争期"))
                return
            end
            if alliance_data.status ~= "peace" then
                UIKit:showMessageDialog(_("提示"),_("目标联盟未处于和平期，不能宣战"))
                return
            end
            if Alliance_Manager:GetMyAlliance().basicInfo.status ~= "peace" and Alliance_Manager:GetMyAlliance().basicInfo.status ~= "protect" then
                UIKit:showMessageDialog(_("提示"),_("联盟正在战争准备期或战争期"))
                return
            end
            if not Alliance_Manager:GetMyAlliance():GetMemeberById(User:Id()):IsTitleEqualOrGreaterThan("general") then
                UIKit:showMessageDialog(_("提示"),_("联盟操作权限不足"))
                return
            end
            UIKit:showMessageDialog(_("主人"),_("确定开启联盟会战吗?")):CreateOKButton(
                {
                    listener = function ()
                        NetManager:getAttackAlliancePromose(alliance_data.id)
                        self:LeftButtonClicked()
                    end
                }
            )
        end):addTo(layer):align(display.RIGHT_TOP, l_size.width,10)
        self:BuildOneButton("icon_goto_38x56.png",_("定位")):onButtonClicked(function()
            self:Located(self.mapIndex)
        end):addTo(layer):align(display.RIGHT_TOP, l_size.width - 125,10)
        self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
            UIKit:newGameUI("GameUIAllianceInfo", alliance_data.id):AddToCurrentScene(true)
        end):addTo(layer):align(display.RIGHT_TOP, l_size.width - 2 * 125,10)
    end
    return layer
end

function WidgetWorldAllianceInfo:GetAllianceArchonName()
    return self:GetAllianceData().archon.name
end
function WidgetWorldAllianceInfo:BuildOneButton(image,title,music_info)
    local btn = WidgetPushButton.new({normal = "btn_138x110.png",pressed = "btn_pressed_138x110.png"},{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }
        ,music_info)
    local s = btn:getCascadeBoundingBox().size
    display.newSprite(image):align(display.CENTER, -s.width/2, -s.height/2+12):addTo(btn)
    UIKit:ttfLabel({
        text =  title,
        size = 18,
        color = 0xffedae,
    }):align(display.CENTER, -s.width/2 , -s.height+25):addTo(btn)
    btn:setTouchSwallowEnabled(true)
    return btn
end


function WidgetWorldAllianceInfo:LoadMoveAlliance()
    local body = self.body
    local b_size = body:getContentSize()
    local mapIndex = self.mapIndex
    local round = DataUtils:getMapRoundByMapIndex(mapIndex)
    local needPalaceLevel = moveLimit[round].needPalaceLevel
    local palaceLevel = Alliance_Manager:GetMyAlliance():GetAllianceBuildingInfoByName("palace").level
    UIKit:createLineItem(
        {
            width = 548,
            text_1 = string.format(_("第%d圈"),round + 1),
            text_2 = {string.format(_("需要联盟宫殿 Lv%s"),needPalaceLevel),palaceLevel >= needPalaceLevel and 0x007c23 or 0x7e0000},
        }
    ):align(display.CENTER_TOP, b_size.width/2 , b_size.height - 50):addTo(body)

    local move_time = UIKit:createLineItem(
        {
            width = 548,
            text_1 = _("迁移冷却时间"),
            text_2 = {"",0x007c23},
        }
    ):align(display.CENTER_TOP, b_size.width/2 , b_size.height - 90):addTo(body)

    scheduleAt(self,function ()
        local time = intInit.allianceMoveColdMinutes.value * 60 + Alliance_Manager:GetMyAlliance().basicInfo.allianceMoveTime/1000.0 - app.timer:GetServerTime()
        local canMove = Alliance_Manager:GetMyAlliance().basicInfo.allianceMoveTime == 0 or time <= 0
        move_time:SetValue(canMove and _("准备就绪") or GameUtils:formatTimeStyle1(time),nil,canMove and 0x007c23 or 0x7e0000)
    end)
    local info_buff = WidgetInfo.new({
        info = DataUtils:GetAllianceMapBuffByRound(round),
        h = 340
    }):align(display.BOTTOM_CENTER, b_size.width/2 , 140)
        :addTo(body)

    local info = {
        _("当迁移时间就绪时，联盟可进行一次免费的迁移。迁移联盟时，针对联盟外目标的行军事件会被强制召回。"),
        _("迁移联盟需要将军以上的权限的玩家操作。"),
    }
    local origin_y, gap_y = 120, 40
    local pre_label
    for i,v in ipairs(info) do
        local y =  origin_y - (pre_label and (pre_label:getContentSize().height + 10) or 0)
        display.newSprite("icon_star_22x20.png"):align(display.LEFT_TOP, 40,y)
            :addTo(body)
        pre_label = UIKit:ttfLabel({
            text = v,
            size = 18,
            color = 0x403C2F,
            dimensions = cc.size(500,0)
        }):align(display.LEFT_TOP, 60,y)
            :addTo(body)
        origin_y = y
    end

    self:BuildOneButton("icon_move_alliance_building.png",_("迁移")):onButtonClicked(function()
        local alliance = Alliance_Manager:GetMyAlliance()
        local time = intInit.allianceMoveColdMinutes.value * 60 + alliance.basicInfo.allianceMoveTime/1000.0 - app.timer:GetServerTime()
        local canMove = alliance.basicInfo.status ~= "prepare" and alliance.basicInfo.status ~= "fight"
        if not canMove then
            UIKit:showMessageDialog(_("提示"), _("联盟正在战争准备期或战争期"))
            self:LeftButtonClicked()
            return
        end
        local canMove = alliance.basicInfo.allianceMoveTime == 0 or time <= 0
        if not canMove then
            UIKit:showMessageDialog(_("提示"), _("迁移联盟冷却中"))
            self:LeftButtonClicked()
            return
        end
        local mapIndex = self.mapIndex
        local canMove1 = palaceLevel >= needPalaceLevel
        if not canMove1 then
            UIKit:showMessageDialog(_("提示"), _("联盟宫殿等级不足,不能移动到目标地块"))
            self:LeftButtonClicked()
            return
        end
        local canMove1 = alliance:GetSelf():CanMoveAlliance()
        if not canMove1 then
            UIKit:showMessageDialog(_("提示"), _("需盟主或将军权限才能迁移！"))
            self:LeftButtonClicked()
            return
        end
        UIKit:showMessageDialog(_("提示"),_("是否确认迁移联盟至该领土？"),function()
            local oldIndex = alliance.mapIndex
            Alliance_Manager.my_mapIndex = nil
            NetManager:getMoveAlliancePromise(mapIndex):done(function()
                Alliance_Manager:RemoveAllianceCache(oldIndex)
                Alliance_Manager:UpdateAllianceBy(mapIndex, Alliance_Manager:GetMyAlliance())
                if UIKit:GetUIInstance("GameUIWorldMap") then
                    UIKit:GetUIInstance("GameUIWorldMap"):GetSceneLayer()
                        :MoveAllianceFromTo(oldIndex, mapIndex)
                else
                    UIKit:newGameUI("GameUIWorldMap", oldIndex, mapIndex):AddToCurrentScene()
                end
            end)
            self:LeftButtonClicked()
        end)
    end):addTo(body):align(display.RIGHT_TOP, b_size.width,10)
    if self.need_goto_btn then
        self:BuildOneButton("icon_goto_38x56.png",_("定位")):onButtonClicked(function()
            self:Located(self.mapIndex)
        end):addTo(body):align(display.RIGHT_TOP, b_size.width - 130,10)
    end
end
return WidgetWorldAllianceInfo

























