print("window")
local window = {}

window.width 					= 640
window.height 				= 960

local width_diff = (display.width - window.width)
local half_width_diff = width_diff / 2
window.left 					= display.left + half_width_diff
window.right 					= display.right - half_width_diff

local height_diff = (display.height - window.height)
local half_height_diff = height_diff / 2
window.top 					= display.top
window.bottom 				= display.bottom + height_diff

window.cx 					= window.left + window.width / 2
window.cy                 	= window.bottom + window.height / 2
window.top_bottom           = display.height - 91 
window.bottom_top           = window.bottom + 68 + 10 -- 底部tab按钮的上端y值
window.betweenHeaderAndTab  = display.height - window.bottom_top - 91 -- 91是顶部的计算高度
return window