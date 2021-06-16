--========================================================--
--                ShadowDancer                            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/05/16                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer"                     "0.1.0"
--========================================================--

namespace "ShadowDancer"

export { floor = math.floor, min = math.min, ceil = math.ceil }

BAR_MAX_BUTTON                  = 12
HIDDEN_FRAME                    = CreateFrame("Frame") HIDDEN_FRAME:Hide()
RECYCLE_MASKS                   = Recycle(Scorpio.Widget.Mask, "ShadowDancer_Mask%d", HIDDEN_FRAME)

RECYCLE_BARS                    = Recycle(ShadowBar, "ShadowDancerBar%d", UIParent)
CURRENT_BARS                    = List()
CURRENT_SPEC

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

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB                       = SVManager("ShadowDancer_DB", "ShadowDancer_CharDB")

    local charSV                = CharSV()

    charSV:SetDefault{ ActionBars = {} }

    if #charSV.ActionBars == 0 then
        charSV.ActionBars[1]    = {

        }
    end
end

function OnSpecChanged(self, spec)
    spec                        = spec or 1

    -- Save the config if we have the bars
    if #CURRENT_BARS > 0 and CURRENT_SPEC then OnQuit() end


end

function OnQuit()
    CharSV(CURRENT_SPEC).ActionBars = CURRENT_BARS:Map(function(self) return self:SaveProfile() end):ToList()
end

-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------

-----------------------------------------------------------
-- Helpers
-----------------------------------------------------------
local function OnStartResizing(self)
    local panel                 = self:GetParent()
    panel.AutoSize              = false

    Next(function()
        while not (panel.AutoSize or InCombatLockdown())  do
            panel.RowCount      = min(BAR_MAX_BUTTON, max(1, floor(panel:GetWidth() / panel.ElementWidth)))
            panel.ColumnCount   = min(ceil(BAR_MAX_BUTTON / panel.RowCount), max(1, floor(panel:GetHeight() / panel.ElementHeight)))
            panel.Count         = min(BAR_MAX_BUTTON, panel.RowCount * panel.ColumnCount)

            Next()
        end
    end)
end

local function OnStopResizing(self)
    if InCombatLockdown() then
        NoCombat(function(self) self.AutoSize = true end, self.GetParent())
    else
        self:GetParent().AutoSize = true
    end
end

local function OpenMaskMenu(self)
end

function RECYCLE_MASKS:OnInit(mask)
    mask.OnClick                = OpenMaskMenu
    mask.OnStartResizing        = OnStartResizing
    mask.OnStopResizing         = OnStopResizing
end

function RECYCLE_MASKS:OnPush(mask)
    mask:SetParent(HIDDEN_FRAME)
end

if Scorpio.IsRetail then
    function CharSV(spec)
        return spec and _SVDB.Char.Specs[spec] or _SVDB.Char.Spec
    end
else
    function CharSV()
        return _SVDB.Char
    end
end