local Set = {}
local mt = {}
-- local function check_metatable(t)
-- 	for k, v in pairs(t) do
-- 		if getmetatable(v) ~= mt then
-- 			-- error("不是集合类型的table!")
-- 		end
-- 	end
-- end
function Set.new(l)
	local set = {}
	setmetatable(set, mt)
	for _, v in ipairs(l) do set[v] = true end
	return set
end

function Set.union(a, b)
	local res = Set.new{}
	for k in pairs(a) do res[k] = true end
	for k in pairs(b) do res[k] = true end
	return res
end

function Set.intersection(a, b)
	local res = Set.new{}
	for k in pairs(a) do
		res[k] = b[k]
	end
	return res
end

function Set.except(a, b)
	local res = Set.new{}
	for k, v in pairs(a) do 
		res[k] = (v and not b[k]) and true or nil
	end
	return res
end

function Set.tostring(set)
	local l = {}
	for e in pairs(set) do
		l[#l + 1] = e
	end
	return "{ " .. table.concat(l, ", ") .. " }"
end

mt.__add = Set.union
mt.__sub = Set.except
mt.__mul = Set.intersection
mt.__tostring = Set.tostring
mt.__metatable = "not your business"

return Set










