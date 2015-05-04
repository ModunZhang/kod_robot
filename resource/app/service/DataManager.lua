DataManager = {}

function DataManager:setUserData( userData, deltaData )
    self.user = userData
    self:OnUserDataChanged(self.user, app.timer:GetServerTime(), deltaData)
end
function DataManager:setUserAllianceData(allianceData,deltaData)
	self.allianceData = allianceData
	if allianceData == json.null then return end
	Alliance_Manager:OnAllianceDataChanged(allianceData,app.timer:GetServerTime(),deltaData)
end

function DataManager:getUserAllianceData()
	return self.allianceData
end

function DataManager:getUserData(  )
    return self.user
end

function DataManager:setEnemyAllianceData(enemyAllianceData,deltaData)
	self.enemyAllianceData = enemyAllianceData
	Alliance_Manager:OnEnemyAllianceDataChanged(enemyAllianceData,app.timer:GetServerTime(),deltaData)
end

function DataManager:getEnemyAllianceData()
	return self.enemyAllianceData
end

function DataManager:OnUserDataChanged(userData,timer, deltaData)
	User:OnUserDataChanged(userData, timer, deltaData)
	ItemManager:OnUserDataChanged(userData, timer, deltaData)
    City:OnUserDataChanged(userData, timer, deltaData)
    Alliance_Manager:OnUserDataChanged(userData, timer, deltaData)
    MailManager:OnUserDataChanged(userData, timer, deltaData)
end

