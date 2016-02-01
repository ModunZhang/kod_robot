--
-- Author: Kenny Dai
-- Date: 2015-05-13 09:29:12
--
local window = import("..utils.window")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetSoldierDetails = import('..widget.WidgetSoldierDetails')
local WidgetUIBackGround = import('..widget.WidgetUIBackGround')

local GameUISquare = UIKit:createUIClass("GameUISquare", "GameUIWithCommonHeader")


function GameUISquare:ctor(city)
    GameUISquare.super.ctor(self,city, _("广场"))

    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_RECRUIT")
end
function GameUISquare:OnMoveInStage()
    GameUISquare.super.OnMoveInStage(self)
    self:CreateSoldierUI()
    local User = self.city:GetUser()
    User:AddListenOnType(self, "soldiers")
    User:AddListenOnType(self, "soldierStarEvents")
end
function GameUISquare:onExit()
    User:RemoveListenerOnType(self, "soldiers")
    User:RemoveListenerOnType(self, "soldierStarEvents")
    GameUISquare.super.onExit(self)
end
function GameUISquare:CreateSoldierUI()
    local User = self.city:GetUser()
    local view = self:GetView()
    if self.soldier_map then
        for k,v in pairs(self.soldier_map) do
            v:removeFromParent(true)
        end
    end
    self.soldier_map = {}
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,568,740),
    })
    list_node:addTo(view):align(display.BOTTOM_CENTER, window.cx, window.bottom + 40)
    local content = display.newNode()
    content:setContentSize(cc.size(568,7 * 166 + 6 * 10))
    local total_width = 568
    local unit_width = 130
    local unit_height = 166
    local origin_y = 7 * 166 + 6 * 10 - unit_height/2
    local origin_x =  unit_width/2
    local gap_x = (total_width - unit_width * 4) / 3
    local add_count = 0
    local total_citizen = 0
    for i, soldier_name in ipairs({
        "swordsman_1", "ranger_1", "lancer_1", "catapult_1",
        "sentinel_1", "crossbowman_1", "horseArcher_1", "ballista_1",
        "swordsman_2", "ranger_2", "lancer_2", "catapult_2",
        "sentinel_2", "crossbowman_2", "horseArcher_2", "ballista_2",
        "swordsman_3", "ranger_3", "lancer_3", "catapult_3",
        "sentinel_3", "crossbowman_3", "horseArcher_3", "ballista_3",
        "skeletonWarrior", "skeletonArcher", "deathKnight", "meatWagon",
    }) do
    
        local soldier_star = User:SoldierStarByName(soldier_name)
        local soldier_num =  User.soldiers[soldier_name]
        if soldier_num > 0 then
            self.soldier_map[soldier_name] = WidgetSoldierBox.new(nil, function()
                WidgetSoldierDetails.new(soldier_name, soldier_star):addTo(self)
            end):addTo(content)
                :alignByPoint(cc.p(0.5, 0.5), origin_x + (unit_width + gap_x) * (add_count % 4) , origin_y - math.floor(add_count/4) *(unit_height + 10))
                :SetSoldier(soldier_name, soldier_star)
                :SetNumber(soldier_num)
            add_count = add_count + 1

            total_citizen = total_citizen + User:GetSoldierConfig(soldier_name).citizen * soldier_num
        end
    end
    local item = list:newItem()
    item:setItemSize(568,7 * 166 + 6 * 10)
    item:addContent(content)
    list:addItem(item)
    list:reload()
    -- 士兵占用人口
    local bg = WidgetUIBackGround.new({width = 556,height = 58},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.TOP_CENTER, window.cx, window.top - 93)
        :addTo(view)
    UIKit:ttfLabel({
        text = _("部队总人口"),
        size = 22,
        color = 0x403c2f,
    }):addTo(bg)
        :align(display.LEFT_CENTER,30,bg:getContentSize().height/2)


    local citizen_label = UIKit:ttfLabel(
        {
            text = string.formatnumberthousands(total_citizen),
            size = 22,
            color = 0x28251d
        }):align(display.RIGHT_CENTER, bg:getContentSize().width-30, bg:getContentSize().height/2)
        :addTo(bg)
    cc.ui.UIImage.new("res_citizen_88x82.png")
        :align(display.RIGHT_CENTER,citizen_label:getPositionX() - citizen_label:getContentSize().width - 10, bg:getContentSize().height/2)
        :addTo(bg)
        :scale(0.4)
end
function GameUISquare:OnUserDataChanged_soldiers()
    self:CreateSoldierUI()
end
function GameUISquare:OnUserDataChanged_soldierStarEvents()
    self:CreateSoldierUI()
end
return GameUISquare






