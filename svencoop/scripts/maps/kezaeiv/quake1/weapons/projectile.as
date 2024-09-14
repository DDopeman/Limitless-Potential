#include "../tempents"

class projectile_qgrenade : ScriptBaseEntity {
  float m_fExplodeTime;

  void Spawn() {
    g_EntityFuncs.SetModel(self, "models/quake1/grenade.mdl");
    g_EntityFuncs.SetSize(self.pev, Vector(-0.5, -0.5, -0.5), Vector(0.5, 0.5, 0.5));
    g_EntityFuncs.SetOrigin(self, self.pev.origin);
    m_fExplodeTime = g_Engine.time + 3.0;
    self.pev.movetype = MOVETYPE_BOUNCE;
    self.pev.solid = SOLID_BBOX;
    self.pev.nextthink = g_Engine.time + 2.5;
    self.pev.avelocity = Vector(300, 300, 300);
    SetThink(ThinkFunction(Explode));
  }

  void Explode() {
    q1_Explode(self, self.pev.dmg);
    g_EntityFuncs.Remove(self);
  }

  void Touch(CBaseEntity@ pOther) {
    if (pOther is null || pOther.IsBSPModel() || pOther.edict() is self.pev.owner) {
      // bounce or some shit
      if (self.pev.velocity.Length() > 15.0) {
        g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_AUTO, "quake1/weapons/bounce.wav", 1.0, ATTN_NORM, 0, 100);
      } else {
        self.pev.angles.x = 0.0;
        self.pev.avelocity = Vector(0.0, 0.0, 0.0);
      }
      self.pev.velocity = self.pev.velocity * 0.5;
      return;
    }
    Explode();
  }
}

class projectile_qrocket : ScriptBaseEntity {
  float m_fExplodeTime;

  void Spawn() {
    g_EntityFuncs.SetModel(self, "models/quake1/rocket.mdl");
    g_EntityFuncs.SetSize(self.pev, Vector(0, 0, 0), Vector(0, 0, 0));
    g_EntityFuncs.SetOrigin(self, self.pev.origin);
    m_fExplodeTime = g_Engine.time + 10.0;
    self.pev.nextthink = g_Engine.time + 0.05;
    self.pev.movetype = MOVETYPE_FLYMISSILE;
    self.pev.solid = SOLID_BBOX;
    self.pev.effects |= EF_DIMLIGHT;
    self.pev.nextthink = g_Engine.time + 10.0;
    SetThink(ThinkFunction(Explode));
  }

  void Explode() {
    q1_Explode(self, self.pev.dmg);
    g_EntityFuncs.Remove(self);
  }

  void Touch(CBaseEntity@ pOther) {
    Explode();
  }
}

class projectile_qmeat : ScriptBaseEntity {
  float m_fExplodeTime;

  void Spawn() {
    g_EntityFuncs.SetModel(self, "models/quake1/zombiegib.mdl");
    m_fExplodeTime = g_Engine.time + 5.0;
    self.pev.movetype = MOVETYPE_BOUNCE;
    self.pev.solid = SOLID_BBOX;
    self.pev.mins = Vector(-1, -1, -1);
    self.pev.maxs = Vector(1, 1, 1);
    self.pev.nextthink = g_Engine.time + 0.1;
    self.pev.avelocity = Vector(3000, 1000, 2000);
  }

  void Explode() {
    g_EntityFuncs.Remove(self);
  }

  void Think() {
    q1_TE_BloodStream(self.pev.origin, (-self.pev.velocity).Normalize(), 73);
    if (g_Engine.time >= m_fExplodeTime)
      Explode();
    else
      self.pev.nextthink = g_Engine.time + 0.1;
  }

  void Touch(CBaseEntity@ pOther) {
    if (pOther is g_EntityFuncs.Instance(self.pev.owner))
      return;

    if (pOther !is null && !pOther.IsBSPModel() && pOther.pev.takedamage != 0) {
      pOther.TakeDamage(self.pev, self.pev.owner.vars, self.pev.dmg, DMG_GENERIC);
      g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_AUTO, "quake1/monsters/zombie/hit.wav", 1.0, ATTN_NORM, 0, 100);
    } else {
      g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_AUTO, "quake1/monsters/zombie/miss.wav", 1.0, ATTN_NORM, 0, 100);
    }

    Explode();
  }
}

class projectile_qscragspike : ScriptBaseEntity {
  float m_fExplodeTime;
  Vector m_vecStart;

