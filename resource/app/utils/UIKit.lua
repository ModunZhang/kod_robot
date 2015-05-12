--
-- Author: dannyhe
-- Date: 2014-08-01 08:46:35
--
-- 封装常用ui工具
import(".bit")
local cocos_promise = import(".cocos_promise")
local promise = import(".promise")
local Enum = import("..utils.Enum")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UILib = import("..ui.UILib")
local UIListView = import("..ui.UIListView")

local error_code = {}
for k,v in pairs(GameDatas.Errors.errors) do
    error_code[v.code] = v
end

UIKit =
    {
        Registry   = import('framework.cc.Registry'),
        GameUIBase = import('..ui.GameUIBase'),
    }
local CURRENT_MODULE_NAME = ...

UIKit.BTN_COLOR = Enum("YELLOW","BLUE","GREEN","RED","PURPLE")
UIKit.UITYPE = Enum("BACKGROUND","WIDGET","MESSAGEDIALOG")
UIKit.open_ui_callbacks = {}
UIKit.close_ui_callbacks = {}

function UIKit:CheckOpenUI(ui)
    local callbacks = self.open_ui_callbacks
    if #callbacks > 0 and callbacks[1](ui) then
        table.remove(callbacks, 1)
    end
end
function UIKit:PromiseOfOpen(ui_name)
    if UIKit:GetUIInstance(ui_name) then
        return cocos_promise.defer(function() return UIKit:GetUIInstance(ui_name) end )
    end
    self.open_ui_callbacks = {}
    local p = promise.new()
    table.insert(self.open_ui_callbacks, function(ui)
        if ui_name == ui.__cname then
            p:resolve(ui)
            return true
        end
    end)
    return p
end
function UIKit:CheckCloseUI(ui_name)
    local callbacks = self.close_ui_callbacks
    if #callbacks > 0 and callbacks[1](ui_name) then
        table.remove(callbacks, 1)
    end
end
function UIKit:PromiseOfClose(name)
    self.close_ui_callbacks = {}
    local p = promise.new()
    table.insert(self.close_ui_callbacks, function(ui_name)
        if name == ui_name then
            p:resolve()
            return true
        end
    end)
    return p
end
function UIKit:GetUIInstance(ui_name)
    if self:getRegistry().isObjectExists(ui_name) then
        return self:getRegistry().getObject(ui_name)
    end
end
function UIKit:RegistUI(ui)
    self.Registry.setObject(ui, ui.__cname)
end

function UIKit:createUIClass(className, baseName)
    return class(className, baseName == nil and self["GameUIBase"] or import('..ui.' .. baseName,CURRENT_MODULE_NAME))
end

function UIKit:newGameUI(gameUIName,... )
    if gameUIName ~= 'FullScreenPopDialogUI' then
        if self.Registry.isObjectExists(gameUIName) then
            print("已经创建过一个Object-->",gameUIName)
            return {AddToCurrentScene=function(...)end,AddToScene=function(...)end} -- 适配后面的调用不报错
        end
    end
    local viewPackageName = app.packageRoot .. ".ui." .. gameUIName
    local viewClass = require(viewPackageName)
    local instance = viewClass.new(...)
    if gameUIName ~= 'FullScreenPopDialogUI' then
        self.Registry.setObject(instance,gameUIName)
    end
    return instance
end
function UIKit:newWidgetUI(gameUIName,... )
    if gameUIName ~= 'FullScreenPopDialogUI' then
        if self.Registry.isObjectExists(gameUIName) then
            print("已经创建过一个Object-->",gameUIName)
            return {AddToCurrentScene=function(...)end,AddToScene=function(...)end} -- 适配后面的调用不报错
        end
    end
    local viewPackageName = app.packageRoot .. ".widget." .. gameUIName
    local viewClass = require(viewPackageName)
    local instance = viewClass.new(...)
    self.Registry.setObject(instance,gameUIName)
    return instance
end
function UIKit:getFontFilePath()
    return "Droid Sans Fallback.ttf"
end

function UIKit:getEditBoxFont()
    return "DroidSansFallback"
end

