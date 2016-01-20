--
-- Author: DoooReyn
-- Date: 2016-01-20 20:59:37
--

local ListView = ccui.ListView
--------------------------------------------------------------
------------Below Are Custom UIListView Parameters------------
--------------------------------------------------------------
ListView._sliderBar = nil               --SliderBar objection
ListView._sliderBg  = nil               --SliderBarBg objection
ListView._slideInTime  = 0.2            --Time of slideBar fade In
ListView._slideOutTime = 0.4            --Time of sliderBar fade Out
ListView._scrollBottomCallback = nil    --CallFunc when scrolled to bottom
ListView._scrollTopCallback = nil       --CallFunc when scrolled to top
ListView._scrollingCallback = nil       --CallFunc when scrolling
ListView._sliderBarCallback = nil       --CallFunc when scrolling of sliderBar
ListView._isEnableScrollListener = false--Flag of enable scroll listener
ListView._isShowLabel = false           --Flag of enable show itemModel's label
local ITEM_MODEL_NAME = 'ItemModel'     --Name of itemModel
local ITEM_LABEL_NAME = 'ItemLabel'     --Name of itemModel's label

--------------------------------------------------------------
----------Below Are Some UIListView Common Functions----------
--------------------------------------------------------------
function ListView:setScrollBottomCallback (callback)
    if callback then
        self._scrollBottomCallback = callback
    end
end

function ListView:setScrollingCallback(callback)
    if callback then
        self._scrollingCallback = callback
    end
end

function ListView:onEvent(callback)
    self:addEventListener(function(sender, eventType)
        local event = {}
        if eventType == 0 then
            event.name = "ON_SELECTED_ITEM_START"
        else
            event.name = "ON_SELECTED_ITEM_END"
        end
        event.target = sender
        callback(event)
    end)
    return self
end

function ListView:enableScrollListener ()
    if self._isEnableScrollListener then
        print('[Info] Listview scroll listener has enabled')
        return
    end
    print('[Info] Enable listview scroll listener succeess')
    self._isEnableScrollListener = true
    self:onScroll(function(event) end)
end

function ListView:onScroll(callback)
    self:addScrollViewEventListener(function(sender, eventType)
        local event = {}
        if eventType == 0 then
            event.name = "SCROLL_TO_TOP"
        elseif eventType == 1 then
            event.name = "SCROLL_TO_BOTTOM"
            if self._scrollBottomCallback then
                self._scrollBottomCallback()
            end
        elseif eventType == 2 then
            event.name = "SCROLL_TO_LEFT"
        elseif eventType == 3 then
            event.name = "SCROLL_TO_RIGHT"
        elseif eventType == 4 then
            event.name = "SCROLLING"
            if self._scrollingCallback then
                self._scrollingCallback()
            end
            if self._sliderBarCallback then
                self._sliderBarCallback()
            end
        elseif eventType == 5 then
            event.name = "BOUNCE_TOP"
        elseif eventType == 6 then
            event.name = "BOUNCE_BOTTOM"
        elseif eventType == 7 then
            event.name = "BOUNCE_LEFT"
        elseif eventType == 8 then
            event.name = "BOUNCE_RIGHT"
        end
        event.target = sender
        callback(event)
    end)
    return self
end

function ListView:clearViewAndRefresh()
    -- the same effect as ListView:removeAllChidren()
    self:removeAllItems() 
    self:refreshView()
end

function ListView:refreshViewTop()
    self:refreshView()
    self:jumpToTop()
end

function ListView:refreshViewBottom()
    self:refreshView()
    self:jumpToBottom()
end

function ListView:setInnerContainerPosition(pos)
    self:getInnerContainer():setPosition(pos)
end

function ListView:getInnerContainerPosition()
    return self:getInnerContainer():getPosition()
end

--------------------------------------------------------------
--------Below Is An Implement of UIListView SliderBar---------
--------------------------------------------------------------

function ListView:setSlideInTime (inTime)
    self._slideInTime = inTime
end

function ListView:setSlideOutTime(outTime)
    self._slideOutTime = outTime
end

function ListView:setSliderBar (bar, barBg)
    if not bar then return end
    if not barBg then return end
    if bar   == self._sliderBar then return end --prevent repeating everytime
    if barBg == self._sliderBg  then return end --prevent repeating everytime
    self._sliderBar = bar
    self._sliderBg  = barBg
    self:enableScrollListener()
    self:setSliderBarCallback(handler(self, self.updateSliderBarPos))
end

function ListView:setSliderBarCallback (callback)
    if callback then
        self._sliderBarCallback = callback
    end
end

function ListView:updateSliderBarPos ()
    local lSize = self:getContentSize()
    local iSize = self:getInnerContainer():getContentSize()
    local iPos  = cc.p(self:getInnerContainer():getPosition())
    local sWidth  = self._sliderBar:getContentSize().width
    local sHeight = self._sliderBar:getContentSize().height
    local bHeight = self._sliderBg:getContentSize().height
    local of = math.max(iSize.height - lSize.height, 1)
    local pc = math.abs(iPos.y) / of
    local dist = lSize.height - sHeight
    local posY = dist * pc + sHeight / 2
    -- print('SlideBar posY = ' .. posY)
    self._sliderBar:setPositionY(posY)
