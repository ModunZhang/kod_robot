return function(...)
    local enum = {}
    for i,v in pairs{...} do
        enum[v] = i
        enum[i] = v
    end
    return enum
end



