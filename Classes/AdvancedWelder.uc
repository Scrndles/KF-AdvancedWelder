class AdvancedWelder extends KFMeleeGun;

//advanced welder functions like old welder for doors
//all welding uses the default charged ammo, but welding armor will also use weldy ammo

/////////////////////////////////////////////////////
///// begin copypaste from welder to extend KFMeleeGun instead of Welder so the ammo will show up
///////////////////////////////////////////////////

var () float AmmoRegenRate;

var float AmmoRegenCount;

// Scripted Nametag vars

var ScriptedTexture  ScriptedScreen;
var Shader ShadedScreen;
var Material   ScriptedScreenBack;

//Font/Color/stuff
var Font NameFont;
var font SmallNameFont;                           // Used when the name is to big too fit
var color NameColor;                                // Colors
var Color BackColor;

var float ScreenWeldPercent;
var bool bNoTarget;  // Not close enough to door to get reading
var int FireModeArray;

// Speech
var	bool	bJustStarted;
var	float	LastWeldingMessageTime;
var	float	WeldingMessageDelay;


function byte BestMode()
{
	return 1;
}

simulated function float RateSelf()
{
	return -100;
}

simulated function Destroyed()
{
	Super.Destroyed();
	if( ScriptedScreen!=None )
	{
		ScriptedScreen.SetSize(256,256);
		ScriptedScreen.FallBackMaterial = None;
		ScriptedScreen.Client = None;
		Level.ObjectPool.FreeObject(ScriptedScreen);
		ScriptedScreen = None;
	}
	if( ShadedScreen!=None )
	{
		ShadedScreen.Diffuse = None;
		ShadedScreen.Opacity = None;
		ShadedScreen.SelfIllumination = None;
		ShadedScreen.SelfIlluminationMask = None;
		Level.ObjectPool.FreeObject(ShadedScreen);
		ShadedScreen = None;
		skins[3] = None;
	}
}

// Destroy this stuff when the level changes
simulated function PreTravelCleanUp()
{
	if( ScriptedScreen!=None )
	{
		ScriptedScreen.SetSize(256,256);
		ScriptedScreen.FallBackMaterial = None;
		ScriptedScreen.Client = None;
		Level.ObjectPool.FreeObject(ScriptedScreen);
		ScriptedScreen = None;
	}

	if( ShadedScreen!=None )
	{
		ShadedScreen.Diffuse = None;
		ShadedScreen.Opacity = None;
		ShadedScreen.SelfIllumination = None;
		ShadedScreen.SelfIlluminationMask = None;
		Level.ObjectPool.FreeObject(ShadedScreen);
		ShadedScreen = None;
		skins[3] = None;
	}
}

simulated function InitMaterials()
{
	if( ScriptedScreen==None )
	{
		ScriptedScreen = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
        ScriptedScreen.SetSize(256,256);
		ScriptedScreen.FallBackMaterial = ScriptedScreenBack;
		ScriptedScreen.Client = Self;
	}

	if( ShadedScreen==None )
	{
		ShadedScreen = Shader(Level.ObjectPool.AllocateObject(class'Shader'));
		ShadedScreen.Diffuse = ScriptedScreen;
		ShadedScreen.SelfIllumination = ScriptedScreen;
		skins[3] = ShadedScreen;
	}
}


simulated function float ChargeBar()
{
	return FMin(1, (AmmoAmount(0))/(FireMode[0].AmmoClass.Default.MaxAmmo));
}


simulated event RenderTexture(ScriptedTexture Tex)
{
	local int SizeX,  SizeY;

	Tex.DrawTile(0,0,Tex.USize,Tex.VSize,0,0,256,256,Texture'KillingFloorWeapons.Welder.WelderScreen',BackColor);   // Draws the tile background

	if(!bNoTarget && ScreenWeldPercent > 0 )
	{
		// Err for now go with a name in black letters
		NameColor.R=(255 - (ScreenWeldPercent * 2));
		NameColor.G=(0 + (ScreenWeldPercent * 2.55));
		NameColor.B=(20 + ScreenWeldPercent);
		NameColor.A=255;
		Tex.TextSize(ScreenWeldPercent@"%",NameFont,SizeX,SizeY); // get the size of the players name
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 85,ScreenWeldPercent@"%", NameFont, NameColor);
		Tex.TextSize("Integrity:",NameFont,SizeX,SizeY);
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 50,"Integrity:", NameFont, NameColor);
	}
	else
	{
		NameColor.R=255;
		NameColor.G=255;
		NameColor.B=255;
		NameColor.A=255;
		Tex.TextSize("-",NameFont,SizeX,SizeY); // get the size of the players name
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 85,"-", NameFont, NameColor);
		Tex.TextSize("Integrity:",NameFont,SizeX,SizeY);
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 50,"Integrity:", NameFont, NameColor);
	}
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	bNoTarget =  true;
	if( Level.NetMode==NM_DedicatedServer )
		Return;
}
 ///////////////////////////// 
 /// end copypaste from welder
 ///////////////////////////////

