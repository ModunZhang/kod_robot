local Observer = class("Observer")


function Observer.extend(target, ...)
	local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, Observer)
    Observer.ctor(target, ...)
    return target
end
function Observer:ctor(...)
	self.observer = {}
end
-- function Observer:CopyListenerFrom(subject)
-- 	local observer = {}
-- 	for i, v in ipairs(subject.observer) do
-- 		observer[i] = v
-- 	end
-- 	self.observer = observer
-- end
function Observer:AddObserver(observer)
	for i,v in ipairs(self.observer) do
		if v == observer then
			return v
		end
	end
	table.insert(self.observer, observer)
	return observer
end
function Observer:RemoveAllObserver()
	self.observer = {}
end
function Observer:RemoveObserver(observer)
	for i,v in ipairs(self.observer) do
		if v == observer then
			return table.remove(self.observer, i)
		end
	end
end
function Observer:NotifyObservers(func)
	for _,v in pairs(self.observer) do
		if func(v) then return end
	end
end


return Observer