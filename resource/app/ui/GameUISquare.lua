--
-- Author: Kenny Dai
-- Date: 2015-05-13 09:29:12
--
local window = import("..utils.window")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetSoldierDetails = import('..widget.WidgetSoldierDetails')
local WidgetUIBackGround = import('..widget.WidgetUIBackGround')
local SoldierManager = import('..entity.SoldierManager')

local GameUISquare = UIKit:createUIClass("GameUISquare", "GameUIWithCommonHeader")


function GameUISquare:ctor(city)
    GameUISquare.super.ctor(self,city, _("广场"))

    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_RECRUIT")
end
function GameUISquare:OnMoveInStage()
    GameUISquare.super.OnMoveInStage(self)
    self:CreateSoldierUI()
    self.city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
    self.city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
end
function GameUISquare:onExit()
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
    GameUISquare.super.onExit(self)
end
function GameUISquare:CreateSoldierUI()
    local soldier_manager = self.city:GetSoldierManager()
    local view = self:GetView()
    if self.soldier_map then
        for k,v in pairs(self.soldier_map) do
            v:removeFromParent(true)
        end
    end
    self.soldier_map = {}
    local view_size = view:getContentSize()
    local total_width = 600
    local unit_width = 130
    local unit_height = 166
    local origin_y = window.top_bottom - 160
    local origin_x = window.left + 40 + unit_width/2
    local gap_x = (total_width - unit_width * 4 - 20 * 2) / 3
    local add_count = 0
    local total_citizen = 0
    for i, soldier_name in ipairs({
        "swordsman", "ranger", "lancer", "catapult",
        "sentinel", "crossbowman", "horseArcher", "ballista",
        "skeletonWarrior", "skeletonArcher", "deathKnight", "meatWagon"
    }) do
        local soldier_star =  soldier_manager:GetStarBySoldierType(soldier_name)
        local soldier_num =  soldier_manager:GetSoldierMap()[soldier_name]
        if soldier_num > 0 then
            self.soldier_map[soldier_name] = WidgetSoldierBox.new(nil, function()
                WidgetSoldierDetails.new(soldier_name, soldier_star):addTo(self)
            end):addTo(view)
                :alignByPoint(cc.p(0.5, 0.5), origin_x + (unit_width + gap_x) * (add_count % 4) , origin_y - math.floor(add_count/4) *(unit_height + 10))
                :SetSoldier(soldier_name, soldier_star)
                :SetNumber(soldier_num)
            add_count = add_count + 1
            display.newSprite("i_icon_20x20.png"):addTo(self.soldier_map[soldier_name]):pos(40,-22)

            total_citizen = total_citizen + soldier_manager:GetSoldierConfig(soldier_name).citizen * soldier_num
        end
    end

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
function GameUISquare:OnSoliderCountChanged( soldier_manager,changed_map )
    self:CreateSoldierUI()
end
function GameUISquare:OnSoldierStarEventsChanged()
    self:CreateSoldierUI()
end
return GameUISquare






