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
local CURRENT_MODULE_NAME = ...
local Localize = import(".Localize", CURRENT_MODULE_NAME)

local error_code = {}
for k,v in pairs(GameDatas.Errors.errors) do
    v.message = Localize.server_errors[v.code]
    error_code[v.code] = v
end

UIKit =
    {
        Registry   = import('framework.cc.Registry'),
        GameUIBase = import('..ui.GameUIBase'),
        messageDialogs = {}
    }
UIKit.BTN_COLOR = Enum("YELLOW","BLUE","GREEN","RED","PURPLE")
UIKit.UITYPE = Enum("BACKGROUND","WIDGET","MESSAGEDIALOG")
UIKit.open_ui_callbacks = {}
UIKit.close_ui_callbacks = {}

function UIKit:CheckOpenUI(ui, isopen)
    local callbacks = self.open_ui_callbacks
    if #callbacks > 0 then
        if isopen then
            local ui_name,callback = unpack(callbacks[1])
            if ui_name == ui.__cname then
                ui.__type = UIKit.UITYPE.BACKGROUND
                ui:GetFteLayer()
            end
        else
            local ui_name,callback = unpack(callbacks[1])
            if callback(ui) then
                table.remove(callbacks, 1)
            end
        end
    end
end
function UIKit:PromiseOfOpen(ui_name)
    if UIKit:GetUIInstance(ui_name) then
        return cocos_promise.defer(function() return UIKit:GetUIInstance(ui_name) end )
    end
    self.open_ui_callbacks = {}
    local p = promise.new()
    table.insert(self.open_ui_callbacks, {ui_name, function(ui)
        if ui_name == ui.__cname then
            p:resolve(ui)
            return true
        end
    end})
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
    if gameUIName == 'FullScreenPopDialogUI' then
    else
        if self.Registry.isObjectExists(gameUIName) then
            print("已经创建过一个Object-->",gameUIName)
            return {AddToCurrentScene=function(...)end,AddToScene=function(...)end} -- 适配后面的调用不报错
        end
    end
    local viewPackageName = app.packageRoot .. ".ui." .. gameUIName
    local viewClass = require(viewPackageName)
    local instance = viewClass.new(...)
    if gameUIName == 'FullScreenPopDialogUI' then
        self:addMessageDialog(instance)
    else
        self.Registry.setObject(instance,gameUIName)
    end
    return instance
end
function UIKit:newWidgetUI(gameUIName,... )
    if gameUIName == 'FullScreenPopDialogUI' then
    else
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

local color_map = {}
function UIKit:hex2rgba(hexNum)
    if not color_map[hexNum] then
        local a = bit:_rshift(hexNum,24)
        if a < 0 then
            a = a + 0x100
        end
        local r = bit:_and(bit:_rshift(hexNum,16),0xff)
        local g = bit:_and(bit:_rshift(hexNum,8),0xff)
        local b = bit:_and(hexNum,0xff)
        print(string.format("hex2rgba:%x --> %d %d %d %d",hexNum,r,g,b,a))
        color_map[hexNum] = {r,g,b,a}
    end
    return unpack(color_map[hexNum])
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
--[[
不会关闭的界面:答题界面  联盟结算界面 网络相关的信息弹出框 联盟对战相关的弹出框
--]]
function UIKit:closeAllUI(force)
    if force then
        self.open_ui_callbacks = {}
        self.close_ui_callbacks = {}
    end
    for name,v in pairs(self:getRegistry().objects_) do
        if v.__isBase and v.__type ~= self.UITYPE.BACKGROUND and v.__cname ~= 'GameUISelenaQuestion'  and v.__cname ~= 'GameUIWarSummary' then
            v:LeftButtonClicked()
        end
    end
    for key,v in pairs(self.messageDialogs) do
        if type(v.GetUserData) == 'function' then
            if v:GetUserData() ~= '__key__dialog' and '__alliance_war_tips__' ~= v:GetUserData() then
                v:LeftButtonClicked()
            end
        else
            self.messageDialogs[key] = nil
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

