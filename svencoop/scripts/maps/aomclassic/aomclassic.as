// Afraid of Monsters Classic Script
// Main Script
// Author: Zorbos
// Weapons are NOT allowed to be given on these maps
const array<string> AOM_LIST_NOWEAPON = {"aom_training", "aom_intro", "aom_nightmare", "aom_end"};
										 
// Map List
// Array indices are used as a means of deciding which maps are farther than others.
// Used for giving out weapons and ammo to the player.
const array<string> AOM_LIST_MAPS = {"aom_hospital", "aom_hospital2", "aom_garage", "aom_backalley",
								     "aom_darkalley", "aom_city", "aom_city2", "aom_city3", "aom_sick", "aom_sick2",
									 "aom_sick3", "aom_forest", "aom_forhouse", "aom_forest2", "aom_forest3",
									 "aom_heaven1", "aom_heaven2"};

#include "weapon_clak47"
#include "weapon_clberetta"
#include "weapon_cldeagle"
#include "weapon_clknife"
#include "weapon_clshotgun"
#include "../point_checkpoint"
#include "ammo_clshotgun"
#include "attachkeyspr"

CScheduledFunction@ interval;

void MapInit()
{ 
	// Register weapons
	RegisterCLAK47();
	RegisterCLBeretta();
	RegisterCLDeagle();
	RegisterCLKnife();
	RegisterCLShotgun();
	RegisterPointCheckPointEntity();
	g_EngineFuncs.CVarSetFloat( "mp_classicmode", 0 );
	
	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_clshotgun", "ammo_clshotgun" );
	
	// Hooks
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	
	// Parsers
	g_Scheduler.SetTimeout("CheckSurvival", 0.025);
}

void CheckSurvival()
{
	bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	
	const array<string> RemoveTargetnamesSurvivalOn = {"mm_checkpoint1", "mm_checkpoint2", "checkpoint_spr1", "checkpoint_spr2", "checkpoint_txt", "spr_checkpoint1", "spr_checkpoint2"};
	const array<string> RemoveTargetnamesSurvivalOff = {"start_block", "relay_init_map"};
	
	edict_t@ pEdict = null;
	CBaseEntity@ pEntity = null;
	
	for( int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex )
	{
		@pEdict = @g_EntityFuncs.IndexEnt(pIndex);
		@pEntity = g_EntityFuncs.Instance(pEdict);
		
		if( pEntity !is null )
		{		
			if(bSurvivalEnabled) // Remove non-survival entities (checkpoints)
			{
				if(RemoveTargetnamesSurvivalOn.find(pEntity.pev.targetname) >= 0)
					g_EntityFuncs.Remove(pEntity);
					
				g_EntityFuncs.FireTargets("relay_survivalenabled", null, null, USE_ON, 0, 0);
			}
			else // Remove survival checkpoints and entities
			{
				if(RemoveTargetnamesSurvivalOff.find(pEntity.pev.targetname) >= 0 ||
				   pEntity.GetClassname() == "point_checkpoint" || pEntity.pev.globalname == "survival_weapons")
					g_EntityFuncs.Remove(pEntity);
				
				g_EntityFuncs.FireTargets("relay_survivaldisabled", null, null, USE_ON, 0, 0);
			}
		}
	}
}

// Equips players with a weapon if they do not already possess one in a respective slot
void EquipPlayer(CBasePlayer@ pPlayer)
{
	string currentMap = g_Engine.mapname;
	
	if(AOM_LIST_NOWEAPON.find(currentMap) < 0) // Is this map a map that we should give weapons on?
	{
		bool bPlayerHasMelee = pPlayer.HasNamedPlayerItem("weapon_clknife") !is null;
		bool bPlayerHasPistol = pPlayer.HasNamedPlayerItem("weapon_clberetta") !is null;
		bool bPlayerHasShotgun = pPlayer.HasNamedPlayerItem("weapon_clshotgun") !is null;
		bool bPlayerHasAK47 = pPlayer.HasNamedPlayerItem("weapon_clak47") !is null;
		bool bPlayerHasMagnum = pPlayer.HasNamedPlayerItem("weapon_cldeagle") !is null;
		
		// Only start giving the knife/beretta after the first map it naturally occurs in
		bool bCanGiveMelee = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find("aom_hospital");
		
		// Only start giving the shotgun after the first map it naturally occurs in
		bool bCanGiveShotgun = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find("aom_hospital2");
		
		// Only start giving the ak47 after the first map it naturally occurs in
		bool bCanGiveAK47 = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find("aom_city3");
		
		// Only start giving the deagle after the first map it naturally occurs in		
		bool bCanGiveMagnum = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find("aom_backalley");
		
		if(!bPlayerHasMelee) // Does the player have a melee weapon already?
			if(bCanGiveMelee)
				pPlayer.GiveNamedItem("weapon_clknife");
			
		if(!bPlayerHasPistol) // Does the player have a pistol already?
			if(bCanGiveMelee)
				pPlayer.GiveNamedItem("weapon_clberetta");
			
		if(!bPlayerHasShotgun) // Does the player have a shotgun already?
			if(bCanGiveShotgun)
				pPlayer.GiveNamedItem("weapon_clshotgun");
				
		if(!bPlayerHasAK47) // Does the player have an ak47 already?
			if(bCanGiveAK47)
				pPlayer.GiveNamedItem("weapon_clak47");
			
		if(!bPlayerHasMagnum) // Does the player have a magnum already?
			if(bCanGiveMagnum)
				pPlayer.GiveNamedItem("weapon_cldeagle");
				
		// Get player reserve ammo amounts		
		int m_iReserve9mm = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("9mm"));
		int m_iReserveBuckshot = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"));
		int m_iReserve357 = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("357"));
	
		// Give ammo if necessary (is ammo low enough and are we on a map that needs this ammo?)
		if(m_iReserve9mm < 65 && bCanGiveMelee)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("9mm"), 65); // Set the ammo amounts
		if(m_iReserveBuckshot < 12 && bCanGiveShotgun)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"), 12);
		if(m_iReserve357 < 6 && bCanGiveMagnum)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("357"), 6);
	}
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{
	EquipPlayer(pPlayer);
	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	g_Scheduler.RemoveTimer(interval);
	return HOOK_CONTINUE;
}