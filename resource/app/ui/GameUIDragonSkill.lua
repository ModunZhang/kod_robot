--
-- Author: Danny He
-- Date: 2014-09-24 22:37:58
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIDragonSkill = UIKit:createUIClass("GameUIDragonSkill","UIAutoClose")
local config_dragonSkill = GameDatas.Dragons.dragonSkill
local BODY_HEIGHT = 450
local LISTVIEW_WIDTH = 520
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local DragonManager = import("..entity.DragonManager") 
local UILib = import(".UILib")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")

function GameUIDragonSkill:ctor(building,skill)
	GameUIDragonSkill.super.ctor(self)
	self.skill = skill
  self.dragon_manager = building:GetDragonManager()
  self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
  if self:SkillIsMaxLevel() then 
      BODY_HEIGHT = 180
  else
      BODY_HEIGHT = 450
  end
end

function GameUIDragonSkill:SkillIsMaxLevel()
    return self.skill:IsMaxLevel()
end

function GameUIDragonSkill:GetSkillIconSprite()
    local skill_icon = UILib.dragon_skill_icon[self.skill:Name()][self.skill:Type()]
    if self.skill:IsLocked() then
        local skill_sp = UIKit:getDiscolorrationSprite(skill_icon)
        return skill_sp
    else
        local skill_sp = display.newSprite(skill_icon)
        return skill_sp
    end
end

function GameUIDragonSkill:onEnter()
	GameUIDragonSkill.super.onEnter(self)
	self.backgroundImage = WidgetUIBackGround.new({height=BODY_HEIGHT})
  self:addTouchAbleChild(self.backgroundImage)
  local y = display.height - 680
  if BODY_HEIGHT == 180 then
      y = display.height - 410
  end
	self.backgroundImage:pos((display.width-self.backgroundImage:getContentSize().width)/2,y)
	local titleBar = display.newSprite("title_blue_600x56.png")
		:align(display.BOTTOM_LEFT, 2,self.backgroundImage:getContentSize().height - 15)
		:addTo(self.backgroundImage)

  self.mainTitleLabel = UIKit:ttfLabel({
       text = _("技能学习"),
       color = 0xffedae,
       align = cc.TEXT_ALIGNMENT_CENTER,
       size  = 24
    })
    :addTo(titleBar)
    :align(display.CENTER, 300, 28)
    self.titleBar = titleBar
    UIKit:closeButton():align(display.RIGHT_BOTTOM,600, 0)
      :addTo(titleBar):onButtonClicked(function()
          self:LeftButtonClicked()
      end)
  local skillBg = display.newSprite("dragon_skill_bg_110x110.png")
        :addTo(self.backgroundImage):align(display.LEFT_TOP,30,titleBar:getPositionY() - 20)
  local skill_icon = UILib.dragon_skill_icon[self.skill:Name()][self.skill:Type()]
  local skill_sp = self:GetSkillIconSprite():addTo(skillBg):pos(55,55)
  skill_sp:scale(80/skill_sp:getContentSize().width)
  local str = self.skill:Level() > 0 and Localize.dragon_skill[self.skill:Name()] .. " (LV" .. self.skill:Level() .. ")" or Localize.dragon_skill[self.skill:Name()]
  local titleLabel = UIKit:ttfLabel({
      text = str,
      size = 24,
      color= 0x403c2f,
      align = cc.ui.UILabel.TEXT_ALIGN_LEFT
  }):addTo(self.backgroundImage):align(display.LEFT_TOP,skillBg:getPositionX()+skillBg:getContentSize().width+5,skillBg:getPositionY()-10)
  self.titleLabel = titleLabel
  local descLabel = UIKit:ttfLabel({
      text = self:GetSkillEffection(),
      size = 20,
      color=0x403c2f,
      align = cc.ui.UILabel.TEXT_ALIGN_LEFT, 
  }):addTo(self.backgroundImage):align(display.LEFT_TOP, skillBg:getPositionX()+skillBg:getContentSize().width+5, titleLabel:getPositionY()- titleLabel:getContentSize().height - 10)
  self.descLabel = descLabel
  if not self:SkillIsMaxLevel() then
    	local upgradeButton = WidgetPushButton.new({
        normal = "yellow_btn_up_186x66.png",
        pressed = "yellow_btn_down_186x66.png",
        disabled = "grey_btn_186x66.png"
      })
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
     local requirements = self:GetRequirements()
     self.listView = WidgetRequirementListview.new({
            title = _("学习条件"),
            height = 188,
            contents = requirements,
        }):addTo(self.backgroundImage):pos(35,60)
    end
  	self:RefreshUI()
