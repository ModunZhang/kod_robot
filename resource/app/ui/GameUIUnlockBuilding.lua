local UIListView = import(".UIListView")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local UpgradeBuilding = import("..entity.UpgradeBuilding")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local MaterialManager = import("..entity.MaterialManager")
local SpriteConfig = import("..sprites.SpriteConfig")


local GameUIUnlockBuilding = class("GameUIUnlockBuilding", WidgetPopDialog)

function GameUIUnlockBuilding:ctor( city, tile )
    GameUIUnlockBuilding.super.ctor(self,650,_("解锁建筑"),display.top-160)
    self.city = city
    self.tile = tile
    self.building = city:GetBuildingByLocationId(tile.location_id)
    self:setNodeEventEnabled(true)
    self:Init()
    self.city:GetResourceManager():AddObserver(self)
end
function GameUIUnlockBuilding:OnResourceChanged(resource_manager)
    self:SetUpgradeRequirementListview()
end
function GameUIUnlockBuilding:onEnter()
    UIKit:CheckOpenUI(self)
end
function GameUIUnlockBuilding:onExit()
    self.city:GetResourceManager():RemoveObserver(self)
end
function GameUIUnlockBuilding:Init()
    -- bg
    local bg = self.body
    -- 建筑功能介绍
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, display.cx-250, display.top-265)
        :addTo(self):setFlippedX(true)
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, display.cx-145, display.top-265)
        :addTo(self)

    local build_png = SpriteConfig[self.building:GetType()]:GetConfigByLevel(1).png
    self.building_image = display.newScale9Sprite(build_png, display.cx-197, display.top-245):addTo(self)
    self.building_image:setAnchorPoint(cc.p(0.5,0.5))
    self.building_image:setScale(124/self.building_image:getContentSize().width)
    
    local configs = SpriteConfig[self.building:GetType()]:GetAnimationConfigsByLevel(1)
    local p = self.building_image:getAnchorPointInPoints()
    for _,v in ipairs(configs) do
        if v.deco_type == "image" then
            display.newSprite(v.deco_name):addTo(self.building_image)
            :pos(p.x + v.offset.x, p.y + v.offset.y)
        elseif v.deco_type == "animation" then
            local offset = v.offset
            local armature = ccs.Armature:create(v.deco_name)
                :addTo(self.building_image):scale(v.scale or 1)
                :align(display.CENTER, offset.x or p.x, offset.y or p.y)
            armature:getAnimation():setSpeedScale(2)
            armature:getAnimation():playWithIndex(0)
        end
    end

    self:InitBuildingIntroduces()

    -- upgrade now button
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即解锁")},
            listener = function ()
                local upgrade_listener = function()
                    local location_id = City:GetLocationIdByBuilding(self.building)
                    NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
                end

                local can_not_update_type = self.building:IsAbleToUpgrade(true)
                if can_not_update_type then
                    self:PopNotSatisfyDialog(upgrade_listener,can_not_update_type)
                else
                    upgrade_listener()
                    self:removeFromParent(true)
                end
            end,
        }
    ):pos(display.cx-150, display.top-380)
        :addTo(self)


    self.upgrade_btn = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams = {text = _("解锁")},
            listener = function ()
                local upgrade_listener = function()
                    local location_id = City:GetLocationIdByBuilding(self.building)
                    NetManager:getUpgradeBuildingByLocationPromise(location_id)
                    self:removeFromParent(true)
                end

                local can_not_update_type = self.building:IsAbleToUpgrade(false)
                if can_not_update_type then
                    self:PopNotSatisfyDialog(upgrade_listener,can_not_update_type)
                else
                    upgrade_listener()
                end
            end,
        }
    ):pos(display.cx+180, display.top-380)
        :addTo(self)

    -- 立即升级所需金龙币
    display.newSprite("gem_icon_62x61.png", display.cx-260, display.top-440):addTo(self):setScale(0.5)
    self.upgrade_now_need_gems_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,display.cx-240,display.top-446):addTo(self)
    self:SetUpgradeNowNeedGems()
    --升级所需时间
    display.newSprite("hourglass_39x46.png", display.cx+100, display.top-440):addTo(self):setScale(0.6)
    self.upgrade_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,display.cx+125,display.top-430):addTo(self)
    self:SetUpgradeTime()

    -- 科技减少升级时间
    self.buff_reduce_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "(-00:20:00)",
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x068329)
    }):align(display.LEFT_CENTER,display.cx+120,display.top-450):addTo(self)

    --升级需求listview
    self:SetUpgradeRequirementListview()
end

function GameUIUnlockBuilding:InitBuildingIntroduces()
    self.building_name = UIKit:ttfLabel({
        size = 24,
        dimensions = cc.size(350, 90),
        color = 0x403c2f
    }):align(display.LEFT_CENTER,display.cx-100, display.top-240):addTo(self)
    self.building_introduces = UIKit:ttfLabel({
        size = 22,
        dimensions = cc.size(350, 90),
        color = 0x403c2f
    }):align(display.LEFT_CENTER,display.cx-100, display.top-280):addTo(self)
    self:SetBuildingName()
    self:SetBuildingIntroduces()
end
function GameUIUnlockBuilding:SetBuildingName()
    local bd = Localize.building_name
    self.building_name:setString(bd[self.building:GetType()])
end
function GameUIUnlockBuilding:SetBuildingIntroduces()
    local bd = Localize.building_description
    self.building_introduces:setString(bd[self.building:GetType()])
end



