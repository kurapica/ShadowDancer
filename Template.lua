--========================================================--
--                ShadowDancer Template                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/06/02                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer.Template"            "1.0.0"
--========================================================--

namespace "ShadowDancer"

import "Scorpio.Secure"
import "System.Reactive"

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
    -- STANCE                      = 101,
    -- WORLDMARK                   = 102,
    -- RAIDTARGET                  = 103,
}

do
    class "DancerButton" {}
    class "ShadowBar"    {}

    RECYCLE_BUTTONS             = Recycle(DancerButton, "ShadowDancerButton%d", UIParent)
    RECYCLE_BARS                = Recycle(ShadowBar,    "ShadowDancerBar%d",    UIParent)

    ------------------------------------------------------
    --                Secure Environment                --
    ------------------------------------------------------
    _ManagerFrame               = SecureFrame("ShadowDancer_Manager", UIParent, "SecureHandlerStateTemplate")
    _ManagerFrame:Hide()

    _ManagerFrame:Execute[==[
        Manager                 = self

        FLYOUT_MAP              = newtable() --  BUTTON  <-> BAR
        BAR_MAP                 = newtable() -- {BUTTON} <-> BAR

        -- temp tables
        EFFECT_BAR              = newtable()
        EFFECT_BUTTON           = newtable()
        TOGGLE_ROOT_BUTTON      = newtable()

        -- Auto fade
        AutoHideMap             = newtable()
        AutoFadeMap             = newtable()
        State                   = newtable()

        CALC_EFFECT_BAR         = [=[
            local bar           = FLYOUT_MAP[self]
            if not bar then return end

            EFFECT_BAR[bar]     = true

            local buttons       = BAR_MAP[bar]
            if not buttons then return end

            for btn in pairs(buttons) do
                if FLYOUT_MAP[btn] and FLYOUT_MAP[btn]:IsVisible() then
                    Manager:RunFor(btn, CALC_EFFECT_BAR)
                end
            end
        ]=]

        CALC_EFFECT_BUTTON      = [=[
            EFFECT_BUTTON[self] = true

            local bar           = BAR_MAP[self]
            if bar and bar:GetAttribute("isFlyoutBar") then
                local root      = FLYOUT_MAP[bar]
                if not root:GetAttribute("alwaysFlyout") then
                    Manager:RunFor(root, CALC_EFFECT_BUTTON)
                end
            end
        ]=]


        HIDE_FLYOUT_BARS        = [=[
            self:UnregisterAutoHide()

            local bar           = FLYOUT_MAP[self]
            if not bar then return end

            local buttons       = BAR_MAP[bar]

            if buttons then
                for btn in pairs(buttons) do
                    if FLYOUT_MAP[btn] and FLYOUT_MAP[btn]:IsVisible() then
                        Manager:RunFor(btn, HIDE_FLYOUT_BARS)
                    end
                end
            end

            if not self:GetAttribute("alwaysFlyout") then
                bar:Hide()
            end
        ]=]
    ]==]

    function RECYCLE_BUTTONS:OnPop(button)
        button:Show()
    end

    function RECYCLE_BUTTONS:OnPush(button)
        button:SetProfile(nil)
        button:ClearAllPoints()
        button:Hide()
    end

    function RECYCLE_BARS:OnPop(bar)
        bar:Show()
    end

    function RECYCLE_BARS:OnPush(bar)
        bar:SetParent(UIParent)
        bar.IsFlyoutBar             = false
        Style[bar]                  = {
            autoFadeOut             = false,
            autoHideCondition       = {},
            fadeAlpha               = 0,
        }
        UnregisterAutoHide(self)
        bar:SetAlpha(1)
        bar:SetProfile(nil)
        bar:ClearAllPoints()
        bar:Hide()
    end

    function UpdateFlyoutLocation(self)
        if not self.FlyoutBar then return end

        local dir                   = self.FlyoutDirection or "UP"

        if dir == "UP" then
            Style[self.FlyoutBar]   = {
                location            = { Anchor("BOTTOM", 0, self.FlyoutBar.VSpacing, nil, "TOP") },
                topToBottom         = false,
                leftToRight         = true,
                orientation         = "VERTICAL",
                rowCount            = self.FlyoutBar.Count,
                columnCount         = 1,
            }
        elseif dir == "DOWN" then
            Style[self.FlyoutBar]   = {
                location            = { Anchor("TOP", 0, - self.FlyoutBar.VSpacing, nil, "BOTTOM") },
                topToBottom         = true,
                leftToRight         = true,
                orientation         = "VERTICAL",
                rowCount            = self.FlyoutBar.Count,
                columnCount         = 1,
            }
        elseif dir == "LEFT" then
            Style[self.FlyoutBar]   = {
                location            = { Anchor("RIGHT", - self.FlyoutBar.HSpacing, 0, nil, "LEFT") },
                topToBottom         = true,
                leftToRight         = false,
                orientation         = "HORIZONTAL",
                columnCount         = self.FlyoutBar.Count,
                rowCount            = 1,
            }
        elseif dir == "RIGHT" then
            Style[self.FlyoutBar]   = {
                location            = { Anchor("LEFT", self.FlyoutBar.HSpacing, 0, nil, "RIGHT") },
                topToBottom         = true,
                leftToRight         = true,
                orientation         = "HORIZONTAL",
                columnCount         = self.FlyoutBar.Count,
                rowCount            = 1,
            }
        end
    end


    function RegisterAutoHide(self, cond, autofade)
        self.AutoHideState      = "autohide" .. self.Name

        _ManagerFrame:SetFrameRef("ShadowBar", self)
        _ManagerFrame:Execute(([[
            local name          = "%s"
            local bar           = Manager:GetFrameRef("ShadowBar")
            AutoHideMap[name]   = bar
            AutoHideMap[bar]    = name
            AutoFadeMap[name]   = %s
            bar:SetAttribute("autofadeout", false)
        ]]):format(self.AutoHideState, tostring(autofade or false)))

        _ManagerFrame:RegisterStateDriver(self.AutoHideState, cond)
        _ManagerFrame:SetAttribute("_onstate-" .. self.AutoHideState, ([[
            local name          = "%s"
            local bar           = AutoHideMap[name]
            if not bar then return end
            local autofade      = AutoFadeMap[name]

            State[bar]          = newstate ~= "hide"

            if newstate == "hide" then
                if autofade then
                    bar:SetAttribute("autofadeout", true)
                    Manager:CallMethod("StartAutoFadeOut", bar:GetName())
                else
                    local btns  = BAR_MAP[bar]
                    if btns then
                        for btn in pairs(btns) do
                            if FLYOUT_MAP[btn] then
                                Manager:RunFor(btn, HIDE_FLYOUT_BARS)
                            end
                        end
                    end

                    bar:Hide()
                end
            else
                bar:Show()

                if autofade then
                    bar:SetAttribute("autofadeout", false)
                    Manager:CallMethod("StopAutoFadeOut", bar:GetName())
                end
            end
        ]]):format(self.AutoHideState))
        _ManagerFrame:SetAttribute("state-" .. self.AutoHideState, nil)
    end

    function UnregisterAutoHide(self)
        if not self.AutoHideState then return end

        _ManagerFrame:UnregisterStateDriver(self.AutoHideState)

        _ManagerFrame:SetFrameRef("ShadowBar", self)
        _ManagerFrame:Execute(([[
            local name          = "%s"
            local bar           = Manager:GetFrameRef("ShadowBar")
            AutoHideMap[name]   = nil
            AutoHideMap[bar]    = nil
            AutoFadeMap[name]   = nil
            State[bar]          = nil

            bar:Show()
        ]]):format(self.AutoHideState))
        _ManagerFrame:SetAttribute("state-" .. self.AutoHideState, nil)

        self.AutoHideState = nil
    end

    __SecureMethod__()
    function _ManagerFrame:StartAutoFadeOut(name)
        GetProxyUI(_G[name]):OnLeave()
    end

    __SecureMethod__()
    function _ManagerFrame:StopAutoFadeOut(name)
        GetProxyUI(_G[name]):OnLeave()
    end

