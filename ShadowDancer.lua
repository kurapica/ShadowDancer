--========================================================--
--                ShadowDancer                            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/05/16                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer"                     "1.0.0"
--========================================================--

namespace "ShadowDancer"

import "Scorpio.Secure"
import "System.Reactive"
import "System.Text"

export { floor = math.floor, min = math.min, max = math.max, ceil = math.ceil, tinsert = table.insert, sqrt = math.sqrt }

BAR_MAX_BUTTON                  = 12
HIDDEN_FRAME                    = CreateFrame("Frame") HIDDEN_FRAME:Hide()
RECYCLE_MASKS                   = Recycle(Scorpio.Widget.Mask, "ShadowDancer_Mask%d", HIDDEN_FRAME)

GLOBAL_BARS                     = List()
CURRENT_BARS                    = List()
CURRENT_SPEC                    = false
UNLOCK_BARS                     = false

ANCHORS                         = XList(Enum.GetEnumValues(FramePoint)):Map(function(x) return { Anchor(x, 0, 0) } end):ToList()

IS_SECURE_LOADED                = false

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB                       = SVManager("ShadowDancer_DB", "ShadowDancer_CharDB")

    _SVDB:SetDefault            {
        PopupDuration           = 0.25,
        HideOriginalBar         = false,

        -- Global Bars
        ActionBars              = {}
    }

    _SVDB.Char:SetDefault       {
        AutoGenBlackList        = {},
    }

    CharSV():SetDefault         {
        Draggable               = true,
        UseMouseDown            = false,

        ActionBars              = {},
    }

    ShadowBar.PopupDuration     = _SVDB.PopupDuration

    _AutoGenBlackList           = _SVDB.Char.AutoGenBlackList

    _AuctionItemClasses         = {}

    local i                     = 0
    local itemCls               = GetItemClassInfo(i)

    while itemCls and #itemCls > 0 do
        _AuctionItemClasses[i]  = { name = itemCls }
        _AuctionItemClasses[itemCls] = _AuctionItemClasses[i]

        local j                 = 0
        local itemSubCls        = GetItemSubClassInfo(i, j)

        while itemSubCls and #itemSubCls > 0 do
            _AuctionItemClasses[i][j] = itemSubCls
            _AuctionItemClasses[i][itemSubCls] = j

            j = j + 1
            itemSubCls          = GetItemSubClassInfo(i, j)
        end

        i                       = i + 1
        itemCls                 = GetItemClassInfo(i)
    end
end

function OnEnable()
    -- Load Global Bars
    for i = 1, #_SVDB.ActionBars do
        local bar               = ShadowBar.BarPool()
        GLOBAL_BARS:Insert(bar)
        bar:SetProfile(_SVDB.ActionBars[i])
    end
end

function OnSpecChanged(self, spec)
    local preProfile

    -- Save the config if we have the bars
    if #CURRENT_BARS > 0 and CURRENT_SPEC and IS_SECURE_LOADED then
        preProfile              = CURRENT_BARS:Map(ShadowBar.GetProfile):ToTable()
        CharSV(CURRENT_SPEC).ActionBars = preProfile
    end

    IS_SECURE_LOADED            = false

    CURRENT_SPEC                = spec or 1

    local charSV                = CharSV()

    --- Load bar from other spec or just init it
    if #_SVDB.ActionBars == 0 and #charSV.ActionBars == 0 then
        charSV.ActionBars       = preProfile and #preProfile > 0 and Toolset.clone(preProfile, true) or {
            {
                Style           = {
                    location    = { Anchor("CENTER") },
                    scale       = 1.0,
                    actionBarMap= ActionBarMap.MAIN,
                    gridAlwaysShow = true,

                    rowCount    = 1,
                    columnCount = 12,
                    count       = 12,
                    elementWidth= 36,
                    elementHeight = 36,
                    orientation = "HORIZONTAL",
                    leftToRight = true,
                    topToBottom = true,
                    hSpacing    = 1,
                    vSpacing    = 1,
                },
                Buttons         = {},
            }
        }
    end

    UpdateOriginalBar()
    SecureActionButton.Draggable["AshToAsh"] = charSV.Draggable
    SecureActionButton.UseMouseDown["AshToAsh"] = charSV.UseMouseDown

    -- Load Bars
    local barCount              = #charSV.ActionBars

    for i = 1, barCount do
        local bar               = CURRENT_BARS[i]
        if not bar then
            bar                 = ShadowBar.BarPool()
            CURRENT_BARS:Insert(bar)
        end

        bar:SetProfile(charSV.ActionBars[i])
    end

    for i = #CURRENT_BARS, barCount + 1, -1 do
        ShadowBar.BarPool(CURRENT_BARS:RemoveByIndex(i))
    end

    IS_SECURE_LOADED            = true
end

function OnQuit()
    if not IS_SECURE_LOADED then return end

    CharSV().ActionBars         = CURRENT_BARS:Map(ShadowBar.GetProfile):ToTable()
    _SVDB.ActionBars            = GLOBAL_BARS:Map(ShadowBar.GetProfile):ToTable()
end

function RECYCLE_MASKS:OnInit(mask)
    mask.OnClick                = OpenMaskMenu
    mask.OnStopMoving           = OnStopMoving
end

function RECYCLE_MASKS:OnPush(mask)
    mask:SetParent(HIDDEN_FRAME)
    mask:Hide()
end

function RECYCLE_MASKS:OnPop(mask)
    mask:Show()
end

