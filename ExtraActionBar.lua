--========================================================--
--                ShadowDancer ExtraActionBar             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/07/11                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer.ExtraActionBar"      "1.0.0"
--========================================================--

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB:SetDefault{
        ExtraActionBar          = {
            Location            = { Anchor("BOTTOM", 0, 100) },
            Scale               = 1,
            ShowStyleBorder     = true,
        }
    }

    -- Block the original extra action bar
    ActionBarController:UnregisterEvent("UPDATE_EXTRA_ACTIONBAR")
end

function OnEnable()
    ExtraActionBar              = ShadowBar.BarPool()
    ExtraActionBar:SetProfile   {
        Style                   = {
            location            = _SVDB.ExtraActionBar.Location,
            scale               = _SVDB.ExtraActionBar.Scale,
            actionBarMap        = ActionBarMap.NONE,
            autoHideCondition   = { "[noextrabar]" },
            autoFadeOut         = false,
            fadeAlpha           = 0,
            gridAlwaysShow      = true,

            rowCount            = 1,
            columnCount         = 1,
            count               = 1,
            orientation         = "HORIZONTAL",
            leftToRight         = true,
            topToBottom         = true,
            hSpacing            = 1,
            vSpacing            = 1,
        },

        Buttons                 = {
            {
                ActionType      = "action",
                ActionTarget    = 1,
                HotKey          = _SVDB.ExtraActionBar.HotKey,
            }
        }
    }

    ExtraActionBar.Elements[1]:SetActionPage(GetExtraBarIndex())

    ExtraActionBarMask          = RECYCLE_MASKS()
    ExtraActionBarMask:SetParent(ExtraActionBar)
    ExtraActionBarMask:Hide()
    ExtraActionBarMask.OnClick  = OpenMaskMenu

    RefreshStyleBorder()
end

__Async__()
function RefreshStyleBorder()
    Style[ExtraActionBar]       = {
        IconTexture             = _SVDB.ShowStyleBorder and {
            drawLayer           = "OVERLAY",
            size                = Size(256, 128),
            location            = { Anchor("CENTER", -2, 0) },
            file                = Wow.FromEvent("UPDATE_EXTRA_ACTIONBAR"):Map(function() return GetOverrideBarSkin() or "Interface\\ExtraButton\\Default" end),
        } or NIL
    }

    ExtraActionBar:GetPropertyChild("IconTexture"):InstantApplyStyle()

    Delay(1)
    FireSystemEvent("UPDATE_EXTRA_ACTIONBAR")
end

function OnQuit()
    _SVDB.ExtraActionBar.Location   = ExtraActionBar:GetLocation()
    _SVDB.ExtraActionBar.Scale      = ExtraActionBar:GetScale()
    _SVDB.ExtraActionBar.HotKey     = ExtraActionBar.Elements[1].HotKey
end

__SystemEvent__()
function SHADOWDANCER_UNLOCK()
    ExtraActionBarMask:Show()
    ExtraActionBar:SetMovable(true)
end

__SystemEvent__()
function SHADOWDANCER_LOCK()
    ExtraActionBarMask:Hide()
    NoCombat(function() ExtraActionBar:SetMovable(false) end)
end

function OpenMaskMenu(self, button)
    if button ~= "RightButton" then return end

    ShowDropDownMenu{
        {
            text                = _Locale["Lock Bar"],
            click               = _Addon.LockBars,
        },
        {
            text                = _Locale["Start Key Binding"],
            click               = function()
                _Addon.LockBars()
                return SecureActionButton.StartKeyBinding()
            end
        },
        {
            text                = _Locale["Scale"] .. " - " .. ("%.2f"):format(ExtraActionBar:GetScale()),
            click               = function()
                local value     = PickRange(_Locale["Choose the scale"], 0.3, 3, 0.1, ExtraActionBar:GetScale())
                if value then ExtraActionBar:SetScale(value) end
            end
        },
        {
            text                = _Locale["Show Style Border"],
            check               = {
                get             = function() return _SVDB.ShowStyleBorder end,
                set             = function(val) _SVDB.ShowStyleBorder = val RefreshStyleBorder() end,
            }
        },
    }
end