
local UIListView = import('.UIListView')
local window = import('..utils.window')
local WidgetSoldierDetails = import('..widget.WidgetSoldierDetails')
local WidgetSoldierBox = import('..widget.WidgetSoldierBox')
local GameUIArmyCamp = UIKit:createUIClass('GameUIArmyCamp',"GameUIUpgradeBuilding")

GameUIArmyCamp.SOLDIERS_NAME = {
    [1] = "swordsman",
    [2] = "ranger",
    [3] = "lancer",
    [4] = "catapult",
    [5] = "sentinel",
    [6] = "crossbowman",
    [7] = "horseArcher",
    [8] = "ballista",
    [9] = "skeletonWarrior",
    [10] = "skeletonArcher",
    [11] = "deathKnight",
    [12] = "meatWagon",
-- [13] = "priest",
-- [14] = "demonHunter",
-- [15] = "paladin",
-- [16] = "steamTank",
}

function GameUIArmyCamp:ctor(city,building)
    GameUIArmyCamp.super.ctor(self,city,_("军用帐篷"),building)
end

function GameUIArmyCamp:CreateBetweenBgAndTitle()
    GameUIArmyCamp.super.CreateBetweenBgAndTitle(self)

    -- 加入军用帐篷info_layer
    self.info_layer = display.newLayer()
    self:addChild(self.info_layer)
end

function GameUIArmyCamp:onEnter()
    GameUIArmyCamp.super.onEnter(self)
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "info",
        },
    },function(tag)
        if tag == 'info' then
            self.info_layer:setVisible(true)
        else
            self.info_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)

    self:CreateTopPart()
    self:CresteSoldiersListView()
    -- self:OpenSoldierDetails()
end

function GameUIArmyCamp:CreateTopPart()
    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("部队总人口"),
            font = UIKit:getFontFilePath(),
            size = 18,
            color = UIKit:hex2c3b(0x665f49)
        }):align(display.LEFT_CENTER, display.cx-260, display.top-130)
        :addTo(self.info_layer)
    -- Total Troops Population 当前数值
    self.total_troops =  cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = City:GetSoldierManager():GetTotalSoldierCount(),
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0x29261c)
        }):align(display.LEFT_CENTER, display.cx-260, display.top-160)
        :addTo(self.info_layer)
    -- 维护费部分
    display.newSprite("res_food_91x74.png", display.cx+160, display.top-145):addTo(self.info_layer):setScale(0.5)
    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("维护费"),
            font = UIKit:getFontFilePath(),
            size = 18,
            color = UIKit:hex2c3b(0x7f775f)
        }):align(display.RIGHT_CENTER, display.cx+260, display.top-130)
        :addTo(self.info_layer)
    self.maintenance_cost = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = City:GetSoldierManager():GetTotalUpkeep(),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x930000)
        }):align(display.RIGHT_CENTER, display.cx+260, display.top-160)
        :addTo(self.info_layer)

    -- 分割线显示部分
    -- 构造分割线显示信息方法
    local function createTipItem(prams)
        -- 分割线
        local line = display.newScale9Sprite("dividing_line.png",prams.x, prams.y, cc.size(520,2))

        -- title
        cc.ui.UILabel.new(
            {
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = prams.title,
                font = UIKit:getFontFilePath(),
                size = 20,
                color = prams.title_color
            }):align(display.LEFT_CENTER, 0, 12)
            :addTo(line)
        -- title value
        line.value = cc.ui.UILabel.new(
            {
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = prams.value,
                font = UIKit:getFontFilePath(),
                size = 20,
                color = prams.value_color
            }):align(display.RIGHT_CENTER, line:getCascadeBoundingBox().size.width, 12)
            :addTo(line)
        return line
    end

    -- 空闲部队人口
    self.free_troops = createTipItem({
        title = _("驻防部队人口"),
        title_color = UIKit:hex2c3b(0x615b44),
        value = City:GetSoldierManager():GetGarrisonSoldierCount(),
        value_color = UIKit:hex2c3b(0x403c2f),
        x = display.cx,
        y = display.top - 220
    }):addTo(self.info_layer)
    -- 驻防部队人口
    self.garrison_troops = createTipItem({
        title = _("出征部队人口"),
        title_color = UIKit:hex2c3b(0x615b44),
        value = City:GetSoldierManager():GetMarchSoldierCount() ,
        value_color = UIKit:hex2c3b(0x403c2f),
        x = display.cx,
        y = display.top - 260
    }):addTo(self.info_layer)
