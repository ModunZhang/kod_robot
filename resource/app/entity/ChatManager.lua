--
-- Author: Danny He
-- Date: 2015-01-21 16:14:47
--
-- Emoji
--------------------------------------------------------------------------------------------------
local EmojiUtil = class("EmojiUtil")

--[[
    将表情化标签转换成富文本语法
    将战报分享转化为富文本语法
    chatmsg : "[1FED]hello world..."
    
    -- dest: {'{\"type\":\"text\", \"value\":\"%s\"}','{\"type\":\"text\", \"value\":\"%s\"}','{\"type\":\"text\", \"value\":\"%s\"}'}
    local func_handler_dest = function(dest)
        table.insert(dest,1,'{\"type\":\"text\", \"value\":\"first\"}')
    end
--]]
function EmojiUtil:ConvertEmojiToRichText(chatmsg,func_handler_dest)
    chatmsg = chatmsg or ""
    if string.len(chatmsg) == 0 then return "" end
    chatmsg = string.gsub(chatmsg,"\n","\\n")
    chatmsg = string.gsub(chatmsg,"'","\'")
    chatmsg = string.gsub(chatmsg,'"',"''")
    chatmsg = string.gsub(chatmsg,'\\','\\\\')
    local dest = {}
    local s,e = string.find(chatmsg,"%[[%P]+%]")
    if not s and string.len(chatmsg) > 0 then
        table.insert(dest, chatmsg)
    end
    while s do
        if s ~= 1 then
            table.insert(dest, string.sub(chatmsg,1,s - 1))
        end
        table.insert(dest, string.sub(chatmsg,s,e))
        chatmsg = string.sub(chatmsg,e+1)
        s,e =  string.find(chatmsg,"%[[%P]+%]")
        if not s and string.len(chatmsg) > 0 then
            table.insert(dest, chatmsg)
        end
    end
    for i,v in ipairs(dest) do
        local result,count = string.gsub(v,"%[([%P]+)%]", "%1")
        if count == 0 or string.len(string.trim(result)) == 0 then
            -- 处理战报分享
            local r_s ,r_e = string.find(result,"<report>.+<report>")
            if r_s and r_e then
                local report = string.sub(result,r_s+8,r_e-8)
                local r_msg = string.split(report,",")
                local msg_value , reportId ,userId = ""
                for __,r in ipairs(r_msg) do
                    if string.find(r,"reportName") then
                        msg_value =  "[" ..string.split(r,":")[2] .. "]"
                    elseif string.find(r,"userId") then
                        userId = string.split(r,":")[2]
                    elseif string.find(r,"reportId") then
                        reportId = string.split(r,":")[2]
                    end
                end
                dest[i] = string.format('{\"type\":\"text\", \"value\":\"%s\"},{\"type\":\"text\", \"value\":\"%s\",\"color\":0xd64600,\"url\":\"%s\"},{\"type\":\"text\", \"value\":\"%s\"}',string.sub(result,1,r_s - 1), msg_value,"report:"..userId..":"..reportId,string.sub(result,r_e+1))
            else
                dest[i] = string.format('{\"type\":\"text\", \"value\":\"%s\"}', v)
            end
        else
            local key = string.format('%s.png', string.upper(result))
            if plist_texture_data[key] then
                dest[i] = string.format('{\"type\":\"image\", \"value\":\"%s\"}', key)
            else
                dest[i] = string.format('{\"type\":\"text\", \"value\":\"%s\"}', v)
            end
        end
    end
    if func_handler_dest and type(func_handler_dest) == 'function' then
        func_handler_dest(dest)
    end
    local result
    if #dest > 0 then
        result = "[" .. table.concat(dest,",") .. "]"
    else
        result = ""
    end
    return result
end
--删除字符串中所有的emoji标签并返回新字符串
function EmojiUtil:RemoveAllEmojiTag(str)
    return string.gsub(str, "%[[%P]+%]","")
end
--系统消息只支持纯文本
function EmojiUtil:FormatSystemChat(msg,opt)
    if msg then
        msg = string.gsub(msg,"\n","\\n")
        msg = string.gsub(msg,"'","\'")
        msg = string.gsub(msg,'"',"''")
        msg = string.gsub(msg,'\\','\\\\')
        if opt then
            return string.format('[{\"type\":\"text\", \"value\":\"%s\",\"color\":0x00b835}]',msg)
        else
            return string.format('[{\"type\":\"text\", \"value\":\"%s\",\"color\":0x245f00}]',msg)
        end
    end
    return ""
end

-- end
--------------------------------------------------------------------------------------------------

local scheduler           = require(cc.PACKAGE_NAME .. ".scheduler")
local MultiObserver       = import(".MultiObserver")
local ChatManager         = class("ChatManager",MultiObserver)
local Enum                = import("..utils.Enum")
local PUSH_INTVAL         = 2 -- 推送的时间间隔
local SIZE_MUST_PUSH      = 5 -- 如果队列中数量达到指定条数立即推送
ChatManager.LISTEN_TYPE   = Enum("TO_TOP","TO_REFRESH")
local BLOCK_LIST_KEY      = "CHAT_BLOCK_LIST"