  void Spawn() {
    g_EntityFuncs.SetModel(self, "models/quake1/spike.mdl");
    m_fExplodeTime = g_Engine.time + 5.0;
    self.pev.movetype = MOVETYPE_FLYMISSILE;
    self.pev.solid = SOLID_BBOX;
    self.pev.angles = Math.VecToAngles(self.pev.velocity);
    m_vecStart = self.pev.origin;
    g_EntityFuncs.SetSize(self.pev, Vector(-0.5, -0.5, -0.5), Vector(0.5, 0.5, 0.5));
    self.pev.nextthink = g_Engine.time + 0.1;
  }

  void Think() {
    if (m_fExplodeTime < g_Engine.time) {
      g_EntityFuncs.Remove(self);
      return;
    }

    q1_TE_BloodStream(self.pev.origin, (-self.pev.velocity).Normalize());

    self.pev.angles = Math.VecToAngles(self.pev.velocity);
    self.pev.nextthink = g_Engine.time + 0.1;
  }

  void Touch(CBaseEntity@ pOther) {
    if (pOther is g_EntityFuncs.Instance(self.pev.owner))
      return;

    g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_AUTO, "quake1/monsters/scrag/hit.wav", 1.0, ATTN_NORM, 0, 100);

    if (pOther !is null && !pOther.IsBSPModel() && pOther.pev.takedamage != 0) {
      g_WeaponFuncs.SpawnBlood(self.pev.origin, pOther.BloodColor(), self.pev.dmg);
      pOther.TakeDamage(self.pev, self.pev.owner.vars, self.pev.dmg, DMG_GENERIC);
    }

    g_EntityFuncs.Remove(self);
  }
}

class projectile_qspike : ScriptBaseEntity {
  void Spawn() {
    g_EntityFuncs.SetModel(self, "models/quake1/spike.mdl");
    self.pev.movetype = MOVETYPE_FLYMISSILE;
    self.pev.solid = SOLID_BBOX;
    g_EntityFuncs.SetSize(self.pev, Vector(0, 0, 0), Vector(0, 0, 0));
    self.pev.nextthink = g_Engine.time + 10.0;
  }

  void Think() {
    g_EntityFuncs.Remove(self);
  }

  void Touch(CBaseEntity@ pOther) {
    if (pOther is g_EntityFuncs.Instance(self.pev.owner))
      return;
    if (pOther !is null && !pOther.IsBSPModel() && pOther.pev.takedamage != 0) {
      pOther.TakeDamage(self.pev, self.pev.owner.vars, self.pev.dmg, DMG_GENERIC);
      g_WeaponFuncs.SpawnBlood(self.pev.origin, pOther.BloodColor(), self.pev.dmg);
    } else {
      g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_AUTO, "quake1/weapons/tink1.wav", 1.0, ATTN_NORM, 0, 100);
      g_Utility.Sparks(self.pev.origin);
      if (pOther !is null && pOther.pev.takedamage != 0)
        pOther.TakeDamage(self.pev, self.pev.owner.vars, self.pev.dmg, DMG_GENERIC);
    }
    g_EntityFuncs.Remove(self);
  }
}

void q1_RadiusDamage(Vector vecCenter, CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, float flDamage, float flRadius, int bitsDamage) {
  array <CBaseEntity@> aEnts(32);
  int iNum = g_EntityFuncs.MonstersInSphere(aEnts, vecCenter, flRadius);
  for (int i = 0; i < iNum; ++i) {
    CBaseEntity@ pEnt = aEnts[i];
    if (pEnt.pev.takedamage != 0 && pEnt !is pInflictor) {
      Vector vecOrg = pEnt.pev.origin + (pEnt.pev.mins + pEnt.pev.maxs) * 0.5;
      TraceResult tr;
      g_Utility.TraceLine(vecCenter, vecOrg, ignore_monsters, dont_ignore_glass, pInflictor.edict(), tr);
      if (tr.flFraction <= 0.999) continue;
      float flPoints = (vecOrg - vecCenter).Length() * 0.5;
      if (flPoints < 0) flPoints = 0;
      flPoints = flDamage - flPoints;
      if (pEnt is pAttacker) flPoints *= 0.5;
      if (flPoints > 0) {
        if (pEnt.GetClassname() == "monster_qshambler")
          pEnt.TakeDamage(pInflictor.pev, pAttacker.pev, flPoints * 0.5, bitsDamage);
        else
          pEnt.TakeDamage(pInflictor.pev, pAttacker.pev, flPoints, bitsDamage);
      }
    }
  }
}

