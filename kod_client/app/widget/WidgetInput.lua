--
-- Author: Kenny Dai
-- Date: 2015-01-16 11:14:47
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")

local WidgetInput = class("WidgetInput", WidgetPopDialog)

function WidgetInput:ctor(params)
    WidgetInput.super.ctor(self,210,"调整数量",display.top-400)
    self:DisableCloseBtn()
    local body = self.body
    local max = params.max
    local current = params.current
    local min = params.min or 0
    local unit = params.unit or ""
    local callback = params.callback or NOT_HANDLE
    local exchange = 1
    if unit == "K" then
        exchange = 1000
    end
    self.current_value = min
    -- max 有时会变化
    self.max = max

    local function edit(event, editbox)
        local text = tonumber(editbox:getText()) or min
        if event == "began" then
            if min==text then
                editbox:setText("")
            end
        elseif event == "changed" then
            if text then
                if text > math.floor(self.max/exchange) then
                    editbox:setText(math.floor(self.max/exchange))
                end
            end
        elseif event == "ended" then
            if editbox:getText()=="" or min>text then
                editbox:setText(min)
            else
                local e_value = math.floor(text*exchange)
                local btn_value
                local btn_unit  = ""
                if e_value>=1000 then
                    local f_value = GameUtils:formatNumber(e_value)
                    btn_value = string.sub(f_value,1,-2)
                    btn_unit = string.sub(f_value,-1,-1)
                else
                    btn_value = e_value
                end
                editbox:setText(btn_value)
                self.perfix_lable:setString(string.format(btn_unit.."/ %s", GameUtils:formatNumber(max)))

                self.current_value = text
            end
            callback(self.current_value)
        end
    end

    local bg1 = WidgetUIBackGround.new({width = 558,height=90},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :align(display.CENTER,304, 130):addTo(body)

    -- soldier current
    self.editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "back_ground_83x32.png",
        size = cc.size(100,32),
        font = UIKit:getFontFilePath(),
        listener = edit
    })
    local editbox = self.editbox
    editbox:setMaxLength(10)
    editbox:setText(current)
    editbox:setFont(UIKit:getFontFilePath(),20)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox:align(display.CENTER, body:getContentSize().width/2,body:getContentSize().height/2+20):addTo(body)

    self.perfix_lable = UIKit:ttfLabel({
        text = string.format(unit.."/ %s", GameUtils:formatNumber(max)),
        size = 20,
        color = 0x403c2f
    }):addTo(body)
        :align(display.LEFT_CENTER, editbox:getPositionX()+70,editbox:getPositionY())
    -- 升级按钮
    WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("确定"),
            size = 22,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                callback(self.current_value)
                self:LeftButtonClicked()
            end
        end):align(display.CENTER, editbox:getPositionX(),editbox:getPositionY()-80):addTo(body)
end
function WidgetInput:SetMax( max )
    self.max = max
end
function WidgetInput:onEnter()
    WidgetInput.super.onEnter(self)
    self.editbox:touchDownAction(editbox,2)
end
return WidgetInput



