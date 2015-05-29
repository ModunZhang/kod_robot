--
-- Author: Danny He
-- Date: 2015-03-09 12:09:20
--
local GameUISelenaQuestion = UIKit:createUIClass("GameUISelenaQuestion")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIKit = UIKit
local WidgetPushButton = import("..widget.WidgetPushButton")
local Enum = import("..utils.Enum")
local config_selena_question = GameDatas.ClientInitGame.selena_question
local MAX_QUESTION_COUNT = 10
local UIListView = import(".UIListView")
local ZORDER_INDEX = {
	TIPS = 10,
	WELCOME = 9,
	ANSWER = 8,
}

GameUISelenaQuestion.WELCOME_UI_TYPE = Enum("WELCOME","SUCCESS","FAILED")
function GameUISelenaQuestion:ctor()
	GameUISelenaQuestion.super.ctor(self)
end

function GameUISelenaQuestion:onEnter()
	local manager = ccs.ArmatureDataManager:getInstance()
	manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH("animations/npc_nv.ExportJson"))
	GameUISelenaQuestion.super.onEnter(self)
	self:BuildUI()
end

function GameUISelenaQuestion:BuildUI()
	local shadowLayer = UIKit:shadowLayer():addTo(self)
	local bg = WidgetUIBackGround.new({height=880}):addTo(shadowLayer)
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom + 34)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,865):addTo(bg)
	local closeButton = UIKit:closeButton()
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:CheckClose()
	   	end)
	UIKit:ttfLabel({
		text = _("塞琳娜的考验"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,28)
	local npc_bg = display.newSprite("selenaquestion_bg_580x536.png"):align(display.TOP_CENTER, 304, 860):addTo(bg)
	local npc_animation = ccs.Armature:create("npc_nv"):addTo(npc_bg):align(display.BOTTOM_CENTER, 290, 6)
	self.npc_animation = npc_animation
	self:GetTipContent():zorder(ZORDER_INDEX.TIPS):addTo(bg):hide()
	self:GetQuestionLayer():zorder(ZORDER_INDEX.ANSWER):addTo(bg):hide()
	self:GetWelcomeLayer():zorder(ZORDER_INDEX.WELCOME):addTo(bg)
	
end

function GameUISelenaQuestion:ShowTips(isCorrect,callback)
	isCorrect = type(isCorrect) == 'boolean' and isCorrect or false
	if not self.tips then
		self.tips = self:GetTipContent()
	end
	local title_1 = self.tips.title_1
	local title_2 = self.tips.title_2
	if isCorrect then
		title_1:setString(_("回答正确!"))
		title_2:setString(self:GetCorrectDesc())
		title_1:setColor(UIKit:hex2c3b(0x8aff00))
		title_2:setColor(UIKit:hex2c3b(0x8aff00))
		self.npc_animation:getAnimation():play("smile", -1, 0)
	else
		title_1:setString(_("回答错误!"))
		title_2:setString(_("抱歉"))
		title_1:setColor(UIKit:hex2c3b(0xe13a00))
		title_2:setColor(UIKit:hex2c3b(0xe13a00))
		self.npc_animation:getAnimation():play("sad", -1, 0)
	end
	self.tips:show()
	self:performWithDelay(function()
		self.tips:hide()
		if callback then
			callback()
		end
	end, 0.8)
end

function GameUISelenaQuestion:GetCorrectDesc()
	return Localize.selenaquestion_tips[self._question_index]
end

function GameUISelenaQuestion:GetTipContent()
	if  self.tips then return self.tips end
	local tips = display.newLayer():size(608,800)
	local tips_content = display.newSprite("selena_tips_564x104.png"):addTo(tips):align(display.BOTTOM_CENTER, 304, 502)
	local title_1 = UIKit:ttfLabel({
		text = "回答正确!",
		size = 30,
		color= 0x8aff00
	}):align(display.BOTTOM_CENTER, 282, 56):addTo(tips_content)
	tips.title_1 = title_1
	local title_2 = UIKit:ttfLabel({
		text = "大答特答",
		size = 26,
		color= 0x8aff00
	}):align(display.BOTTOM_CENTER, 282, 16):addTo(tips_content)
	tips.title_2 = title_2
	self.tips = tips
	return self.tips
end



function GameUISelenaQuestion:GetMsgAndButtonTitleByWelcomeType(welcome_ui_type)
	if welcome_ui_type == self.WELCOME_UI_TYPE.WELCOME then
		return _("大人，我准备了一些小小测试，如果你每日能连续答对10道题，我会奖赏你哦！"),_("开始吧")
	elseif welcome_ui_type == self.WELCOME_UI_TYPE.SUCCESS then 
		self.npc_animation:getAnimation():play("shy", -1, 0)
		return _("大人，恭喜你已经答对所有问题！你可以在每日任务中领取我为你准备的一份小礼物哦！"),_("再来一局")
	elseif welcome_ui_type == self.WELCOME_UI_TYPE.FAILED then 
		return string.format(_("回答错误！大人，你本次答题一共回答正确%s道问题，请你继续努力哦！"),self:GetRightQuestionCount()),_("再来一局")
	end
end

function GameUISelenaQuestion:GetRightQuestionCount()
	return self._question_index > 0 and self._question_index - 1 or 0
end

function GameUISelenaQuestion:GetQuestionLayer(question)
	if self.question_layer then
		self:RefreshQuestionLayer(question)
		return self.question_layer
	end 
	local layer = display.newLayer():size(608,322)
	local title_label = UIKit:ttfLabel({
		text = "",
		size = 24,
		color= 0x403c2f
	}):align(display.CENTER_TOP, 304, 320):addTo(layer)
	layer.title_label = title_label
	local question_label =  UIKit:ttfLabel({
		text = "",
		size = 20,
		color= 0x403c2f,
		dimensions = cc.size(560,0),
		lineHeight = 36,
	}):align(display.LEFT_TOP, 22, 280):addTo(layer)
	layer.question_label = question_label
	local listView = UIListView.new({
        viewRect = cc.rect(22,18,560, 180),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }):addTo(layer)
    self.question_layer_list = listView
	self.question_layer = layer
	self:RefreshQuestionLayer(question)
	return self.question_layer
end

function GameUISelenaQuestion:GetListItem(index,question)
	local item = self.question_layer_list:newItem()
	local label = UIKit:ttfLabel({
		text = question,
		size = 22,
		color= 0x403c2f,
		dimensions = cc.size(494,0),
	})
	local content = display.newNode()
	local height = math.max(label:getContentSize().height,51)
	local panel = UIKit:CreateBoxPanel9({width = 496,height = height}):addTo(content)
	label:align(display.LEFT_CENTER, 14, math.floor(height/2)):addTo(panel)

	local button = WidgetPushButton.new({
			normal = 'activity_check_bg_55x51.png'
		})
		:align(display.LEFT_CENTER, 500, math.floor(height/2))
		:addTo(content)
		:onButtonClicked(function(event)
			self:OnAnswerButtonClicked(index,event.target)
		end)
	local check_state = display.newSprite("activity_check_body_55x51.png"):addTo(button):pos(27,0):hide()
	button.check_state = check_state
	local wrong_state = display.newSprite("wrong_41x45.png"):addTo(button):pos(27,0):hide()
	button.wrong_state = wrong_state
	content:size(560,height)
	item:addContent(content)
	item:setMargin({left = 0, right = 0, top = 0, bottom = 11})
	item:setItemSize(560, height,false)
	return item
end

function GameUISelenaQuestion:RefreshQuestionLayer(question)
	if not question then return end
	local layer = self.question_layer
	local random_indexs = self:RandomThreeSeqNum()
	layer.title_label:setString(string.format(_("连续答题 %s"),self._question_index))
	layer.question_label:setString(question.title)
	question.correct = table.indexof(random_indexs,1) -- 配置表的第一列为正确答案
	self.question_layer_list:removeAllItems()
	for index,v in ipairs(random_indexs) do
		local item = self:GetListItem(index,question['answer_' .. v])
		self.question_layer_list:addItem(item)
	end
	self.question_layer_list:reload()
end

function GameUISelenaQuestion:GetWelcomeLayer(welcome_ui_type)
	welcome_ui_type = welcome_ui_type or self.WELCOME_UI_TYPE.WELCOME
	local msg,button_title = self:GetMsgAndButtonTitleByWelcomeType(welcome_ui_type)
	self._question_index = -1
	if self.welcome_layer then
		self.welcome_layer.setInfo(msg,button_title)
		return self.welcome_layer
	end
	local layer = display.newLayer():size(608,322)
	UIKit:ttfLabel({
		text = _("塞琳娜:"),
		size = 24,
		color= 0x403c2f
	}):align(display.LEFT_TOP, 22, 320):addTo(layer)
	local msg_label = UIKit:ttfLabel({
		text = "",
		size = 20,
		color= 0x403c2f,
		dimensions = cc.size(560,0),
		lineHeight = 36,
	}):align(display.LEFT_TOP, 22, 280):addTo(layer)
	local button = WidgetPushButton.new({
		normal = "yellow_btn_up_186x66.png",
		pressed = "yellow_btn_down_186x66.png"
		})
		:addTo(layer)
		:pos(304,50)
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = ""
		}))
		:onButtonClicked(function ()
			self.npc_animation:getAnimation():play("Animation1", 0, 0)
			self:OnStarButtonClicked()
		end)
	layer.setInfo = function(msg,button_title)
		msg_label:setString(msg)
		button:getButtonLabel("normal"):setString(button_title)
	end
	layer.setInfo(msg,button_title)
	self.welcome_layer = layer
	return self.welcome_layer
