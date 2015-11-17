require("cocos.cocos2d.Cocos2dConstants")
print("加载玩家自定义函数!")
NOT_HANDLE = function(...) print("net message not handel, please check !") end
local texture_data_file = device.platform == 'ios' and ".texture_data_iOS" or ".texture_data"
plist_texture_data     = import(texture_data_file)
local sharedSpriteFrameCache = cc.SpriteFrameCache:getInstance()
local rgba4444 = import(".rgba4444")
local jpg_rgb888 = import(".jpg_rgb888")
local animation = import(".animation")

math.round = function(n)
    return math.ceil(n - 0.5)
end

local pairs = pairs
local ipairs = ipairs
-- -- 设置图片格式
for k,v in pairs(rgba4444) do
    display.setTexturePixelFormat(k, v)
end
--
for k,v in pairs(jpg_rgb888) do
    display.setTexturePixelFormat(k, v)
end
display.setTexturePixelFormat("fte_background.jpg", cc.TEXTURE2_D_PIXEL_FORMAT_RG_B888)
-- 4444
for i,v in ipairs{
    "emoji.png"
} do
    display.setTexturePixelFormat(v, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
end


local _Armature = ccs.Armature
local ccs_Armature_create = _Armature.create
local manager = ccs.ArmatureDataManager:getInstance()
function _Armature:create(ani)
    for _,found_data_in_plist in ipairs(animation[ani]) do
        local png_path = DEBUG_GET_ANIMATION_PATH(found_data_in_plist)
        if not sharedSpriteFrameCache:getSpriteFrame(png_path) then
            local plistName = string.sub(png_path,1,string.find(png_path,"%.") - 1)
            plistName = string.format("%s.plist", plistName)
            printInfo("setTexture:load plist texture:%s", png_path)
            display.addSpriteFrames(DEBUG_GET_ANIMATION_PATH(plistName), png_path)
        end
    end
    local path = DEBUG_GET_ANIMATION_PATH(string.format("animations/%s.ExportJson", ani))
    manager:addArmatureFileInfo(path)
    return ccs_Armature_create(self, ani)
end


local c = cc
local Sprite = c.Sprite
local old_setTexture = Sprite.setTexture
function Sprite:setTexture(arg)
    if type(arg) == 'string' then
        local found_data_in_plist = plist_texture_data[arg]
        if found_data_in_plist then
            local frame = sharedSpriteFrameCache:getSpriteFrame(arg)
            if not frame then
                local plistName = string.sub(found_data_in_plist,1,string.find(found_data_in_plist,"%.") - 1)
                plistName = string.format("%s.plist",plistName)
                printInfo("setTexture:load plist texture:%s",found_data_in_plist)
                display.addSpriteFrames(plistName,found_data_in_plist)
            end
            self:setSpriteFrame(arg)
        else
            old_setTexture(self,arg)
        end
    else
        old_setTexture(self,arg)
    end
end

BUFF_META = {}
function BUFF_META.__add(a, b)
    local t1, t2
    if getmetatable(a) == BUFF_META then
        t1, t2 = a, b
    elseif getmetatable(b) == BUFF_META then
        t1, t2 = b, a
    else
        assert(false)
    end
    local t = {}
    if type(t2) == "table" then
        for k,v in pairs(t1) do
            t[k] = v
        end
        for k,v in pairs(t2) do
            t[k] = v + (t[k] or 0)
        end
    elseif type(t2) == "number" then
        for k,v in pairs(t1) do
            t[k] = v + t2
        end
    end
    return setmetatable(t, BUFF_META)
end
function BUFF_META.__sub(a, b)
    local t = {}
    for k,v in pairs(a) do
        t[k] = v - (b[k] or 0)
    end
    return setmetatable(t, BUFF_META)
end
function BUFF_META.__mul(a, b)
    local t1, t2
    if getmetatable(a) == BUFF_META then
        t1, t2 = a, b
    elseif getmetatable(b) == BUFF_META then
        t1, t2 = b, a
    else
        assert(false)
    end
    local t = {}
    if type(t2) == "table" then
        for k,v in pairs(t1) do
            t[k] = v * (t2[k] or 1)
        end
    elseif type(t2) == "number" then
        for k,v in pairs(t1) do
            t[k] = v * t2
        end
    end
    return setmetatable(t, BUFF_META)
end

local c3b_m_ = {
    __add = function(a,b)
        return {
            r = a.r + b.r,
            g = a.g + b.g,
            b = a.b + b.b,
        }
    end,
    __sub = function(a,b)
        return {
            r = a.r - b.r,
            g = a.g - b.g,
            b = a.b - b.b,
        }
    end
}
local c3b_ = cc.c3b
function cc.c3b( _r,_g,_b )
    local c
    if type(_r) == "table" then
        c = c3b_(_r.r,_r.g,_r.b)
    else
        c = c3b_(_r,_g,_b)
    end
    return setmetatable(c, c3b_m_)
end
local c4b_ = cc.c4b
function cc.c4b(...)
    local rgba = {...}
    if #rgba == 0 then
        return c4b_(0,0,0,0)
    elseif #rgba == 1 then
        return c4b_(rgba[1], rgba[1], rgba[1], rgba[1])
    elseif #rgba == 2 then
        return c4b_(rgba[1], rgba[2], rgba[2], rgba[2])
    elseif #rgba == 3 then
        return c4b_(rgba[1], rgba[2], rgba[3], rgba[3])
    elseif #rgba >= 4 then
        return c4b_(rgba[1], rgba[2], rgba[3], rgba[4])
    end
end
cc.c4f = cc.c4b




local old_ctor = cc.ui.UIPushButton.ctor
function cc.ui.UIPushButton:ctor(images, options,music_info)
    old_ctor(self, images, options)
    music_info = music_info or {down = "NORMAL_DOWN"
        -- , up = "NORMAL_UP"
        }
    self:addButtonPressedEventListener(function(event)
        if type(music_info.down) == 'string' and music_info.down ~= "" then
            app:GetAudioManager():PlayeEffectSoundWithKey(music_info.down)
        end
    end)
    self:addButtonReleaseEventListener(function(event)
        if type(music_info.up) == 'string' and music_info.up ~= "" then
            app:GetAudioManager():PlayeEffectSoundWithKey(music_info.up)
        end
    end)
end
if cc.TransitionCustom then
    ext.TransitionCustom = cc.TransitionCustom
end
display.SCENE_TRANSITIONS = {
    CROSSFADE       = {cc.TransitionCrossFade, 2},
    FADE            = {cc.TransitionFade, 3, cc.c3b(0, 0, 0)},
    FADEBL          = {cc.TransitionFadeBL, 2},
    FADEDOWN        = {cc.TransitionFadeDown, 2},
    FADETR          = {cc.TransitionFadeTR, 2},
    FADEUP          = {cc.TransitionFadeUp, 2},
    FLIPANGULAR     = {cc.TransitionFlipAngular, 3, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    FLIPX           = {cc.TransitionFlipX, 3, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    FLIPY           = {cc.TransitionFlipY, 3, cc.TRANSITION_ORIENTATION_UP_OVER},
    JUMPZOOM        = {cc.TransitionJumpZoom, 2},
    MOVEINB         = {cc.TransitionMoveInB, 2},
    MOVEINL         = {cc.TransitionMoveInL, 2},
    MOVEINR         = {cc.TransitionMoveInR, 2},
    MOVEINT         = {cc.TransitionMoveInT, 2},
    PAGETURN        = {cc.TransitionPageTurn, 3, false},
    ROTOZOOM        = {cc.TransitionRotoZoom, 2},
    SHRINKGROW      = {cc.TransitionShrinkGrow, 2},
    SLIDEINB        = {cc.TransitionSlideInB, 2},
    SLIDEINL        = {cc.TransitionSlideInL, 2},
    SLIDEINR        = {cc.TransitionSlideInR, 2},
    SLIDEINT        = {cc.TransitionSlideInT, 2},
    SPLITCOLS       = {cc.TransitionSplitCols, 2},
    SPLITROWS       = {cc.TransitionSplitRows, 2},
    TURNOFFTILES    = {cc.TransitionTurnOffTiles, 2},
    ZOOMFLIPANGULAR = {cc.TransitionZoomFlipAngular, 2},
    ZOOMFLIPX       = {cc.TransitionZoomFlipX, 3, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    ZOOMFLIPY       = {cc.TransitionZoomFlipY, 3, cc.TRANSITION_ORIENTATION_UP_OVER},

    CUSTOM          = {ext.TransitionCustom, 2},
}



function display.wrapSceneWithTransition(scene, transitionType, time, more)
    print("displ------->")
    local key = string.upper(tostring(transitionType))
    if string.sub(key, 1, 12) == "CCTRANSITION" then
        key = string.sub(key, 13)
    end

    if key == "RANDOM" then
        local keys = table.keys(display.SCENE_TRANSITIONS)
        key = keys[math.random(1, #keys)]
    end

    if display.SCENE_TRANSITIONS[key] then
        local cls, count, default = unpack(display.SCENE_TRANSITIONS[key])
        time = time or 0.2

        if count == 3 then
            scene = cls:create(time, scene, more or default)
        else
            scene = cls:create(time, scene)
        end
        if key == "CUSTOM" then
            scene:setNodeEventEnabled(true)
            function scene:onEnter()
                if type(more) == "function" then
                    more(self, "onEnter")
                end
            end
            function scene:onExit()
                if type(more) == "function" then
                    more(self, "onExit")
                end
            end
        end
    else
        printError("display.wrapSceneWithTransition() - invalid transitionType %s", tostring(transitionType))
    end
    return scene
end

--[[--

使用 TTF 字体创建文字显示对象，并返回 Label 对象。

可用参数：

-    text: 要显示的文本
-    font: 字体名，如果是非系统自带的 TTF 字体，那么指定为字体文件名
-    size: 文字尺寸，因为是 TTF 字体，所以可以任意指定尺寸
-    color: 文字颜色（可选），用 cc.c3b() 指定，默认为白色
-    align: 文字的水平对齐方式（可选）
-    valign: 文字的垂直对齐方式（可选），仅在指定了 dimensions 参数时有效
-    dimensions: 文字显示对象的尺寸（可选），使用 cc.size() 指定
-    x, y: 坐标（可选）

align 和 valign 参数可用的值：

-    cc.TEXT_ALIGNMENT_LEFT 左对齐
-    cc.TEXT_ALIGNMENT_CENTER 水平居中对齐
-    cc.TEXT_ALIGNMENT_RIGHT 右对齐
-    cc.VERTICAL_TEXT_ALIGNMENT_TOP 垂直顶部对齐
-    cc.VERTICAL_TEXT_ALIGNMENT_CENTER 垂直居中对齐
-    cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM 垂直底部对齐

~~~ lua

-- 创建一个居中对齐的文字显示对象
local label = display.newTTFLabel({
    text = "Hello, World",
    font = "Marker Felt",
    size = 64,
    align = cc.TEXT_ALIGNMENT_CENTER -- 文字内部居中对齐
})

-- 左对齐，并且多行文字顶部对齐
local label = display.newTTFLabel({
    text = "Hello, World\n您好，世界",
    font = "Arial",
    size = 64,
    color = cc.c3b(255, 0, 0), -- 使用纯红色
    align = cc.TEXT_ALIGNMENT_LEFT,
    valign = cc.VERTICAL_TEXT_ALIGNMENT_TOP,
    dimensions = cc.size(400, 200)
})

~~~

@param table params 参数表格对象

@return UILabel UILabel对象

]]

function display.newTTFLabel(params)
    assert(type(params) == "table",
        "[framework.display] newTTFLabel() invalid params")

    local text       = tostring(params.text)
    local font       = params.font or display.DEFAULT_TTF_FONT
    local size       = params.size or display.DEFAULT_TTF_FONT_SIZE
    local color      = params.color or display.COLOR_WHITE
    local textAlign  = params.align or cc.TEXT_ALIGNMENT_LEFT
    local textValign = params.valign or cc.VERTICAL_TEXT_ALIGNMENT_TOP
    local x, y       = params.x, params.y
    local dimensions = params.dimensions or cc.size(0, 0)
    local boldSize   = params.bold == true and 1 or 0
    assert(type(size) == "number",
        "[framework.display] newTTFLabel() invalid params.size")
    local label
    if cc.FileUtils:getInstance():isFileExist(font) then
        if device.platform == 'mac' then
            label = cc.Label:createWithTTF(text, font, size, dimensions, textAlign, textValign)
        else
            label = cc.Label:createWithTTF(text, font, size, dimensions, textAlign, textValign,0)
        end
    else
        label = cc.Label:createWithSystemFont(text, font, size, dimensions, textAlign, textValign)
    end

    if label then
        label:setColor(color)
        if x and y then label:setPosition(x, y) end
    end

    return label
end

function display.pushScene(newScene, transitionType, time, more)
    local sharedDirector = cc.Director:getInstance()
    if sharedDirector:getRunningScene() then
        if transitionType then
            newScene = display.wrapSceneWithTransition(newScene, transitionType, time, more)
        end
        sharedDirector:pushScene(newScene)
    else
        sharedDirector:runWithScene(newScene)
    end
end

function display.popScene()
    cc.Director:getInstance():popScene()
end

local newScene = display.newScene
function display.newScene(name)
    local WAI_TAG = 1234
    local scene = newScene(name)
    for k,_ in pairs(jpg_rgb888) do
        scene:markAutoCleanupImage(k)
    end
    function scene:WaitForNet(delay)
        local child = self:getChildByTag(WAI_TAG)
        if not child then
            UIKit:newGameUI("GameUIWatiForNetWork",delay):AddToScene(self, true):zorder(4001):setTag(WAI_TAG)
        else
            child:DelayShow(delay)
        end
    end
    function scene:NoWaitForNet()
        self:removeChildByTag(WAI_TAG, true)
    end

    function scene:onEnterTransitionFinish()
        local message = UIKit:getMessageDialogWillShow()
        printLog("Info", "Check MessageDialog :%s %s",self.__cname,tolua.type(message))
        if message then
            print("add MessageDialog---->",self.__cname)
            message:AddToScene(self,false)
            UIKit:clearMessageDialogWillShow()
        end
    end
    return scene
end
local Node = cc.Node
function Node:scheduleAt(callback, interval)
    callback()
    return self:schedule(callback, interval or 1)
end
function scheduleAt(self, func, interval)
    return display.newNode():addTo(self):scheduleAt(func, interval)
end

display.__newLayer = display.newLayer

function display.newLayer()
    local layer = display.__newLayer()
    layer:setCascadeOpacityEnabled(true)
    return layer
end
display.__newNode = display.newNode
function display.newNode()
    local node = display.__newNode()
    node:setCascadeOpacityEnabled(true)
    return node
end
display.__newSprite = display.newSprite
function display.newSprite(...)
    local args = {...}
    local name = args[1]
    local found_data_in_plist = plist_texture_data[name]
    if found_data_in_plist then
        local frame = sharedSpriteFrameCache:getSpriteFrame(name)
        if not frame then
            local plistName = string.sub(found_data_in_plist,1,string.find(found_data_in_plist,"%.") - 1)
            plistName = string.format("%s.plist",plistName)
            display.addSpriteFrames(plistName,found_data_in_plist)
        end
        printInfo("newSprite: %s load plist texture:%s",name,found_data_in_plist)
        args[1] = string.format("#%s",name)
    end
    local sp = display.__newSprite(unpack(args))
    sp:setCascadeOpacityEnabled(true)
    return sp
end
display.__newScale9Sprite = display.newScale9Sprite

function display.newScale9Sprite(...)
    local sp = display.__newScale9Sprite(...)
    sp:setCascadeOpacityEnabled(true)
    return sp
end

display.__newClippingRegionNode = display.newClippingRegionNode

function display.newClippingRegionNode(...)
    local node = display.__newClippingRegionNode(...)
    node:setCascadeOpacityEnabled(true)
    return node
end

--打开json对null的支持
local cjson = require("cjson")
cjson.decode_lua_nil(false)
------------------------------------------------



