--
-- Author: Danny He
-- Date: 2014-09-13 10:30:04
--
local GameUIResource = UIKit:createUIClass("GameUIResource","GameUIUpgradeBuilding")
local ResourceManager = import("..entity.ResourceManager")
local WidgetInfoWithTitle = import("..widget.WidgetInfoWithTitle")
local WidgetMoveHouse = import("..widget.WidgetMoveHouse")
local UILib = import(".UILib")
local UIListView = import(".UIListView")
local window = import("..utils.window")
function GameUIResource:ctor(city, building, default_tab)
    GameUIResource.super.ctor(self, city, self:GetTitleByType(building),building,default_tab)
    self.building = building
    self.dataSource = self:GetDataSource()
end


function GameUIResource:onEnter()
    GameUIResource.super.onEnter(self)
end
function GameUIResource:CreateUI()
    self:createTabButtons()
end

function GameUIResource:createTabButtons()
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "infomation",
        }
    },
    function(tag)
        if tag == 'infomation' then
            if not self.infomationLayer then
                self:CreateInfomation()
            end
            self:RefreshListView()
        else
            if self.infomationLayer then
                self.infomationLayer:removeFromParent()
                self.infomationLayer = nil
            end
        end
    end):pos(window.cx, window.bottom + 34)
end


