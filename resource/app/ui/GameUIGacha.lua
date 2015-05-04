--
-- Author: Kenny Dai
-- Date: 2015-03-03 09:46:36
--
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local window = import("..utils.window")
local Localize_item = import("..utils.Localize_item")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetGachaItemBox = import("..widget.WidgetGachaItemBox")
local intInit = GameDatas.PlayerInitData.intInit

local NORMAL = GameDatas.Gacha.normal
local ADVANCED = GameDatas.Gacha.advanced

local GameUIGacha = UIKit:createUIClass("GameUIGacha","GameUIWithCommonHeader")

function GameUIGacha:ctor(city)
    GameUIGacha.super.ctor(self,city, _("游乐场"))
end

function GameUIGacha:CreateBetweenBgAndTitle()
    GameUIGacha.super.CreateBetweenBgAndTitle(self)

    self.ordinary_layer = display.newLayer():addTo(self:GetView())

    self.deluxe_layer = display.newLayer():addTo(self:GetView())
end

function GameUIGacha:OnMoveInStage()
    GameUIGacha.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("普通抽奖"),
            tag = "ordinary",
            default = true
        },
        {
            label = _("高级抽奖"),
            tag = "deluxe",
        },
    }, function(tag)
        if tag == 'ordinary' then
            self.ordinary_layer:setVisible(true)
            if not self.isOrdinaryInit then
                self:InitOrdinary()
            end
        else
            self.ordinary_layer:setVisible(false)
        end
        if tag == 'deluxe' then
            self.deluxe_layer:setVisible(true)
            if not self.isDeluxeInit then
                self:InitDeluxe()
            end
        else
            self.deluxe_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)

    User:AddListenOnType(self,User.LISTEN_TYPE.COUNT_INFO)
end
function GameUIGacha:onExit()
    if self.OrdinaryGachaPool then
        self.OrdinaryGachaPool:Destory()
    end
    if self.DeluxeGachaPool then
        self.DeluxeGachaPool:Destory()
    end
    User:RemoveListenerOnType(self,User.LISTEN_TYPE.COUNT_INFO)
    GameUIGacha.super.onExit(self)
end

