--
-- Author: Danny He
-- Date: 2015-04-29 21:15:17
--
local GameUIDragonEquipmentMake = UIKit:createUIClass("GameUIDragonEquipmentMake","UIAutoClose")
local StarBar = import(".StarBar")
local UIListView = import(".UIListView")
local WidgetDragonEquipIntensify = import("..widget.WidgetDragonEquipIntensify")
local BODY_HEIGHT = 578
local BODY_WIDTH = 608
local LISTVIEW_WIDTH = 548
local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local DragonManager = import("..entity.DragonManager")
local GameUIDragonEyrieDetail = import(".GameUIDragonEyrieDetail")
local MaterialManager = import("..entity.MaterialManager")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetMakeEquip = import("..widget.WidgetMakeEquip")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")
local EQUIPMENTS = GameDatas.DragonEquipments.equipments
local UILib = import(".UILib")

function GameUIDragonEquipmentMake:ctor(dragon,equipment_obj)
	GameUIDragonEquipmentMake.super.ctor(self)
	self.equipment = equipment_obj
	self.dragon = dragon
	local blackSmith = City:GetFirstBuildingByType("blackSmith")
	self.blackSmith = blackSmith
end

function GameUIDragonEquipmentMake:onEnter()
	GameUIDragonEquipmentMake.super.onEnter(self)
	local backgroundImage = WidgetUIBackGround.new({height = BODY_HEIGHT})
    self.ui_node_main = display.newNode():addTo(backgroundImage)
    self:addTouchAbleChild(backgroundImage)
	  self.background = backgroundImage:pos((display.width-backgroundImage:getContentSize().width)/2,display.height - backgroundImage:getContentSize().height - 150)
	  local titleBar = display.newSprite("title_blue_600x56.png")
		  :align(display.BOTTOM_LEFT, 2,backgroundImage:getContentSize().height - 15)
		  :addTo(backgroundImage)
	  self.mainTitleLabel =  UIKit:ttfLabel({
        text = Localize.body[self.equipment:Body()],
        size = 24,
        color= 0xffedae,
    })
    :addTo(titleBar)
    :align(display.CENTER, 300, 26)
    self.titleBar = titleBar
    UIKit:closeButton()
      :addTo(titleBar)
      :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width, 0)
      :onButtonClicked(function ()
          self:LeftButtonClicked()
      end)
    self:BuildUI()
end

function GameUIDragonEquipmentMake:BuildUI()
	local node = self.ui_node_main
	local mainEquipment = self:GetEquipmentItem()
          :addTo(node):align(display.LEFT_TOP,15,self.titleBar:getPositionY() - 10)
    local name_bar = display.newScale9Sprite("alliance_event_type_darkblue_222x30.png",0,0, cc.size(468,30), cc.rect(7,7,190,16))  
      :addTo(node):align(display.LEFT_TOP,mainEquipment:getPositionX() + mainEquipment:getContentSize().width + 5,mainEquipment:getPositionY() - 2)
    UIKit:ttfLabel({
        text = Localize.equip[self:GetEquipment():GetCanLoadConfig().name],
        size = 22,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT, 
        color = 0xffedae,
    }):addTo(name_bar):align(display.LEFT_CENTER, 14,15)
    local count_label = UIKit:ttfLabel({
        text = string.format(_("巨龙%d星装备"),self.dragon:Star()),
        size = 22,
        color= 0x403c2f
    }):addTo(node):align(display.LEFT_BOTTOM,name_bar:getPositionX(),mainEquipment:getPositionY() - mainEquipment:getContentSize().height + 8)
    local load_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
      :addTo(node)
      :align(display.RIGHT_BOTTOM,name_bar:getPositionX() + 468,mainEquipment:getPositionY() - mainEquipment:getContentSize().height)
      :setButtonLabel("normal", UIKit:commonButtonLable({
          text = _("制造"),
          size = 24,
      }))
      :onButtonClicked(function()
            if self.blackSmith:IsUnlocked() then
                WidgetMakeEquip.new(self:GetEquipment():GetCanLoadConfig().name, self.blackSmith, City):AddToCurrentScene()
                self:LeftButtonClicked()
            end
      end)
      load_button:setButtonEnabled(self.blackSmith:IsUnlocked())
      local list,list_node = UIKit:commonListView_1({
            viewRect = cc.rect(0, 0, 548, 160),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        })
      list_node:addTo(node):align(display.CENTER_TOP, BODY_WIDTH/2, load_button:getPositionY() - 15)
      self.info_list = list
      self:RefreshInfoListView()
      local requirements = self:GetMakeRequirement()
        self.listView = WidgetRequirementListview.new({
            title = _("需要材料"),
            height = 160,
            contents = requirements,
        }):addTo(node):pos(30,20)
