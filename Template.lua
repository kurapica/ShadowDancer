--========================================================--
--                ShadowDancer Template                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/09/13                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer.Template"            "1.1.0"
--========================================================--

namespace "ShadowDancer"

import "Scorpio.Secure.SecureActionButton"

__Sealed__()
enum "ActionBarMap"             {
    NONE                        = -1,
    MAIN                        = 0,
    BAR1                        = 1,
    BAR2                        = 2,
    BAR3                        = 3,
    BAR4                        = 4,
    BAR5                        = 5,
    BAR6                        = 6,
    PET                         = 100,
    STANCEBAR                   = 200,
}

__Sealed__()
enum "AutoGenRuleType"          {
    RaidTarget                  = 1,
    WorldMarker                 = 2,
    BagSlot                     = 3,
    EquipSet                    = _G.C_EquipmentSet and 4,

    Item                        = 10,
}

__Sealed__()
enum "SwapMode"                 {
    None                        = 0,
    ToRoot                      = 1,
    Queue                       = 2,
}

__Sealed__()
struct "AutoGenRule"  {
    { name = "type",       type = AutoGenRuleType, require = true },
    { name = "class",      type = Number },
    { name = "subclass",   type = Number },
}

do
    class "DancerButton" {}
    class "ShadowBar"    {}

    RECYCLE_BUTTONS             = Recycle(DancerButton, "ShadowDancerButton%d", UIParent)
    RECYCLE_BARS                = Recycle(ShadowBar,    "ShadowDancerBar%d",    UIParent)

    AUTOFADE_WATCH              = {}
    AUTOGEN_MAP                 = {}

    AUTOGEN_ITEM_ROOT           = {}

    CONTAINER_ITEM_LIST         = {}

    ------------------------------------------------------
    --                Secure Environment                --
    ------------------------------------------------------
    _ManagerFrame               = SecureFrame("ShadowDancer_Manager", UIParent, "SecureHandlerStateTemplate")
    _ManagerFrame:Hide()

    _ManagerFrame:Execute[==[
        Manager                 = self

        FLYOUT_MAP              = newtable()
        BAR_MAP                 = newtable()

        -- temp tables
        EFFECT_BAR              = newtable()
        TOGGLE_ROOT_BUTTON      = newtable()

        -- Auto fade
        AutoHideMap             = newtable()
        AutoFadeMap             = newtable()
        State                   = newtable()

        -- Allow button For retail
        AllowButtons            = newtable()
        AllowButtons.down       = true
        AllowButtons.up         = true

        CALC_EFFECT_BAR         = [=[
            local bar           = FLYOUT_MAP[self]
            if not bar or EFFECT_BAR[bar] then return end

            EFFECT_BAR[bar]     = true

            local buttons       = BAR_MAP[bar]
            if not buttons then return end

            for _, btn in ipairs(buttons) do
                if FLYOUT_MAP[btn] and FLYOUT_MAP[btn]:IsVisible() then
                    Manager:RunFor(btn, CALC_EFFECT_BAR)
                end
            end
        ]=]

        HIDE_FLYOUT_BARS        = [=[
            self:UnregisterAutoHide()

            local bar           = FLYOUT_MAP[self]
            if not bar then return end

            local buttons       = BAR_MAP[bar]

            if buttons then
                for _, btn in ipairs(buttons) do
                    if FLYOUT_MAP[btn] and FLYOUT_MAP[btn]:IsVisible() then
                        Manager:RunFor(btn, HIDE_FLYOUT_BARS)
                    end
                end
            end

            if not self:GetAttribute("alwaysFlyout") then
                bar:Hide()
            end
        ]=]

        UPDATE_BAR_AUTOHIDE     = [=[
            for name, bar in pairs(AutoHideMap) do
                if State[name] ~= false then
                    bar:SetAttribute("autoFadeOut", nil)
                    bar:Show()
                    bar:SetAlpha(1)
                elseif AutoFadeMap[name] then
                    bar:Show()
                    bar:SetAttribute("autoFadeOut", true)
                    Manager:CallMethod("StartAutoFadeOut", bar:GetName())
                else
                    bar:SetAttribute("autoFadeOut", nil)
                    bar:Hide()
                    bar:SetAlpha(1)
                end
            end
        ]=]

        FORCE_BAR_SHOW          = [=[
            for name, bar in pairs(AutoHideMap) do
                bar:SetAttribute("autoFadeOut", nil)
                bar:Show()
                bar:SetAlpha(1)
            end
        ]=]
    ]==]

    -- Add check for the ActionButtonUseKeyDown setting
    if Scorpio.IsRetail then
        _ManagerFrame:Execute[==[
            AllowButtons.down   = false
        ]==]
    end

    function RECYCLE_BUTTONS:OnPop(button)
        button:Show()
    end

    function RECYCLE_BUTTONS:OnPush(button)
        button:SetProfile(nil)
        button:ClearAllPoints()
        button:Hide()
        button:SetParent(UIParent)
    end

    function RECYCLE_BARS:OnPop(bar)
        bar:Show()
    end

    function RECYCLE_BARS:OnPush(bar)
        bar:SetProfile(nil)

        bar.IsFlyoutBar             = false
        bar.AutoFadeOut             = false
        bar.AutoHideCondition       = nil
        bar.FadeAlpha               = 0
        bar:SetAlpha(1)

        bar:ClearAllPoints()
        bar:Hide()
        bar:SetParent(UIParent)
    end

    function UpdateFlyoutLocation(self)
        if not self.FlyoutBar then return end

        local dir                   = self.FlyoutDirection or "UP"
        local btnCount              = self.FlyoutBar.Count
        if btnCount == 0 then btnCount = 1 end

        if dir == "UP" then
            self.FlyoutBar:SetLocation{ Anchor("BOTTOM", 0, self.FlyoutBar.VSpacing + 11, nil, "TOP") }
            self.FlyoutBar.TopToBottom = false
            self.FlyoutBar.LeftToRight = true
            self.FlyoutBar.Orientation = "VERTICAL"
            self.FlyoutBar.RowCount    = btnCount
            self.FlyoutBar.ColumnCount = 1
        elseif dir == "DOWN" then
            self.FlyoutBar:SetLocation{ Anchor("TOP", 0, - self.FlyoutBar.VSpacing - 11, nil, "BOTTOM") }
            self.FlyoutBar.TopToBottom = true
            self.FlyoutBar.LeftToRight = true
            self.FlyoutBar.Orientation = "VERTICAL"
            self.FlyoutBar.RowCount    = btnCount
            self.FlyoutBar.ColumnCount = 1
        elseif dir == "LEFT" then
            self.FlyoutBar:SetLocation{ Anchor("RIGHT", - self.FlyoutBar.HSpacing - 11, 0, nil, "LEFT") }
            self.FlyoutBar.TopToBottom = true
            self.FlyoutBar.LeftToRight = false
            self.FlyoutBar.Orientation = "HORIZONTAL"
            self.FlyoutBar.ColumnCount = btnCount
            self.FlyoutBar.RowCount    = 1
        elseif dir == "RIGHT" then
            self.FlyoutBar:SetLocation{ Anchor("LEFT", self.FlyoutBar.HSpacing + 11, 0, nil, "RIGHT") }
            self.FlyoutBar.TopToBottom = true
            self.FlyoutBar.LeftToRight = true
            self.FlyoutBar.Orientation = "HORIZONTAL"
            self.FlyoutBar.ColumnCount = btnCount
            self.FlyoutBar.RowCount    = 1
        end
    end

    __SecureMethod__()
    function _ManagerFrame:StartAutoFadeOut(name)
        AddAutoFadeWatch(GetProxyUI(_G[name]))
    end

    __SecureMethod__()
    function _ManagerFrame:SwapCustomAction(a, b)
        a = GetProxyUI(_G[a])
        b = GetProxyUI(_G[b])

        a.CustomText,    b.CustomText    = b.CustomText,    a.CustomText
        a.CustomTexture, b.CustomTexture = b.CustomTexture, a.CustomTexture
    end

    __Service__(true)
    function AutoFadeService()
        while true do
            while next(AUTOFADE_WATCH) do
                local diff      = 1 / (GetFramerate() * 2)

                for root, a in pairs(AUTOFADE_WATCH) do
                    if not root:GetAttribute("autoFadeOut") then
                        AUTOFADE_WATCH[root] = nil
                        root:SetAlpha(1)
                    elseif root:HasMouseOver() then
                        root:SetAlpha(1)
                        AUTOFADE_WATCH[root] = 1
                    else
                        a       = a - diff
                        if a <= root.FadeAlpha then
                            root:SetAlpha(root.FadeAlpha)
                            AUTOFADE_WATCH[root] = nil
                        else
                            root:SetAlpha(a)
                            AUTOFADE_WATCH[root] = a
                        end
                    end
                end

                Next()
            end

            NextEvent("SHADOWDANCER_AUTO_FADE_WATCH")
        end
    end

    function AddAutoFadeWatch(self)
        if not next(AUTOFADE_WATCH) then FireSystemEvent("SHADOWDANCER_AUTO_FADE_WATCH") end
        AUTOFADE_WATCH[self]    = self:GetAlpha()
    end

    __Service__(true)
    function AutoItemGen()
        local itemClassMap      = {}
        local changed           = {}
        local indexMap          = {}

        while true do
            NoCombat()

            local needAutoGen   = false

            for root in pairs(AUTOGEN_ITEM_ROOT) do
                local rule      = root.AutoGenRule
                if rule and rule.type == AutoGenRuleType.Item then
                    needAutoGen = true
                    local cls   = _AuctionItemClasses[rule.class]
                    if cls then
                        itemClassMap[cls.name] = itemClassMap[cls.name] or {}

                        itemClassMap[cls.name][rule.subclass and cls[rule.subclass] or -1] = root
                    end
                else
                    AUTOGEN_ITEM_ROOT[root] = nil
                end
            end

            if needAutoGen then
                for i = 1, #CONTAINER_ITEM_LIST do
                    local itemID    = CONTAINER_ITEM_LIST[i]
                    local name, _, _, iLevel, reqLevel, cls, subclass = GetItemInfo(itemID)

                    if cls then
                        local root  = itemClassMap[cls]
                        root        = root and (root[subclass] or root[-1])

                        if root then
                            local j = (indexMap[root] or -1) + 1
                            indexMap[root] = j

                            local m = AUTOGEN_MAP[root]
                            if not m then
                                m   = {}
                                AUTOGEN_MAP[root] = m
                            end

                            if m[j] ~= itemID then
                                m[j]= itemID
                                changed[root] = true
                            end
                        end
                    end
                end

                for root in pairs(changed) do
                    local map       = AUTOGEN_MAP[root]
                    for i = #map, indexMap[root] + 1, -1 do
                        map[i]      = nil
                    end

                    root:RefreshAutoGen(AUTOGEN_MAP[root], "item")
                end

                for _, m in pairs(itemClassMap) do wipe(m) end
                wipe(changed)
                wipe(indexMap)
            end

            NextEvent("SHADOWDANCER_AUTO_GEN_ITEM")
        end
    end

    __Service__(true)
    function AutoScanItems()
        local cache             = {}

        Wait(2, "PLAYER_LOGIN") -- wait for the container data

        while true do
            NoCombat()

            wipe(cache)
            local index         = 0
            local changed       = false

            for bag = 0, NUM_BAG_FRAMES do
                for slot = 1, GetContainerNumSlots(bag) do
                    local itemID= GetContainerItemID(bag, slot)

                    if itemID and not cache[itemID] and not _AutoGenBlackList[itemID] and GetItemSpell(itemID) then
                        cache[itemID] = true

                        index   = index + 1

                        if CONTAINER_ITEM_LIST[index] ~= itemID then
                            changed = true
                            CONTAINER_ITEM_LIST[index] = itemID
                        end
                    end
                end
            end

            for i = #CONTAINER_ITEM_LIST, index + 1, -1 do
                changed         = true
                CONTAINER_ITEM_LIST[i] = nil
            end

            if changed then
                FireSystemEvent("SHADOWDANCER_AUTO_GEN_ITEM")
            end

            NextEvent("BAG_UPDATE_DELAYED")
        end
    end

    function RegisterAutoItemGen(self)
        -- For now only allow one button for the same class and subclass
        local itemClass, itemSubClass = self.AutoGenRule.class, self.AutoGenRule.subclass
        if not itemClass then self.AutoGenRule = nil return  end

        for root in pairs(AUTOGEN_ITEM_ROOT) do
            if root ~= self and root.AutoGenRule and root.AutoGenRule.type == AutoGenRuleType.Item then
                if root.AutoGenRule.class == itemClass and (root.AutoGenRule.subclass == itemSubClass or not itemSubClass) then
                    root.AutoGenRule = nil
                    AUTOGEN_ITEM_ROOT[root] = nil
                end
            else
                AUTOGEN_ITEM_ROOT[root] = nil
            end
        end
        AUTOGEN_ITEM_ROOT[self] = true

        FireSystemEvent("SHADOWDANCER_AUTO_GEN_ITEM")
    end
