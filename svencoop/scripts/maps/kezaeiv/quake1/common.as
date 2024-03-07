#include "items"

bool q1_Deathmatch = false;

void q1_InitCommon() {
  q1_PrecachePlayerSounds();

  q1_RegisterItems();

  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @q1_PlayerSpawn);
  g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @q1_PlayerKilled);
  g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @q1_PlayerTakeDamage);
  g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, @q1_PlayerPostThink);

}

HookReturnCode q1_PlayerSpawn(CBasePlayer@ pPlayer) {
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
  
  // clear powerups
  q1_RemovePowerup(pPlayer, Q1_POWER_ALL);

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
    g_SoundSystem.EmitSoundDyn(pdi.pVictim.edict(), CHAN_VOICE, "kezaeiv/c_wep/misc/protect.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
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
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "kezaeiv/c_wep/misc/samjump.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
  }
}

void q1_PrecachePlayerSounds() {
  g_SoundSystem.PrecacheSound("kezaeiv/c_wep/misc/protect.wav");
  g_SoundSystem.PrecacheSound("kezaeiv/c_wep/misc/samjump.wav");
}