__Service__(true)
function AutoHideShowService()
    while true do
        local event             = Wait("ACTIONBAR_SHOWGRID", "SCORPIO_ACTION_BUTTON_KEY_BINDING_START")

        if not InCombatLockdown() then
            -- disable auto hide when key binding or place actions
            for i, bar in GLOBAL_BARS:GetIterator() do
                bar.AutoHideCondition = nil
            end

            for i, bar in CURRENT_BARS:GetIterator() do
                bar.AutoHideCondition = nil
            end

            NextEvent(event == "ACTIONBAR_SHOWGRID" and "ACTIONBAR_HIDEGRID" or "SCORPIO_ACTION_BUTTON_KEY_BINDING_STOP")
            NoCombat()


            -- enable auto hide
            for i, bar in GLOBAL_BARS:GetIterator() do
                bar.AutoHideCondition = _SVDB.ActionBars[i].Style.autoHideCondition or nil
            end

            local charSV        = CharSV()

            for i, bar in CURRENT_BARS:GetIterator() do
                bar.AutoHideCondition = charSV.ActionBars[i].Style.autoHideCondition or nil
            end
        end
    end
end


-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------
__SlashCmd__ ("/shd",          "unlock", _Locale["Unlock the action bars"])
__SlashCmd__ ("/shadow",       "unlock", _Locale["Unlock the action bars"])
__SlashCmd__ ("/shadowdancer", "unlock", _Locale["Unlock the action bars"])
function UnlockBars()
    if InCombatLockdown() or UNLOCK_BARS then return end

    UNLOCK_BARS                 = true

    Next(function()
        while UNLOCK_BARS and not InCombatLockdown() do Next() end
        return UNLOCK_BARS and LockBars()
    end)

    ShadowBar.EditMode          = true

    for i, bar in GLOBAL_BARS:GetIterator() do
        bar:SetMovable(true)

        bar.Mask                = RECYCLE_MASKS()
        bar.Mask:SetParent(bar)
        bar.Mask:Show()
    end

    for i, bar in CURRENT_BARS:GetIterator() do
        bar:SetMovable(true)

        bar.Mask                = RECYCLE_MASKS()
        bar.Mask:SetParent(bar)
        bar.Mask:Show()
    end

    FireSystemEvent("SHADOWDANCER_UNLOCK")
end

__SlashCmd__ ("/shd",          "lock", _Locale["Lock the action bars"])
__SlashCmd__ ("/shadow",       "lock", _Locale["Lock the action bars"])
__SlashCmd__ ("/shadowdancer", "lock", _Locale["Lock the action bars"])
function LockBars()
    if not UNLOCK_BARS then return end
    UNLOCK_BARS                 = false

    NoCombat(function()
        for i, bar in GLOBAL_BARS:GetIterator() do
            bar:SetMovable(false)
        end

        for i, bar in CURRENT_BARS:GetIterator() do
            bar:SetMovable(false)
        end
    end)

    ShadowBar.EditMode          = false

    for i, bar in GLOBAL_BARS:GetIterator() do
        RECYCLE_MASKS(bar.Mask)
        bar.Mask                = nil
    end

    for i, bar in CURRENT_BARS:GetIterator() do
        RECYCLE_MASKS(bar.Mask)
        bar.Mask                = nil
    end

    FireSystemEvent("SHADOWDANCER_LOCK")
end

__SlashCmd__ ("/shd",          "bind", _Locale["Start binding key"])
__SlashCmd__ ("/shadow",       "bind", _Locale["Start binding key"])
__SlashCmd__ ("/shadowdancer", "bind", _Locale["Start binding key"])
function BindKeys()
    if InCombatLockdown() then return end
    SecureActionButton.StartKeyBinding()
end

__SlashCmd__ ("/shd",          "auto", _Locale["Start binding auto gen rule"])
__SlashCmd__ ("/shadow",       "auto", _Locale["Start binding auto gen rule"])
__SlashCmd__ ("/shadowdancer", "auto", _Locale["Start binding auto gen rule"])
__Async__(true)
function BindAutoGen()
    LockBars()

    local current
    local mask              = RECYCLE_MASKS()
    mask.InAutoGenBindMode  = true

    while not InCombatLockdown() and mask.InAutoGenBindMode do
        local button        = GetMouseFocus()

        if button then
            button          = GetProxyUI(button)

            if Class.IsObjectType(button, DancerButton) then
                mask:SetParent(button)
                mask:Show()

                while button:IsMouseOver() and mask.InAutoGenBindMode do
                    Next()
                end

                mask:Hide()
            end
        end

        Next()
    end

    if mask.InAutoGenBindMode then
        mask.InAutoGenBindMode = nil
        RECYCLE_MASKS(mask)
    end
end

__SlashCmd__ ("/shd",          "custom", _Locale["Start binding custom name and texture"])
__SlashCmd__ ("/shadow",       "custom", _Locale["Start binding custom name and texture"])
__SlashCmd__ ("/shadowdancer", "custom", _Locale["Start binding custom name and texture"])
__Async__(true)
function BindCustomAction()
    LockBars()

    local current
    local mask              = RECYCLE_MASKS()
    mask.InCustomBindMode   = true

    while not InCombatLockdown() and mask.InCustomBindMode do
        local button        = GetMouseFocus()

        if button then
            button          = GetProxyUI(button)

            if Class.IsObjectType(button, DancerButton) and button.IsCustomable then
                mask:SetParent(button)
                mask:Show()

                while button:IsMouseOver() and mask.InCustomBindMode do
                    Next()
                end

                mask:Hide()
            end
        end

        Next()
    end

    if mask.InCustomBindMode then
        mask.InCustomBindMode = nil
        RECYCLE_MASKS(mask)
    end
end

__SlashCmd__ ("/shd",          "swap", _Locale["Change the swap mode of the flyout bar"])
__SlashCmd__ ("/shadow",       "swap", _Locale["Change the swap mode of the flyout bar"])
__SlashCmd__ ("/shadowdancer", "swap", _Locale["Change the swap mode of the flyout bar"])
__Async__(true)
function SwapBarMode()
    LockBars()

    local current
    local mask              = RECYCLE_MASKS()
    mask.InSwapBarMode      = true

    while not InCombatLockdown() and mask.InSwapBarMode do
        local button        = GetMouseFocus()

        if button then
            button          = GetProxyUI(button)

            if Class.IsObjectType(button, DancerButton) and button.IsSwappable then
                mask:SetParent(button)
                mask:Show()

                while button:IsMouseOver() and mask.InSwapBarMode do
                    Next()
                end

                mask:Hide()
            end
        end

        Next()
    end

    if mask.InSwapBarMode then
        mask.InSwapBarMode = nil
        RECYCLE_MASKS(mask)
    end
