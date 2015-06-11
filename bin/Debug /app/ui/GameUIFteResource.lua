local GameUIFteResource = UIKit:createUIClass("GameUIFteResource","GameUIResource")


function GameUIFteResource:ctor(...)
	GameUIFteResource.super.ctor(self, ...)
	self.__type  = UIKit.UITYPE.BACKGROUND
end


return GameUIFteResource