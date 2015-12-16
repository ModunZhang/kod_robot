--
-- Author: Kenny Dai
-- Date: 2015-01-31 10:08:11
--

local WidgetPushButton = import(".WidgetPushButton")
local Enum = import("..utils.Enum")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local Alliance = import("..entity.Alliance")
local WidgetUseItems = class("WidgetUseItems")

function WidgetUseItems:Create(params)
    local item_name = params.item_name
    local dialog
    if item_name == "changePlayerName" then
        dialog = self:OpenChangePlayerOrCityName(item_name)
    elseif item_name == "heroBlood_1" then
        dialog = self:OpenHeroBloodDialog(item_name)
    elseif item_name == "stamina_1" then
        dialog = self:OpenStrengthDialog(item_name)
    elseif item_name == "dragonHp_1" then
        if params.dragon then
            dialog = self:OpenOneDragonHPItemDialog(item_name, params.dragon)
        else
            dialog = self:OpenIncreaseDragonExpOrHp(item_name)
        end
    elseif item_name == "dragonExp_1" then
        if params.dragon then
            dialog = self:OpenOneDragonItemExpDialog(item_name, params.dragon)
        else
            dialog = self:OpenIncreaseDragonExpOrHp(item_name)
        end
    elseif item_name == "chest_1" then
        dialog = self:OpenChestDialog(item_name)
    elseif item_name == "vipPoint_1" then
        dialog = self:OpenVipPointDialog(item_name)
    elseif item_name == "vipActive_1" then
        dialog = self:OpenVipActive(item_name)
    elseif UtilsForItem:IsBuffItem(item_name) then
        dialog = self:OpenBuffDialog(item_name)
    elseif UtilsForItem:IsResourceItem(item_name) then
        dialog = self:OpenResourceDialog(item_name)
    elseif item_name == "retreatTroop" then
        dialog = self:OpenRetreatTroopDialog(item_name, params.event, params.eventType)
    elseif item_name == "warSpeedupClass_1" then
        dialog = self:OpenWarSpeedupDialog(item_name, params.event, params.eventType)
    elseif item_name == "moveTheCity" then
        dialog = self:OpenMoveTheCityDialog(item_name,params)
    else
        dialog = self:OpenNormalDialog(item_name)
    end
    return dialog
end
function WidgetUseItems:OpenChangePlayerOrCityName(item_name)
    local title , eidtbox_holder, request_key
    if item_name == "changePlayerName" then
        title=_("更改玩家名称")
        eidtbox_holder=_("输入新的玩家名称")
        request_key= "playerName"
    else
        title=_("更改城市名称")
        eidtbox_holder=_("输入新的城市名称")
        request_key= "cityName"
    end
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",264,title,window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(576,48),
        font = UIKit:getFontFilePath(),
    })
    editbox:setPlaceHolder(eidtbox_holder)
    editbox:setMaxLength(12)
    editbox:setFont(UIKit:getEditBoxFont(),22)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox:align(display.LEFT_TOP,16, size.height-30)
    editbox:addTo(body)

    local item_box_bg = self:GetListBg(size.width/2,90,568,154):addTo(body)

    self:CreateItemBox(item_name,function ()
        local newName = string.trim(editbox:getText())
        if string.len(newName) == 0 then
            UIKit:showMessageDialog(_("主人"),_("请输入新的名称"))
        else
            return true
        end
    end,
    function ()
        NetManager:getUseItemPromise(item_name,{[item_name] = {
            [request_key] = string.trim(editbox:getText())
        }}):done(function ()
            dialog:LeftButtonClicked()
        end)
    end,
    function ()
        NetManager:getBuyAndUseItemPromise(item_name,{[item_name] = {
            [request_key] = string.trim(editbox:getText())
        }}):done(function ()
            dialog:LeftButtonClicked()
        end)
    end
    ):addTo(item_box_bg):align(display.CENTER,item_box_bg:getContentSize().width/2,item_box_bg:getContentSize().height/2)
    return dialog
