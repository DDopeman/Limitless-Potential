#include "kezaeiv/w00tguy/v9/weapon_custom"
#include "HLSPClassicMode"
#include "point_checkpoint"
#include "kezaeiv/autohop_playeruse"


void MapInit()
{
		WeaponCustomMapInit();
		ClassicModeMapInit();
		RegisterPointCheckPointEntity();
		g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
		RegisterAutoBhopping();
		
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_amr.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_anvil.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_balista.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_commando.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_devastator.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_duality_stinger.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_ehve.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_freedom_machine.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_frostbite.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_hyper_blaster.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_kez_partner.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_mprl.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_obsidian.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_plasma_slayer.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_prodigy_launcher.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_purifier.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_raptor_sniper.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_seeker.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_survivor.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_shredder.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep5/weapon_xl4.txt');
		
}

void MapActivate()
{
	WeaponCustomMapActivate();
}