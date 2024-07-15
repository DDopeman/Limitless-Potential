/*
* They Hunger: Escape (th_escape)
* Custom HUD
*
* Created by Tomas "GeckoN" Slavotinek
*/

namespace CustomHUD
{

enum ITEM_TYPE
{
	ITEM_BATTERY = 0,
	ITEM_GASCAN,
	ITEM_TOOLBOX,
	
	NUM_ITEMS
}

array<string> g_itemName =
{
	"item_battery",
	"item_gascan",
	"item_toolbox"
};

const int SPR_SIZE = 48;
const int SPR_SEPARATOR = 28;

array<Vector2D> g_itemPos =
{
	Vector2D( 0, -( SPR_SIZE + SPR_SEPARATOR ) ),
	Vector2D( 0, 0 ),
	Vector2D( 0, +( SPR_SIZE + SPR_SEPARATOR ) )
};

const int HUD_CHAN_TIMER = 0;
const int HUD_CHAN_FIRST_ITEM = 1;

bool g_fShowStatus;

bool g_fShowTimer;
int g_iLastTimeLeft;
float g_flStartTime;

int g_iTimeLimit;
int g_iTimeWarning;

array<bool> g_itemStatus;

string g_strTimerTarget;
string g_strWarningTarget;

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void Init()
{
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	//g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );

	g_fShowStatus = false;
	
	g_fShowTimer = false;
	g_flStartTime = 0.0;
	
	g_iTimeLimit = 0;
	g_strTimerTarget = "";
	
	g_iTimeWarning = 0;
	g_strWarningTarget = "";
	
	InitItemStatus();
	
	g_Scheduler.SetInterval( "Update", 0.1, g_Scheduler.REPEAT_INFINITE_TIMES );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( g_fShowTimer )
		SendTimer( pPlayer );
		
	if ( g_fShowStatus )
		SendSprites( pPlayer );
	
	return HOOK_CONTINUE;
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
/*HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	return HOOK_CONTINUE;
}*/

//=============================================================================
// Time Display
//=============================================================================

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void Update()
{
	if ( g_fShowTimer )
	{
		int iTimeLeft = GetTimeLeftInt();
		
		if ( g_iLastTimeLeft != iTimeLeft )
		{
			edict_t@ worldspawn = g_EntityFuncs.IndexEnt(0);
			
			if ( g_iTimeWarning > 0 && iTimeLeft == g_iTimeWarning )
			{
				SendTimer( null ); // Update everyone
				TriggerWarningTarget();
			}
			else if ( iTimeLeft == 0 )
			{
				TriggerTimerTarget();
			}
			else if ( iTimeLeft == -1 )
			{
				// Hide the timer 1 second later...
				g_PlayerFuncs.HudToggleElement( null, HUD_CHAN_TIMER, false );
				g_fShowTimer = false;
			}
				
			g_iLastTimeLeft = iTimeLeft;
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void SetTarget( int iTimeLimit, const string& in targetname )
{
	g_iTimeLimit = iTimeLimit;
	g_strTimerTarget = targetname;
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void SetWarningTarget( int iWarningTime, const string& in targetname )
{
	if ( iWarningTime <= 0 || targetname == "" )
		return;
	
	g_iTimeWarning = iWarningTime;
	g_strWarningTarget = targetname;
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void TriggerTimerTarget()
{
	if ( g_strTimerTarget != "" )
		g_EntityFuncs.FireTargets( g_strTimerTarget, null, null, USE_ON, 0.0f, 0.0f );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void TriggerWarningTarget()
{
	if ( g_strWarningTarget != "" )
		g_EntityFuncs.FireTargets( g_strWarningTarget, null, null, USE_ON, 0.0f, 0.0f );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
float GetTimeLeft()
{
	return g_iTimeLimit - ( g_Engine.time - g_flStartTime );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
int GetTimeLeftInt()
{
	float flTimeLeft = GetTimeLeft();
	return Math.max( -1, int( Math.Floor( flTimeLeft ) ) );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void SendTimer( CBasePlayer@ pPlayer )
{
	bool fTimeWarning = GetTimeLeftInt() <= g_iTimeWarning;
	
	HUDNumDisplayParams params;
	
	params.channel = HUD_CHAN_TIMER;
	
	params.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_DEFAULT_ALPHA |
		HUD_TIME_MINUTES | HUD_TIME_SECONDS | HUD_TIME_COUNT_DOWN;
	if ( fTimeWarning )
		params.flags |= HUD_TIME_MILLISECONDS;
	
	params.value = GetTimeLeft();
	
	params.x = 0;
	params.y = 0.06;

	params.color1 = fTimeWarning ? RGBA_RED : RGBA_SVENCOOP;
	
	params.spritename = "stopwatch";
	
	g_PlayerFuncs.HudTimeDisplay( null, params );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void ToggleTimeDisplay( bool fVisible )
{
	if ( g_fShowTimer == fVisible )
		return;
	
	g_fShowTimer = fVisible;
	
	if ( g_fShowTimer )
	{
		g_flStartTime = g_Engine.time;
		g_iLastTimeLeft = 0;
		SendTimer( null );
	}
	else
	{
		g_PlayerFuncs.HudToggleElement( null, HUD_CHAN_TIMER, false );
	}
}

//=============================================================================
// Status Indicators
//=============================================================================

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void SendSprites( CBasePlayer@ pPlayer )
{
	for ( int i = 0; i < NUM_ITEMS; i++ )
	{
		SendSprite( pPlayer, ITEM_TYPE(i), false );
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void SendSprite( CBasePlayer@ pPlayer, ITEM_TYPE item, bool fEffect )
{
	string strName;
	snprintf( strName, "th_escape/%1_%2_%3.spr", g_itemName[ item ], SPR_SIZE, g_itemStatus[ item ] ? "on" : "off" );
	//g_Game.AlertMessage( at_console, ">> %1 : %2\n", item, strName );
	
	Vector2D pos = g_itemPos[ item ];
	
	bool fActive = g_itemStatus[ item ];
		
	HUDSpriteParams params;
	
	params.channel = HUD_CHAN_FIRST_ITEM + item;

	params.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_EFFECT_ONCE;
	/*if ( !fActive )
		params.flags |= HUD_ELEM_DYNAMIC_ALPHA;*/

	params.spritename = strName;

	params.x = pos.x;
	params.y = pos.y;

	//params.fadeinTime = 1.5;
	//params.holdTime = 0.0;
	//params.fadeoutTime = 1.5;
	
	if ( fEffect )
	{
		params.fxTime = 2;
		params.effect = HUD_EFFECT_RAMP_DOWN;
	}
	
	params.color1 = fActive ? RGBA_WHITE : RGBA( 255, 255, 255, 100 );
	params.color2 = RGBA( 255, 128, 0, 255 );

	g_PlayerFuncs.HudCustomSprite( pPlayer, params );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void InitItemStatus()
{
	g_itemStatus.resize( NUM_ITEMS );
	for ( int i = 0; i < NUM_ITEMS; i++ )
		g_itemStatus[ i ] = false;
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void SetItemStatus( ITEM_TYPE item, bool fStatus )
{
	if ( g_itemStatus[ item ] == fStatus )
		return;
	
	g_itemStatus[ item ] = fStatus;
	SendSprite( null, item, true ); // Update everyone
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void ToggleSprites( CBasePlayer@ pPlayer, bool fVisible )
{
	for ( int i = 0; i < NUM_ITEMS; i++ )
	{
		g_PlayerFuncs.HudToggleElement( pPlayer, HUD_CHAN_FIRST_ITEM + i, fVisible );
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void ToggleStatusIndicators( bool fVisible )
{
	if ( g_fShowStatus == fVisible )
		return;
	
	g_fShowStatus = fVisible;
	
	if ( g_fShowStatus )
		SendSprites( null );
	else
		ToggleSprites( null, false );
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
void Message( CBasePlayer@ pPlayer, const string& in text, float x = -1, float y = -1 )
{
	HUDTextParams txtPrms;

	txtPrms.x = x;
	txtPrms.y = y;
	txtPrms.effect = 0;

	// Text colour
	txtPrms.r1 = 255;
	txtPrms.g1 = 0;
	txtPrms.b1 = 0;
	txtPrms.a1 = 200;

	// Fade-in colour
	txtPrms.r2 = 255;
	txtPrms.g2 = 0;
	txtPrms.b2 = 0;
	txtPrms.a2 = 200;
	
	txtPrms.fadeinTime = 0.5f;
	txtPrms.fadeoutTime = 0.5f;
	txtPrms.holdTime = 5.0f;
	txtPrms.fxTime = 0.25f;
	txtPrms.channel = 1;
	
	if ( pPlayer !is null )
		g_PlayerFuncs.HudMessage( pPlayer, txtPrms, text );
	else
		g_PlayerFuncs.HudMessageAll( txtPrms, text );
}

} // end of namespace
