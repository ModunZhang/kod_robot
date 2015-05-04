local Enum = import("..utils.Enum")
local WidgetUIBackGround = class("WidgetUIBackGround", function ()
    return display.newNode()
end)

WidgetUIBackGround.STYLE_TYPE = Enum("STYLE_1","STYLE_2","STYLE_3","STYLE_4","STYLE_5","STYLE_6")

local STYLES = {
    [1]= {
        top_img = "back_ground_608x22.png",
        bottom_img = "back_ground_608x62.png",
        mid_img = "back_ground_608X98.png",
    },
    [2] = {
        top_img = "back_ground_568x16_top.png",
        bottom_img = "back_ground_568x80_bottom.png",
        mid_img = "back_ground_568x28_mid.png",
        u_height =16,
        m_height=28,
        b_height=80,
    }
}

function WidgetUIBackGround:ctor(params,style)
    local width = params.width or 608
    local height = params.height or 100
    self:setContentSize(cc.size(width,height))
    if style == WidgetUIBackGround.STYLE_TYPE.STYLE_5 then
        display.newScale9Sprite("back_ground_398x97.png", 0, 0,cc.size(width,height),cc.rect(20,20,358,57))
            :align(display.LEFT_BOTTOM)
            :addTo(self)
        return
    elseif style == WidgetUIBackGround.STYLE_TYPE.STYLE_4 then
        display.newScale9Sprite("back_ground_484X98.png",0 , 0,cc.size(width,height),cc.rect(15,10,454,78))
            :align(display.LEFT_BOTTOM)
            :addTo(self)
        return
    elseif style == WidgetUIBackGround.STYLE_TYPE.STYLE_3 then
        display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(width,height),cc.rect(15,10,136,64))
            :align(display.LEFT_BOTTOM)
            :addTo(self)
        return
    elseif style == WidgetUIBackGround.STYLE_TYPE.STYLE_6 then
        display.newScale9Sprite("background_568x556.png",0 , 0,cc.size(width,height),cc.rect(10,10,548,536))
        :align(display.LEFT_BOTTOM)
            :addTo(self)
        return
    end
    local st = STYLES[style]
    local top_img = st and st.top_img or params.top_img or "back_ground_608x22.png"
    local bottom_img = st and st.bottom_img or params.bottom_img or "back_ground_608x62.png"
    local mid_img = st and st.mid_img or params.mid_img or "back_ground_608X98.png"
    -- 上中下三段的图片高度
    local u_height = st and st.u_height or params.u_height or 22
    local m_height = st and st.m_height or params.m_height or 98
    local b_height = st and st.b_height or params.b_height or 62
    local b_flip = st and st.b_flip or params.b_flip
    local is_have_frame = params.isFrame or "no"
    local capInsets = params.capInsets

    --top
    display.newScale9Sprite(top_img,0, height,cc.size(width,u_height),capInsets):align(display.LEFT_TOP):addTo(self)
    local bottom = display.newScale9Sprite(bottom_img,0, 0,cc.size(width,b_height),capInsets):align(display.LEFT_BOTTOM):addTo(self)

    --bottom
    if b_flip then
        bottom:align(display.LEFT_TOP)
        bottom:setRotationSkewX(180)
    end
    --center
    local need_filled_height = height-(u_height+b_height) --中间部分需要填充的高度
    local center_y = b_height -- 中间部分起始 y 坐标
    local  next_y = b_height
    -- 需要填充的剩余高度大于中间部分图片原始高度时，直接复制即可
    while need_filled_height>=m_height do
        display.newScale9Sprite(mid_img, 0, next_y,cc.size(width,m_height)):align(display.LEFT_BOTTOM):addTo(self)
        need_filled_height = need_filled_height - m_height
        next_y = next_y+m_height
    end
    -- 最后一块小于中间部分图片原始高度时，缩放高度
    if need_filled_height>0 then
        display.newScale9Sprite(mid_img, 0, next_y,cc.size(width,m_height))
            :align(display.LEFT_BOTTOM,0, next_y)
            :addTo(self):setScaleY(need_filled_height/m_height)
    end

    -- 添加边框
    if is_have_frame == "yes" and top_img=="back_ground_608x22.png" then
        display.newSprite("shrie_state_item_line_606_16.png"):addTo(self):align(display.LEFT_TOP,0, height-2)
        display.newSprite("shrie_state_item_line_606_16.png"):addTo(self):align(display.LEFT_BOTTOM,0, 4):flipY(true)
    end
end

return WidgetUIBackGround










