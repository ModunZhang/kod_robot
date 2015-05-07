--
-- Author: Danny He
-- Date: 2015-03-04 20:27:48
--
--
local window = import('..utils.window')
local Flag = import("..entity.Flag")
local Alliance_Manager = Alliance_Manager
local WidgetSequenceButton = import(".WidgetSequenceButton")
local WidgetAllianceLanguagePanel = import(".WidgetAllianceLanguagePanel")
local WidgetAllianceHelper = import(".WidgetAllianceHelper")
local WidgetPushButton = import(".WidgetPushButton")
local CONTENT_WIDTH = window.width - 80
local UICheckBoxButton = import("..ui.UICheckBoxButton")
local config_intInit = GameDatas.AllianceInitData.intInit
local WidgetAllianceCreateOrEdit = class("WidgetAllianceCreateOrEdit",function()
	return display.newNode()
end)


function WidgetAllianceCreateOrEdit:ctor(isModify,callback)
	self.isModify = isModify
	self.callback = callback
	self.alliance_ui_helper = WidgetAllianceHelper.new()
	if self:IsCreate() then
		self.flag_info = Flag:RandomFlag()
		self.terrain_info = self:Helper():RandomTerrain()
	else
		self.flag_info  = clone(Alliance_Manager:GetMyAlliance():Flag())
		self.terrain_info = Alliance_Manager:GetMyAlliance():Terrain()
	end
	self:setNodeEventEnabled(true)
end

function WidgetAllianceCreateOrEdit:onEnter()
	local okButton = WidgetPushButton.new({normal = "green_btn_up_250x66.png",pressed = "green_btn_down_250x66.png"})
    	:addTo(self)
    	:align(display.BOTTOM_RIGHT, CONTENT_WIDTH - 10, 10)
    	:setButtonLabel("normal",UIKit:commonButtonLable({
    		 size = 22,
    		 color= 0xffedae,
    		 text = self:IsCreate() and _("创建") or _("修改")
    	}))
	    :onButtonClicked(function(event)
	    	self:CreateAllianceButtonClicked()
    	end)
		local gemIcon = display.newSprite("gem_icon_62x61.png")
			:addTo(self)
			:align(display.LEFT_BOTTOM,okButton:getPositionX() - 360,12)
			:scale(0.5)
		local gemLabel = UIKit:ttfLabel({
			text = self:IsCreate() and config_intInit.createAllianceGem.value or config_intInit.editAllianceBasicInfoGem.value,
			size = 16,
			color = 0x615b44
		})
			:addTo(self)
			:align(display.LEFT_CENTER, gemIcon:getPositionX()+gemIcon:getCascadeBoundingBox().width + 4,gemIcon:getPositionY() + gemIcon:getCascadeBoundingBox().height/2)
		-- flags
	    self.createFlagPanel = self:createFlagPanel():addTo(self)
	    	:pos(0,okButton:getPositionY()+85)
	    -- landform & language
	    self.landformPanel = self:createCheckAllianeGroup():addTo(self)
	    	:pos(-10,self.createFlagPanel:getCascadeBoundingBox().height+50)
	    -- textfield
	    self.textfieldPanel = self:createTextfieldPanel():addTo(self)
	    	:pos(-10,self.landformPanel:getPositionY()+self.landformPanel:getCascadeBoundingBox().height+20)
end

function WidgetAllianceCreateOrEdit:Helper()
	return self.alliance_ui_helper
end

function WidgetAllianceCreateOrEdit:IsCreate()
	return self.isModify ~= true 
end

