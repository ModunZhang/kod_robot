local Store = {}
local productIds = {
    "com.dragonfall.2500dragoncoins",
    "com.dragonfall.5500dragoncoins",
    "com.dragonfall.12000dragoncoins",
    "com.dragonfall.35000dragoncoins",
    "com.dragonfall.80000dragoncoins",
}
local function checkCCStore()
    if not ext.adeasygo then
        printError("Store - ext.adeasygo not exists.")
        return false
    end
    return true
end

function Store.init(verifyFunction,failedFunction)
    if not checkCCStore() then return false end

    if cc.storeProvider then
        printError("Store.init() - store already init")
        return false
    end

    if type(verifyFunction) ~= "function" then
        printError("Store.init() - invalid listener")
        return false
    end

    cc.storeProvider = ext.adeasygo
    ext.adeasygo.registerPayDoneEvent(verifyFunction)
    ext.adeasygo.init()
    return true
end

function Store.getReceiptVerifyMode()
    if not checkCCStore() then return false end
    printError("Store.getReceiptVerifyMode - Not support on WP")
end

function Store.setReceiptVerifyMode(mode, isSandbox)
    if not checkCCStore() then return false end
    printError("Store.setReceiptVerifyMode - Not support on WP")
end

function Store.getReceiptVerifyServerUrl()
    if not checkCCStore() then return false end
    printError("Store.getReceiptVerifyServerUrl - Not support on WP")
end

function Store.setReceiptVerifyServerUrl(url)
    if not checkCCStore() then return false end

    printError("Store.setReceiptVerifyServerUrl - Not support on WP")
end

function Store.canMakePurchases()
    if not checkCCStore() then return false end
    return cc.storeProvider.canMakePurchases()
end


function Store.loadProducts(productsId, listener)
    if not checkCCStore() then return false end
    printError("Store.loadProducts - Not support on WP")
    return true
end

function Store.cancelLoadProducts()
    if not checkCCStore() then return false end
    printError("Store.cancelLoadProducts - Not support on WP")
end

function Store.isProductLoaded(productId)
    if not checkCCStore() then return false end
    printError("Store.isProductLoaded - Not support on WP") -- TODO:
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
    return cc.storeProvider.buy(productId)
end

function Store.restore()
    if not checkCCStore() then return false end
    printError("Store.restore - Not support on Android")
end

function Store.finishTransaction(transaction)
    if type(transaction) ~= "table" then
        printError("Store.finishTransaction - table")
        return false
    end
    if not checkCCStore() then return false end

    if not cc.storeProvider then
        printError("Store.finishTransaction() - store not init")
        return false
    end
    cc.storeProvider.consumePurchase(transaction.productIdentifier)
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
    return cc.storeProvider.buy(productId)
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
    cc.storeProvider.updateTransactionStates()
end
--[[ 
    新加 构造一个Transaction
]]--
function Store.getTransactionWithIdentifier(identifier)
    if not checkCCStore() then return false end
    printError("Store.restore - Not support on WP")
    return identifier
end

--[[ 
    Android新加 构造一个Transaction
]]--
function Store.getTransactionDataWithPurchaseData(purchaseData)
    printError("Store.getTransactionDataWithPurchaseData - Not support on WP")
   return purchaseData
end

--[[ 
    新加 获取默认购买框架的支持
]] --

function Store.getStoreSupport()
    printError("Store.getStoreSupport - Not support on WP")
    return true
end

--[[ 
    新加 验证微软收据
]] --

function Store.validateMSReceipts()
    if not checkCCStore() then return false end
    cc.storeProvider.validateMSReceipts()
end


return Store