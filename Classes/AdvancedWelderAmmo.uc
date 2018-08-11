class AdvancedWelderAmmo extends KFAmmunition;
/*
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
    {
        MaxAmmo = default.MaxAmmo * 2 * KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetWeldSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo));
    }
}
*/
defaultproperties
{
     MaxAmmo=100
     InitialAmount=25
     AmmoPickupAmount=25
     PickupClass=Class'AdvancedWelderAmmoPickup'
     IconMaterial=Texture'KillingFloorHUD.Generic.HUD'
     IconCoords=(X1=4,Y1=350,X2=110,Y2=395)
     ItemName="Welder Fuel.."
}
