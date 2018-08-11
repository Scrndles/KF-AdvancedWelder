class AdvancedWelderAltFire extends AdvancedWelderFire;

function bool AllowFire()
{
	local KFDoorMover WeldTarget;

	WeldTarget = GetDoor();

	// Can't use welder, if no door.
	if(WeldTarget == none)
		return false;

	// Cannot unweld a door that's already unwelded
	if(WeldTarget.WeldStrength <= 0)
		return false;

	//return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire ;
    return Weapon.AmmoAmount(1) >= AmmoPerFire ; //replaced thismodenum with 0 to make unwelding actually depend on rechargable ammo (also retain only needs 15 energy behaviour)
}

defaultproperties
{
     MeleeDamage=15
     hitDamageClass=Class'KFMod.DamTypeUnWeld'
     
     AmmoClass=Class'KFMod.WelderAmmo'
     AmmoPerFire=15
     MeleeHitSounds(0)=Sound'PatchSounds.WelderFire'
}
