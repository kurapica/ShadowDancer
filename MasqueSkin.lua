--========================================================--
--                ShadowDancer Masque Skin                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/06/23                              --
--========================================================--

if not IsAddOnLoaded("Masque") then return end

--========================================================--
Scorpio           "ShadowDancer.MasqueSkin"          "1.0.0"
--========================================================--

import "Scorpio.Secure.SecureActionButton"

do
    Masque                      = LibStub("Masque", true)
    MasqueSkin                  = Masque:GetSkins() or {}
    skinList                    = XDictionary(pairs(MasqueSkin)).Keys:ToList()
    if not skinList:Contains("Classic") then
        skinList:Insert(1, "Classic")
    end
end

function OnLoad(self)
    if _SVDB.MasqueSkin and _SVDB.MasqueSkin ~= "Classic" and _Config.MasqueSkin:GetValue() == "Classic" then
        return ActiveMasqueSkin(_SVDB.MasqueSkin)
    end
end

__Config__(_Config, enum (skinList), "Classic")
function ActiveMasqueSkin(skin)
    if not MasqueSkin[skin] then return Style.UpdateSkin("ShadowDancerMasqueSkin", {}) end

    -- Generate the Scorpio skin based on the masque skin
    -- The action button and masque use 36 * 36 as the button size, so no scale convertion
    local masqueSkin            = MasqueSkin[skin]
    local skin                  = {
        FlyoutBorder            = NIL,
        FlyoutBorderShadow      = NIL,
    }

    -- Mask for the Buttonn
    -- skin.maskTexture         = BuildMaskSkin(masqueSkin.Mask)

    if masqueSkin.Backdrop and not masqueSkin.Backdrop.Hide then
        skin.BackgroundTexture  = BuildTextureSkin(masqueSkin, "Backdrop", "BACKGROUND")
    end

    if masqueSkin.Icon then
        skin.IconTexture        = {
            texCoords           = masqueSkin.Icon.TexCoords and RectType(unpack(masqueSkin.Icon.TexCoords)) or nil,
            drawLayer           = masqueSkin.Icon.DrawLayer or "BACKGROUND",
            subLevel            = masqueSkin.Icon.DrawLevel or 1,

            size                = GetSize(masqueSkin.Icon),
            setAllPoints        = masqueSkin.Icon.SetAllPoints and true or nil,
            location            = GetLocation(masqueSkin.Icon),

            maskTexture         = BuildMaskSkin(masqueSkin.Icon.Mask or masqueSkin.Icon.UseMask and masqueSkin.Mask),
        }
    end

    if masqueSkin.Shadow and not masqueSkin.Shadow.Hide then
        skin.ShadowTexture      = BuildTextureSkin(masqueSkin, "Shadow", "ARTWORK")
    end

    if masqueSkin.Normal and not masqueSkin.Normal.Hide then
        skin.NormalTexture      = BuildTextureSkin(masqueSkin, "Normal")
    end

    if masqueSkin.Pushed and not masqueSkin.Pushed.Hide then
        skin.PushedTexture      = BuildTextureSkin(masqueSkin, "Pushed")
    end

    if masqueSkin.Checked and not masqueSkin.Checked.Hide then
        skin.CheckedTexture     = BuildTextureSkin(masqueSkin, "Checked")
    end

    if masqueSkin.Highlight and not masqueSkin.Highlight.Hide then
        skin.HighlightTexture   = BuildTextureSkin(masqueSkin, "Highlight")
    end

    if masqueSkin.Flash and not masqueSkin.Flash.Hide then
        local flashSkin         = BuildTextureSkin(masqueSkin, "Flash")
        flashSkin.alpha         = 0
        flashSkin.animationGroup= {
            playing             = Wow.FromUIProperty("IsAutoAttacking"),
            looping             = "REPEAT",

            Alpha1              = {
                order           = 1,
                duration        = 0.01,
                fromAlpha       = 0,
                toAlpha         = 1,
            },
            Alpha2              = {
                order           = 1,
                duration        = 0.01,
                startDelay      = 0.4,
                fromAlpha       = 1,
                toAlpha         = 0,
            },
            Alpha3              = {
                order           = 1,
                duration        = 0.01,
                startDelay      = 0.8,
                fromAlpha       = 0,
                toAlpha         = 0,
            }
        }

        masqueSkin.FlashTexture =  Wow.FromUIProperty("IsAutoAttack"):Map(function(val) return val and flashSkin or nil end)
    end

    if masqueSkin.Name then
        skin.NameLabel          = BuildTextSkin(masqueSkin.Name)
    end

    if masqueSkin.HotKey then
        skin.HotKeyLabel        = BuildTextSkin(masqueSkin.HotKey)
    end

    if masqueSkin.Count then
        skin.CountLabel         = BuildTextSkin(masqueSkin.Count)
    end

    if masqueSkin.Border and not masqueSkin.Border.Hide then
        skin.EquippedItemTexture= BuildTextureSkin(masqueSkin, "Border")
        skin.EquippedItemTexture.visible = Wow.FromUIProperty("IsEquippedItem")
    end

    if masqueSkin.Gloss and not masqueSkin.Gloss.Hide and masqueSkin.Gloss.Texture then
        skin.GlossTexture       = BuildTextureSkin(masqueSkin, "Gloss")
    end

    if masqueSkin.Cooldown then
        local isRound           = masqueSkin.Shape == "Circle"
        skin.Cooldown           = {
            UseCircularEdge     = isRound,
            SwipeTexture        = TextureType(masqueSkin.Cooldown.Texture or (isRound and [[Interface\AddOns\Masque\Textures\Cooldown\Swipe-Circle]]) or [[Interface\AddOns\Masque\Textures\Cooldown\Swipe]]),

            size                = GetSize(masqueSkin.Cooldown),
            setAllPoints        = masqueSkin.Cooldown.SetAllPoints and true or nil,
            location            = GetLocation(masqueSkin.Cooldown),
        }

        local chargeSkin        = Toolset.clone(skin.Cooldown)
        chargeSkin.cooldown     = Wow.FromUIProperty("ChargeCooldown")

        skin.ChargeCooldown     = Wow.FromUIProperty("IsChargable"):Map(function(val) return val and chargeSkin or nil end)
    end

    if masqueSkin.Shape == "Square" then
        Style.ActiveSkin("Default", DancerButtonAlert)
    else
        Style.ActiveSkin("ShadowDancerMasqueSkin", DancerButtonAlert)
    end

    Style.UpdateSkin("ShadowDancerMasqueSkin", { [DancerButton] = skin })
