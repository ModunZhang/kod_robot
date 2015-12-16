local utf8 = import("..utils.utf8")
local RichText = class("RichText", function()
    return display.newNode()
end)
local GameUtils = GameUtils
local LuaUtils = LuaUtils


local function get_first_line(label, width)
    label:setLineBreakWithoutSpace(true)
    label:setMaxLineWidth(width)

    local origin_str = label:getString()
    local len = utf8.len(origin_str)
    local char_index = 0
    while char_index < len do
        local next_index = char_index + 1
        if utf8.index(origin_str, next_index) == "\n" then
            return utf8.substr(origin_str, 1, char_index), utf8.sub(origin_str, char_index + 2), next_index == len
        end
        char_index = next_index
        if label:getLetter(char_index - 1) and not label:getLetter(char_index) and label:getLetter(char_index + 1) then
            break
        end
    end
    local next_index = char_index + 1
    if utf8.index(origin_str, char_index + 1) == "\n" then
        return utf8.substr(origin_str, 1, char_index), utf8.sub(origin_str, char_index + 2), next_index == len
    end
    return utf8.substr(origin_str, 1, char_index), utf8.sub(origin_str, char_index + 1)
end
function RichText:ctor(params)
    assert(params.width)
    self.width = params.width
    self.size = params.size or 30
    self.color = params.color or 0xffffff
    self.lineHeight = params.lineHeight or self.size
    self.url_handle = params.url_handle

    local label = UIKit:ttfLabel({
        text = "...",
        size = size,
        color = color,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
    }):align(display.LEFT_CENTER)
    self.ellipsis_width = label:getContentSize().width
    label:removeFromParent()
end
function RichText:Text(str, line , url_handle)
    if url_handle then
        self.url_handle = url_handle
    end
    -- assert(not self.lines, "富文本不可变!")
    if not str or string.len(str) == 0 then str = "[]" end
    line = line or math.huge
    self:removeAllChildren()
    local items = LuaUtils:table_map(json.decode(str) or {""}, function(k, v)
        local type_ = type(v)
        if type_ == "string" then
            return k, {type = "text", value = v, size = self.size}
        end
        return k, v
    end)
    local width = self.width
    local cur_x = 0
    local cur_y = 0
    local lines = {}
    local function getLine(line_number)
        if not lines[line_number] then
            lines[line_number] = display.newNode():addTo(self)
        end
        return lines[line_number]
    end
    local function curLine()
        return getLine(cur_y)
    end
    local function newLine()
        cur_x = 0
        cur_y = cur_y + 1
        curLine()
        width = cur_y ~= line and self.width or self.width - self.ellipsis_width
    end
    local function append_ellipsis(cur_width, size, color)
        lines[#lines]:removeFromParent()
        lines[#lines] = nil
        UIKit:ttfLabel({
            text = "...",
            size = size or self.size,
            color = color or self.color,
            align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        }):align(display.LEFT_CENTER):addTo(getLine(cur_y - 1)):pos(cur_width, 0)
    end
    newLine()
    for i, v in ipairs(items) do
        if cur_y > line then break end
        local url = v.url
        if v.type == "image" then
            local img = display.newSprite(v.value)
            local size = img:getContentSize()
            local w = v.width or self.size
            local h = v.height or self.lineHeight
            img:setScaleX(w / size.width)
            img:setScaleY(h / size.height)

            local line_width = cur_x
            if w > 5 + width - cur_x then newLine() end
            if cur_y > line then img:removeFromParent() append_ellipsis(line_width) break end

            self:AddUrlTo(img:align(display.CENTER, cur_x + w * 0.5, 0):addTo(curLine()), url)

            cur_x = cur_x + w

            local line_width = cur_x
            if cur_x > width then newLine() end
            if cur_y > line then append_ellipsis(line_width) break end
        elseif v.type == "text" then
            local head, tail, is_newline = v.value, ""
            local underLine = url or v.underLine
            local label_size = v.size or self.size
            local color = v.color or self.color
            repeat
                local line_width = cur_x
                if width - cur_x < label_size then newLine() end
                if cur_y > line then append_ellipsis(line_width, label_size, color) break end

                local label = UIKit:ttfLabel({
                    text = head,
                    size = label_size,
                    color = color,
                    align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
                }):align(display.LEFT_CENTER)
                head, tail, is_newline = get_first_line(label, width - cur_x)
                label:removeFromParent()

                local label = UIKit:ttfLabel({
                    text = head,
                    size = label_size,
                    color = color,
                    align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
                }):align(display.LEFT_CENTER, 0 + cur_x, 0)
                local size = label:getContentSize()
                if size.width == 0 or size.height == 0 then
                    label:removeFromParent()
                else
                    self:AddUrlTo(label:addTo(curLine()), url)
                end

                cur_x = cur_x + size.width
                head, tail = tail, ""
                local line_width = cur_x
                if #head > 0 or cur_x > width or is_newline then newLine() end
                if cur_y > line then append_ellipsis(line_width, label_size, color) break end
            until #head == 0
        end
    end
    self.lines = lines
    return self
end
function RichText:AddUrlTo(item, url)
    if not url then return end
    item:setTouchEnabled(true)
    item:setTouchSwallowEnabled(true)
    local origin_color = item:getColor()
    item:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        local name, x, y = event.name, event.x, event.y
        local is_in = item:getCascadeBoundingBox():containsPoint(cc.p(x,y))
        if name == "began" and is_in then
            item:setColor(cc.c3b(255, 255, 255) - origin_color)
        elseif name == "ended" then
            item:setColor(origin_color)
            if type(self.url_handle) == "function" and is_in then
                self.url_handle(url)
            end
        end
        return is_in
    end)
end
function RichText:align(anchorPoint, x, y)
    assert(self.lines, "必须先生成富文本!")
    local ANCHOR_POINTSint
    if not anchorPoint then
        ANCHOR_POINTSint = self:getAnchorPoint()
        x = self:getPositionX()
        y = self:getPositionY()
    else
        ANCHOR_POINTSint = display.ANCHOR_POINTS[anchorPoint]
    end
    local cur_height = 0
    local line_height = self.lineHeight
    for _, v in ipairs(self.lines) do
        local h = v:getCascadeBoundingBox().height
        v:pos(0, - cur_height - h * 0.5)
        h = h > line_height and h or line_height
        h = h == 0 and 10 or h
        cur_height = cur_height + h
    end

    local size = self:getCascadeBoundingBox()
    local offset_x = ANCHOR_POINTSint.x * size.width
    local offset_y = (1-ANCHOR_POINTSint.y) * size.height
    for _, v in ipairs(self.lines) do
        local x, y = v:getPosition()
        v:pos(x - offset_x, y + offset_y)
    end
    return self:pos(x, y)
end



return RichText











