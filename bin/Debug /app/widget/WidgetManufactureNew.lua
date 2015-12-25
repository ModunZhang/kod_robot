local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetProgress = import("..widget.WidgetProgress")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetMaterialBox = import("..widget.WidgetMaterialBox")
local WidgetTimerProgress = import("..widget.WidgetTimerProgress")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")
local WidgetTimerProgressStyleThree = import("..widget.WidgetTimerProgressStyleThree")
local WidgetManufactureNew = class("WidgetManufactureNew", function()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)
local timer = app.timer


local function newProgress()
    local node = display.newNode()
    node.describe = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):addTo(node):align(display.LEFT_CENTER, -275, 28)

    node.progress = WidgetProgress.new(nil,nil,nil,{label_size = 20}):addTo(node)
        :align(display.LEFT_CENTER, -255, -15)

    node.btn = cc.ui.UIPushButton.new({
        normal = "green_btn_up_148x76.png",
        pressed = "green_btn_down_148x76.png",
    }, {scale9 = false}):setButtonLabel(UIKit:ttfLabel({
        text = _("加速"),
        size = 24,
        color = 0xffedae,
        shadow = true,
    })):addTo(node):pos(200,0)

    return node
end


function WidgetManufactureNew:ctor(toolShop,sub_tab)
    self.toolShop = toolShop
    self.sub_tab = sub_tab
end
--
function WidgetManufactureNew:onEnter()
    self.view = display.newNode():addTo(self)
    self.material_tab = WidgetRoundTabButtons.new({
        {tag = "buildingMaterials",label = _("建筑材料")},
        {tag = "technologyMaterials",label = _("军事材料")},
    }, function(tag)
        self:Reload(tag)
    end):align(display.TOP_CENTER,window.cx,window.top-84):addTo(self)

    local User = self.toolShop:BelongCity():GetUser()
    if self.sub_tab then
        self.material_tab:SelectTab(self.sub_tab )
    else
        local making_event = User:GetMakingMaterialsEvent()
        local store_event = User:GetStoreMaterialsEvent()
        if making_event then
            self.material_tab:SelectTab(making_event.type)
        elseif store_event then
            self.material_tab:SelectTab(store_event.type)
        else
            self.material_tab:SelectTab("buildingMaterials")
        end
    end
    User:AddListenOnType(self, "buildingMaterials")
    User:AddListenOnType(self, "technologyMaterials")
    User:AddListenOnType(self, "materialEvents")
    scheduleAt(self, function()
        self:UpdateCurrentEvent()
    end)
end
function WidgetManufactureNew:onExit()
    local User = self.toolShop:BelongCity():GetUser()
    User:RemoveListenerOnType(self, "buildingMaterials")
    User:RemoveListenerOnType(self, "technologyMaterials")
    User:RemoveListenerOnType(self, "materialEvents")
end
function WidgetManufactureNew:OnUserDataChanged_materialEvents(userData, deltaData)
    local ok, value = deltaData("materialEvents.add")
    if ok then
        app:GetAudioManager():PlayeEffectSoundWithKey("UI_TOOLSHOP_CRAFT_START")
    end
    self:RefreshRequirements(self.material_tab:GetSelectedButtonTag())
    self:UpdateCurrentEvent()
end
function WidgetManufactureNew:OnUserDataChanged_buildingMaterials(userData, deltaData)
    local ok, value = deltaData("buildingMaterials")
    if ok then
        for k,v in pairs(value) do
            if self.material_map[k] then
                self.material_map[k]:SetNumber(v)
            end
        end
    end
end
function WidgetManufactureNew:OnUserDataChanged_technologyMaterials(userData, deltaData)
    local ok, value = deltaData("technologyMaterials")
    if ok then
        for k,v in pairs(value) do
            if self.material_map[k] then
                self.material_map[k]:SetNumber(v)
            end
        end
    end
end
--
function WidgetManufactureNew:Reload(tag)
    if tag == "buildingMaterials" then
        self:ReloadMaterials({
            "blueprints",
            "tools",
            "tiles" ,
            "pulley" ,
        }, self.toolShop:BelongCity():GetUser().buildingMaterials)
    elseif tag == "technologyMaterials" then
        self:ReloadMaterials({
            "trainingFigure",
            "bowTarget",
            "saddle",
            "ironPart",
        }, self.toolShop:BelongCity():GetUser().technologyMaterials)
    else
        assert(false)
    end
    self:RefreshRequirements(tag)
