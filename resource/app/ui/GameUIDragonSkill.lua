--
-- Author: Danny He
-- Date: 2014-09-24 22:37:58
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIDragonSkill = UIKit:createUIClass("GameUIDragonSkill","UIAutoClose")
local config_dragonSkill = GameDatas.Dragons.dragonSkill
local BODY_HEIGHT = 450
local LISTVIEW_WIDTH = 547
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local DragonManager = import("..entity.DragonManager") 
local UILib = import(".UILib")

function GameUIDragonSkill:ctor(building,skill)
	GameUIDragonSkill.super.ctor(self)
	self.skill = skill
  self.dragon_manager = building:GetDragonManager()
  self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
end

function GameUIDragonSkill:onEnter()
	GameUIDragonSkill.super.onEnter(self)
	self.backgroundImage = WidgetUIBackGround.new({height=BODY_HEIGHT})
  self:addTouchAbleChild(self.backgroundImage)
	self.backgroundImage:pos((display.width-self.backgroundImage:getContentSize().width)/2,display.height - self.backgroundImage:getContentSize().height - 280)
	local titleBar = display.newSprite("title_blue_600x52.png")
		:align(display.BOTTOM_LEFT, 2,self.backgroundImage:getContentSize().height - 15)
		:addTo(self.backgroundImage)

  self.mainTitleLabel = UIKit:ttfLabel({
       text = _("技能学习"),
       color = 0xffedae,
       align = cc.TEXT_ALIGNMENT_CENTER,
       size  = 24
    })
    :addTo(titleBar)
    :align(display.CENTER, 300, 22)
    self.titleBar = titleBar
    UIKit:closeButton():align(display.RIGHT_BOTTOM,600, 0)
      :addTo(titleBar):onButtonClicked(function()
          self:LeftButtonClicked()
      end)
  local skillBg = display.newSprite("dragon_skill_bg_110x110.png")
        :addTo(self.backgroundImage):align(display.LEFT_TOP,30,titleBar:getPositionY() - 20)
  local skill_icon = UILib.dragon_skill_icon[self.skill:Name()][self.skill:Type()]
  local skill_sp = display.newSprite(skill_icon):addTo(skillBg):pos(55,55)
  skill_sp:scale(80/skill_sp:getContentSize().width)

  local titleLabel = UIKit:ttfLabel({
      text = Localize.dragon_skill[self.skill:Name()] .. " (LV" .. self.skill:Level() .. ")",
      size = 24,
      color= 0x403c2f,
      align = cc.ui.UILabel.TEXT_ALIGN_LEFT
  }):addTo(self.backgroundImage):align(display.LEFT_TOP,skillBg:getPositionX()+skillBg:getContentSize().width+20,skillBg:getPositionY()-10)
  self.titleLabel = titleLabel
  local descLabel = UIKit:ttfLabel({
      text = self:GetSkillEffection(),
      size = 20,
      color=0x403c2f,
      align = cc.ui.UILabel.TEXT_ALIGN_LEFT, 
  }):addTo(self.backgroundImage):align(display.LEFT_TOP, skillBg:getPositionX()+skillBg:getContentSize().width+20, titleLabel:getPositionY()- titleLabel:getContentSize().height - 10)
  self.descLabel = descLabel
	local upgradeButton = WidgetPushButton.new({
    normal = "yellow_btn_up_185x65.png",
    pressed = "yellow_btn_down_185x65.png"}, {scale9 = false},{disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}})
      :setButtonLabel("normal", UIKit:commonButtonLable({
          text = _("学习"),
          align = cc.ui.UILabel.TEXT_ALIGN_LEFT, 
          size = 24,
      }))
      :addTo(self.backgroundImage)
      :align(display.LEFT_TOP,skillBg:getPositionX()+skillBg:getContentSize().width+260,titleBar:getPositionY() - 20)
      :onButtonClicked(function(event)
      		self:UpgradeButtonClicked()
      end)
    upgradeButton:setButtonEnabled(self:CanUpgrade())
    self.upgradeButton = upgradeButton
  local list_bg = UIKit:commonTitleBox(250):pos((self.backgroundImage:getContentSize().width-LISTVIEW_WIDTH)/2, 50):addTo(self.backgroundImage)

  UIKit:ttfLabel({
       text = _("学习条件"),
       size = 22,
       color = 0x403c2f
    }):align(display.CENTER_TOP,270,240):addTo(list_bg)
	self.listView = UIListView.new {
      viewRect = cc.rect(0, 10, LISTVIEW_WIDTH, 188),
      direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
  	}
  	:addTo(list_bg)
  	self:RefreshUI()
