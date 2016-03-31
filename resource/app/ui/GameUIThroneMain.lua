--
-- Author: Kenny Dai
-- 水晶王座
-- Date: 2016-01-25 10:17:22
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local fight_period = false
local BODY_HEIGHT = fight_period and 740 or 656
local BODY_WIDTH = 608
local LISTVIEW_WIDTH = 548
local GameUIThroneMain = class("GameUIThroneMain", WidgetPopDialog)

function GameUIThroneMain:ctor()
    GameUIThroneMain.super.ctor(self,BODY_HEIGHT,_("水晶王座"),window.top-120,"title_purple_600x56.png")
end
function GameUIThroneMain:onEnter()
    GameUIThroneMain.super.onEnter(self)
    local title_bg = self.title_sprite
    local title_label = self.title_label
    local icon = display.newSprite("world_icon1.png"):addTo(title_bg):pos(title_label:getPositionX() - title_label:getContentSize().width/2 - 20,title_label:getPositionY())

    local body = self:GetBody()
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(134,134)
        :addTo(body)
        :align(display.LEFT_TOP, 30, BODY_HEIGHT - 30)
    local flag_sprite,terrain_sprite,flag_node = WidgetAllianceHelper.new():CreateFlagWithRhombusTerrain("iceField","1,7,7,16,6")
    flag_sprite:addTo(flag_box)
    flag_sprite:pos(67,46):scale(1.4)
    flag_node:setVisible(false)
    display.newSprite("icon_unknown_72x86.png"):align(display.CENTER, flag_box:getContentSize().width/2-4,flag_box:getContentSize().height/2 + 17):addTo(flag_box):scale(0.9)

    local line_2 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("联盟"),
            text_2 = _("无"),
        }
    ):align(display.LEFT_TOP,flag_box:getPositionX() + flag_box:getContentSize().width + 20 , flag_box:getPositionY() - 30)
        :addTo(body)

    local line_2 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("国王"),
            text_2 = _("无"),
        }
    ):align(display.LEFT_TOP,flag_box:getPositionX() + flag_box:getContentSize().width + 20 , flag_box:getPositionY() - 80 )
        :addTo(body)

    local line_2 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("国家"),
            text_2 = _("无"),
        }
    ):align(display.LEFT_TOP,flag_box:getPositionX() + flag_box:getContentSize().width + 20 , flag_box:getPositionY() - 130 )
        :addTo(body)

    local title_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text = _("头衔"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.LEFT_TOP,flag_box:getPositionX(),flag_box:getPositionY() - flag_box:getContentSize().height - 20):addTo(body)
        :onButtonClicked(function(event)
            UIKit:newGameUI("GameUIMedal",City):AddToCurrentScene(true)
        end)
    local abjection_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text = _("驱逐联盟"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.RIGHT_TOP,BODY_WIDTH - 30,flag_box:getPositionY() - flag_box:getContentSize().height - 20):addTo(body)
        :onButtonClicked(function(event)
            UIKit:newGameUI("GameUIAbjectAlliance",City):AddToCurrentScene(true)
        end)
    local king_notice_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text = _("国王通告"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.LEFT_TOP,flag_box:getPositionX(),flag_box:getPositionY() - flag_box:getContentSize().height - 90):addTo(body)
        :onButtonClicked(function(event)
            UIKit:showMessageDialog(_("提示"), _("权限不足"))
            end)
    local mail_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text = _("全服邮件"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.RIGHT_TOP,BODY_WIDTH - 30,flag_box:getPositionY() - flag_box:getContentSize().height - 90):addTo(body)
        :onButtonClicked(function(event)
            UIKit:showMessageDialog(_("提示"), _("权限不足"))
            end)

    local content = WidgetUIBackGround.new({width = 556,height= 164},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER_TOP,BODY_WIDTH / 2,mail_button:getPositionY() - mail_button:getCascadeBoundingBox().size.height - 25):addTo(body)
    local notic_title_bg = display.newSprite("title_red_564x54.png"):align(display.CENTER_TOP, content:getContentSize().width/2,content:getContentSize().height + 10):addTo(content)
    local translation_sp = WidgetPushButton.new({
        normal = "tmp_brown_btn_up_36x24.png",
        pressed= "tmp_brown_btn_down_36x24.png",
    }):align(display.RIGHT_CENTER, notic_title_bg:getContentSize().width - 12,notic_title_bg:getContentSize().height/2 + 5):addTo(notic_title_bg)
    display.newSprite("tmp_icon_translate_26x20.png"):addTo(translation_sp):pos(-18,2)

    UIKit:ttfLabel({text = _("国王通告"),
        size = 20,
        shadow = true,
        color = 0xfff3c7
    }):align(display.CENTER, notic_title_bg:getContentSize().width/2,notic_title_bg:getContentSize().height/2 + 5):addTo(notic_title_bg)

    local  listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(10,10, 536, 118),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(content)
    listview:reload()

    -- local period_label =  UIKit:ttfLabel({text = _("和平期").." ".."00:00:00",
    --     size = 22,
    --     color = 0x007c23
    -- }):align(display.CENTER,BODY_WIDTH/2,content:getPositionY() - content:getContentSize().height - 25):addTo(body)
    -- display.newSprite("info_26x26.png"):addTo(body):align(display.RIGHT_CENTER, period_label:getPositionX() - period_label:getContentSize().width/2 - 5, period_label:getPositionY())
    -- local button = WidgetPushButton.new()
    --     :addTo(body,2):align(display.CENTER, period_label:getPositionX(),period_label:getPositionY())
    --     :onButtonClicked(function(event)
    --         if event.name == "CLICKED_EVENT" then
    --             UIKit:newWidgetUI("WidgetKingWarRule"):addTo(self)
    --         end
    --     end)
    -- button:setContentSize(period_label:getContentSize())
    if fight_period then
        -- 声望排行榜
        local rank_bg = WidgetUIBackGround.new({width = 568,height= 168},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
            :align(display.CENTER_BOTTOM,BODY_WIDTH/2, 20):addTo(body)
        local rank_title_bg = display.newScale9Sprite("back_ground_blue_254x42.png", 0, 0,cc.size(548,34),cc.rect(10,10,234,22))
            :align(display.CENTER_TOP,568/2, 168 - 10):addTo(rank_bg)
        UIKit:ttfLabel({text = _("当前声望排名"),
            size = 20,
            color = 0xffedae
        }):align(display.CENTER, rank_title_bg:getContentSize().width/2,rank_title_bg:getContentSize().height/2):addTo(rank_title_bg)
        local info_bg = display.newSprite("background1_548x76.png"):addTo(rank_bg)
            :align(display.CENTER_BOTTOM,568/2, 50)
        UIKit:ttfLabel({text = "5",
            size = 22,
            color = 0x403c2f
        }):align(display.CENTER, 40,info_bg:getContentSize().height/2):addTo(info_bg)
        
        display.newSprite("icon_unknown_72x86.png"):align(display.CENTER,  100,info_bg:getContentSize().height/2):addTo(info_bg):scale(0.8)

        UIKit:ttfLabel({text = "联盟名字",
            size = 20,
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 150,info_bg:getContentSize().height/2+14):addTo(info_bg)
        UIKit:ttfLabel({text = "[联盟tag]",
            size = 20,
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 150,info_bg:getContentSize().height/2-14):addTo(info_bg)

        local icon_prestige = display.newSprite("icon_prestige_40x40.png"):align(display.CENTER,  380,info_bg:getContentSize().height/2):addTo(info_bg)
        UIKit:ttfLabel({text = _("即将开放"),
            size = 22,
            color = 0x403c2f
        }):align(display.LEFT_CENTER, icon_prestige:getPositionX()+icon_prestige:getContentSize().width/2 + 10,info_bg:getContentSize().height/2):addTo(info_bg)
        WidgetPushButton.new({normal = "tab_btn_down_140x60.png",pressed = "tab_btn_up_140x60.png"},{scale9 = true})
            :setButtonSize(548,40)
            :setButtonLabel(UIKit:ttfLabel({text = _("更多"),
                size = 20,
                shadow = true,
                color = 0xfff3c7
            })):align(display.CENTER_BOTTOM,568/2,10):addTo(rank_bg)
            :onButtonClicked(function(event)
                end)

    else
        local fight_button = WidgetPushButton.new({normal = "tmp_button_battle_up_234x82.png",pressed = "tmp_button_battle_down_234x82.png",disabled = "grey_btn_233x82.png"})
            :setButtonLabel(UIKit:ttfLabel({text = _("宣战"),
                size = 20,
                shadow = true,
                color = 0xfff3c7
            })):setButtonLabelOffset(0, 16)
            :align(display.CENTER_BOTTOM,BODY_WIDTH/2, 20):addTo(body)
            :onButtonClicked(function(event)
                end):setButtonEnabled(false)
        local icon_bg = display.newSprite("background_172x28.png"):addTo(fight_button):align(display.CENTER,0, fight_button:getCascadeBoundingBox().size.height/2 - 20)
        display.newSprite("honour_128x128.png"):align(display.CENTER, 10, 18):addTo(icon_bg):scale(42/128)

        UIKit:ttfLabel({text = _("即将开放"),
            size = 20,
            shadow = true,
            color = 0xffd200
        }):align(display.CENTER, icon_bg:getContentSize().width/2,icon_bg:getContentSize().height/2 + 2):addTo(icon_bg)
    end

end

function GameUIThroneMain:onExit()
    GameUIThroneMain.super.onExit(self)
end

return GameUIThroneMain








