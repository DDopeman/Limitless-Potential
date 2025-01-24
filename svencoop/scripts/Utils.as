/*
* Author(s): Sam "Solokiller" Vanheer
* www.svencoop.com
*
* General purpose utility code
*/

namespace Utils
{
funcdef void ScopedFunction();

/*
* The ScopedExecutor class will execute a function on construction, and a function on destruction
* Both functions are optional
* This class can be used to run code on script initialization by creation a global instance of this class, and passing in a function
*/
class ScopedExecutor
{
	private ScopedFunction@ m_pDestructor;
	
	ScopedExecutor( ScopedFunction@ pConstructor, ScopedFunction@ pDestructor = null )
	{
		@m_pDestructor = @pDestructor;
		
		if( pConstructor !is null )
			pConstructor();
	}
	
	~ScopedExecutor()
	{
		if( m_pDestructor !is null )
			m_pDestructor();
	}
}
}

/*
* Convenience function for alerting text to the server console
*/
void Alert( const string& in szMessage )
{
	g_Game.AlertMessage( at_console, szMessage );
}

/*
* Like Alert, only to a specific player's console, instead of the server console
*/
void ClientAlert( CBasePlayer@ pPlayer, const string& in szMessage )
{
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szMessage );
}
/*
* Like ClientAlert, only to all players
*/
void ClientAlertAll( const string& in szMessage )
{
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, szMessage );
}