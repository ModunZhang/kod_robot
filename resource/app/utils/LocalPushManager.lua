--
-- Author: Danny He
-- Date: 2014-12-12 17:05:14
--
local LocalPushManager = class("LocalPushManager")
local localPush = ext.localpush
local Enum = import("..utils.Enum")
local LOCAL_PUSH_KEY = Enum("LOCAL_PUSH_KEY_BUILD","LOCAL_PUSH_KEY_SOLDIER","LOCAL_PUSH_KEY_TECHNOLOGY","LOCAL_PUSH_KEY_TOOL","LOCAL_PUSH_KEY_WATCH_TOWER")

function LocalPushManager:ctor(game_default)
	if self:IsSupport() then
		self:CancelAll()
		self.game_default = game_default
		self.flag_LOCAL_PUSH_KEY_BUILD = self:GetGameDefault():getBasicInfoValueForKey(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_BUILD],true)
		self.flag_LOCAL_PUSH_KEY_SOLDIER = self:GetGameDefault():getBasicInfoValueForKey(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_SOLDIER],true)
		self.flag_LOCAL_PUSH_KEY_TECHNOLOGY = self:GetGameDefault():getBasicInfoValueForKey(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_TECHNOLOGY],true)
		self.flag_LOCAL_PUSH_KEY_TOOL = self:GetGameDefault():getBasicInfoValueForKey(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_TOOL],true)
		self.flag_LOCAL_PUSH_KEY_WATCH_TOWER = self:GetGameDefault():getBasicInfoValueForKey(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_WATCH_TOWER],true)
		localPush.switchNotification(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_BUILD],self.flag_LOCAL_PUSH_KEY_BUILD)
		localPush.switchNotification(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_SOLDIER],self.flag_LOCAL_PUSH_KEY_SOLDIER)
		localPush.switchNotification(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_TECHNOLOGY],self.flag_LOCAL_PUSH_KEY_TECHNOLOGY)
		localPush.switchNotification(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_TOOL],self.flag_LOCAL_PUSH_KEY_TOOL)
		localPush.switchNotification(LOCAL_PUSH_KEY[LOCAL_PUSH_KEY.LOCAL_PUSH_KEY_WATCH_TOWER],self.flag_LOCAL_PUSH_KEY_WATCH_TOWER)
	end
end

function LocalPushManager:GetGameDefault()
	return self.game_default
end
--返回本地通知是否支持该平台
function LocalPushManager:IsSupport()
	return device.platform == 'ios'
end

function LocalPushManager:CancelAll()
	if not self:IsSupport() then return end
	localPush.cancelAll()
	for __,v in pairs(LOCAL_PUSH_KEY) do
		if type(v) == 'string' then
			self["push_queue_" .. v] = {}
		end
	end
end

function LocalPushManager:CancelNotificationByIdentity(identity)
	if not self:IsSupport() then return end
	localPush.cancelNotification(identity)
end
-- key is string
function LocalPushManager:SwitchNotificationByKey(key,isOn)
	if not self:IsSupport() 
		or not type(key) == 'string' 
		or not LOCAL_PUSH_KEY[key]  
		or self["flag_" .. key ] == isOn 
	then 
		return 
	end
	isOn = checkbool(isOn)
	self["flag_" .. key ] = isOn
	self:CancelNotificationByKey(key)
	if isOn then
		self:RecoverLocalPush(key)
	end
	self:GetGameDefault():setBasicInfoBoolValueForKey(key,isOn)
	self:GetGameDefault():flush()
end

-- key is string
function LocalPushManager:CancelNotificationByKey(key)
	if not LOCAL_PUSH_KEY[key] or not self:IsSupport() then return end
	local target_queue = self["push_queue_" .. key]
	for identity,__ in pairs(target_queue) do
		self:CancelNotificationByIdentity(identity)
	end
end

function LocalPushManager:CancelNotificationByKeyAndIdentity(key,identity)
	if not self:IsSupport() then return end
	self:CancelNotificationByIdentity(identity)
	local target_queue = self["push_queue_" .. key]
	target_queue[identity] = nil
end
-- push_key is string
function LocalPushManager:AddLocalPush(push_key,finishTime,msg,identity)
	if not self:IsSupport() 
		or not type(push_key) == 'string' 
		or not LOCAL_PUSH_KEY[push_key]  
		or not self["flag_" .. push_key ] 
	then 
		return 
	end
	self:CancelNotificationByIdentity(identity)
	localPush.addNotification(push_key, finishTime,msg,identity)
	local target_queue = self["push_queue_" .. push_key]
	target_queue[identity] = {finishTime = finishTime,msg = msg,identity = identity}
