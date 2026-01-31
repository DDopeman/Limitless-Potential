/* Script for swapping default weapons with classic ones without Classic Mode.
Usage: Add #include "classic_weapons" in the script header
then add CLASSICWEAPONS::Enable() in MapInit in your main map script
-Outerbeast 
Very slightly modified for usage with survival and as generic map script.
-Zorik
*/

#include "point_checkpoint"
//#include "hl_weapons/weapon_hlcrowbar"	mp_dropweapons 0
#include "hl_weapons/weapon_hlmp5"
//#include "hl_weapons/weapon_hlshotgun"	weaponmode_shotgun 1
#include "hl_weapons/weapon_hlpythonv"

void ActivateSurvival(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue){
	g_SurvivalMode.Activate();
}

void DisableSurvival(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue){
	g_SurvivalMode.Disable();
}
void EnableSurvival(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue){
	g_SurvivalMode.Enable(true);
}

namespace CLASSICWEAPONS2{

array<ItemMapping@> CLASSIC_WEAPONS_LIST = 
{
    ItemMapping( "weapon_m16", "weapon_hlmp5" ),
    ItemMapping( "weapon_9mmAR", "weapon_hlmp5" ),
    ItemMapping( "weapon_uzi", "weapon_hlmp5" ),
    ItemMapping( "weapon_uziakimbo", "weapon_hlmp5" ),
    //ItemMapping( "weapon_crowbar", "weapon_hlcrowbar" ),
    //ItemMapping( "weapon_shotgun", "weapon_hlshotgun" ),
    ItemMapping( "ammo_556clip", "ammo_9mmAR" ),
    ItemMapping( "ammo_9mmuziclip", "ammo_9mmAR" ),
    ItemMapping( "weapon_357", "weapon_hlpython" )
};

void Enable()
{
    //RegisterHLCrowbar();
    RegisterHLMP5();
    //RegisterHLShotgun();
    HL_PYTHON2::Register();

    g_ClassicMode.SetItemMappings( @CLASSIC_WEAPONS_LIST );
    g_ClassicMode.ForceItemRemap( true );
    
    g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, ItemSpawned2 );
}    
// World weapon swapper routine (credit to KernCore)
HookReturnCode ItemSpawned2(CBaseEntity@ pOldItem) 
{
    if( pOldItem is null ) 
        return HOOK_CONTINUE;

    for( uint w = 0; w < CLASSIC_WEAPONS_LIST.length(); ++w )
    {
        if( pOldItem.GetClassname() != CLASSIC_WEAPONS_LIST[w].get_From() )
            continue;

        CBaseEntity@ pNewItem = g_EntityFuncs.Create( CLASSIC_WEAPONS_LIST[w].get_To(), pOldItem.GetOrigin(), pOldItem.pev.angles, false );

        if( pNewItem is null ) 
            continue;

        pNewItem.pev.movetype = pOldItem.pev.movetype;

        if( pOldItem.pev.netname != "" )
            pNewItem.pev.netname = pOldItem.pev.netname;

        g_EntityFuncs.Remove( pOldItem );
        
    }
    
    return HOOK_CONTINUE;
}
}
void MapInit(){
	g_Module.ScriptInfo.SetAuthor("Outerbeast, Kerncore, very slightly modified by Zorik");
	g_Module.ScriptInfo.SetContactInfo("Sneed");
	RegisterPointCheckPointEntity();
	CLASSICWEAPONS2::Enable();
}