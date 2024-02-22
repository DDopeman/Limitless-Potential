#include "helper"

CCVar@ g_cvarHideChat;
CCVar@ g_cvarSilence;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Zode");
	g_Module.ScriptInfo.SetContactInfo("Zodemon @ Sven co-op forums, Zode @ Sven co-op discrod");

	g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerSpawn);

	@g_cvarHideChat = 		CCVar("hidechat", false, "Hide player chat when executing glow command",  ConCommandFlag::AdminOnly);
	@g_cvarSilence =		CCVar("silence", false, "Silent plugin - only print to user instead of everybody", ConCommandFlag::AdminOnly);
	g_bHasColors = false;
}

dictionary g_PlayerGlows;
dictionary g_GlowColors;
bool g_bHasColors = false;

void MapInit()
{
	//g_PlayerGlows.deleteAll();
	g_GlowColors.deleteAll();
	ReadColors();
	g_bHasColors = false;
}

const string g_ColorFile = "scripts/plugins/Zode/colors.txt";
void ReadColors()
{
	File@ file = g_FileSystem.OpenFile(g_ColorFile, OpenFile::READ);
	if(file !is null && file.IsOpen())
	{
		while(!file.EOFReached())
		{
			string sLine;
			file.ReadLine(sLine);
			if(sLine.SubString(0,1) == "#" || sLine.IsEmpty())
				continue;

			array<string> parsed = sLine.Split(" ");
			if(parsed.length() < 4)
				continue;

			int iR = cclamp(atoi(parsed[1]), 0, 255);
			int iG = cclamp(atoi(parsed[2]), 0, 255);
			int iB = cclamp(atoi(parsed[3]), 0, 255);
			Vector color = Vector(iR, iG, iB);
			g_GlowColors[parsed[0].ToLowercase()] = color;
		}
		file.Close();
	}
}

CTextMenu@ glowMenu = null;
void glowMenuCallBack(CTextMenu@ mMenu, CBasePlayer@ pPlayer, int iPage, const CTextMenuItem@ mItem)
{
	if(mItem !is null && pPlayer !is null)
	{
		if(mItem.m_szName == "<off>")
		{
			string steamId = getFixedSteamId(pPlayer);
			if(g_PlayerGlows.exists(steamId) && steamId != "")
			{
				if(g_cvarSilence.GetBool())
				{
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Glow menu] You are no longer glowing.\n");
				}else{
					g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Glow menu] " + pPlayer.pev.netname + " is no longer glowing.\n");
				}

				setRenderMode(pPlayer, kRenderNormal, kRenderFxNone, 255, Vector(255,255,255), false);
				g_PlayerGlows.delete(steamId);
				return;
			}

			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Glow menu] You don't have a glow!\n");
			return;
		}

		if(g_cvarSilence.GetBool())
		{
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Glow menu] You are now glowing "+mItem.m_szName+".\n");
		}else{
			g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Glow menu] " + pPlayer.pev.netname + " is now glowing "+mItem.m_szName+".\n");
		}

		setRenderMode(pPlayer, kRenderNormal, kRenderFxGlowShell, 4, Vector(g_GlowColors[mItem.m_szName]), true);
	}
}

HookReturnCode ClientSay(SayParameters@ pParams)
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ cArguments = pParams.GetArguments();
	bool bSilent = g_cvarSilence.GetBool();

	if(cArguments.ArgC() >= 2)
	{
		if(cArguments.Arg(0).ToLowercase() == "glow")
		{
			if(!g_bHasColors)
			{ // most likely as_reloadplugins
				if(@glowMenu !is null)
				{
					glowMenu.Unregister();
					@glowMenu = null;
				}

				g_GlowColors.deleteAll();
				//g_PlayerGlows.deleteAll();
				ReadColors();
				g_bHasColors = true;
			}

			pParams.ShouldHide = g_cvarHideChat.GetBool();

			if(cArguments.Arg(1).ToLowercase() == "off")
			{
				if(bSilent)
				{
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Glow] You are no longer glowing.\n");
				}else{
					g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Glow] " + pPlayer.pev.netname + " is no longer glowing.\n");
				}

				setRenderMode(pPlayer, kRenderNormal, kRenderFxNone, 255, Vector(255,255,255), false);
				string steamId = getFixedSteamId(pPlayer);
				if(g_PlayerGlows.exists(steamId))
					g_PlayerGlows.delete(steamId);
			}else if(cArguments.Arg(1).ToLowercase() == "menu")
			{
				if(@glowMenu is null)
				{
					@glowMenu = CTextMenu(glowMenuCallBack);
					glowMenu.SetTitle("Glow menu: ");
					glowMenu.AddItem("<off>", null);
					array<string> colorNames = g_GlowColors.getKeys();
					colorNames.sortAsc();
					for(uint i = 0; i < colorNames.length(); i++)
					{
						glowMenu.AddItem(colorNames[i].ToLowercase(), null);
					}

					glowMenu.Register();
					glowMenu.Open(0, 0, pPlayer);
				}else{
					glowMenu.Open(0, 0, pPlayer);
				}
			}else{
				if(g_GlowColors.exists(cArguments.Arg(1).ToLowercase()))
				{
					if(bSilent)
					{
						g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Glow] You are now glowing "+cArguments.Arg(1).ToLowercase()+".\n");
					}else{
						g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Glow] " + pPlayer.pev.netname + " is now glowing "+cArguments.Arg(1).ToLowercase()+".\n");
					}

					setRenderMode(pPlayer, kRenderNormal, kRenderFxGlowShell, 4, Vector(g_GlowColors[cArguments.Arg(1).ToLowercase()]), true);
				}
				else if( !cArguments.Arg(3).IsEmpty() && g_Utility.IsStringInt( cArguments.Arg(3) ) )
				{
					Vector VecColor = Vector( atoi( cArguments.Arg(1) ), atoi( cArguments.Arg(2) ), atoi( cArguments.Arg(3) ) );
					setRenderMode(pPlayer, kRenderNormal, kRenderFxGlowShell, 4, VecColor, true);
				}
				else
				{
					if(bSilent)
					{
						g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Glow] No such color, try typing glow menu?\n");
					}else{
						g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Glow] No such color, try typing glow menu?\n");
					}
				}
			}

			return HOOK_HANDLED;
		}
	}

	return HOOK_CONTINUE;
}

void setRenderMode(CBasePlayer@ pPlayer, int rendermode, int renderfx, int renderamt, Vector color, bool savesettings)
{
	if(savesettings)
	{
		string steamId = getFixedSteamId(pPlayer);
		g_PlayerGlows[steamId] = color;
	}

	pPlayer.pev.rendermode = rendermode;
	pPlayer.pev.renderfx = renderfx;
	pPlayer.pev.renderamt = renderamt;
	pPlayer.pev.rendercolor = color;
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{
	string steamId = getFixedSteamId(pPlayer);
	if(g_PlayerGlows.exists(steamId))
		g_Scheduler.SetTimeout("plrPostSpawn", 1.0f, g_EngineFuncs.IndexOfEdict(pPlayer.edict()), Vector(g_PlayerGlows[steamId]));

	return HOOK_CONTINUE;
}

void plrPostSpawn(int &in iIndex, Vector &in color)
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iIndex);

	if (pPlayer is null || !pPlayer.IsConnected())
		return;

	setRenderMode(pPlayer, kRenderNormal, kRenderFxGlowShell, 4, color, false);
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer)
{
	string steamId = getFixedSteamId(pPlayer);
	if(g_PlayerGlows.exists(steamId))
		g_PlayerGlows.delete(steamId);

	return HOOK_CONTINUE;
}
