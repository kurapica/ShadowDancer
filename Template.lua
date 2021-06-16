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

do
    class "DancerButton" {}

    RECYCLE_BUTTONS             = Recycle(DancerButton, "ShadowDancerButton%d", UIParent)

    ROOT_MAP                    = Dictionary()
    FLYOUT_MAP                  = Dictionary()

    ------------------------------------------------------
    --                Secure Environment                --
    ------------------------------------------------------
    _ManagerFrame               = SecureFrame("ShadowDancer_Manager", UIParent, "SecureHandlerStateTemplate")
    _ManagerFrame:Hide()

    _ManagerFrame:Execute[[
        Manager                 = self

        ROOT_MAP                = newtable()
        FLYOUT_MAP              = newtable()
    ]]

    _OnEnter                    = [[
    ]]

    _PreClick                   = [[
    ]]

    _PostClick                  = [[
    ]]

    _OnAttributeChanged         = [[
        print("OnAttributeChanged", self:GetName(), name, value)

        if name == "statehidden" then
        elseif name == "alwaysShowFlyout" then
        end
    ]]

    __NoCombat__()
    function RECYCLE_BUTTONS:OnPush(button)
        button:SetAction(nil)

        -- Release all relations in both secure and un-secure
        -- Beware in secure environment, we use the hash to save the relationship
        -- in un-secure, we use list to save
        _ManagerFrame:SetFrameRef("DancerButton", button)
        _ManagerFrame:Execute[[
            local button        = Manager:GetFrameRef("DancerButton")
            local root          = ROOT_MAP[button]

            ROOT_MAP[button]    = nil
            FLYOUT_MAP[button]  = nil

            if root then
                if FLYOUT_MAP[root] then
                    FLYOUT_MAP[root][button] = nil
                end
            end
        ]]

        local root              = ROOT_MAP[button]

        ROOT_MAP[button]        = nil
        FLYOUT_MAP[button]      = nil

        if root then
            if FLYOUT_MAP[root] then
                FLYOUT_MAP[root]:Remove(button)
            end
        end
        button.AlwaysShowFlyout = false
    end
end

__Sealed__()
class "DancerButton" (function(_ENV)
    inherit "SecureActionButton"

    ------------------------------------------------------
    --                     Helper                       --
    ------------------------------------------------------
    local function OnMouseDown(self, button)
        if InCombatLockdown() or button ~= "LeftButton" then return end

        if IsAltKeyDown() then
            -- Generate the flyout buttons if the button is not a flyout button or the last
        elseif IsShiftKeyDown()  then
            -- Generate the brother button if the button is the root button or the last button of the bar

        end
    end

    ------------------------------------------------------
    --                     Property                     --
    ------------------------------------------------------
    --- Whether the flyout buttons of this always show(if this button is shown)
    property "AlwaysShowFlyout" {
            type                = Boolean,
            set                 = function(self, value) self:SetAttribute("alwaysShowFlyout", value or false) end,
            get                 = function(self) return self:GetAttribute("alwaysShowFlyout" or false) end,
        end
    }

    ------------------------------------------------------
    --                      Method                      --
    ------------------------------------------------------


    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self)
        _ManagerFrame:WrapScript(self, "OnEnter", _OnEnter)
        _ManagerFrame:WrapScript(self, "OnClick", _PreClick, _PostClick)
        _ManagerFrame:WrapScript(self, "OnAttributeChanged", _OnAttributeChanged)
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

    local function OnElementAdd(self, ele)
        setupActionMap(ele, self.ActionBarMap)
    end

    local function OnElementRemove(self, ele)
        clearActionMap(ele, self.ActionBarMap)
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

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function LoadProfile(self, config)

    end

    function SaveProfile(self)

    end

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    function __ctor(self)
        self:SetMovable(false)
        self:SetResizable(false)

        self.OnElementAdd       = self.OnElementAdd + OnElementAdd
        self.OnElementRemove    = self.OnElementRemove + OnElementRemove
    end
end)

Style.UpdateSkin("Default",     {
    [DancerButton]              = {

    },
    [ShadowBar]                 = {
        minResize               = Size(36, 36),
        MaxResize               = Size(36 * BAR_MAX_BUTTON, 36 * BAR_MAX_BUTTON),

        elementWidth            = 36,
        elementHeight           = 36,
    },
})