--
-- Author: Danny He
-- Date: 2014-10-07 15:07:59
--

local my_filter  = filter
local UIButton = require("framework.cc.ui.UIButton")
local UIPushButton = cc.ui.UIPushButton
local WidgetPushButton = import(".WidgetPushButton")
local WidgetSequenceButton = class("WidgetSequenceButton",WidgetPushButton)

-- images, options, filters 参数同WidgetPushButton

function WidgetSequenceButton:ctor(images,options,seqImages,seqFilters,initial_state)
	-- assert(initial_state)
	self.seqImages_ = {}
	self.seqsprite_ = {}
	self.seqFilter_ = {}
	self.isImageState = false
	self.scale_ = options and options.scale or 1.0
	if type(seqImages) == 'table' then
		local events = {}
	    -- image Sequence
		local countOfimages = #seqImages
		if countOfimages > 1 then
			self.isImageState = true
			self.events_ = seqImages
	    elseif countOfimages == 1 and seqFilters then
	    	self.events_ = seqFilters
		end
		local index_init = -1

    	for i,v in ipairs(self.events_) do
    		if initial_state and v.name == initial_state then
    			self:setCurrentIndex_(i)
    		end
    		if self.isImageState then
    			self:setButtonSeqImage(v.name,v.image,true)
    		else
    			self:setButtonFilter(v.name,v.color,true)
    		end
    	end
    	self:addNodeEventListener(cc.NODE_EVENT, function(event)
	        if event.name == "enter" then
    			if self.isImageState then
    				self:updateSeqButtonImage_()
    			else
	            	self:updateSeqButtonImage_(seqImages[1].image)
	            end
	        end
    	end)
	end
	-- call super	
	WidgetSequenceButton.super.ctor(self,images, options, {disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}})
	WidgetSequenceButton.super.onButtonClicked(self,handler(self, self.onButtonClicked_))
end

function WidgetSequenceButton:onButtonClicked()
	assert(false,"WidgetSequenceButton is not support onButtonClicked!")
end

function WidgetSequenceButton:setButtonFilter(state,color,ignoreEmpty)
	 if ignoreEmpty and color == nil then return end
	 self.seqFilter_[state] = color
end

function WidgetSequenceButton:setButtonSeqImage(state, image, ignoreEmpty)
    if ignoreEmpty and image == nil then return end
    self.seqImages_[state] = image
    if state == self:getCurrentEvent().name then
        self:updateSeqButtonImage_()
    end
    return self
end

function WidgetSequenceButton:GetSeqState()
	return self:getCurrentEvent().name
end

function WidgetSequenceButton:onSeqStateChange(func)
	self:addEventListener("onSeqStateChange", func)
	return self
end


function WidgetSequenceButton:onSeqStateChange_(dispath_event)
	if type(dispath_event) ~= 'boolean' then dispath_event = true end
	-- if self:isRunning() then
		if self.isImageState then
        	self:updateSeqButtonImage_()
        else
        	self:updateSeqButtonImage_(self.currentSeqImage_)
        end
        if dispath_event then
        	self:dispatchEvent({name = "onSeqStateChange",state = self:GetSeqState()})
        end
    -- end
end

function WidgetSequenceButton:align(align, x, y)
	WidgetSequenceButton.super.align(self,align, x, y)
	self:updateSeqButtonImage_()
    return self
end


function WidgetSequenceButton:updateSeqButtonImage_(oneImage)
	if not oneImage then
		local state = self:getCurrentEvent().name
	    local image = self.seqImages_[state]

	    if image then
	        if self.currentSeqImage_ ~= image then
	            for i,v in ipairs(self.seqsprite_) do
	                v:removeFromParent(true)
	            end
	            self.seqsprite_ = {}
	            self.currentSeqImage_ = image
				self.seqsprite_[1] = display.newSprite(image)
	            if self.seqsprite_[1].setFlippedX then
	                self.seqsprite_[1]:setFlippedX(self.flipX_ or false)
	                self.seqsprite_[1]:setFlippedY(self.flipY_ or false)
	            end
	            self.seqsprite_[1]:setScale(self.scale_)
	            self:addChild(self.seqsprite_[1], UIButton.IMAGE_ZORDER+1)
	        end
	        for i,v in ipairs(self.seqsprite_) do
	            v:setAnchorPoint(self:getAnchorPoint())
	            v:setPosition(0, 0)
	        end
	    end
	else
		local state = self:getCurrentEvent().name
		local filter = self.seqFilter_[state]
    	local customParams = {frag = "shaders/customer_color.fsh",
					shaderName = state,
					color = filter}
		local params = json.encode(customParams)
        if self.seqsprite_ and self.seqsprite_[1] then
        	self:SetFilterOnSprite(self.seqsprite_[1],{
        		name = "CUSTOM",
	        	params = params
        	})
        else
        	self.seqsprite_ = {}
        	self.currentSeqImage_ = oneImage

			self.seqsprite_[1] =  display.newSprite(oneImage, nil, nil, {class=cc.FilteredSpriteWithOne})
	        if self.seqsprite_[1].setFlippedX then
	            self.seqsprite_[1]:setFlippedX(self.flipX_ or false)
	            self.seqsprite_[1]:setFlippedY(self.flipY_ or false)
	        end
	        self:SetFilterOnSprite(self.seqsprite_[1],{
	        	name = "CUSTOM",
	        	params = params
	        })
	        self.seqsprite_[1]:setScale(self.scale_)
	        self:addChild(self.seqsprite_[1], UIButton.IMAGE_ZORDER+1)
	        for i,v in ipairs(self.seqsprite_) do
	            v:setAnchorPoint(self:getAnchorPoint())
	            v:setPosition(0, 0)
	        end
        end
       
	end
end

function WidgetSequenceButton:onButtonClicked_(event)
		--change state
		if not self.events_ then return end
		local next_index = self:getNextIndex_()
		self:setCurrentIndex_(next_index)
		self:onSeqStateChange_()
end

function WidgetSequenceButton:setSeqState( state,dispath_event)
	self:doEvent(state,dispath_event)
end


function WidgetSequenceButton:setCurrentIndex_( index )
	if index > 0 and index<= #self.events_ then
		self.indexOfEvent_  = index
	end
end

function WidgetSequenceButton:getNextIndex_()
	if self.indexOfEvent_ >= #self.events_ then
		return 1
	else
		return self.indexOfEvent_ + 1
	end
end

function WidgetSequenceButton:getCurrentIndex_()
	return self.indexOfEvent_
end

function WidgetSequenceButton:getCurrentEvent()
	if not self.indexOfEvent_ then
		self:setCurrentIndex_(1)
	end
	return self.events_[self.indexOfEvent_]
end

function WidgetSequenceButton:getNextEvent()
	local index = self.indexOfEvent_
	if index then
		if index >= #self.events_ then
			index = 1
		else
			index = index + 1
		end
	end
	self.indexOfEvent_ = index
	return self:getCurrentEvent()
end

function WidgetSequenceButton:doEvent(state,dispath_event)
	local indexOfState = -1
	for i,v in ipairs(self.events_) do
	 	if v.name == state then
	 		indexOfState = i
	 		break
	 	end
	 end
	 if indexOfState > 0 and indexOfState ~= self:getCurrentIndex_() then
	 	self:setCurrentIndex_(indexOfState)
	 	self:onSeqStateChange_(dispath_event)
	 end
end


return WidgetSequenceButton