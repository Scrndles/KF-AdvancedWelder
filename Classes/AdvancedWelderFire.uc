class AdvancedWelderFire extends WeldFire;

var             ScrnHumanPawn    CachedHealee;
var             KFMonster    CachedWeldee;
var float WeldRate, WeldModifier;
  
simulated function bool AllowFire()
{
	local KFDoorMover WeldTarget;
	WeldTarget = GetDoor();
    
	// Can't use welder, if no door.
	if ( WeldTarget == none && !CanFindHealee())
	{
		if ( KFPlayerController(Instigator.Controller) != none )
		{
			KFPlayerController(Instigator.Controller).CheckForHint(54);

			if ( FailTime + 0.5 < Level.TimeSeconds )
			{
				PlayerController(Instigator.Controller).ClientMessage(NoWeldTargetMessage, 'CriticalEvent');
				
				FailTime = Level.TimeSeconds;
			}

		}
		return false;
	}
	if(WeldTarget != none && WeldTarget.bDisallowWeld)
	{
		if( PlayerController(Instigator.controller)!=None )
		{
			PlayerController(Instigator.controller).ClientMessage(CantWeldTargetMessage, 'CriticalEvent');
			
			}

	    return false;
    }
    //return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire ;
    return Weapon.AmmoAmount(1) >= 20; //actually constants until its fixed
}

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


// Can we find someone to heal
function bool CanFindHealee()
{
	local ScrnHumanPawn Healtarget;
    local KFMonster Weldtarget;

    //firstly, disallow finding a healee if we don't have enough secondary ammo
    if (Weapon.AmmoAmount(0) == 0 )
    {
        return false;
    }
    
	Healtarget = GetHealee();
    WeldTarget = GetWeldee(); //copypaste for welding zeds
	CachedHealee = Healtarget;
    CachedWeldee = Weldtarget; //copypasta
   
	// Can't use syringe if we can't find a target
	if ( Healtarget != none)
	{
        // Can't use syringe if our target is already being healed to full health. (and also isn't dead)
        if (  Healtarget.ShieldStrength < Healtarget.GetShieldStrengthMax() && Healtarget.Health >= 0.001 )
        {
            return true; //if here, player's weapon has ammo, and has a target that can have shield added, so it's welding a player
        }
	}
    if ( Weldtarget != none)
    return true; //if here, there's a zed so enable welding to burn it
    else
    return false; //no targets so no welding allowed
}

function ScrnHumanPawn GetHealee()
{
	local ScrnHumanPawn KFHP, BestKFHP;
	local vector Dir;
	local float TempDot, BestDot;
	local vector Dummy,End,Start;

	Dir = vector(Instigator.GetViewRotation());

	foreach Instigator.VisibleCollidingActors(class'ScrnHumanPawn', KFHP, 80.0)
	{
		if ( KFHP.ShieldStrength < 100 )
		{
			TempDot = Dir dot (KFHP.Location - Instigator.Location);
			if ( TempDot > 0.7 && TempDot > BestDot )
			{
				BestKFHP = KFHP;
				BestDot = TempDot;
			}
		}
	}

    Start = Instigator.Location+Instigator.EyePosition();
	End = Start+vector(Instigator.GetViewRotation())*weaponRange;
    Instigator.bBlockHitPointTraces = false;
	Instigator.Trace(Dummy,Dummy,End,Start,True);
	return BestKFHP;
}

//copypaste of GetHealee for welding zeds
function KFMonster GetWeldee()
{
	local KFMonster KFM, BestKFM;
	local vector Dir;
	local float TempDot, BestDot;
	local vector Dummy,End,Start;

	Dir = vector(Instigator.GetViewRotation());

	foreach Instigator.VisibleCollidingActors(class'KFMonster', KFM, 80.0) //range 80
	{
		if ( KFM.Health > 0.001 )
		{
			TempDot = Dir dot (KFM.Location - Instigator.Location);
			if ( TempDot > 0.7 && TempDot > BestDot )
			{
				BestKFM = KFM;
				BestDot = TempDot;
			}
		}
	}

    Start = Instigator.Location+Instigator.EyePosition();
	End = Start+vector(Instigator.GetViewRotation())*weaponRange;
    Instigator.bBlockHitPointTraces = false;
	Instigator.Trace(Dummy,Dummy,End,Start,True);
	return BestKFM;
}

