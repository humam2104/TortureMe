
class TortureMeMut extends KFMutator;
var float JumpZ_Height;
var float TortureHumansTimer;
var class<KFWeapon> TortureHealingSyringe;


function bool IsControllerHuman(PlayerController C)
	{
		if (C.bIsPlayer == false || KFPawn_Human(C.AcknowledgedPawn) == None) //This small check will help loop through all zeds and players quicker
	    		return false;
		else if ( C.bIsPlayer
		        	&& C.PlayerReplicationInfo != none
		        	&& C.PlayerReplicationInfo.bReadyToPlay
		        	&& !C.PlayerReplicationInfo.bOnlySpectator
		        	&& C.GetTeamNum() == 0 ) //Checks for a human player
			        {
			        	return true;
			        }
	}



function bool IsMedicWeaponModded(KFWeap_MedicBase KFW)
	{
		if (KFW.HealAmount == 0)
		{
			`log("Weapon is modded " $ KFW.class.name);
			return true;
		}
		`log("Weapon is NOT modded " $ KFW.class.name);
		return false;
	}


function RemoveHealingAbilities(KFPawn KF_Pawn)
{
		local KFWeap_MedicBase CurKFW_Medic;
		local KFPawn_Human KFPH;

		KFPH = KFPawn_Human(KF_Pawn);
		ForEach KFPH.InvManager.InventoryActors(class'KFWeap_MedicBase', CurKFW_Medic)
		{
			if ( !IsMedicWeaponModded(CurKFW_Medic) )
			{
				CurKFW_Medic.HealAmount = 0;
				`log("Weapon Healing Amount is: " $ CurKFW_Medic.HealAmount);
			}
		}
}



function bool IsFastPerk(KFPerk KFP)
{
	return (KFPerk_Berserker(KFP) != none || KFPerk_FieldMedic(KFP) != none
	 || KFPerk_Gunslinger(KFP) != none || KFPerk_SWAT(KFP) != none && IsSkillActive(KFP,1)
	 || KFPerk_Sharpshooter(KFP) != none && IsSkillActive(KFP,1) );
}


simulated function SetMaxArmor(KFPawn_Human Curpawn,int armor)
{
		local int DeductArmor;
		if(Curpawn != None && Curpawn.MaxArmor != armor)
		{
			DeductArmor = Curpawn.MaxArmor - Curpawn.Armor;
			Curpawn.MaxArmor = armor;
			Curpawn.Armor = armor - DeductArmor;
		}
}	

simulated function SetMaxHP(KFPawn_Human Curpawn,int hp)
{
		local int DeductHP;
		if(Curpawn != None && Curpawn.HealthMax != hp)
		{
			DeductHP = Curpawn.HealthMax - Curpawn.Health;
			Curpawn.HealthMax = hp;
			Curpawn.Health = hp - DeductHP;
		}
}

function float GetDefaultSpeedMultiplier(KFPawn_Human KFPH)
{
	local float SpeedMultiplier;
	SpeedMultiplier = KFPH.default.GroundSpeed/KFPH.GroundSpeed;
	`log("Weapon Speed Modifier is: " $ SpeedMultiplier);
	return SpeedMultiplier;
}

reliable server function SlowDownWeapons(KFPawn KF_Pawn, float SpeedMultiplier,bool RestoreDefaults = false)
	{
		local KFWeapon CurKFW;
		local KFPawn_Human KFPH;

		KFPH = KFPawn_Human(KF_Pawn);
		ForEach KFPH.InvManager.InventoryActors(class'KFWeapon', CurKFW)
		{
			if (CurKFW.MovementSpeedMod == 1 && !RestoreDefaults)
				CurKFW.MovementSpeedMod = SpeedMultiplier;
			else if (RestoreDefaults)
				CurKFW.MovementSpeedMod = 1;

		}
	}

reliable server function RemovePerkSkill(KFPerk CurKFP,byte Skill_1, bool Status = false)
	{
		CurKFP.PerkSkills[Skill_1].bActive = Status;
	}

reliable server function bool IsSkillActive(KFPerk CurKFP,byte Skill_1)
	{
		return CurKFP.PerkSkills[Skill_1].bActive;
	}


function ModifyPlayer(Pawn P) 															 	// Function to modify the player
{
			TortureHumans();
    		SetTimer(TortureHumansTimer, true, nameof(TortureHumans));
}

function TortureHumans()
{
	local KFPerk KFP;
	local PlayerController C;
	local KFPawn_Human KFPH;

	foreach WorldInfo.AllControllers( class'PlayerController', C)
	{
    	if (IsControllerHuman(C))
    	{
    		KFPH = KFPawn_Human(C.AcknowledgedPawn);
    		//One time
    		if (KFPH.JumpZ != JumpZ_Height)
    		{
	    		//Torture All
	    		KFPH.JumpZ = JumpZ_Height;
	    		KFPH.bAllowSprinting = false;
	    		ReplaceSyringe(KFPH);
    		}
    		//Recursive
    		RemoveHealingAbilities(KFPH);
			SetMaxHP(KFPH,100);
			SetMaxArmor(KFPH,100);

    		//Torture Zerk
    		KFP = KFPH.GetPerk();
    		if (KFPerk_Berserker(KFP) != none)
    		{
    			RemovePerkSkill(KFPerk_Berserker(KFP),2);
    		}
    		if ( IsFastPerk(KFP) )
    		{
    			SlowDownWeapons(KFPH,GetDefaultSpeedMultiplier(KFPH));
    		}

    	}
	}
}

function ReplaceSyringe(Pawn P)
	{
		local KFInventoryManager KFIM;
		local KFWeapon OriginalSyringe;
		
		KFIM = KFInventoryManager(KFPawn(P).InvManager);
		
		if (KFIM != none)
		{
				KFIM.GetWeaponFromClass(OriginalSyringe, 'KFWeap_Healer_Syringe'); 					// Assigns the "BabySyringe" name to the original syringe.

				if (TortureHealingSyringe != none) 
				{
					//CreateInventory destroys created item
					KFIM.CreateInventory(TortureHealingSyringe /*, false*/);
					LogInternal("=== TortureSyringe === Added the Torture syringe");
				} 																				// If the real solo syringe doesn't exist, then create it

				if (OriginalSyringe != none)
				{
					KFIM.ServerRemoveFromInventory(OriginalSyringe);
					LogInternal("=== TortureSyringe === Removed Original syringe");
				}

		}
	}



DefaultProperties
{
	TortureHumansTimer = 20.f
	JumpZ_Height = 20.f
	TortureHealingSyringe = class'TortureMe.TortureHealingSyringe'
}