simulated function Tick(float dt)
{
	local KFDoorMover LastDoorHitActor;
	
	if (FireMode[0].bIsFiring)
		FireModeArray = 0;
	else if (FireMode[1].bIsFiring)
		FireModeArray = 1;
	else
		bJustStarted = true;

    //FireModeArray 0 = welding, FireModeArray 1 = unwelding
    //begin welding or unwelding either a player or a door
	if ((WeldFire(FireMode[FireModeArray]).LastHitActor != none && VSize(WeldFire(FireMode[FireModeArray]).LastHitActor.Location - Owner.Location) <= (weaponRange * 1.5) )
	|| AdvancedWelderFire(FireMode[FireModeArray]).CachedHealee != none && VSize(AdvancedWelderFire(FireMode[FireModeArray]).CachedHealee.Location - Owner.Location) <= (weaponRange * 1.5))
	{
		bNoTarget = false;
		LastDoorHitActor = KFDoorMover(WeldFire(FireMode[FireModeArray]).LastHitActor); //stores last door
		
		if(AdvancedWelderFire(FireMode[FireModeArray]).CachedHealee != none)
        {   
            //bWeldingArmor = true;
		    ScreenWeldPercent = AdvancedWelderFire(FireMode[FireModeArray]).CachedHealee.ShieldStrength; //show last welded player integrity
        }
		else
            ScreenWeldPercent = (LastDoorHitActor.WeldStrength / LastDoorHitActor.MaxWeld) * 100; //show last welded door integrity

        if( ScriptedScreen==None )
			InitMaterials();
		ScriptedScreen.Revision++;
		if( ScriptedScreen.Revision>10 )
			ScriptedScreen.Revision = 1;

		if ( Level.Game != none && Level.Game.NumPlayers > 1 && bJustStarted && Level.TimeSeconds - LastWeldingMessageTime > WeldingMessageDelay )
		{
			if ( FireMode[0].bIsFiring )
			{
				bJustStarted = false;
				LastWeldingMessageTime = Level.TimeSeconds;
				if( Instigator != none && Instigator.Controller != none && PlayerController(Instigator.Controller) != none )
				{
				    PlayerController(Instigator.Controller).Speech('AUTO', 0, ""); //I'm welding this doah
				}
			}
			else if ( FireMode[1].bIsFiring )
			{
				bJustStarted = false;
				LastWeldingMessageTime = Level.TimeSeconds;
				if( Instigator != none && Instigator.Controller != none && PlayerController(Instigator.Controller) != none )
				{
				    PlayerController(Instigator.Controller).Speech('AUTO', 1, ""); //I'm unwelding this doah
				}
			}
		}
	}
    //stopped welding either a player or a door
	else if ((AdvancedWelderFire(FireMode[FireModeArray]).LastHitActor == none && AdvancedWelderFire(FireMode[FireModeArray]).CachedHealee == none)
    || WeldFire(FireMode[FireModeArray]).LastHitActor != none && VSize(WeldFire(FireMode[FireModeArray]).LastHitActor.Location - Owner.Location) > (weaponRange * 1.5) && !bNoTarget  )
	{
        //bWeldingArmor = false; //unset my flag
		if( ScriptedScreen==None )
			InitMaterials();
		ScriptedScreen.Revision++;
		if( ScriptedScreen.Revision>10 )
			ScriptedScreen.Revision = 1;
		bNoTarget = true;
		if( ClientState != WS_Hidden && Level.NetMode != NM_DedicatedServer && Instigator != none && Instigator.IsLocallyControlled() )
		{
		  PlayIdle();
		}
	}
    /*
	if ( AmmoAmount(0) < FireMode[0].AmmoClass.Default.MaxAmmo)
	{
		AmmoRegenCount += (dT * AmmoRegenRate );
		ConsumeAmmo(0, -1*(int(AmmoRegenCount)));
		AmmoRegenCount -= int(AmmoRegenCount);
	}
    */
	if ( AmmoAmount(1) < FireMode[1].AmmoClass.Default.MaxAmmo)
	{
		AmmoRegenCount += (dT * AmmoRegenRate );
		ConsumeAmmo(1, -1*(int(AmmoRegenCount)));
		AmmoRegenCount -= int(AmmoRegenCount);
	}
    
}

