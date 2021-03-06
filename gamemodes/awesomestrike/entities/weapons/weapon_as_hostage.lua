AddCSLuaFile()

if CLIENT then
	SWEP.ForceThirdPerson = true
	SWEP.DrawCrosshair = false
	SWEP.ConeCrosshair = false

	function SWEP:DrawWorldModel()
	end
	SWEP.DrawWorldModelTranslucent = SWEP.DrawWorldModel
end

SWEP.Slot = 3

SWEP.PrintName = "Hostage"

SWEP.HoldType = "melee2"

SWEP.WorldModel = "models/Characters/Hostage_01.mdl"

SWEP.Base = "weapon_as_base"

SWEP.IsMelee = true

SWEP.Primary.Delay = 1.25
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Damage = 30

SWEP.WalkSpeed = SPEED_NORMAL

SWEP.SwingDuration = 0.3

function SWEP:GetSwingEnd() return self:GetDTFloat(3) end
function SWEP:SetSwingEnd(time) self:SetDTFloat(3, time) end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local owner = self.Owner
	owner:InterruptSpecialMoves()

	self:Swing()

	self:SetNextPrimaryAttack(CurTime() + self.Primary.Delay)
end

function SWEP:SecondaryAttack()
end

function SWEP:Swing(duration)
	duration = duration or self.SwingDuration
	self.Owner:DoAttackEvent()
	self:EmitSound("npc/zombie/claw_miss1.wav", 75, math.Rand(55, 65) * (self.SwingDuration / duration))
	self:SetSwingEnd(CurTime() + duration)
end

function SWEP:GetSwingTraces()
	return self.Owner:PenetratingTraceHull(self:GetSwingDistance(), MASK_SOLID, 16, self.Owner:GetMeleeAttackFilter(self))
end

function SWEP:GetSwingDistance()
	return 64
end

function SWEP:Swung()
	if not IsFirstTimePredicted() then return end

	local owner = self.Owner

	owner:LagCompensation(true)
	local traces = self:GetSwingTraces()
	owner:LagCompensation(false)

	local startpos = owner:GetShootPos()
	for _, trace in pairs(traces) do
		if not trace.Hit or trace.HitPos:Distance(startpos) > self:GetSwingDistance() + 16 then continue end

		local decalstart = trace.HitPos + trace.HitNormal * 8
		local decalend = trace.HitPos - trace.HitNormal * 8
		util.Decal("Blood", decalstart, decalend)
		util.Decal("Impact.Concrete", decalstart, decalend)

		self:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")

		local ent = trace.Entity
		if ent and ent:IsValid() then
			if SERVER then
				ent:ThrowFromPositionSetZ(owner:GetPos(), 300)
			end
			ent:TakeSpecialDamage(self.Primary.Damage, DMG_CLUB, owner, self, trace.HitPos)
		end
	end
end

function SWEP:Think()
	if self:GetSwingEnd() > 0 and CurTime() >= self:GetSwingEnd() then
		self:SetSwingEnd(0)
		self:Swung()
	end
end

function SWEP:OnHolster()
	if CurTime() >= self:GetNextPrimaryAttack() then
		if SERVER then
			if self.Owner:GetState() == STATE_CARRYHOSTAGE then self.Owner:EndState() end
		end
		return true
	end

	return false
end

function SWEP:CanPrimaryAttack()
	return CurTime() >= self:GetNextPrimaryAttack() and not self.Owner:GetStateTable().CantUseWeapons
end

function SWEP:GetKillAction(pl, attacker, dmginfo)
	return KILLACTION_HOSTAGE, nil
end

RegisterWeaponStatus("weapon_as_hostage", Vector(0, 0, -16), Angle(0, 270, 0))
