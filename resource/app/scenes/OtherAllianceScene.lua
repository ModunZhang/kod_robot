--
-- Author: Danny He
-- Date: 2014-11-20 21:51:12
--
--TODO:周期性的请求对方联盟数据
local AllianceScene = import(".AllianceScene")
local OtherAllianceScene = class("OtherAllianceScene", AllianceScene)
local REQUEST_SERVER_TIME = 30

function OtherAllianceScene:ctor(alliance)
	self.alliance_ = alliance
	OtherAllianceScene.super.ctor(self)
end

function OtherAllianceScene:onEnter()
    OtherAllianceScene.super.onEnter(self)
end

function OtherAllianceScene:OnTouchClicked(pre_x, pre_y, x, y)
end


function OtherAllianceScene:GetAlliance()
	return self.alliance_
end

function OtherAllianceScene:CreateAllianceUI()
	local home = UIKit:newGameUI('GameUIOtherAllianceHome',self:GetAlliance()):AddToScene(self)
    self:GetSceneLayer():AddObserver(home)
    home:setTouchSwallowEnabled(false)
end
function OtherAllianceScene:GotoCurrectPosition()
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(10, 10)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function OtherAllianceScene:onExit()
    OtherAllianceScene.super.onExit(self)
end

--特殊刷新行军路线-->服务器需要添加缺失的行军事件
function OtherAllianceScene:RefreshAllianceMarchLine()
    --TODO:待验证
    self:GetSceneLayer():InitAllianceEvent()
end


return OtherAllianceScene