simulated function Timer()
{
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
		else if(CachedHealee !=none && Instigator != none && Level.NetMode!=NM_Client)
        {
           AdjustedLocation = Hitlocation;
		   AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);
		   Spawn(class'KFWelderHitEffect',,, AdjustedLocation, rotator(HitLocation - StartTrace)); 			
			
			if(CachedHealee.ShieldStrength < 10 && KFPlayerController(CachedHealee.Controller).SelectedVeterancy != class'KFVetSupportSpec')
		    	WeldArmor(CachedHealee, float(MeleeDamage)/(WeldRate*WeldModifier)); //replaced MyDamage with MeleeDamage to disable "weld speed" bonus from applying more armor per ammo
		    else
				WeldArmor(CachedHealee, float(MeleeDamage)/WeldRate);
        }
        if(CachedWeldee !=none && Instigator != none && Level.NetMode!=NM_Client)
        {
           AdjustedLocation = Hitlocation;
		   AdjustedLocation.Z = (Hitlocation.Z - 0.15 * Instigator.collisionheight);
           //HitActor.TakeDamage(MyDamage, Instigator, HitLocation , vector(PointRot),hitDamageClass);
           HitActor.TakeDamage(MeleeDamage, Instigator, HitLocation , vector(PointRot),Class'KFMod.DamTypeTrenchgun'); //replaced mydamage with melee damage to use value of 20 for now
		   Spawn(class'KFWelderHitEffect',,, AdjustedLocation, rotator(HitLocation - StartTrace)); 			
            
        }
        else if (HitActor == none)
        {
          CachedHealee = none;
          CachedWeldee = none;
        }
	}
}

function float GetFireSpeed()
{
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
    {
        return 0.5*(1.0 + KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetWeldSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo)));
        //give only half the bonus, because both weld damage and weld speed are boosted for doors, for players full weld speed bonus is too fast (all charge depletes after about 30 armor welded)
    }
    else
    {
        	return 1.0;
    }
}

function WeldArmor(ScrnHumanPawn CachedHealeeM, float value)
{
    //local float weldingValue;
    //local int intValue;
    //weldingValue = 1;
    //weldingValue += value;
    //intValue = int(weldingValue);  
    //if(intValue>0)
    //{
    //all the calculations disabled because it welds 1 armor at a time
    
    CachedHealeeM.AddShieldStrength(1); //add 1 armor
    Weapon.ConsumeAmmo(0, 1); //consume 1 ammo from ammoclass 0
    if(CachedHealeeM.ShieldStrength >= CachedHealeeM.GetShieldStrengthMax())
    {
        CachedHealeeM.ShieldStrength = CachedHealeeM.GetShieldStrengthMax();
    }
}

defaultproperties
{
     hitDamageClass=Class'KFMod.DamTypeWelder'
     //burnDamageClass=Class'KFMod.DamTypeTrenchgun'
     MyDamage
     TransientSoundVolume=1.8

     //copypaste from armorwelder
     MeleeDamage=20 //10 is the default value
     maxAdditionalDamage=0
     FireRate=0.200000
	 WeldRate = 40
	 WeldModifier = 1
    
     AmmoClass=Class'AdvancedWelder.AdvancedWelderAmmo'   
     AmmoPerFire=20
     
     DamagedelayMin=0.100000
     DamagedelayMax=0.100000
     MeleeHitSounds(0)=Sound'PatchSounds.WelderFire'

     NoWeldTargetMessage="You must be near a weldable door to use the welder."
     CantWeldTargetMessage="You cannot weld this door."
}