end
function WidgetUseItems:OpenBuffDialog( item_name )
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog", #same_items_info * 130 + 140,_("激活增益道具"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()

    -- 是否激活buff
    local event_type = string.split(item_name,"_")[1]
    local isactive, time = User:IsItemEventActive(event_type)
    local buff_status_label = UIKit:ttfLabel({
        size = 22,
        color = isactive and 0x007c23 or 0x403c2f,
    }):addTo(body):align(display.CENTER,size.width/2, size.height-50)
    if isactive then
        buff_status_label:setString(string.format( _("已激活,剩余时间:%s"), GameUtils:formatTimeStyle1(time) ))
    else
        buff_status_label:setString(_("未激活"))
    end


    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{})
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    dialog:scheduleAt(function()
        local isactive, time = User:IsItemEventActive(event_type)
        if isactive then
            buff_status_label:setString(string.format( _("已激活,剩余时间:%s"), GameUtils:formatTimeStyle1(time) ))
            buff_status_label:setColor(UIKit:hex2c4b(0x007c23))
        else
            buff_status_label:setString(_("未激活"))
            buff_status_label:setColor(UIKit:hex2c4b(0x403c2f))
        end
    end)
    return dialog
end
function WidgetUseItems:OpenResourceDialog( item_name )
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",(#same_items_info >4 and 4 or #same_items_info) * 130 +24 + 70,_("增益道具"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()

    local list,list_node = UIKit:commonListView_1({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,546,(#same_items_info >4 and 4 or #same_items_info) * 130),
    })
    list_node:addTo(body):align(display.BOTTOM_CENTER, size.width/2,20)
    local which_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            local list_item = list:newItem()
            list_item:setItemSize(546,130)
            list_item:addContent(self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    if User:GetItemCount(item_name) > 1 then
                        UIKit:newWidgetUI("WidgetUseMutiItems", item_name):AddToCurrentScene()
                    else
                        NetManager:getUseItemPromise(item_name,{
                            [item_name] = {count = User:GetItemCount(item_name)}
                        })
                    end
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{
                        [item_name] = {count = 1}
                    })
                end,
                which_bg
            )
            )
            list:addItem(list_item)
            which_bg = not which_bg
        end
    end
    list:reload()
    return dialog
end
function WidgetUseItems:OpenHeroBloodDialog( item_name )
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info * 130 +150,_("英雄之血"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local blood_bg = display.newScale9Sprite("back_ground_398x97.png",size.width/2,size.height-50,cc.size(556,58),cc.rect(10,10,378,77))
        :addTo(body)
    UIKit:ttfLabel({
        text = _("英雄之血"),
        size = 22,
        color = 0x615b44,
    }):align(display.LEFT_CENTER,40,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)
    local blood_value = UIKit:ttfLabel({
        text = User:GetResValueByType("blood"),
        size = 22,
        color = 0x28251d,
    }):align(display.RIGHT_CENTER,blood_bg:getContentSize().width-40,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)
    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{})
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    dialog:scheduleAt(function()
        blood_value:setString(User:GetResValueByType("blood"))
    end)
    return dialog
end

function WidgetUseItems:OpenOneDragonItemExpDialog( item_name ,dragon)
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info*130+200, _("增加龙的经验"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    UIKit:ttfLabel({
        text = Localize.dragon[dragon:Type()],
        size = 28,
        color = 0x403c2f,
    }):align(display.CENTER,size.width/2,size.height-45)
        :addTo(body)
    local blood_bg = display.newScale9Sprite("back_ground_398x97.png",size.width/2,size.height-100,cc.size(556,58),cc.rect(10,10,378,77))
        :addTo(body)
    local dragon_level = UIKit:ttfLabel({
        text = "LV"..dragon:Level().."/"..dragon:GetMaxLevel(),
        size = 22,
        color = 0x28251d,
    }):align(display.LEFT_CENTER,20,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)
    local dragon_value = UIKit:ttfLabel({
        text = dragon:Exp().."/"..dragon:GetMaxExp(),
        size = 22,
        color = 0x28251d,
    }):align(display.RIGHT_CENTER,blood_bg:getContentSize().width-20,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)

    local exp_icon = display.newSprite("upgrade_experience_icon.png")
        :align(display.CENTER,dragon_value:getPositionX() - dragon_value:getContentSize().width - 20,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)
        :scale(0.6)

    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true

    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{[item_name] = {
                        dragonType = dragon:Type()
                    }})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{[item_name] = {
                        dragonType = dragon:Type()
                    }})
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    -- 添加龙的信息监听
    local dragon_manager = City:GetDragonEyrie():GetDragonManager()
    dragon_manager:AddListenOnType(dialog,dragon_manager.LISTEN_TYPE.OnBasicChanged)
    dialog:addCloseCleanFunc(function ()
        dragon_manager:RemoveListenerOnType(dialog,dragon_manager.LISTEN_TYPE.OnBasicChanged)
    end)

    function dialog:OnBasicChanged()
        dragon_value:setString(dragon:Exp().."/"..dragon:GetMaxExp())
        exp_icon:setPositionX(dragon_value:getPositionX() - dragon_value:getContentSize().width - 20)
        dragon_level:setString("LV"..dragon:Level().."/"..dragon:GetMaxLevel())
    end
    return dialog
