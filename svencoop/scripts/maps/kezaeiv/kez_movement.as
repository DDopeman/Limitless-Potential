//Original PlayerUse_Movement_Speed script: KernCore

//AutoBhop found on an old steam forum by an user called Nero,
//(found out later that another user called Dhalucario made it into a plugin aswell)
//https://gitlab.com/dhalucario/dhalucario_svencoop_as/-/blob/master/svencoop/scripts/plugins/Autohop.as
//altered from plugin to map script by Gaftherman
//Used for my (KEZAEIV) custom campaign (keztris) wich has altered gravity,
//for that reason it makes you jump higher, also it makes unusable the long jump module


void RegisterAutoBhopping()
{
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, PlayerUse );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, PlayerPreThink );
}

HookReturnCode PlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;

	if( pPlayer.pev.flags & FL_ONGROUND != 0 && (pPlayer.m_afButtonLast & IN_USE != 0 || pPlayer.m_afButtonPressed & IN_USE != 0) )
	{
		pPlayer.pev.velocity = pPlayer.pev.velocity * 0.1;
		pPlayer.SetMaxSpeedOverride( 12 );
	}
	else if( pPlayer.m_afButtonReleased & IN_USE != 0 )
	{
		pPlayer.SetMaxSpeedOverride( -1 );
	}

	return HOOK_CONTINUE;

}


HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( (pPlayer.pev.button & IN_JUMP) != 0 )
	{
		int flags = pPlayer.pev.flags;

		if( (flags & FL_WATERJUMP) != 0 || pPlayer.pev.waterlevel >= WATERLEVEL_WAIST || (flags & FL_ONGROUND) == 0 || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;


		Vector velocity = pPlayer.pev.velocity;
		velocity.z += sqrt(2.5 * 800 * 45.0f);
		pPlayer.pev.velocity = velocity;

		pPlayer.pev.gaitsequence = 6;
	}

	return HOOK_CONTINUE;
}

