local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UIListView = import("..ui.UIListView")
local GameUIToolShopSpeedUp = import("..ui.GameUIToolShopSpeedUp")
local MaterialManager = import("..entity.MaterialManager")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetNeedBox = import("..widget.WidgetNeedBox")
local WidgetTimerProgressStyleThree = import("..widget.WidgetTimerProgressStyleThree")
local WidgetManufacture = class("WidgetManufacture", function()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)

local timer = app.timer

function WidgetManufacture:OnBeginMakeMaterialsWithEvent(tool_shop, event)
    self:UpdateEvent(event)
    self:UpdateNeedStatus()
    app:GetAudioManager():PlayeEffectSoundWithKey("UI_TOOLSHOP_CRAFT_START")
    self:performWithDelay(function()
        tool_shop:IteratorEvents(function(k,v)
            self:UpdateEvent(v)
        end)
    end, 0)
end
function WidgetManufacture:OnMakingMaterialsWithEvent(tool_shop, event, current_time)
    self:UpdateEvent(event)
end
function WidgetManufacture:OnEndMakeMaterialsWithEvent(tool_shop, event, current_time)
    self:UpdateEvent(event)
    self:UpdateNeedStatus()
end
function WidgetManufacture:OnGetMaterialsWithEvent(tool_shop, event)
    self:UpdateEvent(event)
end
function WidgetManufacture:OnMaterialsChanged(material_manager, material_type, changed)
    if MaterialManager.MATERIAL_TYPE.BUILD == material_type then
        self.building_item:SetStoreMaterials(LuaUtils:table_map(changed, function(k, v)
            return k, v.new
        end))
    elseif MaterialManager.MATERIAL_TYPE.TECHNOLOGY == material_type then
        self.technology_event:SetStoreMaterials(LuaUtils:table_map(changed, function(k, v)
            return k, v.new
        end))
    end
end
--

local MATERIALS_MAP = {
    blueprints = { "blueprints_128x128.png",  _("建筑图纸"), 1},
    tools = { "tools_128x128.png",  _("建筑工具"), 2},
    tiles = { "tiles_128x128.png",  _("砖石瓦片"), 3},
    pulley = { "pulley_128x128.png",  _("滑轮组"), 4},
    trainingFigure = { "trainingFigure_128x128.png",  _("木人桩"), 1},
    bowTarget = { "bowTarget_128x128.png", _("箭靶"), 2},
    saddle = { "saddle_128x128.png",  _("马鞍"), 3},
    ironPart = { "ironPart_128x128.png",  _("精铁零件"), 4},
}
function WidgetManufacture:ctor(toolShop)
    self.toolShop = toolShop
end
function WidgetManufacture:onEnter()
    self:Manufacture()
    self.toolShop:AddToolShopListener(self)
    self.toolShop:BelongCity():GetMaterialManager():AddObserver(self)
end
function WidgetManufacture:onExit()
    self.toolShop:RemoveToolShopListener(self)
    self.toolShop:BelongCity():GetMaterialManager():RemoveObserver(self)
end
function WidgetManufacture:CreateVerticalListView(...)
    return self:CreateVerticalListViewDetached(...):addTo(self)
end
function WidgetManufacture:CreateVerticalListViewDetached(left_bottom_x, left_bottom_y, right_top_x, right_top_y)
    local width, height = right_top_x - left_bottom_x, right_top_y - left_bottom_y
    return UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a000000),
        viewRect = cc.rect(left_bottom_x, left_bottom_y, width, height),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }
