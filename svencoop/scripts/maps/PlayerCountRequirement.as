/*
*	This script implements a class that enforces a minimum player count.
* 	If the player count is below MinimumPlayersRequired, all players are frozen.
*	If the player count is equal to or higher than MinimumPlayersRequired, all players are unfrozen.
*
*	Note: certain entities will unfreeze players, like trigger_camera with the freeze player flag set.
*	Be careful not to allow such entities to activate while players are frozen by this, or vice versa.
*
*	Usage: instantiate this class, set MinimumPlayersRequired to a positive value to enforce requirements.
*	In practice, only values higher than 1 have any effect.
*
*	PlayerCountRequirement g_PlayerCountRequirement;
*
*	void MapInit()
*	{
*		g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, "ClientPutInServer" );
*		g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, "ClientDisconnect" );
*	
*		g_PlayerCountRequirement.MinimumPlayersRequired = 2;
*	}
*	
*	HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
*	{
*		g_PlayerCountRequirement.PlayerJoined();
*		
*		return HOOK_CONTINUE;
*	}
*	
*	HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
*	{
*		g_PlayerCountRequirement.PlayerLeft();
*		
*		return HOOK_CONTINUE;
*	}
*/

class PlayerCountRequirement
{
	private int m_iMinimumPlayersRequired = 0;
	
	int MinimumPlayersRequired
	{
		get const { return m_iMinimumPlayersRequired; }
		set { m_iMinimumPlayersRequired = Math.max( value, 0 ); }	//Clamp to positive value
	}
	
	void PlayerJoined()
	{
		CheckConditions( false );
	}
	
	void PlayerLeft()
	{
		CheckConditions( true );
	}
	
	private void CheckConditions( bool fPlayerLeft )
	{
		if( fPlayerLeft && g_PlayerFuncs.GetNumPlayers() == MinimumPlayersRequired )
		{
			for( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
			{
				CBasePlayer@ pSomePlayer = g_PlayerFuncs.FindPlayerByIndex( iIndex );
				
				if( pSomePlayer !is null )
					pSomePlayer.pev.flags &= ~FL_FROZEN;
			}
		}
		else if( g_PlayerFuncs.GetNumPlayers() < MinimumPlayersRequired )
		{
			for( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
			{
				CBasePlayer@ pSomePlayer = g_PlayerFuncs.FindPlayerByIndex( iIndex );
				
				if( pSomePlayer !is null )
					pSomePlayer.pev.flags |= FL_FROZEN;
			}
		}
	}
}