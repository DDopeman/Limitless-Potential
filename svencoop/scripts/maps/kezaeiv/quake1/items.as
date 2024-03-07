// [19/10/2019] turns out using BasePlayerItem is not the way to make actual items,
// it's only for inventory items (i.e. guns and item_inventory)

const int Q1_POWER_QUAD = 1;
const int Q1_POWER_SUIT = 2;
const int Q1_POWER_PENT = 4;
const int Q1_POWER_RING = 8;
const int Q1_POWER_ALL  = 255;


// item icon stuff
// all icons are contained in a sprite sheet
const string Q1_ICON_SPR = "quake1/huditems.spr";
const int Q1_ICON_W = 64; // size of individual icon
const int Q1_ICON_H = 64;

mixin class item_qgeneric {
  string m_sModel;
  string m_sSound;
  float m_fRespawnTime = 30.0;
  bool m_bRespawns = true;
  bool m_bRotates = true;

  void CommonSpawn() {
    Precache();
    BaseClass.Spawn();
    self.pev.movetype = MOVETYPE_TOSS;
    self.pev.solid = SOLID_TRIGGER;
    g_EntityFuncs.SetModel(self, m_sModel);
    g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 16));
    if (g_EngineFuncs.DropToFloor(self.edict()) != 1) {
      // oh shit, we're in the floor or something, better freeze in place
      self.pev.movetype = MOVETYPE_NONE;
      g_Game.AlertMessage(at_warning, "Item `%1` (a %2) is fucked!\n", self.pev.targetname, self.pev.classname);
    }
    self.pev.noise = m_sSound;
    SetThink(m_bRotates ? ThinkFunction(this.ItemThink) : null);
    SetTouch(TouchFunction(this.ItemTouch));
    self.pev.nextthink = g_Engine.time + 0.2;
  }

  void Precache() {
    g_Game.PrecacheModel(m_sModel);
    g_SoundSystem.PrecacheSound(m_sSound);
  }

  void ItemThink() {
    // yaw around slowly
    self.pev.angles.y += 2.0;
    self.pev.nextthink = g_Engine.time + 0.01;
  }

  void ItemTouch(CBaseEntity@ pOther) {
    if (pOther is null) return;
    if (!pOther.IsPlayer()) return;
    if (pOther.pev.health <= 0) return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);

    if (PickedUp(pPlayer)) {
      SetTouch(null);
      self.SUB_UseTargets(pOther, USE_TOGGLE, 0);
      g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NONE);
      if (m_bRespawns)
        Respawn();
      else
        Die();
    }
  }

  // despite the name, this is called when the item gets picked
  // to set up the respawn timer and shit
  CBaseEntity@ Respawn() {
    self.pev.effects |= EF_NODRAW;
    SetThink(ThinkFunction(this.Materialize));
    self.pev.nextthink = g_Engine.time + m_fRespawnTime;
    return self;
  }

  // but this is called when the item is ready to respawn
  void Materialize() {
    if ((self.pev.effects & EF_NODRAW) != 0) {
      g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "kezaeiv/c_wep/misc/poweruprespawn.wav", 1.0, ATTN_NONE);
      self.pev.effects &= ~EF_NODRAW;
      self.pev.effects |= EF_MUZZLEFLASH;
    }
    SetThink(m_bRotates ? ThinkFunction(this.ItemThink) : null);
    SetTouch(TouchFunction(this.ItemTouch));
    self.pev.nextthink = g_Engine.time + 0.01;
  }

  void Die() {
    g_EntityFuncs.Remove(self);
  }
}

mixin class item_qpowerup {
  string m_sWarnSnd;
  string m_sUseSnd;
  string m_sPlayerKey;
  int m_iPowerType;

  bool PickedUp(CBasePlayer@ pPlayer) {
    float flEndTime = g_Engine.time + 30.0;
    ApplyEffect(pPlayer);
    pPlayer.GetCustomKeyvalues().SetKeyvalue(m_sPlayerKey, flEndTime);
    g_Scheduler.SetTimeout("q1_RemovePowerup", 30.0, @pPlayer, m_iPowerType);
    if (m_sWarnSnd != "")
      g_Scheduler.SetTimeout("q1_PowerupWarning", 26.0, @pPlayer, m_sWarnSnd, m_sPlayerKey);
    g_Scheduler.SetInterval("q1_DrawPowerups", 1.0, 31, @pPlayer);
    q1_DrawPowerups(pPlayer);
    return true;
  }

  void PowerupSpawn() {
    m_fRespawnTime = 120.0;
    if (m_sWarnSnd != "") g_SoundSystem.PrecacheSound(m_sWarnSnd);
    if (m_sUseSnd != "") g_SoundSystem.PrecacheSound(m_sUseSnd);
    CommonSpawn();
  }
}

