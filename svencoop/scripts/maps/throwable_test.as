#include "streamfox/func_throwable"

void MapInit()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "func_throwable", "throwable" );
    g_CustomEntityFuncs.RegisterCustomEntity( "func_throwable", "func_throwable" );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerUse, @ThrowablePlayerUse );
}

void MapActivate()
{
   
}

HookReturnCode ThrowablePlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if ( ( pPlayer.m_afButtonPressed & IN_USE ) != 0 )
	{
		Math.MakeVectors( pPlayer.pev.v_angle );
		Vector headPos = pPlayer.pev.origin + pPlayer.pev.view_ofs;
		
		TraceResult tr;
		g_Utility.TraceLine(headPos, headPos + g_Engine.v_forward*8192, dont_ignore_monsters, pPlayer.edict(), tr );
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		if (phit !is null and phit.pev.classname == "func_throwable" or phit.pev.classname == "throwable")
		{
			float useDistance = (tr.vecEndPos - headPos).Length();
			func_throwable@ throwable = cast<func_throwable@>(CastToScriptClass(phit));
			if (useDistance < throwable.holdDistance)
				throwable.Use(pPlayer, pPlayer, USE_TOGGLE, 0);
		}
		
	}
	
	return HOOK_CONTINUE;
}