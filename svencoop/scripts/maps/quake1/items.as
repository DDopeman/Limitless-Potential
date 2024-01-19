// [19/10/2019] turns out using BasePlayerItem is not the way to make actual items,
// it's only for inventory items (i.e. guns and item_inventory)

const int Q1_POWER_QUAD = 1;
const int Q1_POWER_SUIT = 2;
const int Q1_POWER_PENT = 4;
const int Q1_POWER_RING = 8;
const int Q1_POWER_ALL  = 255;

const int Q1_KEY_SILVER = 1;
const int Q1_KEY_GOLD   = 2;
const int Q1_KEY_RUNE1  = 4;
const int Q1_KEY_RUNE2  = 8;
const int Q1_KEY_RUNE3  = 16;

// set in base-themed maps manually (q1_e1m1, q1_e2m1, ...)
const int Q1_KEY_SF_KEYCARD = 65536;

// item icon stuff
// all icons are contained in a sprite sheet
const string Q1_ICON_SPR = "quake1/huditems.spr";
const int Q1_ICON_W = 64; // size of individual icon
const int Q1_ICON_H = 64;

// store collected keys globally
// TODO: recall runes?
int q1_Keys = 0;

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
    self.pev.angles.y += 1.25;
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
      g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM);
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
      g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "quake1/itemspawn.wav", 1.0, ATTN_NORM);
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
      g_Scheduler.SetTimeout("q1_PowerupWarning", 27.0, @pPlayer, m_sWarnSnd, m_sPlayerKey);
    g_Scheduler.SetInterval("q1_DrawPowerups", 1.0, 31, @pPlayer);
    q1_DrawPowerups(pPlayer);
    return true;
  }

  void PowerupSpawn() {
    m_fRespawnTime = 60.0;
    if (m_sWarnSnd != "") g_SoundSystem.PrecacheSound(m_sWarnSnd);
    if (m_sUseSnd != "") g_SoundSystem.PrecacheSound(m_sUseSnd);
    CommonSpawn();
  }
}

class item_qquad : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/quake1/w_quad.mdl";
    m_sSound = "quake1/powerups/quad.wav";
    m_sUseSnd = "quake1/powerups/quad_s.wav";
    m_sWarnSnd = "quake1/powerups/quad_warn.wav";
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
    m_sModel = "models/quake1/w_invul.mdl";
    m_sSound = "quake1/powerups/invul.wav";
    m_sUseSnd = "quake1/powerups/invul_s.wav";
    m_sWarnSnd = "quake1/powerups/invul_warn.wav";
    m_sPlayerKey = "$qfl_timePent";
    m_iPowerType = Q1_POWER_PENT;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.x = 255;
    pPlayer.pev.renderamt = 4;
    pPlayer.pev.flags |= FL_GODMODE;
  }
}

class item_qsuit : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/quake1/w_suit.mdl";
    m_sSound = "quake1/powerups/suit.wav";
    m_sUseSnd = "";
    m_sWarnSnd = "quake1/powerups/suit_warn.wav";
    m_sPlayerKey = "$qfl_timeSuit";
    m_iPowerType = Q1_POWER_SUIT;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.y = 255;
    pPlayer.pev.renderamt = 4;
    pPlayer.pev.flags |= FL_IMMUNE_WATER | FL_IMMUNE_LAVA | FL_IMMUNE_SLIME;
  }
}

class item_qinvis : ScriptBaseEntity, item_qgeneric, item_qpowerup {
  void Spawn() {
    m_sModel = "models/quake1/w_invis.mdl";
    m_sSound = "quake1/powerups/invis.wav";
    m_sUseSnd = "";
    m_sWarnSnd = "quake1/powerups/invis_warn.wav";
    m_sPlayerKey = "$qfl_timeRing";
    m_iPowerType = Q1_POWER_RING;
    PowerupSpawn();
  }

  void ApplyEffect(CBasePlayer@ pPlayer) {
    pPlayer.pev.effects |= EF_NODRAW;
    pPlayer.pev.flags |= FL_NOTARGET;
  }
}

mixin class item_qarmor {
  int m_iArmor;

  bool PickedUp(CBasePlayer@ pPlayer) {
    if (pPlayer.pev.armorvalue >= m_iArmor)
      return false;
    pPlayer.pev.armorvalue += m_iArmor;
    if (pPlayer.pev.armorvalue > m_iArmor)
      pPlayer.pev.armorvalue = m_iArmor;
    return true;
  }
}

class item_qarmor1 : ScriptBaseEntity, item_qgeneric, item_qarmor {
  void Spawn() {
    m_iArmor = 25;
    m_sModel = "models/quake1/w_armor_g.mdl";
    m_sSound = "quake1/armor.wav";
    CommonSpawn();
  }
}

