const int Q1_AMMO_SHELLS_MAX   = 100;
const int Q1_AMMO_NAILS_MAX    = 200;
const int Q1_AMMO_ROCKETS_MAX  = 100;
const int Q1_AMMO_ENERGY_MAX   = 100;

const int Q1_AMMO_SHELLS_GIVE  = 25;
const int Q1_AMMO_NAILS_GIVE   = 50;
const int Q1_AMMO_ROCKETS_GIVE = 10;
const int Q1_AMMO_ENERGY_GIVE  = 10;

class ammo_qgeneric : ScriptBasePlayerAmmoEntity {
  string m_sModel;
  string m_sAmmo;
  int m_iGive;
  int m_iMax;

  void CommonSpawn() {
    Precache();
    g_EntityFuncs.SetModel(self, m_sModel);
    BaseClass.Spawn();
  }

  void Spawn() {
    CommonSpawn();
  }

  void Precache() {
    g_Game.PrecacheModel(m_sModel);
    g_SoundSystem.PrecacheSound("quake1/ammo.wav");
  }

  bool AddAmmo(CBaseEntity@ pOther) {
    if (pOther is null) return false;
    if (pOther.GiveAmmo(m_iGive, m_sAmmo, m_iMax) != -1) {
      g_SoundSystem.EmitSound(pOther.edict(), CHAN_ITEM, "quake1/ammo.wav", 1.0, ATTN_NORM);
      return true;
    }
    return false;
  }
}

class ammo_qshells : ammo_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_shotgun_ammo.mdl";
    m_sAmmo = "buckshot";
    m_iGive = Q1_AMMO_SHELLS_GIVE;
    m_iMax = Q1_AMMO_SHELLS_MAX;
    CommonSpawn();
  }
}

class ammo_qnails : ammo_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_nailgun_ammo.mdl";
    m_sAmmo = "bolts";
    m_iGive = Q1_AMMO_NAILS_GIVE;
    m_iMax = Q1_AMMO_NAILS_MAX;
    CommonSpawn();
  }
}

class ammo_qrockets : ammo_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_rocket_ammo.mdl";
    m_sAmmo = "rockets";
    m_iGive = Q1_AMMO_ROCKETS_GIVE;
    m_iMax = Q1_AMMO_ROCKETS_MAX;
    CommonSpawn();
  }
}

class ammo_qenergy : ammo_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_thunder_ammo.mdl";
    m_sAmmo = "uranium";
    m_iGive = Q1_AMMO_ENERGY_GIVE;
    m_iMax = Q1_AMMO_ENERGY_MAX;
    CommonSpawn();
  }
}

void q1_SetAmmoCaps(CBasePlayer@ pPlayer) {
  pPlayer.SetMaxAmmo("buckshot", Q1_AMMO_SHELLS_MAX);
  pPlayer.SetMaxAmmo("bolts", Q1_AMMO_NAILS_MAX);
  pPlayer.SetMaxAmmo("rockets", Q1_AMMO_ROCKETS_MAX);
  pPlayer.SetMaxAmmo("uranium", Q1_AMMO_ENERGY_MAX);
}

void q1_RegisterAmmo() {
  // precache item and ammo models right away
  g_Game.PrecacheModel("models/quake1/w_shotgun_ammo.mdl");
  g_Game.PrecacheModel("models/quake1/w_nailgun_ammo.mdl");
  g_Game.PrecacheModel("models/quake1/w_rocket_ammo.mdl");
  g_Game.PrecacheModel("models/quake1/w_thunder_ammo.mdl");
  g_SoundSystem.PrecacheSound("quake1/ammo.wav");  // for backpacks

  g_CustomEntityFuncs.RegisterCustomEntity("ammo_qshells", "ammo_qshells");
  g_CustomEntityFuncs.RegisterCustomEntity("ammo_qnails", "ammo_qnails");
  g_CustomEntityFuncs.RegisterCustomEntity("ammo_qrockets", "ammo_qrockets");
  g_CustomEntityFuncs.RegisterCustomEntity("ammo_qenergy", "ammo_qenergy");
}
