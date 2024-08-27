local beamMat = Material("ultimateph/aim_laser")
local ray_color = Color(50,170,46)
local ray_width = 6

local dotMat = Material("ultimateph/aim_dot")
local dot_color = Color(255,255,255)

local hunters_aim = {}

function GM:PostDrawTranslucentRenderables()
    hunters_aim = {}
    self:GetHuntersAim()

    -- When "ph_hunter_aim_laser" set to 0, nobody can see the beam
    -- set to 1 == spectator only, set to 2 == props and spectator
    -- Also, we don't want the hunters to see the ray, to prevent eventual visual bugs
    local visibility = GetConVar("ph_hunter_aim_laser"):GetInt()

    if visibility == 0 then return end

    if visibility == 1 and not LocalPlayer():IsSpectator() then return end
    if visibility == 2 and not (LocalPlayer():IsSpectator() or LocalPlayer():IsProp()) then return end

    for _, h_aim in pairs(hunters_aim) do
        render.SetMaterial(beamMat)
        render.DrawBeam(h_aim.eye_pos, h_aim.looking.HitPos, ray_width, 0, 1, ray_color)

        render.SetMaterial(dotMat)
        local size = math.random(8, 16)
        render.DrawQuadEasy(h_aim.looking.HitPos + h_aim.looking.HitNormal, h_aim.looking.HitNormal, size, size, dot_color, 0)
    end
end

function GM:GetHuntersAim()
    for _, ply in pairs(player.GetAll()) do
        if ply:IsHunter() then
            local t = {}
            t.eye_pos = ply:EyePos()
            t.looking = ply:GetEyeTrace()
            table.insert(hunters_aim, t)
        end
    end
end