end

-----------------------------------------------------------
-- Helpers
-----------------------------------------------------------
function OnStopMoving(self)
    NoCombat(function(self)
        local minrange, anchors = 9999999

        for _, loc in ipairs(ANCHORS) do
            local new           = self:GetLocation(loc)
            local range         = sqrt( new[1].x ^ 2 + new[1].y ^ 2 )
            if range < minrange then
                minrange        = range
                anchors         = new
            end
        end

        self:SetLocation(anchors)
    end, self:GetParent())
end

function OpenMaskMenu(self, button)
    if self.InAutoGenBindMode then
        self.InAutoGenBindMode  = nil

        if button == "LeftButton" then
            ShowAutoGenBind(self:GetParent())
        end

        return RECYCLE_MASKS(self)
    elseif self.InCustomBindMode then
        self.InCustomBindMode   = nil

        if button == "LeftButton" then
            ShowCustomBind(self:GetParent())
        end

        return RECYCLE_MASKS(self)
    elseif self.InSwapBarMode then
        self.InSwapBarMode      = nil

        local bar               = self:GetParent().FlyoutBar
        if not bar then return end

        return ShowDropDownMenu {
            check               = {
                get             = function() return bar.SwapMode end,
                set             = function(value) bar.SwapMode = value end,
            },

            {
                text            = _Locale["No action swap"],
                checkvalue      = SwapMode.None,
            },
            {
                text            = _Locale["Swap the action to root button"],
                checkvalue      = SwapMode.ToRoot,
            },
            {
                text            = _Locale["Use the bar as the action queue"],
                checkvalue      = SwapMode.Queue
            },
        }
    end

    local bar                   = self:GetParent()
    if not (bar and button == "RightButton") then return end

    local menu                  = {
        {
            text                = _Locale["Lock Bar"],
            click               = LockBars,
        },
        {
            text                = _Locale["Add Bar"],
            click               = function() return Confirm(_Locale["Do you want create a new action bar?"]) and AddBar(bar) end,
        },
        {
            text                = _Locale["Start Key Binding"],
            click               = function()
                LockBars()
                return SecureActionButton.StartKeyBinding()
            end
        },
        {
            text                = _Locale["Start Swap Mode Binding"],
            click               = SwapBarMode,
        },
        {
            text                = _Locale["Button Operation"],
            submenu             = {
                {
                    text        = _Locale["Custom Action"],
                    click       = BindCustomAction,
                },
                {
                    text        = _Locale["Auto Gen"],
                    submenu     = {
                        {
                            text    = _Locale["Start Binding"],
                            click   = BindAutoGen,
                        },
                        {
                            text    = _Locale["Black List"],
                            click   = function()
                                BlackListDlg:Show()
                            end
                        },
                    },
                },
            },
        },
        {
            text                = _Locale["Global Settings"],
            submenu             = {
                {
                    text                = _Locale["Flyout Popup Duration"] .. " - " .. _SVDB.PopupDuration,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the flyout popup duration"], 0.10, 2, 0.01, _SVDB.PopupDuration)
                        if value then
                            _SVDB.PopupDuration = value
                            ShadowBar.PopupDuration = value
                        end
                    end
                },
                {
                    text                = _Locale["Lock Action"],
                    check               = {
                        get             = function() return not CharSV().Draggable end,
                        set             = function(value)
                            value       = not value
                            CharSV().Draggable = value
                            SecureActionButton.Draggable["AshToAsh"] = value
                        end,
                    }
                },
                {
                    text                = _Locale["Use Mouse Down"],
                    check               = {
                        get             = function() return CharSV().UseMouseDown end,
                        set             = function(value)
                            CharSV().UseMouseDown = value
                            SecureActionButton.UseMouseDown["AshToAsh"] = value
                        end,
                    }
                },
                {
                    text                = _Locale["Hide original action bar"],
                    check               = {
                        get             = function() return _SVDB.HideOriginalBar end,
                        set             = function(value)
                            _SVDB.HideOriginalBar = value
                            UpdateOriginalBar()
                        end,
                    },
                },
            }
        },
        {
            text                = _Locale["Action Bar Settings"],
            submenu             = {
                {
                    text                = _Locale["Global Bar"],
                    check               = {
                        get             = function() return GLOBAL_BARS:Contains(bar) end,
                        set             = function(value)
                            if value then
                                if not GLOBAL_BARS:Contains(bar)  then GLOBAL_BARS:Insert(bar) end
                                if CURRENT_BARS:Contains(bar)     then CURRENT_BARS:Remove(bar) end
                            else
                                if GLOBAL_BARS:Contains(bar)      then GLOBAL_BARS:Remove(bar) end
                                if not CURRENT_BARS:Contains(bar) then CURRENT_BARS:Insert(bar) end
                            end
                        end
                    }
                },
                {
                    text                = _Locale["Action Bar Map"],
                    submenu             = GetActionBarMapConfig(bar),
                },
                {
                    text                = _Locale["Column Count"] .. " - " .. bar.ColumnCount,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the column count"], 1, 12, 1, bar.ColumnCount)
                        if value then
                            bar.ColumnCount = value
                            bar.RowCount    = math.min(bar.RowCount, math.floor(12 / value))
                            bar.Count       = math.min(12, bar.ColumnCount * bar.RowCount)
                        end
                    end
                },
                {
                    text                = _Locale["Row Count"] .. " - " .. bar.RowCount,
                    disabled            = math.floor(12 / bar.ColumnCount) == 1,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the row count"], 1, math.floor(12 / bar.ColumnCount), 1, bar.RowCount)
                        if value then
                            bar.RowCount= value
                            bar.ColumnCount = math.min(bar.ColumnCount, math.floor(12 / value))
                            bar.Count   = math.min(12, bar.ColumnCount * bar.RowCount)
                        end
                    end
                },
                {
                    text                = _Locale["Scale"] .. " - " .. ("%.2f"):format(bar:GetScale()),
                    click               = function()
                        local value     = PickRange(_Locale["Choose the scale"], 0.3, 3, 0.1, bar:GetScale())
                        if value then bar:SetScale(value) end
                    end
                },
                {
                    text                = _Locale["Horizontal Spacing"] .. " - " .. bar.HSpacing,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the horizontal spacing"], 0, 50, 1, bar.HSpacing)
                        if value then bar:SetSpacing(value, bar.VSpacing) end
                    end
                },
                {
                    text                = _Locale["Vertical Spacing"] .. " - " .. bar.VSpacing,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the vertical spacing"], 0, 50, 1, bar.VSpacing)
                        if value then bar:SetSpacing(bar.HSpacing, value) end
                    end
                },
                {
                    text                = _Locale["Always Show Grid"],
                    check               = {
                        get             = function() return bar.GridAlwaysShow end,
                        set             = function(val) bar.GridAlwaysShow = val end,
                    }
                },
                {
                    text                = _Locale["Auto Fade"],
                    check               = {
                        get             = function() return bar.AutoFadeOut end,
                        set             = function(val) bar.AutoFadeOut = val end,
                    }
                },
                {
                    text                = _Locale["Fade Alpha"] .. " - " .. bar.FadeAlpha,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the final fade alpha"], 0, 1, 0.01, bar.FadeAlpha)
                        if value then bar.FadeAlpha = value end
                    end
                },
                {
                    text                = _Locale["Auto Hide"],
                    submenu             = GetAutoHideMenu(bar),
                },
                {
                    text                = _Locale["Disable Auto Flyout"],
                    check               = {
                        get             = function() return bar.NoAutoFlyout end,
                        set             = function(val) bar.NoAutoFlyout = val end,
                    }
                },
            },
        },
        {
            text                = _Locale["Import/Export"],
            submenu             = {
                {
                    text        = _Locale["Export"],
                    click       = ExportSettings,
                },
                {
                    text        = _Locale["Export Current Bar"],
                    click       = function() ExportSettings(bar) end,
                },
                {
                    text        = _Locale["Import"],
                    click       = ImportSettings,
                },
            },
        },
    }

    FireSystemEvent("SHADOWDANCER_OPEN_MENU", bar, menu)

    tinsert(menu, { separator   = true} )
    tinsert(menu,
        {
            text                = _Locale["Delete Bar"],
            click               = function() return Confirm(_Locale["Do you want delete the action bar?"]) and DeleteBar(bar) end,
        }
    )

    ShowDropDownMenu(menu)