end

function GameUISelenaQuestion:CheckClose()
	if self._question_index > 0 then
		UIKit:showMessageDialog(
			_("提示"),
			_("你正在回答问题,如果关闭此界面，之前回答正确的题目数将被清零,是否继续关闭该界面"),
			function()
				self:LeftButtonClicked()
			end,
			function()
			end)
	else
		self:LeftButtonClicked()
	end
end

function GameUISelenaQuestion:LoadNextQuestion()
	if self._question_index >= MAX_QUESTION_COUNT then
		self:GetQuestionLayer():hide()
		self:GetWelcomeLayer(self.WELCOME_UI_TYPE.SUCCESS):show()
		self:SendResultToServerIf()
	else
		self._question_index = self._question_index + 1
		self:GetQuestionLayer(self:GetCurrentQuestion()):show()
	end
end

function GameUISelenaQuestion:OnAnswerButtonClicked(index,button)
	local question = self:GetCurrentQuestion()
	if question.correct == index then --correct! 
		if button then
			button.check_state:show()
		end
		self:ShowTips(true,function()
			self:LoadNextQuestion()
		end)
	else
		if button then
			button.wrong_state:show()
		end
		self:ShowTips(false,function()
			self:GetWelcomeLayer(self.WELCOME_UI_TYPE.FAILED):show()
			self:GetQuestionLayer():hide()
		end)
	end
