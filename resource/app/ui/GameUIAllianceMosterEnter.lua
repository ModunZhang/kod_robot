--
-- Author: Kenny Dai
-- Date: 2015-07-09 17:05:27
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local window = import("..utils.window")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local monsterConfig = GameDatas.AllianceInitData.monsters

local GameUIAllianceMosterEnter = class("GameUIAllianceMosterEnter", WidgetPopDialog)

function GameUIAllianceMosterEnter:ctor(mapObj,alliance)
    self.mapObj = mapObj
    self.entity = alliance:GetMapObjectInfoByObject(mapObj)
    self.isMyAlliance = mapObj.index == Alliance_Manager:GetMyAlliance():MapIndex()
    self.alliance = alliance
    local moster = self:GetBuildingInfo()
    self.moster_config = monsterConfig[moster.level]
    self.moster = moster

    local corps = string.split(monsterConfig[moster.level].soldiers, ";")
    local soldiers = string.split(corps[moster.index + 1], ",")

    local moster_config = self.moster_config
    local icon = string.split(soldiers[1],":")
    local soldier_type = icon[1]
    GameUIAllianceMosterEnter.super.ctor(self,286,Localize.soldier_name[soldier_type],window.top - 200,"title_red_600x56.png")
    display.newNode():addTo(self):schedule(function()
        if not self:GetBuildingInfo() then
            self:LeftButtonClicked()
        end
    end, 1)
end
function GameUIAllianceMosterEnter:onCleanup()
    local scene_name = display.getRunningScene().__cname
    if scene_name == 'AllianceScene' then
        for k,v in pairs(display.getRunningScene():GetSceneLayer():GetAllianceViews()) do
            if v:GetMapObjectById(self.entity.id) then
                v:GetMapObjectById(self.entity.id):Unlock()
            end
        end
    end
    GameUIAllianceMosterEnter.super.onCleanup(self)
end
function GameUIAllianceMosterEnter:onExit()
    scheduler.unscheduleGlobal(self.handle)
    GameUIAllianceMosterEnter.super.onExit(self)
