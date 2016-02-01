local cocos_promise = import("..utils.cocos_promise")
local utf8 = import("..utils.utf8")
local promise = import("..utils.promise")
local window = import("..utils.window")
local WidgetMaskFilter = import("..widget.WidgetMaskFilter")
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
    self.btn = cc.ui.UIPushButton.new({normal = "+_red.png",pressed = "+_red.png"}, nil, {})
        :setButtonSize(display.width,display.height):align(display.LEFT_BOTTOM)
        :addTo(self):setOpacity(0)
    self.leave_callbacks = {}
    self.__type  = UIKit.UITYPE.BACKGROUND
    self:InitDialog(...)
end
function GameUINpc:InitDialog(...)
    self.dialog_index = 1
    self.dialog = {...}
    self.dialog_clicked_callbacks = {}
    local dialog_index_callbacks = {
        [0] = {}
    }
    for i, dialog in ipairs(self.dialog) do
        self.dialog_clicked_callbacks[i] = {}
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
        dialog.brow = dialog.brow
    end
    self.dialog_index_callbacks = dialog_index_callbacks
end
function GameUINpc:OnMoveInStage()
    GameUINpc.super.OnMoveInStage(self)
    self:setLocalZOrder(3001)
    self.ui_map = self:BuildUI()
    self:StartDialog()
    self:RefreshNpc(self:CurrentDialog())
    self.btn:onButtonClicked(function()
        self:OnClick()
    end)
end
function GameUINpc:onExit()
    self:OnLeave()
    GameUINpc.super.onExit(self)
end
function GameUINpc:StartDialog()
    self:ShowWords(self:CurrentDialog())
    return self
end
function GameUINpc:OnClick()
    if self.label and self.label:getActionByTag(LETTER_ACTION) then
        self:ShowWords(self:CurrentDialog(), false)
        self:OnDialogEnded(self.dialog_index)
    else
        local index = self.dialog_index
        self:NextDialog()
        self:OnDialogClicked(index)
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
    if self.npc_brow ~= dialog.brow then
        self.npc_brow = dialog.brow
        if self.npc_brow then
            self.ui_map.woman:getAnimation():play(self.npc_brow, -1, 0)
        else
            self.ui_map.woman:getAnimation():playWithIndex(0, -1, 0)
        end
    end
    self:RefreshNpc(dialog)
    self.label = self:CreateLabel()
    self.label:setString(dialog.real_words or "")
    self.label:updateContent()
    self:hide_letter(self.label)
    self:show_letter(self.label, ani == nil and true or ani)
end
function GameUINpc:RefreshNpc(dialog)
    if dialog.npc == "man" then
        self.ui_map.man:show()
        self.ui_map.woman:hide()
    else
        self.ui_map.man:hide()
        self.ui_map.woman:show()
    end
end
function GameUINpc:Reset()
    self.dialog = {}
    self.dialog_index = 1
    self.dialog_index_callbacks = {}
    self.dialog_clicked_callbacks = {}
    self.leave_callbacks = {}
    if self.label then
        self.label:removeFromParent()
        self.label = nil
    end
end
function GameUINpc:CreateLabel()
    local size = self.ui_map.dialog_bg:getContentSize()
    local label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0xffedae,
    }):addTo(self.ui_map.dialog_bg):align(display.LEFT_TOP, size.width / 2 - 20, size.height - 40)
    label:setLineBreakWithoutSpace(true)
    label:setMaxLineWidth(300)
    return label
end
function GameUINpc:OnDialogClicked(index)
    local callbacks = self.dialog_clicked_callbacks[index]
    if callbacks and #callbacks > 0 then
        table.remove(callbacks, 1)()
    end
end
function GameUINpc:PromiseOfDialogEndWithClicked(index)
    local p = promise.new()
    local callbacks = self.dialog_clicked_callbacks[index]
    assert(#callbacks == 0)
    table.insert(callbacks, function()
        return p:resolve(self)
    end)
    return p
end
function GameUINpc:OnDialogEnded(index)
    if type(self.dialog[index].callback) == "function" then
        self.dialog[index].callback(self)
    end
    local callbacks = self.dialog_index_callbacks[index]
    if callbacks and #callbacks > 0 then
        table.remove(callbacks, 1)()
    end
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
function GameUINpc:PromiseOfSay(...)
    local instance
    if UIKit:getRegistry().isObjectExists("GameUINpc") then
        instance = UIKit:getRegistry().getObject("GameUINpc")
        instance:Reset()
        instance:InitDialog(...)
        instance:StartDialog()
    else
        instance = UIKit:newGameUI('GameUINpc', ...):AddToCurrentScene(true)
    end
    return instance:PromiseOfDialogEndWithClicked(#{...})
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
        instance.leave_callbacks = {}
        table.insert(instance.leave_callbacks, function()
            return p:resolve()
        end)
        instance:LeftButtonClicked()
        return p
    end
    return cocos_promise.defer()
end
function GameUINpc:BuildUI()
    local ui_map = {}
    ui_map.background = WidgetMaskFilter.new():addTo(self):pos(display.cx, display.cy)
    ui_map.dialog_bg = display.newSprite("fte_background.png")
        :addTo(self):align(display.CENTER_BOTTOM, display.cx, 0)
    local size = ui_map.dialog_bg:getContentSize()

    ui_map.next = display.newSprite("fte_next_arrow.png"):addTo(ui_map.dialog_bg)
        :align(display.CENTER_BOTTOM, size.width - 50, 20)
    ui_map.next:runAction(cc.RepeatForever:create(transition.sequence{
        cc.MoveBy:create(0.4, cc.p(5, 0)),
        cc.MoveBy:create(0.4, cc.p(-5, 0))
    }))
    
    ui_map.woman = ccs.Armature:create("npc_nv"):addTo(ui_map.dialog_bg)
        :align(display.BOTTOM_CENTER, 130, 0):hide()
    ui_map.man = display.newSprite("npc_man.png"):addTo(ui_map.dialog_bg)
        :align(display.BOTTOM_CENTER, 130, 0):hide()
    return ui_map
end

return GameUINpc