function UIKit:hex2rgba(hexNum)
    local a = bit:_rshift(hexNum,24)
    if a < 0 then
        a = a + 0x100
    end
    local r = bit:_and(bit:_rshift(hexNum,16),0xff)
    local g = bit:_and(bit:_rshift(hexNum,8),0xff)
    local b = bit:_and(hexNum,0xff)
    -- print(string.format("hex2rgba:%x --> %d %d %d %d",hexNum,r,g,b,a))
    return r,g,b,a
end

function UIKit:hex2c3b(hexNum)
    local r,g,b = self:hex2rgba(hexNum)
    return cc.c3b(r,g,b)
end

function UIKit:hex2c4b(hexNum)
    local r,g,b,a = self:hex2rgba(hexNum)
    return cc.c4b(r,g,b,a)
end


function UIKit:debugNode(node,name)
    name = name or " "
    printf("\n:::%s---------------------\n",name)
    printf("AnchorPoint---->%d,%d\n",node:getAnchorPoint().x,node:getAnchorPoint().y)
    printf("Position---->%d,%d\n",node:getPositionX(),node:getPositionY())
    printf("Size---->%d,%d\n",node:getContentSize().width,node:getContentSize().height)
end

function UIKit:commonProgressTimer(png)
    local progressFill = display.newSprite(png)
    local ProgressTimer = cc.ProgressTimer:create(progressFill)
    ProgressTimer:setType(display.PROGRESS_TIMER_BAR)
    ProgressTimer:setBarChangeRate(cc.p(1,0))
    ProgressTimer:setMidpoint(cc.p(0,0))
    ProgressTimer:setPercentage(0)
    ProgressTimer:setCascadeOpacityEnabled(true)
    return ProgressTimer
end

function UIKit:getRegistry()
    return self.Registry
end

function UIKit:closeAllUI()
    UIKit.open_ui_callbacks = {}
    UIKit.close_ui_callbacks = {}
    for name,v in pairs(self:getRegistry().objects_) do
        if v.__isBase and v.__type ~= self.UITYPE.BACKGROUND then
            v:LeftButtonClicked()
        end
    end
end
--[[
    参数和quick原函数一样
新属性-->
    color:hex 颜色值
    shadow:bool 是否用阴影
    margin:number 单个字水平间距
    lineHeight: number 行高(多行)
    bold:bool 加粗
]]--
function UIKit:ttfLabel( params )
    if not checktable(params) then
        printError("%s","params must a table")
    end
    params.font = UIKit:getFontFilePath()
    params.UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF
    if params.color then
        params.color = self:hex2c3b(params.color)
    end
    local label = cc.ui.UILabel.new(params)
    if params.ellipsis then
        label:setLineBreakWithoutSpace(true)
        label:setEllipsisEabled(true)
    end
    if params.shadow then
        label:enableShadow()
    end
    if params.margin then
        label:setAdditionalKerning(params.margin)
    end
    if params.lineHeight and params.dimensions then
        label:setLineHeight(params.lineHeight)
    end
    return label
end

function UIKit:convertColorToGL_( color )
    local r,g,b = self:hex2rgba(color)
    r = r/255
    g = g/255
    b = b/255
    return {r,g,b}
end