-- 创建所有gacha物品item:普通抽奖，高级抽奖通用
function GameUIGacha:CreateGachaPool(layer)
    local main = self
    local GachaPool = {}



    local items = {}
    local x , y = window.left+138,window.top - 208
    local box_width = 112
    local gap = (570 - 5*box_width)/4
    -- 奖品，是否高级抽奖
    local isSenior
    if layer== self.deluxe_layer then
        isSenior = true
    end
    -- 转盘
    local disk_img_1,disk_img_2
    if isSenior then
        disk_img_1 = "gacha_disk_4.png"
        disk_img_2 = "gacha_disk_5.png"
    else
        disk_img_1 = "gacha_disk_1.png"
        disk_img_2 = "gacha_disk_2.png"
    end
    local disk_1 = display.newSprite(disk_img_1):addTo(layer)
        :align(display.CENTER, window.cx, window.top_bottom-390)
    local disk_2 = display.newSprite(disk_img_2):addTo(layer)
        :align(display.CENTER, window.cx, window.top_bottom-390)
    local disk_3 = display.newSprite("gacha_disk_3.png"):addTo(layer)
        :align(display.CENTER, window.cx, window.top_bottom-390)

    -- 抽到物品背景
    local draw_thing_bg  = display.newSprite("back_ground_320x172.png"):addTo(layer)
        :align(display.CENTER, window.cx, window.top_bottom-510)
    -- 当前赌币
    display.newSprite("icon_casinoToken.png"):addTo(draw_thing_bg)
        :align(display.CENTER, 120,122):scale(0.3)
    local city = self.city
    layer.current_casinoToken_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(city:GetResourceManager():GetCasinoTokenResource():GetValue()),
        size = 18,
        color = 0xffd200,
    }):addTo(draw_thing_bg):align(display.CENTER,170,118)

    local gacha_boxes = {}
    if isSenior then
        table.insert(gacha_boxes,  display.newSprite("box_gacha_92x92.png"):addTo(layer)
            :align(display.CENTER, window.cx-105, window.top_bottom-390))
        table.insert(gacha_boxes,  display.newSprite("box_gacha_92x92.png"):addTo(layer)
            :align(display.CENTER, window.cx, window.top_bottom-390))
        table.insert(gacha_boxes,  display.newSprite("box_gacha_92x92.png"):addTo(layer)
            :align(display.CENTER, window.cx+105, window.top_bottom-390))
    else
        table.insert(gacha_boxes,  display.newSprite("box_gacha_92x92.png"):addTo(layer)
            :align(display.CENTER, window.cx, window.top_bottom-390))
    end

    -- 打乱gacha物品的顺序
    local gacha_item_table = {}
    local temp_table
    if isSenior then
        temp_table = ADVANCED
    else
        temp_table = NORMAL
    end
    for i,v in ipairs(temp_table) do
        table.insert(gacha_item_table, v)
    end
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    for i=1,10 do
        local round_num = math.random(1,#gacha_item_table)
        local remove_element = table.remove(gacha_item_table,round_num)
        table.insert(gacha_item_table,remove_element)
    end


    -- 当前所在位置
    local current_box,current_index
    for i=1,16 do

        local gahca_box =WidgetGachaItemBox.new(gacha_item_table[i],isSenior):addTo(layer,2)
        if i<6 then
            if i>1 then
                x = x+box_width+gap
            end
            gahca_box:pos( x , y )
        elseif i>5 and i <10 then
            y = y-box_width-gap
            gahca_box:pos( x , y )
        elseif i>9 and i <14 then
            x = x-box_width-gap
            gahca_box:pos( x , y )
        elseif i>13 then
            y = y+box_width+gap
            gahca_box:pos( x , y )
        end
        items[i] = gahca_box
        if i==1 then
            gahca_box:SetOrginStatus()
            current_box = gahca_box
            current_index = i
        end
    end

    function GachaPool:ChangeDiskSpeed(speed)
        self.disk_speed = speed
    end
    function GachaPool:DiskRotate()
        local temp_rotate = self.current_rotate or 1
        temp_rotate = temp_rotate + self.disk_speed
        disk_2:setRotation(temp_rotate)
        self.current_rotate = temp_rotate
    end
    function GachaPool:RemoveDiskSchedule()
        if self.disk_handle then
            scheduler.unscheduleGlobal(self.disk_handle)
            self.disk_handle = nil
        end
    end
    function GachaPool:ResetPool()
        for i,v in ipairs(items) do
            v:RemoveSelectStatus()
            v:ResetLigt()
        end
        if self.award then
            for i,v in ipairs(self.award) do
                layer:removeChild(v, true)
            end
            self.award = {}
        end
        current_box = items[1]
        current_index = 1
        current_box:SetOrginStatus()
    end

    function GachaPool:SkipByStep()
        -- 是否顺时针
        local gap = 1
        current_box:ResetLigt()
        -- 下一个位置，小于16则+1，否则为1
        local temp_index = current_index + gap
        local next_index = ( temp_index>16 or temp_index<1) and 1 or temp_index
        local temp_box = items[next_index]
        temp_box:SetPassStatus()
        current_box = temp_box
        current_index = next_index
        app:GetAudioManager():PlayeEffectSound("sfx_gacha.mp3")
    end
    function GachaPool:Stop()
        current_box:ResetLigt()
        current_box:SetSelectedStatus()
        self.run_steps = 0
        -- self:ChangeDiskSpeed(1)

        local draw_item_box = self.draw_item_box
        local award = display.newScale9Sprite(draw_item_box:GetGachaItemIcon()):addTo(layer,2)
            :align(display.CENTER, draw_item_box:getPositionX()-draw_item_box:getContentSize().width/2, draw_item_box:getPositionY()-draw_item_box:getContentSize().height/2)
        award:scale(74/award:getContentSize().width)

        local gacha_box = self.continuous_draw_items and gacha_boxes[self.continuous_index-1] or gacha_boxes[1]
        -- local gacha_box_lable

        app:GetAudioManager():PlayeEffectSoundWithKey("BUY_ITEM")
        transition.scaleTo(award, {scale = 1.5,time =0.4,onComplete = function ()
            transition.moveTo(award, {x = gacha_box:getPositionX(), y=gacha_box:getPositionY() ,time =0.2 ,
                onComplete = function ( )
                    transition.scaleTo(award, {scale = 74/award:getContentSize().width,time =0.4,onComplete = function ()
                        -- gacha_box_lable = UIKit:ttfLabel({
                        --     text = Localize_item.item_name[draw_item_box:GetGachaItemName()],
                        --     size = 20,
                        --     color = 0xffedae,
                        -- }):align(display.CENTER, gacha_box:getPositionX(), gacha_box:getPositionY()-56):addTo(layer)
                        if self.continuous_draw_items and not self.continuous_draw_items[self.continuous_index] or not self.continuous_draw_items then
                            layer:EnAbleButton(true)
                        end
                        table.insert(self.award, award)
                        -- table.insert(self.award, gacha_box_lable)
                        GameGlobalUI:showTips(_("提示"),string.format(_('获得%s x%d'),Localize_item.item_name[self.current_gacha_item_name],self.current_gacha_item_count))
                        if self.continuous_draw_items and self.continuous_draw_items[self.continuous_index] then
                            self:StartLotteryDraw(self.continuous_draw_items[self.continuous_index])
                            self.continuous_index = self.continuous_index + 1
                        else
                            self.continuous_draw_items = nil
                            -- 恢复ui退出home_button
                            main:GetHomeButton():setButtonEnabled(true)
                        end
                        award:setLocalZOrder(1)
                    end})
                end })
        end})


    end
    -- 三连抽
    function GachaPool:StartLotteryDrawThree(item_names)
        self.award ={} -- 抽到物品的图标和名字node,开启下次抽奖需移除
        local continuous_index = 1
        self.continuous_draw_items = item_names
        self:StartLotteryDraw(item_names[continuous_index])
        self.continuous_index = continuous_index + 1
    end
    function GachaPool:StartLotteryDraw(item)
        -- 禁用ui退出home_button
        main:GetHomeButton():setButtonEnabled(false)
        self.award =self.award or {} -- 抽到物品的图标和名字node,开启下次抽奖需移除
        local item_name = item[1]
        self.current_gacha_item_count = item[2]
        self.current_gacha_item_name = item_name
        layer:EnAbleButton(false)
        local terminal_point
        for i,item in ipairs(items) do
            if item:GetGachaItemName() == item_name then
                terminal_point = i
                -- 存在抽到的道具box对象，以便之后获取其位置做抽到奖品动画效果
                self.draw_item_box = item
            end
        end

        -- 随机转几圈
        math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        local round_num = math.random(3,5)
        -- 总共要跳动的格子数
        self.total_steps = round_num*16+terminal_point - current_index
        -- 当前计时器周期
        self.current_period = 0.005
        -- 跳动步子参数，越慢的计时器行走的格子数越少
        self.step_offset = 10
        if self.handle then
            scheduler.unscheduleGlobal(self.handle)
            self.handle = nil
        end
        self.handle = scheduler.scheduleGlobal(handler(self, self.Run), self.current_period, false)

        -- 开始抽奖，加速转盘速度
        -- self:ChangeDiskSpeed(10)

    end
    function GachaPool:Run()
        -- 已经完成所有步数，则停止
        if self.run_steps and self.run_steps == self.total_steps then
            if self.handle then
                scheduler.unscheduleGlobal(self.handle)
                self.handle = nil
            end

            self:Stop()

            return
        end
        local run_steps = self.run_steps or 0

        self:SkipByStep()
        self.run_steps = run_steps + 1
        if self.handle then
            scheduler.unscheduleGlobal(self.handle)
            self.handle = nil
            if self.total_steps-self.run_steps<10 then
                self.current_period = self.current_period + 0.03
            elseif self.total_steps-self.run_steps<40 then
                self.current_period = self.current_period + 0.001
            end
            self.handle = scheduler.scheduleGlobal(handler(self, self.Run), self.current_period, false)
            -- if self.total_steps-self.run_steps<10 then
            -- -- self:ChangeDiskSpeed(self.total_steps-self.run_steps)
            -- end
        end
    end
    function GachaPool:IsRunning()
        return self.handle
    end
    function GachaPool:Destory()
        self:RemoveDiskSchedule()
        if self.handle then
            scheduler.unscheduleGlobal(self.handle)
            self.handle = nil
        end
    end
    -- 创建成功，转盘默然旋转
    GachaPool.disk_speed = 1
    GachaPool.disk_handle = scheduler.scheduleGlobal(handler(GachaPool, GachaPool.DiskRotate), 0.01, false)

    return GachaPool
end
-- 获取装饰亮条
function GameUIGacha:GetLightLine(isSenior)
    local img_1,img_2
    if isSenior then
        img_1,img_2="gacha_line_16x564_1.png","gacha_line_16x564_2.png"
    else
        img_1,img_2="gacha_line_20x568_1.png","gacha_line_20x568_2.png"
    end

    local patten , w,h
    if isSenior then
        patten = "gacha_line_16x564_%d.png"
        w,h = 16,564
    else
        patten = "gacha_line_20x568_%d.png"
        w,h = 20,568
    end
    local srpite_frame_1 = cc.SpriteFrame:create(img_1,cc.rect(0,0,w,h))
    local srpite_frame_2 = cc.SpriteFrame:create(img_2,cc.rect(0,0,w,h))
    local light_line = display.newSprite(img_1)

    cc.SpriteFrameCache:getInstance():addSpriteFrame(srpite_frame_1,img_1)
    cc.SpriteFrameCache:getInstance():addSpriteFrame(srpite_frame_2,img_2)
    local frames = display.newFrames(patten, 1, 2)
    local animation = display.newAnimation(frames, 0.2)
    light_line:playAnimationForever(animation)
    return light_line
end
function GameUIGacha:InitOrdinary()
    local main = self
    local layer = self.ordinary_layer
    self.isOrdinaryInit = display.newSprite("background_gacha_1.jpg"):addTo(layer)
        :align(display.TOP_CENTER, window.cx, window.top_bottom+36)
    UIKit:ttfLabel({
        text = _("每日获得免费抽奖机会，激活VIP5 以上，每日可获得额外的免费抽奖机会"),
        size = 22,
        color = 0xffedae,
        dimensions = cc.size(400,0)
    }):align(display.CENTER, window.cx, window.top_bottom-50):addTo(layer)
    local OrdinaryGachaPool = self:CreateGachaPool(layer)



    -- 两侧亮条
    local line_1 = self:GetLightLine(false):align(display.TOP_CENTER, window.left+32, window.top-200):addTo(layer)
    local line_2 = self:GetLightLine(false):align(display.TOP_CENTER, window.right-31, window.top-200):addTo(layer)

    local button = WidgetPushButton.new({normal = "green_btn_up_252x78.png",pressed = "green_btn_down_252x78.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabelOffset(0,20)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if User:GetOddFreeNormalGachaCount()<1 and self.city:GetResourceManager():GetCasinoTokenResource():GetValue()<intInit.casinoTokenNeededPerNormalGacha.value then
                    UIKit:showMessageDialog(_("提示"),_("赌币不足"))
                else
                    NetManager:getNormalGachaPromise():done(function(response)
                        if response.msg.playerData then
                            local data = response.msg.playerData
                            local items = {}
                            for i,v in ipairs(data) do
                                local key = string.split(v[1], ".")[1]
                                if key == "items" then
                                    items[1] = v[2].name
                                    items[2] = v[2].count
                                end
                            end
                            -- 首先重置gacha池
                            self.OrdinaryGachaPool:ResetPool()
                            self.OrdinaryGachaPool:StartLotteryDraw(items)
                        end
                    end)
                end
            end
        end)
        :align(display.CENTER, window.cx+5, window.bottom+150)
        :addTo(layer)
    -- 是否有免费抽奖次数
    if User:GetOddFreeNormalGachaCount()>0 then
        button:setButtonLabel(UIKit:commonButtonLable({
            text = _("免费抽奖"),
            size = 24
        }))
            :setButtonLabelOffset(0,0)

        local btn_images = {normal = "green_btn_up_252x77.png",
            pressed = "green_btn_down_252x77.png"
        }
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, btn_images["normal"], true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, btn_images["pressed"], true)
    else
        button:setButtonLabel(UIKit:commonButtonLable({
            text = _("开始抽奖")
        }))
        -- 抽奖一次需要赌币
        display.newSprite("icon_casinoToken.png"):addTo(button,1,111)
            :align(display.CENTER, -72,-8):scale(0.4)

        UIKit:ttfLabel({
            text = string.formatnumberthousands(intInit.casinoTokenNeededPerNormalGacha.value),
            size = 18,
            color = 0xffd200,
        }):addTo(button,1,112):align(display.CENTER,0,-12)
    end

    self.normal_gacha_button = button
    function layer:EnAbleButton(enabled)
        button:setButtonEnabled(enabled)
    end
    self.OrdinaryGachaPool = OrdinaryGachaPool
end

function GameUIGacha:InitDeluxe()
    local main = self
    local layer = self.deluxe_layer
    self.isDeluxeInit = display.newSprite("background_gacha_2.jpg"):addTo(layer)
        :align(display.TOP_CENTER, window.cx, window.top_bottom+36)
    UIKit:ttfLabel({
        text = _("购买任意金额的金龙币可以解锁高级抽奖,高级抽奖一次可以获得三种不同的道具"),
        size = 22,
        color = 0xffedae,
        dimensions = cc.size(400,0)
    }):align(display.CENTER, window.cx, window.top_bottom-50):addTo(layer)


    -- 两侧亮条
    local line_1 = self:GetLightLine(true):align(display.TOP_CENTER, window.left+32, window.top-200):addTo(layer)
    local line_2 = self:GetLightLine(true):align(display.TOP_CENTER, window.right-31, window.top-200):addTo(layer)

    local DeluxeGachaPool = self:CreateGachaPool(layer)
    local button = WidgetPushButton.new({normal = "yellow_btn_up_252x78.png",pressed = "yellow_btn_down_252x78.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("开始抽奖")
        }))
        :setButtonLabelOffset(0,20)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if self.city:GetResourceManager():GetCasinoTokenResource():GetValue()<intInit.casinoTokenNeededPerAdvancedGacha.value then
                    UIKit:showMessageDialog(_("提示"),_("赌币不足"))
                else
                    NetManager:getAdvancedGachaPromise():done(function(response)
                        if response.msg.playerData then
                            local data = response.msg.playerData
                            local items = {}
                            for i,v in ipairs(data) do
                                local key = string.split(v[1], ".")[1]
                                if key == "items" then
                                    table.insert(items, {v[2].name,v[2].count})
                                end
                            end
                            -- 首先重置gacha池
                            self.DeluxeGachaPool:ResetPool()
                            self.DeluxeGachaPool:StartLotteryDrawThree(items)
                        end
                    end)
                end
            end
        end)
        :align(display.CENTER, window.cx+5, window.bottom+150)
        :addTo(layer)

    -- 抽奖一次需要赌币
    display.newSprite("icon_casinoToken.png"):addTo(button)
        :align(display.CENTER, -72,-8):scale(0.4)

    UIKit:ttfLabel({
        text = string.formatnumberthousands(intInit.casinoTokenNeededPerAdvancedGacha.value),
        size = 18,
        color = 0xffd200,
    }):addTo(button):align(display.CENTER,0,-12)
    self.DeluxeGachaPool = DeluxeGachaPool
    function layer:EnAbleButton(enabled)
        button:setButtonEnabled(enabled)
    end
