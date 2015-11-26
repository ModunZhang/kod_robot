--[[ 
	将lua版本的pomelo的所有事件缓存在这里,逐帧调用(游戏帧率),暂时未启用
--]] 
import('app.utils.Minheap')
local scheduler = require("framework.scheduler")
local PomeloEventPool = class("PomeloEventPool")

function PomeloEventPool:ctor()
	self.message_queue = Minheap.new(function(a,b)
        return a.time < b.time
    end)
end

function PomeloEventPool:getInstance()
	if not PomeloEventPool._instance_ then
		PomeloEventPool._instance_ = PomeloEventPool:new()
	end
	return PomeloEventPool._instance_
end

function PomeloEventPool:startUpdate()
	if not self.update_id then
		self.update_id = scheduler.scheduleUpdateGlobal(handler(self,self._update))
	end
end

function PomeloEventPool:_update(dt)
	 if not self.message_queue:empty() then
        local message = self.message_queue:pop()
        -- handler msg
       
    end
end

function PomeloEventPool:addMessageToQueue( msg )
	if self.message_queue then
		msg.time = os.time()
		self.message_queue:push(msg)
	end
end

function PomeloEventPool:stopUpdate()
	if self.update_id then
		scheduler.unscheduleGlobal(self.update_id)
		self.update_id = nil
	end
end

return PomeloEventPool