class item_qarmor2 : ScriptBaseEntity, item_qgeneric, item_qarmor {
  void Spawn() {
    m_iArmor = 50;
    m_sModel = "models/quake1/w_armor_y.mdl";
    m_sSound = "quake1/armor.wav";
    CommonSpawn();
  }
}

class item_qarmor3 : ScriptBaseEntity, item_qgeneric, item_qarmor {
  void Spawn() {
    m_iArmor = 100;
    m_sModel = "models/quake1/w_armor_r.mdl";
    m_sSound = "quake1/armor.wav";
    CommonSpawn();
  }
}

// [19/10/2019] keys; they're just dummy items that trigger stuff on pickup
// runes are also keys

mixin class item_qkey {
  int m_iKey;
  string m_sPickupMsg;

  bool PickedUp(CBasePlayer@ pPlayer) {
    m_bRespawns = false;
    q1_Keys |= m_iKey;
    g_PlayerFuncs.ShowMessageAll(m_sPickupMsg);
    return true;
  }
}

class item_qkey1 : ScriptBaseEntity, item_qgeneric, item_qkey {
  void Spawn() {
    m_iKey = Q1_KEY_SILVER;
    m_sPickupMsg = "You got the Silver Key.";
    if ((self.pev.spawnflags & Q1_KEY_SF_KEYCARD) != 0) {
      m_sModel = "models/quake1/w_keycard_silver.mdl";
      m_sSound = "quake1/bkey.wav";
    } else {
      m_sModel = "models/quake1/w_keyrune_silver.mdl";
      m_sSound = "quake1/mkey.wav";
    }
    CommonSpawn();
  }
}

class item_qkey2 : ScriptBaseEntity, item_qgeneric, item_qkey {
  void Spawn() {
    m_iKey = Q1_KEY_GOLD;
    m_sPickupMsg = "You got the Gold Key.";
    if ((self.pev.spawnflags & Q1_KEY_SF_KEYCARD) != 0) {
      m_sModel = "models/quake1/w_keycard_gold.mdl";
      m_sSound = "quake1/bkey.wav";
    } else {
      m_sModel = "models/quake1/w_keyrune_gold.mdl";
      m_sSound = "quake1/mkey.wav";
    }
    CommonSpawn();
  }
}

class item_qrune1 : ScriptBaseEntity, item_qgeneric, item_qkey {
  void Spawn() {
    m_iKey = Q1_KEY_RUNE1;
    m_sPickupMsg = "You got the Rune of Black Magic.";
    m_sModel = "models/quake1/w_rune1.mdl";
    m_sSound = "quake1/rune.wav";
    CommonSpawn();
  }
}

class item_qrune2 : ScriptBaseEntity, item_qgeneric, item_qkey {
  void Spawn() {
    m_iKey = Q1_KEY_RUNE2;
    m_sPickupMsg = "You got the Rune of shit.";
    m_sModel = "models/quake1/w_rune2.mdl";
    m_sSound = "quake1/rune.wav";
    CommonSpawn();
  }
}

class item_qrune3 : ScriptBaseEntity, item_qgeneric, item_qkey {
  void Spawn() {
    m_iKey = Q1_KEY_RUNE3;
    m_sPickupMsg = "You got the Rune of fuck.";
    m_sModel = "models/quake1/w_rune3.mdl";
    m_sSound = "quake1/rune.wav";
    CommonSpawn();
  }
}

// backpack
// gotta make this a separate class for now

class item_qbackpack : ScriptBaseEntity {
  CBasePlayerItem@ m_pWeapon = null;
  int m_iAmmoShells;
  int m_iAmmoNails;
  int m_iAmmoRockets;
  int m_iAmmoCells;

  float m_fDeathTime;