class item_qquad : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/kezaeiv/icons/pu/mk_logo_blue.mdl";
    m_sSound = "kezaeiv/c_wep/misc/quaddamage.wav";
    m_sUseSnd = "kezaeiv/c_wep/misc/quad.wav";
    m_sWarnSnd = "kezaeiv/c_wep/misc/wearoff.wav";
    m_sPlayerKey = "$qfl_timeQuad";
    m_iPowerType = Q1_POWER_QUAD;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.z = 255;
    pPlayer.pev.renderamt = 4;
  }
}

class item_qinvul : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/kezaeiv/icons/pu/mk_logo_purple.mdl";
    m_sSound = "kezaeiv/c_wep/misc/protection.wav";
    m_sUseSnd = "kezaeiv/c_wep/misc/protect.wav";
    m_sWarnSnd = "kezaeiv/c_wep/misc/wearoff.wav";
    m_sPlayerKey = "$qfl_timePent";
    m_iPowerType = Q1_POWER_PENT;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.x = 255;
    pPlayer.pev.rendercolor.z = 80;
    pPlayer.pev.renderamt = 4;
    pPlayer.pev.flags |= FL_GODMODE;
  }
}

class item_qsuit : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/kezaeiv/icons/pu/mk_logo_cyan.mdl";
    m_sSound = "kezaeiv/c_wep/misc/suit.wav";
    m_sUseSnd = "";
    m_sWarnSnd = "kezaeiv/c_wep/misc/wearoff.wav";
    m_sPlayerKey = "$qfl_timeSuit";
    m_iPowerType = Q1_POWER_SUIT;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.y = 255;
    pPlayer.pev.rendercolor.z = 95;
    pPlayer.pev.renderamt = 4;
    pPlayer.pev.flags |= FL_IMMUNE_WATER | FL_IMMUNE_LAVA | FL_IMMUNE_SLIME;
  }
}

class item_qinvis : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/kezaeiv/icons/pu/mk_logo_transparent.mdl";
    m_sSound = "kezaeiv/c_wep/misc/invisibility.wav";
    m_sUseSnd = "";
    m_sWarnSnd = "kezaeiv/c_wep/misc/wearoff.wav";
    m_sPlayerKey = "$qfl_timeRing";
    m_iPowerType = Q1_POWER_RING;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.effects |= EF_NODRAW;
    pPlayer.pev.flags |= FL_NOTARGET;
  }
}


void q1_RemovePowerup(CBasePlayer @pPlayer, int kind) {
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  const float flQuad = pCustom.GetKeyvalue("$qfl_timeQuad").GetFloat();
  const float flPent = pCustom.GetKeyvalue("$qfl_timePent").GetFloat();
  const float flSuit = pCustom.GetKeyvalue("$qfl_timeSuit").GetFloat();
  const float flRing = pCustom.GetKeyvalue("$qfl_timeRing").GetFloat();

  const float flTime = g_Engine.time + 0.1; // allow a slight error

  if ((kind & Q1_POWER_RING) != 0 && flRing < flTime) {
    pPlayer.pev.effects &= ~EF_NODRAW;
    pPlayer.pev.flags &= ~FL_NOTARGET;
  }

  if ((kind & Q1_POWER_QUAD) != 0 && flQuad < flTime)
    pPlayer.pev.rendercolor.z = 0;

  if ((kind & Q1_POWER_PENT) != 0 && flPent < flTime) {
    pPlayer.pev.flags &= ~FL_GODMODE;
    pPlayer.pev.rendercolor.x = 0;
    pPlayer.pev.rendercolor.z = 0;
  }

  if ((kind & Q1_POWER_SUIT) != 0 && flSuit < flTime) {
    pPlayer.pev.flags &= ~(FL_IMMUNE_WATER | FL_IMMUNE_LAVA | FL_IMMUNE_SLIME);
    pPlayer.pev.rendercolor.y = 0;
    pPlayer.pev.rendercolor.z = 0;
  }

  if (kind == Q1_POWER_ALL || (pPlayer.pev.rendercolor.x == 0 && pPlayer.pev.rendercolor.y == 0 && pPlayer.pev.rendercolor.z == 0)) {
    pPlayer.pev.renderfx = kRenderFxNone;
    pPlayer.pev.renderamt = 0;
  }
}

