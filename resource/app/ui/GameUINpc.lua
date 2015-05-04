local cocos_promise = import("..utils.cocos_promise")
local utf8 = import("..utils.utf8")
local promise = import("..utils.promise")
local window = import("..utils.window")
local GameUINpc = UIKit:createUIClass("GameUINpc")
local LETTER_ACTION = 1001

function GameUINpc:label_promise(label, animated)
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
function GameUINpc:hide_letter(label)
    for i = 0, label:getStringLength() - 1 do
        local cur_ = label:getLetter(i)
        if cur_ then
            cur_:setVisible(false)
        end
    end
end
function GameUINpc:update_letter(letter, color, real_char)
    letter:setVisible(true)
    letter:setColor(color)
    if self:CurrentDialog().keyword_map[real_char] then
        letter:setColor(display.COLOR_RED)
        letter:setScale(1.1)
    end
end
function GameUINpc:show_letter(label, animated)
    self:label_promise(label, animated):next(function()
        self:OnDialogEnded(self.dialog_index)
    end)
end
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
function GameUINpc:ctor(...)
    GameUINpc.super.ctor(self)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "ended" and not self.unenable then
            self:OnClick()
        end
        return true
    end)
    self:InitDialog(...)
    -- self.enter_callbacks = {}
    self.leave_callbacks = {}
end
function GameUINpc:InitDialog(...)
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
function GameUINpc:onEnter()
    GameUINpc.super.onEnter(self)
    self:setLocalZOrder(3001)
    self:setTouchSwallowEnabled(true)
    self:EnableReceiveClickMsg(true)
    
    local middle_x = display.cx - 100
    self.dialog_bg = display.newSprite("pop_tip_bg.png")
        :addTo(self):align(display.LEFT_BOTTOM, middle_x, 0)
    display.newSprite("npc_1.png"):addTo(self)
        :align(display.CENTER_BOTTOM, middle_x - 75, 0):scale(0.2)
    self:StartDialog()
end
function GameUINpc:onExit()
    GameUINpc.super.onExit(self)
    self:OnLeave()
end
function GameUINpc:StartDialog()
    self:ShowWords(self:CurrentDialog())
end
function GameUINpc:OnClick()
    if self.label and self.label:getActionByTag(LETTER_ACTION) then
        self:ShowWords(self:CurrentDialog(), false)
    else
        self:NextDialog()
    end
end
function GameUINpc:NextDialog()
    if self.dialog_index < #self.dialog then
        self.dialog_index = self.dialog_index + 1
        self:ShowWords(self:CurrentDialog())
    end
end
function GameUINpc:CurrentDialog()
    return self.dialog[self.dialog_index]
end
function GameUINpc:ShowWords(dialog, ani)
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
function GameUINpc:Reset()
    self.dialog = {}
    self.dialog_index = 1
    self.dialog_index_callbacks = {}
    -- self.enter_callbacks = {}
    self.leave_callbacks = {}
    if self.label then
        self.label:removeFromParent()
        self.label = nil
    end
end
function GameUINpc:CreateLabel()
    local label = UIKit:ttfLabel({
        text = "",
        size = 24,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
    }):addTo(self.dialog_bg):align(display.LEFT_TOP, 30, 140)
    label:setLineBreakWithoutSpace(true)
    label:setMaxLineWidth(350)
    -- label:setAdditionalKerning(1)
    return label
end
function GameUINpc:Wait()
    self:setTouchSwallowEnabled(false)
    self:EnableReceiveClickMsg(false)
end
function GameUINpc:ResumeToNextDialog()
    self:Resume()
    self:NextDialog()
end
function GameUINpc:Resume()
    self:setTouchSwallowEnabled(true)
    self:EnableReceiveClickMsg(true)
end
function GameUINpc:EnableReceiveClickMsg(enable)
    self.unenable = not enable
end
function GameUINpc:OnDialogEnded(index)
    local callbacks = self.dialog_index_callbacks[index]
    if callbacks and #callbacks > 0 then
        callbacks[1]()
        table.remove(callbacks, 1)
    end
end
function GameUINpc:PromiseOfActive()
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        UIKit:getRegistry().getObject("GameUINpc"):EnableReceiveClickMsg(true)
    end
    return cocos_promise.defer()
end
function GameUINpc:PromiseOfInActive()
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        UIKit:getRegistry().getObject("GameUINpc"):EnableReceiveClickMsg(false)
    end
    return cocos_promise.defer()
end
function GameUINpc:PromiseOfInput()
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        UIKit:getRegistry().getObject("GameUINpc"):setTouchSwallowEnabled(false)
    end
    return cocos_promise.defer()
end
function GameUINpc:PromiseOfLockInput()
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        UIKit:getRegistry().getObject("GameUINpc"):setTouchSwallowEnabled(true)
    end
    return cocos_promise.defer()
end
function GameUINpc:PromiseOfDialogEnded(index)
    local p = promise.new()
    local callbacks = self.dialog_index_callbacks[index]
    assert(#callbacks == 0)
    table.insert(callbacks, function()
        return p:resolve(self)
    end)
    return p
end
function GameUINpc:NextOfSay(...)
    local args = {...}
    return function() return GameUINpc:PromiseOfSay(unpack(args)) end
end
function GameUINpc:PromiseOfSay(...)
    local instance
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        instance = UIKit:getRegistry().getObject("GameUINpc")
        instance:Reset()
        instance:InitDialog(...)
        instance:StartDialog()
    else
        instance = UIKit:newGameUI('GameUINpc', ...):AddToCurrentScene(true)
        UIKit:newGameUI('GameUINpc', {words = "欢迎来到kod的世界, 在这里您将带头{冲锋}!"}):AddToScene(self, true)
    end
    return instance:PromiseOfDialogEnded(#{...})
end
function GameUINpc:OnLeave()
    local callbacks = self.leave_callbacks
    if #callbacks > 0 then
        callbacks[1]()
        table.remove(callbacks, 1)
    end
end
function GameUINpc:PromiseOfLeave()
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        local instance = UIKit:getRegistry().getObject("GameUINpc")
        local p = promise.new()
        local callbacks = instance.leave_callbacks
        assert(#callbacks == 0)
        table.insert(callbacks, function()
            return p:resolve()
        end)
        instance:LeftButtonClicked()
        return p
    end
    return cocos_promise.defer()
end
function GameUINpc:PromiseOfEnter()
    assert(false)
end

return GameUINpc




