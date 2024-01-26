void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("rzlx");
  g_Module.ScriptInfo.SetContactInfo("undefined");
  ChatSounds::ScriptInit();
}
void MapInit() {
  ChatSounds::MapInit();
}

namespace ChatSounds
{
auto g_csSpamDelay = CCVar("spamDelay", 0.1, "Time between each client ChatSound", ConCommandFlag::AdminOnly);

class ChatSound {
  private string _k;
  private array<string> _p;
  ChatSound() { }
  ChatSound(const string& in k, const array<string>& in p) { _k = k; _p = p; }
  void Precache() {
    for (uint i = 0; i < _p.size(); i++) {
      g_Game.PrecacheGeneric("sound/" + _p[i]);
      g_Log.PrintF("[Console] [ChatSounds] Precaching: %1\n", _p[i]);
    }
  }
  string GetKey() {
    return (_k + ((_p.size() > 1) ? " (" + _p.size() + ")" : ""));
  }
  string GetPath(int i = -1) {
    return _p[(i < 0) ? Math.RandomLong(0, _p.size()-1) : Math.clamp(0, _p.size()-1, i)];
  }
}

class ClientConfig {
  private int _p = 100, _v = 60;
  private array<string> _m;
  int pitch {
    get const { return _p; } set { _p = Math.clamp(80, 130, value); }
  }
  int volume {
    get const { return _v; } set { _v = Math.clamp(0, 100, value); }
  }
  bool IsMuted(const string& in id) {
    return (_m.find(id) > -1);
  }
  bool AddMuted(const string& in id) {
    if (IsMuted(id)) return false;
    _m.insertLast(id);
    return true;
  }
  bool SubMuted(const string& in id) {
    auto index = _m.find(id);
    if (index < 0) return false;
    _m.removeAt(index);
    return true;
  }
  bool UnMuteAll() {
    if (_m.size() < 1) return false;
    _m.resize(0);
    return true;
  }
}

auto g_csClientSayEvent = g_Hooks.RegisterHook(Hooks::Player::ClientSay, @OnClientSay);
auto g_csListSounds = CClientCommand("listsounds", "List all chat sounds", @ListSounds);
auto g_csVolume = CClientCommand("volume", "Change your ChatSounds volume", @Volume);
auto g_csPitch = CClientCommand("pitch", "Sets the pitch at which your sound play (80-130)", @Pitch);
auto g_csStop = CClientCommand("stop", "Stop playing sounds", @Stop);
auto g_csMute = CClientCommand("mute", 'Mute sounds from player, use target "STEAM_ID" or "nickname"', @Mute);

auto g_clientConfigs = dictionary(); // { uuid: ClientConfig }
auto g_nextSoundTime = array<float>(33, 0.0);

auto g_chatSounds = dictionary(); // { key: ChatSound }
auto g_chatSoundKeys = array<string>();

auto g_cache = array<ClientConfig@>(33, null);
auto g_fileSize = uint(0);
auto g_connectEvent = g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @OnClientPutInServer);
auto g_disconnectEvent = g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @OnClientDisconnect);