-- api
function WidgetAllianceCreateOrEdit:CreateAllianceButtonClicked()
	local data = self:AdapterCreateData2Server_()
	local errMsg = ""
	if string.utf8len(data.name) < 3 or string.utf8len(data.name) > 20 or string.find(data.name,"%p") then
		errMsg = _("联盟名称不合法") .. _("只允许字母、数字和空格，需要3~20个字符")
	end 
	if string.utf8len(data.tag) < 1 or string.utf8len(data.tag) > 3 or not string.match(data.tag,"^%w%w?%w?") then
		errMsg = _("联盟标签不合法") .. _("只允许字母、数字需要1~3个字符")
	end
	if self:IsCreate() then
		if config_intInit.createAllianceGem.value > User:GetGemResource():GetValue() then
			errMsg = _("金龙币不足")
			return 
		end
	else
		if config_intInit.editAllianceBasicInfoGem.value > User:GetGemResource():GetValue() then
			errMsg = _("金龙币不足")
			return 
		end
	end
	if errMsg ~= "" then
  		UIKit:showMessageDialog(_("错误"),errMsg)
		return 
	end
	if self:IsCreate() then
		NetManager:getCreateAlliancePromise(data.name,data.tag,data.language,data.terrain,data.flag):done(function()
			 GameGlobalUI:showTips(_("提示"),_("创建联盟成功!"))
		end)
	else
		local my_alliance = Alliance_Manager:GetMyAlliance()
		if not self:GetFlagInfomation():IsDifferentWith(Alliance_Manager:GetMyAlliance():Flag()) 
			and my_alliance:Tag() == data.tag 
			and my_alliance:Name() == data.name 
			and my_alliance:DefaultLanguage() == data.language 
			then
			UIKit:showMessageDialog(_("提示"),_("联盟信息当前没有任何改动!"))
		else
			NetManager:getEditAllianceBasicInfoPromise(data.name,data.tag,data.language,data.flag):done(function(result)
				GameGlobalUI:showTips(_("提示"),_("修改联盟信息成功!"))
				if self.callback and type(self.callback) == 'function' then
					self.callback()
				end
			end)
		end
	end
end

function WidgetAllianceCreateOrEdit:createFlagPanel()
	local node = display.newNode()
	local panel = display.newSprite("alliance_flag_setting_panel_370x264.png")
		:align(display.RIGHT_BOTTOM, CONTENT_WIDTH - 10,0):addTo(node)

	local color_1,color_2 = self:GetFlagInfomation():GetBackSeqColors()
	local colorButton_right = WidgetSequenceButton.new(
			{normal = "alliance_flag_button_n_92x88.png",pressed = "alliance_flag_button_h_92x88.png"},
			{scale9 = false},
			{{image="alliance_flag_color_62x62.png"}},
			self:Helper():GetAllColorsForSeqButton(),
			color_2
		)
		:addTo(panel)
		:pos(295,75)
		:onSeqStateChange(handler(self, self.OnFlagTypeButtonClicked))
		:setButtonEnabled(self:GetFlagInfomation():GetBackStyle() ~= 1)
	self.colorButton_right = colorButton_right
	local colorButton_left = WidgetSequenceButton.new(
			{normal = "alliance_flag_button_n_92x88.png",pressed = "alliance_flag_button_h_92x88.png"}, 
			{scale9 = false},
			{{image="alliance_flag_color_62x62.png"}},
			self:Helper():GetAllColorsForSeqButton(),
			color_1
		)
		:addTo(panel):pos(183,75)
		:onSeqStateChange(handler(self, self.OnFlagTypeButtonClicked))
	self.colorButton_left = colorButton_left


	local flag_type_button = WidgetSequenceButton.new(
			{normal = "alliance_flag_button_1_n_92x88.png",pressed = "alliance_flag_button_1_h_92x88.png"}, 
			{scale9 = false},
			self:Helper():GetBackStylesForSeqButton(),
			nil,
			self:GetFlagInfomation():GetBackStyle()
		):addTo(panel)
		:pos(70,75)
		:onSeqStateChange(handler(self, self.OnFlagTypeButtonClicked))
	self.flag_type_button = flag_type_button

	local graphic_type_button = WidgetSequenceButton.new(
			{normal = "alliance_flag_button_1_n_92x88.png",pressed = "alliance_flag_button_1_h_92x88.png"}, 
			{scale9 = false,scale = 0.8},
			self:Helper():GetAllGraphicsForSeqButton(),
			nil,
			self:GetFlagInfomation():GetFrontStyle()
		):addTo(panel)
		:pos(70,190)
		:onSeqStateChange(handler(self, self.OnGraphicTypeButtonClicked))
	self.graphic_type_button =  graphic_type_button

	local graphic_right_button = WidgetSequenceButton.new(
			{normal = "alliance_flag_button_n_92x88.png",pressed = "alliance_flag_button_n_92x88.png"}, 
			{scale9 = false},
			{{image="alliance_flag_color_62x62.png"}},
			self:Helper():GetAllColorsForSeqButton(),
			self:GetFlagInfomation():GetFrontSeqColor()
		)
			:addTo(panel)
			:pos(183,190)
			:onSeqStateChange(handler(self, self.OnGraphicTypeButtonClicked))
	self.graphic_right_button = graphic_right_button

	local flagNode,terrain_node,flag_sprite = self:Helper():CreateFlagWithRectangleTerrain(self.terrain_info,self:GetFlagInfomation())
	flagNode:addTo(node):pos(80,140)
	self.terrain_node = terrain_node
	self.flag_sprite = flag_sprite

	local randomButton = WidgetPushButton.new({normal = "alliance_sieve_51x45.png"})
		:addTo(node)
		:align(display.CENTER_BOTTOM, 80,-50)
		:onButtonClicked(function()
			self.flag_info = self:GetFlagInfomation():RandomFlag()
			self:RefreshButtonState()
			self:RefrshFlagSprite()
		end)

	UIKit:ttfLabel({
		text = _("联盟旗帜"),
		size = 22,
		color = 0x403c2f
	}):addTo(node):align(display.CENTER,CONTENT_WIDTH/2 - 10,290)
	return node