end
function WidgetManufacture:Manufacture()
    local material_manager = self.toolShop:BelongCity():GetMaterialManager()
    local materials = material_manager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)

    self.list_view = self:CreateVerticalListView(window.left + 20, window.bottom + 90, window.right - 20, window.top - 80)
    local item = self:CreateMaterialItemWithListView(self.list_view,
        _("生产建筑所需材料"),
        {
            "blueprints",
            "tools",
            "tiles",
            "pulley",
        })
    self.list_view:addItem(item)
    item:GetNeedBox():SetClicked(function()
        local resource_manager = self.toolShop:BelongCity():GetResourceManager()
        local time = timer:GetServerTime()
        local wood_cur = resource_manager:GetWoodResource():GetResourceValueByCurrentTime(time)
        local stone_cur = resource_manager:GetStoneResource():GetResourceValueByCurrentTime(time)
        local iron_cur = resource_manager:GetIronResource():GetResourceValueByCurrentTime(time)
        local count, wood, stone, iron, time = self.toolShop:GetNeedByCategory("building")
        dump({
            wood = wood,
            stone = stone,
            iron = iron,
        })
        dump({
            wood = wood_cur,
            stone = stone_cur,
            iron = iron_cur,
        })
        local need_gems, total_buy = DataUtils:buyResource({
            wood = wood,
            stone = stone,
            iron = iron,
        }, {
            wood = wood_cur,
            stone = stone_cur,
            iron = iron_cur,
        })
        dump(total_buy)
        if need_gems > 0 then
            UIKit:showMessageDialog(_("提示"), "资源不足!")
                :CreateOKButtonWithPrice(
                    {
                        listener = function()
                            if need_gems > User:GetGemResource():GetValue() then
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
                                NetManager:getMakeBuildingMaterialPromise()
                            end
                        end,
                        btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                        price = need_gems
                    }
                ):CreateCancelButton()
        else
            NetManager:getMakeBuildingMaterialPromise()
        end
    end)
    item:GetMaterial():SetClicked(function()
        local content = self.toolShop:GetBuildingEvent():Content()
        if self:CheckOverFlow(content) then
            self:CreateFetchDialog(function()
                self:FetchBuildMaterials(content)
            end, _("当前材料库房中的建筑材料已满，你可能无法获得这些材料。是否仍要获取？"))
        else
            self:FetchBuildMaterials(content)
        end
    end)
    item:SetStoreMaterials(materials)

    item:UpdateByEvent(self.toolShop:GetMakeMaterialsEventByCategory("building"))
    self.building_item = item


    local materials = material_manager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.TECHNOLOGY)
    local item = self:CreateMaterialItemWithListView(self.list_view,
        _("军事科技所需材料"),
        {
            "trainingFigure",
            "bowTarget",
            "saddle",
            "ironPart",
        })
    self.list_view:addItem(item)
    item:GetNeedBox():SetClicked(function()
        local resource_manager = self.toolShop:BelongCity():GetResourceManager()
        local time = timer:GetServerTime()
        local wood_cur = resource_manager:GetWoodResource():GetResourceValueByCurrentTime(time)
        local stone_cur = resource_manager:GetStoneResource():GetResourceValueByCurrentTime(time)
        local iron_cur = resource_manager:GetIronResource():GetResourceValueByCurrentTime(time)
        local count, wood, stone, iron, time = self.toolShop:GetNeedByCategory("technology")
        local need_gems = DataUtils:buyResource({
            wood = wood,
            stone = stone,
            iron = iron,
        }, {
            wood = wood_cur,
            stone = stone_cur,
            iron = iron_cur,
        })
        if need_gems > 0 then
            UIKit:showMessageDialog(_("提示"), "资源不足!")
                :CreateOKButtonWithPrice(
                    {
                        listener = function()
                            if need_gems > User:GetGemResource():GetValue() then
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
                                NetManager:getMakeTechnologyMaterialPromise()
                            end
                        end,
                        btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                        price = need_gems
                    }
                ):CreateCancelButton()
        else
            NetManager:getMakeTechnologyMaterialPromise()
        end
    end)
    item:GetMaterial():SetClicked(function()
        local content = self.toolShop:GetTechnologyEvent():Content()
        if self:CheckOverFlow(content) then
            self:CreateFetchDialog(function()
                self:FetchTechnologyMaterials(content)
            end, _("当前材料库房中的科技材料已满，你可能无法获得这些材料。是否仍要获取？"))
        else
            self:FetchTechnologyMaterials(content)
        end
    end)
    item:SetStoreMaterials(materials)

    item:UpdateByEvent(self.toolShop:GetMakeMaterialsEventByCategory("technology"))
    self.technology_event = item

    self.list_view:reload()