end

function BuildMaskSkin(config)
    local tconfig               = type(config)
    return (tconfig == "table" and not config.Hide) and {
        file                    = config.Texture,
        size                    = GetSize(config),
        setAllPoints            = config.SetAllPoints and true or nil,
        location                = GetLocation(config),
    } or (tconfig == "string" or tconfig == "number") and {
        file                    = config,
        setAllPoints            = true,
    } or nil
end

function BuildTextureSkin(skin, name, defaultDrawLayer)
    local config            = skin[name]
    return (not config.Hide and config.UseColor or config.Texture) and {
        file                = config.UseColor and NIL or config.Texture,
        vertexColor         = config.UseColor and Color.WHITE or config.Color and Color(unpack(config.Color)) or nil,
        color               = config.UseColor and config.Color and Color(unpack(config.Color)) or nil,
        texCoords           = config.TexCoords and RectType(unpack(config.TexCoords)) or nil,
        alphaMode           = config.BlendMode or "BLEND",
        drawLayer           = config.DrawLayer or defaultDrawLayer or "BACKGROUND",
        subLevel            = config.DrawLevel or -1,

        size                = GetSize(config),
        setAllPoints        = config.SetAllPoints and true or nil,
        location            = GetLocation(config),

        maskTexture         = BuildMaskSkin(config.Mask or config.UseMask and skin.Mask),
    }
end

function BuildTextSkin(config)
    return {
        justifyH                = config.JustifyH or "CENTER",
        justifyV                = config.JustifyV or "MIDDLE",
        drawLayer               = config.DrawLayer or "ARTWORK",

        size                    = GetSize(config),
        setAllPoints            = config.SetAllPoints and true or nil,
        location                = GetLocation(config),
    }
end

function GetSize(skin)
    if skin.SetAllPoints then return end

    return Size(skin.Width, skin.Height or 10)
end

function GetLocation(skin, default)
    if skin.SetAllPoints then return end

    local point                 = skin.Point
    local relpoint              = skin.RelPoint or point

    if not point then
        point                   = default and default.Point

        if point then
            relpoint            = default.RelPoint or point
        else
            point               = "CENTER"
            relpoint            = point
        end
    end

    local offsetX               = skin.OffsetX
    local offsetY               = skin.OffsetY

    if default and not offsetX and not offsetY then
        offsetX                 = default.OffsetX or 0
        offsetY                 = default.OffsetY or 0
    end

    return { Anchor(point, offsetX or 0, offsetY or 0, nil, relpoint) }
end


-- The Shadow texture
UI.Property                     {
    name                        = "ShadowTexture",
    require                     = DancerButton,
    childtype                   = Texture,
}

-- The Gloss Texture
UI.Property                     {
    name                        = "GlossTexture",
    require                     = DancerButton,
    childtype                   = Texture,
}


Style.RegisterSkin("ShadowDancerMasqueSkin", {
    [DancerButton]      = {
        FlyoutBorder    = NIL,
        FlyoutBorderShadow = NIL,
    },
    [DancerButtonAlert] = {
        inherit         = "default",

        Spark           = {
            file        = [[Interface\AddOns\Masque\Textures\SpellAlert\IconAlert-Circle]],
        },

        InnerGlow       = {
            file        = [[Interface\AddOns\Masque\Textures\SpellAlert\IconAlert-Circle]],
        },

        InnerGlowOver   = {
            file        = [[Interface\AddOns\Masque\Textures\SpellAlert\IconAlert-Circle]],
        },

        OuterGlow       = {
            file        = [[Interface\AddOns\Masque\Textures\SpellAlert\IconAlert-Circle]],
        },

        OuterGlowOver   = {
            file        = [[Interface\AddOns\Masque\Textures\SpellAlert\IconAlert-Circle]],
        },

        Ants            = {
            file        = [[Interface\AddOns\Masque\Textures\SpellAlert\IconAlertAnts-Circle]],
        },
    }
})

Style.ActiveSkin("ShadowDancerMasqueSkin", DancerButton)
skinList                        = nil