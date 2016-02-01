-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2
DEBUG_FPS = false
DEBUG_MEM = false

-- design resolution
CONFIG_SCREEN_WIDTH = 640
CONFIG_SCREEN_HEIGHT = 960

-- auto scale mode
CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"
CONFIG_SCREEN_ORIENTATION = "portrait"
-- big version config
CONFIG_APP_VERSION = "0.0.1"

LOAD_DEPRECATED_API = true

-- server config
CONFIG_LOCAL_SERVER = {
    update = {
        host = "127.0.0.1",
        port = 3000,
        name = "update-server-1"
    },
    gate = {
        host = "127.0.0.1",
        port = 13100,
        name = "gate-server-1"
    },
}
CONFIG_REMOTE_SERVER = {
    update = {
        host = "54.223.172.65",
        port = 3000,
        name = "update-server-1"
    },
    gate = {
        host = "54.223.172.65",
        port = 13100,
        name = "gate-server-1"
    },
}
-- app store url
CONFIG_APP_URL = {
    ios = "https://itunes.apple.com/us/app/dragonfall-the-1st-moba-slg/id993631614?l=zh&ls=1&mt=8",
    android = "https://batcat.sinaapp.com/ad_hoc/build-index.html"
}
CONFIG_IS_LOCAL = false
-- 是否是测试版本 后面会删除这个变量 从plist/meta-data里面获取值，CONFIG_IS_DEBUG为true时三方sdk不会记录购买和事件信息，传到网关获取服务器信息
CONFIG_IS_DEBUG = true 
-- 是否记录日志文件 如果关闭lua错误将被发送到三方sdk
CONFIG_LOG_DEBUG_FILE = true 

GLOBAL_FTE = false
GLOBAL_FTE_DEBUG = false

-- 是否关闭自动更新,不设置表示打开自动更新
CONFIG_IS_NOT_UPDATE = true

CONFIG_SCREEN_AUTOSCALE_CALLBACK = function(w, h, deviceModel)
    if w/h > 640/960 then
        CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"
    end
end