void ScriptInit() {
  @g_csSpamDelay = CCVar("spamDelay", 0.1, "Time between each client ChatSound", ConCommandFlag::AdminOnly);

  ReadSounds();

  if (g_Engine.time > 1.0) {
    for (int i = 1; i <= g_PlayerFuncs.GetNumPlayers(); i++)
      OnClientPutInServer(g_PlayerFuncs.FindPlayerByIndex(i));
  }
}
void MapInit() {
  g_nextSoundTime = array<float>(33, 0.0);

  if (SoundsChanged())
    ReadSounds();

  if (!g_chatSounds.isEmpty()) {
    for (uint i = 0; i < g_chatSoundKeys.length(); i++)
      cast<ChatSound>(g_chatSounds[g_chatSoundKeys[i]]).Precache();
  }
}
bool SoundsChanged() {
  auto changed = false;
  try {
    auto file = g_FileSystem.OpenFile("scripts/plugins/store/ChatSounds.txt", OpenFile::READ);
    changed = file.GetSize() != g_fileSize;
    file.Close();
  } catch {
    g_Log.PrintF("[Error] [ChatSounds] Could not get txt file size\n");
  }
  return changed;
}
void ReadSounds() {
  g_chatSounds.deleteAll();
  g_chatSoundKeys.resize(0);

  auto line = string();
  auto parsed = array<string>();
  auto chatSound = ChatSound();

  try {
    auto file = g_FileSystem.OpenFile("scripts/plugins/store/ChatSounds.txt", OpenFile::READ);
    g_fileSize = file.GetSize();

    if (file.IsOpen()) {
      while (!file.EOFReached()) {
        file.ReadLine(line);
        line.Trim();

        if (line.IsEmpty() || line.StartsWith("#") || line.StartsWith("//"))
          continue;

        parsed = line.Split(" ");
        if (parsed.length() < 2)
          continue;

        line = parsed[0].ToLowercase();
        parsed.removeAt(0);

        g_chatSoundKeys.insertLast(line);
        g_chatSounds[line] = ChatSound(line, parsed);
        // g_Log.PrintF("[Console] [ChatSounds] Adding %1 to listsound", parsed);
      }
    }

    g_chatSoundKeys.sortAsc();
    file.Close();
  } catch {
    g_Log.PrintF("[Error] [ChatSounds] Could not open txt file\n");
  }
}
ClientConfig@ GetPlayerConfig(edict_t@ edict) {
  auto authId = g_EngineFuncs.GetPlayerAuthId(edict);
  if (!g_clientConfigs.exists(authId)) {
    g_clientConfigs[authId] = ClientConfig();
  }
  return cast<ClientConfig>(g_clientConfigs[authId]);
}
void Speak(const string& in soundPath, const string& in speakerId, int pitch) {
  auto target = EHandle().GetEntity();
  auto command = string();

  for (int i = 1; i <= g_PlayerFuncs.GetNumPlayers(); i++) {
    @target = g_EntityFuncs.Instance(i);
    if (target is null || !target.IsNetClient())
      continue;

    if (g_cache[i].IsMuted(speakerId))
      continue;

    if (snprintf(command, ';speak "%1(p%3 v%2)";', soundPath, g_cache[i].volume, pitch)) {
      g_Log.PrintF("[Console] [ChatSounds] Sending '%1' to '%2'\n", command, target.pev.netname);

      NetworkMessage message(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, target.edict());
        message.WriteString(command);
      message.End();
    } else {
      g_Log.PrintF("[Error] [ChatSounds] Could not send sound to %1\n", target.pev.netname);
    }
  }
}
HookReturnCode OnClientSay(SayParameters@ params) {
  auto arguments = params.GetArguments();
  if (arguments.ArgC() > 0) {
    auto arg0 = arguments.Arg(0).ToLowercase();
    auto player = params.GetPlayer();

    if (arg0 == "cs.help") {
      g_PlayerFuncs.SayText(player, "[ChatSounds] Now check your console for help\n");
      NetworkMessage message(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, player.edict());
        message.WriteString(
          ';as_findcommands "*.listsounds"'
          ';as_findcommands "*.pitch"'
          ';as_findcommands "*.volume"'
          ';as_findcommands "*.stop"'
          ';as_findcommands "*.mute";'
        );
      message.End();
      return HOOK_CONTINUE;
    }

    if (arg0 == ".listsound" || arg0 == ".pitch" || arg0 == ".volume" || arg0 == ".stop" || arg0 == ".mute") {
      if (arg0 == ".listsound")
        g_PlayerFuncs.SayText(player, "[ChatSounds] Sound list sent to your console\n");

      NetworkMessage message(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, player.edict());
        message.WriteString(arguments.GetCommandString());
      message.End();

      params.ShouldHide = true;
      return HOOK_CONTINUE;
    }

    auto exArg = -1;
    auto char0 = arg0[arg0.Length()-1];
    auto found = g_chatSounds.exists(arg0);

    if (!found && isdigit(char0)) {
      exArg = atoi(char0)-1;
      arg0.Resize(arg0.Length()-1);
      found = g_chatSounds.exists(arg0);
    }

    if (found) {
      if (g_nextSoundTime[player.entindex()] > g_Engine.time) {
        g_PlayerFuncs.SayText(
          player, 
          "[ChatSounds] Wait " + 
          formatFloat(g_nextSoundTime[player.entindex()] - g_Engine.time, "", 0, 2) + 
          " seconds\n"
        );
        params.ShouldHide = true;
        return HOOK_CONTINUE;
      }

      auto path = cast<ChatSound>(g_chatSounds[arg0]).GetPath(exArg);
      path = path.SubString(0, path.Find("."));

      Speak(
        path, 
        g_EngineFuncs.GetPlayerAuthId(player.edict()), 
        arguments.ArgC() > 1 && g_Utility.IsStringInt(arguments.Arg(1)) 
          ? Math.clamp(80, 130, atoi(arguments.Arg(1))) 
          : g_cache[player.entindex()].pitch
      );
      g_nextSoundTime[player.entindex()] = g_Engine.time + g_csSpamDelay.GetFloat();
    }
  }
  return HOOK_CONTINUE;
}
void ListSounds(const CCommand@ arguments) {
  auto player = g_ConCommandSystem.GetCurrentPlayer();

  g_PlayerFuncs.ClientPrint(player, HUD_PRINTCONSOLE, "AVAILABLE SOUND TRIGGERS\n");
  g_PlayerFuncs.ClientPrint(player, HUD_PRINTCONSOLE, "------------------------\n");

  auto message = string();
  for (uint i = 0; i < g_chatSoundKeys.length(); ++i) {
    message += cast<ChatSound>(g_chatSounds[g_chatSoundKeys[i]]).GetKey() + " | ";
    if (i % 5 == 0) {
      g_PlayerFuncs.ClientPrint(player, HUD_PRINTCONSOLE, message);
      message = "";
    }
  }
  if (message.Length() > 2) {
    message.Resize(message.Length()-2);
    g_PlayerFuncs.ClientPrint(player, HUD_PRINTCONSOLE, message);
  }
  g_PlayerFuncs.ClientPrint(player, HUD_PRINTCONSOLE, "\n");
}
void Pitch(const CCommand@ arguments) {
  if (arguments.ArgC() < 2)
    return;

  auto player = g_ConCommandSystem.GetCurrentPlayer();
  g_cache[player.entindex()].pitch = atoi(arguments.Arg(1));
  g_PlayerFuncs.SayText(player, "[ChatSounds] Pitch set to: " + g_cache[player.entindex()].pitch + "\n");
}
void Volume(const CCommand@ arguments) {
  if (arguments.ArgC() < 2)
    return;

  auto player = g_ConCommandSystem.GetCurrentPlayer();
  g_cache[player.entindex()].volume = atoi(arguments.Arg(1));
  g_PlayerFuncs.SayText(player, "[ChatSounds] Volume set to: " + g_cache[player.entindex()].volume + "\n");
}
void Stop(const CCommand@ arguments) {
  auto player = g_ConCommandSystem.GetCurrentPlayer();

  NetworkMessage message(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, player.edict());
    message.WriteString(";stopsound;");
  message.End();

  g_PlayerFuncs.SayText(player, "[ChatSounds] Stopping sounds...\n");
}
void Mute(const CCommand@ arguments) {
  auto arg1 = arguments.Arg(1).ToUppercase();
  auto player = g_ConCommandSystem.GetCurrentPlayer();

  if (arg1.IsEmpty()) {
    if (g_cache[player.entindex()].UnMuteAll()) {
      g_PlayerFuncs.SayText(player, "[ChatSounds] Unmuted everyone\n");
    } else {
      g_PlayerFuncs.SayText(player, "[ChatSounds] No one is muted\n");
    }
  } else if (arg1 == "ALL") {
    auto count = 0;
    auto target = EHandle().GetEntity();

    for (int i = 1; i < g_PlayerFuncs.GetNumPlayers(); i++) {
      @target = g_EntityFuncs.Instance(i);
      if (target is null || !target.IsNetClient() || player.entindex() == target.entindex())
        continue;

      if (g_cache[player.entindex()].AddMuted(g_EngineFuncs.GetPlayerAuthId(target.edict())))
        count++;
    }

    if (count > 0) {
      NetworkMessage message(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, player.edict());
        message.WriteString(";stopsound;");
      message.End();

      g_PlayerFuncs.SayText(player, "[ChatSounds] Added " + count + " player(s) to mute list\n");
    } else {
      g_PlayerFuncs.SayText(player, "[ChatSounds] You've already muted everyone here\n");
    }
  } else {
    auto found = false;

    if (arg1.StartsWith("STEAM_0:")) {
      auto id = string();
      auto target = EHandle().GetEntity();

      for (int i = 1; i < g_PlayerFuncs.GetNumPlayers(); i++) {
        @target = g_EntityFuncs.Instance(i);
        if (target is null || !target.IsNetClient() || player.entindex() == target.entindex())
          continue;

        id = g_EngineFuncs.GetPlayerAuthId(target.edict());
        if (arg1 != id)
          continue;

        found = true;
        break;
      }

      if (found && g_cache[player.entindex()].AddMuted(id))
        g_PlayerFuncs.SayText(player, "[ChatSounds] Muted player: " + target.pev.netname + "\n");
    } else {
      auto target = g_PlayerFuncs.FindPlayerByName(arg1, false);
      if (target !is null && g_cache[player.entindex()].AddMuted(g_EngineFuncs.GetPlayerAuthId(target.edict()))) {
        g_PlayerFuncs.SayText(player, "[ChatSounds] Muted player: " + target.pev.netname + "\n");
        found = true;
      }
    }

    if (!found)
      g_PlayerFuncs.SayText(player, "[ChatSounds] Target not found or is alredy muted\n");
  }
}
HookReturnCode OnClientPutInServer(CBasePlayer@ player) {
  if (player is null)
    return HOOK_CONTINUE;

  @g_cache[player.entindex()] = GetPlayerConfig(player.edict());
  return HOOK_CONTINUE;
}
HookReturnCode OnClientDisconnect(CBasePlayer@ player) {
  if (player is null)
    return HOOK_CONTINUE;

  @g_cache[player.entindex()] = null;
  return HOOK_CONTINUE;
}

}