end

function WidgetUseItems:OpenOneDragonHPItemDialog( item_name ,dragon)
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info*130+200, _("增加龙的生命值"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    UIKit:ttfLabel({
        text = Localize.dragon[dragon:Type()],
        size = 28,
        color = 0x403c2f,
    }):align(display.CENTER,size.width/2,size.height-45)
        :addTo(body)


    local bg,progressTimer = nil,nil
    bg = display.newSprite("process_bar_540x40.png")
        :addTo(body)
        :align(display.CENTER, size.width/2,size.height-100)
    progressTimer = UIKit:commonProgressTimer("progress_bar_540x40_2.png"):addTo(bg):align(display.LEFT_CENTER,0,20)
    progressTimer:setPercentage(math.floor(dragon:Hp()/dragon:GetMaxHP()*100))
    local iconbg = display.newSprite("drgon_process_icon_bg.png")
        :addTo(bg)
        :align(display.LEFT_BOTTOM, -13,-2)
    display.newSprite("dragon_lv_icon.png")
        :addTo(iconbg)
        :pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
    local dragon_hp_label = UIKit:ttfLabel({
        text = dragon:Hp().."/"..dragon:GetMaxHP(),
        color = 0xfff3c7,
        shadow = true,
        size = 20
    }):addTo(bg):align(display.LEFT_CENTER, 40, 20)


    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true

    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{[item_name] = {
                        dragonType = dragon:Type()
                    }})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{[item_name] = {
                        dragonType = dragon:Type()
                    }})
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    -- 添加龙的信息监听
    local dragon_manager = City:GetDragonEyrie():GetDragonManager()
    dragon_manager:AddListenOnType(dialog,dragon_manager.LISTEN_TYPE.OnHPChanged)
    dialog:addCloseCleanFunc(function ()
        dragon_manager:RemoveListenerOnType(dialog,dragon_manager.LISTEN_TYPE.OnHPChanged)
    end)
    function dialog:OnHPChanged()
        dragon_hp_label:setString(dragon:Hp().."/"..dragon:GetMaxHP())
        progressTimer:setPercentage(math.floor(dragon:Hp()/dragon:GetMaxHP()*100))
    end
    return dialog
end
function WidgetUseItems:OpenStrengthDialog( item_name )
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info * 138 +110,_("探索体力值"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local blood_bg = display.newScale9Sprite("back_ground_398x97.png",size.width/2,size.height-50,cc.size(556,58),cc.rect(10,10,378,77))
        :addTo(body)
    local blood_icon = display.newSprite("stamina_3_128x128.png"):addTo(blood_bg):align(display.CENTER, 40, blood_bg:getContentSize().height/2):scale(0.4)
    UIKit:ttfLabel({
        text = _("探索体力值"),
        size = 22,
        color = 0x615b44,
    }):align(display.LEFT_CENTER,80,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)

    local value = User:GetResValueByType("stamina")
    local res = User:GetResProduction("stamina")
    local strength_label = UIKit:ttfLabel({
        text = string.format(_("%s(+%d/每小时)"), string.formatnumberthousands(value), res.output),
        size = 22,
        color = 0x28251d,
    }):align(display.RIGHT_CENTER,blood_bg:getContentSize().width-40,blood_bg:getContentSize().height/2)
        :addTo(blood_bg)
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{})
                end
            ):addTo(body):align(display.CENTER,size.width/2,size.height - 160 - (i-1)*138)
        end
    end
    dialog:scheduleAt(function()
        local value = User:GetResValueByType("stamina")
        local res = User:GetResProduction("stamina")
        strength_label:setString(string.format(_("%s(+%d/每小时)"), string.formatnumberthousands(value), res.output))
    end)
    return dialog
