/*
* Field Intensity
* Main script file
*/

#include "point_checkpoint"

#include "env_energy_ball_trap"
#include "env_extinguisher"
#include "env_model"
#include "env_render_pulse"
#include "env_shockwave"
#include "env_sprite_attached"
//#include "env_state"
#include "env_stompshooter"
#include "func_breakable_effect"
#include "info_entity_hint"
#include "item_eyescanner"
#include "locus_beam"
#include "trigger_check_playercount"
#include "trigger_timer"

#include "monster_floater"
#include "monster_alien_slave_fi"
#include "weapon_knife"
#include "weapon_penguin"

#include "dead_monsters"
#include "warpball"

void MapInit()
{
	// Batteries and rechargers give less armor
	g_EngineFuncs.CVarSetString("sk_battery", "20");
	g_EngineFuncs.CVarSetString("sk_suitcharger", "80");
	
	g_EngineFuncs.CVarSetFloat( "mp_classicmode", 0 );

	PrecacheWarpballResources();
	g_CustomEntityFuncs.RegisterCustomEntity( "env_energy_ball_trap", "env_energy_ball_trap" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_extinguisher", "env_extinguisher" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_model_spirit", "env_model_spirit" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_render_pulse", "env_render_pulse" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_shockwave", "env_shockwave" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_sprite_attached", "env_sprite_attached" );
	//g_CustomEntityFuncs.RegisterCustomEntity( "env_state", "env_state" ); // not working!
	g_CustomEntityFuncs.RegisterCustomEntity( "env_stompshooter", "env_stompshooter" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_teleport_effect", "env_teleport_effect" );
	g_CustomEntityFuncs.RegisterCustomEntity( "func_breakable_effect", "func_breakable_effect" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_eyescanner", "item_eyescanner" );
	g_CustomEntityFuncs.RegisterCustomEntity( "calc_position", "calc_position" );
	g_CustomEntityFuncs.RegisterCustomEntity( "locus_beam", "locus_beam" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_timer", "trigger_timer" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_check_playercount", "trigger_check_playercount" );
	g_CustomEntityFuncs.RegisterCustomEntity( "dyndiff_squadmaker", "dyndiff_squadmaker" );
	//g_CustomEntityFuncs.RegisterCustomEntity( "info_entity_hint", "info_entity_hint" );
	CPenguin::Register();
	RegisterKnife(true);
	FIDeadMonsters::Register();
	FIFlockingFloater::Register();
	FIVortigaunt::Register();

	RegisterPointCheckPointEntity();
	g_SurvivalMode.EnableMapSupport();
}


// Set items to not respawn in survival mode
// NOTE: This won't reset the cvars if the mode was changed by players vote during the game!
void CheckAndSetupSurvivalMode()
{
	g_Game.AlertMessage(at_console, "Survival mode is %1\n", g_SurvivalMode.IsEnabled() ? "enabled" : "disabled");
	if (g_SurvivalMode.IsEnabled())
	{
		g_Game.AlertMessage(at_console, "Setting cvars and behaviors for survival mode\n");
		g_EngineFuncs.CVarSetString("mp_ammo_respawndelay", "-1");
		g_EngineFuncs.CVarSetString("mp_item_respawndelay", "-1");
		g_EngineFuncs.CVarSetString("mp_weapon_respawndelay", "86400");
		g_EngineFuncs.CVarSetString("mp_weaponfadedelay", "300");

		const array<string> rechargers = {"func_recharge", "func_healthcharger"};
		for (uint i=0; i<rechargers.length(); ++i)
		{
			CBaseEntity@ pEntity = null;
			while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, rechargers[i] ) ) !is null)
			{
				g_EntityFuncs.DispatchKeyValue(pEntity.edict(), "CustomRechargeTime", "86400");
			}
		}
	}
}

void MapActivate()
{
	// NOTE: We want to check whether the survival mode is enabled but it's not fully initialized at the map start. So we have to wait.
	g_Scheduler.SetTimeout( "CheckAndSetupSurvivalMode", 1 );

	FIVortigaunt::MapActivate();
}
