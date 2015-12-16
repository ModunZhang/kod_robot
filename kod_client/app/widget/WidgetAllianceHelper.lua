--
-- Author: Danny He
-- Date: 2015-04-10 15:04:46
--
local WidgetAllianceHelper = class("WidgetAllianceHelper")

WidgetAllianceHelper.FLAG_ZORDER = {
	BODY = 1,
	GRAPHIC = 3,
	FLAG_BOX = 4,
}

WidgetAllianceHelper.FLAG_TAG = {
	BODY = 1,
	GRAPHIC = 3,
	FLAG_BOX = 4,
}


function WidgetAllianceHelper:ctor()
	self.colors = {
		0x000000,
		0xffffff,
		0x209b5c,
		0x673499,
		0xa82128,
		0x30529c,
		0xbfac12,
		0x494949,
		0x349bc4,
		0xc061ef,
		0xd05e15,
		0x209a9b
	}
	self.landforms = {
		grassLand = 1,desert = 2,iceField = 3
	}
	self.count_of_landforms = 3
	self.terrain_info = math.random(self.count_of_landforms)
	--旗帜的所有图案
	self.images_of_graphics = {}
	table.insert(self.images_of_graphics,{name = 1,image = "transparent_1x1.png"})
	for i=1,30 do
	    local imageName = string.format("tmp_alliance_graphic_88x88_%d",i)
	    table.insert(self.images_of_graphics,{name = i + 1,image = imageName .. ".png"})
	end
	--旗帜背景布局样式
	self.images_of_category = {}
	for i=1,10 do
	    local bodyButtonImageName = string.format("alliance_flag_type_48x46_%d",i)
		self.images_of_category[i] = {name = i,image = bodyButtonImageName .. ".png"}
	end
	--对应三种地形
	self.images_of_terrain_rhombus = {"rhombus_grassLand_83x61.png","rhombus_desert_83x61.png","rhombus_iceField_83x61.png"}
	self.images_of_terrain_rectangle = {"rectangle_grassLand_178x263.png","rectangle_desert_178x263.png","rectangle_iceField_178x263.png"}

end

function WidgetAllianceHelper:GetRectangleTerrainImageByIndex(index)
	index = tonumber(index)
	return self.images_of_terrain_rectangle[index]
end

function WidgetAllianceHelper:GetRhombusTerrainImageByIndex(index)
	index = tonumber(index)
	return self.images_of_terrain_rhombus[index]
end

function WidgetAllianceHelper:GetGraphicImageNameByIndex(index)
	index = tonumber(index)
	return self.images_of_graphics[index].image
end

function WidgetAllianceHelper:GetAllGraphicsForSeqButton()
	return self.images_of_graphics
end

function WidgetAllianceHelper:GetAllColors()
	return self.colors
end

function WidgetAllianceHelper:GetAllColorsForSeqButton()
	if not self.seq_colors then
		self.seq_colors = {}
		table.foreachi(self:GetAllColors(),function(index,v)
	    	table.insert(self.seq_colors,{name = "colors_" .. tostring(index),color=UIKit:convertColorToGL_(v)})
		end)
	end
	return self.seq_colors
end

function WidgetAllianceHelper:GetBackStylesForSeqButton()
	return self.images_of_category
end

function WidgetAllianceHelper:GetColorByIndex(index)
	return self.colors[index]
end

function WidgetAllianceHelper:GetTerrainIndex(name)
	return self.landforms[name]
end

function WidgetAllianceHelper:GetTerrainNameByIndex(index)
	local index = tonumber(index)
	for k,v in pairs(self.landforms) do
		if v == index then
			return k
		end
	end
	return ""
end

function WidgetAllianceHelper:RandomTerrain()
	self.terrain_info = math.random(self.count_of_landforms)
	return self.terrain_info
end

function WidgetAllianceHelper:RandomAlliacneNameAndTag()
	return DataUtils:randomAllianceNameTag()
end

function WidgetAllianceHelper:GetTerrain()
	return self.terrain_info
end

--旗帜
---------------------------------------------------------------------------------------------------
--创建一个自定义颜色的Sprite
function WidgetAllianceHelper:CreateColorSprite(image,color_index)
    return display.newFilteredSprite(image, "CUSTOM", self:GetColorFilter(color_index))
end
function WidgetAllianceHelper:GetColorFilter(color_index)
	local customParams = self:GetColorShaderParams(color_index)
	return json.encode(customParams)