function UIKit:getImageByBuildingType( building_type ,level)
    local level_1,level_2 = 2 ,3
    if building_type=="keep" then
        return "keep_1.png"
    elseif building_type=="dragonEyrie" then
        return "dragonEyrie.png"
    elseif building_type=="watchTower" then
        return "watchTower_445x638.png"
    elseif building_type=="warehouse" then
        return "warehouse_498x468.png"
    elseif building_type=="toolShop" then
        return "toolShop_1_521x539.png"
    elseif building_type=="materialDepot" then
        return "materialDepot_1_438x531.png"
    elseif building_type=="armyCamp" then
        return "armyCamp.png"
    elseif building_type=="barracks" then
        return "barracks_553x536.png"
    elseif building_type=="blackSmith" then
        return "blackSmith_1_442x519.png"
    elseif building_type=="foundry" then
        return "foundry_1_487x479.png"
    elseif building_type=="lumbermill" then
        return "lumbermill_1_495x423.png"
    elseif building_type=="mill" then
        return "mill_1_470x405.png"
    elseif building_type=="stoneMason" then
        return "stoneMason_1_423x486.png"
    elseif building_type=="hospital" then
        return "hospital_1_392x472.png"
    elseif building_type=="townHall" then
        return "townHall_1_524x553.png"
    elseif building_type=="tradeGuild" then
        return "tradeGuild_1_558x403.png"
    elseif building_type=="tower" then
        return "tower_head_78x124.png"
    elseif building_type=="wall" then
        return "gate_292x302.png"
    elseif building_type=="dwelling" then
        if level<level_1 then
            return "dwelling_1_297x365.png"
        elseif level<level_2 then
            return "dwelling_2_357x401.png"
        else
            return "dwelling_3_369x419.png"
        end
    elseif building_type=="woodcutter" then
        if level<level_1 then
            return "woodcutter_1_342x250.png"
        elseif level<level_2 then
            return "woodcutter_2_364x334.png"
        else
            return "woodcutter_3_351x358.png"
        end
    elseif building_type=="farmer" then
        if level<level_1 then
            return "farmer_1_315x281.png"
        elseif level<level_2 then
            return "farmer_2_312x305.png"
        else
            return "farmer_3_332x345.png"
        end
    elseif building_type=="quarrier" then
        if level<level_1 then
            return "quarrier_1_303x296.png"
        elseif level<level_2 then
            return "quarrier_2_347x324.png"
        else
            return "quarrier_3_363x386.png"
        end
    elseif building_type=="miner" then
        if level<level_1 then
            return "miner_1_315x309.png"
        elseif level<level_2 then
            return "miner_2_340x308.png"
        else
            return "miner_3_326x307.png"
        end
    elseif building_type=="moonGate" then
        return UILib.alliance_building.moonGate
    elseif building_type=="orderHall" then
        return UILib.alliance_building.orderHall
    elseif building_type=="palace" then
        return UILib.alliance_building.palace
    elseif building_type=="shop" then
        return UILib.alliance_building.shop
    elseif building_type=="shrine" then
        return UILib.alliance_building.shrine
    end
end

function UIKit:shadowLayer()
    return display.newColorLayer(UIKit:hex2c4b(0x7a000000))
end

--
function UIKit:CreateEventTitle(...)
    local title, desc, callback = ...
    local node = display.newNode()
    node.tips = WidgetTips.new(title, desc):addTo(node)
        :align(display.CENTER, display.cx, display.top - 140)
        :show()
    node.timer = WidgetTimerProgress.new(549, 108):addTo(node)
        :align(display.CENTER, display.cx, display.top - 140)
        :hide()
        :OnButtonClicked(function(event)
            callback()
        end)

    function node:BeginEvent()
        self.tips:hide()
        self.timer:show()
    end
    function node:UpdateEvent(event, time)
        local is_empty = self:IsEmpty()

        self.tips:setVisible(is_empty)
        self.timer:setVisible(not is_empty)

        self.timer:SetDescribe(event:ContentDesc())
        self.timer:SetProgressInfo(event:TimeDesc(time))
    end
    function node:EndEvent()
        self.tips:show()
        self.timer:hide()
    end
    return node
end

-- TODO: 玩家头像
function UIKit:GetPlayerCommonIcon(key,isOnline)
    isOnline = type(isOnline) ~= 'boolean' and true or isOnline
    local heroBg = isOnline and display.newSprite("chat_hero_background.png") or self:getDiscolorrationSprite("chat_hero_background.png")
    self:GetPlayerIconOnly(key,isOnline):addTo(heroBg)
        :align(display.CENTER,56,65)
    return heroBg
end

function UIKit:GetPlayerIconImage(key)
    return UILib.player_icon[tonumber(key)]
end

function UIKit:GetPlayerIconOnly(key,isOnline)
    isOnline = type(isOnline) ~= 'boolean' and true or isOnline
    if not key then
        return isOnline and display.newSprite(UILib.player_icon[1]) or self:getDiscolorrationSprite(UILib.player_icon[1])
    end
    return isOnline and display.newSprite(self:GetPlayerIconImage(key)) or self:getDiscolorrationSprite(self:GetPlayerIconImage(key))