end
function WidgetUseItems:OpenIncreaseDragonExpOrHp( item_name )
    local increase_type = string.split(item_name,"_")[1]
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local dragons = dragon_manager:GetDragonsSortWithPowerful()
    local dragon_num = LuaUtils:table_size(dragons)
    if dragon_num==0 then
        UIKit:showMessageDialog(_("提示"),_("您还没孵化巨龙,快去龙巢孵化一只吧!"))
        return
    end
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",

    }
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
            text = Localize.dragon[dragon:Type()] .."(LV "..dragon:Level()..")",
            size = 22,
            color = 0x514d3e,
        }):align(display.LEFT_CENTER,20,100)
            :addTo(box_bg,2)

        -- 经验 or hp
        local text_1 = increase_type == "dragonHp" and string.format( _("生命值 %d/%d"), dragon:Hp(), dragon:GetMaxHP() ) or string.format( _("经验值 %d/%d"), dragon:Exp(), dragon:GetMaxExp() )
        local dragon_vitality = UIKit:ttfLabel({
            text = text_1,
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER,20,60)
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
        }):align(display.LEFT_CENTER,20,30)
            :addTo(box_bg)

        -- check_box
        local check_box = cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.CENTER,380,63)
            :addTo(box_bg)

        function dragon_frame:GetDragonType()
            return dragon:Type()
        end
        function dragon_frame:setCheckBoxButtonSelected( isSelected )
            check_box:setButtonSelected(isSelected)
        end
        function dragon_frame:setDragonVitality( string )
            dragon_vitality:setString(string)
        end
        function dragon_frame:setDragonName( string )
            dragon_name:setString(string)
        end
        function dragon_frame:IsSelected()
            return check_box:isButtonSelected()
        end
        function dragon_frame:GetCheckBox()
            return check_box
        end

        function dragon_frame:OnStateChanged(listener)
            check_box:onButtonStateChanged(function(event)
                listener(event)
            end)
            return self
        end
        return dragon_frame
    end

    local dialog = UIKit:newWidgetUI("WidgetPopDialog",220 + dragon_num*136,increase_type == "dragonHp" and _("增加龙的生命值") or _("增加龙的经验"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()

    local origin_y = size.height-260
    local gap_y = 130
    local add_count = 0
    local optional_dragon = {}
    function optional_dragon:OnStateChanged( event )
        if event.target:isButtonSelected() == false then
            return
        end
        for i,v in ipairs(self) do
            if v:GetCheckBox() == event.target then
                if not v:IsSelected() then
                    v:setCheckBoxButtonSelected(true)
                end
            else
                if v:IsSelected() then
                    v:setCheckBoxButtonSelected(false)
                end
            end
        end
    end
    -- 默认选中最强的并且可以出战的龙,如果都不能出战,则默认最强龙
    local default_dragon_type = dragon_manager:GetCanFightPowerfulDragonType() ~= "" and dragon_manager:GetCanFightPowerfulDragonType() or dragon_manager:GetPowerfulDragonType()
    local default_select_dragon_index
    local dragon_boxes = {}
    for k,dragon in ipairs(dragons) do
        if dragon:Level()>0 then
            local dragon_box = createDragonFrame(dragon):align(display.LEFT_CENTER, 30,origin_y-add_count*gap_y)
                :addTo(body)
                :OnStateChanged(function (event)
                    optional_dragon:OnStateChanged(event)
                end)

            add_count = add_count + 1
            table.insert(optional_dragon, dragon_box)
            if dragon:Type() == default_dragon_type then
                dragon_box:setCheckBoxButtonSelected(true)
            end
            table.insert(dragon_boxes, dragon_box)
        end
    end

    local item_box_bg = self:GetListBg(size.width/2,size.height - 100,568,154):addTo(body)

    self:CreateItemBox(
        item_name,
        function ()
            local select_dragonType = ""
            for i,v in ipairs(optional_dragon) do
                if v:IsSelected() then
                    select_dragonType = v:GetDragonType()
                    break
                end
            end
            if select_dragonType == "" then
                UIKit:showMessageDialog(_("提示"), _("请选择巨龙"))
            end
            return select_dragonType ~= ""
        end,
        function ()
            local select_dragonType = ""
            for i,v in ipairs(optional_dragon) do
                if v:IsSelected() then
                    select_dragonType = v:GetDragonType()
                    break
                end
            end
            NetManager:getUseItemPromise(item_name,{[item_name] = {
                dragonType = select_dragonType
            }})
        end,
        function ()
            local select_dragonType = ""
            for i,v in ipairs(optional_dragon) do
                if v:IsSelected() then
                    select_dragonType = v:GetDragonType()
                    break
                end
            end
            NetManager:getBuyAndUseItemPromise(item_name,{[item_name] = {
                dragonType = select_dragonType
            }})
        end
    ):addTo(item_box_bg):align(display.CENTER,item_box_bg:getContentSize().width/2,item_box_bg:getContentSize().height/2)

    -- 添加龙的信息监听
    local dragon_manager = City:GetDragonEyrie():GetDragonManager()
    dragon_manager:AddListenOnType(dialog,dragon_manager.LISTEN_TYPE.OnBasicChanged)
    dragon_manager:AddListenOnType(dialog,dragon_manager.LISTEN_TYPE.OnHPChanged)
    dialog:addCloseCleanFunc(function ()
        dragon_manager:RemoveListenerOnType(dialog,dragon_manager.LISTEN_TYPE.OnBasicChanged)
        dragon_manager:RemoveListenerOnType(dialog,dragon_manager.LISTEN_TYPE.OnHPChanged)
    end)
    function dialog:OnHPChanged()
        if increase_type == "dragonHp" then
            for i,v in ipairs(dragon_boxes) do
                local dragon = dragon_manager:GetDragon(v:GetDragonType())
                v:setDragonVitality( string.format( _("生命值 %d/%d"), dragon:Hp(), dragon:GetMaxHP() ) )
            end
        end
    end
    function dialog:OnBasicChanged()
        if increase_type == "dragonExp" then
            for i,v in ipairs(dragon_boxes) do
                local dragon = dragon_manager:GetDragon(v:GetDragonType())
                v:setDragonVitality( string.format( _("经验值 %d/%d"), dragon:Exp(), dragon:GetMaxExp() ) )
                v:setDragonName( Localize.dragon[dragon:Type()] .."(LV "..dragon:Level()..")")
            end
        end
    end
    return dialog
end
function WidgetUseItems:OpenChestDialog( item_name )
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info * 130 +140, UtilsForItem:GetItemLocalize(item_name), window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function (item_name)
                    if User:CanOpenChest(item_name) then
                        return true
                    else
                        UIKit:showMessageDialog(_("主人"),_("没有钥匙"))
                    end
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{})
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    return dialog
end
function WidgetUseItems:OpenMoveTheCityDialog( item_name ,params)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",200, UtilsForItem:GetItemLocalize(item_name),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local item_box_bg = self:GetListBg(size.width/2,90,568,154):addTo(body)

    self:CreateItemBox(
        item_name,
        function ()
            return true
        end,
        function ()
            if #UtilsForEvent:GetAllMyMarchEvents() > 0 then
                UIKit:showMessageDialog(_("提示"),_("部队在外时不能移城"))
            elseif Alliance_Manager:GetMyAlliance().basicInfo.status == "fight" then
                UIKit:showMessageDialog(_("提示"),_("战争期不能移城"))
            else
                NetManager:getUseItemPromise(item_name,{
                    [item_name]={
                        locationX = params.locationX,
                        locationY = params.locationY
                    }

                }):done(function ()
                    dialog:LeftButtonClicked()
                end)
            end
        end,
        function ()
            if #UtilsForEvent:GetAllMyMarchEvents() > 0  then
                UIKit:showMessageDialog(_("提示"),_("部队在外时不能移城"))
            elseif Alliance_Manager:GetMyAlliance().basicInfo.status == "fight" then
                UIKit:showMessageDialog(_("提示"),_("战争期不能移城"))
            else
                NetManager:getBuyAndUseItemPromise(item_name,{
                    [item_name]={
                        locationX = params.locationX,
                        locationY = params.locationY
                    }
                }):done(function ()
                    dialog:LeftButtonClicked()
                end)
            end
        end
    ):addTo(item_box_bg):align(display.CENTER,item_box_bg:getContentSize().width/2,item_box_bg:getContentSize().height/2)
    return dialog
end
function WidgetUseItems:OpenVipPointDialog(item_name)
    local dialog = self:OpenNormalDialog(item_name,_("增加VIP点数"),window.top-180 , 150)
    local exp_bar = UIKit:CreateVipExpBar():addTo(dialog,1,999):pos(dialog:getContentSize().width/2-287, dialog:getContentSize().height-230)
    local vip_level,percent,exp = User:GetVipLevel()
    exp_bar:LightLevelBar(vip_level,percent,exp, true)
    function dialog:OnUserDataChanged_basicInfo(userData, deltaData)
        if deltaData("basicInfo.vipExp") then
            local vip_level,percent,exp = userData:GetVipLevel()
            self:removeChildByTag(999, true)
            local exp_bar = UIKit:CreateVipExpBar():addTo(self,1,999):pos(self:getContentSize().width/2-287, self:getContentSize().height-230)
            exp_bar:LightLevelBar(vip_level,percent,exp, true)
        end
    end
    User:AddListenOnType(dialog, "basicInfo")
    dialog:addCloseCleanFunc(function ()
        User:RemoveListenerOnType(dialog, "basicInfo")
    end)
    return dialog
end

function WidgetUseItems:OpenNormalDialog( item_name ,title ,y , offset_hight)
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info * 130 + (offset_hight or 100),title or UtilsForItem:GetItemLocalize(item_name), y and y or window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()

    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{}):done(function ()
                        UIKit:PlayUseItemAni(item_name)
                    end)
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{}):done(function ()
                        UIKit:PlayUseItemAni(item_name)
                    end)
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    return dialog
end
function WidgetUseItems:OpenVipActive( item_name )
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",3 * 130+24 +80,_("激活VIP"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    -- 是否激活 vip
    local vip_status_label = UIKit:ttfLabel({
        size = 22,
        color = User:IsVIPActived() and 0x007c23 or 0x403c2f,
    }):addTo(body):align(display.CENTER,size.width/2, size.height-35)
    local isactive,leftTime = User:IsVIPActived()
    if isactive then
        local left_time_str = GameUtils:formatTimeStyle1(leftTime)
        vip_status_label:setString( string.format( _("已激活,剩余时间:%s"), left_time_str ) )
    else
        vip_status_label:setString(_("未激活"))
    end
    dialog.vip_status_label = vip_status_label



    function dialog:OnVipEventTimer()
        local isactive, time = User:IsVIPActived()
        if time > 0 then
            local left_time_str = GameUtils:formatTimeStyle1(time)
            vip_status_label:setString( string.format( _("已激活,剩余时间:%s"), left_time_str ) )
            vip_status_label:setColor(UIKit:hex2c4b(0x007c23))
        else
            vip_status_label:setString(_("未激活"))
            vip_status_label:setColor(UIKit:hex2c4b(0x403c2f))
        end
    end
    dialog:scheduleAt(function()
        dialog:OnVipEventTimer()
    end)

    local list,list_node = UIKit:commonListView_1({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,546,3 * 130),
    })
    list_node:addTo(body):align(display.BOTTOM_CENTER, size.width/2,20)

    local list_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            local list_item = list:newItem()
            list_item:setItemSize(546,130)
            list_item:addContent(self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{})
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{})
                end,
                list_bg
            )
            )
            list:addItem(list_item)
            list_bg = not list_bg
        end
    end
    list:reload()
    dialog.list = list
    return dialog
