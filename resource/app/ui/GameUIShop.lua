--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local cocos_promise = import("..utils.cocos_promise")
local Alliance = import("..entity.Alliance")
local Flag = import("..entity.Flag")
local WidgetPushButton = import("..widget.WidgetPushButton")
local promise = import("..utils.promise")
local window = import("..utils.window")
local GameUIShop = UIKit:createUIClass("GameUIShop", "GameUIWithCommonHeader")

function GameUIShop:ctor(city)
    GameUIShop.super.ctor(self, city, _("商城"))
    self.shop_city = city
end
function GameUIShop:onEnter()
    GameUIShop.super.onEnter(self)

    local list_view = self:CreateVerticalListView(window.left + 20, window.bottom + 70, window.right - 20, window.top - 100)
    local item = list_view:newItem()
    local content = display.newNode()
    content:setContentSize(cc.size(640, 0))
    local add_gem = 100000000
    local button = WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"}
        ,{scale9 = false}
    -- ,{
    --     disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
    -- }
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "金龙币增加十万",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 500)
        :onButtonClicked(function()
            local current = self.shop_city:GetUser():GetGemResource():GetValue() + add_gem
            -- NetManager:sendMsg("gem "..current, NOT_HANDLE)
            cocos_promise.promiseWithCatchError(NetManager:getSendGlobalMsgPromise("resources gem "..current))
        end)
    -- :setButtonEnabled(false)
    -- :SetFilter({
    --     disabled = nil
    -- })

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "重新生成OpenUDID",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 500)
        :onButtonClicked(function()
            if device.platform == 'ios' then
                ext.clearOpenUdid()
                app:restart()
            elseif device.platform == 'mac' then
                 device.showAlert("提示","改代码!",{_("确定")})
            end
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "草地",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 200)
        :onButtonClicked(function()
            cocos_promise.promiseWithCatchError(NetManager:getChangeToGrassPromise())
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "雪地",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 200)
        :onButtonClicked(function()
            cocos_promise.promiseWithCatchError(NetManager:getChangeToIceFieldPromise())
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "沙地",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 200)
        :onButtonClicked(function()
            cocos_promise.promiseWithCatchError(NetManager:getChangeToDesertPromise())
        end)


    -- print(Alliance_Manager:GetMyAlliance():JoinType())
    local join_btn = WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = string.format("联盟类型到%s", Alliance_Manager:GetMyAlliance():JoinType() == "all" and "审核" or "直接"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 300)
        :onButtonClicked(function(event)
            if event.target:getButtonLabel():getString() == "联盟类型到直接" then
                event.target:getButtonLabel():setString("联盟类型到审核")
                -- NetManager:editAllianceJoinType("all", NOT_HANDLE)
                cocos_promise.promiseWithCatchError(NetManager:getEditAllianceJoinTypePromise("all")):done(function(result)
                    dump(result)
                end)
            else
                event.target:getButtonLabel():setString("联盟类型到直接")
                -- NetManager:editAllianceJoinType("audit", NOT_HANDLE)
                cocos_promise.promiseWithCatchError(NetManager:getEditAllianceJoinTypePromise("audit")
                ):done(function(result)
                    dump(result)
                end)
            end
        end)

    -- local member_id
    -- for _, v in ipairs(Alliance_Manager:GetMyAlliance():JoinRequestEvents()) do
    --     if v.id ~=  DataManager:getUserData()._id then
    --         member_id = v.id
    --     end
    -- end
    local join_btn = WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "拒绝一个申请",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 300)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getRefuseJoinAllianceRequestPromise(member_id)):done(function(result)
                dump(result)
            end)
        end)
    local join_btn = WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "接受一个申请",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 300)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getAgreeJoinAllianceRequestPromise(member_id)):done(function(result)
                dump(result)
            end)
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "创建联盟1",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 400)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getCreateAlliancePromise("1", "111", "all", "grassLand", Flag:RandomFlag():EncodeToJson())
                :done(function(result)
                    dump(result)
                end))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "立即加入联盟1",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 400)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getFetchCanDirectJoinAlliancesPromise("1"):next(function(result)
                -- dump(result)
                return NetManager:getJoinAllianceDirectlyPromise(Alliance:DecodeFromJsonData(result.alliances[1]):Id())
            end))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "请求加入联盟1",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 400)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getSearchAllianceByTagPromsie("1"):next(function(result)
                return NetManager:getRequestToJoinAlliancePromise(Alliance:DecodeFromJsonData(result.alliances[1]):Id())
            end))
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "退出联盟 1",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 500)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getQuitAlliancePromise())
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "创建联盟2",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 600)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getCreateAlliancePromise("2", "222", "all", "grassLand", Flag:RandomFlag():EncodeToJson()))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "立即加入联盟2",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 600)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getSearchAllianceByTagPromsie("2"):next(function(result)
                return NetManager:getJoinAllianceDirectlyPromise(Alliance:DecodeFromJsonData(result.alliances[1]):Id())
            end))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "请求加入联盟2",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 600)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getSearchAllianceByTagPromsie("2"):next(function(result)
                return NetManager:getRequestToJoinAlliancePromise(Alliance:DecodeFromJsonData(result.alliances[1]):Id())
            end))
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "邀请2进入联盟",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 700)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getInviteToJoinAlliancePromise("71Eb79lF"):next(function(result)
                dump(result)
            end))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "显示帧率",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 700)
        :onButtonClicked(function(event)
            DEBUG_FPS = not DEBUG_FPS
            cc.Director:getInstance():setDisplayStats(DEBUG_FPS)
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "随机踢出一个成员",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 700)
        :onButtonClicked(function(event)
            local memberid
            Alliance_Manager:GetMyAlliance():IteratorAllMembers(function(_, v)
                if v:Id() ~= User:Id() then
                    memberid = v:Id()
                    return true
                end
            end)
            cocos_promise.promiseWithCatchError(NetManager:getKickAllianceMemberOffPromise(memberid)
                :next(function(data)
                    dump(data)
                end))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "随机提升一个成员",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 800)
        :onButtonClicked(function(event)
            local member
            Alliance_Manager:GetMyAlliance():IteratorAllMembers(function(_, v)
                if v:Id() ~= User:Id() then
                    member = v
                    return true
                end
            end)
            if not member:IsTitleHighest() then
                cocos_promise.promiseWithCatchError(NetManager:getEditAllianceMemberTitlePromise(member:Id(), member:TitleUpgrade())
                    :next(function(data)
                        dump(data)
                    end))
            end
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "随机降级一个成员",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 800)
        :onButtonClicked(function(event)
            local member
            Alliance_Manager:GetMyAlliance():IteratorAllMembers(function(_, v)
                if v:Id() ~= User:Id() then
                    member = v
                    return true
                end
            end)
            if not member:IsTitleLowest() then
                cocos_promise.promiseWithCatchError(NetManager:getEditAllianceMemberTitlePromise(member:Id(), member:TitleDegrade())
                    :next(function(data)
                        dump(data)
                    end))
            end
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "移交萌主到随机成员",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 800)
        :onButtonClicked(function(event)
            local member
            Alliance_Manager:GetMyAlliance():IteratorAllMembers(function(_, v)
                if v:Id() ~= User:Id() then
                    member = v
                    return true
                end
            end)
            if Alliance_Manager:GetMyAlliance():GetMemeberById(User:Id()):IsArchon() then
                cocos_promise.promiseWithCatchError(NetManager:getHandOverArchonPromise(member:Id())
                    :next(function(data)
                        dump(data)
                    end))
            end
        end)



    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "发布一个随机公告",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 900)
        :onButtonClicked(function(event)
            math.randomseed(os.time())
            cocos_promise.promiseWithCatchError(NetManager:getEditAllianceNoticePromise("随机数公告: "..math.random(123456789)))

        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "发布一个随机描述",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 900)
        :onButtonClicked(function(event)
            math.randomseed(os.time())
            cocos_promise.promiseWithCatchError(NetManager:getEditAllianceDescriptionPromise("随机描述: "..math.random(123456789)))
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "随机修改萌主名字",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 900)
        :onButtonClicked(function(event)
            math.randomseed(os.time())
            cocos_promise.promiseWithCatchError(NetManager:getEditTitleNamePromise("archon", "萌主"..math.random(10)))
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "同意加入联盟",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1000)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getAgreeJoinAllianceInvitePromise(User:InviteToAllianceEvents()[1].id):next(function(ee)
                dump(ee)
            end))
        end)


    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "撤销加入联盟",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1000)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getCancelJoinAlliancePromise(
                User:RequestToAllianceEvents()[1].id
            ):next(function(ee)
                dump(ee)
            end))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "拒绝一个邀请",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1000)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(NetManager:getDisagreeJoinAllianceInvitePromise(
                User:InviteToAllianceEvents()[1].id
            ))
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "随机移动圣殿",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1100)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(
                NetManager:getMoveAllianceBuildingPromise(
                    "shrine", 14, 8
                )
            )
        end)
    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "修改联盟荣耀 100000",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1100)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(
                NetManager:getSendGlobalMsgPromise("alliancehonour 100000")
            )
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "随机移动城市",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1100)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(
                NetManager:getMoveAllianceMemberPromise(
                    14, 15
                )
            )
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "获取拆除道具",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1200)
        :onButtonClicked(function(event)
            NetManager:getBuyItemPromise("torch",1)
        end)




    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "联盟洞察力500",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1200)
        :onButtonClicked(function(event)
            NetManager:getSendGlobalMsgPromise("allianceperception "..500)
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "构建月门战测试环境1",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1200)
        :onButtonClicked(function(event)
            -- 重置玩家和联盟数据
            cocos_promise.promiseWithCatchError(
                -- 增加金龙币
                NetManager:getSendGlobalMsgPromise("gem "..1000000)
                    -- 升级城堡到4级
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    -- 解锁军帐
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(8)
                    end)
                    -- 解锁兵营
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(7)
                    end)
                    -- 招募士兵
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("swordsman", 20, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("ranger", 20, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("catapult", 5, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("lancer", 5, cb)
                    end)
                    -- 孵化龙
                    :next(function()
                        return NetManager:getSendGlobalMsgPromise("dragonstar redDragon 3 ")
                    end)
                    -- 创建联盟
                    :next(function()
                        return NetManager:getCreateAlliancePromise("jordan", "aj23", "all",  "grassLand", Flag:RandomFlag():EncodeToJson())
                    end)
            )
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "构建月门战测试环境2",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1300)
        :onButtonClicked(function(event)
            -- 重置玩家和联盟数据
            cocos_promise.promiseWithCatchError(
                -- 增加金龙币
                NetManager:getSendGlobalMsgPromise("gem "..1000000)
                    -- 升级城堡到4级
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    -- 解锁军帐
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(8)
                    end)
                    -- 解锁兵营
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(7)
                    end)
                    -- 招募士兵
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("swordsman", 20, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("ranger", 20, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("catapult", 5, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("lancer", 5, cb)
                    end)
                    -- 孵化龙
                    :next(function()
                        return NetManager:getSendGlobalMsgPromise("dragonstar blueDragon 3 ")
                    end)

                    -- 创建联盟
                    :next(function()
                        return NetManager:getCreateAlliancePromise("iverson", "ai3", "all",  "grassLand", Flag:RandomFlag():EncodeToJson())
                    end)
            )
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "构建月门战测试环境3",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1300)
        :onButtonClicked(function(event)
            -- 重置玩家和联盟数据
            cocos_promise.promiseWithCatchError(
                -- 增加金龙币
                NetManager:getSendGlobalMsgPromise("resources gem "..1000000)
                    -- 升级城堡到4级
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(1)
                    end)
                    -- 解锁军帐
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(8)
                    end)
                    -- 解锁兵营
                    :next(function()
                        return NetManager:getInstantUpgradeBuildingByLocationPromise(5)
                    end)
                    -- 招募士兵
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("swordsman", 20, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("ranger", 20, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("catapult", 5, cb)
                    end)
                    :next(function()
                        return NetManager:getInstantRecruitNormalSoldierPromise("lancer", 5, cb)
                    end)
                    -- 孵化龙
                    :next(function()
                        return NetManager:getSendGlobalMsgPromise("dragonstar blueDragon 3 ")
                    end)
            )
        end)
    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "驻防龙",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1300)
        :onButtonClicked(function(event)
            cocos_promise.promiseWithCatchError(
                NetManager:getSetDefenceDragonPromise("redDragon")
            )
        end)
    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "音乐开关->"  .. (app:GetAudioManager():GetBackgroundMusicState() and "on" or "off"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1400)
        :onButtonClicked(function(event)
            app:GetAudioManager():SwitchBackgroundMusicState(not app:GetAudioManager():GetBackgroundMusicState())
            event.target:setButtonLabelString("音乐开关->" .. (app:GetAudioManager():GetBackgroundMusicState() and "on" or "off"))
        end)
    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "音效开关->" .. (app:GetAudioManager():GetEffectSoundState() and "on" or "off"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1400)
        :onButtonClicked(function(event)
            app:GetAudioManager():SwitchEffectSoundState(not app:GetAudioManager():GetEffectSoundState())
            event.target:setButtonLabelString("音效开关->" .. (app:GetAudioManager():GetEffectSoundState() and "on" or "off"))
        end)
    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "游戏说明",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1400)
        :onButtonClicked(function(event)
            UIKit:newGameUI("GameUITips"):AddToCurrentScene(true)
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "在线人数",
        size = 20,
        font = UIKit:getFontFilePath(),
        color = cc.c3b(0,0,255)}))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1500)
        :onButtonClicked(function(event)
            NetManager:getServersPromise():done(function(response)
                if response.msg.code == 200 then
                    local servers = response.msg.servers
                    local str = ""
                    for __,v in ipairs(servers) do
                        str = str .. string.format("%s %d\n",v.id,v.userCount)
                    end
                     device.showAlert("在线人数", str,{_("确定")})
                end
            end)
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "版本信息",
        size = 20,
        font = UIKit:getFontFilePath(),
        color =  cc.c3b(255,0,0)
    }))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1500)
        :onButtonClicked(function(event)
            device.showAlert("版本信息", app:showDebugInfo(),{_("确定")})
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "匹配联盟战",
        size = 20,
        font = UIKit:getFontFilePath(),
        color =  UIKit:hex2c3b(0xfff3c7)
    }))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1500)
        :onButtonClicked(function(event)
            NetManager:getFindAllianceToFightPromose()
        end)
    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "升级学院生产科技",
        size = 20,
        font = UIKit:getFontFilePath(),
        color =  UIKit:hex2c3b(0xfff3c7)
    }))
        :addTo(content)
        :align(display.CENTER, window.left + 140, window.top - 1600)
        :onButtonClicked(function(event)
            NetManager:getUpgradeProductionTechPromise("crane",false):next(function(msg)
                dump(msg)
            end)
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "调试联盟数据",
        size = 20,
        font = UIKit:getFontFilePath(),
        color =  cc.c3b(255,0,0)
    }))
        :addTo(content)
        :align(display.CENTER, window.left + 320, window.top - 1600)
        :onButtonClicked(function(event)
            local alliance = Alliance_Manager:GetMyAlliance()
            if not alliance:IsDefault() then 
                device.showAlert("提示",alliance:Id(),{_("确定")})
            end
        end)

    WidgetPushButton.new(
        {normal = "green_btn_up_169x86.png", pressed = "green_btn_down_169x86.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "OpenUDID调试",
        size = 20,
        font = UIKit:getFontFilePath(),
        color =  cc.c3b(255,0,0)
    }))
        :addTo(content)
        :align(display.CENTER, window.left + 500, window.top - 1600)
        :onButtonClicked(function(event)
                local str = string.format("OpenUDID:%s",device.getOpenUDID())
                device.showAlert("提示",str,{_("确定")})
        end)
    item:addContent(content)
    item:setItemSize(640, 1000)
    list_view:addItem(item)
    list_view:reload()
    -- :resetPosition()
end
function GameUIShop:onExit()
    GameUIShop.super.onExit(self)
end


return GameUIShop
