end

__Sealed__()
class "DancerButton" (function(_ENV)
    inherit "SecureActionButton"

    export{ abs = math.abs, floor = math.floor, min = math.min, tremove = table.remove }

    local _SpellFlyoutMap       = {}

    Wow.FromEvent("SPELL_FLYOUT_UPDATE"):Next():Subscribe(function()
        for root in pairs(_SpellFlyoutMap) do
            root:RefreshFlyout()
        end
    end)

    ------------------------------------------------------
    --                     Helper                       --
    ------------------------------------------------------
    local function getDirectionValue(dir)
        return dir == "UP" and 0 or dir == "RIGHT" and 1 or dir == "DOWN" and 2 or dir == "LEFT" and 3
    end

    local function parseDirectionValue(val)
        return val == 0 and "UP" or val == 1 and "RIGHT" or val == 2 and "DOWN" or val == 3 and "LEFT"
    end

    local function clockwise(self, diff)
        self.FlyoutDirection    = parseDirectionValue((diff + getDirectionValue(self.FlyoutDirection)) % 4)

        for _, btn in self.FlyoutBar:GetIterator() do
            if btn.FlyoutBar then
                clockwise(btn, diff)
            end
        end
    end

    local function regenerateFlyout(self)
        local l, b, w, h        = self:GetRect()
        local cx, cy            = self:GetCenter()
        local e                 = self:GetEffectiveScale()

        local baseBar           = self:GetParent()
        local baseBarRoot, isLast
        local isGenBar, isAdjustBar, orgFlyout
        local btnProfiles, orgDir

        -- change the base bar if the button is the last
        if baseBar.IsFlyoutBar then
            baseBarRoot         = baseBar:GetParent()
            isLast              = self:GetID() == self:GetParent().Count
        end

        Delay(0.2)

        while IsMouseButtonDown("LeftButton") and not InCombatLockdown() and IsControlKeyDown() do
            local x, y          = GetCursorPosition()
            x, y                = x / e, y / e

            -- Check the direction
            local row           = floor(abs(y > cy and ((y + h / 2 - cy) / h) or ((y - h / 2 - cy) / h)))
            local col           = floor(abs(x > cx and ((x + w / 2 - cx) / w) or ((x - w / 2 - cx) / w)))

            if(row >= 1 or col >= 1) then
                local dir       = row >= col and (y > cy and "UP" or "DOWN") or (x > cx and "RIGHT" or "LEFT")

                if not (isGenBar or isAdjustBar) then
                    -- Init check
                    if baseBarRoot and isLast and ((baseBar.Orientation == "HORIZONTAL" and (dir == "LEFT" or dir == "RIGHT")) or (baseBar.Orientation == "VERTICAL" and (dir == "UP" or dir == "DOWN"))) then
                        isGenBar        = true  -- Change the bar of the base

                        -- The flyout has a auto-gen feature, so can't modify
                        if baseBarRoot and (baseBarRoot.ActionType == "flyout" or baseBarRoot.AutoGenRule) then return end
                        btnProfiles     = XList(baseBar:GetIterator()):Map(DancerButton.GetProfile):ToList()  -- temporary keep the button profiles

                        self            = baseBarRoot
                        baseBar         = self:GetParent()
                        orgDir          = self.FlyoutDirection
                        cx, cy          = self:GetCenter()
                        orgFlyout       = self.FlyoutDirection

                        self.FlyoutBar.GridAlwaysShow = true

                        for _, btn in self.FlyoutBar:GetIterator() do
                            if btn.FlyoutBar then btn.FlyoutBar:Hide() end
                        end
                    elseif not baseBar.IsFlyoutBar or ((baseBar.Orientation == "HORIZONTAL" and (dir == "UP" or dir == "DOWN")) or (baseBar.Orientation == "VERTICAL" and (dir == "LEFT" or dir == "RIGHT"))) then
                        -- For flyout bar, only cross direction is allowed
                        if self.FlyoutBar then
                            isAdjustBar = true
                            orgFlyout   = self.FlyoutDirection

                            self.FlyoutBar.GridAlwaysShow = true

                            for _, btn in self.FlyoutBar:GetIterator() do
                                if btn.FlyoutBar then btn.FlyoutBar:Hide() end
                            end
                        else
                            isGenBar    = true
                            orgDir      = dir

                            -- The flyout has a auto-gen feature, so can't modify
                            if baseBarRoot and (baseBarRoot.ActionType == "flyout" or baseBarRoot.AutoGenRule) then return end
                        end
                    end
                elseif isGenBar then
                    if not orgDir and (not baseBar.IsFlyoutBar or ((baseBar.Orientation == "HORIZONTAL" and (dir == "UP" or dir == "DOWN")) or (baseBar.Orientation == "VERTICAL" and (dir == "LEFT" or dir == "RIGHT")))) then
                        orgDir          = dir
                    end

                    local rowCount      = 1
                    local columnCount   = 1
                    local count         = 0

                    if orgDir == "UP" then
                        count           = row
                        rowCount        = count
                    elseif orgDir == "DOWN" then
                        count           = row
                        rowCount        = count
                    elseif orgDir == "LEFT" then
                        count           = col
                        columnCount     = count
                    elseif orgDir == "RIGHT" then
                        count           = col
                        columnCount     = count
                    end

                    if count > 0 then
                        self.FlyoutDirection= orgDir
                        if not self.FlyoutBar then
                            self.AlwaysFlyout = true
                            self.FlyoutBar  = ShadowBar.BarPool()

                            -- Init
                            self.FlyoutBar:SetScale(1)
                            self.FlyoutBar.ActionBarMap = ActionBarMap.NONE
                            self.FlyoutBar.ElementWidth = baseBar.ElementWidth
                            self.FlyoutBar.ElementHeight= baseBar.ElementHeight
                            self.FlyoutBar.HSpacing     = baseBar.HSpacing
                            self.FlyoutBar.VSpacing     = baseBar.VSpacing
                            self.FlyoutBar.GridAlwaysShow = true

                            UpdateFlyoutLocation(self)
                        end

                        self.FlyoutBar.RowCount     = rowCount
                        self.FlyoutBar.ColumnCount  = columnCount
                        self.FlyoutBar.Count        = count
                    else
                        self.FlyoutBar  = nil
                        orgDir          = nil
                    end
                elseif isAdjustBar then
                    if not baseBar.IsFlyoutBar or ((baseBar.Orientation == "HORIZONTAL" and (dir == "UP" or dir == "DOWN")) or (baseBar.Orientation == "VERTICAL" and (dir == "LEFT" or dir == "RIGHT"))) then
                        self.FlyoutDirection = dir
                    end
                end
            elseif isGenBar then
                self.FlyoutBar          = nil
                orgDir                  = nil
            end

            Delay(0.1)
        end

        if not (isGenBar or isAdjustBar) then return end

        NoCombat()

        -- Check and modify the direction of the sub-bars
        if isAdjustBar then
            local diff                  = (getDirectionValue(self.FlyoutDirection) - getDirectionValue(orgFlyout)) % 4
            if diff == 0 then return end

            for _, btn in self.FlyoutBar:GetIterator() do
                if btn.FlyoutBar then
                    clockwise(btn, diff)
                    btn.FlyoutBar:SetShown(btn.AlwaysFlyout)
                    btn.Flyouting       = btn.AlwaysFlyout
                end
            end
        elseif isGenBar and self.FlyoutBar and btnProfiles and #btnProfiles > 0 then
            -- Restore the buttons
            for i = 1, min(self.FlyoutBar.Count, #btnProfiles) do
                local btn               = self.FlyoutBar.Elements[i]
                if btn then btn:SetProfile(btnProfiles[i]) end
            end

            local diff                  = (getDirectionValue(self.FlyoutDirection) - getDirectionValue(orgFlyout)) % 4
            if diff == 0 then return end

            for _, btn in self.FlyoutBar:GetIterator() do
                if btn.FlyoutBar then
                    clockwise(btn, diff)
                    btn.FlyoutBar:SetShown(btn.AlwaysFlyout)
                    btn.Flyouting       = btn.Flyouting
                end
            end
        end

        if self.FlyoutBar then
            self.FlyoutBar.GridAlwaysShow   = baseBar.GridAlwaysShow
        end
    end

    local function onMouseDown(self, button)
        return button == "LeftButton" and self:IsMouseOver() and IsControlKeyDown() and not InCombatLockdown() and Next(regenerateFlyout, self)
    end

    local function onEnter(self)
        local bar               = self:GetParent()
        while bar.IsFlyoutBar do
            bar                 = bar:GetParent():GetParent()
        end
        return bar:OnEnter()
    end

    ------------------------------------------------------
    --                     Property                     --
    ------------------------------------------------------
    --- Whether use custom flyout logic
    property "IsCustomFlyout"   { set = false, default = true }

    --- The action button group
    property "ActionButtonGroup"{ set = false, default = "AshToAsh" }

    --- Whether the flyout buttons of this always show(if this button is shown)
    property "AlwaysFlyout"     {
        type                    = Boolean,
        set                     = function(self, value) self:SetAttribute("alwaysFlyout", value or false) end,
        get                     = function(self) return self:GetAttribute("alwaysFlyout") or false end,
    }

    --- The flyout shadow bar
    property "FlyoutBar"        { type = ShadowBar,
        handler                 = function(self, bar, old)
            _ManagerFrame:SetFrameRef("DancerButton", self)

            if old then
                _ManagerFrame:SetFrameRef("ShadowBar", old)
                _ManagerFrame:Execute[[
                    local button    = Manager:GetFrameRef("DancerButton")
                    local bar       = Manager:GetFrameRef("ShadowBar")

                    FLYOUT_MAP[bar] = nil
                    FLYOUT_MAP[button] = nil
                ]]

                old.IsFlyoutBar     = false
                ShadowBar.BarPool(old)
            end

            if bar then
                _ManagerFrame:SetFrameRef("ShadowBar", bar)
                _ManagerFrame:Execute[[
                    local button    = Manager:GetFrameRef("DancerButton")
                    local bar       = Manager:GetFrameRef("ShadowBar")

                    FLYOUT_MAP[bar] = button
                    FLYOUT_MAP[button] = bar
                ]]

                bar.IsFlyoutBar     = true
                bar:SetParent(self)
            else
                self.AlwaysFlyout   = false
            end

            self.IsFlyout           = bar and true or false
        end
    }

    --- The autogen rules
    property "AutoGenRule"      { type = AutoGenRule, handler = function(self, rule)
            if rule then
                if rule.type and self.FlyoutBar then self.FlyoutBar.IsSwappable = nil end

                if rule.type == AutoGenRuleType.RaidTarget then
                    self:RefreshAutoGen({ [0] = 0, 1, 2, 3, 4, 5, 6, 7, 8 }, "raidtarget")
                elseif rule.type == AutoGenRuleType.WorldMarker then
                    self:RefreshAutoGen({ [0] = 1, 2, 3, 4, 5, 6, 7, 8 }, "worldmarker")
                elseif rule.type == AutoGenRuleType.BagSlot then
                    self:RefreshAutoGen({ [0] = 0, 1, 2, 3, 4 }, "bag")
                elseif rule.type == AutoGenRuleType.EquipSet then
                    Continue(function()
                        while self.AutoGenRule and self.AutoGenRule == AutoGenRuleType.EquipSet do
                            local map       = {}
                            local index     = 0

                            for _, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
                                map[index]  = C_EquipmentSet.GetEquipmentSetInfo(id)
                                index       = index + 1
                            end

                            self:RefreshAutoGen(map, "equipmentset")

                            NextEvent("EQUIPMENT_SETS_CHANGED") NoCombat()
                        end
                    end)
                elseif rule.type == AutoGenRuleType.Item then
                    -- The item has a big auto gen rule, add it to the service
                    return RegisterAutoItemGen(self)
                else
                    -- No support
                end
            elseif AUTOGEN_MAP[self] then
                AUTOGEN_MAP[self] = nil
                self:SetAction(nil)
                self.FlyoutBar  = nil
            end
        end
    }

    --- Whether the button is customable
    property "IsCustomable"     { get = function(self)
            if self.AutoGenRule and self.AutoGenRule.type then return false end
            if self.ActionType and self.ActionType ~= "empty" and self.ActionType ~= "custom" and self.ActionType ~= "macrotext" then return false end

            local bar           = self:GetParent()
            if bar.ActionBarMap ~= ActionBarMap.NONE then return false end
            if bar.IsFlyoutBar then
                local root      = bar:GetParent()
                if root.AutoGenRule and root.AutoGenRule.type then return false end
            end
            return true
        end
    }

    --- Whether the button is swap able
    property "IsSwappable"      { get = function(self)
            if not self.FlyoutBar then return false end
            if self.AutoGenRule and self.AutoGenRule.type then return false end

            local bar           = self:GetParent()
            if bar.ActionBarMap ~= ActionBarMap.NONE then return false end

            if bar.IsFlyoutBar then
                local root      = bar:GetParent()
                if root.AutoGenRule and root.AutoGenRule.type then return false end
            end
            return true
        end
    }

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function SetProfile(self, config)
        self.AutoGenRule        = nil   -- Make sure change or clear action won't cause item added to the black list

        if config then
            local parent        = self:GetParent()

            if parent.ActionBarMap == ActionBarMap.NONE then
                if config.CustomType then
                    self:SetAction(config.CustomType, config.MacroText or Toolset.fakefunc)
                    self.CustomText     = config.CustomText
                    self.CustomTexture  = config.CustomTexture
                else
                    self:SetAction(config.ActionType, config.ActionTarget, config.ActionDetail)
                end
            end

            -- Fix for the first version
            self.FlyoutDirection= config.FlyoutDirection == "TOP" and "UP" or config.FlyoutDirection == "BOTTOM" and "DOWN" or config.FlyoutDirection or "UP"
            self.AlwaysFlyout   = config.AlwaysFlyout or false

            self.HotKey         = config.HotKey

            if config.FlyoutBar then
                self.FlyoutBar  = self.FlyoutBar or ShadowBar.BarPool()
                self.FlyoutBar:SetProfile(config.FlyoutBar)
                self.FlyoutBar:SetShown(self.AlwaysFlyout)
                self.Flyouting  = self.AlwaysFlyout
            else
                self.FlyoutBar  = nil
            end

            self.AutoGenRule    = config.AutoGenRule
        else
            -- Clear
            self:SetAction(nil)
            self.HotKey         = nil
            self.FlyoutBar      = nil
        end
    end

    function GetProfile(self, nocontent)
        local isCustom          = self.ActionType == "custom" or self.ActionType == "macrotext"
        local needAction        = not nocontent and not isCustom and self:GetParent().ActionBarMap == ActionBarMap.NONE and not (self.AutoGenRule and self.AutoGenRule.type)

        return {
            -- Action Info
            ActionType          = needAction and self.ActionType or nil,
            ActionTarget        = needAction and self.ActionTarget or nil,
            ActionDetail        = needAction and self.ActionDetail or nil,

            CustomType          = isCustom and self.ActionType or nil,
            CustomText          = isCustom and self.CustomText or nil,
            CustomTexture       = isCustom and self.CustomTexture or nil,
            MacroText           = self.ActionType == "macrotext" and self.ActionTarget or nil,

            FlyoutDirection     = self.FlyoutDirection,
            AlwaysFlyout        = self.AlwaysFlyout,
            HotKey              = self.HotKey,

            FlyoutBar           = self.FlyoutBar and self.ActionType ~= "flyout" and not (self.AutoGenRule and self.AutoGenRule.type) and self.FlyoutBar:GetProfile(nocontent) or nil,
            AutoGenRule         = self.AutoGenRule and self.AutoGenRule.type and Toolset.clone(self.AutoGenRule)
        }
    end

    __NoCombat__()
    function RefreshAutoGen(self, map, type)
        AUTOGEN_MAP[self]       = map

        -- The flyout use different logic for itself
        if self.ActionType ~= "flyout" then
            self:SetAction(type, map and map[0])
        end

        if map and #map > 0 then
            local baseBar       = self:GetParent()
            self.FlyoutBar      = self.FlyoutBar or ShadowBar.BarPool()

            local bar           = self.FlyoutBar

            -- Init
            bar:SetScale(1)
            bar.ActionBarMap    = ActionBarMap.NONE
            bar.ElementWidth    = 36
            bar.ElementHeight   = 36
            bar.HSpacing        = baseBar.HSpacing or 1
            bar.VSpacing        = baseBar.VSpacing or 1
            bar.GridAlwaysShow  = baseBar.GridAlwaysShow

            UpdateFlyoutLocation(self)

            if self.FlyoutDirection == "UP" then
                bar.Orientation = "VERTICAL"
                bar.TopToBottom = false
                bar.LeftToRight = true
                bar.ColumnCount = 1
                bar.RowCount    = #map
                bar.Count       = #map
            elseif self.FlyoutDirection == "RIGHT" then
                bar.Orientation = "HORIZONTAL"
                bar.TopToBottom = true
                bar.LeftToRight = true
                bar.RowCount    = 1
                bar.ColumnCount = #map
                bar.Count       = #map
            elseif self.FlyoutDirection == "DOWN" then
                bar.Orientation = "VERTICAL"
                bar.TopToBottom = true
                bar.LeftToRight = true
                bar.ColumnCount = 1
                bar.RowCount    = #map
                bar.Count       = #map
            elseif self.FlyoutDirection == "LEFT" then
                bar.Orientation = "HORIZONTAL"
                bar.TopToBottom = true
                bar.LeftToRight = false
                bar.RowCount    = 1
                bar.ColumnCount = #map
                bar.Count       = #map
            end

            for i = 1, #map do
                bar.Elements[i]:SetAction(type, map[i])
            end

            bar:SetShown(self.AlwaysFlyout)
        else
            self.FlyoutBar      = nil
        end
    end

    __NoCombat__()
    function RefreshFlyout(self)
        if self.ActionType ~= "flyout" then
            self.FlyoutBar      = nil
            return
        end

        local flyoutID          = self.ActionTarget
        local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutID)

        if numSlots and numSlots > 0 and isKnown then
            local changed       = false
            local map           = AUTOGEN_MAP[self]

            if not map then
                changed         = true
                map             = {}
                AUTOGEN_MAP[self] = map
            end

            local j             = 1
            for i = 1, numSlots do
                local spellID, _, isKnown = GetFlyoutSlotInfo(flyoutID, i)
                if isKnown then
                    if changed then
                        map[j]  = spellID
                    elseif map[j] ~= spellID then
                        changed = true
                        map[j]  = spellID
                    end
                    j           = j + 1
                end
            end

            for i = #map, j, -1 do
                tremove(map)
                changed         = true
            end

            return changed and self:RefreshAutoGen(map, "spell")
        else
            self.FlyoutBar      = nil
        end
    end

    function Refresh(self)
        if self.ActionType == "flyout" then
            _SpellFlyoutMap[self]   = true
            self:RefreshFlyout()
        elseif _SpellFlyoutMap[self] then
            _SpellFlyoutMap[self]   = nil
            AUTOGEN_MAP[self]       = nil
            NoCombat(function() self.FlyoutBar = nil end)
        end

        if self.ActionType == "empty" then
            -- If auto-gen add to black list
            if self.AutoGenRule and self.AutoGenRule.type == AutoGenRuleType.Item then
                local map               = AUTOGEN_MAP[self]
                if map and map[0] then
                    _AutoGenBlackList[map[0]] = true
                    map[0]              = tremove(map, 1)

                    self:RefreshAutoGen(map, "item")
                end
            else
                local baseBar           = self:GetParent()
                if not baseBar.IsFlyoutBar then return end

                local root              = baseBar:GetParent()
                if not (root and root.AutoGenRule and root.AutoGenRule.type == AutoGenRuleType.Item) then return end

                local id                = self:GetID()
                local map               = AUTOGEN_MAP[root]
                if not map or #map < id then return end

                _AutoGenBlackList[tremove(map, id)] = true

                root:RefreshAutoGen(map, "item")
            end
        end
    end

    __SecureMethod__()
    function UpdateFlyout(self)
    end

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self)
        _ManagerFrame:WrapScript(self, "OnEnter", [=[
                if BAR_MAP[self] and FLYOUT_MAP[self] and not FLYOUT_MAP[self]:IsVisible() and not BAR_MAP[self]:GetAttribute("noAutoFlyout") then
                    FLYOUT_MAP[self]:Show()
                    if self:GetAttribute("alwaysFlyout") then return end

                    wipe(EFFECT_BAR)
                    self:UnregisterAutoHide()
                    self:RegisterAutoHide(Manager:GetAttribute("popupDuration") or 0.25)

                    Manager:RunFor(self, CALC_EFFECT_BAR)

                    for bar in pairs(EFFECT_BAR) do
                        self:AddToAutoHide(bar)
                    end

                    -- Refresh the auto hide of the root buttons
                    local base  = BAR_MAP[self]
                    while base:GetAttribute("isFlyoutBar") do
                        self    = FLYOUT_MAP[base]

                        if not self:GetAttribute("alwaysFlyout") then
                            self:UnregisterAutoHide() -- Need Re-register
                            self:RegisterAutoHide(Manager:GetAttribute("popupDuration") or 0.25)

                            Manager:RunFor(self, CALC_EFFECT_BAR) -- No need to clear here

                            for bar in pairs(EFFECT_BAR) do
                                self:AddToAutoHide(bar)
                            end
                        end

                        base    = BAR_MAP[self]
                    end
                end
            ]=]
        )

        _ManagerFrame:WrapScript(self, "OnClick", [=[
                -- Check repeat
                local btn = down and "down" or "up"
                if not AllowButtons[btn] then
                    return button
                end

                -- Toggle always flyout
                if FLYOUT_MAP[self] then
                    if button == "RightButton" and not (IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()) then
                        -- No modify right click to toggle always show of the flyout bar
                        self:SetAttribute("alwaysFlyout", not self:GetAttribute("alwaysFlyout"))
                        if self:GetAttribute("alwaysFlyout") then
                            FLYOUT_MAP[self]:Show()
                        else
                            Manager:RunFor(self, HIDE_FLYOUT_BARS)
                        end
                        return false
                    elseif not self:GetAttribute("alwaysFlyout") then
                        -- Toggle the flyout if the action type is empty
                        local atype = self:GetAttribute("actiontype")

                        if atype == "action" then
                            -- Check empty action
                            local page  = self:GetAttribute("actionpage") or 1
                            if not GetActionInfo( self:GetID() + (page - 1) * 12 ) then
                                atype = "empty"
                            end
                        end

                        if not atype or atype == "" or atype == "empty" or atype == "custom" or atype == "flyout" then
                            if FLYOUT_MAP[self]:IsVisible() then
                                Manager:RunFor(self, HIDE_FLYOUT_BARS)
                            else
                                -- Hide brother's flyout bar
                                for _, brother in ipairs(BAR_MAP[BAR_MAP[self]]) do
                                    if brother ~= self and FLYOUT_MAP[brother] and FLYOUT_MAP[brother]:IsVisible() and not brother:GetAttribute("alwaysFlyout") then
                                        Manager:RunFor(brother, HIDE_FLYOUT_BARS)
                                    end
                                end

                                FLYOUT_MAP[self]:Show()
                            end

                            return false
                        end
                    end
                end

                -- Check swap mode
                local swapBar = FLYOUT_MAP[self]
                local swapMode

                if swapBar then
                    swapMode = swapBar:GetAttribute("swapMode")
                    if swapMode ~= 1 and swapMode ~= 2 then
                        swapBar = nil
                    end
                end

                if not swapBar then
                    swapBar = BAR_MAP[self]
                    swapMode = swapBar:GetAttribute("swapMode")
                    if swapMode ~= 1 and swapMode ~= 2 then
                        swapBar = nil
                    end
                end

                if swapBar and (swapMode == 1 and FLYOUT_MAP[swapBar] ~= self) or swapMode == 2 then
                    TOGGLE_ROOT_BUTTON[2] = swapBar
                    TOGGLE_ROOT_BUTTON[3] = swapMode
                    TOGGLE_ROOT_BUTTON[4] = self
                else
                    TOGGLE_ROOT_BUTTON[2] = nil
                    TOGGLE_ROOT_BUTTON[3] = nil
                    TOGGLE_ROOT_BUTTON[4] = nil
                end

                -- Check
                while BAR_MAP[self]:GetAttribute("isFlyoutBar") do self = FLYOUT_MAP[BAR_MAP[self]] end
                TOGGLE_ROOT_BUTTON[1] = FLYOUT_MAP[self] and self or nil

                -- return messge if need to do a flyout auto hide
                return button, (TOGGLE_ROOT_BUTTON[2] or TOGGLE_ROOT_BUTTON[1]) and "toggle" or nil
            ]=], [=[
                local swapBar = TOGGLE_ROOT_BUTTON[2]
                if swapBar then
                    local swapMode = TOGGLE_ROOT_BUTTON[3]
                    local btn = TOGGLE_ROOT_BUTTON[4]

                    if swapMode == 1 then
                        -- To root
                        local root = FLYOUT_MAP[swapBar]
                        if root ~= btn then
                            local rtype, raction, rdetail = root:RunAttribute("GetAction")
                            local btype, baction, bdetail = btn:RunAttribute("GetAction")

                            root:RunAttribute("SetAction", btype, baction, bdetail)
                            btn:RunAttribute("SetAction", rtype, raction, rdetail)

                            Manager:CallMethod("SwapCustomAction", root:GetName(), btn:GetName())
                        end
                    elseif swapMode == 2 then
                        -- Queue
                        local buttons = BAR_MAP[swapBar]
                        if buttons then
                            local index = 0
                            if btn ~= FLYOUT_MAP[swapBar] then
                                for i = 1, #buttons do
                                    if buttons[i] == btn then
                                        index = i
                                        break
                                    end
                                end
                            end

                            for i = index + 1, #buttons do
                                local nxt = buttons[i]

                                local btype, baction, bdetail = btn:RunAttribute("GetAction")
                                local ntype, naction, ndetail = nxt:RunAttribute("GetAction")

                                nxt:RunAttribute("SetAction", btype, baction, bdetail)
                                btn:RunAttribute("SetAction", ntype, naction, ndetail)

                                Manager:CallMethod("SwapCustomAction", nxt:GetName(), btn:GetName())

                                btn = nxt
                            end
                        end
                    end

                    TOGGLE_ROOT_BUTTON[2] = nil
                    TOGGLE_ROOT_BUTTON[3] = nil
                    TOGGLE_ROOT_BUTTON[4] = nil
                end

                if TOGGLE_ROOT_BUTTON[1] then
                    Manager:RunFor(TOGGLE_ROOT_BUTTON[1], HIDE_FLYOUT_BARS)
                    TOGGLE_ROOT_BUTTON[1] = nil
                end
            ]=]
        )

        _ManagerFrame:WrapScript(self, "OnAttributeChanged", [=[
                if name == "statehidden" then
                    if value then
                        self:Show()
                        Manager:RunFor(self, HIDE_FLYOUT_BARS)
                    end
                elseif name == "alwaysFlyout" then
                    if value then
                        self:UnregisterAutoHide()
                        if FLYOUT_MAP[self] then
                            FLYOUT_MAP[self]:Show()
                        end
                    else
                        Manager:RunFor(self, HIDE_FLYOUT_BARS)
                    end
                end
            ]=]
        )

        Observable.From(self, "FlyoutDirection"):Subscribe(function() return UpdateFlyoutLocation(self) end)

        self.OnMouseDown        = self.OnMouseDown + onMouseDown
        self.OnEnter            = self.OnEnter + onEnter
    end
