-- 判断utf8字符byte长度
-- 0xxxxxxx - 1 byte
-- 110yxxxx - 192, 2 byte
-- 1110yyyy - 225, 3 byte
-- 11110zzz - 240, 4 byte
local function chsize(char)
    if not char then
        print("not char")
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

local function utf8charLen(c)
    return chsize(string.byte(c, 1))
end

-- 计算utf8字符串字符数, 各种字符都按一个字符计算
-- 例如utf8len("1你好") => 3
local function utf8len(str)
    local len = 0
    local currentIndex = 1
    while currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + chsize(char)
        len = len +1
    end
    return len
end

-- 截取utf8 字符串
-- str:         要截取的字符串
-- startChar:   开始字符下标,从1开始
-- numChars:    要截取的字符长度
local function utf8sub(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + chsize(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex
    numChars = numChars or #str
    while numChars > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + chsize(char)
        numChars = numChars -1
    end
    return str:sub(startIndex, currentIndex - 1)
end

local function utf8substr(str, startChar, endChar)
    local numChars = endChar and endChar - startChar + 1 or nil
    return utf8sub(str, startChar, numChars)
end


local function utf8find(str, t, start)
    local b, e = string.find(str, t, start)
    if not b then return nil end
    local len = utf8len(string.sub(str, b, e))
    local l = utf8len(string.sub(str, 1, b - 1))
    return l + 1, len, b, e
end

local function utf8iterator(str)
    local len = 0
    local currentIndex = 1
    return function()
        local char = string.byte(str, currentIndex)
        if not char then return nil end
        local char_len = chsize(char)
        local next_index = currentIndex + char_len
        local real_char = string.sub(str, currentIndex, next_index - 1)
        currentIndex = next_index
        len = len + 1
        return len , real_char
    end
end

local function utf8index(str, index)
    return utf8sub(str, index, 1)
end


return {
    charLen = utf8charLen,
    len = utf8len,
    sub = utf8sub,
    substr = utf8substr,
    find = utf8find,
    iterator = utf8iterator,
    index = utf8index
}