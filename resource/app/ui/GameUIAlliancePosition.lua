local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")

local GameUIAlliancePosition = class("GameUIAlliancePosition",WidgetPopDialog)

function GameUIAlliancePosition:ctor()
    -- 根据是否处于联盟战状态构建不同UI
    local my_alliance = Alliance_Manager:GetMyAlliance()
    local height = 258
    GameUIAlliancePosition.super.ctor(self,height,_("定位坐标"),window.top-200)
    local body = self.body
    -- 联盟名字
    UIKit:ttfLabel({
        text = "["..my_alliance.basicInfo.tag.."]"..my_alliance.basicInfo.name,
        size = 20,
        color = 0x514d3e,
    }):align(display.CENTER, 304, 225):addTo(body)



    local bg1 = WidgetUIBackGround.new({width = 558,height=118},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :align(display.CENTER,304, 140):addTo(body)

    -- 最大坐标
    local max = GameDatas.AllianceInitData.intInit.bigMapLength.value * GameDatas.AllianceInitData.intInit.allianceRegionMapWidth.value
              
    local min = 1
    local function edit(event, editbox)
        local text = tonumber(editbox:getText()) or min
        if event == "began" then
        -- if min==text then
        --     editbox:setText("1")
        -- end
        elseif event == "changed" then
            if text then
                if text > max then
                    editbox:setText(max)
                end
            end
        elseif event == "ended" then
            if text=="" or min>text then
                editbox:setText(min)
            end
        end
    end
    -- x 坐标
    UIKit:ttfLabel({
        text = "X:",
        size = 26,
        color = 0x514d3e,
    }):align(display.CENTER, 100, 140):addTo(body)
    local editbox_x = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(174,40),
        font = UIKit:getFontFilePath(),
        listener = edit
    })
    editbox_x:setMaxLength(4)
    editbox_x:setFont(UIKit:getEditBoxFont(),22)
    editbox_x:setFontColor(cc.c3b(0,0,0))
    editbox_x:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
    editbox_x:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox_x:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox_x:align(display.LEFT_CENTER,110, 140)
    editbox_x:addTo(body)
    -- y 坐标
    UIKit:ttfLabel({
        text = "Y:",
        size = 26,
        color = 0x514d3e,
    }):align(display.CENTER, 320, 140):addTo(body)
    local editbox_y = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(174,40),
        font = UIKit:getEditBoxFont(),
        listener = edit
    })
    editbox_y:setMaxLength(4)
    editbox_y:setFont(UIKit:getFontFilePath(),22)
    editbox_y:setFontColor(cc.c3b(0,0,0))
    editbox_y:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
    editbox_y:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox_y:align(display.LEFT_CENTER,330, 140)
    editbox_y:addTo(body)

    WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :align(display.CENTER,body:getContentSize().width/2,46)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local x = string.trim(editbox_x:getText())
                local y = string.trim(editbox_y:getText())
                if string.len(x) == 0 or string.len(y) == 0 then
                    UIKit:showMessageDialog(_("提示"),_("请输入坐标"))
                    return
                end
                local map_layer = display.getRunningScene():GetSceneLayer()
                local alliance_id
                local mapIndex , rx , ry = DataUtils:GetAlliancePosition(x, y)
                local point = map_layer:RealPosition(mapIndex,rx,ry)
                map_layer:GotoMapPositionInMiddle(point.x,point.y)

                self:removeFromParent(true)
            end
        end)
        :setButtonLabel("normal", UIKit:ttfLabel({
            text = _("定位"),
            size = 20,
            color = 0xfff3c7,
            shadow = true
        }))
        :addTo(body)
end


function GameUIAlliancePosition:onEnter()
end

function GameUIAlliancePosition:onExit()
    UIKit:getRegistry().removeObject(self.__cname)
end

return GameUIAlliancePosition









