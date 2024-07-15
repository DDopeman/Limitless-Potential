#include "kezaeiv/weapon_custom/v9/weapon_custom"
#include "kezaeiv/hl_weapons/weapons"
#include "kezaeiv/hl_weapons/mappings"
#include "HLSPClassicMode"
#include "point_checkpoint"
#include "kezaeiv/kez_movement"


void MapInit()
{
		WeaponCustomMapInit();
		ClassicModeMapInit();
		RegisterClassicWeapons();
		RegisterPointCheckPointEntity();
		g_ItemMappings.insertAt(0, g_ClassicWeapons);
		g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
		g_ClassicMode.ForceItemRemap( true );
		RegisterAutoBhopping();
		
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_amr.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_anvil.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_balista.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_commando.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_devastator.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_duality_stinger.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_ehve.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_freedom_machine.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_frostbite.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_hyper_blaster.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_kez_partner.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_mprl.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_obsidian.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_plasma_slayer.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_prodigy_launcher.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_purifier.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_raptor_sniper.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_seeker.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_survivor.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep4/weapon_shredder.txt');
		
}

void MapActivate()
{
	WeaponCustomMapActivate();
}