end


function WidgetAllianceCreateOrEdit:createCheckAllianeGroup()
	local groupNode = display.newNode()
	if self:IsCreate() then
		local tipsLabel = UIKit:ttfLabel({
				text = _("草地——产出强化绿龙的材料，更容易培养绿龙，更容易培养绿龙，草地产出绿金龙币，建造资源加成类的铺筑建筑"),
				size = 18,
				color = 0x615b44,
				dimensions = cc.size(552, 0),
		}):addTo(groupNode):align(display.LEFT_BOTTOM, 0, 0)
		local landSelect = UIKit:CreateBoxPanelWithBorder({}):addTo(groupNode):pos(0,tipsLabel:getContentSize().height+10)
		local title = display.newSprite("alliance_panel_bg_544x32.png")
			:align(display.CENTER_TOP,landSelect:getContentSize().width/2, landSelect:getContentSize().height - 6)
			:addTo(landSelect)
		UIKit:ttfLabel({
			text = _("联盟地形"),
			size = 20,
			color = 0xffedae
		}):addTo(title):align(display.CENTER,272, 16)
		local checkbox_image = {
	        off = "checkbox_unselected.png",
	        off_pressed = "checkbox_unselected.png",
	        off_disabled = "checkbox_unselected.png",
	        on = "checkbox_selectd.png",
	        on_pressed = "checkbox_selectd.png",
	        on_disabled = "checkbox_selectd.png",

	    }
		self.landTypeButton = cc.ui.UICheckBoxButtonGroup.new()
	        :addButton(UICheckBoxButton.new(checkbox_image)
	            :setButtonLabel(UIKit:ttfLabel({text = _("草地"),size = 20,color = 0x615b44}))
	            :setButtonLabelOffset(40, 0)
	            :align(display.LEFT_CENTER))
	        :addButton(UICheckBoxButton.new(checkbox_image)
	            :setButtonLabel(UIKit:ttfLabel({text = _("沙漠"),size = 20,color = 0x615b44}))
	            :setButtonLabelOffset(40, 0)
	            :align(display.LEFT_CENTER))
	        :addButton(UICheckBoxButton.new(checkbox_image)
	            :setButtonLabel(UIKit:ttfLabel({text = _("雪地"),size = 20,color = 0x615b44}))
	            :setButtonLabelOffset(40, 0)
	            :align(display.LEFT_CENTER))
	        :setButtonsLayoutMargin(10, 100, 0,0)
	        :onButtonSelectChanged(function(event)
	            self.terrain_info = event.selected
	            self:RefrshFlagSprite(3)
	        end)
	        :addTo(landSelect):pos(10,10)
	    self.languageSelected  = WidgetAllianceLanguagePanel.new():addTo(groupNode)
	    	:pos(0,landSelect:getCascadeBoundingBox().height+landSelect:getPositionY()+20)
    	self:SelectLandCheckButton(self.terrain_info,true)
	else
   		self.languageSelected  = WidgetAllianceLanguagePanel.new(Alliance_Manager:GetMyAlliance():DefaultLanguage()):addTo(groupNode):pos(0,0)
   	end
    return groupNode