end
function WidgetUseItems:OpenWarSpeedupDialog( item_name ,march_event, eventType)
    local same_items_info = User:GetRelationItemInfos(item_name)
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",#same_items_info * 130 + 140,_("战争沙漏"),window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()

    -- 金龙币数量
    local gem_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(User:GetGemValue()),
        size = 20,
        color = 0x403c2f,
    }):addTo(body):align(display.RIGHT_CENTER,size.width - 30 ,size.height-50)
    -- gem icon
    local gem_icon = display.newSprite("gem_icon_62x61.png")
        :align(display.RIGHT_CENTER,gem_label:getPositionX() - gem_label:getContentSize().width - 10,size.height-50)
        :addTo(body)
        :scale(0.6)
    UIKit:ttfLabel({
        text = _("拥有:"),
        size = 20,
        color = 0x403c2f,
    }):addTo(body):align(display.RIGHT_CENTER,gem_icon:getPositionX() - gem_icon:getContentSize().width * 0.6 - 10,size.height-50)

    local time, percent = UtilsForEvent:GetEventInfo(march_event)
    local buff_status_label = UIKit:ttfLabel({
        text = string.format( _("剩余时间: %s"), GameUtils:formatTimeStyle1(time) ),
        size = 22,
        color = 0x007c23,
    }):addTo(body):align(display.LEFT_CENTER,30, size.height-50)

    local list_bg = self:GetListBg(size.width/2,(#same_items_info * 130+24)/2+30, 568, #same_items_info * 130+24)
        :addTo(body)

    local which_bg = true
    for i,v in ipairs(same_items_info) do
        local item_name = v.name
        if User:IsItemVisible(item_name) then
            self:CreateItemBox(
                item_name,
                function ()
                    return true
                end,
                function ()
                    NetManager:getUseItemPromise(item_name,{
                        [item_name]={
                            eventType = eventType,
                            eventId = march_event.id
                        }

                    })
                end,
                function ()
                    NetManager:getBuyAndUseItemPromise(item_name,{
                        [item_name]={
                            eventType = eventType,
                            eventId= march_event.id
                        }
                    })
                end,
                which_bg
            ):addTo(list_bg):align(display.CENTER,568/2,#same_items_info * 130+12 - 130/2 - (i-1)*130)
            which_bg = not which_bg
        end
    end
    function dialog:OnAllianceDataChanged_marchEvents(alliance, deltaData)
        return self:HandleEvents("remove", deltaData("marchEvents.attackMarchEvents.remove"))
            or self:HandleEvents("edit", deltaData("marchEvents.attackMarchEvents.edit"))
            or self:HandleEvents("remove", deltaData("marchEvents.attackMarchReturnEvents.remove"))
            or self:HandleEvents("edit", deltaData("marchEvents.attackMarchReturnEvents.edit"))
            or self:HandleEvents("remove", deltaData("marchEvents.strikeMarchEvents.remove"))
            or self:HandleEvents("edit", deltaData("marchEvents.strikeMarchEvents.edit"))
            or self:HandleEvents("remove", deltaData("marchEvents.strikeMarchReturnEvents.remove"))
            or self:HandleEvents("edit", deltaData("marchEvents.strikeMarchReturnEvents.edit"))
    end
    function dialog:HandleEvents(op, ok, value)
        if not ok then return end
        if op == "remove" then
            for i,v in ipairs(value) do
                if v.id == march_event.id then
                    self:LeftButtonClicked()
                    return true
                end
            end
        elseif op == "edit" then
            for i,v in ipairs(value) do
                if v.id == march_event.id then
                    march_event.arriveTime = v.arriveTime
                    return true
                end
            end
        end
        
    end
    local alliance = Alliance_Manager:GetMyAlliance()
    alliance:AddListenOnType(dialog, "marchEvents")
    dialog:addCloseCleanFunc(function()
        alliance:RemoveListenerOnType(dialog, "marchEvents")
    end)
    dialog:scheduleAt(function()
        gem_label:setString(string.formatnumberthousands(User:GetGemValue()))
        local time, percent = UtilsForEvent:GetEventInfo(march_event)
        buff_status_label:setString(string.format(_("剩余时间:%s"), GameUtils:formatTimeStyle1(time)))
    end)
    return dialog
end
function WidgetUseItems:OpenRetreatTroopDialog( item_name,event,eventType )
    local dialog = UIKit:newWidgetUI("WidgetPopDialog", 130 + 80 + 40, UtilsForItem:GetItemLocalize(item_name), window.top-230)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    -- 金龙币数量
    local gem_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(User:GetGemValue()),
        size = 20,
        color = 0x403c2f,
    }):addTo(body):align(display.RIGHT_CENTER,size.width - 30 ,size.height-45)
    -- gem icon
    local gem_icon = display.newSprite("gem_icon_62x61.png")
        :align(display.RIGHT_CENTER,gem_label:getPositionX() - gem_label:getContentSize().width - 10,size.height-45)
        :addTo(body)
        :scale(0.6)
    UIKit:ttfLabel({
        text = _("拥有:"),
        size = 20,
        color = 0x403c2f,
    }):addTo(body):align(display.RIGHT_CENTER,gem_icon:getPositionX() - gem_icon:getContentSize().width * 0.6 - 10,size.height-45)


    local item_box_bg = self:GetListBg(size.width/2,100,568,154):addTo(body)

    self:CreateItemBox(
        item_name,
        function ()
            return true
        end,
        function ()
            NetManager:getUseItemPromise(item_name,{
                [item_name]={
                    eventType = eventType,
                    eventId = event.id
                }
            }):done(function ()
                dialog:LeftButtonClicked()
            end)
        end,
        function ()
            NetManager:getBuyAndUseItemPromise(item_name,{
                [item_name]={
                    eventType = eventType,
                    eventId = event.id
                }
            }):done(function ()
                dialog:LeftButtonClicked()
            end)
        end
    ):addTo(item_box_bg):align(display.CENTER,item_box_bg:getContentSize().width/2,item_box_bg:getContentSize().height/2)
    dialog:scheduleAt(function()
        if UtilsForEvent:GetEventInfo(event) <= 0 then
            dialog:LeftButtonClicked()
            return 
        end
        gem_label:setString(string.formatnumberthousands(User:GetGemValue()))
    end)
    return dialog
end

function WidgetUseItems:CreateItemBox(item_name,checkUseFunc,useItemFunc,buyAndUseFunc,which_bg)
    local body_image = which_bg and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
    local body = display.newScale9Sprite(body_image,0,0,cc.size(548,130),cc.rect(10,10,528,20))
    body:setNodeEventEnabled(true)
    function body:Init()
        self:removeAllChildren()
        local item_bg = display.newSprite("box_118x118.png"):addTo(body):pos(65,65)
        local item_icon = display.newSprite(UILib.item[item_name]):addTo(item_bg):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2):scale(0.6)
        item_icon:scale(100/item_icon:getContentSize().width)

        -- 道具名称
        UIKit:ttfLabel({
            text = UtilsForItem:GetItemLocalize(item_name),
            size = 24,
            color = 0x403c2f,
        }):addTo(body):align(display.LEFT_CENTER,130, body:getContentSize().height-22)
        -- 道具介绍
        UIKit:ttfLabel({
            text = UtilsForItem:GetItemDesc(item_name),
            size = 20,
            color = 0x5c553f,
            dimensions = cc.size(260,0)
        }):addTo(body):align(display.LEFT_CENTER,130, body:getContentSize().height/2-10)

        local btn_pics , btn_label, btn_call_back
        if User:GetItemCount(item_name) < 1 then
            local item_info = UtilsForItem:GetItemInfoByName(item_name)
            btn_pics = {normal = "green_btn_up_148x58.png", pressed = "green_btn_down_148x58.png"}
            btn_label = _("购买&使用")
            btn_call_back = function ()
                if item_info.price > User:GetGemValue() then
                    UIKit:showMessageDialog(_("主人"),_("金龙币不足"))
                        :CreateOKButton(
                            {
                                listener = function ()
                                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                end,
                                btn_name= _("前往商店")
                            }
                        )
                else
                    if app:GetGameDefautlt():IsOpenGemRemind() then
                        UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),string.formatnumberthousands(item_info.price)), function()
                            buyAndUseFunc()
                        end,true,true)
                    else
                        buyAndUseFunc()
                    end
                end
            end
            if item_info.isSell then
                local price_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):addTo(body):align(display.CENTER,470,94)
                -- gem icon
                local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(price_bg):align(display.CENTER, 20, price_bg:getContentSize().height/2):scale(0.6)
                UIKit:ttfLabel({
                    text = string.formatnumberthousands(item_info.price),
                    size = 20,
                    color = 0x403c2f,
                }):align(display.LEFT_CENTER, 50 , price_bg:getContentSize().height/2)
                    :addTo(price_bg)
            end
        else
            local num_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):addTo(body):align(display.CENTER,470,94)

            local own_label = UIKit:ttfLabel({
                text = string.format(_("拥有:%d"), User:GetItemCount(item_name)),
                size = 20,
                color = 0x403c2f,
            }):addTo(num_bg):align(display.CENTER,num_bg:getContentSize().width/2, num_bg:getContentSize().height/2)

            btn_pics = {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"}
            btn_label = _("使用")
            btn_call_back = useItemFunc
        end
        -- 使用按钮
        local use_btn = WidgetPushButton.new(
            btn_pics,
            {scale9 = false}
        ):setButtonLabel(UIKit:commonButtonLable({text = btn_label}))
            :addTo(body):align(display.CENTER, 470, 34)
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    if checkUseFunc(item_name) then
                        btn_call_back(item_name)
                    end
                end
            end)
        use_btn:setVisible(User:IsItemVisible(item_name))
        self.use_btn = use_btn
    end
    function body:OnUserDataChanged_items()
        self:Init()
    end
    function body:onExit()
        User:RemoveListenerOnType(body, "items")
    end
    User:AddListenOnType(body, "items")
    body:Init()
    return body
end

function WidgetUseItems:GetListBg(x,y,width,height)
    return display.newScale9Sprite("background_568x120.png",x,y,cc.size(width,height),cc.rect(10,10,548,100))
end









return WidgetUseItems


































