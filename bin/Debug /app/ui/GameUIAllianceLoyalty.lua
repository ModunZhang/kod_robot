
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")

local GameUIAllianceLoyalty = class("GameUIAllianceLoyalty", WidgetPopDialog)

function GameUIAllianceLoyalty:ctor()
    GameUIAllianceLoyalty.super.ctor(self,340,_("忠诚值"),window.top-200)

    local go_shop_btn = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
        :align(display.CENTER,self.body:getContentSize().width/2,60)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local building = Alliance_Manager:GetMyAlliance():GetAllianceMap():FindAllianceBuildingInfoByName("shop")
                UIKit:newGameUI('GameUIAllianceShop',City,"goods",building):AddToCurrentScene(true)
                self:removeFromParent(true)
            end
        end)
        :setButtonLabel("normal", UIKit:ttfLabel({
            text = "    ".._("前往").."\n".._("联盟商店"),
            size = 20,
            color = 0xfff3c7,
            shadow = true
        }))
        :addTo(self.body)
    -- 背景框
    local bg = WidgetUIBackGround.new({
        width = 572,
        height = 178,
    },WidgetUIBackGround.STYLE_TYPE.STYLE_5):align(display.TOP_CENTER, self.body:getContentSize().width/2, self.body:getContentSize().height-30)
        :addTo(self.body)
    local tips = {
        _("忠诚值是玩家自己的属性，退出联盟后依然保留"),
        _("忠诚值可以在联盟商店中购买道具"),
        _("向联盟捐赠资源可以增加忠诚值"),
        _("帮助盟友加速科技研发和建筑升级的时间"),
    }
    local  origin_y = 150
    local count = 0
    for _,v in pairs(tips) do
        self:CreateTipItem(v):align(display.CENTER, 20, origin_y - count* 40)
            :addTo(bg)
        count = count + 1
    end
end

function GameUIAllianceLoyalty:CreateTipItem(tip)
    local star = display.newSprite("star_23X23.png")
    UIKit:ttfLabel({
        text = tip,
        size = 18,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 30, star:getContentSize().height/2)
        :addTo(star)
    return star
end
function GameUIAllianceLoyalty:onEnter()
end

function GameUIAllianceLoyalty:onExit()
    UIKit:getRegistry().removeObject(self.__cname)
end

return GameUIAllianceLoyalty
















