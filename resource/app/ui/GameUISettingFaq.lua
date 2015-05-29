--
-- Author: Danny He
-- Date: 2015-02-24 18:14:14
--
local GameUISettingFaq = UIKit:createUIClass("GameUISettingFaq")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIScrollView = import(".UIScrollView")

function GameUISettingFaq:onEnter()
	GameUISettingFaq.super.onEnter(self)
	self:CreateBackGround()
    self:CreateTitle(_("遇到问题"))
    self.home_btn = self:CreateHomeButton()
    local gem_button = cc.ui.UIPushButton.new({
    	normal = "contact_n_148x60.png", pressed = "contact_h_148x60.png"
    }):onButtonClicked(function(event)
       	UIKit:newGameUI("GameUISettingContactUs"):AddToCurrentScene(true)
    end):addTo(self):setButtonLabel("normal", UIKit:commonButtonLable({
    	text = _("联系我们"),
    }))
    gem_button:align(display.RIGHT_TOP, window.cx+314, window.top-5)
    self:BuildUI()
end

function GameUISettingFaq:BuildUI()
    local function onEdit(event, editbox)
        if event == 'ended' then
            local keyword = string.trim(editbox:getText())
            self.list_data = self:GetAllListData(string.len(keyword) > 0 and keyword or nil)
            self:RefreshListView()
        end
    end
    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(548,57),
        listener = onEdit,
    })
    editbox:setPlaceHolder(_("描述你的问题"))
    editbox:setMaxLength(140)
    editbox:setFont(UIKit:getEditBoxFont(),18)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_SEARCH)
    editbox:align(display.CENTER_TOP,window.cx,window.top - 100):addTo(self)
    self.editbox = editbox

    local list,list_node = UIKit:commonListView({
        direction = UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,562,740),
        -- bgColor = UIKit:hex2c4b(0x7a000000),
    })
    list_node:addTo(self):pos(window.left + 40,window.bottom+30)
    self.list_view = list
    list:onTouch(handler(self, self.listviewListener))
    self.list_data = self:GetAllListData()
    self:RefreshListView()
end

function GameUISettingFaq:GetAllListData(filter)
    local orgin_data = {
        {
            title = "怎么玩",
            content = "怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩"
        },
        {
            title = "怎么玩",
            content = "怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩怎么玩"
        },
    }
    if filter then
        return LuaUtils:table_filteri(orgin_data,function(k,v)
            return string.match(string.lower(v.title),string.lower(filter)) or string.match(string.lower(v.content),string.lower(filter))
        end)
    else
        return orgin_data
    end
end

function GameUISettingFaq:RefreshListView()
    self.list_view:removeAllItems()
    for __,v in ipairs(self.list_data ) do
        local item = self:GetItem(v)
        self.list_view:addItem(item)
    end
    self.list_view:reload()
end


function GameUISettingFaq:listviewListener(event)
    if "clicked" == event.name then
        local data = self.list_data[event.itemPos]
        if not data then return end
        UIKit:newGameUI("GameUISettingFaqDetail", data):AddToCurrentScene(true)
    end
end
function GameUISettingFaq:GetItem(data)
    local item = self.list_view:newItem()
    local content = display.newScale9Sprite("back_ground_568x110.png"):size(562,84)
    local box = display.newSprite("faq_item_box_548x72.png"):addTo(content):align(display.LEFT_BOTTOM, 8, 5)
    UIKit:ttfLabel({
        text = data.title,
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_CENTER,22,36):addTo(box)
    display.newSprite("next_32x38.png"):align(display.RIGHT_CENTER, 524, 36):addTo(box)
    item:addContent(content)
    item:setItemSize(562,84)
    return item
end

return GameUISettingFaq