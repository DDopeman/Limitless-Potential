CCVar simulated_player_count( "simulated_player_count", -1, "Pretend that there's this number of alive players for trigger_check_playercount");

const int FEW_PLAYERS = 2;
const int MANY_PLAYERS = 4;

namespace FI_DynDiff
{
	int CountAlivePlayers()
	{
		int alivePlayers = 0;
		for (int i = 1; i <= g_Engine.maxClients; i++) {
			CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(i);
			if (player is null or !player.IsConnected())
				continue;
			if (player.IsAlive())
			{
				alivePlayers++;
			}
		}
		return alivePlayers;
	}

	int PercievedPlayerCount()
	{
		const int simulatedCount = simulated_player_count.GetInt();
		if (simulatedCount >=0 )
		{
			return simulatedCount;
		}
		else
		{
			return (g_SurvivalMode.IsEnabled() ? CountAlivePlayers() : 32); // Pretend there're always a lot of alive players in non-survival mode.
		}
	}
}

class trigger_check_playercount : ScriptBaseEntity
{
	string onManyPlayers;
	string onFewPlayers;
	string onSinglePlayer;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "on_many_players")
		{
			onManyPlayers = szValue;
			return true;
		}
		else if (szKey == "on_few_players")
		{
			onFewPlayers = szValue;
			return true;
		}
		else if (szKey == "on_single_player")
		{
			onSinglePlayer = szValue;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey,szValue );
	}
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value = 0.0f )
	{
		const int percievedCount = FI_DynDiff::PercievedPlayerCount();
		if (percievedCount >= MANY_PLAYERS && onManyPlayers != "")
		{
			g_EntityFuncs.FireTargets(onManyPlayers, pActivator, self, USE_TOGGLE);
		}
		else if (percievedCount >= FEW_PLAYERS)
		{
			if (onFewPlayers != "")
				g_EntityFuncs.FireTargets(onFewPlayers, pActivator, self, USE_TOGGLE);
		}
		else if (percievedCount == 1)
		{
			if (onSinglePlayer != "")
				g_EntityFuncs.FireTargets(onSinglePlayer, pActivator, self, USE_TOGGLE);
		}
	}
}

enum PlayerAmountRequirement
{
	ANY_PLAYER_COUNT = 0,
	FEW_PLAYERS_AT_LEAST = 1,
	MANY_PLAYERS_REQUIRED = 2,
};

class dyndiff_squadmaker : ScriptBaseEntity
{
	private dictionary g_KeyValueData; // Save all keyvalue data for later usage
	private int m_amountRequirement = FEW_PLAYERS_AT_LEAST;
	private string functionName;
	private bool CanSpawn()
	{
		const int percievedCount = FI_DynDiff::PercievedPlayerCount();
		int requiredAmount = 1;
		if (m_amountRequirement == FEW_PLAYERS_AT_LEAST)
			requiredAmount = FEW_PLAYERS;
		else if (m_amountRequirement == MANY_PLAYERS_REQUIRED)
			requiredAmount = MANY_PLAYERS;
		return percievedCount >= requiredAmount;
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_amountRequirement" )
		{
			m_amountRequirement = atoi( szValue );
		}
		else
		{
			g_KeyValueData[ szKey ] = szValue;
		}

		if( szKey == "monstertype" )
		{
			g_Game.PrecacheOther( szValue );
		}

		return true;
	}

	void Spawn()
	{
		pev.movetype	= MOVETYPE_NONE;
		pev.solid		= SOLID_NOT;

		// Store entvars as well
		g_KeyValueData[ "angles" ]			= pev.angles.ToString().Replace( ",", "" );
		g_KeyValueData[ "origin" ]			= pev.origin.ToString().Replace( ",", "" );
		g_KeyValueData[ "rendercolor" ]		= pev.rendercolor.ToString().Replace( ",", "" );
		g_KeyValueData[ "spawnflags" ]		= string( pev.spawnflags );
		g_KeyValueData[ "target" ]			= string( pev.target );
		g_KeyValueData[ "targetname" ]		= string( pev.classname );
		g_KeyValueData[ "rendermode" ]		= string( pev.rendermode );
		g_KeyValueData[ "renderamt" ]		= string( pev.renderamt );
		g_KeyValueData[ "renderfx" ]		= string( pev.renderfx );
		g_KeyValueData[ "netname" ]			= string( pev.netname );
		g_KeyValueData[ "weapons" ]			= string( pev.weapons );
		g_KeyValueData[ "health" ]			= string( pev.health );

		BaseClass.Spawn();
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( CanSpawn() )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "squadmaker", g_KeyValueData );

			if( pEntity !is null )
			{
				g_EntityFuncs.SetOrigin( pEntity, pev.origin );
				pEntity.Use( pActivator, self, USE_TOGGLE, 0.0 );
			}
		}
		self.SUB_Remove();
	}
}
