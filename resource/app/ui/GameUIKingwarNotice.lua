--
-- Author: Kenny Dai
-- Date: 2016-02-23 09:33:42
--
local GameUIKingwarNotice = UIKit:createUIClass("GameUIKingwarNotice","GameUIWithCommonHeader")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")

function GameUIKingwarNotice:ctor(city)
    GameUIKingwarNotice.super.ctor(self,city, _("国王通告"))
end

function GameUIKingwarNotice:onEnter()
    GameUIKingwarNotice.super.onEnter(self)
    local content = WidgetUIBackGround.new({width = 556,height= 164},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER_TOP,window.cx,window.top_bottom - 10):addTo(self:GetView())
    local notic_title_bg = display.newSprite("title_red_564x54.png"):align(display.CENTER_TOP, content:getContentSize().width/2,content:getContentSize().height + 10):addTo(content)
    local translation_sp = WidgetPushButton.new({
        normal = "tmp_brown_btn_up_36x24.png",
        pressed= "tmp_brown_btn_down_36x24.png",
    }):align(display.RIGHT_CENTER, notic_title_bg:getContentSize().width - 12,notic_title_bg:getContentSize().height/2 + 5):addTo(notic_title_bg)
    display.newSprite("tmp_icon_translate_26x20.png"):addTo(translation_sp):pos(-18,2)

    UIKit:ttfLabel({text = _("国王通告"),
        size = 22,
        shadow = true,
        color = 0xffed36c
    }):align(display.CENTER, notic_title_bg:getContentSize().width/2,notic_title_bg:getContentSize().height/2 + 5):addTo(notic_title_bg)

    local  listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(10,10, 536, 118),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(content)
    listview:reload()

    local title_bg = display.newSprite("title_552x16.png"):align(display.TOP_CENTER, window.cx,content:getPositionY() - 190):addTo(self:GetView())
    UIKit:ttfLabel({text = _("修改"),
        size = 22,
        color = 0x403c2f
    }):align(display.CENTER, title_bg:getContentSize().width/2,title_bg:getContentSize().height/2):addTo(title_bg)

    -- local textView = ccui.UITextView:create(cc.size(580,472),display.newScale9Sprite("background_88x42.png"))
    -- textView:addTo(write_mail):align(display.CENTER_BOTTOM,r_size.width/2,76)
    -- textView:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    -- textView:setFont(UIKit:getEditBoxFont(), 24)
    -- textView:setMaxLength(1000)
    -- textView:setFontColor(cc.c3b(0,0,0))

    WidgetPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed= "yellow_btn_down_148x58.png",
    }):setButtonLabel(UIKit:ttfLabel({text = _("修改"),
        size = 20,
        shadow = true,
        color = 0xfff3c7
    })):align(display.CENTER, window.cx,window.cy):addTo(self:GetView())
        :onButtonClicked(function (event)
            if event.name == "CLICKED_EVENT" then
            end
        end)
end
function GameUIKingwarNotice:onExit()
    GameUIKingwarNotice.super.onExit(self)
end

return GameUIKingwarNotice








