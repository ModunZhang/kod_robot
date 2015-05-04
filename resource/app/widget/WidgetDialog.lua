local promise = import("..utils.promise")
local utf8 = import("..utils.utf8")
local WidgetDialog = class("WidgetDialog", function()
    return display.newNode()
end)

local LETTER_ACTION = 1001
local function compute_str_len(strarray)
    local count = 0
    for i = 1, #strarray do
        count = count + utf8.len(strarray[i])
    end
    return count
end
local function mark_key_word(s, e, key_word, keyword_map)
    for i = s, e do
        keyword_map[i] = key_word
    end
end
function WidgetDialog:ctor(...)
    self.bg = display.newSprite("alliance_search_item_bg_608x164.png")
    :addTo(self):align(display.CENTER, 0, 0)
    self:InitDialog(...)
    self.leave_callbacks = {}
    self.bg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "ended" then
            self:OnClick()
        end
        return true
    end)
    self.bg:setTouchEnabled(true)
    self.bg:setTouchSwallowEnabled(true)
end
function WidgetDialog:align(anchorPoint, x, y)
    self.bg:align(anchorPoint)
    if x and y then self:setPosition(x, y) end
    return self
end
function WidgetDialog:InitDialog(...)
    self.dialog_index = 1
    self.dialog = {...}
    local dialog_index_callbacks = {
        [0] = {}
    }
    for i, dialog in ipairs(self.dialog) do
        dialog_index_callbacks[i] = {}
        local keyword_map = {}
        local words = dialog.words
        local s_index
        local str_array = {}
        local begin_index = 1
        local end_index = 1
        while 1 do
            local b, _, _, ended = utf8.find(words, "{", s_index)
            if not b then
                local str = utf8.sub(words, begin_index, #words)
                if #str > 0 then table.insert(str_array, str) end
                break
            end
            end_index = b
            local str = utf8.sub(words, begin_index, end_index - begin_index)
            if #str > 0 then table.insert(str_array, str) end
            local e, _, _, ended = utf8.find(words, "}", ended + 1)
            if not e then assert(false) end
            begin_index = e + 1
            local key_word_len = e - b - 1
            local str = utf8.sub(words, b + 1, key_word_len)
            if #str > 0 then
                local start_index = compute_str_len(str_array) + 1
                mark_key_word(start_index, start_index + key_word_len - 1, str, keyword_map)
                table.insert(str_array, str)
            end
            s_index = ended + 1
        end
        dialog.real_words = table.concat(str_array, "")
        dialog.keyword_map = keyword_map
    end
    self.dialog_index_callbacks = dialog_index_callbacks
end
function WidgetDialog:CreateLabel()
    local label = UIKit:ttfLabel({
        text = "",
        size = 24,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
    }):addTo(self.bg):align(display.LEFT_TOP, 30, 140)
    label:setLineBreakWithoutSpace(true)
    label:setMaxLineWidth(350)
    return label
end
function WidgetDialog:OnClick()
    if self.label and self.label:getActionByTag(LETTER_ACTION) then
        self:ShowWords(self:CurrentDialog(), false)
    else
        self:NextDialog()
    end
end
function WidgetDialog:ShowWords(dialog, ani)
    if not dialog then return end
    if self.label then
        self.label:removeFromParent()
        self.label = nil
    end
    self.label = self:CreateLabel()
    self.label:setString(dialog.real_words or "")
    self.label:updateContent()
    self:hide_letter(self.label)
    self:show_letter(self.label, ani == nil and true or ani)
end
function WidgetDialog:CurrentDialog()
    return self.dialog[self.dialog_index]
end
function WidgetDialog:NextDialog()
    if self.dialog_index < #self.dialog then
        self.dialog_index = self.dialog_index + 1
        self:ShowWords(self:CurrentDialog())
    end
end
function WidgetDialog:CurrentDialog()
    return self.dialog[self.dialog_index]
end
function WidgetDialog:Reset()
    self.dialog = {}
    self.dialog_index = 1
    self.dialog_index_callbacks = {}
    self.leave_callbacks = {}
    if self.label then
        self.label:removeFromParent()
        self.label = nil
    end
end
function WidgetDialog:StartDialog()
    self:ShowWords(self:CurrentDialog())
end
function WidgetDialog:OnDialogEnded(index)
    local callbacks = self.dialog_index_callbacks[index]
    if callbacks and #callbacks > 0 then
        callbacks[1]()
        table.remove(callbacks, 1)
    end
end
function WidgetDialog:update_letter(letter, color, real_char)
    letter:setVisible(true)
    letter:setColor(color)
    if self:CurrentDialog().keyword_map[real_char] then
        letter:setColor(display.COLOR_RED)
        letter:setScale(1.1)
    end
end
function WidgetDialog:show_letter(label, animated)
    self:label_promise(label, animated):next(function()
        self:OnDialogEnded(self.dialog_index)
    end)
end
function WidgetDialog:hide_letter(label)
    for i = 0, label:getStringLength() - 1 do
        local cur_ = label:getLetter(i)
        if cur_ then
            cur_:setVisible(false)
        end
    end
end
function WidgetDialog:label_promise(label, animated)
    local p = promise.new()
    local color = label:getColor()
    local real_char = 1
    if animated then
        local i = 0
        label:schedule(function()
            local cur_ = label:getLetter(i)
            if cur_ then
                self:update_letter(cur_, color, real_char)
                real_char = real_char + 1
            end
            i = i + 1
            if i > label:getStringLength() - 1 then
                label:stopActionByTag(LETTER_ACTION)
                p:resolve()
            end
        end, 0.04):setTag(LETTER_ACTION)
    else
        for i = 0, label:getStringLength() - 1 do
            local cur_ = label:getLetter(i)
            if cur_ then
                self:update_letter(cur_, color, real_char)
                real_char = real_char + 1
            end
        end
        label:performWithDelay(function()
            p:resolve()
        end, 0)
    end
    return p
end
function WidgetDialog:PromiseOfDialogEnded(index)
    local p = promise.new()
    local callbacks = self.dialog_index_callbacks[index]
    assert(#callbacks == 0)
    table.insert(callbacks, function()
        return p:resolve(self)
    end)
    return p
end

return WidgetDialog

