local GameUIFteKeep = UIKit:createUIClass('GameUIFteKeep',"GameUIKeep")


function GameUIFteKeep:ctor(...)
	GameUIFteKeep.super.ctor(self, ...)
	self.__type  = UIKit.UITYPE.BACKGROUND
end



return GameUIFteKeep