end

-- BEGIN set 各项数值方法
-- 部队总人口
function GameUIArmyCamp:SetTotalTroopsPop()
    self.total_troops:setString()
end
-- 维护费
function GameUIArmyCamp:SetMaintenanceCost()
    self.maintenance_cost:setString()
end
-- 空闲部队人口
function GameUIArmyCamp:SetFreeTroopsPop()
    self.free_troops:setString()
end
-- 驻防部队总人口
function GameUIArmyCamp:SetGarrisonTroopsPop()
    self.garrison_troops:setString()
end
--END set 各项数值方法

function GameUIArmyCamp:OpenSoldierDetails(soldier_type, star)
    self.soldier_details_layer = WidgetSoldierDetails.new(soldier_type,star)
    self:addChild(self.soldier_details_layer)
end

function GameUIArmyCamp:CresteSoldiersListView()
    self.soldiers_listview = UIListView.new{
        -- bgColor = cc.c4b(200, 200, 0, 170),
        bgScale9 = true,
        viewRect = cc.rect(display.cx-274, display.top-870, 547, 600),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
        :addTo(self.info_layer)
    self:CreateItemWithListView(self.soldiers_listview)
end

function GameUIArmyCamp:CreateItemWithListView(list_view)
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    -- local widget_rect = self.widget:getBoundingBox()
    local unit_width = 130
    local gap_x = (547 - unit_width * 4) / 3
    local row_item = display.newNode()
    local soldier_map = City:GetSoldierManager():GetSoldierMap()
    local row_count = -1
    for i,soldier_name in pairs(GameUIArmyCamp.SOLDIERS_NAME) do
        print("index ===",i," soldier name = ",soldier_name)
        if soldier_name~="skeletonWarrior"
            and soldier_name~="skeletonArcher"
            and soldier_name~="deathKnight"
            and soldier_name~="meatWagon"
        then
            -- local soldier_name = v
            local soldier_number = soldier_map[soldier_name]
            row_count = row_count+1
            local soldier = WidgetSoldierBox.new("",function ()
                if soldier_number>0 then
                    if soldier_name=="skeletonWarrior"
                        or soldier_name=="skeletonArcher"
                        or soldier_name=="deathKnight"
                        or soldier_name=="meatWagon"
                    then
                        self:OpenSoldierDetails(soldier_name)
                    else
                        self:OpenSoldierDetails(soldier_name,City:GetSoldierManager():GetStarBySoldierType(soldier_name))
                    end
                end
            end):addTo(row_item)
                :alignByPoint(cc.p(0.5,0.4), origin_x + (unit_width + gap_x) * row_count + unit_width / 2, 0)
                :SetNumber(soldier_number)
            if soldier_name=="skeletonWarrior"
                or soldier_name=="skeletonArcher"
                or soldier_name=="deathKnight"
                or soldier_name=="meatWagon"
            then
                soldier:SetSoldier(soldier_name)
            else
                soldier:SetSoldier(soldier_name,1)
            end
            if row_count>2 then
                local item = list_view:newItem()
                item:addContent(row_item)
                item:setItemSize(547, 170)
                list_view:addItem(item)
                row_count=-1
                row_item = display.newNode()
            end
        end

    end
    list_view:reload()
end

return GameUIArmyCamp



