function UIKit:GetPlayerCommonIcon(key,isOnline)
    isOnline = type(isOnline) ~= 'boolean' and true or isOnline
    local heroBg = isOnline and display.newSprite("dragon_bg_114x114.png") or self:getDiscolorrationSprite("dragon_bg_114x114.png")
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
    local node = self:CreateBoxPanel9({height = height})
    return node
end

function UIKit:CreateBoxPanel9(params)
    local common_bg = WidgetUIBackGround.new({width = params.width and params.width or 552,height = params.height},WidgetUIBackGround.STYLE_TYPE.STYLE_3)
    common_bg:setAnchorPoint(cc.p(0,0))
    return common_bg
end


function UIKit:CreateBoxWithoutContent(params)
    local params = params or {}
    return WidgetUIBackGround.new({width = params.width or 558,height = params.height or 66},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
end
function UIKit:CreateBoxPanelWithBorder(params)
    local node = WidgetUIBackGround.new({width = params.width or 556,height = params.height or 120},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
    node:setAnchorPoint(cc.p(0,0))
    return node
end

function UIKit:commonButtonLable(params)
    if not params then params = {} end
    params.color = params.color or 0xffedae
    params.size  = params.size or 22
    params.shadow = true
    return UIKit:ttfLabel(params)
end

function UIKit:commonTitleBox(height)
    local node = display.newNode()

    local list_bg = display.newScale9Sprite("back_ground_540x64.png", 4, 0,cc.size(540, height - 50),cc.rect(10,10,520,44))
        :align(display.LEFT_BOTTOM):addTo(node)
    local title_bg = display.newSprite("alliance_evnets_title_548x50.png"):align(display.LEFT_BOTTOM, 0, height - 50):addTo(node)

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

function UIKit:commonListView(params,topEnding,bottomEnding,useSysUI)
    assert(params.direction==cc.ui.UIScrollView.DIRECTION_VERTICAL,"错误！只支持上下滑动")
    local viewRect = params.viewRect
    viewRect.x = 0
    viewRect.y = 0
    local list_node = display.newNode()
    list_node:ignoreAnchorPointForPosition(false)
    list_node:setContentSize(cc.size(viewRect.width,viewRect.height))
    local ui_class = UIListView
    if useSysUI then  ui_class = cc.ui.UIListView end
    local list = ui_class.new(params):addTo(list_node)
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
    local line = display.newScale9Sprite("dividing_line.png",0,0,cc.size(params.width,2),cc.rect(10,2,382,2))
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
-- MessageDialog
------------------------------------------------------------------------------------------------------------------------------------------------
function UIKit:showMessageDialogCanCanleNotAutoClose(title,tips,ok_callback,cancel_callback)
    -- title = title or _("提示")
    -- local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback)
    --     :SetTitle(title)
    --     :SetPopMessage(tips)
    --     :CreateOKButton({
    --         listener =  function ()
    --             if ok_callback then
    --                 ok_callback()
    --             end
    --         end
    --     })
    -- dialog:CreateCancelButton({
    --     listener = function ()
    --         if cancel_callback then
    --             cancel_callback()
    --         end
    --     end,
    --     btn_name = _("取消")
    -- })
    -- dialog:DisableAutoClose()
    -- self:__addMessageDialogToCurrentScene(dialog)
    -- return dialog
    return self:showMessageDialogWithParams({
        title = title,
        content = tips,
        ok_callback = ok_callback,
        cancel_callback = cancel_callback,
        auto_close = false,
    })
end

function UIKit:addMessageDialog(instance)
    print(instance:GetUserData(),"addMessageDialog---->")
    self.messageDialogs[instance:GetUserData()] = instance
    dump(self.messageDialogs,"self.messageDialogs----->")
end

function UIKit:removeMesssageDialog(instance)
    print(instance:GetUserData(),"removeMesssageDialog---->")
    self.messageDialogs[instance:GetUserData()] = nil
    dump(self.messageDialogs,"self.messageDialogs----->")
end

function UIKit:isKeyMessageDialogShow()
    return self.messageDialogs['__key__dialog'] ~= nil
end

function UIKit:isMessageDialogShow(instance)
    return instance and instance.__cname == 'FullScreenPopDialogUI' and self:isMessageDialogShowWithUserData(instance:GetUserData())
end

function UIKit:isMessageDialogShowWithUserData(userData)
    return self.messageDialogs[userData] ~= nil
end

function UIKit:showKeyMessageDialog(title,tips,ok_callback,cancel_callback)
    if self:isKeyMessageDialogShow() then
        print("忽略了一次关键性弹窗")
        return
    end
    local dialog =  UIKit:showMessageDialog(title,tips,ok_callback,cancel_callback,false,nil,"__key__dialog")
end

function UIKit:showMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button,x_button_callback,user_data)
    title = title or _("提示")
    tips = tips or ""
    if type(visible_x_button) ~= 'boolean' then visible_x_button = true end
    local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback,user_data):SetTitle(title):SetPopMessage(tips)
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
    self:__addMessageDialogToCurrentScene(dialog)
    dialog:zorder(4001)
    return dialog
