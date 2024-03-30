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
		g_ClassicMode.ForceItemRemap( true );
		
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_balista.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_devastator.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_duality_stinger.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_mprl.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/ver02/weapon_obsidian.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_kez_partner.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_plasma_slayer.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_frostbite.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_seeker.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_amr.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_freedom_machine.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_raptor_sniper.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep2/weapon_commando.txt');
		
		q1_InitCommon();
		
}

void MapActivate()
{
	WeaponCustomMapActivate();
}