void q1_Explode(CBaseEntity@ proj, float dmg) {
  // fake explosion because explosions in goldsrc are shit
  g_EntityFuncs.CreateExplosion(proj.pev.origin, proj.pev.angles, proj.pev.owner, 64.0, false);
  // apply quake-like explosion damage manually
  // g_WeaponFuncs.RadiusDamage(proj.pev.origin, proj.pev, proj.pev.owner.vars, dmg, dmg + 40.0, 0, DMG_BLAST);
  q1_RadiusDamage(proj.pev.origin, proj, g_EntityFuncs.Instance(proj.pev.owner), dmg, 140.0, DMG_BLAST);
  // alert nearby monsters
  q1_AlertMonsters(g_EntityFuncs.Instance(proj.pev.owner), proj.pev.origin, 1600);
}

CBaseEntity@ q1_ShootCustomProjectile(string classname, string mdl, Vector ori, Vector vel, Vector angles, CBaseEntity@ owner) {
  if (classname.Length() == 0)
    return null;
  
  dictionary keys;
  Vector boltAngles = angles * Vector(-1, 1, 1);
  keys["origin"] = ori.ToString();
  keys["angles"] = boltAngles.ToString();
  keys["velocity"] = vel.ToString();
  
  // replace model or use error.mdl if no model specified and not a standard entity
  string model = mdl.Length() > 0 ? mdl : "models/error.mdl";
  keys["model"] = model;
  if (mdl.Length() == 0)
    keys["rendermode"] = "1"; // don't render the model
    
  CBaseEntity@ shootEnt = g_EntityFuncs.CreateEntity(classname, keys, false);  
  @shootEnt.pev.owner = owner.edict(); // do this or else crash  
  g_EntityFuncs.DispatchSpawn(shootEnt.edict());

  return shootEnt;
}

// had to move these here because shit doesn't work otherwise
void q1_ScragDelayedSpike(CBaseEntity@ pOwner, CBaseEntity@ pEnemy, Vector vecSrc, Vector vecOffset) {
  if (pOwner is null || pEnemy is null || pOwner.pev.health <= 0)
    return;

  pOwner.pev.effects |= EF_MUZZLEFLASH;

  Vector dst = pEnemy.pev.origin - vecOffset;
  Vector vec = (dst - vecSrc).Normalize();

  g_SoundSystem.EmitSoundDyn(pOwner.edict(), CHAN_VOICE, "quake1/monsters/scrag/shoot.wav", 1.0, ATTN_NORM, 0, 100);

  auto @pBolt = q1_ShootCustomProjectile("projectile_qscragspike", "models/quake1/spike.mdl", 
                                         vecSrc, vec * 600,
                                         Math.VecToAngles(vec), pOwner);
  pBolt.pev.dmg = 9;
}

void q1_ScragDelaySpike(CBaseEntity@ pOwner, CBaseEntity@ pEnemy, Vector vecSrc, Vector vecOffset, float time) {
  g_Scheduler.SetTimeout("q1_ScragDelayedSpike", time, @pOwner, @pEnemy, vecSrc, vecOffset);
}

void q1_ZombieMissile(CBaseEntity@ pOwner, CBaseEntity@ pEnemy, Vector vecOrigin, Vector vecOffset) {
  g_EngineFuncs.MakeVectors(pOwner.pev.angles);

  Vector vecOrg = vecOrigin + vecOffset.x * g_Engine.v_forward + vecOffset.y * g_Engine.v_right + (vecOffset.z - 24) * g_Engine.v_up;
  Vector vecVelocity = (pEnemy.EyePosition() - vecOrg).Normalize() * 600;
  vecVelocity.z = 200;

  auto @pBolt = q1_ShootCustomProjectile("projectile_qmeat", "models/quake1/zombiegib.mdl", 
                                         vecOrg, vecVelocity,
                                         Math.VecToAngles(vecVelocity), pOwner);
  pBolt.pev.dmg = 10;
}

void q1_RegisterProjectiles() {
  g_CustomEntityFuncs.RegisterCustomEntity("projectile_qgrenade", "projectile_qgrenade");
  g_CustomEntityFuncs.RegisterCustomEntity("projectile_qrocket", "projectile_qrocket");
  g_CustomEntityFuncs.RegisterCustomEntity("projectile_qspike", "projectile_qspike");
  g_CustomEntityFuncs.RegisterCustomEntity("projectile_qscragspike", "projectile_qscragspike");
  g_CustomEntityFuncs.RegisterCustomEntity("projectile_qmeat", "projectile_qmeat");
}
