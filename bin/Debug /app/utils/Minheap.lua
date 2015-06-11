
module('Minheap', package.seeall)

local methods = {
}
methods.__index = methods

--  package function
function new(cmpFunc)
    cmpFunc = cmpFunc or (function(a, b) return a < b end)
    local o = {_cmpFunc = cmpFunc, data = {}}
    setmetatable(o, methods)
    return o
end

function heapSort(array, func)
    local heap = Minheap.new(func)
    for _, v in ipairs(array) do heap:push(v) end
    for i, v in ipairs(array) do array[i] = heap:pop() end
    assert(heap:empty())
end

-- Minheap:methods
function methods:push(v)
    table.insert(self.data, v)
    local n = #self.data
    while n > 1 do
        local p = math.floor(n / 2)
        if not self._cmpFunc(self.data[n], self.data[p]) then break end
        self.data[n], self.data[p] = self.data[p], self.data[n]
        n = p
    end
end

function methods:pop()
    assert(not self:empty())
    local rv = self.data[1]
    self.data[1] = self.data[#self.data]
    table.remove(self.data)
    local i, len = 1, #self.data
    while true do
        local minChild = i * 2
        if minChild > len then break end
        if minChild + 1 <= len and self._cmpFunc(
            self.data[minChild + 1], self.data[minChild]) then
            minChild = minChild + 1
        end
        if not self._cmpFunc(self.data[minChild], self.data[i]) then
            break
        end
        self.data[i], self.data[minChild] = self.data[minChild], self.data[i]
        i = minChild
    end
    return rv
end

function methods:top()
    assert(not self:empty())
    return self.data[1]
end

function methods:empty()
    return #self.data == 0
end

function methods:clear()
    self.data = {}
end