function ChatManager:ctor(gameDefault)
    ChatManager.super.ctor(self)
    self.gameDefault           = gameDefault
    self.emojiUtil             = EmojiUtil.new()
    self.global_channel        = {}
    self.alliance_channel      = {}
    self.allianceFight_channel = {}
    self.push_buff_queue       = {}
    self.___handle___          = scheduler.scheduleGlobal(handler(self, self.__checkNotifyIf),PUSH_INTVAL)
    self._blockedIdList_       = self:GetGameDefault():getBasicInfoValueForKey(BLOCK_LIST_KEY,{})
end

function ChatManager:GetEmojiUtil()
    return self.emojiUtil
end

function ChatManager:GetGameDefault()
    return self.gameDefault
end

function ChatManager:__checkIsBlocked(msg)
    if msg.id == User._id then
        msg.name = User.basicInfo.name
        msg.icon = User.basicInfo.icon
        local alliacne = Alliance_Manager:GetMyAlliance()
        if not alliacne:IsDefault() then
            msg.allianceTag = alliacne.basicInfo.tag
        end
    end
    return self._blockedIdList_[msg.id] ~= nil
end

function ChatManager:__getMessageWithChannel(channel)
    if channel == 'global' then
        return self.global_channel
    elseif channel == 'allianceFight' then
        return self.allianceFight_channel
    elseif channel == 'alliance' then
        return self.alliance_channel
    end
end



function ChatManager:insertNormalMessage_(msg)
    if not msg.channel then return end
    local msg_type = string.lower(msg.channel)
    if msg_type =='global' or msg_type == 'system' then
        if not self:__checkIsBlocked(msg) then
            table.insert(self.global_channel,1,msg)
            return true
        end
    elseif msg_type == 'alliance' then
        if not self:__checkIsBlocked(msg) then
            table.insert(self.alliance_channel,1,msg)
            return true
        end
    elseif msg_type == 'alliancefight' then
        if not self:__checkIsBlocked(msg) then
            table.insert(self.allianceFight_channel,1,msg)
            return true
        end
    end
    return false
end


function ChatManager:callEventsChangedListeners_(LISTEN_TYPE,tabel_param)
    tabel_param = tabel_param or {}
    dump(tabel_param)
    self:NotifyListeneOnType(LISTEN_TYPE, function(listener)
        listener[self.LISTEN_TYPE[LISTEN_TYPE]](listener,unpack(tabel_param))
    end)
end

function ChatManager:__checkNotifyIf()
    if #self.push_buff_queue ~= 0 then
        self:callEventsChangedListeners_(self.LISTEN_TYPE.TO_TOP,{self.push_buff_queue})
        self:emptyPushQueue_()
    end
end

function ChatManager:getAllChannelReadStatus()
    if not self.channelReadStatus then
        self.channelReadStatus = {
            global = false,
            alliance = false,
            allianceFight = false,
        }
    end
    return self.channelReadStatus
end
function ChatManager:setChannelReadStatus(channel,status)
    if not self.channelReadStatus then
        self.channelReadStatus = {
            global = false,
            alliance = false,
            allianceFight = false,
        }
    end
    self.channelReadStatus[channel] = status
end
function ChatManager:pushMsgToQueue_(msg)
    self:setChannelReadStatus(msg.channel,true)
    table.insert(self.push_buff_queue,1,msg)
    if #self.push_buff_queue >= SIZE_MUST_PUSH then
        self:__checkNotifyIf()
    end
end

function ChatManager:emptyAllianceChannel()
    self.alliance_channel = {}
    self.allianceFight_channel = {}
    self:setChannelHaveInited('allianceFight',false)
    self:setChannelHaveInited('alliance',false)
end

function ChatManager:emptyChannel_(channel)
    if channel == 'global' then
        self.global_channel = {}
        self:setChannelHaveInited(channel,false)
    elseif channel == 'allianceFight' then
        self.allianceFight_channel = {}
        self:setChannelHaveInited(channel,false)
    elseif channel == 'alliance' then
        self.alliance_channel = {}
        self:setChannelHaveInited(channel,false)
    else
        self.global_channel = {}
        self.alliance_channel = {}
        self.allianceFight_channel = {}
        self:setChannelHaveInited('global',false)
        self:setChannelHaveInited('allianceFight',false)
        self:setChannelHaveInited('alliance',false)
    end
end

function ChatManager:emptyPushQueue_()
    self.push_buff_queue = {}
end

-- api
function ChatManager:HandleNetMessage(eventName,msg,channel)
    if eventName == 'onChat' then
        if self:insertNormalMessage_(msg) then
            self:pushMsgToQueue_(msg)
        end
    elseif eventName == 'onAllChat' then
        self:emptyPushQueue_()
        self:emptyChannel_(channel)
        for _,v in ipairs(msg) do
            self:insertNormalMessage_(v)
        end
        self:setChannelHaveInited(channel,true)
        self:callEventsChangedListeners_(self.LISTEN_TYPE.TO_REFRESH,{})
    end
