--========================================================--
--                ShadowDancer ExtraActionButton             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/07/11                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer.ExtraActionButton"      "1.0.0"
--========================================================--

if not GetExtraBarIndex or Scorpio.IsRetail then return end

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB:SetDefault{
        ExtraActionButton       = {
            Location            = { Anchor("BOTTOM", 0, 100) },
            Scale               = 1,
        }
    }

    -- Clear the previous settings
    _SVDB.ExtraActionBar        = nil

    -- Block the original extra action bar
    ActionBarController:UnregisterEvent("UPDATE_EXTRA_ACTIONBAR")
end

function OnEnable()
    ExtraActionButton           = SecureActionButton("ShadowDancer_ExtraActionButton")

    Style[ExtraActionButton]    = {
        size                    = Size(52, 52),

        BackgroundTexture       = {
            drawLayer           = "OVERLAY",
            size                = Size(256, 128),
            location            = { Anchor("CENTER", -2, 0) },
            file                = Wow.FromEvent("UPDATE_EXTRA_ACTIONBAR"):Map(function() return GetOverrideBarSkin() or "Interface\\ExtraButton\\Default" end),
        }
    }


    ExtraActionButton:SetLocation(_SVDB.ExtraActionButton.Location)
    ExtraActionButton:SetAutoHide("[noextrabar]")
    ExtraActionButton:SetID(1)
    ExtraActionButton:SetActionPage(GetExtraBarIndex())
    ExtraActionButton:SetScale(_SVDB.ExtraActionButton.Scale)
    ExtraActionButton.HotKey    = _SVDB.ExtraActionButton.HotKey
    ExtraActionButton.GridAlwaysShow = true

    ExtraActionButton:GetPropertyChild("BackgroundTexture"):InstantApplyStyle()

    ExtraActionButtonMask          = RECYCLE_MASKS()
    ExtraActionButtonMask:SetParent(ExtraActionButton)
    ExtraActionButtonMask:Hide()
    ExtraActionButtonMask.OnClick  = OpenMaskMenu

    Delay(1, FireSystemEvent, "UPDATE_EXTRA_ACTIONBAR")
end

function OnQuit()
    _SVDB.ExtraActionButton.Location   = ExtraActionButton:GetLocation()
    _SVDB.ExtraActionButton.Scale      = ExtraActionButton:GetScale()
    _SVDB.ExtraActionButton.HotKey     = ExtraActionButton.HotKey
end

__SystemEvent__()
function SHADOWDANCER_UNLOCK()
    ExtraActionButton:SetAutoHide(nil)
    ExtraActionButton:Show()
    ExtraActionButtonMask:Show()
    ExtraActionButton:SetMovable(true)
end

__SystemEvent__()
function SHADOWDANCER_LOCK()
    ExtraActionButton:SetAutoHide("[noextrabar]")
    ExtraActionButtonMask:Hide()
    NoCombat(function() ExtraActionButton:SetMovable(false) end)
end

__SystemEvent__()
function SCORPIO_ACTION_BUTTON_KEY_BINDING_START()
    ExtraActionButton:SetAutoHide(nil)
    ExtraActionButton:Show()
end

__SystemEvent__()
function SCORPIO_ACTION_BUTTON_KEY_BINDING_STOP()
    ExtraActionButton:SetAutoHide("[noextrabar]")
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
            text                = _Locale["Scale"] .. " - " .. ("%.2f"):format(ExtraActionButton:GetScale()),
            click               = function()
                local value     = PickRange(_Locale["Choose the scale"], 0.3, 3, 0.1, ExtraActionButton:GetScale())
                if value then ExtraActionButton:SetScale(value) end
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