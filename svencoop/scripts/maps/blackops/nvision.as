namespace NightVision
{

enum nvmodes
{
	NVMODE_FLASHLIGHT_ONLY = -1,
	NVMODE_OFF,
	NVMODE_ON
};

enum light_position
{
	CENTER = 0,
	EYE,
	EAR
};

bool blEnabled;

int
	iRadius 		= 42,
	iLife			= 3,
	iDecay 			= 2,
	iBrightness 	= 64,
	iFadeAlpha 		= 64,
	iPosition 		= EYE,
	iNVModeDefault 	= NVMODE_OFF;

float
	flVolume			= 0.8f,
	flFadeTime 			= 0.01f,
	flFadeHold 			= 0.5f;

Vector vecNVColor;
const Vector NV_GREEN( 0, 255, 0 ), NV_RED( 255, 0, 0 );

string szSndHudNV = "player/hud_nightvision.wav", szSndFLight = "items/flashlight2.wav";

CClientCommand@ cmdNVSetMode;

array<int> I_NV_PLAYERS;

void Precache()
{
	g_SoundSystem.PrecacheSound( szSndHudNV );
	g_SoundSystem.PrecacheSound( szSndFLight );
}

void Enable(Vector vecNVColorIn = NV_GREEN, string strEnabledMaps = "")
{
	if( blEnabled )
		return;

	if( strEnabledMaps != "" )
	{
		if( strEnabledMaps.Split( ";" ).find( g_Engine.mapname ) < 0 )
			return;
	}

	Precache();

	vecNVColor = vecNVColorIn != g_vecZero ? vecNVColorIn : NV_GREEN;

	I_NV_PLAYERS = array<int>( g_Engine.maxClients + 1, iNVModeDefault );

	blEnabled = g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, PlayerJoinLeave ) &&
				g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, PlayerJoinLeave ) &&
				g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilled	) &&
				g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerPostThink );

	if( blEnabled )
		@cmdNVSetMode = CClientCommand( "nvision_mode", "Toggles night vision on/off", NVSetMode );
}

void nvOn(EHandle hPlayer) 
{
	if( !hPlayer )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

	if( pPlayer is null || I_NV_PLAYERS[pPlayer.entindex()] == NVMODE_FLASHLIGHT_ONLY )
		return;

	if( I_NV_PLAYERS[pPlayer.entindex()] == NVMODE_OFF ) 
	{
		I_NV_PLAYERS[pPlayer.entindex()] = NVMODE_ON;
		g_PlayerFuncs.ScreenFade( pPlayer, vecNVColor, flFadeTime, flFadeHold, iFadeAlpha, FFADE_OUT | FFADE_STAYOUT );
		g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, szSndHudNV, flVolume, ATTN_NORM, 0, PITCH_NORM );
	}

	Vector vecSrc; 

	switch( iPosition )
	{
		case CENTER:
			vecSrc = pPlayer.Center();
			break;
		
		case EYE:
			vecSrc = pPlayer.EyePosition();
			break;

		case EAR:
			vecSrc = pPlayer.EarPosition();
			break;

		default:
			vecSrc = pPlayer.GetOrigin();
	}

	NetworkMessage netMsg( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
		netMsg.WriteByte( TE_DLIGHT );
		netMsg.WriteCoord( vecSrc.x );
		netMsg.WriteCoord( vecSrc.y );
		netMsg.WriteCoord( vecSrc.z );

		netMsg.WriteByte( iRadius );
		netMsg.WriteByte( int( vecNVColor.x ) );
		netMsg.WriteByte( int( vecNVColor.y ) );
		netMsg.WriteByte( int( vecNVColor.z ) );

		netMsg.WriteByte( iLife );
		netMsg.WriteByte( iDecay );
	netMsg.End();
}

void nvOff(EHandle hPlayer)
{
	if( !hPlayer )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

	if( pPlayer is null )
		return;
	
	if( I_NV_PLAYERS[pPlayer.entindex()] == NVMODE_ON )
	{
		g_PlayerFuncs.ScreenFade( pPlayer, vecNVColor, flFadeTime, flFadeHold, iFadeAlpha, FFADE_IN );
		g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, szSndFLight, flVolume, ATTN_NORM, 0, PITCH_NORM );
		I_NV_PLAYERS[pPlayer.entindex()] = NVMODE_OFF;
	}
}

HookReturnCode PlayerJoinLeave(CBasePlayer@ pPlayer)
{
	if( pPlayer !is null )
		nvOff( pPlayer );

	return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
{
	if( pPlayer !is null )
		nvOff( pPlayer );

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPostThink(CBasePlayer@ pPlayer)
{
	if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;

	if( pPlayer.FlashlightIsOn() )
		nvOn( pPlayer );
	else
		nvOff( pPlayer );

	return HOOK_CONTINUE;
}

void NVSetMode(const CCommand@ cmdArgs)
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if( cmdArgs.ArgC() != 1 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "It's just ''nvision_mode'' to switch between nightvision and normal flashlight.\n" );
		return;
	}

	I_NV_PLAYERS[pPlayer.entindex()] = I_NV_PLAYERS[pPlayer.entindex()] == NVMODE_FLASHLIGHT_ONLY ? NVMODE_OFF : NVMODE_FLASHLIGHT_ONLY;

	switch( I_NV_PLAYERS[pPlayer.entindex()] )
	{
		case NVMODE_FLASHLIGHT_ONLY:
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "NightVision mode set to: flashlight only\n" );
			break;

		case NVMODE_OFF:
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "NightVision mode set to: night vision\n" );
			break;
	}
}

void Disable()
{
	if( !blEnabled )
		return;

	I_NV_PLAYERS = array<int>( g_Engine.maxClients + 1, iNVModeDefault );
	@cmdNVSetMode = null;
	
	g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, PlayerJoinLeave );
	g_Hooks.RemoveHook( Hooks::Player::ClientDisconnect, PlayerJoinLeave );
	g_Hooks.RemoveHook( Hooks::Player::PlayerKilled, PlayerKilled );
	g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, PlayerPostThink );

	blEnabled = false;
}

}
