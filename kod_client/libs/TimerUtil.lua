--
-- Author: Your Name
-- Date: 2016-02-01 14:39:06
--

local TimerUtil = class("TimerUtil")
local DEBUG = false
local print = print
if not DEBUG then
	print = function(...)end
end
function TimerUtil:ctor()
	self.__tasks__ = {}
	self._nextDeltaTimeZero = true
end

function TimerUtil:getInstance()
	if not self.__instance__ then
		self.__instance__ = TimerUtil:new() 
	end
	return self.__instance__
end

function TimerUtil:performWithDelayGlobal(fn,delay)
	local ret = tostring(fn)
	delay = tonumber(delay) or 0
	self.__tasks__[ret] = {fn = fn,delay = delay}
	return ret
end

function TimerUtil:unscheduleGlobal(identity)
	if self.__tasks__[identity] then
		self.__tasks__[identity] = nil
	end
end

function TimerUtil:scheduleGlobal(fn, interval)
	local ret = tostring(fn)
	local interval = tonumber(interval) or 0
	self.__tasks__[ret] = {fn = fn,interval = interval,needRemove = false}
	return ret
end

function TimerUtil:unscheduleGlobal(handle)
	local task = self.__tasks__[handle]
	if task then
		task.needRemove = true
	end
end

function TimerUtil:update()
	local now = ext.now()/1000 -- sec
	if self._nextDeltaTimeZero then
		self._deltaTime = 0
		self._nextDeltaTimeZero = false
	else
		self._deltaTime = math.max(now - self._lastUpdate,0)
	end
	self._lastUpdate = now
	self:checkTasks(self._deltaTime)
end

function TimerUtil:checkTasks(dt)
	print("[TimerUtil]:checkTasks",dt)
	local needRemoveEvents = {}
	for k,v in pairs(self.__tasks__) do
		if not v._elapsed then 
			v._elapsed = 0
		else
			v._elapsed = v._elapsed + dt
		end
		print("[TimerUtil]:__tasks__",k,v.delay,v._elapsed)
		if not v.interval then 
			if v._elapsed > v.delay or v._elapsed == v.delay then
				table.insert(needRemoveEvents,k)
				print("[TimerUtil]:trigger delay",k)
				v.fn()
			end
		else
			if v.needRemove then
				table.insert(needRemoveEvents,k)
			else
				if v._elapsed > v.interval or v._elapsed == v.interval then
					print("[TimerUtil]:trigger global",k)
					v._elapsed = 0
					v.fn()
				end
			end
		end
	end
	for __,v in ipairs(needRemoveEvents) do
		if self.__tasks__[v] then self.__tasks__[v] = nil end
	end
	needRemoveEvents = nil
end

return TimerUtil