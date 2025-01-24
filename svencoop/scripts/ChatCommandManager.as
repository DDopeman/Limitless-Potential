/*
* Author(s): Sam "Solokiller" Vanheer
* www.svencoop.com
*
* This class manages commands that can be interpreted from game chat
* Must be created inside PluginInit for plugins; otherwise the console command namespace is not used
*
* You will have to pass game chat to the manager by hooking into Hooks::Player::ClientSay, and calling the manager's ExecuteCommand method
* Sample implementation:
*
* 	HookReturnCode ClientSay( SayParameters@ pParams )
* 	{		
* 		if( g_ChatCommands.ExecuteCommand( pParams ) )
* 			return HOOK_CONTINUE;
* 	
* 		return HOOK_CONTINUE;
* 	}
*/

namespace ChatCommandSystem
{
funcdef void ChatCommandCallback( SayParameters@ pParams );

/*
* Represents a command
*/
class ChatCommand
{
	private string m_szName;
	private ChatCommandCallback@ m_Callback;
	private bool m_fIsCheat;
	private int m_iMinArgumentsRequired;
	private string m_szHelpInfo;
	
	string Name
	{
		 get const { return m_szName; }
	}
	
	ChatCommandCallback@ Callback
	{
		get const { return m_Callback; }
	}
	
	bool IsCheat
	{
		get const { return m_fIsCheat; }
	}
	
	int MinimumArgumentsRequired
	{
		get const { return m_iMinArgumentsRequired; }
	}
	
	string HelpInfo
	{
		get const { return m_szHelpInfo; }
	}
	
	ChatCommand( const string& in szName, ChatCommandCallback@ callback, bool fIsCheat, int iMinArgumentsRequired = 0, const string& in szHelpInfo = "" )
	{
		m_szName = szName;
		m_szName.Trim();
		@m_Callback = @callback;
		m_fIsCheat = fIsCheat;
		m_iMinArgumentsRequired = iMinArgumentsRequired >= 0 ? iMinArgumentsRequired : 0;
		m_szHelpInfo = szHelpInfo;
	}
}

class ChatCommandManager
{
	private dictionary m_Commands;

	private CCVar@ m_pCheatsEnabled = null;
	
	private CClientCommand@ m_pAreCheatsEnabled = null;
	
	private CClientCommand@ m_pListCommands = null;
	
	ChatCommandManager()
	{
		@m_pCheatsEnabled = CCVar( "cheats_enabled", 1.0f, "Whether cheats are enabled or not" );
		@m_pAreCheatsEnabled = CClientCommand( "are_cheats_enabled", "Whether cheats are enabled or not", ClientCommandCallback( this.ShowState ) );
		@m_pListCommands = CClientCommand( "listcommands", "List all commands available in this manager", ClientCommandCallback( this.ListCommands ) );
	}
	
	void ShowState( const CCommand@ pArgs )
	{
		g_EngineFuncs.ClientPrintf( g_ConCommandSystem.GetCurrentPlayer(), print_console, "Cheats are " + ( m_pCheatsEnabled.GetBool() ? "enabled" : "disabled" ) + "\n" );
	}
	
	void ListCommands( const CCommand@ pArgs )
	{
		array<string>@ keys = m_Commands.getKeys();
		
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		
		const uint uiCount = keys.length();
		
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "List of chat commands:\n" );
		
		ChatCommand@ pChatCommand;
		
		for( uint uiIndex = 0; uiIndex < uiCount; ++uiIndex )
		{
			if( m_Commands.get( keys[ uiIndex ], @pChatCommand ) )
				g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Name: " + pChatCommand.Name + ", is cheat: " + ( pChatCommand.IsCheat ? "yes" : "no" ) + "\n" );
		}
		
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "End list\n" );
	}
	
	void AddCommand( ChatCommand@ pCommand )
	{
		if( pCommand is null )
			return;
			
		if( pCommand.Name.IsEmpty() )
		{
			g_Game.AlertMessage( at_console, "Chat command name must be valid!\n" );
			return;
		}
			
		if( pCommand.Callback is null )
		{
			g_Game.AlertMessage( at_console, "Chat command callbacks must be non-null!\n" );
			return;
		}
		
		if( !m_Commands.exists( pCommand.Name ) )
			m_Commands.set( pCommand.Name, @pCommand );
	}
	
	void RemoveCommand( ChatCommand@ pCommand )
	{
		if( pCommand is null )
			return;
			
		ChatCommand@ pStoredCommand = null;
		
		if( m_Commands.get( pCommand.Name, @pStoredCommand ) && pStoredCommand is pCommand )
			m_Commands.delete( pCommand.Name );
	}
	
	bool ExecuteCommand( SayParameters@ pParams )
	{
		const CCommand@ pArguments = pParams.GetArguments();
		
		if( pArguments.ArgC() < 1 )
			return false;
			
		ChatCommand@ pStoredCommand = null;
		
		if( !m_Commands.get( pArguments[ 0 ], @pStoredCommand ) )
			return false;
			
		if( pStoredCommand.Callback is null )
			return false;
			
		if( !m_pCheatsEnabled.GetBool() && pStoredCommand.IsCheat )
			return false;
			
		//pArguments contains the command name, so always add 1
		if( pArguments.ArgC() < ( 1 + pStoredCommand.MinimumArgumentsRequired ) )
		{
			string szMessage = "Not enough parameters for command \"" + pStoredCommand.Name + 
				"\" (expected at least " + pStoredCommand.MinimumArgumentsRequired + ", got " + ( pArguments.ArgC() - 1 ) + ")\n";
				
			const string szHelpInfo = pStoredCommand.HelpInfo;
			
			if( !szHelpInfo.IsEmpty() )
				szMessage += szHelpInfo + "\n";
				
			g_PlayerFuncs.SayText( pParams.GetPlayer(), szMessage );
				
			return false;
		}
			
		ChatCommandCallback@ pCallback = @pStoredCommand.Callback;
			
		pCallback( pParams );
		
		return true;
	}
}
}