function GameUIUnlockBuilding:SetUpgradeRequirementListview()
    local wood = City.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = City.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = City.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local population = City.resource_manager:GetPopulationResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local building = self.building

    local has_materials =City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)
    local pre_condition = building:IsBuildingUpgradeLegal()
    local requirements = {
        {
            resource_type = _("前置条件"),
            isVisible = building:GetLevel()>5,
            isSatisfy = not pre_condition,
            canNotBuy=true,
            icon="hammer_31x33.png",
            description = building:GetPreConditionDesc()
        },
        {
            resource_type = _("建造队列"),
            isVisible = true,
            isSatisfy = #City:GetUpgradingBuildings()<City:BuildQueueCounts(),
            icon="hammer_31x33.png",
            description=_("建造队列")..(City:BuildQueueCounts()-#City:GetUpgradingBuildings()).."/"..1
        },
        {
            resource_type = _("木材"),
            isVisible = self.building:GetLevelUpWood()>0,
            isSatisfy = wood>=self.building:GetLevelUpWood(),
            icon="res_wood_82x73.png",
            description= wood.."/"..self.building:GetLevelUpWood()
        },

        {
            resource_type = _("石料"),
            isVisible = self.building:GetLevelUpStone()>0,
            isSatisfy = stone>=self.building:GetLevelUpStone() ,
            icon="res_stone_88x82.png",
            description=stone.."/"..self.building:GetLevelUpStone()
        },

        {
            resource_type = _("铁矿"),
            isVisible = self.building:GetLevelUpIron()>0,
            isSatisfy = iron>=self.building:GetLevelUpIron() ,
            icon="res_iron_91x63.png",
            description=iron.."/"..self.building:GetLevelUpIron()
        },

        {
            resource_type = _("建筑蓝图"),
            isVisible = self.building:GetLevelUpBlueprints()>0,
            isSatisfy = has_materials.blueprints>=self.building:GetLevelUpBlueprints() ,
            icon="blueprints_128x128.png",
            description=has_materials.blueprints.."/"..self.building:GetLevelUpBlueprints()
        },
        {
            resource_type = _("建造工具"),
            isVisible = self.building:GetLevelUpTools()>0,
            isSatisfy = has_materials.tools>=self.building:GetLevelUpTools() ,
            icon="tools_128x128.png",
            description=has_materials.tools.."/"..self.building:GetLevelUpTools()
        },
        {
            resource_type = _("砖石瓦片"),
            isVisible = self.building:GetLevelUpTiles()>0,
            isSatisfy = has_materials.tiles>=self.building:GetLevelUpTiles() ,
            icon="tiles_128x128.png",
            description=has_materials.tiles.."/"..self.building:GetLevelUpTiles()
        },
        {
            resource_type = _("滑轮组"),
            isVisible = self.building:GetLevelUpPulley()>0,
            isSatisfy = has_materials.pulley>=self.building:GetLevelUpPulley() ,
            icon="pulley_128x128.png",
            description=has_materials.pulley.."/"..self.building:GetLevelUpPulley()
        },
    }

    if not self.requirement_listview then
        self.requirement_listview = WidgetRequirementListview.new({
            title = _("解锁需求"),
            height = 270,
            contents = requirements,
        }):addTo(self):pos(window.cx-274, window.top - 790)
    end
    self.requirement_listview:RefreshListView(requirements)
end

function GameUIUnlockBuilding:PopNotSatisfyDialog(listener,can_not_update_type)
    local dialog = UIKit:showMessageDialog()
    if can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.RESOURCE_NOT_ENOUGH then
        local required_gems =self.building:getUpgradeRequiredGems()
        local owen_gem = City:GetUser():GetGemResource():GetValue()
        if owen_gem<required_gems then
            dialog:SetTitle(_("提示"))
            dialog:SetPopMessage(UpgradeBuilding.NOT_ABLE_TO_UPGRADE.GEM_NOT_ENOUGH)
        else
            dialog:CreateOKButton(
                {
                    listener = function()
                        listener()
                    end
                }
            )
            dialog:SetTitle(_("补充资源"))
            dialog:SetPopMessage(_("您当前没有足够的资源,是否花费魔法石立即补充"))
            dialog:CreateNeeds({value = required_gems})
        end
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_NOT_ENOUGH then
        local required_gems =self.building:getUpgradeRequiredGems()
        dialog:CreateOKButton(
            {
                listener = function()
                    listener()
                end
            })
        dialog:SetTitle(_("立即开始"))
        dialog:SetPopMessage(_("您当前没有空闲的建筑,是否花费魔法石立即完成上一个队列"))
        dialog:CreateNeeds({value = required_gems})
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.GEM_NOT_ENOUGH then
        dialog:SetTitle(_("提示"))
            :SetPopMessage(can_not_update_type)
            :CreateOKButton({
                listener =  function ()
                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                    self:LeftButtonClicked()
                end
            })
    else
        dialog:SetTitle(_("提示"))
        dialog:SetPopMessage(can_not_update_type)
    end
end
function GameUIUnlockBuilding:SetUpgradeNowNeedGems()
    self.upgrade_now_need_gems_label:setString(self.building:getUpgradeNowNeedGems().."")
end
function GameUIUnlockBuilding:SetUpgradeTime()
    self.upgrade_time:setString(GameUtils:formatTimeStyle1(self.building:GetUpgradeTimeToNextLevel()))
end


-- fte
function GameUIUnlockBuilding:Find()
    return cocos_promise.defer(function()
        return self.upgrade_btn
    end)
end


return GameUIUnlockBuilding








