--========================================================--
--                ShadowDancer                            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/05/16                              --
--========================================================--

--========================================================--
Scorpio           "ShadowDancer.M6"                  "1.0.0"
--========================================================--

if not IsAddOnLoaded("M6") then return end

-- Add M6 support
__Sealed__()
interface "IM6"                 (function(_ENV)
    local texMetaIndex do
        local tex               = WorldFrame:CreateTexture()
        tex:Hide()
        texMetaIndex            = getmetatable(tex).__index
    end

    local function OnActionRefresh(self)
        -- Add support to M6
        local m6tex             = nil
        if self.ActionType == "macro" or self.ActionType == "action" then
            local name, tex     = GetMacroInfo(self.ActionTarget)
            if name and name:match("^_M6") then
                m6tex           = tex
            end
        end

        if self.ActionType == "action" then
            local type, id      = GetActionInfo(self.ActionTarget)
            if type == "macro" then
                local name, tex = GetMacroInfo(id)
                if name and name:match("^_M6") then
                    m6tex       = tex
                end
            end
        end

        if m6tex then
            self.__M6           = true

            Next(function()
                while not self:GetPropertyChild("IconTexture") do
                    Next()
                end

                -- trigger the M6 hook
                texMetaIndex.SetTexture(self:GetPropertyChild("IconTexture"), m6tex)
            end)
        elseif self.__M6 then
            self.__M6           = nil
            print("Trigger release")
            Next(function()
                while not self:GetPropertyChild("IconTexture") do
                    Next()
                end

                -- trigger the M6 hook
                texMetaIndex.SetTexture(self:GetPropertyChild("IconTexture"), "")
            end)
        end
    end

    function __init(self)
        self.OnActionRefresh    = self.OnActionRefresh + OnActionRefresh
    end
end)

class "DancerButton"            (function(_ENV)
    extend "IM6"

    local shareCooldown         = { start = 0, duration = 0 }

    __SecureMethod__()
    function OverrideM6Update(self, usable, state, icon, _, count, cd, cd2, tf, ta, ext, lab)
        usable                  = usable ~= false
        local active, overlay, usableCharge = state % 2 > 0, state % 4 > 1, usable or (state % 128 >= 64)
        local rUsable           = state % 2048 < 1024

        -- icon
        self.Icon               = icon

        -- cooldown
        shareCooldown.start     = cd2 > 0 and GetTime()+cd-cd2 or 0
        shareCooldown.duration  = cd2 == 60 and 59.95 or cd2

        if usableCharge then
            self.ChargeCooldown = shareCooldown
        else
            self.Cooldown       = shareCooldown
        end

        -- text
        self.SetText            = lab or ""

        --  checked
        self:SetChecked(active)

        -- usable
        self.IsUsable           = usable
        self.InRange            = hasrange

        -- count
        self.Count              = count >= 1 and count or nil

        -- overlay
        self.OverlayGlow        = overlay
    end
end)