void q1_DrawPowerups(CBasePlayer @pPlayer) {
  const auto NORM_COLOR = RGBA(100, 130, 200, 255);
  const auto WARN_COLOR = RGBA(255, 0, 0, 255);

  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  const float flQuad = pCustom.GetKeyvalue("$qfl_timeQuad").GetFloat() - g_Engine.time;
  const float flSuit = pCustom.GetKeyvalue("$qfl_timeSuit").GetFloat() - g_Engine.time;
  const float flPent = pCustom.GetKeyvalue("$qfl_timePent").GetFloat() - g_Engine.time;
  const float flRing = pCustom.GetKeyvalue("$qfl_timeRing").GetFloat() - g_Engine.time;
  const array<float> powTimes = { flQuad, flSuit, flPent, flRing };

  HUDSpriteParams sparm;
  sparm.flags = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y;
  sparm.spritename = Q1_ICON_SPR;
  sparm.color2 = NORM_COLOR;
  sparm.holdTime = 3.0; // make sure it doesn't disappear before next update
  sparm.effect = HUD_EFFECT_NONE;
  sparm.x = -12;
  sparm.y = 128;
  sparm.channel = 4; // in case something wants 0-3
  sparm.width = Q1_ICON_W;
  sparm.height = Q1_ICON_H;
  sparm.top = 0;

  HUDNumDisplayParams nparm;
  nparm.flags = HUD_NUM_RIGHT_ALIGN | HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y;
  nparm.color2 = NORM_COLOR;
  nparm.holdTime = 3.0;
  nparm.maxdigits = 2;
  nparm.defdigits = 2;
  nparm.x = -88;

  for (uint i = 0; i < powTimes.length(); ++i, sparm.channel += 2) {
    if (powTimes[i] > 0.0) {
      sparm.left = Q1_ICON_W * i;
      // turn red when ~5 seconds left
      nparm.color1 = sparm.color1 = (powTimes[i] > 3.95) ? NORM_COLOR : WARN_COLOR;
      nparm.value = powTimes[i];
      nparm.y = sparm.y + 20;
      nparm.channel = sparm.channel + 1;
      g_PlayerFuncs.HudCustomSprite(pPlayer, sparm); // current channel
      g_PlayerFuncs.HudNumDisplay(pPlayer, nparm);   // current channel + 1
      sparm.y += Q1_ICON_H + 8;
    } else {
      // clean up
      g_PlayerFuncs.HudToggleElement(pPlayer, sparm.channel, false);
      g_PlayerFuncs.HudToggleElement(pPlayer, sparm.channel + 1, false);
    }
  }
}

bool q1_CheckQuad(CBasePlayer @pPlayer) {
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  float flQuad = pCustom.GetKeyvalue("$qfl_timeQuad").GetFloat();
  return flQuad > g_Engine.time;
}

void q1_PowerupWarning(CBasePlayer @pPlayer, string szSound, string szKey) {
  const float flTime = pPlayer.GetCustomKeyvalues().GetKeyvalue(szKey).GetFloat() - g_Engine.time;
  if (flTime > 2.0 && flTime < 4.0) // sanity check in case we picked up another powerup instance
    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, szSound, 0.7, ATTN_NORM, 0, 100);
}

void q1_RegisterItems() {
  // precache item and ammo models right away
  g_Game.PrecacheModel("models/kezaeiv/icons/pu/mk_logo_purple.mdl");
  g_Game.PrecacheModel("models/kezaeiv/icons/pu/mk_logo_cyan.mdl");
  g_Game.PrecacheModel("models/kezaeiv/icons/pu/mk_logo_blue.mdl");
  g_Game.PrecacheModel("models/kezaeiv/icons/pu/mk_logo_transparent.mdl");
  g_SoundSystem.PrecacheSound("kezaeiv/c_wep/misc/poweruprespawn.wav");

  g_CustomEntityFuncs.RegisterCustomEntity("item_qquad", "item_qquad");
  g_ItemRegistry.RegisterItem("item_qquad", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qinvul", "item_qinvul");
  g_ItemRegistry.RegisterItem("item_qinvul", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qsuit", "item_qsuit");
  g_ItemRegistry.RegisterItem("item_qsuit", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qinvis", "item_qinvis");
  g_ItemRegistry.RegisterItem("item_qinvis", "quake1/items");
}
