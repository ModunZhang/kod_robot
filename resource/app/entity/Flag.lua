local Flag = class("Flag")
local count_config = {
    backstyle=10,
    colors=12,
    graphics=20,
}
local random_graphics_key = {}
local random_back_color_1_key = {}
local random_back_color_2_key = {}
local random_back_backstyle_key = {}
local random_front_color_key = {}
function Flag:ctor()
    self.form_index = 2
    self.form_color_index_1 = 10
    self.form_color_index_2 = 2 
    self.graphic_index = 10
    self.graphic_color_index = 11
end
function Flag:SetBackColors(color1, color2)
    if type(color1) == 'string' and string.find(color1,"colors_") then
        color1 = string.sub(color1,8)
    end   
    if type(color2) == 'string' and string.find(color2,"colors_") then
        color2 = string.sub(color2,8)
    end  

    color1 = tonumber(color1)
    color2 = tonumber(color2)
    self.form_color_index_1 = color1
    self.form_color_index_2 = color2
end
function Flag:GetBackColors()
    return self.form_color_index_1,self.form_color_index_2
end

function Flag:GetBackSeqColors()
    return "colors_" .. self.form_color_index_1,"colors_" .. self.form_color_index_2
end

function Flag:SetBackStyle(back_style)
    back_style = tonumber(back_style)
    self.form_index = back_style
end

function Flag:GetBackStyle()
    return self.form_index
end

function Flag:SetFrontStyle(front_style)
    front_style = tonumber(front_style)
    self.graphic_index = front_style
end

function Flag:GetFrontStyle()
    return self.graphic_index
end

function Flag:SetFrontColor(color)
     if type(color) == 'string' and string.find(color,"colors_") then
        color = string.sub(color,8)
    end   
    color = tonumber(color)
    self.graphic_color_index = color
end

function Flag:GetFrontColor()
    return self.graphic_color_index
end

function Flag:GetFrontSeqColor()
    return "colors_" .. self.graphic_color_index
end

function Flag:IsDifferentWith(flag)
    return not self:IsSameWith(flag)
end
function Flag:IsSameWith(flag)
    return self.form_index == flag.form_index
        and self.form_color_index_1 == flag.form_color_index_1
        and self.form_color_index_2 == flag.form_color_index_2
        and self.graphic_index == flag.graphic_index
        and self.graphic_color_index == flag.graphic_color_index
end
-- 随机不会替换以前的旗帜
local math = math
local random = math.random
local randomseed = math.randomseed

function Flag:RandomFlag()
    local flag = Flag.new()
    randomseed(tostring(os.time()):reverse():sub(1, 10))
    local backStyle_random = random(count_config.backstyle)
    if LuaUtils:table_size(random_back_backstyle_key) >= count_config.backstyle then random_back_backstyle_key = {} end
    while random_back_backstyle_key[backStyle_random] do
        backStyle_random = random(count_config.backstyle)
    end
    random_back_backstyle_key[backStyle_random] = true
    flag:SetBackStyle(backStyle_random)
    local oneColor = random(0,count_config.colors - 1) + 1
    if LuaUtils:table_size(random_back_color_1_key) >= count_config.colors then random_back_color_1_key = {} end
    while random_back_color_1_key[oneColor] do
        oneColor = random(count_config.colors) 
    end
    random_back_color_1_key[oneColor] = true
    local otherColor = random(count_config.colors)
    if LuaUtils:table_size(random_back_color_2_key) >= count_config.colors then random_back_color_2_key = {} end
    while random_back_color_2_key[otherColor] do
        otherColor = random(count_config.colors)
    end
    random_back_color_2_key[otherColor] = true
    flag:SetBackColors(oneColor, otherColor)
    local random_num = random(count_config.graphics)
    if LuaUtils:table_size(random_graphics_key) >= count_config.graphics then random_graphics_key = {} end
    while random_graphics_key[random_num] do
        random_num = random(count_config.graphics)
    end
    random_graphics_key[random_num] = true
    flag:SetFrontStyle(random_num)
    oneColor = random(0,count_config.colors - 2) + 2
    if LuaUtils:table_size(random_front_color_key) >= count_config.colors then random_front_color_key = {} end
    while random_front_color_key[oneColor] do
        oneColor = random(count_config.colors)
    end
    random_front_color_key[oneColor] = true
    flag:SetFrontColor(oneColor)
    
    return flag
end
function Flag:EncodeToJson()
    checkint(self.form_index)
    checkint(self.form_color_index_1)
    checkint(self.form_color_index_2)
    checkint(self.graphic_index)
    checkint(self.graphic_color_index)
    return string.format("%d,%d,%d,%d,%d",self.form_index,self.form_color_index_1,self.form_color_index_2,self.graphic_index,self.graphic_color_index)
end

function Flag:DecodeFromJson(json_data)
    local flag = Flag.new()
    local r = string.split(json_data, ",")
    local form_index,form_color_index_1,form_color_index_2,graphic_index,graphic_color_index = unpack(r)
    flag.form_index,flag.form_color_index_1,flag.form_color_index_2,flag.graphic_index,flag.graphic_color_index = 
        tonumber(form_index),tonumber(form_color_index_1),tonumber(form_color_index_2),tonumber(graphic_index),tonumber(graphic_color_index)
    return flag
end



return Flag


