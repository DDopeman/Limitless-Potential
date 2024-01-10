

const int vulcan_DEFAULT_GIVE		= 100;
const int vulcan_MAX_AMMO			= 250;
const int vulcan_WEIGHT 			= 15;
const float vulcan_DAMAGE			= 10.0f;
const int vulcan_SLOT				= 2;
const int vulcan_POSITION			= 8;

const string vulcan_MODEL_VIEW		= "models/shl/weapons/v_768mmvulcan.mdl";
const string vulcan_MODEL_WORLD		= "models/shl/weapons/w_768mmvulcan.mdl";
const string vulcan_MODEL_PLAYER	= "models/shl/weapons/p_768mmvulcan.mdl";
const string vulcan_MODEL_CLIP		= "models/shl/weapons/w_768ammo.mdl";

const string vulcan_SOUND_SHOOT		= "shl/weapons/m16burst.ogg";
const string vulcan_SOUND_SPIN		= "shl/weapons/hw_spin.ogg";
const string vulcan_SOUND_SPIN_UP	= "shl/weapons/hw_spinup.ogg";
const string vulcan_SOUND_SPIN_DOWN	= "shl/weapons/hw_spindown.ogg";
const string vulcan_SOUND_SPIN_STOP	= "buttons/button8.wav";

enum vulcan21Animation
{
	vulcan_DRAW,
	vulcan_REHOLSTER,
	vulcan_SHOOT,
	vulcan_SPINSLOW,
	vulcan_SPINMED,
	vulcan_SPINFAST,
	vulcan_STOPPED,
};

enum vulcanSpinSpeed
{
	SPIN_STOP,
	SPIN_SLOW,
	SPIN_MED,
	SPIN_FAST,
};