end
function WidgetManufactureNew:ReloadMaterials(materials, materials_map)
    self.view:removeAllChildren()
    self.material_map = {}
    for i,v in ipairs(materials) do
        local x, y = window.left + (i-1) * 142 + 42, window.top - 380
        local title = display.newScale9Sprite("back_ground_96x30.png", nil, nil, cc.size(120, 30))
            :addTo(self.view):pos(x + 66, y + 190)
        local point = title:getAnchorPointInPoints()
        UIKit:ttfLabel({
            text = Localize.materials[v],
            size = 20,
            color = 0xffedae
        }):addTo(title, 10):align(display.CENTER, point.x, point.y)

        self.material_map[v] = WidgetMaterialBox.new("buildingMaterials", v)
            :addTo(self.view):pos(x, y):SetNumber(materials_map[v])
        self.material_map[v]:GetButton():removeEventListenersByEvent("PRESSED_EVENT")
        self.material_map[v]:GetButton():removeEventListenersByEvent("RELEASE_EVENT")
    end


    self.build_node = display.newNode():addTo(self.view)
        :pos(window.cx, window.top - 450)
    self.build_node.build_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):addTo(self.build_node):align(display.LEFT_CENTER, -275, 20)
    display.newSprite("hourglass_30x38.png"):addTo(self.build_node):pos(-265, -15):scale(0.8)
    self.build_node.build_time = UIKit:ttfLabel({
        text = "00:00:00",
        size = 20,
        color = 0x403c2f,
    }):addTo(self.build_node):align(display.LEFT_CENTER, -250, -15)
    self.build_node.buff_time = UIKit:ttfLabel({
        text = "(-00:00:00)",
        size = 20,
        color = 0x068329,
    }):addTo(self.build_node):align(display.LEFT_CENTER, -250 + 75, -15)
    self.build_node.build_btn = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams={text = _("生产")},
            listener = function ()
                local User = self.toolShop:BelongCity():GetUser()
                local wood_cur = User:GetResValueByType("wood")
                local stone_cur = User:GetResValueByType("stone")
                local iron_cur = User:GetResValueByType("iron")
                local count, wood, stone, iron, time
                if self.material_tab:GetSelectedButtonTag() == "buildingMaterials" then
                    count, wood, stone, iron, time = self.toolShop:GetNeedByCategory("buildingMaterials")
                else
                    count, wood, stone, iron, time = self.toolShop:GetNeedByCategory("technologyMaterials")
                end
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
                                    if need_gems > User:GetGemValue() then
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
                                        self:BuildMaterial()
                                    end
                                end,
                                btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                                price = need_gems
                            }
                        ):CreateCancelButton()
                else
                    self:BuildMaterial()
                end
            end,
        }
    ):pos(180,0):addTo(self.build_node).button


    self.progress_node = display.newNode():addTo(self.view)
        :pos(window.cx, window.top - 450):hide()
    self.progress_node.progress = newProgress():addTo(self.progress_node)
    self.progress_node.progress.btn:onButtonClicked(function()
        UIKit:newGameUI("GameUIToolShopSpeedUp", self.toolShop):AddToCurrentScene(true)
    end)


    self.get_node = display.newNode():addTo(self.view)
        :pos(window.cx, window.top - 450):hide()
    UIKit:ttfLabel({
        text = _("制造材料完成!"),
        size = 20,
        color = 0x403c2f,
    }):addTo(self.get_node):align(display.LEFT_CENTER, -275, 0)
    self.get_node.get_btn = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams={text = _("获得")},
            listener = function ()
                local event_name = self.material_tab:GetSelectedButtonTag()
                local event = User:GetStoreMaterialsEvent(event_name)
                if event then
                    if self:CheckOverFlow(event.materials) then
                        self:CreateFetchDialog(function()
                            self:FetchMaterials(event)
                        end, _("当前材料库房中的材料已满，你可能无法获得这些材料。是否仍要获取？"))
                    else
                        self:FetchMaterials(event)
                    end
                end
            end,
        }
    ):pos(180,0):addTo(self.get_node)


    self.require_list = WidgetRequirementListview.new({
        title = _("所需资源"),
        height = 158,
        contents = {
            {
                resource_type = _("木材"),
                isVisible = true,
                isSatisfy = false,
                icon = "res_wood_82x73.png",
                description = "1000/1000"
            },
            {
                resource_type = _("石料"),
                isVisible = true,
                isSatisfy = false,
                icon = "res_stone_88x82.png",
                description = "1000/1000"
            },
            {
                resource_type = _("铁矿"),
                isVisible = true,
                isSatisfy = true,
                icon = "res_iron_91x63.png",
                description = "1000/1000"
            }
        },
    }):addTo(self.view):pos(window.cx-274, window.top - 730)

    self:UpdateCurrentEvent()
end
function WidgetManufactureNew:UpdateCurrentEvent()
    local event_name = self.material_tab:GetSelectedButtonTag()
    self:UpdateByEvent(User:GetMakingMaterialsEvent(event_name) 
        or User:GetStoreMaterialsEvent(event_name))