end

function GameUIDragonEquipmentMake:GetMakeRequirement()
	local material_manager = City:GetMaterialManager()
	local materials = material_manager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.DRAGON)
	local requirements = {}
	local equip_config = EQUIPMENTS[self:GetEquipment():GetCanLoadConfig().name]
	local matrials = LuaUtils:table_map(string.split(equip_config.materials, ","), function(k, v)
        return k, string.split(v, ":")
    end)
	local desc = ""
	if self.blackSmith:IsUnlocked() then
		desc = self.blackSmith:IsEquipmentEventEmpty() and "1/1" or "0/1"
	else
		desc = _("铁匠铺还未解锁")
	end
    table.insert(requirements,
    {
        resource_type = "queue",
        isVisible = true,
        isSatisfy = self.blackSmith:IsUnlocked() and self.blackSmith:IsEquipmentEventEmpty(),
        icon="hammer_31x33.png",
        description= desc
    })
    local need_coin = equip_config.coin
    local coin = City.resource_manager:GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    table.insert(requirements,
    {
        resource_type = "coin",
        isVisible = true,
        isSatisfy = coin >= need_coin,
        icon="res_coin_81x68.png",
        description = coin .. "/" .. need_coin
    })

   	for __,v in ipairs(matrials) do
   		local material_type = v[1]
        local matrials_need = tonumber(v[2])
        local current = tonumber(materials[material_type])
   		table.insert(requirements,
        {
            resource_type = material_type,
            isVisible = true,
            isSatisfy = current >= matrials_need,
            icon = UILib.dragon_material_pic_map[material_type],
            description= string.format("%s %d/%d",Localize.equip_material[material_type],current,matrials_need)
        })
   	end
   	return requirements
end

function GameUIDragonEquipmentMake:GetEquipmentItem()
    return GameUIDragonEyrieDetail:GetEquipmentItem(self:GetEquipment(),self.dragon:Star(),false)
end

function GameUIDragonEquipmentMake:GetEquipment()
	return self.equipment
end

function GameUIDragonEquipmentMake:GetCurrentEquipmentCount()
    local player_equipments = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.EQUIPMENT)
    local equipment = self:GetEquipment()
    local eq_name = equipment:IsLoaded() and equipment:Name() or equipment:GetCanLoadConfig().name
    return player_equipments[eq_name] or 0
end

function GameUIDragonEquipmentMake:GetEquipmentEffect()
  local r = {}
  local equipment = self:GetEquipment()
  local vitality,strength = equipment:GetVitalityAndStrengh()
  local leadership = equipment:GetLeadership()
  table.insert(r,{_("活力"),vitality})
  table.insert(r,{_("力量"),strength})
  table.insert(r,{_("领导力"),leadership})
  table.insert(r,{_("附加随机属性数量"),self.dragon:Star()})
  return r
end

function GameUIDragonEquipmentMake:RefreshInfoListView()
	local data = self:GetEquipmentEffect()
  	if not data then return end
  	self.info_list:removeAllItems()
  	table.foreach(data,function(index,dataItem)
	    local item = self.info_list:newItem()
	    local content = self:GetListItem(index,dataItem[1],dataItem[2])
	    item:addContent(content)
	    item:setItemSize(LISTVIEW_WIDTH,40)
	    self.info_list:addItem(item)
  	end)
  self.info_list:reload()
end

function GameUIDragonEquipmentMake:GetListItem(index,title,value)
	local bg = display.newScale9Sprite(string.format("resource_item_bg%d.png",index%2)):size(LISTVIEW_WIDTH,40)
	  UIKit:ttfLabel({
	      text = title,
	      size = 20,
	      color = 0x615b44,
	      align = cc.ui.UILabel.TEXT_ALIGN_LEFT, 
	  }):addTo(bg):align(display.LEFT_CENTER,14,20)
	  UIKit:ttfLabel({
	      text = value,
	      size = 20,
	      align = cc.ui.UILabel.TEXT_ALIGN_RIGHT, 
	      color = 0x403c2f,
	  }):addTo(bg):align(display.RIGHT_CENTER, LISTVIEW_WIDTH - 10, 20)
	return bg
end

return GameUIDragonEquipmentMake