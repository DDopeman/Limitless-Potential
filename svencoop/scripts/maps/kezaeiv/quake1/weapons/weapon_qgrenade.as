#include "../items"

const int  Q1_GL_AMMO_DEFAULT = 5;
const int  Q1_GL_AMMO_MAX     = 100;

enum q1_GrenadeAnims {
  GRENADE_IDLE = 0,
  GRENADE_SHOOT
};

class weapon_qgrenade : ScriptBasePlayerWeaponEntity {
  CScheduledFunction@ m_pRotFunc;

  void Spawn() {
    Precache();
    g_EntityFuncs.SetModel(self, "models/quake1/w_grenade.mdl");
    self.m_iDefaultAmmo = Q1_GL_AMMO_DEFAULT;
    BaseClass.Spawn();
    self.FallInit();

    self.pev.movetype = MOVETYPE_NONE;
    @m_pRotFunc = @g_Scheduler.SetInterval(this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES);
  }

  void Precache() {
    self.PrecacheCustomModels();
    g_Game.PrecacheModel("models/quake1/v_grenade.mdl");
    g_Game.PrecacheModel("models/quake1/p_grenade.mdl");
    g_Game.PrecacheModel("models/quake1/w_grenade.mdl");
    g_Game.PrecacheModel("models/quake1/grenade.mdl");

    g_SoundSystem.PrecacheSound("quake1/weapon.wav" );              
    g_SoundSystem.PrecacheSound("quake1/weapons/grenade.wav");
    g_SoundSystem.PrecacheSound("weapons/357_cock1.wav");
    g_SoundSystem.PrecacheSound("quake1/weapons/bounce.wav");
  }
  
  bool PlayEmptySound() {
    if (self.m_bPlayEmptySound) {
      CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE
      self.m_bPlayEmptySound = false;
      g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM);
    }
    return false;
  }

  bool AddToPlayer(CBasePlayer@ pPlayer) {
    if(BaseClass.AddToPlayer(pPlayer) == true) {
      NetworkMessage message(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
      message.WriteLong( self.m_iId );
      message.End();
      g_Scheduler.RemoveTimer(m_pRotFunc);
      @m_pRotFunc = null;
      return true;
    }
    return false;
  }
  
  bool GetItemInfo(ItemInfo& out info) {
    info.iMaxAmmo1 = Q1_GL_AMMO_MAX;
    info.iMaxAmmo2 = -1;
    info.iMaxClip = WEAPON_NOCLIP;
    info.iSlot = 5;
    info.iPosition = 10;
    info.iFlags = 0;
    info.iWeight = 3;

    return true;
  }

  bool Deploy() {
    return self.DefaultDeploy(self.GetV_Model("models/quake1/v_grenade.mdl"),
                              self.GetP_Model("models/quake1/p_grenade.mdl"), GRENADE_IDLE, "shotgun");
  }

  void PrimaryAttack() {
    CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE
    int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
    if (ammo <= 0) {
      self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
      self.PlayEmptySound();
      return;
    }

    self.SendWeaponAnim(GRENADE_SHOOT, 0, 0);
    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/grenade.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0x1f));
    m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
    m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

    --ammo;

    // player "shoot" animation
    m_pPlayer.SetAnimation(PLAYER_ATTACK1);

    Vector vecSrc   = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16 - g_Engine.v_up * 10;
    Vector vecAiming = m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

    int iDamage = 120;
    if (q1_CheckQuad(m_pPlayer)) {
      iDamage *= 4;
      g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "quake1/powerups/quad_s.wav", Math.RandomFloat(0.69, 0.7), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
    }

    m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
    self.pev.effects |= EF_MUZZLEFLASH;
    auto @pGrenade = q1_ShootCustomProjectile("projectile_qgrenade", "models/quake1/grenade.mdl", 
                                              vecSrc, vecAiming * 1024, 
                                              m_pPlayer.pev.v_angle, m_pPlayer);
    pGrenade.pev.dmg = iDamage;

    m_pPlayer.pev.punchangle.x = -5.0;
    self.m_flNextPrimaryAttack = g_Engine.time + 0.6;

    if (ammo != 0)
      self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
    else {
      m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
      self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
    }

    q1_AlertMonsters(m_pPlayer, m_pPlayer.pev.origin, 1000);
    m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo);
  }

  void WeaponIdle() {
    self.ResetEmptySound();
    BaseClass.WeaponIdle();
  }

  void RotateThink() {
    self.pev.angles.y += 1;
  }

  void UpdateOnRemove() {
    if (m_pRotFunc !is null)
      g_Scheduler.RemoveTimer(m_pRotFunc);
    BaseClass.UpdateOnRemove();
  }
}

void q1_RegisterWeapon_GRENADE() {
  g_CustomEntityFuncs.RegisterCustomEntity("weapon_qgrenade", "weapon_qgrenade");
  g_ItemRegistry.RegisterWeapon("weapon_qgrenade", "quake1/weapons", "rockets");
}
