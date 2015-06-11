local EventDispatherService = class("EventDispatherService")

function EventDispatherService:ctor()
	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
end

return EventDispatherService