end
--TODO:将这个函数替换成CreateBoxPanel9来实现
function UIKit:CreateBoxPanel(height)
    local node = display.newNode()
    local bottom = display.newSprite("alliance_box_bottom_552x12.png")
        :addTo(node)
        :align(display.LEFT_BOTTOM,0,0)
    local top =  display.newSprite("alliance_box_top_552x12.png")
    local middleHeight = height - bottom:getContentSize().height - top:getContentSize().height
    local next_y = bottom:getContentSize().height
    while middleHeight > 0 do
        local middle = display.newSprite("alliance_box_middle_552x1.png")
            :addTo(node)
            :align(display.LEFT_BOTTOM,0, next_y)
        middleHeight = middleHeight - middle:getContentSize().height
        next_y = next_y + middle:getContentSize().height
    end
    top:addTo(node)
        :align(display.LEFT_BOTTOM,0,next_y)
    return node

end

function UIKit:CreateBoxPanel9(params)
    local common_bg = display.newScale9Sprite("gray_box_574x102.png")
    common_bg:setCapInsets(cc.rect(8,8,556,78))
    common_bg:setAnchorPoint(cc.p(0,0))
    common_bg:size(params.width and params.width or 552,params.height)
    return common_bg
end


function UIKit:CreateBoxWithoutContent(params)
    if not params then
        return display.newSprite("mission_box_558x66.png")
    else
        local sp = display.newScale9Sprite("mission_box_558x66.png")
        sp:size(params.width or 558,params.height or 66)
    end
end
function UIKit:CreateBoxPanelWithBorder(params)
    local node = display.newScale9Sprite("panel_556x120.png")
    node:setAnchorPoint(cc.p(0,0))
    node:size(params.width or 556,params.height or 120)
    return node
end

function UIKit:commonButtonLable(params)
    if not params then params = {} end
    params.color = params.color or 0xffedae
    params.size  = params.size or 24
    params.shadow = true
    return UIKit:ttfLabel(params)
end

function UIKit:commonTitleBox(height)
    local node = display.newNode()
    local bottom = display.newSprite("title_box_bottom_540x18.png")
        :addTo(node)
        :align(display.LEFT_BOTTOM,4,0)
    local top =  display.newSprite("title_box_top_548x58.png")
    local middleHeight = height - bottom:getContentSize().height - top:getContentSize().height
    local next_y = bottom:getContentSize().height
    while middleHeight > 0 do
        local middle = display.newSprite("title_box_middle_540x1.png")
            :addTo(node)
            :align(display.LEFT_BOTTOM,4, next_y)
        middleHeight = middleHeight - middle:getContentSize().height
        next_y = next_y + middle:getContentSize().height
    end
    top:addTo(node):align(display.LEFT_BOTTOM,0,next_y)
    return node
end

function UIKit:closeButton()
    local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
    return closeButton
end

-- 带按钮文字的黄，绿，红，紫，蓝，按钮
function UIKit:commonButtonWithBG(options)
    local BTN_COLOR = {
        "yellow",
        "blue",
        "green",
        "red",
        "purple",
    }
    -- display.newScale9Sprite("btn_bg_148x58.png",nil,nil,cc.size(options.w, options.h))
    local btn_bg = cc.ui.UIImage.new("btn_bg_148x58.png", {scale9 = true,
        capInsets = cc.rect(0, 0, 144 , 54)
    }):align(display.CENTER):setLayoutSize(options.w, options.h)
    btn_bg.button = WidgetPushButton.new(
        {normal = BTN_COLOR[options.style].."_btn_up_148x58.png",pressed = BTN_COLOR[options.style].."_btn_down_148x58.png",disabled="gray_btn_148x58.png"},
        {scale9 = true}
    ):setButtonSize(options.w-2,options.h-2)
        :setButtonLabel(self:commonButtonLable(options.labelParams))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if options.listener then
                    options.listener()
                end
            end
        end)
        :align(display.CENTER,btn_bg:getContentSize().width/2,btn_bg:getContentSize().height/2):addTo(btn_bg)

    return btn_bg
end

