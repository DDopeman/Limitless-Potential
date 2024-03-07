#include "trigger_observer_proto_20220918"

/* stfu_and_climb map script
By Meryilla

This script is only required as item effects e.g. invulnerability do not appear to continue after the player respawns
Here we provide players with a bunch of hp after respawning if they have the end ball

*/

void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerSpawn );
	TriggerObserver::Init();
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;
	
	InventoryList@ invPlayer = pPlayer.get_m_pInventory();
	
	while( invPlayer !is null )
	{
		CItemInventory@ pInventoryItem = cast<CItemInventory@>( invPlayer.hItem.GetEntity() );
		if( pInventoryItem !is null && string( pInventoryItem.m_szItemName ) == "ball" )
		{
			pPlayer.pev.health = 9999999999.0;
			pPlayer.pev.max_health = 9999999999.0;
			break;
		}
		@invPlayer = @invPlayer.pNext;
	}
	
	return HOOK_CONTINUE;
}