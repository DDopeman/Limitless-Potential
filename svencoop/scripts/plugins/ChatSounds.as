/***
 * BASED ON:
  incognico's old ChatSounds
 * REFERENCES FROM:
  KernCore's BuyMenu - BuyMenuCVARS
  Zode's AFBUtil - GetTargetPlayers
  w00tguy's AntiRush - getPlayerState and doCommand
  Speak And Spk Commands - https://steamcommunity.com/sharedfiles/filedetails/?id=595080353
 * IMPORTANT: Strict configuration of sounds to work properly:
  WAV only 11025Hz, 22050Hz or 44100Hz(iffy, not recommended) sampling rate, Mono, 8-bit PCM
 - WHY THIS CONFIGURATION? 
  1. Don't need to load sounds on the server when using the spk command.
  2. Clients will load sounds on-demand as long as the files exist for them.
  3. This speeds up loading time since sounds normally load all at once on join.
 ** HOW TO CONVERT MY SOUNDS TO THIS CONFIGURATION: ( w/ "Audacity" )
  1. Open Audacity and load your sound to be converted (File>Import>Audio, File>Open or simply drag the file into the program).
  2. Most likely your sound is stereo, so you will need to convert it to mono (Tracks>Mix>Mix Stereo to Mono).
  3. Now you will need to resample your sound to one of the supported frequencies, preferably 22050Hz (Tracks>Resample...>Select or type 22050 and press OK).
  4. Finally you will have to export your sound as WAV 8-bit PCM (File>Export>Export as WAV, in "Save as Type" it should be: WAV (Microsoft), below in "Encoding" select: Unsigned 8-bit PCM and press Save).
 * INSTALLATION: Add the following lines to "default_plugins.txt":
	"plugin"
	{
		"name" "ChatSounds"
		"script" "ChatSounds"
		"concommandns" "cs"
	}
***/

ChatSounds::CChatSounds@ g_ChatSounds = @ChatSounds::CChatSounds();

const array<string> m_sprite = {
	"sprites/kezaeiv/chatsound.spr"
};
const string szFilePath = "scripts/plugins/store/ChatSounds.txt";

CClientCommand _help( "cshelp", "Shows you the available commands", ClientCommandCallback( g_ChatSounds.ClientCommand ) );
CClientCommand _listsounds( "listsounds", "List all ChatSounds", ClientCommandCallback( g_ChatSounds.ClientCommand ) );
CClientCommand _stop( "stop", "Stop current ChatSounds in playback", ClientCommandCallback( g_ChatSounds.ClientCommand ) );
CClientCommand _volume( "csvolume", "Sets your volume at which your ChatSounds play <10-100> (def: 100)", ClientCommandCallback( g_ChatSounds.ClientCommand ) );
CClientCommand _pitch( "cspitch", "Sets the pitch at which your ChatSounds play <80-145> (def: 100)", ClientCommandCallback( g_ChatSounds.ClientCommand ) );
CClientCommand _mute( "csmute", "Stop playing ChatSounds <on-off> (def: off)", ClientCommandCallback( g_ChatSounds.ClientCommand ) );
CClientCommand _forcemute( "csforcemute", "Force mute on <target> (steamid or nickname)", ClientCommandCallback( g_ChatSounds.ClientCommand ), ConCommandFlag::AdminOnly );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Rizulix" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/svencoop" );

	g_ChatSounds.OnInit();
}

void PluginExit()
{
	g_ChatSounds.OnExit();
}

void MapInit()
{
	g_ChatSounds.Initialize();
}

namespace ChatSounds
{

final class CChatSounds
{
	private CCVar@ g_BaseDelay;
	private CCVar@ g_DelayVariance;

	private array<string> m_playerID;
	private array<CChatSounds@> m_playerData;

	private array<string> m_soundKey;
	private array<string> m_soundFile;

	private bool m_bMuted = false;
	private bool m_bForcedMute = false;
	private uint8 m_uiPitch = 100;
	private uint8 m_uiVolume = 100;
	private float m_flNextChatSounds = 0.0f;

	private float m_flChatSoundsDelay;