end

function GetActionBarMapConfig(self)
    local config                = XDictionary(Enum.GetEnumValues(ActionBarMap)).Values:ToList():Sort():Map(function(v) return { text = _Locale[ActionBarMap(v)], checkvalue = v } end):ToTable()
    config.check                = {
        get                     = function()
            return self.ActionBarMap
        end,
        set                     = function(value)
            self.ActionBarMap = value
            if value == ActionBarMap.PET or value == ActionBarMap.STANCEBAR then
                self.GridAlwaysShow = false
            end
        end
    }
    return config
end

function GetAutoHideMenu(self)
    local config                = {
        {
            text                = _Locale["Add Macro Condition"],
            click               = function()
                local new       = PickMacroCondition(_Locale["Please select the macro condition"])
                if new then
                    if self.AutoHideCondition then
                        for _, macro in ipairs(self.AutoHideCondition) do
                            if macro == new then return end
                        end
                    end

                    if self.AutoHideCondition then
                        tinsert(self.AutoHideCondition, new)
                        self.AutoHideCondition = Toolset.clone(self.AutoHideCondition)
                    else
                        self.AutoHideCondition = { new }
                    end
                end
            end,
        },
        {
            separator           = true,
        },
    }

    if self.AutoHideCondition then
        for i, macro in ipairs(self.AutoHideCondition) do
            table.insert(config,    {
                text                = macro,
                click               = function()
                    if Confirm(_Locale["Do you want delete the macro condition"]) then
                        table.remove(self.AutoHideCondition, i)
                        self.AutoHideCondition = Toolset.clone(self.AutoHideCondition)
                    end
                end,
            })
        end
    end

    return config
end

function AddBar(self)
    local bar                   = ShadowBar.BarPool()

    bar:SetProfile              {
        Style                   = {
            location            = { Anchor("CENTER") },
            scale               = self:GetScale(),
            actionBarMap        = ActionBarMap.NONE,
            gridAlwaysShow      = self.GridAlwaysShow,

            rowCount            = 1,
            columnCount         = 12,
            count               = 12,
            elementWidth        = self.ElementWidth,
            elementHeight       = self.ElementHeight,
            orientation         = "HORIZONTAL",
            leftToRight         = true,
            topToBottom         = true,
            hSpacing            = self.HSpacing,
            vSpacing            = self.VSpacing,
        },
        Buttons                 = {},
    }

    CURRENT_BARS:Insert(bar)

    bar:SetMovable(true)
    bar:SetResizable(false)

    bar.Mask                    = RECYCLE_MASKS()
    bar.Mask:SetParent(bar)
    bar.Mask:Show()
end

function DeleteBar(self)
    if self.Mask then
        RECYCLE_MASKS(self.Mask)
        self.Mask               = nil
    end

    CURRENT_BARS:Remove(self)
    return ShadowBar.BarPool(self)
end