end

__Sealed__()
class "DancerButton" (function(_ENV)
    inherit "SecureActionButton"

    export{ abs = math.abs, floor = math.floor, min = math.min }

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
            isLast              = self.ID == self:GetParent().Count
        end

        Delay(0.2)

        while IsMouseButtonDown("LeftButton") and not InCombatLockdown() and IsControlKeyDown() do
            local x, y          = GetCursorPosition()
            x, y                = x / e, y / e

            -- Check the direction
            local row           = y > cy and floor((y + h / 2 - cy) / h) or floor((y - h / 2 - cy) / h)
            local col           = x > cx and floor((x + w / 2 - cx) / w) or floor((x - w / 2 - cx) / w)
            local arow, acol    = abs(row), abs(col)

            if(arow >= 1 or acol >= 1) then
                local dir       = arow >= acol and (row > 0 and "UP" or "DOWN") or (col > 0 and "RIGHT" or "LEFT")

                if not (isGenBar or isAdjustBar) then
                    -- Init check
                    if baseBarRoot and isLast and ((baseBar.Orientation == "HORIZONTAL" and (dir == "LEFT" or dir == "RIGHT")) or (baseBar.Orientation == "VERTICAL" and (dir == "UP" or dir == "DOWN"))) then
                        isGenBar        = true  -- Change the bar of the base

                        self            = baseBarRoot
                        baseBar         = self:GetParent()
                        orgDir          = self.FlyoutDirection
                        cx, cy          = self:GetCenter()
                        orgFlyout       = self.FlyoutDirection
                        btnProfiles     = XList(baseBar:GetIterator()):Map(DancerButton.GetProfile):ToList()  -- temporary keep the button profiles

                        for _, btn in self.FlyoutBar:GetIterator() do
                            if btn.FlyoutBar then btn.FlyoutBar:Hide() end
                        end
                    elseif not baseBar.IsFlyoutBar or ((baseBar.Orientation == "HORIZONTAL" and (dir == "UP" or dir == "DOWN")) or (baseBar.Orientation == "VERTICAL" and (dir == "LEFT" or dir == "RIGHT"))) then
                        -- For flyout bar, only cross direction is allowed
                        if self.FlyoutBar then
                            isAdjustBar = true
                            orgFlyout   = self.FlyoutDirection

                            for _, btn in self.FlyoutBar:GetIterator() do
                                if btn.FlyoutBar then btn.FlyoutBar:Hide() end
                            end
                        else
                            isGenBar    = true
                            orgDir      = dir
                        end
                    end
                elseif isGenBar then
                    if not orgDir and (not baseBar.IsFlyoutBar or ((baseBar.Orientation == "HORIZONTAL" and (dir == "UP" or dir == "DOWN")) or (baseBar.Orientation == "VERTICAL" and (dir == "LEFT" or dir == "RIGHT")))) the
                        orgDir          = dir
                    end

                    local rowCount      = 1
                    local columnCount   = 1
                    local count         = 0

                    if orgDir == "UP" then
                        count           = row > 0 and row or 0
                        rowCount        = count
                    elseif orgDir == "DOWN" then
                        count           = row < 0 and arow or 0
                        rowCount        = count
                    elseif orgDir == "LEFT" then
                        count           = col < 0 and acol or 0
                        columnCount     = count
                    elseif orgDir == "RIGHT" then
                        count           = col > 0 and col or 0
                        columnCount     = count
                    end

                    if count > 0 then
                        self.FlyoutDirection= orgDir
                        if not self.FlyoutBar then
                            self.FlyoutBar  = ShadowBar.BarPool()

                            Style[self.FlyoutBar] = {
                                hSpacing    = baseBar.HSpacing,
                                vSpacing    = baseBar.VSpacing,
                            }

                            UpdateFlyoutLocation(self)
                        end

                        Style[self.FlyoutBar] = {
                            rowCount        = rowCount,
                            columnCount     = columnCount,
                            count           = count,
                        }
                    else
                        self.FlyoutBar  = nil
                        orgDir          = nil
                    end
                elseif isAdjustBar then
                    if not baseBar.IsFlyoutBar or ((baseBar.Orientation == "HORIZONTAL" and (dir == "UP" or dir == "DOWN")) or (baseBar.Orientation == "VERTICAL" and (dir == "LEFT" or dir == "RIGHT"))) the
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
                end
            end
        elseif isGenBar and btnProfiles and #btnProfiles > 0 then
            -- Restore the buttons
            for i = 1, min(self.FlyoutBar.Count, #btnProfiles) do
                btn:SetProfile(btnProfiles[i])
            end

            local diff                  = (getDirectionValue(self.FlyoutDirection) - getDirectionValue(orgFlyout)) % 4
            if diff == 0 then return end

            for _, btn in self.FlyoutBar:GetIterator() do
                if btn.FlyoutBar then
                    clockwise(btn, diff)
                    btn.FlyoutBar:SetShown(btn.AlwaysFlyout)
                end
            end
        end
    end

    local function onMouseDown(self, button)
        return button == "LeftButton" and IsControlKeyDown() and not InCombatLockdown() and Next(regenerateFlyout, self)
    end

    local function onEnter(self)
        local bar               = self:GetParent()
        while bar.IsFlyoutBar do
            bar                 = bar:GetParent():GetParent()
        end
        return bar:OnEnter()
    end

    local function onLeave(self)
        local bar               = self:GetParent()
        while bar.IsFlyoutBar do
            bar                 = bar:GetParent():GetParent()
        end
        return bar:OnLeave()
    end

    ------------------------------------------------------
    --                     Property                     --
    ------------------------------------------------------
    --- The action button group
    property "ActionButtonGroup"{ set = false, default = "AshToAsh" }

    --- Whether the flyout buttons of this always show(if this button is shown)
    property "AlwaysFlyout"     {
            type                = Boolean,
            set                 = function(self, value) self:SetAttribute("alwaysFlyout", value or false) end,
            get                 = function(self) return self:GetAttribute("alwaysFlyout") or false end,
        end
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
            end
        end
    }

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function SetProfile(self, config)
        if config then
            local parent        = self:GetParent()

            if parent.ActionBarMap == ActionBarMap.NONE then
                self:SetAction(config.ActionType, config.ActionTarget, config.ActionDetail)
            end

            self.FlyoutDirection= config.FlyoutDirection
            self.AlwaysFlyout   = config.AlwaysFlyout

            self.AutoKeyBinding = parent.IsFlyoutBar
            self.HotKey         = config.HotKey

            if config.FlyoutBar then
                self.FlyoutBar  = self.FlyoutBar or ShadowBar.BarPool()
                self.FlyoutBar:SetProfile(config.FlyoutBar)
                self.FlyoutBar:SetShown(self.AlwaysFlyout)
            else
                self.FlyoutBar  = nil
            end
        else
            -- Clear
            self:SetAction(nil)
            self.HotKey         = nil
            self.FlyoutBar      = nil
        end
    end

    function GetProfile(self)
        local needAction        = self:GetParent().ActionBarMap == ActionBarMap.NONE

        return {
            -- Action Info
            ActionType          = needAction and self.ActionType or nil,
            ActionTarget        = needAction and self.ActionTarget or nil,
            ActionDetail        = needAction and self.ActionDetail or nil,

            FlyoutDirection     = self.FlyoutDirection,
            AlwaysFlyout        = self.AlwaysFlyout,
            HotKey              = self.HotKey,

            FlyoutBar           = self.FlyoutBar and self.FlyoutBar:GetProfile(),
        }
    end

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self)
        _ManagerFrame:WrapScript(self, "OnEnter", [=[
                if BAR_MAP[self] and FLYOUT_MAP[self] and not FLYOUT_MAP[self]:IsVisible() then
                    FLYOUT_MAP[self]:Show()
                    if self:GetAttribute("alwaysFlyout") then return end

                    self:RegisterAutoHide(Manager:GetAttribute("popupDuration") or 0.25)

                    wipe(EFFECT_BAR) wipe(EFFECT_BUTTON)
                    Manager:RunFor(self, CALC_EFFECT_BAR)
                    Manager:RunFor(self, CALC_EFFECT_BUTTON)

                    for root in pairs(EFFECT_BUTTON) do
                        for bar in pairs(EFFECT_BAR) do
                            root:AddToAutoHide(bar)
                        end
                    end
                end
            ]=]
        )

        _ManagerFrame:WrapScript(self, "OnClick", [=[
                if FLYOUT_MAP[self] then
                    if button == "RightButton" and not (IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()) then
                        -- No modify right click to toggle always show of the flyout bar
                        self:SetAttribute("alwaysFlyout", not self:GetAttribute("alwaysFlyout"))
                        return false
                    elseif not self:GetAttribute("alwaysFlyout") then
                        -- Toggle the flyout if the action type is empty
                        local atype = self:GetAttribute("actiontype")
                        if not atype or atype == "" or atype == "empty" then
                            if FLYOUT_MAP[self]:IsVisible() then
                                Manager:RunFor(self, HIDE_FLYOUT_BARS)
                            else
                                FLYOUT_MAP[self]:Show()
                            end

                            return false
                        end
                    end
                end

                while BAR_MAP[self]:GetAttribute("isFlyoutBar") do self = FLYOUT_MAP[BAR_MAP[self]] end
                TOGGLE_ROOT_BUTTON[1] = FLYOUT_MAP[self] and self or nil

                -- return messge if need to do a flyout auto hide
                return button, TOGGLE_ROOT_BUTTON[1] and "toggle" or nil
            ]=], [=[
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
        self.OnLeave            = self.OnLeave = onLeave
    end
end)

__Sealed__()
class "ShadowBar" (function(_ENV)
    inherit "SecurePanel"

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
            self:SetAction("action", self.ID)
        elseif map >= ActionBarMap.BAR1 and map <= ActionBarMap.BAR6 then
            self:SetActionPage(map)
            self:SetAction("action", self.ID)
        end
    end

    local function handlerAutoHideOrFade(self)
        if self.IsFlyoutBar then
            self:SetAttribute("autoFadeOut", nil)
            UnregisterAutoHide(self)
            self:SetAlpha(1)
        else
            if self.AutoHideCondition and #self.AutoHideCondition > 0 then
                local cond      = ""
                for _, k in ipairs(self.AutoHideCondition) do cond = cond .. k .. "hide;" end
                cond            = cond .. "show;"
                RegisterAutoHide(self, cond, self.AutoFadeOut)
            else
                UnregisterAutoHide(self)
                self:SetAttribute("autoFadeOut", self.AutoFadeOut)
                if self.AutoFadeOut then self:OnLeave() end
            end
        end
    end

    local function autoFadeOut(self)
        local task              = self.__AutoFadeOutTask
        local endt              = GetTime() + 2
        local min               = self.FadeAlpha
        local df                = 1 - min

        while self.__AutoFadeOutTask == task and self:GetAttribute("autofadeout") do
            local now           = GetTime()
            if now >= endt then return self:SetAlpha(min) end

            self:SetAlpha(min + (endt - now) / 2 * df)
            Next()
        end
    end

    local function onElementAdd(self, ele)
        _ManagerFrame:SetFrameRef("ShadowBar", self)
        _ManagerFrame:SetFrameRef("DancerButton", ele)

        _ManagerFrame:Execute[[
            local bar           = Manager:GetFrameRef("ShadowBar")
            local button        = Manager:GetFrameRef("DancerButton")

            if not BAR_MAP[bar] then
                BAR_MAP[bar]= newtable()
            end

            BAR_MAP[bar][button] = true
            BAR_MAP[button]     = bar
        ]]

        return setupActionMap(ele, self.ActionBarMap)
    end

    local function onElementRemove(self, ele)
        _ManagerFrame:SetFrameRef("ShadowBar", self)
        _ManagerFrame:SetFrameRef("DancerButton", ele)

        _ManagerFrame:Execute[[
            local bar           = Manager:GetFrameRef("ShadowBar")
            local button        = Manager:GetFrameRef("DancerButton")

            if BAR_MAP[bar] then
                BAR_MAP[bar][button] = nil
            end
            BAR_MAP[button]     = nil
        ]]

        return clearActionMap(ele, self.ActionBarMap)
    end

    local function onEnter(self)
        if self.AutoFadeOut then
            self.__AutoFadeOutTask = (self.__AutoFadeOutTask or 0) + 1
        end
        self:SetAlpha(1)
    end

    local function onLeave(self)
        if self:GetAttribute("autoFadeOut") and not self.IsFlyoutBar then
            self.__AutoFadeOutTask = (self.__AutoFadeOutTask or 0) + 1
            return Next(autoFadeOut, self)
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
            for i = 1, self.Count do
                local ele       = self.Elements[i]
                clearActionMap(ele, old)
                setupActionMap(ele, map)
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
    property "FadeAlpha"        { type = Number,  default = 0, handler = function(self, val)
            val                 = val or 0
            if self:GetAlpha() < val then self:SetAlpha(val) end
        end
    }


    ------------------------------------------------------
    -- Static Property
    ------------------------------------------------------
    __Static__()
    property "BarPool"          { set = false, default = RECYCLE_BARS }

    __Static__()
    property "PopupDuration"    { handler = function(self, value) _ManagerFrame:SetAttribute("popupDuration", value) end }

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function SetProfile(self, config)
        if config then
            Style[self]         = config.Style

            if config.Buttons and #config.Buttons > 0 then
                for i = 1, self.Count do
                    self.Elements[i]:SetProfile(config.Buttons[i])
                end
            end
        else
            -- Clear
            self.ActionBarMap   = ActionBarMap.NONE
            self.Count          = 0
        end
    end

    function GetProfile(self)
        return {
            Style               = {
                location        = self:GetLocation(),
                scale           = self:GetScale(),
                actionBarMap    = self.ActionBarMap,
                autoHideCondition = self.AutoHideCondition and Toolset.clone(self.AutoHideCondition),
                autoFadeOut     = not self.IsFlyoutBar and self.AutoFadeOut or false,
                fadeAlpha       = not self.IsFlyoutBar and self.FadeAlpha or 0,

                rowCount        = self.RowCount,
                columnCount     = self.ColumnCount,
                count           = self.Count,
                elementWidth    = self.ElementWidth,
                elementHeight   = self.ElementHeight,
                orientation     = self.Orientation,
                leftToRight     = self.LeftToRight,
                topToBottom     = self.TopToBottom,
                hSpacing        = self.HSpacing,
                vSpacing        = self.VSpacing,
            },

            Buttons             = XList(self:GetIterator()):Map(DancerButton.GetProfile):ToTable(),
        }
    end

    function SetSpacing(self, hSpacing, vSpacing)
        Style[self]             = {
            hSpacing            = hSpacing or self.HSpacing,
            vSpacing            = vSpacing or self.VSpacing,
        }

        for _, btn in self:GetIterator() do
            if btn.FlyoutBar then
                btn.FlyoutBar:SetSpacing(hSpacing, vSpacing)
                UpdateFlyoutLocation(btn)
            end
        end
    end

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    __InstantApplyStyle__()
    function __ctor(self)
        self:SetMovable(false)
        self:SetResizable(false)

        self.OnElementAdd       = self.OnElementAdd + onElementAdd
        self.OnElementRemove    = self.OnElementRemove + onElementRemove
        self.OnEnter            = self.OnEnter + onEnter
        self.OnLeave            = self.OnLeave + onLeave
    end
end)

Style.UpdateSkin("Default",     {
    [DancerButton]              = {

    },
    [ShadowBar]                 = {
        minResize               = Size(36, 36),

        elementWidth            = 36,
        elementHeight           = 36,
    },
})