end)

__Sealed__()
class "ShadowBar" (function(_ENV)
    inherit "SecurePanel"

    export{ max = math.max, min = math.min }

    local stanceBar             = {}
    local autoFadeOutBar        = {}

    Wow.FromEvent("UPDATE_SHAPESHIFT_FORMS"):Next():Subscribe(function()
        for root in pairs(stanceBar) do
            root:RefreshStance()
        end
    end)

    local function clearActionMap(self, map)
        self:SetAction(nil)

        if map == ActionBarMap.MAIN then
            self:SetMainPage(false)
        elseif map >= ActionBarMap.BAR1 and map <= ActionBarMap.BAR6 then
            self:SetActionPage(nil)
        end
    end

    local function setupActionMap(self, map)
        if map == ActionBarMap.MAIN then
            self:SetMainPage(true)
            self:SetAction("action", self:GetID())
        elseif map >= ActionBarMap.BAR1 and map <= ActionBarMap.BAR6 then
            self:SetActionPage(map)
            self:SetAction("action", self:GetID())
        elseif map == ActionBarMap.PET then
            self:SetAction("pet", self:GetID())
        elseif map == ActionBarMap.STANCEBAR then
            local index         = self:GetID()
            if index <= GetNumShapeshiftForms() or 0 then
                local id        = select(4, GetShapeshiftFormInfo(index))
                if id then self:SetAction("spell", id) end
            end
        end
    end

    local function handlerAutoHideOrFade(self)
        autoFadeOutBar[self]    = nil

        _ManagerFrame:SetFrameRef("ShadowBar", self)
        if self.AutoHideState then
            _ManagerFrame:UnregisterStateDriver(self.AutoHideState)
            _ManagerFrame:SetAttribute("state-" .. self.AutoHideState, nil)

            _ManagerFrame:Execute(([[
                local name          = "%s"
                AutoHideMap[name]   = nil
                AutoFadeMap[name]   = nil
                State[name]         = nil
            ]]):format(self.AutoHideState))

            self.AutoHideState      = nil
        end

        if self.IsFlyoutBar then
            -- Only the root bar can auto hide/fade out
            self:SetAttribute("autoFadeOut", nil)
            self:SetAlpha(1)
        else
            if self.AutoHideCondition and #self.AutoHideCondition > 0 then
                local cond          = ""
                for _, k in ipairs(self.AutoHideCondition) do cond = cond .. k .. "hide;" end
                cond                = cond .. "show;"

                self.AutoHideState  = "autohide" .. self:GetName()

                _ManagerFrame:Execute(([[
                    local name          = "%s"
                    local bar           = Manager:GetFrameRef("ShadowBar")
                    AutoHideMap[name]   = bar
                    AutoFadeMap[name]   = %s
                    bar:SetAttribute("autofadeout", false)
                ]]):format(self.AutoHideState, tostring(self.AutoFadeOut or false)))

                _ManagerFrame:RegisterStateDriver(self.AutoHideState, cond)
                _ManagerFrame:SetAttribute("_onstate-" .. self.AutoHideState, ([[
                    local name          = "%s"
                    local bar           = AutoHideMap[name]
                    local autofade      = AutoFadeMap[name]

                    State[name]         = newstate ~= "hide"

                    if newstate == "hide" then
                        if autofade then
                            bar:SetAttribute("autoFadeOut", true)
                            Manager:CallMethod("StartAutoFadeOut", bar:GetName())
                        else
                            bar:SetAttribute("autoFadeOut", nil)

                            local btns  = BAR_MAP[bar]
                            if btns then
                                for _, btn in ipairs(btns) do
                                    if FLYOUT_MAP[btn] then
                                        Manager:RunFor(btn, HIDE_FLYOUT_BARS)
                                    end
                                end
                            end

                            bar:Hide()
                        end
                    else
                        bar:SetAttribute("autoFadeOut", nil)
                        bar:Show()
                        bar:SetAlpha(1)
                    end
                ]]):format(self.AutoHideState))
                _ManagerFrame:SetAttribute("state-" .. self.AutoHideState, nil)

                if self.AutoFadeOut then self:Show() end
            elseif self.AutoFadeOut then
                autoFadeOutBar[self]= true
                self:SetAttribute("autoFadeOut", true)
                self:Show()
                AddAutoFadeWatch(self)
            else
                self:SetAttribute("autoFadeOut", nil)
                self:SetAlpha(1)
                self:Show()
            end
        end
    end

    local function onElementAdd(self, ele)
        _ManagerFrame:SetFrameRef("ShadowBar", self)
        _ManagerFrame:SetFrameRef("DancerButton", ele)

        _ManagerFrame:Execute[[
            local bar           = Manager:GetFrameRef("ShadowBar")
            local button        = Manager:GetFrameRef("DancerButton")

            if not BAR_MAP[bar] then
                BAR_MAP[bar]    = newtable()
            end

            tinsert(BAR_MAP[bar], button)
            BAR_MAP[button]     = bar
        ]]

        setupActionMap(ele, self.ActionBarMap)
        ele.GridAlwaysShow      = self.GridAlwaysShow
        ele.AutoKeyBinding      = self.IsFlyoutBar
    end

    local function onElementRemove(self, ele)
        _ManagerFrame:SetFrameRef("ShadowBar", self)
        _ManagerFrame:SetFrameRef("DancerButton", ele)

        _ManagerFrame:Execute[[
            local bar           = Manager:GetFrameRef("ShadowBar")
            local button        = Manager:GetFrameRef("DancerButton")
            local map           = BAR_MAP[bar]

            if map then
                for i = #map, 1, -1 do
                    if map[i] == button then
                        tremove(map, i)
                        break
                    end
                end
            end
            BAR_MAP[button]     = nil
        ]]

        clearActionMap(ele, self.ActionBarMap)
    end

    local function onEnter(self)
        if not self.IsFlyoutBar and self:GetAttribute("autoFadeOut") then
            AddAutoFadeWatch(self)
        end
    end

    local function onShow(self)
        if self.IsFlyoutBar then
            self:GetParent().Flyouting = true
        end
    end

    local function onHide(self)
        if self.IsFlyoutBar then
            self:GetParent().Flyouting = false
        end
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The Element Recycle
    property "ElementPool"      { default = RECYCLE_BUTTONS }

    --- The Element Type
    property "ElementType"      { default = DancerButton }

    --- The action bar map(0: Main Bar, 1 ~ 6: Action Bar, Pet, Stance, WorldMark, RaidTarget)
    property "ActionBarMap"     { type = ActionBarMap, default = ActionBarMap.NONE,
        handler                 = function(self, map, old)
            stanceBar[self]     = map == ActionBarMap.STANCEBAR

            for i = 1, self.Count do
                local ele       = self.Elements[i]
                clearActionMap(ele, old)
                setupActionMap(ele, map)
            end

            if map and map ~= ActionBarMap.NONE then
                self.SwapMode   = nil
            end

            if stanceBar[self] then
                Next(RefreshStance, self)
            end
        end
    }

    --- Whether the bar is a flyout action bar
    property "IsFlyoutBar"      { type = Boolean, handler = function(self, value) self:SetAttribute("isFlyoutBar", value and true or nil) end }

    --- Whether auto fade the action bar
    property "AutoFadeOut"      { type = Boolean, handler = handlerAutoHideOrFade }

    --- The auto hide macro conditions
    property "AutoHideCondition"{ type = Table,   handler = handlerAutoHideOrFade }

    --- The auto fade alpha
    property "FadeAlpha"        { type = Number,  default = 0, handler = function(self, val) val = val or 0 if self:GetAlpha() < val then self:SetAlpha(val) end end }

    --- Whether always show the button grid
    property "GridAlwaysShow"   { type = Boolean, default = true, handler = function(self, val)
            for _, btn in self:GetIterator() do
                btn.GridAlwaysShow  = val
                if btn.FlyoutBar then btn.FlyoutBar.GridAlwaysShow = val end
            end
        end
    }

    --- Whether disable the auto flyout
    property "NoAutoFlyout"     {
        type                    = Boolean,
        set                     = function(self, value) self:SetAttribute("noAutoFlyout", value or false) end,
        get                     = function(self) return self:GetAttribute("noAutoFlyout") or false end,
    }

    --- The swap mode of the button
    property "SwapMode"         {
        type                    = SwapMode,
        set                     = function(self, value) self:SetAttribute("swapMode", value) end,
        get                     = function(self) return self:GetAttribute("swapMode") or SwapMode.None end,
    }

    ------------------------------------------------------
    -- Static Property
    ------------------------------------------------------
    __Static__()
    property "BarPool"          { set = false, default = RECYCLE_BARS }

    __Static__()
    property "PopupDuration"    { handler = function(self, value) _ManagerFrame:SetAttribute("popupDuration", value) end }

    __Static__()
    property "EditMode"         { type = Boolean, handler = function(_, mode)
            if mode then
                _ManagerFrame:Execute[[ Manager:Run(FORCE_BAR_SHOW) ]]

                for bar in pairs(autoFadeOutBar) do
                    bar:SetAttribute("autoFadeOut", nil)
                    bar:SetAlpha(1)
                end
            else
                NoCombat(function() _ManagerFrame:Execute[[ Manager:Run(UPDATE_BAR_AUTOHIDE) ]] end)

                for bar in pairs(autoFadeOutBar) do
                    bar:SetAttribute("autoFadeOut", true)
                    AddAutoFadeWatch(bar)
                end
            end
        end
    }

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function SetProfile(self, config)
        if config then
            self:SetLocation(config.Style.location)
            self:SetScale(config.Style.scale)

            self:SetClampedToScreen(true)

            self.ActionBarMap       = config.Style.actionBarMap
            self.AutoHideCondition  = config.Style.autoHideCondition or nil
            self.AutoFadeOut        = config.Style.autoFadeOut
            self.FadeAlpha          = config.Style.fadeAlpha
            self.GridAlwaysShow     = config.Style.gridAlwaysShow
            self.NoAutoFlyout       = config.Style.noAutoFlyout or false
            self.SwapMode           = config.Style.swapMode

            self.AutoPosition       = false
            self.KeepMaxSize        = true
            self.RowCount           = config.Style.rowCount or 1
            self.ColumnCount        = config.Style.columnCount or 1
            self.ElementWidth       = 36
            self.ElementHeight      = 36
            self.Orientation        = config.Style.orientation
            self.LeftToRight        = config.Style.leftToRight
            self.TopToBottom        = config.Style.topToBottom
            self.HSpacing           = config.Style.hSpacing or 1
            self.VSpacing           = config.Style.vSpacing or 1
            self.Count              = max(min(config.Style.count, config.Style.rowCount * config.Style.columnCount), 1)

            if config.Buttons and #config.Buttons > 0 then
                for i = 1, self.Count do
                    self.Elements[i]:SetProfile(config.Buttons[i])
                end
            end
        else
            -- Clear
            self:SetScale(1)
            self.ActionBarMap       = ActionBarMap.NONE
            self.AutoHideCondition  = nil
            self.AutoFadeOut        = false
            self.NoAutoFlyout       = false
            self.SwapMode           = nil
            self.FadeAlpha          = 0
            self.Count              = 0
        end
    end

    function GetProfile(self, nocontent)
        return {
            Style               = {
                location        = self:GetLocation(),
                scale           = self:GetScale(),
                actionBarMap    = self.ActionBarMap,
                autoHideCondition = self.AutoHideCondition and #self.AutoHideCondition > 0 and Toolset.clone(self.AutoHideCondition) or nil,
                autoFadeOut     = not self.IsFlyoutBar and self.AutoFadeOut or false,
                fadeAlpha       = not self.IsFlyoutBar and self.FadeAlpha or 0,
                swapMode        = self.IsFlyoutBar and self.SwapMode or nil,
                gridAlwaysShow  = self.GridAlwaysShow,
                noAutoFlyout    = self.NoAutoFlyout or nil,

                rowCount        = self.RowCount,
                columnCount     = self.ColumnCount,
                count           = self.Count,
                orientation     = self.Orientation,
                leftToRight     = self.LeftToRight,
                topToBottom     = self.TopToBottom,
                hSpacing        = self.HSpacing,
                vSpacing        = self.VSpacing,
            },

            Buttons             = XList(self:GetIterator()):Map(function(self) return self:GetProfile(nocontent) end):ToTable(),
        }
    end

    function SetSpacing(self, hSpacing, vSpacing)
        if hSpacing then self.HSpacing = hSpacing end
        if vSpacing then self.VSpacing = vSpacing end

        for _, btn in self:GetIterator() do
            if btn.FlyoutBar then
                btn.FlyoutBar:SetSpacing(hSpacing, vSpacing)
                UpdateFlyoutLocation(btn)
            end
        end
    end

    function HasMouseOver(self)
        if self:IsMouseOver() then return true end

        for _, btn in self:GetIterator() do
            local bar           = btn.FlyoutBar
            if bar and bar:HasMouseOver() then return true end
        end

        return false
    end

    __NoCombat__()
    function RefreshStance(self)
        if self.ActionBarMap ~= ActionBarMap.STANCEBAR then return end

        local count             = GetNumShapeshiftForms() or 0

        for i = 1, self.Count do
            local id            = i <= count and select(4, GetShapeshiftFormInfo(i))
            if id then
                self.Elements[i]:SetAction("spell", id)
            else
                self.Elements[i]:SetAction(nil)
            end
        end
    end

    __SecureMethod__()
    function GetSpellFlyoutDirection(self)
        return self.FlyoutDirection
    end

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    function __ctor(self)
        super(self)

        self:SetMouseMotionEnabled(true)
        self:SetMovable(false)
        self:SetResizable(false)

        self.OnElementAdd       = self.OnElementAdd + onElementAdd
        self.OnElementRemove    = self.OnElementRemove + onElementRemove
        self.OnEnter            = self.OnEnter + onEnter
        self.OnShow             = self.OnShow + onShow
        self.OnHide             = self.OnHide + onHide
    end
end)

do
    __Sealed__()
    class "DancerButtonAlert" { SpellActivationAlert }

    --- SpellActivationAlert
    UI.Property                     {
        name                        = "SpellActivationAlert",
        require                     = DancerButton,
        type                        = Boolean,
        default                     = false,
        set                         = function(self, value)
            local alert             = self.__SpellActivationAlert
            if value then
                if not alert then
                    alert           = SpellActivationAlert.Pool[DancerButtonAlert]()
                    local w, h      = self:GetSize()

                    alert:SetParent(self)
                    alert:ClearAllPoints()
                    alert:SetPoint("CENTER")
                    alert:SetSize(w * 1.4, h * 1.4)
                    self.__SpellActivationAlert = alert
                end

                alert.AnimationState= "IN"
            else
                if alert then
                    alert.AnimationState = "OUT"
                    self.__SpellActivationAlert = nil
                end
            end
        end,
    }

    Style.UpdateSkin("Default",     { [DancerButtonAlert] = {} })
end