local LoadingScene = class("LoadingScene", function()
    return display.newScene("LoadingScene")
end)

function LoadingScene:ctor(...)
	local args = {...}
	self.nextScene = table.remove(args, 1)
	self.args = args
end

local animation = import("..animation")
function LoadingScene:onEnter()
	display.newColorLayer(cc.c4b(255, 255, 255, 255)):addTo(self)
	self:performWithDelay(function()
		if device.platform == 'winrt' then
			local manager = ccs.ArmatureDataManager:getInstance()
		    for k,v in pairs(animation) do
		        local path = DEBUG_GET_ANIMATION_PATH(string.format("animations/%s.ExportJson", k))
		        manager:removeArmatureFileInfo(path)
		    end
		    cc.Director:getInstance():purgeCachedData()
		end
	    enter_scene(app:enterScene(self.nextScene, self.args))
	end, 0.1)
end

function LoadingScene:onExit()

end
return LoadingScene