function ExportSettings(bar)
    LockBars()

    Style[ExportGuide].Header.text = _Locale["Export"]

    if not bar then
        chkGlobalBars:Show()
        chkCurrentBars:Show()
        chkClearAllBars:Hide()
        confirmButton:Show()
        result:Hide()

        chkGlobalBars:Enable()
        chkCurrentBars:Enable()
        chkClearAllBars:Disable()
        confirmButton:Enable()

        chkGlobalBars:SetChecked(true)
        chkCurrentBars:SetChecked(true)
        chkClearAllBars:SetChecked(false)
    else
        chkGlobalBars:Hide()
        chkCurrentBars:Hide()
        chkClearAllBars:Hide()
        confirmButton:Show()
        result:Show()
        result:SetText(Base64.Encode(Deflate.Encode(Toolset.tostring{ ActionBar = bar:GetProfile(true) })))
    end

    ExportGuide:Show()
    ExportGuide.ExportMode      = true
    Style[confirmButton].text   = _Locale["Next"]
end

function ImportSettings()
    LockBars()

    Style[ExportGuide].Header.text = _Locale["Import"]
    chkGlobalBars:Hide()
    chkCurrentBars:Hide()
    chkClearAllBars:Hide()
    confirmButton:Show()
    result:Show()

    ExportGuide:Show()
    ExportGuide.ExportMode      = false
    Style[confirmButton].text   = _Locale["Next"]
end

function loadImportSettings()
    return Toolset.parsestring(Deflate.Decode(Base64.Decode(result:GetText())))
end

-----------------------------------------------------------
-- Client Helpers
-----------------------------------------------------------
if Scorpio.IsRetail then
    function CharSV(spec)
        return spec and _SVDB.Char.Specs[spec] or _SVDB.Char.Spec
    end

    function UpdateOriginalBar()
        if _SVDB.HideOriginalBar then
            if MicroButtonAndBagsBar:GetParent() == MainMenuBar then
                MainMenuBar:SetAlpha(0)
                MainMenuBar:SetMovable(true)
                MainMenuBar:SetUserPlaced(true)
                MainMenuBar:ClearAllPoints()
                MainMenuBar:SetPoint("RIGHT", UIParent, "LEFT", -1000, 0)

                MicroButtonAndBagsBar:SetParent(HIDDEN_FRAME)

                PetActionBarFrame:UnregisterAllEvents()
            end
        else
            if MicroButtonAndBagsBar:GetParent() == HIDDEN_FRAME then
                MainMenuBar:SetAlpha(1)
                MainMenuBar:ClearAllPoints()
                MainMenuBar:SetPoint("BOTTOM")
                MainMenuBar:SetUserPlaced(false)
                MainMenuBar:SetMovable(false)

                MicroButtonAndBagsBar:SetParent(MainMenuBar)

                PetActionBarFrame:RegisterEvent("PLAYER_CONTROL_LOST")
                PetActionBarFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
                PetActionBarFrame:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
                PetActionBarFrame:RegisterEvent("UNIT_PET")
                PetActionBarFrame:RegisterEvent("UNIT_FLAGS")
                PetActionBarFrame:RegisterEvent("PET_BAR_UPDATE")
                PetActionBarFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
                PetActionBarFrame:RegisterEvent("PET_BAR_SHOWGRID")
                PetActionBarFrame:RegisterEvent("PET_BAR_HIDEGRID")
                PetActionBarFrame:RegisterEvent("PET_BAR_UPDATE_USABLE")
                PetActionBarFrame:RegisterEvent("PET_UI_UPDATE")
                PetActionBarFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
                PetActionBarFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
                PetActionBarFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
                PetActionBarFrame:RegisterUnitEvent("UNIT_AURA", "pet")
            end
        end
    end
else
    function CharSV()
        return _SVDB.Char
    end

    function UpdateOriginalBar()
        if _SVDB.HideOriginalBar then
            if MainMenuBar:GetParent() == UIParent then
                MainMenuBar:SetParent(HIDDEN_FRAME)
            end
        else
            if MainMenuBar:GetParent() == HIDDEN_FRAME then
                MainMenuBar:SetParent(UIParent)
            end
        end
    end
end

-----------------------------------------------------------
-- Config UI
-----------------------------------------------------------
BlackListDlg                    = Dialog("ShadowDancer_Black_List")
BlackListDlg:Hide()

Viewer                          = HtmlViewer("Viewer", BlackListDlg)

TEMPLATE_BLACKLIST              = TemplateString[[
    <html>
        <body>
            @for id in pairs(target) do
            <p><a href="@id">[@GetItemInfo(id)]</a></p>
            @end
        </body>
    </html>
]]


Style[BlackListDlg]             = {
    Header                      = { Text = _Locale["Auto Gen Black List"] },
    Size                        = Size(300, 400),
    clampedToScreen             = true,
    minResize                   = Size(100, 100),

    Viewer                      = {
        location                = { Anchor("TOPLEFT", 24, -32), Anchor("BOTTOMRIGHT", -48, 48) },
    },
}

function BlackListDlg:OnShow()
    Viewer:SetText(TEMPLATE_BLACKLIST{ target = _AutoGenBlackList })
end

function Viewer:OnHyperlinkClick(id)
    id                          = tonumber(id) or id
    _AutoGenBlackList[id]       = nil

    Viewer:SetText(TEMPLATE_BLACKLIST{ target = _AutoGenBlackList })

    FireSystemEvent("BAG_UPDATE_DELAYED")
end

function Viewer:OnHyperlinkEnter(id)
    id                          = tonumber(id) or id
    if id then
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(select(2, GetItemInfo(id)))
        GameTooltip:Show()
    end
end

function Viewer:OnHyperlinkLeave(id)
    GameTooltip:Hide()
end


-----------------------------------------------------------
-- Export/Import UI
-----------------------------------------------------------
ExportGuide                     = Dialog("ShadowDancer_Export_Guide")
ExportGuide:Hide()