end
function WidgetManufacture:FetchBuildMaterials(content)
    NetManager:getFetchMaterialsPromise(self.toolShop:GetBuildingEvent():Id()):done(function()
        local desc_t = {}
        for i,v in ipairs(content) do
            table.insert(desc_t, string.format("%sx%d", Localize.materials[v.name], v.count))
        end
        GameGlobalUI:showTips(_("获取建筑材料"), table.concat(desc_t, ", "))
    end)
end
function WidgetManufacture:FetchTechnologyMaterials(content)
    NetManager:getFetchMaterialsPromise(self.toolShop:GetTechnologyEvent():Id()):done(function()
        local desc_t = {}
        for i,v in ipairs(content) do
            table.insert(desc_t, string.format("%sx%d", Localize.materials[v.name], v.count))
        end
        GameGlobalUI:showTips(_("获取科技材料"), table.concat(desc_t, ", "))
    end)
end
function WidgetManufacture:IsQueueEmpty()
    local current_time = app.timer:GetServerTime()
    for _, event in pairs(self.toolShop:GetMakeMaterialsEvents()) do
        if event:IsMaking(current_time) then
            return false
        end
    end
    return true
end
function WidgetManufacture:UpdateEvent(event)
    if event:Category() == "building" then
        self.building_item:UpdateByEvent(event)
    elseif event:Category() == "technology" then
        self.technology_event:UpdateByEvent(event)
    end
end
function WidgetManufacture:UpdateNeedStatus()
    self.building_item:GetNeedBox():GetNormalButton()
        :setButtonEnabled(self:IsQueueEmpty())
    self.technology_event:GetNeedBox():GetNormalButton()
        :setButtonEnabled(self:IsQueueEmpty())
