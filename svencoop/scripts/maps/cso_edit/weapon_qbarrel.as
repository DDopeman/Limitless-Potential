namespace cso_qbarrel
{

const Vector VECTOR_CONE_QBARREL( 0.15, 0.07, 0.00 );		// 10 degrees by 5 degrees
const int CSOW_DEFAULT_GIVE	= 4;
const int CSOW_MAX_AMMO		= 64;
const int CSOW_MAX_CLIP 		= 4;
const int CSOW_WEIGHT 			= 20;
const int CSOW_DAMAGE			= 8;
const uint CSOW_PELLETCOUNT	= 16;
const float CSOW_TIME_DELAY1	= 0.1;
const float CSOW_TIME_DELAY2	= 1;
const float CSOW_TIME_DRAW	= 1.1;
const float CSOW_TIME_RELOAD	= 3.0;

const string MODEL_VIEW			= "models/cso_edit/v_qbarrel.mdl";
const string MODEL_PLAYER		= "models/cso_edit/p_qbarrel.mdl";
const string MODEL_WORLD		= "models/cso_edit/w_qbarrel.mdl";
const string MODEL_AMMO			= "models/cso_edit/w_shotbox.mdl";
const string MODEL_SHELL		= "models/shotgunshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW
}

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"cso_edit/cs16/dryfire_rifle.wav", //only here for the precache
	"cso_edit/qbarrel-1.wav",
	"cso_edit/qbarrel_clipin1.wav",
	"cso_edit/qbarrel_clipin2.wav",
	"cso_edit/qbarrel_clipout1.wav",
	"cso_edit/qbarrel_draw.wav"
};

class weapon_qbarrel : CBaseCSOWeapon
{
	private int m_iRemainingClip;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = self.pev.dmg;


		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_AMMO );

		g_Game.PrecacheModel( MODEL_SHELL );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/cso_edit/weapon_qbarrel.txt" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud60.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_qbarrel.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip		= CSOW_MAX_CLIP;
		info.iSlot				= cso::QBARREL_SLOT - 1;
		info.iPosition		= cso::QBARREL_POSITION - 1;
		info.iWeight			= cso::QBARREL_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage qbarrel( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			qbarrel.WriteLong( g_ItemRegistry.GetIdForName("weapon_qbarrel") );
		qbarrel.End();

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, "shotgun", 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		SetThink( null );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		Shoot( 0.2, true );
	}

	void SecondaryAttack()
	{
		Shoot( 0.2, false );
	}

	void Shoot( float flCycleTime, bool IsPrimaryAttack )
	{
		flCycleTime -= 0.07;
		
		if( IsPrimaryAttack )
		{
			if( (m_pPlayer.m_afButtonPressed & IN_ATTACK) == 0 )
				return;
		}
		else
		{
			if( (m_pPlayer.m_afButtonPressed & IN_ATTACK2) == 0 )
				return;
		}

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.159;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.Reload();
			self.PlayEmptySound();
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.5, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;

		if( self.m_flCustomDmg > 0 ) flDamage = self.m_flCustomDmg;

		if( IsPrimaryAttack )
		{
			--self.m_iClip;
			self.SendWeaponAnim( ANIM_SHOOT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_pPlayer.FireBullets( CSOW_PELLETCOUNT, vecSrc, vecAiming, VECTOR_CONE_QBARREL, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );
			cso::CreateShotgunPelletDecals( m_pPlayer, vecSrc, vecAiming, VECTOR_CONE_QBARREL, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET) );
			m_pPlayer.pev.punchangle.x = -5.0;
		}
		else
		{
			self.SendWeaponAnim( ANIM_SHOOT2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			m_iRemainingClip = self.m_iClip;

			for( int i = 0; i < m_iRemainingClip; i++ )
			{
				self.m_iClip--;
				m_pPlayer.FireBullets( CSOW_PELLETCOUNT, vecSrc, vecAiming, VECTOR_CONE_QBARREL, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );
				cso::CreateShotgunPelletDecals( m_pPlayer, vecSrc, vecAiming, VECTOR_CONE_QBARREL, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET) );
			}

			m_pPlayer.pev.punchangle.x = -5.0 * m_iRemainingClip;
		}

		self.m_flNextPrimaryAttack = g_Engine.time + flCycleTime;
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY2;

		if( self.m_iClip == 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		self.pev.nextthink = g_Engine.time + 0.80;
		SetThink( ThinkFunction(this.EjectClipThink) );

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + 6.1;
	}

	void EjectClipThink()
	{
		Vector vecShellVelocity, vecShellOrigin;

		for( int i = 1; i <= 4; i++ )
		{
			CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 7, 8, -8, true, true );
			g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHOTSHELL );
		}
	}
}

class ammo_buckshotb : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 2.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = CSOW_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, "ammo_buckshotb", CSOW_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
} 

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_qbarrel::ammo_buckshotb", "ammo_buckshotb" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_qbarrel::weapon_qbarrel", "weapon_qbarrel" );
	g_ItemRegistry.RegisterWeapon( "weapon_qbarrel", "cso_edit", "ammo_buckshotb", "", "ammo_buckshotb" ); //"buckshot", "", "ammo_buckshot"
}

} //namespace cso_qbarrel END