chkGlobalBars                   = UICheckButton("GlobalBars", ExportGuide)
chkCurrentBars                  = UICheckButton("CurrentBar", ExportGuide)
chkClearAllBars                 = UICheckButton("ClearAllBars", ExportGuide)
confirmButton                   = UIPanelButton("Confirm",    ExportGuide)
result                          = InputScrollFrame("Result",  ExportGuide)

Style[ExportGuide]              = {
    Header                      = { Text = "ShadowDancer" },
    Size                        = Size(400, 400),
    clampedToScreen             = true,
    minResize                   = Size(200, 200),

    GlobalBars                  = {
        location                = { Anchor("TOPLEFT", 24, -32) },
        label                   = { text = _Locale["Global Action Bars"] },
    },
    CurrentBar                  = {
        location                = { Anchor("TOP", 0, -16, "GlobalBars", "BOTTOM") },
        label                   = { text = _Locale["Current Action Bars"] },
    },
    ClearAllBars                = {
        location                = { Anchor("TOP", 0, -16, "CurrentBar", "BOTTOM") },
        label                   = { text = _Locale["Clear Existed Bars"] },
    },

    Result                      = {
        maxLetters              = 0,
        location                = { Anchor("TOPLEFT", 24, -32), Anchor("BOTTOMRIGHT", -24, 60) },
    },

    Confirm                     = {
        location                = { Anchor("BOTTOMLEFT", 24, 16 ) },
        text                    = _Locale["Next"],
    },
}

function confirmButton:OnClick()
    if InCombatLockdown() then
        ExportGuide.TempSettings= nil
        ExportGuide:Hide()
        return
    end

    if ExportGuide.ExportMode then
        Style[confirmButton].text       = _Locale["Close"]

        if chkGlobalBars:IsShown() then
            local settings              = {}
            if chkGlobalBars:GetChecked() then
                settings.GlobalBars     = GLOBAL_BARS:Map(ShadowBar.GetProfile):ToTable()
            end
            if chkCurrentBars:GetChecked() then
                settings.CurrentBars    = CURRENT_BARS:Map(function(self) return self:GetProfile(true) end):ToTable()
            end

            chkGlobalBars:Hide()
            chkCurrentBars:Hide()
            chkClearAllBars:Hide()
            confirmButton:Show()

            result:SetText(Base64.Encode(Deflate.Encode(Toolset.tostring(settings)), true))
            result:Show()
        else
            ExportGuide:Hide()
        end
    else
        if chkGlobalBars:IsShown() then
            local settings              = ExportGuide.TempSettings
            if chkGlobalBars:GetChecked() and settings.GlobalBars and #settings.GlobalBars > 0 then
                if chkClearAllBars:GetChecked() then
                    for i = 1, #settings.GlobalBars do
                        local bar       = GLOBAL_BARS[i]
                        if not bar then
                            bar         = ShadowBar.BarPool()
                            GLOBAL_BARS:Insert(bar)
                        end

                        bar:SetProfile(settings.GlobalBars[i])
                    end

                    for i = #GLOBAL_BARS, #settings.GlobalBars + 1, -1 do
                        ShadowBar.BarPool(GLOBAL_BARS:RemoveByIndex(i))
                    end
                else
                    for i = 1, #settings.GlobalBars do
                        local bar       = ShadowBar.BarPool()
                        GLOBAL_BARS:Insert(bar)
                        bar:SetProfile(settings.GlobalBars[i])
                    end
                end
            end

            if chkCurrentBars:GetChecked() and settings.CurrentBars and #settings.CurrentBars > 0  then
                if chkClearAllBars:GetChecked() then
                    for i = 1, #settings.CurrentBars do
                        local bar       = CURRENT_BARS[i]
                        if not bar then
                            bar         = ShadowBar.BarPool()
                            CURRENT_BARS:Insert(bar)
                        end

                        bar:SetProfile(settings.CurrentBars[i])
                    end

                    for i = #CURRENT_BARS, #settings.CurrentBars + 1, -1 do
                        ShadowBar.BarPool(CURRENT_BARS:RemoveByIndex(i))
                    end
                else
                    for i = 1, #settings.CurrentBars do
                        local bar       = ShadowBar.BarPool()
                        CURRENT_BARS:Insert(bar)
                        bar:SetProfile(settings.CurrentBars[i])
                    end
                end
            end

            ExportGuide.TempSettings    = nil
            ExportGuide:Hide()
        else
            local ok, settings          = pcall(loadImportSettings)
            if ok and type(settings) == "table" then
                if settings.ActionBar then
                    local bar   = ShadowBar.BarPool()
                    CURRENT_BARS:Insert(bar)
                    bar:SetProfile(settings.ActionBar)

                    ExportGuide.TempSettings = nil
                    ExportGuide:Hide()

                    return
                end

                chkGlobalBars:Show()
                chkCurrentBars:Show()
                chkClearAllBars:Show()
                confirmButton:Show()
                result:Hide()

                if settings.GlobalBars then
                    chkGlobalBars:Enable()
                    chkGlobalBars:SetChecked(true)
                else
                    chkGlobalBars:Disable()
                    chkGlobalBars:SetChecked(false)
                end

                if settings.CurrentBars then
                    chkCurrentBars:Enable()
                    chkCurrentBars:SetChecked(true)
                else
                    chkCurrentBars:Disable()
                    chkCurrentBars:SetChecked(false)
                end

                chkClearAllBars:Enable()
                chkClearAllBars:SetChecked(false)

                ExportGuide.TempSettings = settings
            end
        end
    end
end


-----------------------------------------------------------
-- Auto Gen Binding UI
-----------------------------------------------------------
BindingGuide                    = Dialog("ShadowDancer_AutoGen_Guide")
BindingGuide:Hide()

cboAutoGenType                  = ComboBox("AutoGenType",  BindingGuide)
cboItemClass                    = ComboBox("ItemClass",    BindingGuide)
cboSubClass                     = ComboBox("SubClass",     BindingGuide)
confirmAutoGen                  = UIPanelButton("Confirm", BindingGuide)

