--
-- Author: Danny He
-- Date: 2015-01-29 17:16:37
--
-- quick 3.2 里拷贝出来 修改bug 新加方法

local Store = {}

local function checkCCStore()
    if not cc.Store then
        printError("framework.cc.sdk.Store - cc.CCStore not exists.")
        return false
    end
    return true
end

function Store.init(listener)
    if not checkCCStore() then return false end

    if cc.storeProvider then
        printError("Store.init() - store already init")
        return false
    end

    if type(listener) ~= "function" then
        printError("Store.init() - invalid listener")
        return false
    end

    cc.storeProvider = cc.Store:sharedStore() -- avoid gc
    return cc.storeProvider:postInitWithTransactionListener(listener)
end

function Store.getReceiptVerifyMode()
    if not checkCCStore() then return false end
    return cc.storeProvider:getReceiptVerifyMode()
end

function Store.setReceiptVerifyMode(mode, isSandbox)
    if not checkCCStore() then return false end

    if type(mode) ~= "number"
        or (mode ~= cc.CCStoreReceiptVerifyModeNone
            and mode ~= cc.CCStoreReceiptVerifyModeDevice
            and mode ~= cc.CCStoreReceiptVerifyModeServer) then
        printError("Store.setReceiptVerifyMode() - invalid mode")
        return false
    end

    if type(isSandbox) ~= "boolean" then isSandbox = true end
    cc.storeProvider:setReceiptVerifyMode(mode, isSandbox)
end

function Store.getReceiptVerifyServerUrl()
    if not checkCCStore() then return false end
    return cc.storeProvider:getReceiptVerifyServerUrl()
end

function Store.setReceiptVerifyServerUrl(url)
    if not checkCCStore() then return false end

    if type(url) ~= "string" then
        printError("Store.setReceiptVerifyServerUrl() - invalid url")
        return false
    end
    cc.storeProvider:setReceiptVerifyServerUrl(url)
end

function Store.canMakePurchases()
    if not checkCCStore() then return false end
    return cc.storeProvider:canMakePurchases()
end

function Store.loadProducts(productsId, listener)
    if not checkCCStore() then return false end

    if type(listener) ~= "function" then
        printError("Store.loadProducts() - invalid listener")
        return false
    end

    if type(productsId) ~= "table" then
        printError("Store.loadProducts() - invalid productsId")
        return false
    end

    for i = 1, #productsId do
        if type(productsId[i]) ~= "string" then
            printError("Store.loadProducts() - invalid id[#%d] in productsId", i)
            return false
        end
    end

    cc.storeProvider:loadProducts(productsId, listener)
    return true
end

function Store.cancelLoadProducts()
    if not checkCCStore() then return false end
    cc.storeProvider:cancelLoadProducts()
end

function Store.isProductLoaded(productId)
    if not checkCCStore() then return false end
    return cc.storeProvider:isProductLoaded(productId)
end

function Store.purchase(productId)
    if not checkCCStore() then return false end

    if not cc.storeProvider then
        printError("Store.purchase() - store not init")
        return false
    end

    if type(productId) ~= "string" then
        printError("Store.purchase() - invalid productId")
        return false
    end

    return cc.storeProvider:purchase(productId)
end

function Store.restore()
    if not checkCCStore() then return false end
    cc.storeProvider:restore()
end

function Store.finishTransaction(transaction)
    if type(transaction) == "string" then
        transaction = Store.getTransactionWithIdentifier(transaction)
    end
    if not checkCCStore() then return false end

    if not cc.storeProvider then
        printError("Store.finishTransaction() - store not init")
        return false
    end
    if type(transaction) ~= "table" or type(transaction.transactionIdentifier) ~= "string" then
        printError("Store.finishTransaction() - invalid transaction")
        return false
    end

    return cc.storeProvider:finishTransaction(transaction.transactionIdentifier)
end
--[[
	新加 客户端不请求商品信息的情况下 直接通过商品id进行内购
]]--
function Store.purchaseWithProductId(productId,count)
	if not checkCCStore() then return false end

    if not cc.storeProvider then
        printError("Store.purchaseWithProductId() - store not init")
        return false
    end

    if type(productId) ~= "string" then
        printError("Store.purchaseWithProductId() - invalid productId")
        return false
    end
	count = count or 1
	return cc.storeProvider:purchaseWithIdentifier(productId,count)
end
--[[
	新加 强制刷新客户端 购买列表的状态
]]--
function Store.updateTransactionStates()
	if not checkCCStore() then return false end

    if not cc.storeProvider then
        printError("Store.updateTransactionStates() - store not init")
        return false
    end
    cc.storeProvider:updateTransactionStates()
end
--[[ 
    新加 构造一个Transaction
]]--
function Store.getTransactionWithIdentifier(identifier)
    return {
        transactionIdentifier = identifier
    }
end

--[[ 
    新加 获取默认购买框架的支持
]] --

function Store.getStoreSupport()
    if Store.canMakePurchases() then return end
    printError("Store.getStoreSupport() -  Not support on iOS")
end

return Store
