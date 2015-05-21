local GameUINpc = import(".GameUINpc")
local GameUIFteDragonEyrieMain = UIKit:createUIClass("GameUIFteDragonEyrieMain", "GameUIDragonEyrieMain")


function GameUIFteDragonEyrieMain:ctor(...)
    local dragon_type
    for k,v in pairs(DataManager:getUserData().dragons) do
        if v.star > 0 then
            dragon_type = k
        end
    end
    local city,building,default_tab,lockDragon = ...
    GameUIFteDragonEyrieMain.super.ctor(self, city,building,default_tab,lockDragon, dragon_type)
    self.__type  = UIKit.UITYPE.BACKGROUND
end


-- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
local DiffFunction = import("..utils.DiffFunction")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteDragonEyrieMain:FindHateBtn()
    return self.hate_button
end
function GameUIFteDragonEyrieMain:FindGarrisonBtn()
    return self.garrison_button
end
function GameUIFteDragonEyrieMain:PromiseOfFte()
    local p = cocos_promise.defer()
    if not check("HateDragon") then
        p:next(function()
            return self:PromiseOfHate()
        end)
    end
    if not check("DefenceDragon") then
        p:next(function()
            return GameUINpc:PromiseOfSay(
                {words = _("不可思议，传说是真的？！觉醒者过让能够号令龙族。。。大人您真是厉害！"), brow = "shy"}
            ):next(function()
                return GameUINpc:PromiseOfLeave()
            end):next(function()
                return self:PormiseOfDefence()
            end):next(function()
                return self:PromsieOfExit("GameUIFteDragonEyrieMain")
            end)
        end)
    end
    return p
end
function GameUIFteDragonEyrieMain:PromiseOfHate()
    local r = self:FindHateBtn():getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self:FindHateBtn())
    WidgetFteArrow.new(_("点击按钮：孵化")):addTo(self:GetFteLayer())
    :TurnUp():pos(r.x + r.width/2, r.y - 40)

    self:FindHateBtn():removeEventListenersByEvent("CLICKED_EVENT")
    self:FindHateBtn():onButtonClicked(function()
        self:FindHateBtn():setButtonEnabled(false)
        self:DestroyFteLayer()
        mockData.HateDragon()
    end)

    return self.dragon_manager:PromiseOfHate()
end
function GameUIFteDragonEyrieMain:PormiseOfDefence()
    self:FindGarrisonBtn():setTouchSwallowEnabled(true)
    self:GetFteLayer():SetTouchObject(self:FindGarrisonBtn())

    self:FindGarrisonBtn():removeEventListenersByEvent("CLICKED_EVENT")
    self:FindGarrisonBtn():onButtonClicked(function()
        self:FindGarrisonBtn():setButtonEnabled(false)
        mockData.DefenceDragon()
    end)

    local r = self:FindGarrisonBtn():getCascadeBoundingBox()
    WidgetFteArrow.new(_("点击设置：巨龙在城市驻防，如果敌军入侵，巨龙会自动带领士兵进行防御"))
        :addTo(self:GetFteLayer()):TurnUp(false):align(display.LEFT_TOP, r.x + 30, r.y - 20)

    return self.dragon_manager:PromiseOfDefence():next(function()
        self:FindGarrisonBtn():setButtonEnabled(false)
        self:DestroyFteLayer()
    end)
end



return GameUIFteDragonEyrieMain