end

function GameUIDragonSkill:GetDragon()
  return self.dragon_manager:GetDragon(self.skill:Type())
end

function GameUIDragonSkill:RefreshUI()
  local str = self.skill:Level() > 0 and Localize.dragon_skill[self.skill:Name()] .. " (LV" .. self.skill:Level() .. ")" or Localize.dragon_skill[self.skill:Name()]
  self.titleLabel:setString(str)
  self.descLabel:setString(self:GetSkillEffection())
  if not self:SkillIsMaxLevel() then
      local requirements = self:GetRequirements()
      self.listView:RefreshListView(requirements)
      self.upgradeButton:setButtonEnabled(self:CanUpgrade())
  end
end

function GameUIDragonSkill:OnMoveOutStage()
  self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
  GameUIDragonSkill.super.OnMoveOutStage(self)
end

function GameUIDragonSkill:UpgradeButtonClicked()
  if self:SkillIsMaxLevel() then
    UIKit:showMessageDialog(_("提示"),_("技能已经达到最大等级"))
    return 
  end
  NetManager:getUpgradeDragonDragonSkillPromise(self.skill:Type(),self.skill:Key()):done(function()
      GameGlobalUI:showTips(_("提示"),_("技能学习成功!"))
      if self:SkillIsMaxLevel() then
          self:LeftButtonClicked()
      else
        self:RefreshUI()
      end
  end)
end

function GameUIDragonSkill:GetListItem(index,key,val)
	local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",index%2 == 0 and 1 or 2)):size(520,48)
	local imageIcon = ""
	local title = ""
	if key == "blood" then
		title = _("英雄之血")
		imageIcon = "heroBlood_3_128x128.png"
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

function GameUIDragonSkill:GetRequirements()
  local requirements = {}
  local blood = City:GetResourceManager():GetBloodResource():GetValue()
  local cost = self.skill:GetBloodCost()
  table.insert(requirements,
  {
      resource_type = _("英雄之血"),
      isVisible = true,
      isSatisfy = blood >= self.skill:GetBloodCost(),
      icon="heroBlood_3_128x128.png",
      description= string.format("%s/%s",blood,self.skill:GetBloodCost())
  })
  local star = self.skill:Star()
  local need_star = DataUtils:GetDragonSkillUnLockStar(self.skill:Name())
  table.insert(requirements,
  {
      resource_type = "dragon_star",
      isVisible = true,
      isSatisfy = star >= need_star,
      icon="dragon_star_40x40.png",
      description= string.format(_("龙的星级达到%d星"),need_star),
      canNotBuy = true,
  })
  return requirements
end

function GameUIDragonSkill:CanUpgrade()
  local cost = self.skill:GetBloodCost()
  local flag = City:GetResourceManager():GetBloodResource():GetValue() >= cost
  return flag and not self.skill:IsLocked()
end

function GameUIDragonSkill:GetSkillEffection()
  local count  = string.format("%d%%",self.skill:GetEffect() * 100)
  if self.skill:Level() >  0 then
      return Localize.dragon_skill_effection[self.skill:Name()] .. " " .. count
  else
      return Localize.dragon_skill_effection[self.skill:Name()]
  end
end

function GameUIDragonSkill:OnBasicChanged()
  local dragon = self.dragon_manager:GetDragon(self.skill:Type())
  self.skill = dragon:GetSkillByKey(self.skill:Key())
  self:RefreshUI()
end

return GameUIDragonSkill