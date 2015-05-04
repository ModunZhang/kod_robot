--
-- Author: Danny He
-- Date: 2014-12-12 14:53:18
--

local GameDefautlt = class("GameDefautlt")


function GameDefautlt:ctor()
    self.game_base_info = self:getTableForKey("GAME_BASE") or {}
    self.ver_info = self:getStringForKey("GAMEDEFAUTLT_VERSION") == "" and "0.0.1" or self:getStringForKey("GAMEDEFAUTLT_VERSION")
    dump(self.game_base_info,"GameDefautlt-->game_base_info")
    self:getBasicInfoValueForKey("NEVER_SHOW_TIP_ICON",false)
end

function GameDefautlt:flush()
    self:setStringForKey("GAMEDEFAUTLT_VERSION",self.ver_info)
    self:setTableForKey("GAME_BASE",self.game_base_info)
    cc.UserDefault:getInstance():flush()
end

function GameDefautlt:getTableForKey(key,default)
    local jsonString = self:getStringForKey(key)
    if jsonString and string.len(jsonString) > 0 then
        local t = json.decode(jsonString)
        if type(t) == 'table' then
            return t
        end
    else
        if default then
            default = checktable(default)
            self:setTableForKey(key,default)
            self:flush()
            return default
        end
    end
    return nil
end

function GameDefautlt:setStringForKey(key,str)
    cc.UserDefault:getInstance():setStringForKey(key, str)
end

function GameDefautlt:getStringForKey(key)
    return cc.UserDefault:getInstance():getStringForKey(key)
end

function GameDefautlt:setTableForKey(key,t)
    local jsonString = json.encode(t)
    self:setStringForKey(key,jsonString)
end
-- 邮件最近联系人
function GameDefautlt:getRecentContacts()
    return self:getTableForKey("RECENT_CONTACTS:"..User:Id(),{})
end
-- 添加最近联系人
function GameDefautlt:addRecentContacts(contacts)
    local recent_contacts = self:getRecentContacts()
    local new_contacts = {
        id = contacts.id,
        name = contacts.name,
        icon = contacts.icon,
        allianceTag = contacts.allianceTag,
        time = contacts.time,
    }
    -- 最多保存50个联系人
    if #recent_contacts == 50 then
        table.remove(recent_contacts,50)
    end
    for i,v in ipairs(recent_contacts) do
        if v.id == contacts.id then
            table.remove(recent_contacts,i)
        end
    end
    table.insert(recent_contacts, 1, new_contacts)
    self:setTableForKey("RECENT_CONTACTS:"..User:Id(),recent_contacts)
    self:flush()
end
-- basic info
function GameDefautlt:setBasicInfoBoolValueForKey(key,val)
    val = checkbool(val)
    self.game_base_info[key] = val
end

function GameDefautlt:getBasicInfoValueForKey(key,default)
    if self.game_base_info[key] == nil and default ~= nil then
        self.game_base_info[key] = default
        self:flush()
    end
    return self.game_base_info[key]
end

function GameDefautlt:setBasicInfoValueForKey(key,val)
    self.game_base_info[key] = val
end

function GameDefautlt:getGameBasicInfo()
    return self.game_base_info
end

return GameDefautlt








