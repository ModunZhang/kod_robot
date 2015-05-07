local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local Localize = import("..utils.Localize")
local UILib = import(".UILib")


local UICheckBoxButton = import(".UICheckBoxButton")


local GameUICollectReport = class("GameUICollectReport",WidgetPopDialog)


function GameUICollectReport:ctor(report)
    GameUICollectReport.super.ctor(self,500,_("采集战报"))
    self.report = report
    -- bg
    local body = self.body
    local r_size = body:getContentSize()

    local strike_result_image = display.newSprite("report_collect_590x137.png")
        :align(display.CENTER_TOP, r_size.width/2, r_size.height-17)
        :addTo(body)

    -- 战斗发生时间
    local war_result_label = UIKit:ttfLabel(
        {
            text = GameUtils:formatTimeStyle2(math.floor(report.createTime/1000)),
            size = 18,
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 40, r_size.height-190)
        :addTo(body)
    local war_result_label = UIKit:ttfLabel(
        {
            text = self:GetFightTarget(),
            size = 18,
            color = 0x615b44
        }):align(display.LEFT_CENTER, 40, r_size.height-220)
        :addTo(body)

    -- 战利品
    self:CreateBootyPart()


    local delete_btn = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("删除"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:showMessageDialog(_("删除战报"),_("您即将删除所选战报,删除后将无法恢复,您确定要这么做吗?"))
                    :CreateOKButton(
                        {
                            listener =function ()
                                NetManager:getDeleteReportsPromise({report.id}):done(function ()
                                    self:removeFromParent()
                                end)
                            end
                        }
                    )
            end
        end):align(display.CENTER,106,50):addTo(body)
    -- 收藏按钮
    local saved_button = UICheckBoxButton.new({
        off = "mail_saved_button_normal.png",
        off_pressed = "mail_saved_button_normal.png",
        off_disabled = "mail_saved_button_normal.png",
        on = "mail_saved_button_pressed.png",
        on_pressed = "mail_saved_button_pressed.png",
        on_disabled = "mail_saved_button_pressed.png",
    }):onButtonStateChanged(function(event)
        local target = event.target
        if target:isButtonSelected() then
            NetManager:getSaveReportPromise(report.id):fail(function()
                target:setButtonSelected(false,true)
            end)
        else
            NetManager:getUnSaveReportPromise(report.id):fail(function()
                target:setButtonSelected(true,true)
            end)
        end
    end):addTo(body):pos(r_size.width-48, 37)
        :setButtonSelected(report:IsSaved(),true)

end

function GameUICollectReport:CreateBootyPart()
    local item_width = 540
    -- 战利品列表部分高度
    local booty_count = #self:GetBooty()
    local booty_group = display.newNode()
    -- cc.ui.UIGroup.new()
    local booty_list_bg
    if booty_count>0 then
        local item_height = 46
        local booty_list_height = booty_count * item_height

        -- 战利品列表
        booty_list_bg = WidgetUIBackGround.new({width = item_width,height = booty_list_height+16},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
            :align(display.CENTER,0,-25)

        local booty_list_bg_size = booty_list_bg:getContentSize()
        booty_group:addChild(booty_list_bg)

        -- 构建所有战利品标签项
        local booty_item_bg_color_flag = true
        local added_booty_item_count = 0
        for k,booty_parms in pairs(self:GetBooty()) do
            local booty_item_bg_image = booty_item_bg_color_flag and "upgrade_resources_background_3.png" or "upgrade_resources_background_2.png"
            local booty_item_bg = display.newSprite(booty_item_bg_image)
                :align(display.TOP_CENTER, booty_list_bg_size.width/2, booty_list_bg_size.height-item_height*added_booty_item_count-6)
                :addTo(booty_list_bg,2)
            local booty_icon = display.newSprite(booty_parms.icon, 30, 23):addTo(booty_item_bg)
            booty_icon:setScale(40/booty_icon:getContentSize().width)
            UIKit:ttfLabel({
                text = booty_parms.resource_type,
                size = 22,
                color = 0x403c2f
            }):align(display.LEFT_CENTER,80,23):addTo(booty_item_bg)
            UIKit:ttfLabel({
                text = booty_parms.value,
                size = 22,
                color = booty_parms.value>0 and 0x288400 or 0x7e0000
            }):align(display.RIGHT_CENTER,booty_list_bg_size.width-30,23):addTo(booty_item_bg)

            added_booty_item_count = added_booty_item_count + 1
            booty_item_bg_color_flag = not booty_item_bg_color_flag
        end
    end
    local booty_title_bg = display.newSprite("alliance_evnets_title_548x50.png")
        :align(display.CENTER_BOTTOM, 0,booty_list_bg and booty_list_bg:getContentSize().height/2-25 or -25)

    booty_group:addChild(booty_title_bg)


    UIKit:ttfLabel({
        text = booty_count > 0 and _("战利品") or _("无战利品") ,
        size = 24,
        color = 0xffedae
    }):align(display.CENTER,booty_title_bg:getContentSize().width/2, 25):addTo(booty_title_bg)

    booty_group:addTo(self.body):align(display.CENTER,304,180)
end


function GameUICollectReport:GetFightTarget()
    local battleAt = self.report:GetBattleAt()
    local location = self.report:GetBattleLocation()
    return string.format(_("Battle at %s (%d,%d)"),battleAt,location.x,location.y)
end
function GameUICollectReport:GetBooty()
    local booty = {}
    LuaUtils:outputTable("self.report:GetMyRewards()", self.report:GetMyRewards())
    for k,v in pairs(self.report:GetMyRewards()) do
        table.insert(booty, {
            resource_type = Localize.fight_reward[v.name],
            icon= UILib.resource[v.name],
            value = v.count
        })
    end
    return booty
end
return GameUICollectReport








   






