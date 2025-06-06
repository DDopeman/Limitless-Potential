#include "kezaeiv/w00tguy/v9/weapon_custom"
#include "HLSPClassicMode"
#include "point_checkpoint"


void MapInit()
{
		WeaponCustomMapInit();
		ClassicModeMapInit();
		RegisterPointCheckPointEntity();
		g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
		
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_amr.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_anvil.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_balista.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_bonecracker.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_commando.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_devastator.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_duality_stinger.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_ehve.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_freedom_machine.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_frostbite.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_hyper_blaster.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_kz_annihilator.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_kz_purifier.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_mprl.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_obsidian.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_pt808.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_raptor.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_sbc.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_schofield.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_seeker.txt');
		g_Game.PrecacheGeneric('sprites/singularity/c_wep/weapon_xl2.txt');
		
}

void MapActivate()
{
	WeaponCustomMapActivate();
}
