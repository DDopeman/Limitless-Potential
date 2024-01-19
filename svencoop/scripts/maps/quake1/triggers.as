#include "weapons/projectile"

class qnailshooter : ScriptBaseEntity {
  float m_fShootTime = 0.0;

  void Spawn() {
    Precache();
    BaseClass.Spawn();

    self.pev.movetype = MOVETYPE_NONE;
    self.pev.solid = SOLID_NOT;

    if (self.pev.dmg == 0) self.pev.dmg = 9;
  }

  void Precache() {
    g_Game.PrecacheModel("models/quake1/spike.mdl");
    g_SoundSystem.PrecacheSound("quake1/weapons/nailgun2.wav");
    g_SoundSystem.PrecacheSound("quake1/weapons/tink1.wav");
  }

  void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value) {
    if (m_fShootTime > g_Engine.time) return;
    m_fShootTime = g_Engine.time + 0.1; // don't let it shoot too often

    g_EngineFuncs.MakeVectors(self.pev.angles);
    g_SoundSystem.EmitSound(self.edict(), CHAN_WEAPON, "quake1/weapons/nailgun2.wav", 1.0, ATTN_NORM);
    auto @pBolt = q1_ShootCustomProjectile("projectile_qspike", "models/quake1/spike.mdl", 
                                           self.pev.origin, g_Engine.v_forward * 1024, 
                                           self.pev.angles, self);
    pBolt.pev.dmg = self.pev.dmg;
  }
}

// don't feel like fucking around with triggers all day
class trigger_qboss : ScriptBaseEntity {
  bool m_fPylonA = false;
  bool m_fPylonB = false;
  float m_flFireTime = 0;

  void Spawn() {
    Precache();
    BaseClass.Spawn();
    self.pev.movetype = MOVETYPE_NONE;
    self.pev.solid = SOLID_NOT;    
  }

  void Precache() {
    g_SoundSystem.PrecacheSound("quake1/shock.wav");
  }

  void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value) {
    if (pCaller.GetClassname() == "func_door") {
      if (pCaller.pev.targetname == "pa")
        m_fPylonA = !m_fPylonA;
      else if (pCaller.pev.targetname == "pb")
        m_fPylonB = !m_fPylonB;
      m_flFireTime = g_Engine.time + 1.0;
    } else if (pCaller.GetClassname() == "func_button") {
      if (m_fPylonA && m_fPylonB && m_flFireTime <= g_Engine.time) {
        g_SoundSystem.EmitSound(self.edict(), CHAN_WEAPON, "quake1/shock.wav", 1.0, ATTN_NORM);
        self.SUB_UseTargets(self, USE_TOGGLE, 0);
        // try hurting the boss
        CBaseEntity@ pBoss = g_EntityFuncs.FindEntityByClassname(null, "monster_qboss");
        if (pBoss !is null) pBoss.TakeDamage(self.pev, pActivator.pev, 1, DMG_ENERGYBEAM);
      }
    }
  }
}

void q1_RegisterTriggers() {
  g_CustomEntityFuncs.RegisterCustomEntity("qnailshooter", "qnailshooter");
  g_CustomEntityFuncs.RegisterCustomEntity("trigger_qboss", "trigger_qboss");
}
