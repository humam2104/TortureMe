class TortureSyringeHealingBase extends KFWeap_HealerBase;
		

	
	var float TortureSyringeStandAloneHealAmount;
	var float TortureSyringeOthersHealAmount;
			
	var float TortureSyringeHealSelfRechargeSeconds;
	var float TortureSyringeHealOthersRechargeSeconds;
		
function GetSyringeConfig(){
		TortureSyringeStandAloneHealAmount = 0;
		TortureSyringeOthersHealAmount = 0;
		TortureSyringeHealSelfRechargeSeconds = 15;
		TortureSyringeHealOthersRechargeSeconds = 7.5;		
		`log("*** Torture Syringe Parameters are set successfuly! ***");
}


/**
 * Initializes ammo counts, when weapon is spawned.
 * Overwriting to stop perks changing the magazine size
 * Probably have to add functionality when we add the medic perk
 */
function InitializeAmmo()
{
	GetSyringeConfig();
	// Set ammo amounts based on perk.  MagazineCapacity must be replicated, but
	// only the server needs to know the InitialSpareMags value
	MagazineCapacity[0] = default.MagazineCapacity[0];
	InitialSpareMags[0] = default.InitialSpareMags[0];

	AmmoCount[0] = MagazineCapacity[0];
	AddAmmo(InitialSpareMags[0] * MagazineCapacity[0]);
}

simulated function CustomFire() // Redeclared parent function to replace variables
{
	local float HealAmount;

	if( Role == ROLE_Authority )
	{
		// Healing a teammate
		if( CurrentFireMode == DEFAULT_FIREMODE )
		{
			HealAmount = TortureSyringeOthersHealAmount;															 
			HealTarget.HealDamage( HealAmount, Instigator.Controller, InstantHitDamageTypes[CurrentFireMode]);
			HealRechargeTime = TortureSyringeHealOthersRechargeSeconds;
		}
		// Healing Self
		else if( CurrentFireMode == ALTFIRE_FIREMODE )
		{
			if ( GetActivePlayerCount() < 2 )
			{
				HealAmount = TortureSyringeStandAloneHealAmount; 														// Replaced "StandAloneHealAmount" for solo with my own variable
			}
			else
			{
				HealAmount = TortureSyringeStandAloneHealAmount; 														// Replaced "StandAloneHealAmount" for solo with my own variable
			}
			Instigator.HealDamage(HealAmount, Instigator.Controller, InstantHitDamageTypes[CurrentFireMode]);
			HealRechargeTime = TortureSyringeHealSelfRechargeSeconds; 												// Replaced "HealSelfRechargeSeconds"
		}
	}
}

defaultproperties
{
}

