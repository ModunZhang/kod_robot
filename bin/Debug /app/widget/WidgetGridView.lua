local WidgetGridView = class("WidgetGridView", cc.ui.UIListView)


function WidgetGridView:ctor(params, col)
	WidgetGridView.super.ctor(self, params)
	self.column = col
	self.row_items = {}
end

function WidgetGridView:NewRowItem()
	local item = self:newItem()

	return item
end




return WidgetGridView