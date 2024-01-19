#include "ammo"
#include "items"
#include "triggers"
#include "monsters/monsters"
#include "weapons/projectile"
#include "weapons/weapon_qaxe"
#include "weapons/weapon_qshotgun"
#include "weapons/weapon_qshotgun2"
#include "weapons/weapon_qnailgun"
#include "weapons/weapon_qnailgun2"
#include "weapons/weapon_qgrenade"
#include "weapons/weapon_qrocket"
#include "weapons/weapon_qthunder"

bool q1_Deathmatch = false;

void q1_InitCommon() {
  q1_PrecachePlayerSounds();

  q1_RegisterProjectiles();
  q1_RegisterAmmo();
  q1_RegisterItems();
  q1_RegisterTriggers();
  q1_RegisterWeapon_AXE();
  q1_RegisterWeapon_SHOTGUN();
  q1_RegisterWeapon_SHOTGUN2();
  q1_RegisterWeapon_NAILGUN();
  q1_RegisterWeapon_NAILGUN2();
  q1_RegisterWeapon_GRENADE();
  q1_RegisterWeapon_ROCKET();
  q1_RegisterWeapon_THUNDER();

  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @q1_PlayerSpawn);
  g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @q1_PlayerKilled);
  g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @q1_PlayerTakeDamage);
  g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, @q1_PlayerPostThink);

  q1_Keys = 0;
}

HookReturnCode q1_PlayerSpawn(CBasePlayer@ pPlayer) {
  q1_SetAmmoCaps(pPlayer);
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  // all the powerup timers are stored as keyvalues to show HUD tickers, yet
  // the powerup effects are actually removed using a scheduled timer
  pCustom.SetKeyvalue("$qfl_timeQuad", 0.0);
  pCustom.SetKeyvalue("$qfl_timeSuit", 0.0);
  pCustom.SetKeyvalue("$qfl_timePent", 0.0);
  pCustom.SetKeyvalue("$qfl_timeRing", 0.0);
  // reset powerup state
  q1_RemovePowerup(pPlayer, Q1_POWER_ALL);
  return HOOK_HANDLED;
}

HookReturnCode q1_PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib) {
  if (pPlayer.pev.health > -30) {
    // AUTHENTIC DEATH SOUNDS
    if (pPlayer.pev.waterlevel >= WATERLEVEL_HEAD) {
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "quake1/player/drown.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
    } else {
      int iNum = Math.RandomLong(1, 5);
      string sName = "quake1/player/death" + string(iNum) + ".wav";
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, sName, Math.RandomFloat(0.95, 1.0), ATTN_NORM);
    }  
  }

  // clear powerups
  q1_RemovePowerup(pPlayer, Q1_POWER_ALL);

  // spawn a backpack, moving player's weapon and ammo into it
  item_qbackpack@ pPack = q1_SpawnBackpack(pPlayer);
  // [19/10/2019] ActiveItem might actually be null on respawn (thanks, KernCore)
  if (pPlayer.m_hActiveItem) {
    @pPack.m_pWeapon = cast<CBasePlayerItem@>(pPlayer.m_hActiveItem.GetEntity());
    pPlayer.RemovePlayerItem(cast<CBasePlayerItem@>(pPlayer.m_hActiveItem.GetEntity()));
  } else {
    @pPack.m_pWeapon = null;
  }
  pPack.m_iAmmoShells = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"));
  pPack.m_iAmmoNails = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bolts"));
  pPack.m_iAmmoRockets = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"));
  pPack.m_iAmmoCells = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("uranium"));
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"), 0);
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bolts"), 0);
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"), 0);
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("uranium"), 0);
  if (pPack.m_pWeapon is null && pPack.m_iAmmoShells == 0 && pPack.m_iAmmoNails == 0 && pPack.m_iAmmoRockets == 0 && pPack.m_iAmmoCells == 0)
    g_EntityFuncs.Remove(pPack.self);

  return HOOK_HANDLED;
}

HookReturnCode q1_PlayerPostThink(CBasePlayer@ pPlayer) {
  q1_PlayPlayerJumpSounds(pPlayer);
  return HOOK_HANDLED;
}