end

function ListView:updateSlideBarState ()
    if not self._sliderBar then return end
    if not self._sliderBg then return end

    local iHeight = self:getInnerContainer():getContentSize().height
    local bHeight = self._sliderBg:getContentSize().height
    if bHeight >= iHeight then
        self._sliderBg:setVisible(false)
        return
    end

    -- ListView:isScrollPaused() is a custom function defined and implemented in C++
    local isPaused = self:isScrollPaused() 
    if isPaused and self._sliderBg._isActionEnd then
        self._sliderBg._isActionEnd = false
        local a1 = cc.FadeOut:create(self._slideOutTime)
        local a2 = cc.Hide:create()
        local st = cc.Sequence:create(a1,a2)
        self._sliderBg:runAction(st)
    end
    if not isPaused then
        self._sliderBg:stopAllActions()
        self._sliderBar:stopAllActions()
        self._sliderBg:setVisible(true)
        self._sliderBg:setOpacity(255)
        local a1 = cc.DelayTime:create(self._slideInTime)
        local a2 = cc.CallFunc:create(function()
            self._sliderBg._isActionEnd = true
        end)
        local st = cc.Sequence:create(a1, a2)
        self._sliderBar:runAction(st)
        self._sliderBg:runAction(st:clone())
    end
end

--------------------------------------------------------------
------Below Is A Promotion of UIListView Items-Loading--------
--------------------------------------------------------------

function ListView:getVisibleBottomItem ()
    local innerSize = self:getInnerContainerSize()
    local viewSize  = self:getContentSize()
    local innerPos  = cc.p(self:getInnerContainerPosition())
    -- print('innerPos.y = ' .. innerPos.y)
    local items = self:getItems()
    if next(items) then
        for row, item in ipairs(items) do
            local itemPos = cc.p(item:getPosition())
            if itemPos.y <= math.abs(innerPos.y) then
                -- print('itemPos.y = ' .. itemPos.y)
                return item, row
            end
        end
    end
    return items[#items], #items
end

function ListView:getVisibleCount(itemModel)
    local viewSize = self:getContentSize()
    local itemSize = itemModel:getContentSize()
    local viewMgin = self:getItemsMargin()
    local oneHeight = itemSize.height + viewMgin
    return math.ceil(viewSize.height / oneHeight)
end

function ListView:packAutoLoadItem(itemModel, isCenterAround)
    local viewItem = itemModel:clone()
    local packItem = ccui.Layout:create()
    packItem:setContentSize(viewItem:getContentSize())
    viewItem:setName(ITEM_MODEL_NAME)
    if isCenterAround or nil == isCenterAround then
        -- call Tools.UIHelper.centerAround() to set child in the center of parent
        Tools.UIHelper.centerAround(viewItem, packItem, true)
    else
        packItem:addChild(viewItem)
    end
    if self._isShowLabel then
        if itemModel._row then
            self:addRowLabel(itemModel._row, packItem)
        end
    end
    return packItem
end

function ListView:enableAutoLoad (itemModel, initFunc, releaseFunc)
    if not itemModel then return end
    if not initFunc then return end
    local visibleCount = self:getVisibleCount(itemModel)
    self:enableScrollListener()
    self:setScrollingCallback(function()
        local _, row = self:getVisibleBottomItem()
        if row == 1 then row = visibleCount end
        local items = self:getItems()
        local limit = math.max(1, row - visibleCount)
        print('current row = ' .. row)
        print('visible cnt = ' .. visibleCount)
        if #items > 0 then
            for i, item in ipairs(items) do
                if i <= row and i >= limit then
                    --item init here
                    self:loadItemData(i, item, initFunc)
                else
                    --item release here
                    self:releaseItemData(i, item, releaseFunc)
                end
            end
        end
    end)
end

function ListView:loadItemData (row, item, initFunc)
    if item._isInit then
        return
    end
    print('--load item in row--'..row)
    item._isInit = true
    item._isRelease = false
    local realItem = item:getChildByName(ITEM_MODEL_NAME)
    realItem:setVisible(true)
    if self._isShowLabel then
        self:addRowLabel(row, item)
    end
    if initFunc then
        initFunc(row, realItem)
    end
end

function ListView:releaseItemData(row, item, releaseFunc)
    if item._isRelease then
        return
    end
    print('--release item in row--'..row)
    item._isInit = false
    item._isRelease = true
    item:getChildByName(ITEM_MODEL_NAME):setVisible(false)
    if releaseFunc then
        releaseFunc(row, item)
    end
end

function ListView:addRowLabel (row, item)
    --Call Tools.UIHelper.isExistNode() to check if parent has a child called ITEM_LABEL_NAME
    --if YES , it returns true.
    if Tools.UIHelper.isExistNode(ITEM_LABEL_NAME, item, false) then
        return
    end
    local label = cc.Label:create()
    label:setString('Row '..row)
    label:setSystemFontSize(32)
    label:setName(ITEM_LABEL_NAME)
    Tools.UIHelper.centerAround(label, item, true)
    return label
end

function ListView:setLabelShown (var)
    if self._isShowLabel == var then
        return
    end
    self._isShowLabel = var
end
