#include "projectile"
#include "../items"

const Vector Q1_NG_CONE(0.0, 0.0, 0.0);
const int Q1_NG_AMMO_DEFAULT = 50;
const int Q1_NG_AMMO_MAX     = 200;

enum q1_NailgunAnims {
  NAILGUN_IDLE = 0,
  NAILGUN_SHOOT1,
  NAILGUN_SHOOT2
};

class weapon_qnailgun : ScriptBasePlayerWeaponEntity {
  CScheduledFunction@ m_pRotFunc;
  uint m_iShootAnim = 0;

  void Spawn() {
    Precache();
    g_EntityFuncs.SetModel(self, "models/quake1/w_nailgun.mdl");
    self.m_iDefaultAmmo = Q1_NG_AMMO_DEFAULT;
    BaseClass.Spawn();
    self.FallInit();

    self.pev.movetype = MOVETYPE_NONE;
    @m_pRotFunc = @g_Scheduler.SetInterval(this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES);
  }

  void Precache() {
    self.PrecacheCustomModels();
    g_Game.PrecacheModel("models/quake1/v_nailgun.mdl");
    g_Game.PrecacheModel("models/quake1/p_nailgun.mdl");
    g_Game.PrecacheModel("models/quake1/w_nailgun.mdl");
    g_Game.PrecacheModel("models/quake1/spike.mdl");

    g_SoundSystem.PrecacheSound("quake1/weapon.wav" );              
    g_SoundSystem.PrecacheSound("quake1/weapons/nailgun1.wav");
    g_SoundSystem.PrecacheSound("weapons/357_cock1.wav");
    g_SoundSystem.PrecacheSound("quake1/weapons/tink1.wav");
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
    info.iMaxAmmo1 = Q1_NG_AMMO_MAX;
    info.iMaxAmmo2 = -1;
    info.iMaxClip = WEAPON_NOCLIP;
    info.iSlot = 3;
    info.iPosition = 10;
    info.iFlags = 0;
    info.iWeight = 2;

    return true;
  }

  bool Deploy() {
    return self.DefaultDeploy(self.GetV_Model("models/quake1/v_nailgun.mdl"),
                              self.GetP_Model("models/quake1/p_nailgun.mdl"), NAILGUN_IDLE, "mp5");
  }

  void PrimaryAttack() {
    CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE
    int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
    if (ammo <= 0) {
      self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
      self.PlayEmptySound();
      return;
    }

    m_iShootAnim = (m_iShootAnim + 1) & 1;
    self.SendWeaponAnim(NAILGUN_SHOOT1 + m_iShootAnim, 0, 0);
    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/nailgun1.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
    m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
    m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

    --ammo;

    // player "shoot" animation
    m_pPlayer.SetAnimation(PLAYER_ATTACK1);

    float flMod = m_iShootAnim == 0 ? -2 : 2;
    Vector vecSrc   = m_pPlayer.GetGunPosition() + g_Engine.v_right * flMod - g_Engine.v_up * 5;
    Vector vecAiming = m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);
    
    int iDamage = 9;
    if (q1_CheckQuad(m_pPlayer)) {
      iDamage *= 4;
      g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "quake1/powerups/quad_s.wav", Math.RandomFloat(0.69, 0.7), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
    }

    m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
    self.pev.effects |= EF_MUZZLEFLASH;
    auto @pBolt = q1_ShootCustomProjectile("projectile_qspike", "models/quake1/spike.mdl", 
                                           vecSrc, vecAiming * 1024, 
                                           m_pPlayer.pev.v_angle, m_pPlayer);
    pBolt.pev.dmg = iDamage;

    m_pPlayer.pev.punchangle.x = -0.5;
    self.m_flNextPrimaryAttack = g_Engine.time + 0.1;

    if (ammo != 0)
      self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
    else {
      m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
      self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
    }

    q1_AlertMonsters(m_pPlayer, m_pPlayer.pev.origin, 500);
    m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo);
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

void q1_RegisterWeapon_NAILGUN() {
  g_CustomEntityFuncs.RegisterCustomEntity("weapon_qnailgun", "weapon_qnailgun");
  g_ItemRegistry.RegisterWeapon("weapon_qnailgun", "quake1/weapons", "bolts");
}