/*
 * The Field Intensity version of the penguin (mutated snark)
 * Based on the Opposing Force version of the penguin by Rizulix
 * Updated by FreeSlave, with the help of Outerbeast
 */

namespace CPenguin
{

enum penguin_e
{
  IDLE1 = 0,
  FIDGETFIT,
  FIDGETNIP,
  DOWN,
  UP,
  THROW
};

// Weapon information
const int MAX_CARRY    = 9;
const int DEFAULT_GIVE = 3;
const int WEIGHT       = 5;

int m_explode1;
int m_explode2;

class weapon_penguin : ScriptBasePlayerWeaponEntity
{
  private CBasePlayer@ m_pPlayer
  {
    get const { return cast<CBasePlayer>(self.m_hPlayer.GetEntity()); }
    set       { self.m_hPlayer = EHandle(@value); }
  }
  private bool m_fJustThrown;

  float WeaponTimeBase() { return g_Engine.time; }

  void Spawn()
  {
    Precache();
    g_EntityFuncs.SetModel(self, self.GetW_Model('models/fi/w_penguinnest.mdl'));
    self.m_iDefaultAmmo = DEFAULT_GIVE;
    self.FallInit();

    pev.sequence = 1;
    pev.animtime = g_Engine.time;
    pev.framerate = 1.0;
    self.ResetSequenceInfo();
  }

  void Precache()
  {
    self.PrecacheCustomModels();
    g_Game.PrecacheModel('models/fi/v_penguin.mdl');
    g_Game.PrecacheModel('models/fi/w_penguin.mdl');
    g_Game.PrecacheModel('models/fi/p_penguin.mdl');
    g_Game.PrecacheModel('models/fi/w_penguinnest.mdl');

    g_Game.PrecacheOther('monster_snark');

    g_SoundSystem.PrecacheSound('squeek/sqk_hunt2.wav');
    g_SoundSystem.PrecacheSound('squeek/sqk_hunt3.wav');
    g_SoundSystem.PrecacheSound('common/null.wav');

    g_Game.PrecacheModel('sprites/fi/640hudof03.spr');
    g_Game.PrecacheModel('sprites/fi/640hudof04.spr');
    g_Game.PrecacheModel('sprites/fi/640hud7.spr');
    g_Game.PrecacheGeneric('sprites/fi/weapon_penguin.txt');
    
    m_explode1 = g_Game.PrecacheModel( "sprites/spore_exp_01.spr" );
    m_explode2 = g_Game.PrecacheModel( "sprites/spore_exp_c_01.spr" );
  }

  bool GetItemInfo(ItemInfo &out info)
  {
    info.iMaxAmmo1 = MAX_CARRY;
    info.iMaxAmmo2 = -1;
    info.iAmmo1Drop = 1;
    info.iAmmo2Drop = -1;
    info.iMaxClip = WEAPON_NOCLIP;
    info.iFlags = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
    info.iSlot = 4;
    info.iPosition = 5;
    info.iId = g_ItemRegistry.GetIdForName(pev.classname);
    info.iWeight = WEIGHT;

    return true;
  }

  bool AddToPlayer(CBasePlayer@ pPlayer)
  {
    if (!BaseClass.AddToPlayer(pPlayer))
      return false;
      
    NetworkMessage message(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
      message.WriteLong(g_ItemRegistry.GetIdForName(pev.classname));
    message.End();

    @m_pPlayer = pPlayer;
    
    return true;
  }

  bool Deploy()
  {
    if (Math.RandomFloat(0.0, 1.0) <= 0.5)
      g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, 'squeek/sqk_hunt2.wav', VOL_NORM, ATTN_NORM);
    else
      g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, 'squeek/sqk_hunt3.wav', VOL_NORM, ATTN_NORM);

    m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;

    bool bResult = self.DefaultDeploy(self.GetV_Model('models/fi/v_penguin.mdl'), self.GetP_Model('models/fi/p_penguin.mdl'), UP, 'squeak');
    self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
    return bResult;
  }

  void Holster(int skiplocal = 0)
  {
    g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, 'common/null.wav', VOL_NORM, ATTN_NORM);

