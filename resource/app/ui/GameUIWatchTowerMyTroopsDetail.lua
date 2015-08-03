--
-- Author: Danny He
-- Date: 2015-05-06 14:39:34
--

local GameUIWatchTowerMyTroopsDetail = UIKit:createUIClass("GameUIWatchTowerMyTroopsDetail","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
local StarBar = import(".StarBar")
local UILib = import(".UILib")

GameUIWatchTowerMyTroopsDetail.ITEM_TYPE = Enum("DRAGON_INFO","DRAGON_EQUIPMENT","DRAGON_SKILL","SOLIDERS","TECHNOLOGY","BUFF_EFFECT")
local titles = {
    DRAGON_EQUIPMENT = _("龙的装备"),
    DRAGON_SKILL = _("龙的技能"),
    SOLIDERS = _("军事单位"),
    TECHNOLOGY = _("军事科技水平"),
    BUFF_EFFECT = _("战争增益"),
}
function GameUIWatchTowerMyTroopsDetail:ctor(entity)
    GameUIWatchTowerMyTroopsDetail.super.ctor(self)
    self.dragon_manager = City:GetDragonEyrie():GetDragonManager()
    self.entity = entity
    self.data = clone(entity:WithObject())
end


function GameUIWatchTowerMyTroopsDetail:GetDragon()

    local dragon_type = self:GetData().dragon.type
    return self.dragon_manager:GetDragon(dragon_type)
end


function GameUIWatchTowerMyTroopsDetail:onEnter()
    GameUIWatchTowerMyTroopsDetail.super.onEnter(self)
    self.backgroundImage = WidgetUIBackGround.new({height=718})
    self.backgroundImage:pos((display.width - self.backgroundImage:getContentSize().width)/2,window.bottom_top + 106)
    self:addTouchAbleChild(self.backgroundImage)
    local title_bar = display.newSprite("title_blue_600x56.png")
        :addTo(self.backgroundImage)
        :align(display.CENTER_BOTTOM, 304, 704)
    UIKit:closeButton():addTo(title_bar)
        :align(display.BOTTOM_RIGHT,title_bar:getContentSize().width, 0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    self.title_label = UIKit:ttfLabel({
        text = _("部队详情"),
        size = 24,
        color = 0xffedae,
    }):align(display.CENTER,title_bar:getContentSize().width/2, title_bar:getContentSize().height/2)
        :addTo(title_bar)

    local listBg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(568,648),cc.rect(15,10,538,100))
        :align(display.CENTER_BOTTOM, self.backgroundImage:getContentSize().width/2, 30)
        :addTo(self.backgroundImage)

    self.listView = UIListView.new {
        viewRect = cc.rect(10, 12, 548,624),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(listBg)
    if self:GetEntity():GetTypeStr() == 'HELPTO' then
        self:RequestPlayerHelpedByTroops()
    else
        self:RefreshListView()
    end
end

function GameUIWatchTowerMyTroopsDetail:RequestPlayerHelpedByTroops()
    NetManager:getHelpDefenceTroopDetailPromise(self:GetData().beHelpedPlayerData.id,User:Id()):done(function(response)
        self.data = response.msg.troopDetail
        self:RefreshListView()
    end)
end

function GameUIWatchTowerMyTroopsDetail:GetData()
    local type_str = self:GetEntity():GetTypeStr()
    if	type_str == 'MARCH_OUT'
        or type_str == 'MARCH_RETURN'
        or type_str == 'STRIKE_OUT'
        or type_str == 'STRIKE_RETURN' then

        return self.data.attackPlayerData
    elseif type_str == 'COLLECT' then
        return self.data.playerData
    elseif type_str == 'SHIRNE' then
        for __,v in ipairs(self:GetEntity():WithObject().playerTroops) do
            if v.id == User:Id() then
                self.data = clone(v)
                break
            end
        end
        return self.data
    else
        return self.data
    end
end

function GameUIWatchTowerMyTroopsDetail:GetEntity()
    return self.entity
end

function GameUIWatchTowerMyTroopsDetail:onCleanup()
    self.data = nil
    self.entity = nil
    self.dragon_manager = nil
    GameUIWatchTowerMyTroopsDetail.super.onCleanup(self)
end

function GameUIWatchTowerMyTroopsDetail:RefreshListView()
    self.listView:removeAllItems()
    local item = self:GetItem(self.ITEM_TYPE.DRAGON_INFO,self:GetData())
    self.listView:addItem(item)
    local type_str = self:GetEntity():GetTypeStr()
    item = self:GetItem(self.ITEM_TYPE.SOLIDERS,self:GetData())
    self.listView:addItem(item)
    self.listView:reload()
end

function GameUIWatchTowerMyTroopsDetail:GetItem(ITEM_TYPE,item_data)
    local item = self.listView:newItem()
    local height,sub_line = 0,0
    if ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO then
        sub_line = 3
        height   = sub_line * 38
    elseif ITEM_TYPE == self.ITEM_TYPE.SOLIDERS then
        if not item_data.soldiers then
            sub_line = 0
        else
            table.sort( item_data.soldiers, function(a,b)
                return a.count < b.count
            end)
            sub_line = #item_data.soldiers
        end
        height   = sub_line * 36
    end
    local bg = display.newScale9Sprite("transparent_1x1.png"):size(548,height + 38)
    local title_bar = display.newSprite("alliance_member_title_548x38.png"):addTo(bg):align(display.LEFT_TOP, 0, height + 38)
    if ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO then
        local dragon = self:GetDragon()
        local dragon_name = Localize.dragon[dragon:Type()] or '?'
        UIKit:ttfLabel({
            text = dragon_name,
            size = 20,
            color= 0xffedae
        }):align(display.LEFT_CENTER, 20, 19):addTo(title_bar)
        local star_bar = StarBar.new({
            max = 4,
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = dragon:Star(),
        }):addTo(title_bar):align(display.RIGHT_CENTER,538,19)
        local y = 0
        local dragon_hp = dragon:Hp() .. "/" .. dragon:GetMaxHP()
        self:GetSubItem(ITEM_TYPE,1,{_("生命值"),dragon_hp}):addTo(bg):align(display.RIGHT_BOTTOM, 547, y)
        y = y + 38
        local dragon_strength = dragon:TotalStrength()
        self:GetSubItem(ITEM_TYPE,2,{_("力量"),dragon_strength}):addTo(bg):align(display.RIGHT_BOTTOM, 547, y)
        y = y + 38
        local dragon_level = dragon:Level()
        self:GetSubItem(ITEM_TYPE,3,{_("等级"),dragon_level}):addTo(bg):align(display.RIGHT_BOTTOM, 547, y)
        local dragon_png = UILib.dragon_head[dragon:Type()]
        if dragon_png then
            local icon_bg = display.newSprite("dragon_bg_114x114.png", 65, 60):addTo(bg):scale(98/114)
            display.newSprite(dragon_png, 57, 60):addTo(icon_bg)
        else
            display.newSprite("unknown_dragon_icon_112x112.png", 65, 60):addTo(bg):scale(98/112)
        end
    else
        UIKit:ttfLabel({
            text = titles[self.ITEM_TYPE[ITEM_TYPE]],
            size = 20,
            color= 0xffedae,
        }):addTo(title_bar):align(display.CENTER, 274, 19)
        if ITEM_TYPE == self.ITEM_TYPE.SOLIDERS  and item_data.soldiers then
            local y = 0
            for i,v in ipairs(item_data.soldiers) do
                local name = Localize.soldier_name[v.name]
                self:GetSubItem(ITEM_TYPE,i,{name,v.count,v.star or City:GetSoldierManager():GetStarBySoldierType(v.name)}):addTo(bg):align(display.LEFT_BOTTOM,0, y)
                y = y + 36
            end
        end
    end
    item:addContent(bg)
    item:setItemSize(548,height + 38)
    return item
end

function GameUIWatchTowerMyTroopsDetail:GetSubItem(ITEM_TYPE,index,item_data)
    local height = ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO and 38 or 36
    local width  = ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO and 420 or 546
    local item = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", (index - 1) % 2 == 0 and 1 or 2)):size(width,height)
    local title_label = UIKit:ttfLabel({
        text = item_data[1],
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_CENTER, 12, 19):addTo(item)
    if ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO then
        local val_label = UIKit:ttfLabel({
            text = item_data[2],
            size = 20,
            color= 0x403c2f
        }):align(display.LEFT_CENTER, title_label:getPositionX()+title_label:getContentSize().width + 20, 19):addTo(item)
    elseif ITEM_TYPE == self.ITEM_TYPE.SOLIDERS then
        local val_label = UIKit:ttfLabel({
            text = item_data[2],
            size = 20,
            color= 0x403c2f
        }):align(display.RIGHT_CENTER,526, 19):addTo(item)
        StarBar.new({
            max = 3,
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = item_data[3],
        }):addTo(item):align(display.LEFT_CENTER,12, 19):scale(0.8)
        title_label:setPositionX(90)
    end
    return item
end

return GameUIWatchTowerMyTroopsDetail


