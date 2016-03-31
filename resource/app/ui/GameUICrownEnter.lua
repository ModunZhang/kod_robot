--
-- Author: Kenny Dai
-- Date: 2016-03-15 09:16:51
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUICrownEnter = UIKit:createUIClass("GameUICrownEnter", "UIAutoClose")

function GameUICrownEnter:ctor(mapIndex)
    GameUICrownEnter.super.ctor(self)
    self.mapIndex = mapIndex
    local round = DataUtils:getMapRoundByMapIndex(mapIndex)
    self.body = display.newSprite("background_crown_enter.png"):align(display.TOP_CENTER,display.cx,display.top-140)
    local body = self.body
    self:addTouchAbleChild(body)
    -- 王冠
    local icon_crown = display.newSprite("icon_crown_110x94.png"):align(display.TOP_CENTER,311,470):addTo(body)
    -- 背景图
    local bg_img = display.newSprite("background_crown_454x154.png"):align(display.TOP_CENTER,311,350):addTo(body)
    -- 无人
    local head_bg = display.newSprite("dragon_bg_114x114.png")
        :align(display.TOP_CENTER,bg_img:getContentSize().width - 82,bg_img:getContentSize().height - 5)
        :addTo(bg_img)
        :scale(104/114)

    local icon_none = display.newSprite("icon_none_90x92.png")
        :align(display.TOP_CENTER,bg_img:getContentSize().width - 82,bg_img:getContentSize().height - 15)
        :addTo(bg_img)

    UIKit:ttfLabel({
        text = _("位置"),
        color= 0x615b44,
        size = 20
    }):align(display.LEFT_BOTTOM, 90, 160):addTo(body)

    UIKit:ttfLabel({
        text = _("第1圈").."(430,430)",
        color= 0x403c2f,
        size = 20
    }):align(display.RIGHT_BOTTOM, 527, 160):addTo(body)

    UIKit:ttfLabel({
        text = _("阶段"),
        color= 0x615b44,
        size = 20
    }):align(display.LEFT_BOTTOM, 90, 120):addTo(body)

    UIKit:ttfLabel({
        text = _("无"),
        color= 0x403c2f,
        size = 20
    }):align(display.RIGHT_BOTTOM, 527, 120):addTo(body)

    UIKit:ttfLabel({
        text = _("国王"),
        color= 0x615b44,
        size = 20
    }):align(display.LEFT_BOTTOM, 90, 80):addTo(body)

    UIKit:ttfLabel({
        text = _("无"),
        color= 0x403c2f,
        size = 20
    }):align(display.RIGHT_BOTTOM, 527, 80):addTo(body)

    UIKit:ttfLabel({
        text = _("国家"),
        color= 0x615b44,
        size = 20
    }):align(display.LEFT_BOTTOM, 90, 40):addTo(body)

    UIKit:ttfLabel({
        text = _("无"),
        color= 0x403c2f,
        size = 20
    }):align(display.RIGHT_BOTTOM, 527, 40):addTo(body)

    self.mask_layer = display.newLayer():addTo(self, 2):hide()

    self:LoadMoveAlliance()
end
local function EnterIn(mapIndex)
    local worldmap = UIKit:GetUIInstance("GameUIWorldMap")
    if not worldmap then
        return
    end
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
function GameUICrownEnter:Located(mapIndex, x, y)
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
            scene:GotoAllianceByXY(scene:GetSceneLayer():IndexToLogic(mapIndex))
            EnterIn(mapIndex)
            self:LeftButtonClicked()
        end
    end
end

function GameUICrownEnter:BuildOneButton(image,title,music_info)
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

function GameUICrownEnter:LoadMoveAlliance()
    local body = self.body
    local b_size = body:getContentSize()
    self:BuildOneButton("icon_goto_38x56.png",_("定位")):onButtonClicked(function()
        self:Located(self.mapIndex)
    end):addTo(body):align(display.RIGHT_TOP, b_size.width - 10,10)
    self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
        UIKit:newGameUI("GameUIThroneMain"):AddToCurrentScene()
        self:LeftButtonClicked()
    end):addTo(body):align(display.RIGHT_TOP, b_size.width - 140 ,10)
end
return GameUICrownEnter