end
function WidgetAllianceHelper:GetColorShaderParams(color_index)
	color_index = tonumber(color_index)
	return {
        frag = "shaders/customer_color.fsh",
        shaderName = "colors_" .. color_index,
        color = UIKit:convertColorToGL_(self:GetColorByIndex(color_index))
    }
end

--创建旗帜
local count_config = {
    backstyle=10,
    colors=12,
    graphics=20,
}
local random_back_backstyle_key = {}
local random_back_color_1_key = {}
local random_back_color_2_key = {}
local random_graphics_key = {}
local random_front_color_key = {}
function WidgetAllianceHelper:RandomFlagStr()
	math.randomseed(tostring(os.time()):reverse():sub(1, 10))
    random = math.random
   
    local form = random(count_config.backstyle)
    if LuaUtils:table_size(random_back_backstyle_key) >= count_config.backstyle then random_back_backstyle_key = {} end
    while random_back_backstyle_key[form] do
        form = random(count_config.backstyle)
    end
    random_back_backstyle_key[form] = true

    local color1 = random(0,count_config.colors - 1) + 1
    if LuaUtils:table_size(random_back_color_1_key) >= count_config.colors then random_back_color_1_key = {} end
    while random_back_color_1_key[color1] do
        color1 = random(count_config.colors) 
    end
    random_back_color_1_key[color1] = true

    local color2 = random(count_config.colors)
    if LuaUtils:table_size(random_back_color_2_key) >= count_config.colors then random_back_color_2_key = {} end
    while random_back_color_2_key[color2] do
        color2 = random(count_config.colors)
    end
    random_back_color_2_key[color2] = true

    local graphic = random(count_config.graphics)
    if LuaUtils:table_size(random_graphics_key) >= count_config.graphics then random_graphics_key = {} end
    while random_graphics_key[graphic] do
        graphic = random(count_config.graphics)
    end
    random_graphics_key[graphic] = true

    local graphic_color = random(0,count_config.colors - 2) + 2
    if LuaUtils:table_size(random_front_color_key) >= count_config.colors then random_front_color_key = {} end
    while random_front_color_key[graphic_color] do
        graphic_color = random(count_config.colors)
    end
    random_front_color_key[graphic_color] = true

	return string.format("%d,%d,%d,%d,%d", form, color1, color2, graphic, graphic_color)
end
function WidgetAllianceHelper:GetFlagArray(flag_str)
	local form, color1, color2, graphic, graphic_color = unpack(string.split(flag_str, ","))
	return tonumber(form), tonumber(color1), tonumber(color2), tonumber(graphic), tonumber(graphic_color)
end
function WidgetAllianceHelper:GetFlagStr(...)
    for i,v in ipairs{...} do
        assert(tonumber(v), v)
    end
    return string.format("%s,%s,%s,%s,%s", ...)
end
function WidgetAllianceHelper:CreateFlagContentSprite(flagstr)
	local box_bounding = display.newSprite("alliance_flag_box_119x139.png")
	local size = box_bounding:getContentSize()
    local box = display.newNode()
    --body
    local body_node = self:CreateFlagBody(flagstr,size)
    body_node:addTo(box,self.FLAG_ZORDER.BODY,self.FLAG_TAG.BODY)
    --graphic
    local graphic_node = self:CreateFlagGraphic(flagstr,size)
    graphic_node:addTo(box,self.FLAG_ZORDER.GRAPHIC,self.FLAG_TAG.GRAPHIC)
   	box_bounding:addTo(box,self.FLAG_ZORDER.FLAG_BOX,self.FLAG_TAG.FLAG_BOX):align(display.LEFT_BOTTOM, 0, 0)

   	local this = self
   	function box:SetFlag(flagstr)
   		local form, color1, color2, graphic, graphic_color = this:GetFlagArray(flagstr)
   		body_node:getChildByTag(1):setFilter(filter.newFilter("CUSTOM", this:GetColorFilter(color1)))
   		local is_visible = form > 1
   		local color2_sprite = body_node:getChildByTag(2)
   		if color2_sprite then
   			if is_visible then
   				color2_sprite:setTexture(this:GetColor2Image(form))
   				color2_sprite:setFilter(filter.newFilter("CUSTOM", this:GetColorFilter(color2)))
   			end
   			color2_sprite:setVisible(is_visible)
   		else
   			if is_visible then
   				local content = this:CreateColorSprite(this:GetColor2Image(form),color2)
    			:addTo(body_node,0,2)
        		:pos(size.width/2,size.height/2)
   			end
   		end
   		-- 
   		local filename, color = this:GetFlagGraphic(flagstr)
   		graphic_node:setTexture(filename)
   		graphic_node:setColor(color)
   	end
    return box
