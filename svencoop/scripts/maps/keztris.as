#include "kezaeiv/weapon_custom/v9/weapon_custom"
#include "kezaeiv/weapon_destroyer"
#include "LimitlessPotential/point_checkpoint"
#include "kezaeiv/sentrymk"


namespace kezaeiv {

	void MapInit()
	{
		WeaponCustomMapInit();
		RegisterDestroyer();
		
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_balista.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_devastator.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_duality_stinger.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_hyper_blaster.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_mprl.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_obsidian.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_prodigy_launcher.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_shredder.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_kez_partner.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_plasma_slayer.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_anvil.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_destroyer.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_frostbite.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_factory.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_deagle_mk9.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_seeker.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_survivor.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_amr.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_freedom_machine.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_raptor_sniper.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_purifier.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_ehve.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_commando.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_swarm.txt');
		g_Game.PrecacheGeneric('sprites/kezaeiv/c_wep/weapon_modified_frag_grenade.txt');
	}

	void MapActivate()
	{
		WeaponCustomMapActivate();
	}
}