function UIKit:commonListView(params,topEnding,bottomEnding)
    assert(params.direction==cc.ui.UIScrollView.DIRECTION_VERTICAL,"错误！只支持上下滑动")
    local viewRect = params.viewRect
    viewRect.x = 0
    viewRect.y = 0
    local list_node = display.newNode()
    list_node:ignoreAnchorPointForPosition(false)
    list_node:setContentSize(cc.size(viewRect.width,viewRect.height))
    local list = UIListView.new(params):addTo(list_node)
    -- 是否有顶部的边界条，默认有
    local isTopEnding
    if tolua.type(topEnding)~="nil" then
        isTopEnding = topEnding
    else
        isTopEnding = true
    end
    if isTopEnding then
        cc.ui.UIImage.new("listview_edging.png"):addTo(list_node):align(display.BOTTOM_CENTER,viewRect.width/2,viewRect.height-6)
    end
    if bottomEnding == nil or bottomEnding == true then
        cc.ui.UIImage.new("listview_edging.png"):addTo(list_node):align(display.BOTTOM_CENTER,viewRect.width/2,-11):flipY(true)
    end
    return list,list_node
end
function UIKit:commonListView_1(params)
    assert(params.direction==cc.ui.UIScrollView.DIRECTION_VERTICAL,"错误！只支持上下滑动")
    local viewRect = params.viewRect
    viewRect.x = 0
    viewRect.y = 0
    local list_node = WidgetUIBackGround.new({width = viewRect.width+20,height = viewRect.height+22},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
    local list = UIListView.new(params):addTo(list_node):pos(10,12)
    return list,list_node
end
function UIKit:createLineItem(params)
    -- 分割线
    local line = display.newScale9Sprite("dividing_line.png")
    line:size(params.width,2)
    local line_size = line:getContentSize()
    self:ttfLabel(
        {
            text = params.text_1,
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_BOTTOM, 0, 4)
        :addTo(line)
    local value_label = self:ttfLabel(
        {
            text = params.text_2,
            size = 22,
            color = 0x403c2f
        }):align(display.RIGHT_BOTTOM, line_size.width, 4)
        :addTo(line)

    function line:SetValue(value)
        value_label:setString(value)
    end
    return line
end

function UIKit:showMessageDialogCanCanleNotAutoClose(title,tips,ok_callback,cancel_callback)
    title = title or _("提示")
    local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback)
        :SetTitle(title)
        :SetPopMessage(tips)
        :CreateOKButton({
            listener =  function ()
                if ok_callback then
                    ok_callback()
                end
            end
        })
    dialog:CreateCancelButton({
        listener = function ()
            if cancel_callback then
                cancel_callback()
            end
        end,
        btn_name = _("取消")
    })
    dialog:DisableAutoClose()
    dialog:AddToCurrentScene()
    return dialog
end

function UIKit:showMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button,x_button_callback)
    title = title or _("提示")
    tips = tips or ""
    if type(visible_x_button) ~= 'boolean' then visible_x_button = true end
    local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback):SetTitle(title):SetPopMessage(tips)
    if ok_callback then
        dialog:CreateOKButton({
            listener =  function ()
                if ok_callback then
                    ok_callback()
                end
            end
        })
    end

    if cancel_callback then
        dialog:CreateCancelButton({
            listener = function ()
                cancel_callback()
            end,btn_name = _("取消")})
    end
    dialog:VisibleXButton(visible_x_button)
    if not visible_x_button then
        dialog:DisableAutoClose()
    end
    dialog:zorder(3000)
    dialog:AddToCurrentScene()
    return dialog
end

function UIKit:showEvaluateDialog()
    local dialog = UIKit:newGameUI("FullScreenPopDialogUI"):SetTitle("亲"):SetPopMessage("是否去app store评价我们?")
        :CreateOKButton({
            listener =  function ()
                device.openURL("http://www.baidu.com")
            end,btn_name = _("支持一个")
        })
        :CreateCancelButton({
            listener = function ()
            end,btn_name = _("残忍的拒绝")
        })dialog:AddToCurrentScene()
    return dialog
end

function UIKit:WaitForNet(delay)
    local scene = display.getRunningScene()
    if scene.WaitForNet then
        scene:WaitForNet(delay)
    end
end

function UIKit:NoWaitForNet()
    local scene = display.getRunningScene()
    if scene.NoWaitForNet then
        scene:NoWaitForNet()
    end
end

function UIKit:getErrorCodeData(code)
    return error_code[code] or {}
end

