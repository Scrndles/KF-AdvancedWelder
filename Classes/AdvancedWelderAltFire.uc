class AdvancedWelderAltFire extends AdvancedWelderFire;
//ScrnHumanPawn.AddShieldStrength()

var             ScrnHumanPawn    CachedSelfHealee;
var bool bSelfWeldMode;

//allow fire on doors for unwelding, and allow firing for no target if has armor welding ammo and can self weld
function bool AllowFire()
{
    //local ScrnHumanPawn localSHP;
	local KFDoorMover WeldTarget;

	WeldTarget = GetDoor();
	
    // Can't use welder, if no door.
	if(WeldTarget != none)
    {
        bSelfWeldMode = false;
        if (WeldTarget.WeldStrength <= 0) // Cannot unweld a door that's already unwelded
            return false;
        else
            return Weapon.AmmoAmount(1) >= AmmoPerFire ; //replaced thismodenum with 0 to make unwelding actually depend on rechargable ammo (also retain only needs 15 energy behaviour)
    }
    //if there is no door, do check if armor can be added to allow self weld
    if (CachedSelfHealee.AddShieldStrength(1))
    {
        bSelfWeldMode = true;
        return Weapon.AmmoAmount(0) >= 1 ; 
    }
}
/*
function bool CanFindHealee()
{
    local ScrnHumanPawn localSHP;

    //firstly, disallow finding a healee if we don't have enough secondary ammo
    if (Weapon.AmmoAmount(0) == 0 )
    {
        return false;
    }
    
    //next, check if we can have more armor
    if (localSHP.AddShieldStrength(1) == true )
    {
        return true;
    }
}
*/
//added to add consume ammo
simulated event ModeDoFire()
{
	local float Rec;

	if (!AllowFire())
		return;

	Rec = GetFireSpeed();
	SetTimer(DamagedelayMin/Rec, False);
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;
  
	if (MaxHoldTime > 0.0)
		HoldTime = FMin(HoldTime, MaxHoldTime);

	// server
	if (Weapon.Role == ROLE_Authority)
	{
		Weapon.ConsumeAmmo(1, AmmoPerFire); //consume 20 ammo from ammoclass 1
		DoFireEffect();


		HoldTime = 0;   // if bot decides to stop firing, HoldTime must be reset first
		if ( (Instigator == None) || (Instigator.Controller == None) )
			return;

		if ( AIController(Instigator.Controller) != None )
			AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

		Instigator.DeactivateSpawnProtection();
	}

	// client
	if (Instigator.IsLocallyControlled())
	{
		ShakeView();
		PlayFiring();
		FlashMuzzleFlash();
		StartMuzzleSmoke();
		ClientPlayForceFeedback(FireForce);
	}
	else // server
		ServerPlayFiring();

	Weapon.IncrementFlashCount(ThisModeNum);

	// set the next firing time. must be careful here so client and server do not get out of sync
	if (bFireOnRelease)
	{
		if (bIsFiring)
			NextFireTime += MaxHoldTime + FireRate;
		else
			NextFireTime = Level.TimeSeconds + FireRate;
	}
	else
	{
		NextFireTime += FireRate;
		NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
	}

	Load = AmmoPerFire;
	HoldTime = 0;

	if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
	{
		bIsFiring = false;
		Weapon.PutDown();
	}

    if( Weapon.Owner != none && Weapon.Owner.Physics != PHYS_Falling )
    {
        Weapon.Owner.Velocity.x *= KFMeleeGun(Weapon).ChopSlowRate;
        Weapon.Owner.Velocity.y *= KFMeleeGun(Weapon).ChopSlowRate;
    }
}

simulated function Timer()
{
    //if this if firing, it's either hitting a door or nothing, if it hits nothing then do self weld

	local Actor HitActor;
	local vector StartTrace, EndTrace, HitLocation, HitNormal,AdjustedLocation;
	local rotator PointRot;
	local int MyDamage;
	
	
	If( !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = MeleeDamage + Rand(MaxAdditionalDamage);
        
		if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		{
			MyDamage = float(MyDamage) * KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetWeldSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo));
		}
		PointRot = Instigator.GetViewRotation();
		StartTrace = Instigator.Location + Instigator.EyePosition();

		if( AIController(Instigator.Controller)!=None && Instigator.Controller.Target!=None )
		{
			EndTrace = StartTrace + vector(PointRot)*weaponRange;
			Weapon.bBlockHitPointTraces = false;
			HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
            Weapon.bBlockHitPointTraces = Weapon.default.bBlockHitPointTraces;

			if( HitActor==None )
			{
				EndTrace = Instigator.Controller.Target.Location;
    			Weapon.bBlockHitPointTraces = false;
				HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
                Weapon.bBlockHitPointTraces = Weapon.default.bBlockHitPointTraces;
			}
			if( HitActor==None )
				HitLocation = Instigator.Controller.Target.Location;
			HitActor = Instigator.Controller.Target;
		}
		else
		{
			EndTrace = StartTrace + vector(PointRot)*weaponRange;
            Weapon.bBlockHitPointTraces = false;
            HitActor = Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
            Weapon.bBlockHitPointTraces = Weapon.default.bBlockHitPointTraces;
		}

		LastHitActor = KFDoorMover(HitActor);

		if( LastHitActor!=none && Level.NetMode!=NM_Client )
		{
			AdjustedLocation = Hitlocation;
			AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);

			HitActor.TakeDamage(MyDamage, Instigator, HitLocation , vector(PointRot),hitDamageClass);
			Spawn(class'KFWelderHitEffect',,, AdjustedLocation, rotator(HitLocation - StartTrace));
		}
        else if (HitActor == none && bSelfWeldMode)
        {
          //CachedSelfHealee = none;
            //if( CachedSelfHealee.AddShieldStrength(1) != false && Instigator != none && Level.NetMode!=NM_Client)
            //{
                AdjustedLocation = Hitlocation;
                AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);
                Spawn(class'KFWelderHitEffect',,, AdjustedLocation, rotator(HitLocation - StartTrace)); 			
                SelfWeld();
            //}
        }
	}

}

Function SelfWeld()
{
    local int MyDamage;

    MyDamage = 1;

    //Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
    Instigator.ShieldStrength+= MyDamage; //to max of 100
    if ( Instigator.ShieldStrength >= 100) 
    {
        Instigator.ShieldStrength = 100;
    }
}

defaultproperties
{
     MeleeDamage=15
     hitDamageClass=Class'KFMod.DamTypeUnWeld'
     
     AmmoClass=Class'KFMod.WelderAmmo'
     AmmoPerFire=15
     MeleeHitSounds(0)=Sound'PatchSounds.WelderFire'
}