	void OnInit()
	{
		g_Hooks.RegisterHook( Hooks::Player::ClientSay, ClientSayHook( this.ClientSay ) );
		g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.ClientPutInServer ) );
		g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, ClientDisconnectHook( this.ClientDisconnect ) );

		if( g_BaseDelay is null || g_DelayVariance is null )
		{
			@g_BaseDelay = CCVar( "basedelay", 0.72f, "This will be the default basedelay(i.e. at 0 players)", ConCommandFlag::AdminOnly, CVarCallback( this.CVar ) ); // as_command cs.basedelay
			@g_DelayVariance = CCVar( "delayvariance", 0.00f, "Adds or subtracts time to the basedelay when joining or leaving the server respectively", ConCommandFlag::AdminOnly, CVarCallback( this.CVar ) ); // as_command cs.delayvariance
		}

		if( g_Engine.time > 3.1f )
		{
			ReadSounds();
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[ChatSounds] Plugin reloaded! New sounds(if any) will be distributed to the map change\n" );
		}

		GetDelay( m_flChatSoundsDelay );
	}

	void OnExit()
	{
		g_Hooks.RemoveHook( Hooks::Player::ClientSay, ClientSayHook( this.ClientSay ) );
		g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.ClientPutInServer ) );
		g_Hooks.RemoveHook( Hooks::Player::ClientDisconnect, ClientDisconnectHook( this.ClientDisconnect ) );

		m_playerID.removeRange( 0, m_playerID.length() );
		m_playerData.removeRange( 0, m_playerData.length() );

		m_soundKey.removeRange( 0, m_soundKey.length() );
		m_soundFile.removeRange( 0, m_soundFile.length() );
	}

	void Initialize()
	{
		m_soundKey.removeRange( 0, m_soundKey.length() );
		m_soundFile.removeRange( 0, m_soundFile.length() );

		LoadSounds();

		for( uint i = 0; i < m_sprite.length(); ++i )
			g_Game.PrecacheModel( m_sprite[i] );
	}

	CChatSounds@ GetConfig( CBasePlayer@ pPlayer )
	{
		if( pPlayer is null || !pPlayer.IsConnected() )
			return null;

		string szAuthId = auth_id(pPlayer);
		if( m_playerID.find( szAuthId ) < 0 )
		{
			CChatSounds pSounds;
			m_playerID.insertLast( szAuthId );
			m_playerData.insertLast( pSounds );
		}
		return @m_playerData[m_playerID.find(szAuthId)];
	}

	private void AddSounds( array<string> @line )
	{
		line[0].ToLowercase();
		if( m_soundKey.find( line[0] ) >= 0 )
		{
			m_soundFile[m_soundKey.find(line[0])] = line[1];
			return;
		}

		m_soundKey.insertLast( line[0] );
		m_soundFile.insertLast( line[1] );
	}

	private void SortAsc()
	{
		array<array<string>> temp;
		for( uint i = 0; i < m_soundKey.length(); i++ )
			temp.insertLast( { m_soundKey[i], m_soundFile[i] } );

		m_soundKey.sortAsc();
		for( uint j = 0; j < m_soundKey.length(); j++ )
		{
			for( uint k = 0; k < temp.size(); k++ )
			{
				if( temp[k][0] == m_soundKey[j] )
					m_soundFile[j] = temp[k][1];
			}
		}
	}

	private void Aliases()
	{
		for( uint i = 0; i < m_soundFile.length(); i++ )
		{
			if( !m_soundFile[i].StartsWith("*") )
				continue;

			string soundfile = "";
			m_soundFile[i].ToLowercase();
			for( uint j = 1; j < m_soundFile[i].Length(); j++ ) // 'string::erase' method doesn't exist
				soundfile += m_soundFile[i][j];

			m_soundFile[i] = m_soundKey.find(soundfile);
		}
	}

	private void ReadSounds()
	{
		File@ pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::READ );

		if( pFile is null || !pFile.IsOpen() )
		{
			g_Game.AlertMessage( at_console, "[ChatSounds] ATTENTION: \"%1\" failed to open or file not exist\n", szFilePath );
			return;
		}
		while( !pFile.EOFReached() )
		{
			string szLine;
			pFile.ReadLine( szLine );
			if( szLine.SubString(0,1) == "#" || szLine.SubString(0,2) == "//" || szLine.IsEmpty() )
				continue;

			array<string> parsed = szLine.Split(" ");
			if( parsed.length() < 2 )
				continue;

			AddSounds( parsed );
		}
		pFile.Close();
		SortAsc();
		Aliases();
	}

	private void LoadSounds()
	{
		ReadSounds();
	/*
		for( uint i = 0; i < m_soundKey.length(); ++i )
		{
			if( !m_soundFile[i].EndsWith(".wav") )
				continue;

			g_Game.PrecacheGeneric( "sound/" + m_soundFile[i] );
		}*/
	}

	private void GetDelay( float& out flChatSoundsDelay )
	{
		flChatSoundsDelay = g_BaseDelay.GetFloat() + (g_DelayVariance.GetFloat());
	}

	void ClientCommand( const CCommand@ args )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		const string szFirstArg = args.Arg(0).ToLowercase();

		if( args.ArgC() == 1 && szFirstArg == ".cshelp" )
			Help( pPlayer );
		else if( args.ArgC() == 1 && szFirstArg == ".listsounds" )
			ListSounds( pPlayer );
		else if( args.ArgC() == 1 && szFirstArg == ".stop" )
			Stop( pPlayer, true );
		else if( args.ArgC() <= 2 && szFirstArg == ".csvolume" )
			SetVolume( pPlayer, args, true );
		else if( args.ArgC() <= 2 && szFirstArg == ".cspitch" )
			SetPitch( pPlayer, args, true );
		else if( args.ArgC() <= 2 && szFirstArg == ".csmute" )
			SetMute( pPlayer, args, true );
		else if( args.ArgC() <= 3 && szFirstArg == ".csforcemute" )
			ForceMute( pPlayer, args, true );
	}

	void CVar( CCVar@ cvar, const string& in, float )
	{
		if( cvar is g_BaseDelay || cvar is g_DelayVariance )
			GetDelay( m_flChatSoundsDelay );
	}

	private void Help( CBasePlayer@ pPlayer )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "AVAILABLE CHATSOUNDS COMMANDS\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "------------------------\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".cshelp\" in console to shows you the available commands.\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".listsounds\" in console to list all ChatSounds.\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".stop\" in console or chat to stop current ChatSounds in playback.\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".csmute\" or \".csmute <on-off>\", in console or chat to stop playing ChatSounds.\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".csvolume <10-100>\" (def: 100) in console or chat to sets your volume at which your ChatSounds play.\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".cspitch <80-145>\" (def: 100) in console or chat to sets your pitch at which your ChatSounds play.\n" );
		if( g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".csforcemute <target>\" or \".csforcemute <target> <on-off>\", in console or chat to force mute on target.\n" );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Where target can be: \"nickname\" or \"steamid\"\n" );
		}
	}

	private void ListSounds( CBasePlayer@ pPlayer )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "AVAILABLE SOUND TRIGGERS\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "------------------------\n" );

		string szMessage = "";
		for( uint i = 1; i < m_soundKey.length()+1; ++i )
		{
			szMessage += m_soundKey[i-1] + " | ";
			if( i % 5 == 0 )
			{
				szMessage.Resize( szMessage.Length()-2 );
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szMessage );
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\n" );
				szMessage = "";
			}
		}

		if( szMessage.Length() > 2 )
		{
			szMessage.Resize( szMessage.Length()-2 );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szMessage + "\n" );
		}
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\n" );
	}

	private void Stop( CBasePlayer@ pPlayer, bool bConsole )
	{
		CChatSounds@ pSounds = GetConfig( pPlayer );

		if( pSounds.m_bMuted || pSounds.m_bForcedMute )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] You are " + (pSounds.m_bForcedMute ? "\"forcibly muted\"" : "\"muted\"") + ", you don't need to do this!\n" );
			return;
		}

		ClientCommand( pPlayer, ";stopsound;" );
		g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Stopping current ChatSounds in playback\n" );
	}

	private void SetVolume( CBasePlayer@ pPlayer, const CCommand@ args, bool bConsole )
	{
		CChatSounds@ pSounds = GetConfig( pPlayer );

		if( !isdigit(args.Arg(1)) || args.Arg(1) == "" )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] " + (args.Arg(1) == "" ? "Empty" : "Invalid") + " argument!\n" );
			return;
		}

		if( atoui(args.Arg(1)) != pSounds.m_uiVolume )
		{
			pSounds.m_uiVolume = Math.clamp( 10, 100, atoui(args.Arg(1)) );
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Volume set to: \"" + pSounds.m_uiVolume + "\"\n" );
		}
		else
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Your current Volume is: \"" + pSounds.m_uiVolume + "\"\n" );
	}

	private void SetPitch( CBasePlayer@ pPlayer, const CCommand@ args, bool bConsole )
	{
		CChatSounds@ pSounds = GetConfig( pPlayer );

		if( !isdigit(args.Arg(1)) || args.Arg(1) == "" )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] " + (args.Arg(1) == "" ? "Empty" : "Invalid") + " argument!\n" );
			return;
		}

		if( atoui(args.Arg(1)) != pSounds.m_uiPitch )
		{
			pSounds.m_uiPitch = Math.clamp( 80, 145, atoui(args.Arg(1)) );
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Pitch set to: \"" + pSounds.m_uiPitch + "\"\n" );
		}
		else
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Your current Pitch is: \"" + pSounds.m_uiPitch + "\"\n" );
	}

	private void SetMute( CBasePlayer@ pPlayer, const CCommand@ args, bool bConsole )
	{
		CChatSounds@ pSounds = GetConfig( pPlayer );

		if( args.ArgC() == 1 )
		{
			if( pSounds.m_bMuted )
				pSounds.m_bMuted = false;
			else
				pSounds.m_bMuted = true;
		}
		else if( args.ArgC() == 2 )
		{
			if( args.Arg(1).ToLowercase() == "on" )
			{
				if( pSounds.m_bMuted )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] You are currently \"muted\"!\n" );
					return;
				}
				else
					pSounds.m_bMuted = true;
			}
			else if( args.Arg(1).ToLowercase() == "off" )
			{
				if( !pSounds.m_bMuted )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] You are currently \"unmuted\"!\n" );
					return;
				}
				else
					pSounds.m_bMuted = false;
			}
			else
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Invalid argument!\n" );
				return;
			}
		}
		g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Sounds now are \"" + (pSounds.m_bMuted ? "muted" : "unmuted") + "\"\n" );
	}

	private void SetForceMute( CBasePlayer@ pPlayer, CBasePlayer@ pTarget, const CCommand@ args, bool bConsole )
	{
		CChatSounds@ pSounds = GetConfig( pTarget );

		if( args.ArgC() == 2 )
		{
			if( pSounds.m_bForcedMute )
				pSounds.m_bForcedMute = false;
			else
				pSounds.m_bForcedMute = true;
		}
		else if( args.ArgC() == 3 )
		{
			if( args.Arg(2).ToLowercase() == "on" )
			{
				if( pSounds.m_bForcedMute )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] This player is currently \"muted\"!\n" );
					return;
				}
				else
					pSounds.m_bForcedMute = true;
			}
			else if( args.Arg(2).ToLowercase() == "off" )
			{
				if( !pSounds.m_bForcedMute )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] This player is currently \"unmuted\"!\n" );
					return;
				}
				else
					pSounds.m_bForcedMute = false;
			}
			else
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Invalid argument!\n" );
				return;
			}
		}
		g_PlayerFuncs.SayText( pTarget, "[ChatSounds] You were \"" + (pSounds.m_bForcedMute ? "muted" : "unmuted") + "\" by an admin: \"" + pPlayer.pev.netname + "\"\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] \"" + pTarget.pev.netname + "\" was \"" + (pSounds.m_bForcedMute ? "muted" : "unmuted") + "\"\n" );
	}

	private void ForceMute( CBasePlayer@ pPlayer, const CCommand@ args, bool bConsole )
	{
		if( g_PlayerFuncs.AdminLevel( pPlayer ) < ADMIN_YES )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] You don't have permission for this command!\n" );
			return;
		}

		if( args.Arg(1).SubString(0,6).ToLowercase() == "steam_" )
		{
			CBasePlayer@ pTarget = null;
			for( int i = 1; i <= g_Engine.maxClients; i++ )
			{
				CBasePlayer@ pTemp = g_PlayerFuncs.FindPlayerByIndex( i );
				if( pTemp is null || !pTemp.IsConnected() )
					continue;

				string szAuthId = auth_id(pTemp);
				szAuthId.ToLowercase();

				if( szAuthId == args.Arg(1).ToLowercase() )
					@pTarget = pTemp;
			}

			if( pTarget is null || !pTarget.IsConnected() )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Invalid target id!\n" );
				return;
			}
			SetForceMute( pPlayer, pTarget, args, bConsole );
		}
		else if( args.Arg(1) != "" )
		{
			CBasePlayer@ pTarget = null;
			for( int i = 1; i <= g_Engine.maxClients; i++ )
			{
				CBasePlayer@ pTemp = g_PlayerFuncs.FindPlayerByIndex( i );
				if( pTemp is null || !pTemp.IsConnected() )
					continue;

				if( string(pTemp.pev.netname).ToLowercase() == args.Arg(1).ToLowercase() )
					@pTarget = pTemp;
			}

			if( pTarget is null || !pTarget.IsConnected() )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] Invalid target name!\n" );
				return;
			}
			SetForceMute( pPlayer, pTarget, args, bConsole );
		}
		else
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatSounds] You must write a target!\n" );
			return;
		}
	}

	private void ClientCommand( CBasePlayer@ pPlayer, string szCommand )
	{
		NetworkMessage netmsg( MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict() );
			netmsg.WriteString( szCommand );
		netmsg.End();
	}

	private void Speak( string szSound, uint8 uiPitch, uint8 uiVolume )
	{
		szSound = szSound.SubString(0,szSound.Find("."));
		string szCommand = ";spk \"" + szSound + "(v" + uiVolume + " p" + uiPitch + ")\";";

		for( int i = 1; i <= g_Engine.maxClients; i++ )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
			if( pPlayer is null || !pPlayer.IsConnected() )
				continue;

			CChatSounds@ pSounds = GetConfig( pPlayer );
			if( pSounds.m_bMuted || pSounds.m_bForcedMute )
				continue;

			ClientCommand( pPlayer, szCommand );
		}
	}

	HookReturnCode ClientSay( SayParameters@ pParams )
	{
		CBasePlayer@ pPlayer = pParams.GetPlayer();
		const CCommand@ args = pParams.GetArguments();
		const string szFirstArg = args.Arg(0).ToLowercase();
		const int iSoundIndex = m_soundKey.find( szFirstArg );

		if( args.ArgC() == 1 && iSoundIndex >= 0 )
		{
			CChatSounds@ pSounds = GetConfig( pPlayer );

			if( pSounds.m_bForcedMute || pSounds.m_bMuted )
			{
				if( pSounds.m_bForcedMute )
				{
					pParams.ShouldHide = true;
					g_PlayerFuncs.SayText( pPlayer, "[ChatSounds] You are muted by an admin!\n" );
				}
				return HOOK_HANDLED;
			}

			if( pSounds.m_flNextChatSounds > g_Engine.time )
			{
				pParams.ShouldHide = true;
				float wait = pSounds.m_flNextChatSounds - g_Engine.time;
				g_PlayerFuncs.SayText( pPlayer, "[ChatSounds] Wait " + format_float(wait) + " seconds\n" );
				return HOOK_HANDLED;
			}
			else
			{
				if( !m_soundFile[iSoundIndex].EndsWith(".wav") )
				{
					if( atoi(m_soundFile[iSoundIndex]) < 0 )
					{
						pParams.ShouldHide = true;
						g_PlayerFuncs.SayText( pPlayer, "[ChatSounds] Oh no! Something went wrong...\n" );
						return HOOK_HANDLED;
					}
					else
						Speak( m_soundFile[atoi(m_soundFile[iSoundIndex])], pSounds.m_uiPitch, pSounds.m_uiVolume );
				}
				else
					Speak( m_soundFile[iSoundIndex], pSounds.m_uiPitch, pSounds.m_uiVolume );

				if( m_sprite.length() > 0 )
					pPlayer.ShowOverheadSprite( m_sprite[Math.RandomLong(0,m_sprite.length()-1)], 56.0f, 2.25f );

				pSounds.m_flNextChatSounds = g_Engine.time + m_flChatSoundsDelay;
				return HOOK_HANDLED;
			}
		}
		else if( args.ArgC() == 1 && szFirstArg == ".stop" )
		{
			pParams.ShouldHide = true;
			Stop( pPlayer, false );
			return HOOK_HANDLED;
		}
		else if( args.ArgC() <= 2 && szFirstArg == ".csvolume" )
		{
			pParams.ShouldHide = true;
			SetVolume( pPlayer, args, false );
			return HOOK_HANDLED;
		}
		else if( args.ArgC() <= 2 && szFirstArg == ".cspitch" )
		{
			pParams.ShouldHide = true;
			SetPitch( pPlayer, args, false );
			return HOOK_HANDLED;
		}
		else if( args.ArgC() <= 2 && szFirstArg == ".csmute" )
		{
			pParams.ShouldHide = true;
			SetMute( pPlayer, args, false );
			return HOOK_HANDLED;
		}
		else if( args.ArgC() <= 3 && szFirstArg == ".csforcemute" )
		{
			pParams.ShouldHide = true;
			ForceMute( pPlayer, args, false );
			return HOOK_HANDLED;
		}
		return HOOK_CONTINUE;
	}

	HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
	{

		if( pPlayer is null )
			return HOOK_CONTINUE;

		CChatSounds@ pSounds = GetConfig( pPlayer );
		pSounds.m_flNextChatSounds = g_Engine.time + m_flChatSoundsDelay;
		return HOOK_CONTINUE;
	}

	HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
	{
		m_flChatSoundsDelay -= g_DelayVariance.GetFloat();
		return HOOK_CONTINUE;
	}

	private string auth_id( CBasePlayer@ plr )
	{
		string szAuthId = g_EngineFuncs.GetPlayerAuthId( plr.edict() );
		if( szAuthId == "STEAM_ID_LAN" || szAuthId == "BOT" )
			szAuthId = plr.pev.netname;
		return szAuthId;
	}

	private string format_float( float f )
	{
		uint decimal = uint(((f - int(f)) * 10)) % 10;
		return "" + int(f) + "." + decimal;
	}
}

}
