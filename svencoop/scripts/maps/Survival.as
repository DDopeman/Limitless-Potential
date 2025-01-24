final class Survival
{
	private CCVar@ m_pSurvivalEnabled;
	private CCVar@ m_pSurvivalStartOn;
	private CCVar@ m_pNextSurvivalMap;
	
	Survival()
	{
		// NOTICE:
		// These AS CVARs are here just for compatibility with the existing survival maps.
		// Please update your map if it's using this old system.
		@m_pSurvivalEnabled = CCVar( "survival_enabled", 1, "Controls whether survival mode is enabled or disabled", ConCommandFlag::None, CVarCallback( this.SurvivalEnabledCB ) );
		@m_pSurvivalStartOn = CCVar( "survival_start_on", 1, "Controls whether survival mode should be activated when the map loads", ConCommandFlag::None, CVarCallback( this.SurvivalStartOnCB ) );
		@m_pNextSurvivalMap = CCVar( "next_survival_map", "", "Sets the next survival map to switch to if next map is voted",  ConCommandFlag::None, CVarCallback( this.NextSurvivalMapCB ) );
	}
	
	void MapInit()
	{
	}
	
	void MapActivate()
	{
		if ( m_pSurvivalEnabled.GetInt() != 0 )
		{
			g_SurvivalMode.EnableMapSupport();
		}
	}
	
	private void SurvivalEnabledCB( CCVar@ cvar, const string& in szOldValue, float flOldValue )
	{
		if ( cvar.GetInt() != 0 )
		{
			g_SurvivalMode.EnableMapSupport();
			g_SurvivalMode.Enable();
		}
	}
	
	private void SurvivalStartOnCB( CCVar@ cvar, const string& in szOldValue, float flOldValue )
	{	
		g_SurvivalMode.SetStartOn( cvar.GetInt() != 0 );
	}
	
	private void NextSurvivalMapCB( CCVar@ cvar, const string& in szOldValue, float flOldValue )
	{
		g_SurvivalMode.SetNextMap( cvar.GetString() );
	}
	
	bool IsEnabled
	{
		get const { return g_SurvivalMode.IsEnabled(); }
	}
	
	void Enable()
	{
		g_SurvivalMode.Enable();
	}
	
	void Disable()
	{
		g_SurvivalMode.Disable();
	}
	
	void Toggle()
	{
		g_SurvivalMode.Toggle();
	}
	
	bool IsActive
	{
		get const { return g_SurvivalMode.IsActive(); }
	}
	
	void Activate()
	{
		g_SurvivalMode.Activate();
	}
	
	void EndRound()
	{
		g_SurvivalMode.EndRound();
	}
	
	float DelayBeforeStart
	{
		get const { return g_SurvivalMode.GetDelayBeforeStart(); }
		set { g_SurvivalMode.SetDelayBeforeStart( value ); }
	}
}