end

function WidgetAllianceCreateOrEdit:createTextfieldPanel()
	local node = display.newNode()
	local limitLabel = UIKit:ttfLabel({
		text = _("只允许字母、数字需要1~3个字符"),
		size = 18,
		color = 0x615b44
	}):addTo(node):align(display.LEFT_BOTTOM, 0, 0)

	local editbox_tag = cc.ui.UIInput.new({
    	UIInputType = 1,
        image = "alliance_editbox_575x48.png",
        size = cc.size(552,48),
    })
    editbox_tag:setPlaceHolder(_("最多可输入3字符"))
    editbox_tag:setFont(UIKit:getEditBoxFont(),18)
    editbox_tag:setFontColor(cc.c3b(0,0,0))
    editbox_tag:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox_tag:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editbox_tag:align(display.LEFT_BOTTOM,0,limitLabel:getContentSize().height+10):addTo(node)
    self.editbox_tag = editbox_tag
    if not self:IsCreate() then
    	editbox_tag:setText(Alliance_Manager:GetMyAlliance():Tag())
    end
    local tagLabel = UIKit:ttfLabel({
		text = _("联盟标签"),
		size = 22,
		color = 0x403c2f
	}):addTo(node):align(display.CENTER, 552/2, editbox_tag:getPositionY()+editbox_tag:getContentSize().height+20)

	local nameTipLabel = UIKit:ttfLabel({
		text = _("只允许字母、数字和空格，需要3~20个字符"),
		size = 18,
		color = 0x615b44
	}):addTo(node):align(display.LEFT_BOTTOM, 0, tagLabel:getPositionY()+40)

	local editbox_name = cc.ui.UIInput.new({
    	UIInputType = 1,
        image = "alliance_editbox_575x48.png",
        size = cc.size(510,48),
    })
    editbox_name:setPlaceHolder(_("最多可输入20字符"))
    editbox_name:setFont(UIKit:getEditBoxFont(),18)
    editbox_name:setFontColor(cc.c3b(0,0,0))
    editbox_name:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox_name:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editbox_name:align(display.LEFT_BOTTOM,0,nameTipLabel:getPositionY()+nameTipLabel:getContentSize().height+10):addTo(node)
     if not self:IsCreate() then
    	editbox_name:setText(Alliance_Manager:GetMyAlliance():Name())
    end
    self.editbox_name = editbox_name

    local randomButton = WidgetPushButton.new({normal = "alliance_sieve_51x45.png"})
		:addTo(node)
		:align(display.LEFT_BOTTOM, editbox_name:getContentSize().width+editbox_name:getPositionX()+2, editbox_name:getPositionY())
		:onButtonClicked(function()
			self:RandomAllianceName_()
		end):zorder(editbox_name:getLocalZOrder()+10)
	randomButton:setTouchSwallowEnabled(false)

     local nameLabel = UIKit:ttfLabel({
		text = _("联盟名称"),
		size = 22,
		color = 0x403c2f
	}):addTo(node):align(display.CENTER, 552/2, editbox_name:getPositionY()+editbox_name:getContentSize().height+20)
	return node
end

function WidgetAllianceCreateOrEdit:GetFlagInfomation()
	return self.flag_info
end

function WidgetAllianceCreateOrEdit:SelectLandCheckButton( type,selected)
	self.landTypeButton:getButtonAtIndex(type):setButtonSelected(selected)
end

function WidgetAllianceCreateOrEdit:RandomAllianceName_()
	local name,tag = self:Helper():RandomAlliacneNameAndTag()
	self.editbox_name:setText(name)
	self.editbox_tag:setText(tag)
