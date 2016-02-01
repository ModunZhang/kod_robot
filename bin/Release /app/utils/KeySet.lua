local KeySet = {}
local mt = {}
function KeySet.new(set)
	setmetatable(set, mt)
	return set
end

function KeySet.union(a, b)
	local res = KeySet.new{}
	for k in pairs(a) do res[k] = true end
	for k in pairs(b) do res[k] = true end
	return res
end

function KeySet.intersection(a, b)
	local res = KeySet.new{}
	for k in pairs(a) do
		res[k] = b[k]
	end
	return res
end

function KeySet.except(a, b)
	local res = KeySet.new{}
	for k, v in pairs(a) do 
		res[k] = (v and not b[k]) and true or nil
	end
	return res
end

function KeySet.tostring(set)
	local l = {}
	for k, v in pairs(set) do
		table.insert(l, string.format("%s = %s", k, v))
	end
	return "{ " .. table.concat(l, ", ") .. " }"
end

mt.__add = KeySet.union
mt.__sub = KeySet.except
mt.__mul = KeySet.intersection
mt.__tostring = KeySet.tostring
mt.__metatable = "not your business"

return KeySet