end
function WidgetManufactureNew:UpdateByEvent(event)
    local server_time = timer:GetServerTime()
    if not event then
        local User = self.toolShop:BelongCity():GetUser()
        self.build_node:show()
        self.build_node.build_btn:setButtonEnabled(User:CanMakeMaterials())
        self.progress_node:hide()
        self.get_node:hide()
        self:CleanStoreNumbers()
        local number, wood, stone, iron, time = self.toolShop:GetNeedByCategory(self.material_tab:GetSelectedButtonTag())
        self.build_node.build_label:setString(string.format(_("随机制造%d个材料"), number))
        self.build_node.build_time:setString(GameUtils:formatTimeStyle1(time))
        local size = self.build_node.build_time:getContentSize()
        local tech = User.productionTechs["sketching"]
        local tech_effect = UtilsForTech:GetEffect("sketching", tech)
        self.build_node.buff_time:setString(string.format("(-%s)", GameUtils:formatTimeStyle1(math.ceil(time * tech_effect))))
        self.build_node.buff_time:setPositionX(self.build_node.build_time:getPositionX() + 90)
    elseif event.finishTime == 0 then
        self.build_node:hide()
        self.progress_node:hide()
        self.get_node:show()
        for i,v in ipairs(event.materials) do
            if self.material_map[v.name] then
                self.material_map[v.name]:SetSecondNumber(string.format("+%d", v.count))
            end
        end
    elseif event.finishTime ~= 0 then
        self.build_node:hide()
        self.progress_node:show()
        self.get_node:hide()
        local number = self.toolShop:GetNeedByCategory(event.type)
        local time, percent = UtilsForEvent:GetEventInfo(event)
        local prog = self.progress_node.progress
        prog.describe:setString(string.format(_("制造材料 x%d"), number))
        prog.progress:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end
end
function WidgetManufactureNew:CleanStoreNumbers()
    for k,v in pairs(self.material_map) do
        v:SetSecondNumber()
    end
end
function WidgetManufactureNew:RefreshRequirements(category)
    local _, wood, stone, iron, time = self.toolShop:GetNeedByCategory(category)
    self:RefreshRequirementList(wood, stone, iron, time)
end
function WidgetManufactureNew:RefreshRequirementList(wood, stone, iron, time)
    local User = self.toolShop:BelongCity():GetUser()
    local wood_cur = User:GetResValueByType("wood")
    local stone_cur = User:GetResValueByType("stone")
    local iron_cur = User:GetResValueByType("iron")
    self.require_list:RefreshListView({
        {
            resource_type = _("木材"),
            isVisible = true,
            isSatisfy = wood_cur >= wood,
            icon = "res_wood_82x73.png",
            description = wood_cur.."/"..wood,
        },
        {
            resource_type = _("石料"),
            isVisible = true,
            isSatisfy = stone_cur >= stone,
            icon = "res_stone_88x82.png",
            description = stone_cur.."/"..stone
        },
        {
            resource_type = _("铁矿"),
            isVisible = true,
            isSatisfy = iron_cur >= iron,
            icon = "res_iron_91x63.png",
            description = iron_cur.."/"..iron
        }
    })
end
function WidgetManufactureNew:CreateFetchDialog(func,text)
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
function WidgetManufactureNew:CheckOverFlow(content)
    local city = self.toolShop:BelongCity()
    local User = city:GetUser()
    local limit = city:GetFirstBuildingByType("materialDepot"):GetMaxMaterial()
    local mm = User.technologyMaterials
    for k,v in pairs(User.buildingMaterials) do
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
function WidgetManufactureNew:FetchMaterials(event)
    NetManager:getFetchMaterialsPromise(event.id):done(function()
        local desc_t = {}
        for i,v in ipairs(event.materials) do
            table.insert(desc_t, string.format("%sx%d", Localize.materials[v.name], v.count))
        end
        if event.type == "buildingMaterials" then
            GameGlobalUI:showTips(_("获取建筑材料"), table.concat(desc_t, ", "))
        else
            GameGlobalUI:showTips(_("获取科技材料"), table.concat(desc_t, ", "))
        end
    end)
end
function WidgetManufactureNew:BuildMaterial()
    if self.material_tab:GetSelectedButtonTag() == "buildingMaterials" then
        NetManager:getMakeBuildingMaterialPromise():done(function()
            self:RefreshRequirements("buildingMaterials")
        end)
    else
        NetManager:getMakeTechnologyMaterialPromise():done(function()
            self:RefreshRequirements("technologyMaterials")
        end)
    end
end


return WidgetManufactureNew