end

function UIKit:showConfirmUseGemMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button,x_button_callback,user_data)
    title = title or _("提示")
    tips = tips or ""
    if type(visible_x_button) ~= 'boolean' then visible_x_button = true end
    local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback,user_data):SetTitle(title):SetMessageBgSize(342,190):SetPopMessage(tips)
    if ok_callback then
        dialog:CreateOKButton({
            listener =  function ()
                if ok_callback then
                    ok_callback()
                end
            end,
            y = display.top-560
        })
    end

    dialog:CreateCancelButton({
        listener = function ()
        end,btn_name = _("取消"),y = display.top-560})
    dialog:VisibleXButton(visible_x_button)
    if not visible_x_button then
        dialog:DisableAutoClose()
    end
    -- 取消提醒按钮
    self:ttfLabel({
        text = _("不再提醒"),
        size = 18,
        color = 0x615b44
    }):addTo(dialog):align(display.RIGHT_CENTER,display.cx+240,display.top-620)
    local tmp_bg = display.newSprite("activity_check_bg_55x51.png"):addTo(dialog):pos(display.cx+256,display.top-620):scale(0.6)
    tmp_bg:hide()
    local saved_button = cc.ui.UICheckBoxButton.new({
        off = "activity_check_bg_55x51.png",
        on = "activity_check_body_55x51.png",
    }):onButtonStateChanged(function(event)
        dump(event)
        if event.state == "on" then
            tmp_bg:show()
            app:GetGameDefautlt():CloseGemRemind()
        else
            app:GetGameDefautlt():OpenGemRemind()
            tmp_bg:hide()
        end
    end):addTo(dialog):pos(display.cx+256,display.top-620):scale(0.6)
    self:__addMessageDialogToCurrentScene(dialog)
    dialog:zorder(4001)
    return dialog
end