Style[BindingGuide]             = {
    Header                      = { Text = _Locale["Auto Gen Binding"] },
    Size                        = Size(400, 400),
    clampedToScreen             = true,
    minResize                   = Size(200, 200),

    AutoGenType                 = {
        location                = { Anchor("TOPLEFT", 140, -48) },
        size                    = Size(200, 28),
        label                   = {
            text                = _Locale["Auto Gen Type"],
            location            = { Anchor("RIGHT", -24, 0, nil, "LEFT") },
        },
    },
    ItemClass                   = {
        location                = { Anchor("TOPLEFT", 0, -16, "AutoGenType", "BOTTOMLEFT") },
        size                    = Size(200, 28),
        label                   = {
            text                = _Locale["Item Class"],
            location            = { Anchor("RIGHT", -24, 0, nil, "LEFT") },
        },
    },
    SubClass                    = {
        location                = { Anchor("TOPLEFT", 0, -16, "ItemClass", "BOTTOMLEFT") },
        size                    = Size(200, 28),
        label                   = {
            text                = _Locale["Item Sub Class"],
            location            = { Anchor("RIGHT", -24, 0, nil, "LEFT") },
        },
    },

    Confirm                     = {
        location                = { Anchor("BOTTOMLEFT", 24, 16 ) },
        text                    = _Locale["Confirm"],
    },
}

function ShowAutoGenBind(self)
    BindingGuide.Button         = self
    BindingGuide:Show()

    local rule                  = self.AutoGenRule
    if rule then
        cboAutoGenType.SelectedValue = rule.type
        cboAutoGenType:OnSelectChanged(rule.type)

        if rule.type == AutoGenRuleType.Item then
            cboItemClass.SelectedValue = rule.class
            cboItemClass:OnSelectChanged(rule.class)

            cboSubClass.SelectedValue  = rule.subclass or 100
        end
    else
        cboAutoGenType.SelectedValue = 0
        cboAutoGenType:OnSelectChanged(0)
    end
end

function BindingGuide:OnShow()
    self.OnShow                 = nil

    cboAutoGenType:ClearItems()
    cboAutoGenType.Items[0]     = _Locale["NONE"]

    for _, v in XDictionary(Enum.GetEnumValues(AutoGenRuleType)).Values:ToList():Sort():GetIterator() do
        cboAutoGenType.Items[v] = _Locale[AutoGenRuleType(v)]
    end

    cboItemClass:Hide()
    cboSubClass:Hide()

    cboItemClass:ClearItems()
    cboSubClass:ClearItems()

    for i = 0, #_AuctionItemClasses do
        cboItemClass.Items[i]   = _AuctionItemClasses[i].name
    end
end

function cboAutoGenType:OnSelectChanged(value)
    if value == AutoGenRuleType.Item then
        cboItemClass:Show()
        cboSubClass:Show()
    else
        cboItemClass:Hide()
        cboSubClass:Hide()
    end
end

function cboItemClass:OnSelectChanged(value)
    cboSubClass:ClearItems()

    cboSubClass.Items[100]      = _Locale["All"]

    if not _AuctionItemClasses[value] then return end

    for i, subcls in ipairs(_AuctionItemClasses[value]) do
        cboSubClass.Items[i]    = subcls
    end
end

function confirmAutoGen:OnClick()
    BindingGuide:Hide()

    if not BindingGuide.Button then return end

    if cboAutoGenType.SelectedValue == 0 then
        BindingGuide.Button.AutoGenRule = nil
    else
        BindingGuide.Button.AutoGenRule = {
            type                = cboAutoGenType.SelectedValue,
            class               = cboAutoGenType.SelectedValue == AutoGenRuleType.Item and cboItemClass.SelectedValue or nil,
            subclass            = cboAutoGenType.SelectedValue == AutoGenRuleType.Item and cboSubClass.SelectedValue ~= 100 and cboSubClass.SelectedValue or nil,
        }
    end

    BindingGuide.Button         = nil
end

-----------------------------------------------------------
-- Custom Action Bind
-----------------------------------------------------------
local MACRO_ICON_FILENAMES

CustomBindGuide                 = Dialog("ShadowDancer_CustomBind_Guide")
CustomBindGuide:Hide()

inputCustomName                 = InputBox("Name", CustomBindGuide)
customIcon                      = Button("Icon", CustomBindGuide)
inputMacroText                  = InputScrollFrame("Macro", CustomBindGuide)
iconPanel                       = ElementPanel("Panel", CustomBindGuide)
confirmCustom                   = UIPanelButton("Confirm", CustomBindGuide)
cancelCustom                    = UIPanelButton("Cancel", CustomBindGuide)
btnNextPage                     = UIPanelButton("Next", CustomBindGuide)
btnPrevPage                     = UIPanelButton("Prev", CustomBindGuide)

Style[CustomBindGuide]          = {
    Header                      = { text = _Locale["Custom Name & Icon Bind"] },
    Size                        = Size(460, 500),
    clampedToScreen             = true,
    resizable                   = false,
    Name                        = {
        location                = { Anchor("TOPLEFT", 140, -30) },
        size                    = Size(200, 28),
        label                   = {
            text                = _Locale["Custom Name"],
            location            = { Anchor("LEFT", -120, 0 )},
        }
    },
    Icon                        = {
        location                = { Anchor("LEFT", 8, 0, "Name", "RIGHT")},
        size                    = Size(36, 36),
        NormalTexture           = { setAllPoints = true },
    },
    Macro                       = {
        label                   = {
            location            = { Anchor("BOTTOMLEFT", 0, 4, nil, "TOPLEFT") },
            text                = _Locale["Macro Text"],
        },
        location                = { Anchor("TOPLEFT", 0, -32, "Name.label", "BOTTOMLEFT"), Anchor("RIGHT", -36, 0) },
        height                  = 80,
        maxBytes                = 255,
    },
    Panel                       = {
        enableMouseWheel        = true,
        location                = { Anchor("TOPLEFT", 0, -8, "Macro", "BOTTOMLEFT") },
        elementWidth            = 36,
        elementHeight           = 36,
        columnCount             = 12,
        rowCount                = 8,
        elementType             = Button,
    },
    Confirm                     = {
        location                = { Anchor("BOTTOMLEFT", 24, 16 ) },
        text                    = _Locale["Confirm"],
    },
    Cancel                      = {
        location                = { Anchor("LEFT", 8, 0, "Confirm", "RIGHT") },
        text                    = _Locale["Cancel"],
    },
    Next                        = {
        location                = { Anchor("BOTTOMRIGHT", -24, 16 ) },
        text                    = _Locale["Next Page"],
    },
    Prev                        = {
        location                = { Anchor("RIGHT", -8, 0, "Next", "LEFT") },
        text                    = _Locale["Prev Page"],
    },
}