end

function GameUISelenaQuestion:OnStarButtonClicked()
	self:LoadQuestionFromConfig()
	self:GetQuestionLayer(self:GetCurrentQuestion()):show()
	self.welcome_layer:hide()
end

function GameUISelenaQuestion:GetCurrentQuestion()
	return self._questions[self._question_index]
end

--随机生成题目 MAX_QUESTION_COUNT
function GameUISelenaQuestion:LoadQuestionFromConfig()
	local questions = {}
	local indexs = self:RandomIndexForConfig()
	for index,__ in pairs(indexs) do
		table.insert(questions,config_selena_question[index])
	end
	self._questions = questions
	self._question_index = 1
end

function GameUISelenaQuestion:RandomIndexForConfig()
	local r = {}
	local total = #config_selena_question
	for i=1,MAX_QUESTION_COUNT do
		local random_index = math.random(total)
		while r[random_index] do
			random_index = math.random(total)
		end
		r[random_index] = true
	end
	return r
end

function GameUISelenaQuestion:RandomThreeSeqNum()
	math.newrandomseed()
	local r = {}
	local indexs = {}
	local total_num = 3
	for i=1,total_num do
		local random_index = math.random(total_num)
		while indexs[random_index] do
			random_index = math.random(total_num)
		end
		indexs[random_index] = true
		table.insert(r,random_index)
	end
	return r
end

function GameUISelenaQuestion:CheckFinishSelenaTestIf()
	local data = User:GetDailyTasksInfo("empireRise")
	for __,v in ipairs(data) do
		if v == 3 then
			return true
		end
	end
	return false
end

function GameUISelenaQuestion:SendResultToServerIf()
	--check need send to server?
	if not self:CheckFinishSelenaTestIf() then
		NetManager:getPassSelinasTestPromise()
	end
end

return GameUISelenaQuestion