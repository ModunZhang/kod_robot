local Observer = import(".Observer")
local MultiObserver = class("MultiObserver")
function MultiObserver:ctor()
	assert(self.LISTEN_TYPE, "你必须声明监听那些东西!")
    self.listeners = {}
    self:ClearAllListener()
end
function MultiObserver:AddListenOnType(listener, listenerType)
    self.listeners[listenerType]:AddObserver(listener)
end
function MultiObserver:RemoveListenerOnType(listener, listenerType)
    self.listeners[listenerType]:RemoveObserver(listener)
end
function MultiObserver:RemoveAllListenerOnType(listenerType)
    self.listeners[listenerType] = Observer.new()
end
function MultiObserver:ClearAllListener()
    table.foreach(self.LISTEN_TYPE, function(key, listen_type)
        self.listeners[listen_type] = Observer.new()
    end)
end
function MultiObserver:NotifyListeneOnType(listenerType, func)
    self.listeners[listenerType]:NotifyObservers(function(listener)
        func(listener)
    end)
end


return MultiObserver