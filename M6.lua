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

class "DancerButton" 			(function(_ENV)

	local shareCooldown 		= { start = 0, duration = 0 }

	__SecureMethod__()
	function OverrideM6Update(self, usable, state, icon, _, count, cd, cd2, tf, ta, ext, lab)
		print("M6", self:GetName(), usable, state, icon, _, count, cd, cd2, tf, ta, ext, lab)

		usable 					= usable ~= false
		local active, overlay, usableCharge = state % 2 > 0, state % 4 > 1, usable or (state % 128 >= 64)
		local rUsable 			= state % 2048 < 1024

		-- icon
		self.Icon 				= icon

		-- cooldown
		shareCooldown.start 	= cd2 > 0 and GetTime()+cd-cd2 or 0
		shareCooldown.duration 	= cd2 == 60 and 59.95 or cd2

		if usableCharge then
			self.ChargeCooldown = shareCooldown
		else
			self.Cooldown 		= shareCooldown
		end

		-- text
		self.SetText 			= lab or ""

		--  checked
		self:SetChecked(active)

		-- usable
		self.IsUsable 			= usable
		self.InRange 			= hasrange

		-- count
		self.Count 				= count >= 1 and count or nil

		-- overlay
		self.OverlayGlow 		= overlay
	end
end)