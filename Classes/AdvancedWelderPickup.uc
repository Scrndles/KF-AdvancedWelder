class AdvancedWelderPickup extends KFWeaponPickup;

//obj load
#exec OBJ LOAD FILE=ArmorWelder_T.utx

defaultproperties
{
     Weight=2.000000
     cost=200
     AmmoCost=40
     BuyClipSize=10
     PowerValue=55
     SpeedValue=80
     RangeValue=30
     AmmoItemName="Weldy ammo"
     AmmoAmount=50 //initial ammo on pickup
     SecondaryAmmoShortName="W"
     AmmoMesh=StaticMesh'KillingFloorStatics.L85Ammo'
     CorrespondingPerkIndex=1
     EquipmentCategoryID=3
     InventoryType=Class'AdvancedWelder'
     Description="An Advanced Welder that can weld doors, armor and zeds."
     PickupMessage="You got the Advanced Welder."
     PickupSound=Sound'Inf_Weapons_Foley.AmmoPickup'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KF_pickups_Trip.welder_pickup'
     CollisionHeight=5.000000
     ItemName="Advanced Welder"
     ItemShortName="Advanced Welder"
}
