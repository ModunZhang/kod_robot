--[[
	CCPomelo
	适配项目使用lua版本的pomelo接口 v0.0.1
--]]

local Pomelo = require("libs.pomelo.Pomelo")

local CCPomelo = class("CCPomelo")

function CCPomelo:ctor()
	self._pomelo = Pomelo:new()
end

function CCPomelo:getInstance()
	if not CCPomelo._instance_ then
		CCPomelo._instance_ = CCPomelo:new()
	end
	return CCPomelo._instance_
end
-- cb(success,data)
function CCPomelo:request(route, msg,cb)
	print(route,"CCPomelo:request---->")
	dump(msg,"CCPomelo:request---->")
	self._pomelo:request(route, msg,function( args )
        cb(true,args)
	end)
end
-- cb(success)
function CCPomelo:asyncConnect(host, port,cb)
	self._pomelo:init({host = host,port = port},function( args )
		cb(args)
	end)
end
-- cb(success)
function CCPomelo:notify(route, msg,cb)
	self._pomelo:notify(route,msg)
	cb(true)
end

-- cb(success,data)
function CCPomelo:addListener(event,cb)
	self._pomelo:on(event,function( args )
		cb(true,args)
	end)
end

function CCPomelo:removeListener( event )
	self._pomelo:off(event)
end

function CCPomelo:stop()
	self._pomelo:disconnect()
end

function CCPomelo:cleanup()
	self._pomelo:removeAllListener()
end

return CCPomelo