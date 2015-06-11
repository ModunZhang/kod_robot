local IsoMapAnchorBottomLeft = class("IsoMapAnchorBottomLeft")
function IsoMapAnchorBottomLeft:ctor(map_info)
    self.tile_w = map_info.tile_w
    self.tile_h = map_info.tile_h
    self.map_width = map_info.map_width
    self.map_height = map_info.map_height
    self.base_x = map_info.base_x + self.tile_w / 2
    self.base_y = map_info.base_y + self.tile_h
end
function IsoMapAnchorBottomLeft:GetSize()
    return self.map_width, self.map_height
end
function IsoMapAnchorBottomLeft:ConvertToMapPosition(x, y)
    return (x - y) * self.tile_w * 0.5 + self.base_x, self.base_y - (y + x + 1) * self.tile_h * 0.5
end
function IsoMapAnchorBottomLeft:ConvertToLogicPosition(x, y)
    local w = self.tile_w
    local h = self.tile_h
    vec_x = x - self.base_x
    vec_y = y - self.base_y
    return math.floor(vec_x / w - vec_y / h), math.floor(- vec_x / w - vec_y / h)
end
function IsoMapAnchorBottomLeft:ConvertToLocalPosition(x, y)
    return (y - x) * self.tile_w * 0.5, (y + x) * self.tile_h * 0.5
end



return IsoMapAnchorBottomLeft