//overwritten to enable consumption of secondary ammo?
simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
	local Inventory Inv;
	local bool bOutOfAmmo;
	local KFWeapon KFWeap;

	if ( Super.ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
	{
		if ( Load > 0 && (Mode == 0 || bReduceMagAmmoOnSecondaryFire) )
			MagAmmoRemaining--;

		NetUpdateTime = Level.TimeSeconds - 1;

		if ( FireMode[Mode].AmmoPerFire > 0 && InventoryGroup > 0 && !bMeleeWeapon && bConsumesPhysicalAmmo &&
			 (Ammo[0] == none || FireMode[0] == none || FireMode[0].AmmoPerFire <= 0 || Ammo[0].AmmoAmount < FireMode[0].AmmoPerFire) &&
			 (Ammo[1] == none || FireMode[1] == none || FireMode[1].AmmoPerFire <= 0 || Ammo[1].AmmoAmount < FireMode[1].AmmoPerFire) )
		{
			bOutOfAmmo = true;

			for ( Inv = Instigator.Inventory; Inv != none; Inv = Inv.Inventory )
			{
				KFWeap = KFWeapon(Inv);

				if ( Inv.InventoryGroup > 0 && KFWeap != none && !KFWeap.bMeleeWeapon && KFWeap.bConsumesPhysicalAmmo &&
					 ((KFWeap.Ammo[0] != none && KFWeap.FireMode[0] != none && KFWeap.FireMode[0].AmmoPerFire > 0 &&KFWeap.Ammo[0].AmmoAmount >= KFWeap.FireMode[0].AmmoPerFire) ||
					 (KFWeap.Ammo[1] != none && KFWeap.FireMode[1] != none && KFWeap.FireMode[1].AmmoPerFire > 0 && KFWeap.Ammo[1].AmmoAmount >= KFWeap.FireMode[1].AmmoPerFire)) )
				{
					bOutOfAmmo = false;
					break;
				}
			}

			if ( bOutOfAmmo )
			{
				PlayerController(Instigator.Controller).Speech('AUTO', 3, "");
			}
		}

		return true;
	}
	return false;
}



defaultproperties
{
    skins(0)=ColorModifier'ArmorWelder_T.ArmorWelder.ArmorWelder_CM'
    skinrefs(0)="ArmorWelder_T.ArmorWelder.ArmorWelder_CM"

    ScriptedScreenBack=FinalBlend'KillingFloorWeapons.Welder.WelderWindowFinal'
    NameFont=Font'ROFonts.ROBtsrmVr24'//Font'UT2003Fonts.FontLarge'  KFTODO: Replace this
    SmallNameFont=Font'ROFonts.ROBtsrmVr12'//Font'UT2003Fonts.FontSmall' KFTODO: Replace this
    weaponRange=90.000000
    
    Weight=2.000000
    bKFNeverThrow=False
    
    bAmmoHUDAsBar=False
    bShowChargingBar=False
    
    bHasSecondaryAmmo=True
    bReduceMagAmmoOnSecondaryFire=false

    FireModeClass(0)=Class'AdvancedWelderFire'
    FireModeClass(1)=Class'AdvancedWelderAltFire'

    AIRating=-2.000000
    bMeleeWeapon=False
    EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
    Priority=1 //low priority switch
    InventoryGroup=5
    GroupOffset=1
    PickupClass=Class'AdvancedWelderPickup'
    BobDamping=6.000000
    AttachmentClass=Class'AdvancedWelderAttachment'
    IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
    ItemName="Advanced Welder"
    Description="An Advanced Welder that can weld doors, armor and zeds."
    Mesh=SkeletalMesh'KF_Weapons_Trip.Welder_Trip'
    AmbientGlow=2
    BackColor=(R=128,B=128,G=128,A=255)

    DisplayFOV=75.000000
    StandardDisplayFOV=75.0

	HudImage=texture'KillingFloorHUD.WeaponSelect.Welder_unselected'
	SelectedHudImage=texture'KillingFloorHUD.WeaponSelect.Welder'

	WeldingMessageDelay=10.0
	bConsumesPhysicalAmmo=true
    SleeveNum=2
}
