--
-- Author: Danny He
-- Date: 2015-08-03 20:53:25
--
local Store = {}
local productIds = {
    "com.dragonfall.2500dragoncoins",
    "com.dragonfall.5500dragoncoins",
    "com.dragonfall.12000dragoncoins",
    "com.dragonfall.35000dragoncoins",
    "com.dragonfall.80000dragoncoins",
}
local function checkCCStore()
    if not ext.store then
        printError("Store - ext.store not exists.")
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

    if type(verifyFunction) ~= "function"  or  type(failedFunction) ~= "function" then
        printError("Store.init() - invalid listener")
        return false
    end

    cc.storeProvider = ext.store
    return cc.storeProvider.init(verifyFunction,failedFunction)
end

function Store.getReceiptVerifyMode()
    if not checkCCStore() then return false end
    printError("Store.getReceiptVerifyMode - Not support on Android")
end

function Store.setReceiptVerifyMode(mode, isSandbox)
    if not checkCCStore() then return false end
    printError("Store.setReceiptVerifyMode - Not support on Android")
end

function Store.getReceiptVerifyServerUrl()
    if not checkCCStore() then return false end
    printError("Store.getReceiptVerifyServerUrl - Not support on Android")
end

function Store.setReceiptVerifyServerUrl(url)
    if not checkCCStore() then return false end

  	printError("Store.setReceiptVerifyServerUrl - Not support on Android")
end

function Store.canMakePurchases()
    if not checkCCStore() then return false end
    return cc.storeProvider.canMakePurchases()
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

    cc.storeProvider.loadProducts(productsId, listener)
    return true
end

function Store.cancelLoadProducts()
    if not checkCCStore() then return false end
    printError("Store.cancelLoadProducts - Not support on Android")
end

function Store.isProductLoaded(productId)
    if not checkCCStore() then return false end
    printError("Store.isProductLoaded - Not support on Android")
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
    cc.storeProvider.consumePurchase(transaction.transactionIdentifier)
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
    cc.storeProvider.updateTransactionStates(productIds)
end
--[[ 
    新加 构造一个Transaction
]]--
function Store.getTransactionWithIdentifier(identifier)
    if not checkCCStore() then return false end
    printError("Store.restore - Not support on Android")
    return identifier
end

--[[ 
    Android新加 构造一个Transaction
]]--
function Store.getTransactionDataWithPurchaseData(purchaseData)
    if not checkCCStore() or type(purchaseData) ~= 'string' then return false end
    local json_obj = json.decode(purchaseData)
    return {
        transactionIdentifier = json_obj.orderId,
        productIdentifier = json_obj.productId
    }
end

--[[ 
    新加 获取默认购买框架的支持
]] --

function Store.getStoreSupport()
    if Store.canMakePurchases() then return end
    cc.storeProvider.getStoreSupport()
end

return Store