    BaseClass.Holster(skiplocal);
  }
  
  CBasePlayerItem@ DropItem()
    {
        return self;
    }

    bool CanHaveDuplicates()
    {
        return true;
    }

    bool CanDeploy()
    {
        return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0;
    }

  void PrimaryAttack()
  {
    if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0)
    {
      Math.MakeVectors(m_pPlayer.pev.v_angle);

      Vector vecSrc = m_pPlayer.pev.origin;

      if (m_pPlayer.pev.flags & FL_DUCKING != 0)
      {
        vecSrc.z += 18.0;
      }

      const Vector vecStart = vecSrc + (g_Engine.v_forward * 20.0);
      const Vector vecEnd = vecSrc + (g_Engine.v_forward * 64.0);

      TraceResult tr;
      g_Utility.TraceLine(vecStart, vecEnd, dont_ignore_monsters, null, tr);

      if (tr.fAllSolid == 0 && tr.fStartSolid == 0 && tr.flFraction > 0.25)
      {
        self.SendWeaponAnim(THROW, 0, pev.body);

        m_pPlayer.SetAnimation(PLAYER_ATTACK1);

        // Yeah... I don't wanna bother making custom monster that most likely won't work correctly.
        auto penguin = g_EntityFuncs.Create('monster_snark', tr.vecEndPos, m_pPlayer.pev.v_angle, true, m_pPlayer.edict());
        g_EntityFuncs.SetModel(penguin, 'models/fi/w_penguin.mdl');
        // g_EntityFuncs.DispatchKeyValue(penguin.edict(), 'bloodcolor', '1'); // Snark ignores this kv
        g_EntityFuncs.DispatchKeyValue(penguin.edict(), 'ondestroyfn', 'CPenguin::Killed');
        penguin.SetClassification(m_pPlayer.Classify());
        g_EntityFuncs.DispatchSpawn(penguin.edict());

        penguin.pev.velocity = m_pPlayer.pev.velocity + (g_Engine.v_forward * 200.0);

        if (Math.RandomFloat(0.0, 1.0) <= 0.5)
          g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, 'squeek/sqk_hunt2.wav', VOL_NORM, ATTN_NORM);
        else
          g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, 'squeek/sqk_hunt3.wav', VOL_NORM, ATTN_NORM);

        m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
        m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1);
        m_fJustThrown = true;

        self.m_flNextPrimaryAttack = g_Engine.time + 0.3;
        self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
      }
    }
  }

  void SecondaryAttack()
  {
    // Nothing
  }

  void WeaponIdle()
  {
    if (self.m_flTimeWeaponIdle > WeaponTimeBase())
      return;

    if (m_fJustThrown)
    {
      m_fJustThrown = false;

      if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0)
      {
        self.SendWeaponAnim(UP, 0, pev.body);
        self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 10.0, 15.0);
      }
      else
      {
        self.RetireWeapon();
      }
    }
    else
    {
      int iAnim;
      const float flRand = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0, 1.0);
      if (flRand <= 0.75)
      {
        iAnim = IDLE1;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.75;
      }
      else if (flRand <= 0.875)
      {
        iAnim = FIDGETFIT;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 4.375;
      }
      else
      {
        iAnim = FIDGETNIP;
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0;
      }

      self.SendWeaponAnim(iAnim, 0, pev.body);
    }
  }
}

void Killed(CBaseEntity@ pSqueak)
{
  const int iHitTimes = int(pSqueak.pev.dmg / g_EngineFuncs.CVarGetFloat('sk_snark_dmg_pop'));
  pSqueak.pev.dmg = g_EngineFuncs.CVarGetFloat('sk_plr_hand_grenade') * iHitTimes;

  const float maxDamage = 500.0;
  const float maxRadius = 500.0;
  
  // CPenguinGrenade::SuperBounceTouch(CBaseEntity* pOther)
  if (pSqueak.pev.dmg > maxDamage)
  {
    pSqueak.pev.dmg = maxDamage;
  }

  // CPenguinGrenade::Killed(CBaseEntity* attacker, int iGib)
  Vector vecSpot = pSqueak.pev.origin + Vector(0.0, 0.0, 8.0);
  //cast<CGrenade>(pSqueak).Explode(vecSpot, vecSpot + Vector(0.0, 0.0, -40.0));

	const float explosionRadius = Math.min(maxRadius, pSqueak.pev.dmg * 2.5f);
	entvars_t@ pevOwner;
	if( pSqueak.pev.owner !is null )
		@pevOwner = pSqueak.pev.owner.vars;
	else
		@pevOwner = null;
	@pSqueak.pev.owner = null;
	g_WeaponFuncs.RadiusDamage( pSqueak.pev.origin, pSqueak.pev, pevOwner, pSqueak.pev.dmg, explosionRadius, CLASS_NONE, DMG_BLAST );
  
	NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpot);
	m.WriteByte(TE_SPRITE);
	m.WriteCoord(vecSpot.x);
	m.WriteCoord(vecSpot.y);
	m.WriteCoord(vecSpot.z);
	m.WriteShort(Math.RandomLong(0,1) == 1 ? m_explode1 : m_explode2);
	m.WriteByte(int(Math.min(explosionRadius * 0.15, 255)));
	m.WriteByte(110);
	m.End();
}

void SetBigExploEffect(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster)
{
	g_EntityFuncs.DispatchKeyValue(pMonster.edict(), 'ondestroyfn', 'CPenguin::Killed');
}

string GetName()
{
  return 'weapon_penguin';
}

void Register()
{
  if (!g_CustomEntityFuncs.IsCustomEntity(GetName()))
  {
    g_CustomEntityFuncs.RegisterCustomEntity('CPenguin::weapon_penguin', GetName());
    g_ItemRegistry.RegisterWeapon("weapon_penguin", "fi", "weapon_penguin" '', "weapon_penguin", '');
  }
}

}