end

function GameUIDragonSkill:GetDragon()
  return self.dragon_manager:GetDragon(self.skill:Type())
end

function GameUIDragonSkill:RefreshUI()
  self.titleLabel:setString(Localize.dragon_skill[self.skill:Name()] .. " (LV" .. self.skill:Level() .. ")")
  self.descLabel:setString(self:GetSkillEffection())
	local requires = self:GetUpgradeSkillCost(self.skill.name,self.skill.level)
  self.listView:removeAllItems()
	for i,v in ipairs(requires) do
		local newItem = self.listView:newItem()
  		local content = self:GetListItem(i,v[1],v[2])
  		newItem:addContent(content)
  		newItem:setItemSize(content:getContentSize().width,45)
  		self.listView:addItem(newItem)
	end
  self.listView:reload()
  self.upgradeButton:setButtonEnabled(self:CanUpgrade())
end

function GameUIDragonSkill:OnMoveOutStage()
  self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
  GameUIDragonSkill.super.OnMoveOutStage(self)
end

function GameUIDragonSkill:UpgradeButtonClicked()
  NetManager:getUpgradeDragonDragonSkillPromise(self.skill:Type(),self.skill:Key())
end

function GameUIDragonSkill:GetListItem(index,key,val)
	local bg = display.newSprite(string.format("box_bg_item_520x48_%d.png",index%2))
	local imageIcon = "dragon_energy_45x38.png"
	local title = ""
	if key == "blood" then
		title = _("英雄之血")
		imageIcon = "dragonskill_blood_51x63.png"
	end
	local icon = display.newSprite(imageIcon):addTo(bg):pos(30,bg:getContentSize().height/2)
	icon:setScale(0.5)
  local titleLable = UIKit:ttfLabel({
      text = title,
      size = 20,
      align = cc.ui.UILabel.TEXT_ALIGN_LEFT, 
      color = 0x615b44
  })
  :addTo(bg):align(display.LEFT_CENTER, icon:getPositionX()+30, 24)

  local valLabel = UIKit:ttfLabel({
      text = val,
      size = 20,
      align = cc.ui.UILabel.TEXT_ALIGN_RIGHT, 
      color = 0x403c2f
  }):align(display.RIGHT_CENTER, 510,24):addTo(bg)
	return bg
end

function GameUIDragonSkill:GetUpgradeSkillCost()
    local config = self.skill:GetSkillConfig()
    local r = {
        {"blood",self.skill:GetBloodCost()},
    }
    return r
end

function GameUIDragonSkill:CanUpgrade()
  local requires = self:GetUpgradeSkillCost()
  local flag = City:GetResourceManager():GetBloodResource():GetValue() >= requires[1][2]
  return flag
end

function GameUIDragonSkill:GetSkillEffection()
  local count  = string.format("%d%%",self.skill:GetEffect() * 100)
  return Localize.dragon_skill_effection[self.skill:Name()] .. " " .. count
end


function GameUIDragonSkill:OnBasicChanged()
  local dragon = self.dragon_manager:GetDragon(self.skill:Type())
  self.skill = dragon:GetSkillByKey(self.skill:Key())
  self:RefreshUI()
end

return GameUIDragonSkill