end
function GameUIGacha:OnResourceChanged(resource_manager)
    GameUIGacha.super.OnResourceChanged(self,resource_manager)
    if self.ordinary_layer.current_casinoToken_label then
        self.ordinary_layer.current_casinoToken_label:setString(string.formatnumberthousands(resource_manager:GetCasinoTokenResource():GetValue()))
    end
    if self.deluxe_layer.current_casinoToken_label then
        self.deluxe_layer.current_casinoToken_label:setString(string.formatnumberthousands(resource_manager:GetCasinoTokenResource():GetValue()))
    end
end

function GameUIGacha:OnCountInfoChanged()
    if User:GetOddFreeNormalGachaCount()>0 then
        local button = self.normal_gacha_button
        button:setButtonLabel(UIKit:commonButtonLable({
            text = _("免费抽奖"),
            size = 24

        })):setButtonLabelOffset(0,0)

        local btn_images = {normal = "green_btn_up_250x65.png",
            pressed = "green_btn_down_250x65.png"
        }
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, btn_images["normal"], true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, btn_images["pressed"], true)
    else
        local button = self.normal_gacha_button
        button:setButtonLabel(UIKit:commonButtonLable({
            text = _("开始抽奖"),
            size = 20
        })):setButtonLabelOffset(0,20)

        local btn_images = {normal = "green_btn_up_252x78.png",
            pressed = "green_btn_down_252x78.png"
        }
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, btn_images["normal"], true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, btn_images["pressed"], true)

        button:removeChildByTag(111, true)
        button:removeChildByTag(112, true)
        button:setButtonEnabled(not self.OrdinaryGachaPool:IsRunning())
        -- 抽奖一次需要赌币
        display.newSprite("icon_casinoToken.png"):addTo(button,1,111)
            :align(display.CENTER, -72,-8):scale(0.4)

        UIKit:ttfLabel({
            text = string.formatnumberthousands(intInit.casinoTokenNeededPerNormalGacha.value),
            size = 18,
            color = 0xffd200,
        }):addTo(button,1,112):align(display.CENTER,0,-12)
    end
end
return GameUIGacha