class CWeaponvulcan : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	int m_iShell;
	int iShellModelIndex;
	int iSpinSpeed = 0;
	float fSpinTime = 0.0f;
	bool m_bInZoom;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, vulcan_MODEL_WORLD );
		self.m_iDefaultAmmo = vulcan_DEFAULT_GIVE;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( vulcan_MODEL_VIEW );
		g_Game.PrecacheModel( vulcan_MODEL_WORLD );
		g_Game.PrecacheModel( vulcan_MODEL_PLAYER );
		g_Game.PrecacheModel( vulcan_MODEL_CLIP );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		g_SoundSystem.PrecacheSound( vulcan_SOUND_SPIN_STOP );
		g_SoundSystem.PrecacheSound( vulcan_SOUND_SPIN	 );
		g_SoundSystem.PrecacheSound( vulcan_SOUND_SPIN_UP );
		g_SoundSystem.PrecacheSound( vulcan_SOUND_SPIN_DOWN );		
		
		g_Game.PrecacheGeneric( "sound/" + vulcan_SOUND_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + vulcan_SOUND_SPIN_STOP );
		g_Game.PrecacheGeneric( "sound/" + vulcan_SOUND_SPIN );
		g_Game.PrecacheGeneric( "sound/" + vulcan_SOUND_SPIN_UP );
		g_Game.PrecacheGeneric( "sound/" + vulcan_SOUND_SPIN_DOWN );

		g_SoundSystem.PrecacheSound( vulcan_SOUND_SHOOT );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= vulcan_MAX_AMMO;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= vulcan_SLOT;
		info.iPosition 	= vulcan_POSITION;
		info.iFlags 	= 0;
		info.iWeight 	= vulcan_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
			message.End();
			return true;
		}
		
		return false;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( vulcan_MODEL_VIEW ), self.GetP_Model( vulcan_MODEL_PLAYER ), vulcan_DRAW, "mp5" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
			return bResult;
		}
	}


	void Holster( int skipLocal = 0 )
	{
		self.SendWeaponAnim( vulcan_REHOLSTER );
		BaseClass.Holster( skipLocal );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{	
		CBasePlayer@ pPlayer = m_pPlayer;
		int iAmmo = pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || iAmmo <= 0 )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		if (iSpinSpeed == SPIN_STOP)
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.51f;
			iSpinSpeed = SPIN_SLOW;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN_UP, 1.0f, ATTN_NORM );
			return;
		}
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--iAmmo;
		
		self.SendWeaponAnim( vulcan_SHOOT, 0, 0 );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SHOOT, 1.0f, ATTN_NORM );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, vulcan_DAMAGE );
			
		TraceResult tr = g_Utility.GetGlobalTrace();;
		g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SAW );
		
		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( -1.0f, 2.0f );

		g_EntityFuncs.EjectBrass( vecSrc, Vector(16.0f,-20.0f,6.0f), 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );

		m_pPlayer.pev.effects = EF_MUZZLEFLASH;
		pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, iAmmo);
		
		if (iSpinSpeed == SPIN_FAST)
			{
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.03f;
				fSpinTime = 1.01f;
				return;
			}
		
		if (iSpinSpeed == SPIN_MED)
			{
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.06f;
				fSpinTime = fSpinTime + 0.06f;
				if (fSpinTime > 1.0f)
					{
						iSpinSpeed = SPIN_FAST;
					}
				return;
			}
			
		if (iSpinSpeed == SPIN_SLOW)
			{
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.10f;
				fSpinTime = fSpinTime + 0.10f;
				if (fSpinTime > 0.5f)
					{
						iSpinSpeed = SPIN_MED;
					}
				return;
			}
		
	}

	void SecondaryAttack()
	{	
		CBasePlayer@ pPlayer = m_pPlayer;
		int iAmmo = pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || iAmmo <= 0 )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		if (iSpinSpeed == SPIN_FAST)
			{
				self.SendWeaponAnim( vulcan_SPINFAST, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2f;
				fSpinTime = 0.71f;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN, 1.0f, ATTN_NORM,0,PITCH_NORM);
				return;
			}
		
		if (iSpinSpeed == SPIN_MED)
			{
				self.SendWeaponAnim( vulcan_SPINMED, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2f;
				fSpinTime = fSpinTime + 0.2f;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN, 1.0f, ATTN_NORM,0,PITCH_NORM);
				iSpinSpeed = SPIN_FAST;
				return;
			}
		
		if (iSpinSpeed == SPIN_SLOW)
			{
				self.SendWeaponAnim( vulcan_SPINSLOW, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = fSpinTime + 0.5f;
				//g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN, 1.0f, ATTN_NORM );
				iSpinSpeed = SPIN_MED;
				return;
			}
			
		if (iSpinSpeed == SPIN_STOP)
			{
				self.SendWeaponAnim( vulcan_STOPPED, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = fSpinTime + 0.5f;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN_UP, 1.0f, ATTN_NORM,0,PITCH_NORM);
				iSpinSpeed = SPIN_SLOW;
				return;
			}
	}
	
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.1f;
			
			
		if (iSpinSpeed == SPIN_FAST)
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN_DOWN, 1.0f, ATTN_NORM,0,PITCH_NORM );
				self.SendWeaponAnim( vulcan_SPINMED, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				iSpinSpeed = SPIN_MED;
				fSpinTime = 1.01f;
				return;
			}
		
		if (iSpinSpeed == SPIN_MED)
			{
				//g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN_DOWN, 1.0f, ATTN_NORM );
				self.SendWeaponAnim( vulcan_SPINSLOW, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = 0.51f;
				iSpinSpeed = SPIN_SLOW;
				return;
			}
		
		if (iSpinSpeed == SPIN_SLOW)
			{
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, vulcan_SOUND_SPIN_STOP, 1.0f, ATTN_NORM );
				self.SendWeaponAnim( vulcan_STOPPED, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = 0.01f;
				iSpinSpeed = SPIN_STOP;
				return;
			}
	
	
	}

	void SetThink( ThinkFunction@ pThink, const float flNextThink )
	{
		SetThink( pThink );
		pev.nextthink = g_Engine.time + flNextThink;

	}
}

class A768mmBox : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();
		g_EntityFuncs.SetModel( self, vulcan_MODEL_CLIP );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( vulcan_MODEL_CLIP );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = vulcan_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, "768mmbox", vulcan_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

void Registervulcan()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CWeaponvulcan", "weapon_vulcan" );
	g_ItemRegistry.RegisterWeapon( "weapon_vulcan", "shl/weapons", "768mmbox" );
}

void RegisterA768mmBox()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "A768mmBox", "ammo_768mmbox" );
}