end
function WidgetManufacture:CreateMaterialItemWithListView(list_view, title, materials)
    local toolShop = self.toolShop
    local toolShop_ui = self
    local align_x, align_y = 30, 35
    local height = 378
    local content = WidgetUIBackGround.new({height=height,isFrame="yes"}):align(display.CENTER)

    local size = content:getContentSize()
    local title_blue = cc.ui.UIImage.new("title_blue_586x34.png",
        {scale9 = true})
        :addTo(content, 2)
        :align(display.CENTER, size.width / 2, height - 40)

    -- title_blue:setVisible(false)
    UIKit:ttfLabel({
        text = title,
        size = 22,
        color = 0xffedae
    }):addTo(title_blue):align(display.CENTER, title_blue:getContentSize().width/2, title_blue:getContentSize().height/2)

    local function new_material(type)
        local origin_x, origin_y, gap_x = 90, height - 160, 143
        local png = MATERIALS_MAP[type][1]
        local describe = MATERIALS_MAP[type][2]
        local index = MATERIALS_MAP[type][3]

        local back_ground = WidgetUIBackGround.new({width = 120,height = 154},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
            :align(display.CENTER, origin_x + gap_x * (index - 1), origin_y)

        local pos = back_ground:getAnchorPointInPoints()

        local icon_bg = cc.ui.UIImage.new("box_118x118.png")
            :align(display.CENTER, pos.x, pos.y+18)
            :addTo(back_ground)
        local material = cc.ui.UIImage.new(png)
            :addTo(icon_bg)
            :align(display.CENTER, icon_bg:getContentSize().width/2,icon_bg:getContentSize().height/2)
            :scale(100/128)

        local num_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64))
            :addTo(back_ground):align(display.CENTER,pos.x, 20)

        local store_label = UIKit:ttfLabel({
            text = "",
            size = 20,
            color = 0x403c2f
        }):addTo(num_bg)
            :align(display.CENTER, num_bg:getContentSize().width / 2, num_bg:getContentSize().height / 2)


        local name_label = cc.ui.UILabel.new({
            text = describe,
            size = 18,
            font = UIKit:getFontFilePath(),
            align = cc.ui.TEXT_ALIGN_RIGHT,
            color = UIKit:hex2c3b(0x403c2f)
        }):addTo(back_ground, 2)
            :align(display.CENTER, pos.x, pos.y + 88)

        local num_label = UIKit:ttfLabel({
            text = "",
            size = 20,
            color = 0x007c23
        }):addTo(num_bg)
            :align(display.LEFT_CENTER, 0,num_bg:getContentSize().height / 2)
            :hide()
        function back_ground:SetStoreNumber(number)
            store_label:setString(number)
            return self
        end
        function back_ground:ShowNumber(number)
            num_label:show()
            num_label:setString(number == nil and "" or ("+"..number))
            if number then
                local margin_x =5
                local width = store_label:getContentSize().width + num_label:getContentSize().width
                store_label:setPositionX(num_bg:getContentSize().width/2-width/2)
                store_label:align(display.LEFT_CENTER)
                num_label:setPositionX(store_label:getPositionX()+store_label:getContentSize().width+margin_x)
            else
                store_label:align(display.CENTER, num_bg:getContentSize().width / 2, num_bg:getContentSize().height / 2)
            end
            return self
        end
        function back_ground:Reset()
            num_label:hide()
            store_label:align(display.CENTER, num_bg:getContentSize().width / 2, num_bg:getContentSize().height / 2)
            return self
        end
        function back_ground:Index()
            return index
        end

        return back_ground
    end


    local materials_map = {}
    for i, v in ipairs(materials) do
        materials_map[v] = new_material(v):addTo(content, 2):Reset()
    end


    local function new_need_box()
        local need_box = WidgetNeedBox.new()

        local contetn_size = need_box:getCascadeBoundingBox()
        local width = contetn_size.width
        local height = contetn_size.height

        local describe = cc.ui.UILabel.new({
            text = _("随机制造10个材料"),
            size = 22,
            font = UIKit:getFontFilePath(),
            align = cc.ui.TEXT_ALIGN_RIGHT,
            color = UIKit:hex2c3b(0x403c2f)
        }):addTo(need_box, 2)
            :align(display.LEFT_CENTER, 0, -22)

        local button = WidgetPushButton.new(
            {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
            {scale9 = false},
            {
                disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
            }
        ):addTo(need_box, 2)
            :align(display.CENTER, width-74 , -30)
            :setButtonLabel(cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = _("生产"),
                size = 24,
                font = UIKit:getFontFilePath(),
                color = UIKit:hex2c3b(0xfff3c7)}))


        function need_box:Update(category)
            local resource_manager = toolShop:BelongCity():GetResourceManager()
            local time = timer:GetServerTime()
            local wood_cur = resource_manager:GetWoodResource():GetResourceValueByCurrentTime(time)
            local stone_cur = resource_manager:GetStoneResource():GetResourceValueByCurrentTime(time)
            local iron_cur = resource_manager:GetIronResource():GetResourceValueByCurrentTime(time)
            local number, wood, stone, iron, time = toolShop:GetNeedByCategory(category)
            describe:setString( string.format(_("随机制造%d个材料"), number) )
            self:SetNeedNumber({wood_cur, wood}, {stone_cur, stone}, {iron_cur, iron}, time)
            return self
        end
        function need_box:GetNormalButton()
            return button
        end
        function need_box:SetClicked(func)
            button:onButtonClicked(function(event)
                func()
            end)
            return self
        end
        return need_box
    end


    local function new_get_material()
        local height = 48
        local material = display.newNode()
        local describe = cc.ui.UILabel.new({
            text = _("制造材料完成"),
            size = 22,
            font = UIKit:getFontFilePath(),
            align = cc.ui.TEXT_ALIGN_RIGHT,
            color = UIKit:hex2c3b(0x403c2f)
        }):addTo(material, 2):align(display.LEFT_CENTER, 10, height)

        local button = WidgetPushButton.new(
            {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
            {scale9 = false}
        ):setButtonLabel(cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("获得"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xfff3c7)}))
            :addTo(material, 2):align(display.CENTER, 351 + 120, height)

        function material:SetNumber(number)
            describe:setString(string.format( _("制造材料x%d 完成!"), number ) )
            return self
        end
        function material:SetClicked(func)
            button:onButtonClicked(function(event)
                func()
            end)
            return self
        end
        return material
    end

    local back_ground_351x96 = new_need_box():addTo(content, 2):pos(align_x, align_y+40):hide()
    local progress_box = WidgetTimerProgressStyleThree.new()
        :addTo(content, 2)
        :pos(size.width/2, 110)
        :hide()
        :OnButtonClicked(function(event)
            UIKit:newGameUI("GameUIToolShopSpeedUp", self.toolShop):AddToCurrentScene(true)
        end)

    local get_material = new_get_material():addTo(content, 2):pos(align_x, align_y):hide()

    local item = list_view:newItem()
    function item:UpdateByEvent(event)
        local server_time = app.timer:GetServerTime()
        if event:IsEmpty() then
            self:ResetGetMaterials()

            self:GetNeedBox()
                :show()
                :Update(event:Category())
                :GetNormalButton()
                :setButtonEnabled(toolShop_ui:IsQueueEmpty())

            self:GetProgressBox():hide()
            self:GetMaterial():hide()
        elseif event:IsMaking(server_time) then
            local number = toolShop:GetNeedByCategory(event:Category())
            local elapse_time = event:ElapseTime(server_time)
            local total_time = event:FinishTime() - event:StartTime()
            local percent = elapse_time * 100.0 / total_time

            self:GetProgressBox():show()
                :SetDescribe(string.format(_("制造材料 x%d"), number))
                :SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(server_time)), percent)

            self:GetMaterial():hide()
            self:GetNeedBox():hide()
        elseif event:IsStored(server_time) then
            self:SetGetMaterials(event:Content())
            printLog("sss","%s",".."..event:TotalCount())
            self:GetMaterial():show():SetNumber(event:TotalCount())

            self:GetProgressBox():hide()
            self:GetNeedBox():hide()
        end
        return self
    end
    function item:GetNeedBox()
        return back_ground_351x96
    end
    function item:GetProgressBox()
        return progress_box
    end
    function item:GetMaterial()
        return get_material
    end
    function item:SetStoreMaterials(materials)
        for k, v in pairs(materials) do
            local ui = materials_map[k]
            if ui then
                ui:SetStoreNumber(v)
            end
        end
    end
    function item:SetGetMaterials(materials)
        local get_material = LuaUtils:table_map(materials, function(k, v)
            return v.name, v.count
        end)
        for k, v in pairs(materials_map) do
            v:ShowNumber(get_material[k])
        end
    end
    function item:ResetGetMaterials()
        for k, v in pairs(materials_map) do
            v:Reset()
        end
    end

    item:addContent(content)
    item:setItemSize(549, height + 10)
    return item
end
function WidgetManufacture:CheckOverFlow(content)
    local limit = self.toolShop:BelongCity():GetFirstBuildingByType("materialDepot"):GetMaxMaterial()
    local mm = City:GetMaterialManager():GetMaterialsByType(City:GetMaterialManager().MATERIAL_TYPE.TECHNOLOGY)
    for k,v in pairs(City:GetMaterialManager():GetMaterialsByType(City:GetMaterialManager().MATERIAL_TYPE.BUILD)) do
        mm[k] = v
    end
    local overflows = {}
    for _,v in ipairs(content) do
        if mm[v.name] + v.count > limit then
            overflows[v.name] = true
        end
    end
    return next(overflows)
end
function WidgetManufacture:CreateFetchDialog(func,text)
    local dialog = UIKit:showMessageDialogWithParams({
        title = _("提示"),
        content = text,
        ok_callback = func,
        ok_btn_images = {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
        ok_string = _("强行获取"),
        cancel_callback = function () end,
        cancel_btn_images = {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
    })
end


return WidgetManufacture