end
function GameUIAllianceMosterEnter:onEnter()
    GameUIAllianceMosterEnter.super.onEnter(self)
    local alliance = self.alliance
    local isMyAlliance = self.isMyAlliance
    local entity = self.entity
    local moster = self.moster
    local moster_config = self.moster_config
    local rewards = string.split(moster_config.rewards,",")

    local corps = string.split(monsterConfig[moster.level].soldiers, ";")
    local soldiers = string.split(corps[moster.index + 1], ",")

    local icon = string.split(soldiers[1],":")
    local soldier_type = icon[1]
    local soldier_star = tonumber(icon[2])
    local level = moster_config.level

    local body = self:GetBody()
    local b_size = body:getContentSize()
    local b_width , b_height = b_size.width , b_size.height
    -- 下次刷新野怪时间
    local header_bg = UIKit:CreateBoxPanelWithBorder({height = 58}):align(display.TOP_CENTER, b_width/2, b_height - 24):addTo(body)
    self.time_label = UIKit:ttfLabel({
        text = string.format(_("即将消失:%s"),GameUtils:formatTimeStyle1(alliance.basicInfo.monsterRefreshTime/1000 - app.timer:GetServerTime())),
        color = 0x6a1f10,
        size = 22,
    }):addTo(header_bg):align(display.CENTER, header_bg:getContentSize().width/2, header_bg:getContentSize().height/2)
    -- 怪物士兵头像
    local soldier_ui_config = UILib.black_soldier_image[soldier_type]
    display.newSprite(UILib.black_soldier_color_bg_images[soldier_type]):addTo(body)
        :align(display.CENTER_TOP,94, b_height-94):scale(130/128)

    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER_TOP,94, b_height-94)
    soldier_head_icon:scale(130/soldier_head_icon:getContentSize().height)
    display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
    body:addChild(soldier_head_icon)
    -- 等级
    local level_bg = WidgetUIBackGround.new({width = 130 , height = 36},WidgetUIBackGround.STYLE_TYPE.STYLE_3)
        :align(display.CENTER, soldier_head_icon:getPositionX(), soldier_head_icon:getPositionY() - 150):addTo(body)
    UIKit:ttfLabel({
        text = string.format(_("等级%d"),level),
        color = 0x514d3e,
        size = 22,
    }):addTo(level_bg):align(display.CENTER, level_bg:getContentSize().width/2, level_bg:getContentSize().height/2)

    local title_bg = display.newScale9Sprite("title_blue_430x30.png",soldier_head_icon:getPositionX() + 90, soldier_head_icon:getPositionY(), cc.size(390,30), cc.rect(10,10,410,10))
        :align(display.LEFT_TOP)
        :addTo(body)
    UIKit:ttfLabel({
        text = _("有几率获得"),
        color = 0xffedae,
        size = 20,
    }):addTo(title_bg):align(display.LEFT_CENTER, 10, title_bg:getContentSize().height/2)

    -- 创建奖励node
    local reward_table = {}
    local origin_x,origin_y,gap_x ,added_count = soldier_head_icon:getPositionX() + 90,soldier_head_icon:getPositionY() - 85, 100,1
    for i,reward in ipairs(rewards) do
        local info = string.split(reward,":")
        local reward_node = display.newNode():setOpacity(i < 5 and 255 or 0)
        reward_node:setContentSize(cc.size(88,88))
        reward_node:addTo(body):align(display.LEFT_CENTER, origin_x + (added_count - 1) * gap_x, origin_y)
        local reward_box = display.newSprite("box_118x118.png"):addTo(reward_node):align(display.CENTER, 44 , 44):scale(88/118)
        local material_icon = display.newSprite(UILib.materials[info[2]] or UILib.item[info[2]])
            :align(display.CENTER, 44 , 44)
            :addTo(reward_node)
        material_icon:scale(74/math.max(material_icon:getContentSize().width,material_icon:getContentSize().height))
        local num_bg = display.newSprite("gacha_num_bg.png"):addTo(reward_node):align(display.CENTER, 64,14)
        UIKit:ttfLabel({
            text = "X "..info[3],
            size = 16,
            color = 0xffedae
        }):align(display.RIGHT_CENTER, num_bg:getContentSize().width, num_bg:getContentSize().height/2)
            :addTo(num_bg)
        UIKit:ttfLabel({
            text = info[1] == "buildingMaterials" and  Localize.materials[info[2]] or Localize_item.item_name[info[2]],
            color = 0x615b44,
            size = 16,
        }):addTo(reward_node):align(display.CENTER, 44 ,- 16)
        if added_count + 1 > 4 then
            added_count = 1
        else
            added_count = added_count + 1
        end
        table.insert(reward_table, reward_node)
    end
    local show_reward_index = 5
    self:performWithDelay(function()
        scheduleAt(self, function()
            local end_index = show_reward_index + 4
            for i,reward_node in ipairs(reward_table) do
                if i < end_index and i >= show_reward_index then
                    reward_node:runAction(cc.FadeTo:create(0.4, 255))
                else
                    if reward_node:isVisible() then
                        reward_node:runAction(cc.FadeTo:create(0.4, 0))
                    end
                end
            end
            show_reward_index = end_index > #reward_table and 1 or end_index
        end,2)
    end, 2)
    -- local clipNode = display.newClippingRegionNode(cc.rect(soldier_head_icon:getPositionX() + 90 ,20,380,150)):addTo(body)
    -- local rewards_node = display.newNode():addTo(clipNode)
    -- rewards_node:setContentSize(cc.size(#rewards * 100,100))
    -- rewards_node:align(display.LEFT_CENTER, 0, 50)
    -- for i,reward in ipairs(rewards) do
    --     local info = string.split(reward,":")
    --     display.newSprite("box_118x118.png"):addTo(rewards_node):align(display.CENTER, 44 + (i - 1) * 100, 100):scale(88/118)
    --     local material_icon = display.newSprite(UILib.materials[info[2]] or UILib.item[info[2]])
    --         :align(display.CENTER, 44 + (i - 1) * 100, 100)
    --         :addTo(rewards_node)
    --     material_icon:scale(74/math.max(material_icon:getContentSize().width,material_icon:getContentSize().height))
    --     local num_bg = display.newSprite("gacha_num_bg.png"):addTo(rewards_node):align(display.CENTER, 64 + (i - 1) * 100,70)
    --     UIKit:ttfLabel({
    --         text = "X "..info[3],
    --         size = 16,
    --         color = 0xffedae
    --     }):align(display.RIGHT_CENTER, num_bg:getContentSize().width, num_bg:getContentSize().height/2)
    --         :addTo(num_bg)
    --     UIKit:ttfLabel({
    --         text = info[1] == "buildingMaterials" and  Localize.materials[info[2]] or Localize_item.item_name[info[2]],
    --         -- text = "X "..info[3],
    --         color = 0x615b44,
    --         size = 16,
    --     -- ellipsis = true,
    --     -- dimensions = cc.size(90,20)
    --     }):addTo(rewards_node):align(display.CENTER, 44 + (i - 1) * 100 ,40)
    -- end

    -- rewards_node:runAction(cc.RepeatForever:create(transition.sequence{
    --     cc.MoveTo:create(10, cc.p(soldier_head_icon:getPositionX() + 90 - rewards_node:getContentSize().width, 50)),
    --     cc.CallFunc:create(function()
    --         rewards_node:setPositionX(soldier_head_icon:getPositionX() + 90 + 380)
    --     end)
    -- }))

    self.handle = scheduler.scheduleGlobal(handler(self, self.ShowReward), 1, false)


    -- 进攻按钮
    local entity = self.entity
    local mapObj = self.mapObj
    local my_alliance = Alliance_Manager:GetMyAlliance()
    local alliance = self:GetBelongAlliance()
    local btn = WidgetPushButton.new({normal = "btn_138x110.png",pressed = "btn_pressed_138x110.png"},{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }):onButtonClicked(function()
        local final_func = function ()
            local attack_monster_func = function ()
                UIKit:newGameUI('GameUISendTroopNew',function(dragonType,soldiers,total_march_time,GameUISendTroopNew)
                    local scene_name = display.getRunningScene().__cname
                    if not alliance:FindAllianceMonsterInfoByObject(mapObj) then
                        UIKit:showMessageDialog(_("提示"),_("敌人已经消失了"))
                        return
                    end
                    NetManager:getAttackMonsterPromise(dragonType,soldiers,alliance._id,entity.id):done(function()
                        app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                    end)
                end,{targetAlliance = alliance,toLocation = entity.location,returnCloseAction = false}):AddToCurrentScene(true)
            end
            UIKit:showSendTroopMessageDialog(attack_monster_func,"buildingMaterials",_("建筑"))
        end

        if my_alliance:GetSelf():IsProtected() then
            UIKit:showMessageDialog(_("提示"),_("进攻该目标将失去保护状态，确定继续派兵?"),final_func)
        else
            final_func()
        end
        end):addTo(body):align(display.RIGHT_TOP, b_width, 10)
    local s = btn:getCascadeBoundingBox().size
    display.newSprite("attack_58x56.png"):align(display.CENTER, -s.width/2, -s.height/2+12):addTo(btn)
    UIKit:ttfLabel({
        text =  _("进攻"),
        size = 18,
        color = 0xffedae,
    }):align(display.CENTER, -s.width/2 , -s.height+25):addTo(btn)
    self.attack_btn = btn
end
function GameUIAllianceMosterEnter:ShowReward()
    local time = self.alliance.basicInfo.monsterRefreshTime/1000 - app.timer:GetServerTime()
    self.time_label:setString(time >= 0 and string.format(_("即将消失:%s"),GameUtils:formatTimeStyle1(time)) or _("未知"))
end

function GameUIAllianceMosterEnter:GetBuildingInfo()
    return self.alliance:FindAllianceMonsterInfoByObject(self.mapObj)
end
function GameUIAllianceMosterEnter:GetBelongAlliance()
    return self.alliance
end

return GameUIAllianceMosterEnter
