function UIKit:getErrorCodeKey(code)
    return self:getErrorCodeData(code).key or ""
end

function UIKit:GotoPreconditionBuilding(jump_building)
    local city = jump_building:BelongCity()
    if tolua.type(jump_building) == "string" then
        UIKit:showMessageDialog(_("提示"),string.format(_("请首先建造%s"),Localize.building_name[jump_building]),function()end)
            :AddToCurrentScene()
        return
    end
    local current_scene = display.getRunningScene()
    local building_sprite = current_scene:GetSceneLayer():FindBuildingSpriteByBuilding(jump_building, city)
    current_scene:GotoLogicPoint(jump_building:GetMidLogicPosition())
    if current_scene.AddIndicateForBuilding then
        current_scene:AddIndicateForBuilding(building_sprite)
    end
end
-- 暂时只有宝箱
function UIKit:PlayUseItemAni(items)
    if string.find(items:Name(),"dragonChest") then
        local ani = ""
        local item_name = items:Name()
        if item_name == "dragonChest_1" then
            ani = "lanse"
        elseif item_name == "dragonChest_2" then
            ani = "lvse_box"
        elseif item_name == "dragonChest_3" then
            ani = "zise_box"
        end
        local box = ccs.Armature:create(ani):addTo(display.getRunningScene(),10000):align(display.CENTER, display.cx-50, display.cy)
            :scale(0.5)
        box:getAnimation():setMovementEventCallFunc(function (armatureBack, movementType, movementID)
            if movementType == ccs.MovementEventType.start then
            elseif movementType == ccs.MovementEventType.complete then
                box:removeFromParent()
            elseif movementType == ccs.MovementEventType.loopComplete then
            end
        end)

        box:getAnimation():play("Animation1", -1, 0)
    end
end



function UIKit:pack_alliance_flag(form_index,form_color_index_1,form_color_index_2,graphic_index,graphic_color_index)
    checkint(form_index)
    checkint(form_color_index_1)
    checkint(form_color_index_2)
    checkint(graphic_index)
    checkint(graphic_color_index)
    return string.format("%d,%d,%d,%d,%d",form_index,form_color_index_1,form_color_index_2,graphic_index,graphic_color_index)
end

function UIKit:unpack_alliance_flag(flag_str)
    local r = string.split(flag_str, ",")
    return unpack(r)
end

function UIKit:getDiscolorrationSprite(image)
    return display.newFilteredSprite(image, "CUSTOM", json.encode({frag = "shaders/ps_discoloration.fs",shaderName = "ps_discoloration"}))
end


function UIKit:getIapPackageName(productId)
    local Localize = import(".Localize", CURRENT_MODULE_NAME)
    return Localize.iap_package_name[productId]
end

function UIKit:addTipsToNode( node,tips , include_node)
    node:setTouchEnabled(true)
    node:setTouchSwallowEnabled(false)
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            local world_postion = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            local tips_bg = display.newScale9Sprite("back_ground_240x73.png",0,0,cc.size(240,73),cc.rect(10,10,220,53))
                :addTo(include_node):align(display.BOTTOM_CENTER)
            tips_bg:setTag(100)
            local text_1 = UIKit:ttfLabel({text = tips,size = 20 ,color = 0xfff2b3})
                :addTo(tips_bg)
            tips_bg:size(text_1:getContentSize().width+20,text_1:getContentSize().height+40)
            local t_size = tips_bg:getContentSize()
            text_1:align(display.CENTER, t_size.width/2, t_size.height/2)
            tips_bg:zorder(999999)
            local node_postioon = include_node:convertToNodeSpace(world_postion) 
            tips_bg:setPosition(node_postioon.x, node_postioon.y + node:getContentSize().height/2)
        elseif event.name == "ended" then
            if include_node:getChildByTag(100) then
                include_node:removeChildByTag(100, true)
            end
        elseif event.name == "moved" then
            local rect = node:convertToNodeSpace(cc.p(event.x,event.y))
            local box = node:getContentSize()
            if box.width < rect.x or rect.x < 0 or box.height < rect.y or rect.y < 0 then
                if include_node:getChildByTag(100) then
                    include_node:removeChildByTag(100, true)
                end
            end
        end
        return true
    end)
end