end


-- where : 1->body 2->graphic 3->terrain other->all
function WidgetAllianceCreateOrEdit:RefrshFlagSprite(where)
	local box_bounding = self.flag_sprite:getChildByTag(self.alliance_ui_helper.FLAG_TAG.FLAG_BOX)
	if 1 == where then --body
		local flag_obj = self:GetFlagInfomation()
		local flag_body = self.flag_sprite:getChildByTag(self.alliance_ui_helper.FLAG_TAG.BODY)
		flag_body:removeFromParent(true)
		flag_body = self.alliance_ui_helper:CreateFlagBody(flag_obj,box_bounding:getContentSize())
		flag_body:addTo(self.flag_sprite,self.alliance_ui_helper.FLAG_ZORDER.BODY,self.alliance_ui_helper.FLAG_TAG.BODY)
	elseif 2 == where then --graphic
		local graphic_node = self.flag_sprite:getChildByTag(self.alliance_ui_helper.FLAG_TAG.GRAPHIC)
		graphic_node:removeFromParent(true)
		graphic_node = self.alliance_ui_helper:CreateFlagGraphic(self:GetFlagInfomation(),box_bounding:getContentSize())
		graphic_node:addTo(self.flag_sprite,self.alliance_ui_helper.FLAG_ZORDER.GRAPHIC,self.alliance_ui_helper.FLAG_TAG.GRAPHIC)
	elseif 3 == where then
		self.terrain_node:setTexture(self.alliance_ui_helper:GetRectangleTerrainImageByIndex(self.terrain_info))
	else --all
		self:RefrshFlagSprite(1)
		self:RefrshFlagSprite(2)
	end
end

function WidgetAllianceCreateOrEdit:RefreshButtonState()
	local flag = self:GetFlagInfomation()
	local color_1,color_2 = self:GetFlagInfomation():GetBackSeqColors()
	self.colorButton_right:setSeqState(color_2,false)
	self.colorButton_left:setSeqState(color_1,false)
	self.flag_type_button:setSeqState(flag:GetBackStyle(),false)
	self.graphic_right_button:setSeqState(flag:GetFrontSeqColor(),false)
	self.graphic_type_button:setSeqState(flag:GetFrontStyle(),false)
	self.colorButton_right:setButtonEnabled(flag:GetBackStyle() ~= 1)
	self.graphic_right_button:setButtonEnabled(flag:GetFrontStyle() ~= 1)
end

function WidgetAllianceCreateOrEdit:AdapterCreateData2Server_()
	return {
		name=string.trim(self.editbox_name:getText()),
		tag=string.trim(self.editbox_tag:getText()),
		language=self.languageSelected:getSelectedLanguage(),
		terrain=self.alliance_ui_helper:GetTerrainNameByIndex(self.terrain_info),
		flag=self:GetFlagInfomation():EncodeToJson()
	}
end

-- flag button event
function WidgetAllianceCreateOrEdit:OnFlagTypeButtonClicked()
	local flag = self:GetFlagInfomation()
	flag:SetBackStyle(self.flag_type_button:GetSeqState())
	flag:SetBackColors(self.colorButton_left:GetSeqState(),self.colorButton_right:GetSeqState())
	self.colorButton_right:setButtonEnabled(flag:GetBackStyle() ~= 1)
	self.graphic_right_button:setButtonEnabled(flag:GetFrontStyle() ~= 1)
	self:RefrshFlagSprite(1)
end

function WidgetAllianceCreateOrEdit:OnGraphicTypeButtonClicked()
	local flag = self:GetFlagInfomation()
	flag:SetFrontStyle(self.graphic_type_button:GetSeqState())
	flag:SetFrontColor(self.graphic_right_button:GetSeqState())
	self.colorButton_right:setButtonEnabled(flag:GetBackStyle() ~= 1)
	self.graphic_right_button:setButtonEnabled(flag:GetFrontStyle() ~= 1)
	self:RefrshFlagSprite(2)
end
return WidgetAllianceCreateOrEdit