function GameUIResource:CreateInfomation()
    local infomationLayer = display.newNode():addTo(self:GetView())
    self.infomationLayer = infomationLayer
    local iconBg = display.newSprite("box_118x118.png")
        :align(display.LEFT_TOP, window.left+40, window.top - 100)
        :addTo(infomationLayer)
    display.newSprite(UILib.item.torch)
        :align(display.CENTER, iconBg:getContentSize().width/2, iconBg:getContentSize().height/2):
        addTo(iconBg)
    local lvBg = display.newSprite("back_ground_102x30.png")
        :align(display.LEFT_TOP, window.left+48, iconBg:getPositionY()-iconBg:getContentSize().height+36)
        :addTo(infomationLayer)
    local lvLabel = UIKit:ttfLabel({
        text = _("拥有").." "..ItemManager:GetItemByName("torch"):Count(),
        size = 18,
        color = 0xffedae,
    }):addTo(lvBg):align(display.CENTER,lvBg:getContentSize().width/2,lvBg:getContentSize().height/2)

    local title_bg = display.newSprite("title_blue_430x30.png"):addTo(infomationLayer)
        :align(display.LEFT_TOP,iconBg:getPositionX()+iconBg:getContentSize().width,iconBg:getPositionY()-2)
    local titleLable = UIKit:ttfLabel({
        text = _("拆除这个建筑"),
        size = 22,
        color = 0xffedae,
    }):addTo(title_bg)
        :align(display.LEFT_CENTER,10,title_bg:getContentSize().height/2)

    local fistLine = display.newScale9Sprite("dividing_line.png",title_bg:getPositionX()+10,lvBg:getPositionY()+lvBg:getContentSize().height-15,
        cc.size(262,2),cc.rect(1,1,400,1))
        :align(display.BOTTOM_LEFT)
        :addTo(infomationLayer)

    local firstLable = UIKit:ttfLabel({
        text = _("返还城民"),
        size = 20,
        color = 0x615b44,
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
    }):addTo(infomationLayer)
        :align(display.LEFT_BOTTOM,fistLine:getPositionX(),fistLine:getPositionY()+2)
    self.firstLable = firstLable
    local firstValueLabel = UIKit:ttfLabel({
        text = "-100",
        size = 20,
        color = 0x403c2f,
    }):addTo(infomationLayer)
        :align(display.RIGHT_BOTTOM,fistLine:getPositionX()+262,firstLable:getPositionY())
    self.firstValueLabel = firstValueLabel
    local secondLine = display.newScale9Sprite("dividing_line.png",firstLable:getPositionX(),lvBg:getPositionY()-lvBg:getContentSize().height,
        cc.size(262,2),cc.rect(1,1,400,1))
        :align(display.BOTTOM_LEFT)
        :addTo(infomationLayer)

    local secondLabel = UIKit:ttfLabel({
        text = _("城民增长"),
        size = 20,
        color = 0x615b44,
    }):addTo(infomationLayer)
        :align(display.LEFT_BOTTOM,secondLine:getPositionX(),secondLine:getPositionY()+2)
    self.secondLabel = secondLabel
    self.secondValueLabel = UIKit:ttfLabel({
        text = "-100/h",
        size = 20,
        color = 0x403c2f,
    }):addTo(infomationLayer)
        :align(display.RIGHT_BOTTOM,secondLine:getPositionX()+262,secondLabel:getPositionY())

    local chaiButton =  cc.ui.UIPushButton.new()
        :addTo(infomationLayer)
        :align(display.TOP_RIGHT, window.right-50, secondLine:getPositionY()+56)
        :onButtonClicked(function(event)
            self:ChaiButtonAction(event)
        end)
    if ItemManager:GetItemByName("torch"):Count()>0 then
        chaiButton:setButtonImage(cc.ui.UIPushButton.NORMAL, "red_btn_up_148x58.png", true)
        chaiButton:setButtonImage(cc.ui.UIPushButton.PRESSED, "red_btn_down_148x58.png", true)
        chaiButton:setButtonLabel("normal", UIKit:ttfLabel({
            text = _("拆除"),
            size = 22,
            color = 0xffedae,
        }))
    else
        chaiButton:setButtonImage(cc.ui.UIPushButton.NORMAL, "green_btn_up_148x58.png", true)
        chaiButton:setButtonImage(cc.ui.UIPushButton.PRESSED, "green_btn_down_148x58.png", true)
        chaiButton:setButtonLabel("normal", UIKit:ttfLabel({
            text = _("购买&拆除"),
            size = 18,
            color = 0xffedae,
        }))
            :setButtonLabelOffset(0, 14)
        local num_bg = display.newSprite("back_ground_122x20.png"):addTo(chaiButton):align(display.CENTER, -74, -40)
        -- gem icon
        local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(num_bg):align(display.CENTER, 20, num_bg:getContentSize().height/2):scale(0.5)
        local price = UIKit:ttfLabel({
            text = string.formatnumberthousands(ItemManager:GetItemByName("torch"):Price()),
            size = 18,
            color = 0xffd200,
        }):align(display.LEFT_CENTER, 50 , num_bg:getContentSize().height/2)
            :addTo(num_bg)
    end


    -- 移动小屋
    local movingConstruction_item = ItemManager:GetItemByName("movingConstruction")
    local iconBg = display.newSprite("box_118x118.png")
        :align(display.LEFT_TOP, window.left+40, window.top - 260)
        :addTo(infomationLayer)
    display.newSprite(UILib.item.movingConstruction)
        :align(display.CENTER, iconBg:getContentSize().width/2, iconBg:getContentSize().height/2):
        addTo(iconBg)
    local lvBg = display.newSprite("back_ground_102x30.png")
        :align(display.LEFT_TOP, window.left+48, iconBg:getPositionY()-iconBg:getContentSize().height+36)
        :addTo(infomationLayer)
    local lvLabel = UIKit:ttfLabel({
        text = _("拥有").." "..movingConstruction_item:Count(),
        size = 18,
        color = 0xffedae,
    }):addTo(lvBg):align(display.CENTER,lvBg:getContentSize().width/2,lvBg:getContentSize().height/2)

    local title_bg = display.newSprite("title_blue_430x30.png"):addTo(infomationLayer)
        :align(display.LEFT_TOP,iconBg:getPositionX()+iconBg:getContentSize().width,iconBg:getPositionY()-2)
    local titleLable = UIKit:ttfLabel({
        text = _("移动这个建筑"),
        size = 22,
        color = 0xffedae,
    }):addTo(title_bg)
        :align(display.LEFT_CENTER,10,title_bg:getContentSize().height/2)


    UIKit:ttfLabel({
        text = _("用来调换城市内的资源建筑的位置"),
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(240,0)
    }):addTo(infomationLayer)
        :align(display.LEFT_CENTER,title_bg:getPositionX()+10,title_bg:getPositionY()-70)

    local moveButton =  cc.ui.UIPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}, {scale9 = false})
        :addTo(infomationLayer)
        :align(display.TOP_RIGHT, window.right-50, title_bg:getPositionY()-58)
        :onButtonClicked(function(event)
            self:MoveButtonAction(event)
        end)
    if movingConstruction_item:Count()>0 then
        moveButton:setButtonLabel("normal", UIKit:ttfLabel({
            text = _("移动"),
            size = 22,
            color = 0xffedae,
        }))
    else
        moveButton:setButtonLabel("normal", UIKit:ttfLabel({
            text = _("购买&移动"),
            size = 18,
            color = 0xffedae,
        }))
            :setButtonLabelOffset(0, 14)
        local num_bg = display.newSprite("back_ground_122x20.png"):addTo(moveButton):align(display.CENTER, -74, -40)
        -- gem icon
        local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(num_bg):align(display.CENTER, 20, num_bg:getContentSize().height/2):scale(0.5)
        local price = UIKit:ttfLabel({
            text = string.formatnumberthousands(movingConstruction_item:Price()),
            size = 18,
            color = 0xffd200,
        }):align(display.LEFT_CENTER, 50 , num_bg:getContentSize().height/2)
            :addTo(num_bg)
    end


    self.info = WidgetInfoWithTitle.new({
        title = _("总计"),
        h = 226
    }):addTo(self.infomationLayer)
        :align(display.TOP_CENTER, window.cx,secondLine:getPositionY()-240)



    self.listView = self.info:GetListView()

    local resource = self.city.resource_manager:GetResourceByType(self.building:GetUpdateResourceType())
    local citizen = self.building:GetCitizen()
    self.firstValueLabel:setString(string.format('%d',citizen))
    local __,resource_title = self:GetTitleByType(self.building)
    self.secondLabel:setString(resource_title)

    if ResourceManager.RESOURCE_TYPE.CITIZEN ==  self.building:GetUpdateResourceType() then
        self.secondValueLabel:setString(string.format("-%d",self.building:GetProductionLimit()))
        self.firstLable:setString(_("银币产量"))
        self.firstValueLabel:setString(string.format("-%d/h",self.building:GetProductionPerHour()))
    else
        local reduce = self.building:GetProductionPerHour()
        local buffMap,__ = self.city.resource_manager:GetTotalBuffData(self.city)
        local key = ResourceManager.RESOURCE_TYPE[self.building:GetUpdateResourceType()]
        if buffMap[key] then
            reduce = reduce * (1 + buffMap[key])
        end
        self.secondValueLabel:setString(string.format("-%d/h",reduce))
    end
