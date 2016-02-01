local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local window = import("..utils.window")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIPveReward = class("GameUIPveReward", WidgetPopDialog)
local stages = GameDatas.PvE.stages

function GameUIPveReward:ctor(index, callback)
    self.index = index
    self.callback = callback
    GameUIPveReward.super.ctor(self,500,_("领取奖励"),window.top - 150)
end
function GameUIPveReward:onEnter()
    GameUIPveReward.super.onEnter(self)
    local size = self:GetBody():getContentSize()

    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0, 550, 400),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list.touchNode_:setTouchEnabled(false)
    list_node:addTo(self:GetBody()):pos(20, size.height - 460)



    for i = 1, 4 do
        local item = list:newItem()
        local content = self:GetListItem(i)
        item:addContent(content)
        item:setItemSize(600,100)
        list:addItem(item)
    end
    list:reload()
    self.list = list

    self:RefreshUI()
end
function GameUIPveReward:onExit()
    GameUIPveReward.super.onExit(self)
    if type(self.callback) == "function" then
        self.callback()
    end
end
function GameUIPveReward:GetListItem(index)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(600,100)

    local sbg = display.newSprite("tmp_pve_star_bg.png"):addTo(bg):pos(60,100*3/5):scale(0.7)
    local size = sbg:getContentSize()
    display.newSprite("tmp_pve_star.png"):addTo(sbg):pos(size.width/2, size.height/2)

    local stage_name = string.format("%d_%d", self.index, index)
    local stage = stages[stage_name]
    UIKit:ttfLabel({
        text = math.floor(tonumber(stage.needStar)),
        size = 20,
        color = 0x403c2f,
    }):addTo(bg):align(display.CENTER,60,100*1/4)

    for i,v in ipairs(string.split(stage.rewards, ",")) do
        local type,name,count = unpack(string.split(v, ":"))
        local png, txt
        if type == "items" then
            png = UILib.item[name]
            txt = Localize_item.item_name[name]
        elseif type == "soldierMaterials" then
            png = UILib.soldier_metarial[name]
            txt = Localize.soldier_material[name]
        end
        local icon = display.newSprite(png):addTo(
            display.newSprite("box_118x118.png"):addTo(bg)
                :pos(150 + (i-1) * 100, 50):scale(0.7)
        ):pos(118/2, 118/2):scale(100/128)
        display.newColorLayer(cc.c4b(0,0,0,128)):addTo(icon)
            :setContentSize(128, 40)
        UIKit:addTipsToNode(icon, txt,self)
        UIKit:ttfLabel({
            text = "x"..count,
            size = 18,
            color = 0xffedae,
        }):addTo(bg):align(display.CENTER, 150 + (i-1) * 100, 25)
    end


    bg.button = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png", disabled = 'gray_btn_148x58.png'}
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("领取") ,
        size = 24,
        color = 0xffedae,
        shadow = true
    })):addTo(bg):align(display.CENTER,548 - 60,100*1/2)
        :setButtonEnabled(User:GetStageStarByIndex(self.index) >= tonumber(stage.needStar) and not User:IsStageRewardedByName(stage_name))
        :onButtonClicked(function()
            self:CheckMaterials(function()
                NetManager:getPveStageRewardPromise(stage_name):done(function()
                    self:RefreshUI()
                    local str = {}
                    for i,v in ipairs(string.split(stage.rewards, ",")) do
                        local type,name,count = unpack(string.split(v, ":"))
                        if type == "items" then
                            table.insert(str, string.format("%s x%d", Localize_item.item_name[name], count))
                        elseif type == "soldierMaterials" then
                            table.insert(str, string.format("%s x%d", Localize.soldier_material[name], count))
                        end
                    end
                    GameGlobalUI:showTips(_("获得奖励"), table.concat(str, ", "))
                    app:GetAudioManager():PlayeEffectSoundWithKey("BUY_ITEM")
                end)
            end, stage.rewards)
        end)

    bg.label = UIKit:ttfLabel({
        text = _("已领取") ,
        size = 24,
        color = 0xffedae,
        shadow = true
    }):addTo(bg):align(display.CENTER,548 - 60,100*1/2)
    return bg
end
function GameUIPveReward:RefreshUI()
    for i,v in ipairs(self.list.items_) do
        local stage_name = string.format("%d_%d", self.index, i)
        local stage = stages[stage_name]
        v:getContent().button:setVisible(not User:IsStageRewardedByName(stage_name))
        v:getContent().button:setButtonEnabled(User:GetStageStarByIndex(self.index) >= tonumber(stage.needStar) and not User:IsStageRewardedByName(stage_name))
        v:getContent().label:setVisible(not not User:IsStageRewardedByName(stage_name))
    end
end
function GameUIPveReward:CheckMaterials(callback, rewards)
    local materials_map = {}
    for _,item in ipairs(string.split(rewards, ",")) do
        local type,name,count = unpack(string.split(item, ":"))
        if type == "soldierMaterials" then
            materials_map[name] = true
        end
    end
    if User:IsMaterialOutOfRange("soldierMaterials", materials_map) then
        UIKit:showMessageDialogWithParams({
            title = _("提示"),
            content = _("当前材料库房中的士兵材料已满，你可能无法获得材料奖励。是否仍要获取？"),
            ok_callback = callback,
            ok_btn_images = {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
            ok_string = _("强行领取"),
        })
    else
        if type(callback) == "function" then
            callback()
        end
    end
end


return GameUIPveReward













