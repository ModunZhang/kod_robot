local FiniteMachine = class("FiniteMachine")


function FiniteMachine.extend(target, ...)
	local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, FiniteMachine)
    target:ctor(...)
    return target
end

function FiniteMachine:ctor(states)
	self.all_states = states and states or {}
	self.current_state_name = nil
end
function FiniteMachine:TranslateToSatateByName(state_name)
	local current_state_name = self.current_state_name
	local all_states = self.all_states
	if current_state_name then
		all_states[current_state_name]:OnExit()
	end
	self.current_state_name = state_name
	local current_state = all_states[state_name]
	if current_state then
		current_state:OnEnter()
	end
	-- assert(current_state)
end
function FiniteMachine:AddState(state_name, state)
	self.all_states[state_name] = state
end
function FiniteMachine:CurrentState()
	return self.all_states[self.current_state_name]
end
function FiniteMachine:CurrentStateName()
	return self.current_state_name
end
function FiniteMachine:IsInStateName(state_name)
	return self.current_state_name == state_name
end


return FiniteMachine