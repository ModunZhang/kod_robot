--
-- Author: Danny He
-- Date: 2015-04-02 17:29:32
--
local GameUIAllianceRuinsEnter = UIKit:createUIClass("GameUIAllianceRuinsEnter","GameUIAllianceVillageEnter")

function GameUIAllianceRuinsEnter:IsRuins()
	return true
end

function GameUIAllianceRuinsEnter:GetUIHeight()
	return 200
end

return GameUIAllianceRuinsEnter