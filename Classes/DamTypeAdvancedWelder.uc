class DamTypeAdvancedWelder extends DamTypeWelder
	abstract;

defaultproperties
{
     WeaponClass=Class'AdvancedWelder.AdvancedWelder'
     DeathString="ÿ%k welded %o (Advanced Welder)."
     FemaleSuicide="%o was welded."
     MaleSuicide="%o was welded."
     
     //bDealBurningDamage=true
     
     bRagdollBullet=True
     bBulletHit=True
     FlashFog=(X=600.000000)
     KDamageImpulse=1000.000000
     VehicleDamageScaling=0.800000
}