end

function LocalPushManager:GetLocalPushStateByKey(push_key)
	if not self:IsSupport() 
		or not type(push_key) == 'string' 
		or not LOCAL_PUSH_KEY[push_key]  
	then 
		return false
	else
		return self["flag_" .. push_key ] 
	end
end

function LocalPushManager:RecoverLocalPush(push_key)
	if not self:IsSupport() then return end
	local target_queue = self["push_queue_" .. push_key]
	local current_time = app.timer:GetServerTime()
	for __,v in pairs(target_queue) do
		if v.finishTime >= current_time then
			self:AddLocalPush(push_key,v.finishTime,v.msg,v.identity)
		end
	end
end
--TODO:push相关函数的调用
-- api
function LocalPushManager:GetBuildPushState()
	return self:GetLocalPushStateByKey("LOCAL_PUSH_KEY_BUILD")
end
function LocalPushManager:SwitchBuildPush(isOn)
	self:SwitchNotificationByKey("LOCAL_PUSH_KEY_BUILD",isOn)
end

function LocalPushManager:UpdateBuildPush(finishTime,msg,identity)
	self:AddLocalPush("LOCAL_PUSH_KEY_BUILD",finishTime,msg,identity)
end

function LocalPushManager:CancelBuildPush(identity)
	self:CancelNotificationByKeyAndIdentity("LOCAL_PUSH_KEY_BUILD",identity)
end

function LocalPushManager:GetSoldierPushState()
	return self:GetLocalPushStateByKey("LOCAL_PUSH_KEY_SOLDIER")
end
function LocalPushManager:SwitchSoldierPush(isOn)
	self:SwitchNotificationByKey("LOCAL_PUSH_KEY_SOLDIER",isOn)
end

function LocalPushManager:UpdateSoldierPush(finishTime,msg,identity)
	self:AddLocalPush("LOCAL_PUSH_KEY_SOLDIER",finishTime,msg,identity)
end

function LocalPushManager:CancelSoldierPush(identity)
	self:CancelNotificationByKeyAndIdentity("LOCAL_PUSH_KEY_SOLDIER",identity)
end

function LocalPushManager:GetTechnologyPushState()
	return self:GetLocalPushStateByKey("LOCAL_PUSH_KEY_TECHNOLOGY")
end
function LocalPushManager:SwitchTechnologyPush(isOn)
	self:SwitchNotificationByKey("LOCAL_PUSH_KEY_TECHNOLOGY",isOn)
end

function LocalPushManager:UpdateTechnologyPush(finishTime,msg,identity)
	self:AddLocalPush("LOCAL_PUSH_KEY_TECHNOLOGY",finishTime,msg,identity)
end

function LocalPushManager:CancelTechnologyPush(identity)
	self:CancelNotificationByKeyAndIdentity("LOCAL_PUSH_KEY_TECHNOLOGY",identity)
end
--工具与装备制造
function LocalPushManager:GetToolEquipemtPushState()
	return self:GetLocalPushStateByKey("LOCAL_PUSH_KEY_TOOL")
end

function LocalPushManager:SwitchToolEquipmentPush(isOn)
	self:SwitchNotificationByKey("LOCAL_PUSH_KEY_TOOL",isOn)
end

function LocalPushManager:UpdateToolEquipmentPush(finishTime,msg,identity)
	self:AddLocalPush("LOCAL_PUSH_KEY_TOOL",finishTime,msg,identity)
end

function LocalPushManager:CancelToolEquipmentPush(identity)
	self:CancelNotificationByKeyAndIdentity("LOCAL_PUSH_KEY_TOOL",identity)
end
--瞭望塔
function LocalPushManager:GetWatchTowerPushState()
	return self:GetLocalPushStateByKey("LOCAL_PUSH_KEY_WATCH_TOWER")
end

function LocalPushManager:SwitchWatchTowerPush(isOn)
	self:SwitchNotificationByKey("LOCAL_PUSH_KEY_WATCH_TOWER",isOn)
end

function LocalPushManager:UpdateWatchTowerPush(finishTime,msg,identity)
	self:AddLocalPush("LOCAL_PUSH_KEY_WATCH_TOWER",finishTime,msg,identity)
end

function LocalPushManager:CancelWatchTowerPush(identity)
	self:CancelNotificationByKeyAndIdentity("LOCAL_PUSH_KEY_WATCH_TOWER",identity)
end
return LocalPushManager