end


function GameUIResource:GetListItem(index,title,val)
    local bgImage = string.format("back_ground_548x40_%d.png", tonumber(index-1) % 2 == 0 and 1 or 2)
    local item = self.listView:newItem()
    local bg = display.newSprite(bgImage)
    local titleLabel = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = title,
        font = UIKit:getFontFilePath(),
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x615b44),
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER})
        :addTo(bg)
        :pos(10,20)
    local valLabel = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = val,
        font = UIKit:getFontFilePath(),
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f),
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER})
        :addTo(bg)
    valLabel:pos(bg:getContentSize().width - valLabel:getContentSize().width - 10 , 20)
    item:addContent(bg)
    item:setItemSize(bg:getContentSize().width,bg:getContentSize().height)
    return item
end

function GameUIResource:RefreshListView()
    self.dataSource = self:GetDataSource()
    self.info:CreateInfoItems(self.dataSource)
end

function GameUIResource:GetDataSource()
    local dataSource = {{_("待建地基"),'x' .. #self.city:GetRuinsNotBeenOccupied()}}
    local decorators = self.city:GetDecoratorsByType(self.building:GetType())
    table.insert(dataSource,{_("可建造数量"),#decorators .. '/' .. self.city:GetMaxHouseCanBeBuilt(self.building:GetType())})
    local resource = self.city.resource_manager:GetResourceByType(self.building:GetUpdateResourceType())
    local __,__,title = self:GetTitleByType(self.building)
    table.insert(dataSource,{title,string.format("%d/h",resource:GetProductionPerHour())})

    if self.building:GetUpdateResourceType() == ResourceManager.RESOURCE_TYPE.CITIZEN then
        local coin_resource = self.city.resource_manager:GetCoinResource()
        local desc = string.format("%d/h",coin_resource:GetProductionPerHour())
        table.insert(dataSource,{_("当前产出银币"),desc})
    end
    local levelTable = {}
    for _,v in ipairs(decorators) do
        local level = tonumber(v:GetLevel())
        if levelTable[level] then
            levelTable[level] = levelTable[level] + 1
        else
            levelTable[level] = 1
        end
    end
    local final_level_table = {}
    for k,v in pairs(levelTable) do
        table.insert(final_level_table,{level = k,count = v})
    end
    table.sort( final_level_table, function(a,b) return a.level < b.level end)

    local title = self:GetTitleByType(self.building)
    for k,v in ipairs(final_level_table) do
        table.insert(dataSource,{title .. ' LV ' .. v.level ,'x' .. v.count})
    end
    return dataSource
end


function GameUIResource:GetTitleByType(building)
    local type = building:GetUpdateResourceType()
    if type == ResourceManager.RESOURCE_TYPE.WOOD then
        return _("木工小屋"),_("木材产量"),_("当前产出木材")
    elseif type == ResourceManager.RESOURCE_TYPE.IRON then
        return _("矿工小屋"),_("铁矿产量"),_("当前产出铁矿")
    elseif type == ResourceManager.RESOURCE_TYPE.STONE then
        return _("石匠小屋"),_("石料产量"),_("当前产出铁矿")
    elseif type == ResourceManager.RESOURCE_TYPE.FOOD then
        return _("农夫小屋"),_("粮食产量"),_("当前产出铁矿")
    elseif type == ResourceManager.RESOURCE_TYPE.CITIZEN then
        return _("住宅"),_("城民上限"),_("当前城民增长")
    else
        assert(false)
    end
end

function GameUIResource:OnMoveInStage()
    self:CreateUI()
    GameUIResource.super.OnMoveInStage(self)
end

function GameUIResource:ChaiButtonAction( event )
    if self.building:IsUpgrading() or self.building:IsBuilding() then
        UIKit:showMessageDialog(_("提示"), _("正在建造或者升级小屋,不能拆除!"), function()end)
        return
    end
    local tile = self.city:GetTileWhichBuildingBelongs(self.building)
    local house_location = tile:GetBuildingLocation(self.building)
    local torch_count = ItemManager:GetItemByName("torch"):Count()
    if torch_count<1 then
        UIKit:showMessageDialog(_("提示"),_("是否确认拆除?"),function ()
            NetManager:getBuyAndUseItemPromise("torch",{
                torch = {
                    buildingLocation = tile.location_id,
                    houseLocation = house_location,
                }
            })
        end,
        function ()
        end)

    else
        UIKit:showMessageDialog(_("提示"),_("是否确认拆除?"),function ()
            NetManager:getUseItemPromise("torch",{
                torch = {
                    buildingLocation = tile.location_id,
                    houseLocation = house_location,
                }
            })
        end,
        function ()
        end)
    end

    self:LeftButtonClicked(nil)
end
function GameUIResource:MoveButtonAction( event )
    if self.building:IsUpgrading() or self.building:IsBuilding() then
        UIKit:showMessageDialog(_("提示"), _("正在建造或者升级小屋,不能拆除!"), function()end)
        return
    end
    local tile = self.city:GetTileWhichBuildingBelongs(self.building)
    local house_location = tile:GetBuildingLocation(self.building)
    local torch_count = ItemManager:GetItemByName("movingConstruction"):Count()

    if torch_count<1 then
        NetManager:getBuyItemPromise("movingConstruction",1)
        WidgetMoveHouse.new(self.building)
    else
        WidgetMoveHouse.new(self.building)
    end

    self:LeftButtonClicked(nil)
end

function GameUIResource:OnMoveOutStage()
    self.dataSource = nil
    self.building = nil
    GameUIResource.super.OnMoveOutStage(self)
end

function GameUIResource:OnResourceChanged(resource_manager)
    GameUIResource.super.OnResourceChanged(self,resource_manager)
    -- if self.listView:getItems():count() < 2 then return end
    local number = self.city.resource_manager:GetResourceByType(self.building:GetUpdateResourceType()):GetResourceValueByCurrentTime(app.timer:GetServerTime())
    -- print("update cout:",number)
end

return GameUIResource





















