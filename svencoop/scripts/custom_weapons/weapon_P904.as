#include "proj_pbullet"

const int P904_DEFAULT_GIVE		= 50;
const int P904_DEFAULT_GIVE2	= 0;
const int P904_MAX_AMMO			= 250;
const int P904_MAX_AMMO2		= 10;
const int P904_MAX_CLIP 			= 50;
const int P904_WEIGHT 				= 15;
const float P904_DAMAGE			= 12.0f;
const int P904_SLOT				= 2;
const int P904_POSITION			= 7;

const string P904_MODEL_VIEW		= "models/shl/weapons/v_p904.mdl";
const string P904_MODEL_WORLD		= "models/shl/weapons/w_p904.mdl";
const string P904_MODEL_PLAYER		= "models/shl/weapons/p_p904.mdl";

const string P904_SOUND_SHOOT		= "shl/weapons/m16burst.ogg";
const string P904_SOUND_RELOAD		= "shl/weapons/p904_reload1.ogg";
const string P904_SOUND_RELOAD2		= "shl/weapons/p904_reload2.ogg";

enum P904Animation
{
	P904_SHOOT,
	P904_GRENADE,
	P904_UP,
	P904_RELOAD,
	P904_IDLE,
	P904_LONGIDLE,
};

class CWeaponP904 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	int	m_iSecondaryAmmo;
	float m_flNextAnimTime;
	int m_iShell;
			
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, P904_MODEL_WORLD );
		self.m_iDefaultAmmo = P904_DEFAULT_GIVE;
		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( P904_MODEL_VIEW );
		g_Game.PrecacheModel( P904_MODEL_WORLD );
		g_Game.PrecacheModel( P904_MODEL_PLAYER );
		g_Game.PrecacheModel( "models/grenade.mdl" );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		g_SoundSystem.PrecacheSound( "hl/weapons/glauncher.wav" );
		g_SoundSystem.PrecacheSound( "hl/weapons/glauncher2.wav" );

		g_Game.PrecacheGeneric( "sound/" + P904_SOUND_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + P904_SOUND_RELOAD );
		g_Game.PrecacheGeneric( "sound/" + P904_SOUND_RELOAD2 );
		
		g_SoundSystem.PrecacheSound( P904_SOUND_SHOOT );
		g_SoundSystem.PrecacheSound( P904_SOUND_RELOAD );
		g_SoundSystem.PrecacheSound( P904_SOUND_RELOAD2 );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= P904_MAX_AMMO;
		info.iMaxAmmo2 	= P904_MAX_AMMO2;
		info.iMaxClip 	= P904_MAX_CLIP;
		info.iSlot 		= P904_SLOT;
		info.iPosition 	= P904_POSITION;
		info.iFlags 	= 0;
		info.iWeight 	= P904_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model( P904_MODEL_VIEW ), self.GetP_Model( P904_MODEL_PLAYER ), P904_UP, "mp5" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
			return bResult;
		}
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{	
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0: self.SendWeaponAnim( P904_SHOOT, 0, 0 ); break;
			case 1: self.SendWeaponAnim( P904_SHOOT, 0, 0 ); break;
			case 2: self.SendWeaponAnim( P904_SHOOT, 0, 0 ); break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, P904_SOUND_SHOOT, 1.0f, ATTN_NORM );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, P904_DAMAGE );
		TraceResult tr = g_Utility.GetGlobalTrace();;
		g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SAW );
		
		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( -1.25f, 2.5f );

		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.06;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + 4.0f;
		
		
		m_pPlayer.pev.effects = EF_MUZZLEFLASH;
	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}
		
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			return;
		}
	

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;
	
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

		m_pPlayer.pev.punchangle.x = -10.0;
	
		self.SendWeaponAnim( P904_GRENADE );
	
		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
	
		if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP3
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/glauncher.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		else
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP3
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/glauncher2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
	
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		// we don't add in player velocity anymore.
		if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
		{
			g_EntityFuncs.ShootContact( m_pPlayer.pev, 
								m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
								g_Engine.v_forward * 900 ); //800
		}
		else
		{
			g_EntityFuncs.ShootContact( m_pPlayer.pev, 
								m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
								g_Engine.v_forward * 900 ); //800
		}
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;// idle pretty soon after shooting.
	
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
			// HEV suit - indicate out of ammo condition
		m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	
	}
	
	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= P904_MAX_CLIP )
			return;
		
		self.DefaultReload( P904_MAX_CLIP, P904_RELOAD, 1.83, 0 );
		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0: self.SendWeaponAnim( P904_IDLE, 0, 0 ); break;
			case 1: self.SendWeaponAnim( P904_LONGIDLE, 0, 0 ); break;
			case 2: self.SendWeaponAnim( P904_LONGIDLE, 0, 0 ); break;
		}
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 8.0f;
	}

	void SetThink( ThinkFunction@ pThink, const float flNextThink )
	{
		SetThink( pThink );
		pev.nextthink = g_Engine.time + flNextThink;
	}
}

void RegisterP904()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CWeaponP904", "weapon_P904" );
	g_ItemRegistry.RegisterWeapon( "weapon_P904", "shl/weapons", "768mmbox" , "ARgrenades");
}