HookReturnCode q1_PlayerTakeDamage(DamageInfo@ pdi) {
  // [19/10/2019] there is a takedamage hook now, so use it for AUTHENTIC PAIN SOUNDS

  // don't scream or override anything if invulnerable, but play the pentagram sound
  if ((pdi.pVictim.pev.flags & FL_GODMODE) != 0) {
    g_SoundSystem.EmitSoundDyn(pdi.pVictim.edict(), CHAN_VOICE, "quake1/powerups/invul_s.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
    return HOOK_CONTINUE;
  }

  int iDmgType = pdi.bitsDamageType;

  // ignore lava/acid/drowning damage if wearing a biosuit
  if (iDmgType == DMG_BURN || iDmgType == DMG_ACID || iDmgType == DMG_RADIATION || iDmgType == DMG_DROWN) {
    float flSuit = pdi.pVictim.GetCustomKeyvalues().GetKeyvalue("$qfl_timeSuit").GetFloat();
    if (flSuit > g_Engine.time) {
      pdi.flDamage = 0.0;
      return HOOK_CONTINUE;
    }
  }

  // HACK: force friendly fire in DM by changing the players to 2 hostile classes before TakeDamage takes place
  if (q1_Deathmatch && pdi.pAttacker !is null && pdi.pAttacker.IsPlayer() && pdi.pAttacker != pdi.pVictim) {
    pdi.pVictim.KeyValue("classify", CLASS_HUMAN_MILITARY);
    pdi.pAttacker.KeyValue("classify", CLASS_PLAYER);
  }

  float flDmg = pdi.flDamage;
  if (flDmg < 5.0) return HOOK_CONTINUE;

  string sName;
  if (pdi.pVictim.pev.waterlevel >= WATERLEVEL_HEAD) {
    // can't really scream underwater
    sName = "quake1/player/wpain" + string(Math.RandomLong(1, 2)) + ".wav";
  } else {
    if ((iDmgType & DMG_BURN) != 0 || (iDmgType & DMG_ACID) != 0) {
      // we're in lava or acid or some shit, scream properly
      sName = "quake1/player/burn" + string(Math.RandomLong(1, 2)) + ".wav";
    } else if ((iDmgType & DMG_FALL) != 0) {
      // fell, break knees
      sName = "quake1/player/fall.wav";
    } else {
      // scream with intensity proportional to damage value
      int iNum = 1 + int(flDmg / 20) + Math.RandomLong(0, 2);
      if (iNum > 6) iNum = 6;
      if (iNum < 1) iNum = 1;
      sName = "quake1/player/pain" + string(iNum) + ".wav";
    }
  }

  g_SoundSystem.EmitSoundDyn(pdi.pVictim.edict(), CHAN_VOICE, sName, Math.RandomFloat(0.95, 1.0), ATTN_NORM);

  return HOOK_CONTINUE;
}

void q1_PlayPlayerJumpSounds(CBasePlayer@ pPlayer) {
  if (pPlayer.pev.health < 1) return; // don't HUH if dead
  if ((pPlayer.m_afButtonPressed & IN_JUMP) != 0 && (pPlayer.pev.waterlevel < WATERLEVEL_WAIST)) {
    TraceResult tr;
    // gotta trace it because we already jumped at this point
    // this is a hack, but there's no PlayerJump hook or anything, so it'll do
    g_Utility.TraceHull(pPlayer.pev.origin, pPlayer.pev.origin + Vector(0, 0, -5), dont_ignore_monsters, human_hull, pPlayer.edict(), tr);
    if (tr.flFraction < 1.0)
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "quake1/player/jump.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
  }
}

void q1_PrecachePlayerSounds() {
  g_SoundSystem.PrecacheSound("quake1/player/pain1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain3.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain4.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain5.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain6.wav");
  g_SoundSystem.PrecacheSound("quake1/player/burn1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/burn2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/wpain1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/wpain2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death3.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death4.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death5.wav");
  g_SoundSystem.PrecacheSound("quake1/player/drown.wav");
  g_SoundSystem.PrecacheSound("quake1/player/jump.wav");
  g_SoundSystem.PrecacheSound("quake1/gib.wav");
}
