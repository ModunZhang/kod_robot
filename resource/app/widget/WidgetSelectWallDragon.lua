--
-- Author: Danny He
-- Date: 2015-05-05 09:20:47
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetSelectWallDragon = class("WidgetSelectWallDragon", WidgetPopDialog)
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local WidgetPushButton = import(".WidgetPushButton")

function WidgetSelectWallDragon:ctor(params)
	WidgetSelectWallDragon.super.ctor(self,516,_("选择驻防龙"))
	local body = self.body
    local rb_size = body:getContentSize()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()

       local function createDragonFrame(dragon)
        local dragon_frame = display.newSprite("alliance_item_flag_box_126X126.png")


        local dragon_bg = display.newSprite("dragon_bg_114x114.png")
            :align(display.LEFT_CENTER, 7,dragon_frame:getContentSize().height/2)
            :addTo(dragon_frame)
        local dragon_img = display.newSprite(UILib.dragon_head[dragon:Type()])
            :align(display.CENTER, dragon_bg:getContentSize().width/2, dragon_bg:getContentSize().height/2+5)
            :addTo(dragon_bg)
        local box_bg = display.newSprite("box_426X126.png")
            :align(display.LEFT_CENTER, dragon_frame:getContentSize().width, dragon_frame:getContentSize().height/2)
            :addTo(dragon_frame)
        -- 龙，等级
        local dragon_name = UIKit:ttfLabel({
            text = Localize.dragon[dragon:Type()] .."（LV "..dragon:Level().."）",
            size = 22,
            color = 0x514d3e,
        }):align(display.LEFT_CENTER,20,100)
            :addTo(box_bg,2)
        -- 总力量
        local dragon_vitality = UIKit:ttfLabel({
            text = _("总力量")..dragon:TotalStrength(),
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER,20,60)
            :addTo(box_bg)
        -- 龙活力
        local dragon_vitality = UIKit:ttfLabel({
            text = _("生命值")..dragon:Hp().."/"..dragon:GetMaxHP(),
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER,20,20)
            :addTo(box_bg)
        -- 龙状态
        local d_status = dragon:GetLocalizedStatus()
        local s_color = dragon:IsFree() and 0x007c23 or 0x7e0000
        if dragon:IsDead() then
            s_color = 0x7e0000
        end
        local dragon_status = UIKit:ttfLabel({
            text = d_status,
            size = 20,
            color = s_color,
        }):align(display.RIGHT_CENTER,300,100)
            :addTo(box_bg)
        
        return dragon_frame
    end

    local dragons = dragon_manager:GetDragonsSortWithPowerful()
    if LuaUtils:table_size(dragons)==0 then
        return
    end
    local origin_y = rb_size.height-90
    local gap_y = 130
    local add_count = 0
    local optional_dragon = {}
    -- 默认选中最强的并且可以出战的龙,如果都不能出战,则默认最强龙
    local default_dragon_type = params.default_dragon_type or dragon_manager:GetCanFightPowerfulDragonType() ~= "" and dragon_manager:GetCanFightPowerfulDragonType() or dragon_manager:GetPowerfulDragonType()
    local default_dragon 
    local default_select_dragon_index
    for k,dragon in ipairs(dragons) do
        if dragon:Level()>0 then
            createDragonFrame(dragon):align(display.LEFT_CENTER, 30,origin_y-add_count*gap_y)
                :addTo(body)
            add_count = add_count + 1
            table.insert(optional_dragon, dragon)
            if dragon:Type() == default_dragon_type then
                default_select_dragon_index = k
                default_dragon = dragon
            end
        end
    end

    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",

    }
    local group = cc.ui.UICheckBoxButtonGroup.new(display.TOP_TO_BOTTOM)
        :addTo(body)
    for i=1,add_count do
        group:addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.LEFT_CENTER))
    end
    group:setButtonsLayoutMargin(80, 0, 0, 0)
        :setLayoutSize(100, 500)
        :align(display.TOP_CENTER, 500 , 110)
    group:getButtonAtIndex(default_select_dragon_index):setButtonSelected(true)
    local defence_button =  WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("驻防"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
            	local dragon 
		    	for i=1,group:getButtonsCount() do
		            if group:getButtonAtIndex(i):isButtonSelected() then
		            	dragon = optional_dragon[i]
		                break
		            end
		        end
		        if dragon then
		        	if dragon:IsFree() then
		        		params.callback[1](dragon)
		        		self:removeSelf()
		        	else
		        		UIKit:showMessageDialog(_("错误"),_("没有空闲的龙"), function()end)
		        	end
		        end
            end
        end):align(display.CENTER,rb_size.width/2,50):addTo(body)
    defence_button:setVisible(not default_dragon:IsDefenced())

   local removal_button = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("撤防"),
                size = 24,
                color = 0xffedae,
                shadow= true
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                	params.callback[2]()
                	self:removeSelf()
                end
            end):align(display.CENTER,rb_size.width/2,50):addTo(body)
    removal_button:setVisible(default_dragon:IsDefenced())
    group:onButtonSelectChanged(function()
    	local dragon 
    	for i=1,group:getButtonsCount() do
            if group:getButtonAtIndex(i):isButtonSelected() then
            	dragon = optional_dragon[i]
                break
            end
        end
        if not dragon then return end
        if dragon:IsDefenced() then
        	defence_button:hide()
        	removal_button:show()
        else
        	defence_button:show()
        	removal_button:hide()
        end
    end)
end

return WidgetSelectWallDragon