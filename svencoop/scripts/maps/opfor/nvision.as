/*
* |=========================================================================|
* | O P P O S I N G  F O R C E   N I G H T  V I S I O N                     |
* | Author: Neo (SC, Discord),  Version V 1.4b, May, 14th 2021              |
* |=========================================================================|
* |This map script enables the Opposing Force style NightVision             |
* |view mode, which can used with standard flash light key.                 |
* |=========================================================================|
* |Map script install instructions:                                         |
* |-------------------------------------------------------------------------|
* |1. Extract the map script 'scripts/maps/nvision.as'                      |
* |                       to 'svencoop_addon/scripts/maps'.                 |
* |-------------------------------------------------------------------------|
* |2. Add to main map script the following code:                            |
* |                                                                         |
* | (a) #include "opfor/nvision"                                            |
* |                                                                         |
* | (b) in function 'MapInit()':                                            |
* |     NightVision::Enable();                                              |
* |                                                                         |
* | (c) To change color put your rgb values in like this:                   |
* |		NightVision::Enable( Vector(0,255,0) )                              |
* |=========================================================================|
* |Usage of OF NightVision:                                                 |
* |-------------------------------------------------------------------------|
* |Simply use standard flash light key to switch the                        |
* |OF NightVision view mode on and off                                      |
* |=========================================================================|
*/
namespace NightVision
{

enum light_position
{
	CENTER = 0,
	EYE,
	EAR
}

int	iRadius 	= 42;
int	iLife		= 2;
int	iDecay 		= 1;
int	iBrightness = 64;
int	iFadeAlpha 	= 64;
int	iPosition 	= CENTER;

float  fInterval 	= 0.05f;
float  flVolume 	= 0.8f;
float  flFadeTime 	= 0.01f;
float  flFadeHold 	= 0.5f;

Vector vec_NVColor;
const Vector NV_GREEN( 0, 255, 0 );
const Vector NV_RED( 255, 0, 0 );

string szSndHudNV  = "player/hud_nightvision.wav";
string szSndFLight = "items/flashlight2.wav";

dictionary nvPlayer;

void Enable(Vector vec_NVColorIn = NV_GREEN)
{
	if( vec_NVColorIn != g_vecZero )
		vec_NVColor = vec_NVColorIn;
	else
		vec_NVColor = NV_GREEN;

	g_SoundSystem.PrecacheSound(szSndHudNV);
	g_SoundSystem.PrecacheSound(szSndFLight);

	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @NVPlayerClient);
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,  @NVPlayerClient);
	g_Hooks.RegisterHook(Hooks::Player::PlayerKilled,      @NVPlayerKilled);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink,  @NVPlayerPostThink);
}

void nvOn(EHandle hPlayer) 
{
	if( !hPlayer )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

	if(!nvPlayer.exists(szSteamId)) 
	{
		nvPlayer[szSteamId] = true;
		g_PlayerFuncs.ScreenFade( pPlayer, vec_NVColor, flFadeTime, flFadeHold, iFadeAlpha, FFADE_OUT | FFADE_STAYOUT);
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
		netMsg.WriteByte( int(vec_NVColor.x) );
		netMsg.WriteByte( int(vec_NVColor.y) );
		netMsg.WriteByte( int(vec_NVColor.z) );
		netMsg.WriteByte( iLife );
		netMsg.WriteByte( iDecay );
	netMsg.End();
}

void nvOff(EHandle hPlayer)
{
	if( !hPlayer )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	
	if(nvPlayer.exists(szSteamId))
	{
		g_PlayerFuncs.ScreenFade( pPlayer, vec_NVColor, flFadeTime, flFadeHold, iFadeAlpha, FFADE_IN);
		g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, szSndFLight, flVolume, ATTN_NORM, 0, PITCH_NORM );
		nvPlayer.delete(szSteamId);
	}
}

HookReturnCode NVPlayerClient(CBasePlayer@ pPlayer)
{
	if(pPlayer !is null)
		nvOff(pPlayer);

	return HOOK_CONTINUE;
}

HookReturnCode NVPlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
{
	if(pPlayer !is null)
		nvOff(pPlayer);

	return HOOK_CONTINUE;
}

HookReturnCode NVPlayerPostThink(CBasePlayer@ pPlayer)
{
	if ( pPlayer !is null and pPlayer.IsConnected() and pPlayer.IsAlive())
	{
		if(pPlayer.FlashlightIsOn())
			nvOn(pPlayer);
		else
			nvOff(pPlayer);
	}
	return HOOK_CONTINUE;
}

}