  void Spawn() {
    Precache();
    BaseClass.Spawn();

    self.pev.movetype = MOVETYPE_TOSS;
    self.pev.solid = SOLID_TRIGGER;
    g_EntityFuncs.SetModel(self, "models/quake1/w_backpack.mdl");
    g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 56));

    m_fDeathTime = g_Engine.time + 120.0;
    self.pev.nextthink = g_Engine.time + 0.01;
  }

  void Precache() {
    g_Game.PrecacheModel("models/quake1/w_backpack.mdl");
    g_SoundSystem.PrecacheSound("quake1/ammo.wav");
    g_SoundSystem.PrecacheSound("quake1/weapon.wav");
  }

  void Think() {
    self.pev.angles.y += 1.25;
    if (m_fDeathTime < g_Engine.time)
      Die();
    else
      self.pev.nextthink = g_Engine.time + 0.01;
  }

  void Die() {
    if (m_pWeapon !is null)
      g_EntityFuncs.Remove(m_pWeapon);
    g_EntityFuncs.Remove(self);
  }

  void Touch(CBaseEntity@ pOther) {
    if (pOther is null) return;
    if (!pOther.IsPlayer()) return;
    if (pOther.pev.health <= 0) return;

    int iRemove = 0;
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);

    if (m_iAmmoShells > 0 && pPlayer.GiveAmmo(m_iAmmoShells, "buckshot", 100, false) >= 0)
      iRemove = 1;
    if (m_iAmmoNails > 0 && pPlayer.GiveAmmo(m_iAmmoNails, "bolts", 200, false) >= 0)
      iRemove = 1;
    if (m_iAmmoRockets > 0 && pPlayer.GiveAmmo(m_iAmmoRockets, "rockets", 100, false) >= 0)
      iRemove = 1;
    if (m_iAmmoCells > 0 && pPlayer.GiveAmmo(m_iAmmoCells, "uranium", 100, false) >= 0)
      iRemove = 1;

    if (m_pWeapon !is null && pPlayer.HasNamedPlayerItem(m_pWeapon.GetClassname()) is null) {
      pPlayer.GiveNamedItem(m_pWeapon.GetClassname());
      iRemove = 2;
    }

    if (iRemove > 0) {
      g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, iRemove == 1 ? "quake1/ammo.wav" : "quake1/weapon.wav", 1.0, ATTN_NORM);
      Die();
    }
  }
}

item_qbackpack@ q1_SpawnBackpack(CBaseEntity@ pOwner) {
  Vector vecVelocity = Vector(Math.RandomFloat(-100, 100), Math.RandomFloat(-100, 100), 200);
  CBaseEntity@ pPackEnt = q1_ShootCustomProjectile("item_qbackpack", "models/quake1/w_backpack.mdl", 
                                                   pOwner.pev.origin, vecVelocity, 
                                                   g_vecZero, pOwner);
  return cast<item_qbackpack@>(CastToScriptClass(pPackEnt));
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
  }

  if ((kind & Q1_POWER_SUIT) != 0 && flSuit < flTime) {
    pPlayer.pev.flags &= ~(FL_IMMUNE_WATER | FL_IMMUNE_LAVA | FL_IMMUNE_SLIME);
    pPlayer.pev.rendercolor.y = 0;
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
  g_Game.PrecacheModel("models/quake1/w_quad.mdl");
  g_Game.PrecacheModel("models/quake1/w_invul.mdl");
  g_Game.PrecacheModel("models/quake1/w_invis.mdl");
  g_Game.PrecacheModel("models/quake1/w_suit.mdl");
  g_Game.PrecacheModel("models/quake1/w_armor_g.mdl");
  g_Game.PrecacheModel("models/quake1/w_armor_y.mdl");
  g_Game.PrecacheModel("models/quake1/w_armor_r.mdl");
  g_Game.PrecacheModel("models/quake1/w_backpack.mdl");
  g_SoundSystem.PrecacheSound("quake1/itemspawn.wav");

  g_CustomEntityFuncs.RegisterCustomEntity("item_qquad", "item_qquad");
  g_ItemRegistry.RegisterItem("item_qquad", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qinvul", "item_qinvul");
  g_ItemRegistry.RegisterItem("item_qinvul", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qsuit", "item_qsuit");
  g_ItemRegistry.RegisterItem("item_qsuit", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qinvis", "item_qinvis");
  g_ItemRegistry.RegisterItem("item_qinvis", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qarmor1", "item_qarmor1");
  g_ItemRegistry.RegisterItem("item_qarmor1", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qarmor2", "item_qarmor2");
  g_ItemRegistry.RegisterItem("item_qarmor2", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qarmor3", "item_qarmor3");
  g_ItemRegistry.RegisterItem("item_qarmor3", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qbackpack", "item_qbackpack");
  g_ItemRegistry.RegisterItem("item_qbackpack", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qkey1", "item_qkey1");
  g_ItemRegistry.RegisterItem("item_qkey1", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qkey2", "item_qkey2");
  g_ItemRegistry.RegisterItem("item_qkey2", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qrune1", "item_qrune1");
  g_ItemRegistry.RegisterItem("item_qrune1", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qrune2", "item_qrune2");
  g_ItemRegistry.RegisterItem("item_qrune2", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qrune3", "item_qrune3");
  g_ItemRegistry.RegisterItem("item_qrune3", "quake1/items");
}
