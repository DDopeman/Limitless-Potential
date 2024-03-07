#include "kezaeiv/weapon_custom/v9/weapon_custom"
#include "kezaeiv/quake1/common"
#include "kezaeiv/hl_weapons/weapons"
#include "kezaeiv/hl_weapons/mappings"
#include "HLSPClassicMode"
#include "point_checkpoint"


void MapInit()
{
		WeaponCustomMapInit();
		ClassicModeMapInit();
		RegisterClassicWeapons();
		RegisterPointCheckPointEntity();
		g_ItemMappings.insertAt(0, g_ClassicWeapons);
		g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
		
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_balista.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_devastator.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_duality_stinger.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_mprl.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_obsidian.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_kez_partner.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_plasma_slayer.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_frostbite.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_seeker.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_amr.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_freedom_machine.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_raptor_sniper.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_commando.txt');
		
		q1_InitCommon();
		
}

void MapActivate()
{
	WeaponCustomMapActivate();
}