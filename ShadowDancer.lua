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

export { floor = math.floor, min = math.min, max = math.max, ceil = math.ceil, tinsert = table.insert, sqrt = math.sqrt }

BAR_MAX_BUTTON                  = 12
HIDDEN_FRAME                    = CreateFrame("Frame") HIDDEN_FRAME:Hide()
RECYCLE_MASKS                   = Recycle(Scorpio.Widget.Mask, "ShadowDancer_Mask%d", HIDDEN_FRAME)

GLOBAL_BARS                     = List()
CURRENT_BARS                    = List()
CURRENT_SPEC                    = false
UNLOCK_BARS                     = false

ANCHORS                         = XList(Enum.GetEnumValues(FramePoint)):Map(function(x) return { Anchor(x, 0, 0) } end):ToList()


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

    CharSV():SetDefault         {
        Draggable               = true,
        UseMouseDown            = false,

        ActionBars              = {}
    }

    ShadowBar.PopupDuration     = _SVDB.PopupDuration
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
    if #CURRENT_BARS > 0 and CURRENT_SPEC then
        preProfile              = CURRENT_BARS:Map(ShadowBar.GetProfile):ToTable()
        CharSV(CURRENT_SPEC).ActionBars = preProfile
    end

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
end

function OnQuit()
    CharSV().ActionBars         = CURRENT_BARS:Map(ShadowBar.GetProfile):ToTable()
    _SVDB.ActionBars            = GLOBAL_BARS:Map(ShadowBar.GetProfile):ToTable()
end

function RECYCLE_MASKS:OnInit(mask)
    mask.OnClick                = OpenMaskMenu
    mask.OnStopMoving           = OnStopMoving
end

function RECYCLE_MASKS:OnPush(mask)
    mask:SetParent(HIDDEN_FRAME)
end

-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------
__SlashCmd__ "/shd"          "unlock"
__SlashCmd__ "/shadow"       "unlock"
__SlashCmd__ "/shadowdancer" "unlock"
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
end

__SlashCmd__ "/shd"          "lock"
__SlashCmd__ "/shadow"       "lock"
__SlashCmd__ "/shadowdancer" "lock"
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
end

__SlashCmd__ "/shd"          "bind"
__SlashCmd__ "/shadow"       "bind"
__SlashCmd__ "/shadowdancer" "bind"
function BindKeys()
    if InCombatLockdown() then return end
    SecureActionButton.StartKeyBinding()
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
                            bar.RowCount    = math.max(bar.RowCount, math.floor(12 / value))
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
                            bar.Count   = math.min(12, bar.ColumnCount * bar.RowCount)
                        end
                    end
                },
                {
                    text                = _Locale["Scale"] .. " - " .. bar:GetScale(),
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
    config.check                = { get = function() return self.ActionBarMap end, set = function(value) Style[self].actionBarMap = value end }
    return config
end

function GetAutoHideMenu(self)
    local config                = {
        {
            text                = _Locale["Add Macro Condition"],
            click               = function()
                local new       = PickMacroCondition(_Locale["Please select the macro condition"])
                if new then
                    print("new", new)
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
            end
        else
            if MicroButtonAndBagsBar:GetParent() == HIDDEN_FRAME then
                MainMenuBar:SetAlpha(1)
                MainMenuBar:ClearAllPoints()
                MainMenuBar:SetPoint("BOTTOM")
                MainMenuBar:SetUserPlaced(false)
                MainMenuBar:SetMovable(false)

                MicroButtonAndBagsBar:SetParent(MainMenuBar)
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