function UIKit:showMessageDialogWithParams(params)
    local title = params.title or _("提示")
    local content = params.content or ""
    local ok_callback = params.ok_callback or function()end
    local ok_string = params.ok_string or _("确定")
    local ok_btn_images = params.ok_btn_images or {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
    local cancel_string = params.cancel_string or _("取消")
    local cancel_btn_images = params.cancel_btn_images or {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"}
    local visible_x_button = true
    if  type(params.visible_x_button) == 'boolean' then
        visible_x_button = params.visible_x_button
    end
    local x_button_callback = params.x_button_callback or function()end
    local user_data = params.user_data or nil
    local zorder = params.zorder or  3001

    local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback,user_data):SetTitle(title):SetPopMessage(content):zorder(zorder)

    dialog:CreateOKButton({listener = ok_callback,btn_name = ok_string, btn_images = ok_btn_images})
    if params.cancel_callback then
        dialog:CreateCancelButton({listener = cancel_callback,btn_name = cancel_string,btn_images = cancel_btn_images})
    end
    dialog:VisibleXButton(visible_x_button)
    if type(params.auto_close) ~= "boolean" then
        if not visible_x_button then dialog:DisableAutoClose() end
    else
        if not params.auto_close then
            dialog:DisableAutoClose()
        end
    end
    self:__addMessageDialogToCurrentScene(dialog)
    return dialog
end
-- 可能得到材料的派兵行为检查
function UIKit:showSendTroopMessageDialog(attack_func,material_type,effect_str)
    if City:GetMaterialManager():CheckOutOfRangeByType(material_type) then
        local dialog = self:showMessageDialogWithParams({
            title = _("提示"),
            content = _(string.format(_("当前材料库房中的%s材料已满，你可能无法获得此次战斗所得的材料奖励。是否仍要派兵？"),effect_str)),
            ok_callback = attack_func,
            ok_btn_images = {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
            ok_string = _("强行派兵"),
            cancel_callback = function () end,
            cancel_btn_images = {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
        })
    else
        attack_func()
    end
end

function UIKit:getMessageDialogWithParams(params)
    local title = params.title or _("提示")
    local content = params.content or ""
    local ok_callback = params.ok_callback or function()end
    local ok_string = params.ok_string or _("确定")
    local cancel_string = params.cancel_string or _("取消")
    local visible_x_button = true
    if  type(params.visible_x_button) == 'boolean' then
        visible_x_button = params.visible_x_button
    end
    local x_button_callback = params.x_button_callback or function()end
    local user_data = params.user_data or nil
    local zorder = params.zorder or  3001

    local dialog = UIKit:newGameUI("FullScreenPopDialogUI",x_button_callback,user_data):SetTitle(title):SetPopMessage(content):zorder(zorder)

    dialog:CreateOKButton({listener = ok_callback,btn_name = ok_string})
    if params.cancel_callback then
        dialog:CreateCancelButton({listener = cancel_callback,btn_name = _("取消")})
    end
    dialog:VisibleXButton(visible_x_button)
    if type(params.auto_close) ~= "boolean" then
        if not visible_x_button then dialog:DisableAutoClose() end
    else
        if not params.auto_close then
            dialog:DisableAutoClose()
        end
    end
    return dialog
end

function UIKit:showEvaluateDialog(ok_callback)
    local dialog = UIKit:newGameUI("FullScreenPopDialogUI"):SetTitle(_("评价我们")):SetPopMessage(_("喜欢我们的游戏吗？"))
        :CreateOKButton({
            listener =  function ()
                device.openURL(CONFIG_APP_URL[device.platform])
                if ok_callback then
                    ok_callback()
                end
            end,btn_name = _("前去评价"),btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}
        })
        :CreateCancelButton({
            listener = function ()
            end,btn_name = _("残忍的拒绝")
        })
    self:__addMessageDialogToCurrentScene(dialog)
    return dialog
end

function UIKit:__addMessageDialogToCurrentScene(dialog)
    local current_scene = display.getRunningScene()
    if current_scene then
        if tolua.type(current_scene) ~= 'cc.Scene' then
            self:addMessageDialogWillShow(dialog)
        else
            dialog:AddToScene(current_scene, true)
        end
    end
end

function UIKit:getMessageDialogWillShow()
    -- printLog("info", "getMessageDialogWillShow--->%s",self.willShowMessage_ or "nil")
    return self.willShowMessage_
end
function UIKit:clearMessageDialogWillShow()
    if self.willShowMessage_ then
        self.willShowMessage_:release()
    end
    self.willShowMessage_ = nil
end
--如果是__key__dialog强制替换
function UIKit:addMessageDialogWillShow(messageDialog)
    if self.willShowMessage_ then
        print("addMessageDialogWillShow----->1",tolua.type(messageDialog))
        if messageDialog:GetUserData() == '__key__dialog' then
            self.willShowMessage_:release()
            messageDialog:retain()
            self.willShowMessage_ = messageDialog
        end
    else
        print("addMessageDialogWillShow----->2",tolua.type(messageDialog),messageDialog.__cname,type(messageDialog.AddToScene))
        messageDialog:retain()
        self.willShowMessage_ = messageDialog
    end
end
------------------------------------------------------------------------------------------------------------
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
        return
    end
    local current_scene = display.getRunningScene()
    local building_sprite = current_scene:GetSceneLayer():FindBuildingSpriteByBuilding(jump_building, city)
    local x,y = jump_building:GetMidLogicPosition()
    current_scene:GotoLogicPoint(x,y,40):next(function()
        if current_scene.AddIndicateForBuilding then
            current_scene:AddIndicateForBuilding(building_sprite)
        end
    end)
end
-- 暂时只有宝箱
function UIKit:PlayUseItemAni(items,awards,message)
    if string.find(items:Name(),"dragonChest") or string.find(items:Name(),"chest") then
        local ani = ""
        local item_name = items:Name()
        if item_name == "dragonChest_1" then
            ani = "lanse"
        elseif item_name == "dragonChest_2" then
            ani = "lvse_box"
        elseif item_name == "dragonChest_3" then
            ani = "zise_box"
        elseif item_name == "chest_1" then
            ani = "mu_box"
        elseif item_name == "chest_2" then
            ani = "tong_box"
        elseif item_name == "chest_3" then
            ani = "yin_box"
        elseif item_name == "chest_4" then
            ani = "jin_box"
        end
        if ani then
            self:newGameUI("GameUIChest", items,awards,message,ani):AddToCurrentScene():setLocalZOrder(10000)
        end
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
    return Localize.iap_package_name[productId]
end

function UIKit:addTipsToNode( node,tips , include_node)
    node:setTouchEnabled(true)
    node:setTouchSwallowEnabled(false)
    local tips_bg
    if not include_node:getChildByTag(9090) then
        tips_bg = display.newScale9Sprite("back_ground_240x73.png",0,0,cc.size(240,73),cc.rect(10,10,220,53))
            :addTo(include_node):align(display.BOTTOM_CENTER)
        tips_bg:setTag(9090)
        local text_1 = UIKit:ttfLabel({text = tips,size = 20 ,color = 0xfff2b3})
            :addTo(tips_bg)
        tips_bg:size(text_1:getContentSize().width+20,text_1:getContentSize().height+40)
        local t_size = tips_bg:getContentSize()
        text_1:align(display.CENTER, t_size.width/2, t_size.height/2)
        tips_bg:zorder(999999)
        tips_bg:hide()
        function tips_bg:SetTips( tips )
            text_1:setString(tips)
            self:size(text_1:getContentSize().width+20,text_1:getContentSize().height+40)
            local t_size = self:getContentSize()
            text_1:align(display.CENTER, t_size.width/2, t_size.height/2)
        end
    else
        tips_bg = include_node:getChildByTag(9090)
    end
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            local world_postion = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            local node_postioon = include_node:convertToNodeSpace(world_postion)
            tips_bg:setPosition(node_postioon.x, node_postioon.y + node:getContentSize().height/2)
            tips_bg:SetTips(tips)
            tips_bg:show()
        elseif event.name == "ended" then
            tips_bg:hide()
        elseif event.name == "moved" then
            local rect = node:convertToNodeSpace(cc.p(event.x,event.y))
            local box = node:getContentSize()
            if box.width < rect.x or rect.x < 0 or box.height < rect.y or rect.y < 0 then
                tips_bg:hide()
            end
        end
        return true
    end)
    return tips_bg
end

function UIKit:GetItemImage(reward_type,item_key)
    if reward_type == 'soldiers' then
        return UILib.soldier_image[item_key][1]
    elseif reward_type == 'resource'
        or reward_type == 'special'
        or reward_type == 'speedup'
        or reward_type == 'buff'
        or reward_type == 'buff' then
        return UILib.item[item_key]
    elseif reward_type == 'dragonMaterials' then
        return UILib.dragon_material_pic_map[item_key]
    elseif reward_type == 'allianceInfo' then
        if item_key == 'loyalty' then
            return "loyalty_128x128.png"
        end
    elseif reward_type == 'basicInfo' then
        if item_key == 'marchQueue' then
            return "tmp_march_queue_128x128.png"
        end
    end
end

function UIKit:ShakeAction(is_forever, delay)
    is_forever = is_forever or true
    delay = delay or 0
    local t = 0.025
    local r = 5
    local shake_list = {
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
    }
    if delay > 0 then
        table.insert(shake_list, cca.delay(delay))
    end
    if is_forever then
        return cc.RepeatForever:create(transition.sequence(shake_list))
    end
    return transition.sequence(shake_list)
end
function UIKit:ButtonAddScaleAction(button)
    button:onButtonPressed(function(event)
        event.target:runAction(cc.ScaleTo:create(0.1, 1.2))
    end):onButtonRelease(function(event)
        event.target:runAction(cc.ScaleTo:create(0.1, 1))
    end)
    return button
end

---
local soldier_animap = {
    -- 普通兵种
    --
    bubing_1 = {cc.p(0.55, 0.38), false, 1},
    bubing_2 = {cc.p(0.61, 0.45), false, 1},
    bubing_3 = {cc.p(0.59, 0.48), false, 1},
    --
    gongjianshou_1 = {cc.p(0.52, 0.37), false, 1},
    gongjianshou_2 = {cc.p(0.52, 0.37), false, 1},
    gongjianshou_3 = {cc.p(0.52, 0.37), false, 1},
    --
    qibing_1 = {cc.p(0.5, 0.45), false, 1},
    qibing_2 = {cc.p(0.5, 0.46), false, 1},
    qibing_3 = {cc.p(0.5, 0.48), false, 1},
    --
    toushiche = {cc.p(0.39, 0.4), false, 1},
    toushiche_2 = {cc.p(0.39, 0.4), false, 1},
    toushiche_3 = {cc.p(0.37, 0.4), false, 1},
    --
    shaobing_1 = {cc.p(0.5, 0.36), false, 1},
    shaobing_2 = {cc.p(0.5, 0.36), false, 1},
    shaobing_3 = {cc.p(0.5, 0.36), false, 1},
    --
    nugongshou_1 = {cc.p(0.5, 0.38), false, 1},
    nugongshou_2 = {cc.p(0.5, 0.38), false, 1},
    nugongshou_3 = {cc.p(0.34, 0.38), false, 1},
    --
    youqibing_1 = {cc.p(0.5, 0.38), false, 1},
    youqibing_2 = {cc.p(0.5, 0.38), false, 1},
    youqibing_3 = {cc.p(0.5, 0.38), false, 1},
    --
    nuche_1 = {cc.p(0.5, 0.45), false, 1},
    nuche_2 = {cc.p(0.5, 0.45), false, 1},
    nuche_3 = {cc.p(0.5, 0.45), false, 1},

    -- 特殊兵种
    kulouyongshi = {cc.p(0.5, 0.45), false, 1.6},
    kulousheshou = {cc.p(0.28, 0.45), false, 1.6},
    siwangqishi = {cc.p(0.5, 0.45), false, 1.5},
    jiaorouche = {cc.p(0.37, 0.45), false, 1.4},
    -- 黑化兵
    heihua_bubing_2 = {cc.p(0.5, 0.3), false, 1},
    heihua_bubing_3 = {cc.p(0.45, 0.33), true, 0.9},
    --
    heihua_gongjianshou_2 = {cc.p(0.1, 0.09), true, 1, true},
    heihua_gongjianshou_3 = {cc.p(0.47, 0.22), true, 1},
    --
    heihua_qibing_2 = {cc.p(0.5, 0.4), true, 0.9},
    heihua_qibing_3 = {cc.p(0.55, 0.45), true, 0.9},
    --
    heihua_toushiche_2 = {cc.p(0.4, 0.4), true, 0.7},
    heihua_toushiche_3 = {cc.p(0.4, 0.45), true, 0.7},
    --
    heihua_shaobing_2 = {cc.p(0.5, 0.22), true, 0.9},
    heihua_shaobing_3 = {cc.p(0.5, 0.3), true, 0.9},
    --
    heihua_nugongshou_2 = {cc.p(0.48, 0.35), true, 0.9},
    heihua_nugongshou_3 = {cc.p(0.48, 0.3), true, 0.9},
    --
    heihua_youqibing_2 = {cc.p(0.48, 0.3), true, 0.9},
    heihua_youqibing_3 = {cc.p(0.48, 0.35), true, 0.9},
    --
    heihua_nuche_2 = {cc.p(0.5, 0.4), true, 0.7},
    heihua_nuche_3 = {cc.p(0.5, 0.45), true, 0.7},
}
local dragon_fly_45_ani = {
    red_long = {cc.p(0.52, 0.47), false, 1},
    blue_long = {cc.p(0.52, 0.47), false, 1},
    green_long = {cc.p(0.52, 0.47), false, 1},
}
local dragon_fly_neg_45_ani = {
    red_long = {cc.p(0.53, 0.49), false, 1},
    blue_long = {cc.p(0.53, 0.49), false, 1},
    green_long = {cc.p(0.53, 0.49), false, 1},
}
local soldier_move_45_ani = {
    -- 普通兵种
    --
    bubing_1 = {cc.p(0.54, 0.38), false, 1},
    bubing_2 = {cc.p(0.57, 0.48), false, 1},
    bubing_3 = {cc.p(0.54, 0.54), false, 1},
    --
    gongjianshou_1 = {cc.p(0.5, 0.31), false, 1},
    gongjianshou_2 = {cc.p(0.5, 0.35), false, 1},
    gongjianshou_3 = {cc.p(0.49, 0.35), false, 1},
    --
    qibing_1 = {cc.p(0.48, 0.45), false, 1},
    qibing_2 = {cc.p(0.48, 0.45), false, 1},
    qibing_3 = {cc.p(0.48, 0.48), false, 1},
    --
    toushiche = {cc.p(0.39, 0.4), false, 1},
    toushiche_2 = {cc.p(0.39, 0.44), false, 1},
    toushiche_3 = {cc.p(0.37, 0.44), false, 1},
    --
    shaobing_1 = {cc.p(0.47, 0.47), false, 1},
    shaobing_2 = {cc.p(0.47, 0.47), false, 1},
    shaobing_3 = {cc.p(0.5, 0.46), false, 1},
    --
    nugongshou_1 = {cc.p(0.47, 0.4), false, 1},
    nugongshou_2 = {cc.p(0.47, 0.38), false, 1},
    nugongshou_3 = {cc.p(0.32, 0.4), false, 1},
    --
    youqibing_1 = {cc.p(0.48, 0.38), false, 1},
    youqibing_2 = {cc.p(0.48, 0.38), false, 1},
    youqibing_3 = {cc.p(0.48, 0.38), false, 1},
    --
    nuche_1 = {cc.p(0.5, 0.45), false, 1},
    nuche_2 = {cc.p(0.5, 0.45), false, 1},
    nuche_3 = {cc.p(0.49, 0.45), false, 1},

    -- 特殊兵种
    kulouyongshi = {cc.p(0.47, 0.45), false, 1},
    kulousheshou = {cc.p(0.24, 0.46), false, 1},
    siwangqishi = {cc.p(0.5, 0.45), false, 1},
    jiaorouche = {cc.p(0.338, 0.48), false, 1},
}
local soldier_move_neg_45_ani = {
    -- 普通兵种
    --
    bubing_1 = {cc.p(0.51, 0.31), false, 1},
    bubing_2 = {cc.p(0.57, 0.4), false, 1},
    bubing_3 = {cc.p(0.52, 0.4), false, 1},
    --
    gongjianshou_1 = {cc.p(0.51, 0.37), false, 1},
    gongjianshou_2 = {cc.p(0.52, 0.37), false, 1},
    gongjianshou_3 = {cc.p(0.52, 0.38), false, 1},
    --
    qibing_1 = {cc.p(0.4, 0.36), false, 1},
    qibing_2 = {cc.p(0.4, 0.36), false, 1},
    qibing_3 = {cc.p(0.4, 0.38), false, 1},
    --
    toushiche = {cc.p(0.39, 0.43), false, 1},
    toushiche_2 = {cc.p(0.39, 0.45), false, 1},
    toushiche_3 = {cc.p(0.37, 0.44), false, 1},
    --
    shaobing_1 = {cc.p(0.45, 0.3), false, 1},
    shaobing_2 = {cc.p(0.45, 0.3), false, 1},
    shaobing_3 = {cc.p(0.47, 0.33), false, 1},
    --
    nugongshou_1 = {cc.p(0.46, 0.4), false, 1},
    nugongshou_2 = {cc.p(0.46, 0.38), false, 1},
    nugongshou_3 = {cc.p(0.3, 0.4), false, 1},
    --
    youqibing_1 = {cc.p(0.48, 0.38), false, 1},
    youqibing_2 = {cc.p(0.48, 0.38), false, 1},
    youqibing_3 = {cc.p(0.48, 0.38), false, 1},
    --
    nuche_1 = {cc.p(0.5, 0.45), false, 1},
    nuche_2 = {cc.p(0.5, 0.45), false, 1},
    nuche_3 = {cc.p(0.49, 0.45), false, 1},

    -- 特殊兵种
    kulouyongshi = {cc.p(0.46, 0.44), false, 1},
    kulousheshou = {cc.p(0.26, 0.46), false, 1},
    siwangqishi = {cc.p(0.4, 0.38), false, 1},
    jiaorouche = {cc.p(0.345, 0.48), false, 1},
}

local function createAniWithConfig(ani, config, default_animation)
    local ap,flip,s,shadow = unpack(config)
    local sprite = ccs.Armature:create(ani)
    sprite:setScaleX(flip and -s or s)
    sprite:setScaleY(s)
    sprite:setAnchorPoint(ap)
    sprite:getAnimation():play(default_animation)
    if shadow then
        display.newSprite("tmp_soldier_shadow.png")
            :addTo(sprite):setAnchorPoint(cc.p(0.25,0.45))
    end
    return sprite
end
function UIKit:CreateIdle45Ani(ani)
    return createAniWithConfig(ani, soldier_animap[ani], "idle_45")
end
function UIKit:CreateDragonFly45Ani(ani)
    return createAniWithConfig(ani, dragon_fly_45_ani[ani], "flying_45")
end
function UIKit:CreateDragonFlyNeg45Ani(ani)
    return createAniWithConfig(ani, dragon_fly_neg_45_ani[ani], "flying_-45")
end
function UIKit:CreateSoldierMove45Ani(ani)
    return createAniWithConfig(ani, soldier_move_45_ani[ani], "move_45")
end
function UIKit:CreateSoldierMoveNeg45Ani(ani)
    return createAniWithConfig(ani, soldier_move_neg_45_ani[ani], "move_-45")
end
function UIKit:GetSoldierMoveAniConfig(ani, act)
    if act == "move_45" then
        return soldier_move_45_ani[ani]
    elseif act == "move_-45" then
        return soldier_move_neg_45_ani[ani]
    else
        assert(false)
    end
end
function UIKit:CreateNameBanner(name, dragon_type)
    local node = display.newNode()
    local size = self:ttfLabel({
        text = name,
        color = 0xfffab9,
        size = 18,
    }):addTo(node, 1):align(display.CENTER):getContentSize()
    display.newSprite("arrow_green_22x32.png"
        , nil, nil, {class=cc.FilteredSpriteWithOne})
        :addTo(node)
        :setScale(size.width / 22 * 1.3, size.height/32 * 1.01)
        :setFilter(filter.newFilter("CUSTOM",
            json.encode({
                frag = "shaders/banner.fs",
                shaderName = "banner",
            })
        ))
    local dragon_bg = display.newSprite("dragon_bg_114x114.png")
        :addTo(node, 2):scale(0.3):pos(-size.width/2-20, 0)
    display.newSprite(UILib.dragon_head[dragon_type or "redDragon"])
        :align(display.CENTER, dragon_bg:getContentSize().width/2, dragon_bg:getContentSize().height/2+5)
        :addTo(dragon_bg)
    return node
end