function RefreshPlayerSpellIconInfo()
    if ( MACRO_ICON_FILENAMES ) then
        return;
    end

    -- We need to avoid adding duplicate spellIDs from the spellbook tabs for your other specs.
    local activeIcons = {};

    for i = 1, GetNumSpellTabs() do
        local tab, tabTex, offset, numSpells, _ = GetSpellTabInfo(i);
        offset = offset + 1;
        local tabEnd = offset + numSpells;
        for j = offset, tabEnd - 1 do
            --to get spell info by slot, you have to pass in a pet argument
            local spellType, ID = GetSpellBookItemInfo(j, "player");
            if (spellType ~= "FUTURESPELL") then
                local fileID = GetSpellBookItemTexture(j, "player");
                if (fileID) then
                    activeIcons[fileID] = true;
                end
            end
            if (spellType == "FLYOUT") then
                local _, _, numSlots, isKnown = GetFlyoutInfo(ID);
                if (isKnown and numSlots > 0) then
                    for k = 1, numSlots do
                        local spellID, overrideSpellID, isKnown = GetFlyoutSlotInfo(ID, k)
                        if (isKnown) then
                            local fileID = GetSpellTexture(spellID);
                            if (fileID) then
                                activeIcons[fileID] = true;
                            end
                        end
                    end
                end
            end
        end
    end

    MACRO_ICON_FILENAMES = { "INV_MISC_QUESTIONMARK" };
    for fileDataID in pairs(activeIcons) do
        MACRO_ICON_FILENAMES[#MACRO_ICON_FILENAMES + 1] = fileDataID;
    end

    GetLooseMacroIcons( MACRO_ICON_FILENAMES );
    GetLooseMacroItemIcons( MACRO_ICON_FILENAMES );
    GetMacroIcons( MACRO_ICON_FILENAMES );
    GetMacroItemIcons( MACRO_ICON_FILENAMES );

    Next()
end

local onIconClick               = function(self)
    customIcon.Icon             = self.Icon
    customIcon:GetPropertyChild("NormalTexture"):SetTexture(self.Icon)
end

function customIcon:OnClick()
    customIcon.Icon             = nil
    customIcon:GetPropertyChild("NormalTexture"):SetTexture(nil)
end

function LoadIconPage(page)
    iconPanel.Page              = page

    local max                   = iconPanel.MaxCount

    for i = 1, iconPanel.MaxCount do
        local icon              = MACRO_ICON_FILENAMES[(page - 1) * max + i]

        icon                    = tonumber(icon) or icon
        if type(icon) ~= "number" then
            icon                = "INTERFACE\\ICONS\\"..icon
        end

        iconPanel.Elements[i].Icon = icon
        iconPanel.Elements[i]:SetNormalTexture(icon)
        iconPanel.Elements[i].OnClick = onIconClick
    end

    if page > 1 then
        btnPrevPage:Enable()
    else
        btnPrevPage:Disable()
    end

    if page * max >= #MACRO_ICON_FILENAMES then
        btnNextPage:Disable()
    else
        btnNextPage:Enable()
    end
end

function confirmCustom:OnClick()
    if CustomBindGuide.Button then
        local name              = inputCustomName:GetText()
        local macro             = inputMacroText:GetText()
        local icon              = customIcon.Icon

        if name and name ~= "" or macro and macro ~= "" or icon then
            CustomBindGuide.Button:SetAction(macro and macro ~= "" and "macrotext" or "custom", macro and macro ~= "" and macro or Toolset.fakefunc)
            CustomBindGuide.Button.CustomText = name and name ~= "" and name or nil
            CustomBindGuide.Button.CustomTexture = icon
        else
            CustomBindGuide.Button:SetAction(nil)
        end
    end

    CustomBindGuide.Button      = nil
    CustomBindGuide:Hide()
end

function cancelCustom:OnClick()
    CustomBindGuide.Button      = nil
    CustomBindGuide:Hide()
end

function btnNextPage:OnClick()
    LoadIconPage(iconPanel.Page + 1)
end

function btnPrevPage:OnClick()
    LoadIconPage(iconPanel.Page - 1)
end

function iconPanel:OnMouseWheel(delta)
    if delta > 0 then
        if iconPanel.Page > 1 then
            LoadIconPage(iconPanel.Page - 1)
        end
    else
        if iconPanel.Page * iconPanel.MaxCount < #MACRO_ICON_FILENAMES then
            LoadIconPage(iconPanel.Page + 1)
        end
    end
end

__Async__()
function ShowCustomBind(self)
    -- Init
    RefreshPlayerSpellIconInfo()

    LoadIconPage(1)

    CustomBindGuide.Button      = self

    customIcon.Icon             = self.CustomTexture
    customIcon:GetPropertyChild("NormalTexture"):SetTexture(customIcon.Icon)
    inputCustomName:SetText(self.CustomText or "")
    inputMacroText:SetText(self.ActionType == "macrotext" and self.ActionTarget or "")

    CustomBindGuide:Show()
end