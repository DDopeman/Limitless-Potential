#include "../items"

const Vector Q1_SSG_CONE(0.14, 0.08, 0);

const int  Q1_SSG_AMMO_DEFAULT = 25;
const int  Q1_SSG_AMMO_MAX     = 100;
const uint Q1_SSG_NPELLETS     = 14;

enum q1_Shotgun2Anims {
  SHOTGUN2_IDLE = 0,
  SHOTGUN2_SHOOT
};

class weapon_qshotgun2 : ScriptBasePlayerWeaponEntity {
  int m_iShell;
  CScheduledFunction@ m_pRotFunc;

  void Spawn() {
    Precache();
    g_EntityFuncs.SetModel(self, "models/quake1/w_shotgun2.mdl");
    self.m_iDefaultAmmo = Q1_SSG_AMMO_DEFAULT;
    BaseClass.Spawn();
    self.FallInit();

    self.pev.movetype = MOVETYPE_NONE;
    @m_pRotFunc = @g_Scheduler.SetInterval(this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES);
  }

  void Precache() {
    self.PrecacheCustomModels();
    g_Game.PrecacheModel("models/quake1/v_shotgun2.mdl");
    g_Game.PrecacheModel("models/quake1/p_shotgun2.mdl");
    g_Game.PrecacheModel("models/quake1/w_shotgun2.mdl");

    m_iShell = g_Game.PrecacheModel("models/quake1/shotgunshell.mdl");

    g_SoundSystem.PrecacheSound("quake1/weapon.wav" );              
    g_SoundSystem.PrecacheSound("quake1/weapons/shotgun2.wav");
    g_SoundSystem.PrecacheSound("weapons/357_cock1.wav");
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
    info.iMaxAmmo1 = Q1_SSG_AMMO_MAX;
    info.iMaxAmmo2 = -1;
    info.iMaxClip = WEAPON_NOCLIP;
    info.iSlot = 2;
    info.iPosition = 10;
    info.iFlags = 0;
    info.iWeight = 1;

    return true;
  }

  bool Deploy() {
    return self.DefaultDeploy(self.GetV_Model("models/quake1/v_shotgun2.mdl"),
                              self.GetP_Model("models/quake1/p_shotgun2.mdl"), SHOTGUN2_IDLE, "shotgun");
  }

  void CreatePelletDecals(const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount) {
    TraceResult tr;  
    float x, y;
    CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE
    
    for (uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet) {
      g_Utility.GetCircularGaussianSpread(x, y);
      
      Vector vecDir = vecAiming 
              + x * vecSpread.x * g_Engine.v_right 
              + y * vecSpread.y * g_Engine.v_up;

      Vector vecEnd  = vecSrc + vecDir * 2048;
      
      g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);
      
      if (tr.flFraction < 1.0) {
        if (tr.pHit !is null) {
          CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
          
          if( pHit is null || pHit.IsBSPModel() == true )
            g_WeaponFuncs.DecalGunshot(tr, BULLET_PLAYER_BUCKSHOT);
        }
      }
    }
  }

  void EjectShell(const Vector& in vecSrc) {
      CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE
      Vector vecShellVelocity = m_pPlayer.pev.velocity 
               + g_Engine.v_right * Math.RandomFloat(50, 70) 
               + g_Engine.v_up * Math.RandomFloat(100, 150) 
               + g_Engine.v_forward * 25;
      g_EntityFuncs.EjectBrass(vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -42 + g_Engine.v_forward * 11 + g_Engine.v_right * 5, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHOTSHELL);
  }

  void PrimaryAttack() {
    CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE
    int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
    if (ammo <= 1) {
      self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
      self.PlayEmptySound();
      return;
    }

    self.SendWeaponAnim(SHOTGUN2_SHOOT, 0, 0);
    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/shotgun2.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0x1f));
    m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
    m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

    ammo -= 2;

    // player "shoot" animation
    m_pPlayer.SetAnimation(PLAYER_ATTACK1);

    Vector vecSrc   = m_pPlayer.GetGunPosition();
    Vector vecAiming = m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);
    
    int iDamage = 4;
    if (q1_CheckQuad(m_pPlayer)) {
      iDamage *= 4;
      g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "quake1/powerups/quad_s.wav", Math.RandomFloat(0.69, 0.7), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
    }

    m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
    self.pev.effects |= EF_MUZZLEFLASH;
    m_pPlayer.FireBullets(Q1_SSG_NPELLETS, vecSrc, vecAiming, Q1_SSG_CONE, 2048, 
                               BULLET_PLAYER_CUSTOMDAMAGE, 0, iDamage);
  
    Math.MakeVectors( m_pPlayer.pev.v_angle );
    EjectShell(vecSrc);
    EjectShell(vecSrc);

    m_pPlayer.pev.punchangle.x = -5.0;
    self.m_flNextPrimaryAttack = g_Engine.time + 0.7;

    if (ammo > 1)
      self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
    else {
      m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
      self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
    }

    q1_AlertMonsters(m_pPlayer, m_pPlayer.pev.origin, 1500);
    CreatePelletDecals(vecSrc, vecAiming, Q1_SSG_CONE, Q1_SSG_NPELLETS);
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

void q1_RegisterWeapon_SHOTGUN2() {
  g_CustomEntityFuncs.RegisterCustomEntity("weapon_qshotgun2", "weapon_qshotgun2");
  g_ItemRegistry.RegisterWeapon("weapon_qshotgun2", "quake1/weapons", "buckshot");
}