end

--旗帜背景
function WidgetAllianceHelper:CreateFlagBody(flagstr,box_bounding)
	local body_node = display.newNode() 
	local form, color1, color2, graphic, graphic_color = self:GetFlagArray(flagstr)
	local bg = self:CreateColorSprite("alliance_flag_body_106x126_1.png",color1)
		:addTo(body_node,0,1)
        :pos(box_bounding.width/2,box_bounding.height/2)
   	if form > 1 then
    	local content = self:CreateColorSprite(self:GetColor2Image(form),color2)
    		:addTo(body_node,0,2)
        	:pos(box_bounding.width/2,box_bounding.height/2)
    end
	return body_node
end
function WidgetAllianceHelper:GetColor2Image(form)
	return string.format("alliance_flag_body_106x126_%d.png", form)
end
--旗帜图案
function WidgetAllianceHelper:CreateFlagGraphic(flagstr,box_bounding)
	local filename, color = self:GetFlagGraphic(flagstr)
	local sprite = display.newSprite(filename)
				:pos(box_bounding.width/2,box_bounding.height/2)
	sprite:setColor(color)
	return sprite
end
function WidgetAllianceHelper:GetFlagGraphic(flagstr)
	local form, color1, color2, graphic, graphic_color = self:GetFlagArray(flagstr)
	local filename = self:GetGraphicImageNameByIndex(graphic)
	local color = UIKit:hex2c3b(self:GetColorByIndex(graphic_color))
	return filename, color
end
--带地形(矩形)的旗帜
function WidgetAllianceHelper:CreateFlagWithRectangleTerrain(terrain_info,flagstr)
	if type(terrain_info) == 'string' then terrain_info = self:GetTerrainIndex(terrain_info) end
	local terrain_file = self:GetRectangleTerrainImageByIndex(terrain_info)
	local node = display.newNode()
	local terrain_sprite = display.newSprite(terrain_file)
        :addTo(node)
        :scale(0.9)

    local shadow = display.newSprite("alliance_flag_shadow_113x79.png")
        :addTo(node)
        :align(display.RIGHT_BOTTOM, terrain_sprite:getPositionX()+36, terrain_sprite:getPositionY()-80)
        :scale(0.9)
    local base = display.newSprite("alliance_flag_base_84x89.png")
        :addTo(node)
        :align(display.RIGHT_BOTTOM, terrain_sprite:getPositionX()+35, terrain_sprite:getPositionY()-80)
        :scale(0.9)
    local flag_node = self:CreateFlagContentSprite(flagstr):addTo(node)
        :align(display.RIGHT_BOTTOM, terrain_sprite:getPositionX() - 55, terrain_sprite:getPositionY()-45)
        :scale(0.9)
    local box = display.newSprite("rectangle_terrain_box_216x282.png")
        :addTo(node)
        :scale(0.9)

    return node,terrain_sprite,flag_node
end
--带地形(菱形)的旗帜
function WidgetAllianceHelper:CreateFlagWithRhombusTerrain(terrain_info,flagstr)
    if type(terrain_info) == 'string' then terrain_info = self:GetTerrainIndex(terrain_info)  end
    local node = display.newNode()
    local terrain = self:GetRhombusTerrainImageByIndex(terrain_info)
    local terrain_sprite = display.newSprite(terrain)
        :addTo(node)
    local shadow = display.newSprite("alliance_flag_shadow_113x79.png")
        :addTo(node)
        :align(display.RIGHT_BOTTOM, terrain_sprite:getPositionX()+14, terrain_sprite:getPositionY() - 14)
        :scale(0.4)
    local base = display.newSprite("alliance_flag_base_84x89.png")
        :addTo(node)
        :align(display.RIGHT_BOTTOM, terrain_sprite:getPositionX()+14, terrain_sprite:getPositionY()-14)
        :scale(0.4)
    local flag_node = self:CreateFlagContentSprite(flagstr):addTo(node)
        :align(display.RIGHT_BOTTOM, terrain_sprite:getPositionX() - 26, terrain_sprite:getPositionY())
        :scale(0.4)

    return node,terrain_sprite,flag_node
end

return WidgetAllianceHelper