end

function ChatManager:FetchChannelMessage(channel)
    if not self:isChannelInited(channel) then
        self:FetchAllChatMessageFromServer(channel)
        return {}
    else
        local messages = self:__getMessageWithChannel(channel)
        return LuaUtils:table_filteri(messages,function(_,v)
            return not self:__checkIsBlocked(v)
        end)
    end
end

function ChatManager:__formatLastMessage(chat)
    if not chat then return ""  end
    if chat.id == User._id then
        chat.name = User.basicInfo.name
    end
    if string.lower(chat.id) == 'system' then
        return self:GetEmojiUtil():FormatSystemChat(string.format("%s : %s",chat.name,chat.text),true)
    else
        local chat_text = string.format(" : %s",chat.text)
        local result = self:GetEmojiUtil():ConvertEmojiToRichText(chat_text,function(json_table)
            table.insert(json_table,1,string.format('{\"type\":\"text\", \"value\":\"%s\",\"color\":0x00b4cf}', chat.name))
        end)
        return result
    end
end

function ChatManager:FetchLastChannelMessage()
    local messages_1 = self:__getMessageWithChannel('global')
    local messages_2 = self:__getMessageWithChannel('alliance')
    local messages_3 = self:__getMessageWithChannel('allianceFight')
    messages_1 =  LuaUtils:table_filteri(messages_1,function(_,v)
        return not self:__checkIsBlocked(v)
    end)
    messages_2 =  LuaUtils:table_filteri(messages_2,function(_,v)
        return not self:__checkIsBlocked(v)
    end)
    messages_3 =  LuaUtils:table_filteri(messages_3,function(_,v)
        return not self:__checkIsBlocked(v)
    end)
    return
        {
            self:__formatLastMessage(messages_1[1]),
            self:__formatLastMessage(messages_1[2]),
            self:__formatLastMessage(messages_2[1]),
            self:__formatLastMessage(messages_2[2]),
            self:__formatLastMessage(messages_3[1]),
            self:__formatLastMessage(messages_3[2]),
        }
end

function ChatManager:FetchChatWhenReLogined()
    self:FetchAllChatMessageFromServer('global')
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        self:FetchAllChatMessageFromServer('alliance')
        local status = alliance.basicInfo.status
        if status ~= 'prepare' and status ~= 'fight' then
            self:emptyChannel_('allianceFight')
        else
            self:FetchAllChatMessageFromServer('allianceFight')
        end
    end
end

function ChatManager:FetchAllChatMessageFromServer(channel)
    self:emptyChannel_(channel)
    NetManager:getFetchChatPromise(channel):done(function(response)
        self:HandleNetMessage('onAllChat',response.msg.chats,channel)
    end)
end

function ChatManager:isChannelInited(channel)
    return self[string.format("inited_channel_%s",channel)]
end

function ChatManager:setChannelHaveInited(channel,trueOrFalse)
    if type(trueOrFalse) ~= 'boolean' then
        trueOrFalse = true
    end
    self[string.format("inited_channel_%s",channel)] = trueOrFalse
end

function ChatManager:SendChat(channel,msg,cb)
    NetManager:getSendChatPromise(channel,msg):done(function()
        self:__checkNotifyIf()
        if cb then cb() end
    end)
end

function ChatManager:Reset()
    self:emptyChannel_()
    self:emptyPushQueue_()
    if self.___handle___ then
        scheduler.unscheduleGlobal(self.___handle___)
    end
end

function ChatManager:AddBlockChat(chat)
    if self:__checkIsBlocked(chat) then return false end
    self._blockedIdList_[chat.id] = chat
    self:__flush()
    return true
end

function ChatManager:GetBlockList()
    return self._blockedIdList_
end

function ChatManager:RemoveItemFromBlockList(chat)
    if self:__checkIsBlocked(chat) then
        self._blockedIdList_[chat.id] = nil
        self:__flush()
        return true
    end
    return true
end

function ChatManager:__flush()
    self:GetGameDefault():setBasicInfoValueForKey(BLOCK_LIST_KEY,self._blockedIdList_)
    self:GetGameDefault():flush()
end

function ChatManager:FetMessageFirstStartGame()
    if not self:isChannelInited('global') then
        self:FetchAllChatMessageFromServer('global')
    end
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        if not self:isChannelInited("alliance") then
            self:FetchAllChatMessageFromServer('alliance')
        end
        if not self:isChannelInited("allianceFight") then
            local status = alliance.basicInfo.status
            if status ~= 'prepare' and status ~= 'fight' then
                self:emptyChannel_('allianceFight')
            else
                self:FetchAllChatMessageFromServer('allianceFight')
            end
        end
    end
end

return ChatManager



