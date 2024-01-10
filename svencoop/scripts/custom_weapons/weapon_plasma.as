#include "proj_plasma_projectile"
enum plasmaAnimation
{
	plasma_SHOOT1,
	plasma_SHOOT2,
	plasma_DEPLOY,
	plasma_HOLSTER,
	plasma_RELOAD,
	plasma_LONG_IDLE,
	plasma_IDLE,
	
};

const int plasma_DEFAULT_GIVE 	= 60;
const int plasma_MAX_AMMO		= 300;
const int plasma_MAX_CLIP 		= 60;
const int plasma_WEIGHT 		= 15;
const int plasma_DAMAGE1		= 15;
const int plasma_DAMAGE2		= 50;
const int plasma_PLASMA_VELOCITY	= 1500;
const float plasma_PLASMA_RADIUS_NONE	= 2.0f;
const float plasma_PLASMA_RADIUS_SECONDARY	= 300.0f;

const string plasma_MODEL_VIEW		= "models/shl/weapons/v_plasmagun.mdl";
const string plasma_MODEL_WORLD		= "models/shl/weapons/w_plasmagun.mdl";
const string plasma_MODEL_PLAYER	= "models/shl/weapons/p_plasmagun.mdl";
const string plasma_MODEL_CLIP		= "models/shl/weapons/w_plasmaclip.mdl";

const string plasma_SOUND_CHARGE_UP	= "ambience/particle_suck1.wav";
const string plasma_SOUND_CHARGE_EXPLODE	= "weapons/mortarhit.wav";
const string plasma_SPRITE_TRAIL	= "sprites/laserbeam.spr";
const string plasma_SPRITE_EXPLODE	= "sprites/shl/weapons/plasmasmall.spr";

const string plasma_SOUND_SHOOT		= "shl/weapons/plasma1.ogg";
const string plasma_SOUND_SHOOT2	= "shl/weapons/plasma2.ogg";
const string plasma_SOUND_RELOAD	= "shl/weapons/plasma_re.ogg";
int plasma_mode = 0;
	
class CWeaponplasma : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	int g_iCurrentMode;
	int g_iInSpecialReload;
		
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, plasma_MODEL_WORLD );

		self.m_iDefaultAmmo = plasma_DEFAULT_GIVE;
		g_iCurrentMode = 1;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( plasma_MODEL_VIEW );
		g_Game.PrecacheModel( plasma_MODEL_WORLD );
		g_Game.PrecacheModel( plasma_MODEL_PLAYER );
		g_Game.PrecacheModel( plasma_MODEL_CLIP );
		g_Game.PrecacheModel( plasma_SPRITE_TRAIL );
		g_Game.PrecacheModel( plasma_SPRITE_EXPLODE );
		g_Game.PrecacheModel( "sprites/shl/weapons/plasma.spr" );
		g_Game.PrecacheModel( "models/not_precached2.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + plasma_SOUND_CHARGE_UP );
		g_Game.PrecacheGeneric( "sound/" + plasma_SOUND_CHARGE_EXPLODE );

		g_Game.PrecacheGeneric( "sound/" + plasma_SOUND_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + plasma_SOUND_SHOOT2 );
		g_Game.PrecacheGeneric( "sound/" + plasma_SOUND_RELOAD );

		g_SoundSystem.PrecacheSound( plasma_SOUND_CHARGE_UP );
		g_SoundSystem.PrecacheSound( plasma_SOUND_CHARGE_EXPLODE );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );

		g_SoundSystem.PrecacheSound( plasma_SOUND_SHOOT );
		g_SoundSystem.PrecacheSound( plasma_SOUND_SHOOT2 );
		g_SoundSystem.PrecacheSound( plasma_SOUND_RELOAD );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= plasma_MAX_AMMO;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= plasma_MAX_CLIP;
		info.iSlot 		= 3;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= plasma_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
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
			
			CBasePlayer@ basePlayer = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
			g_SoundSystem.EmitSoundDyn( basePlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( plasma_MODEL_VIEW ), self.GetP_Model( plasma_MODEL_PLAYER ), plasma_DEPLOY, "gauss" );
	}
	
	void Holster( int skipLocal = 0 )
	{	
		self.m_fInReload = false;
		BaseClass.Holster( skipLocal );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	void PrimaryAttack()
	{
		Vector vecSrc, vecVelocity, vecAngles;
		CBasePlayer@ basePlayer = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
			
		if( basePlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		basePlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		basePlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		basePlayer.pev.effects = EF_MUZZLEFLASH;

		basePlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( basePlayer.pev.v_angle );
		vecSrc = basePlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 6;
		
		ShootPlasmaProjectile( basePlayer.pev, vecSrc, g_Engine.v_forward * (plasma_PLASMA_VELOCITY/2) );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.05f;
		
		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0f;
		else
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.75f;
		
		g_iInSpecialReload = 0;
		
		g_SoundSystem.EmitSoundDyn( basePlayer.edict(), CHAN_WEAPON, plasma_SOUND_SHOOT, 0.9, ATTN_NORM, 0, PITCH_NORM );
		self.SendWeaponAnim( plasma_SHOOT1, 0, 0 );
	}
	
	void SecondaryAttack()
	{
		float fPlasmaChargeTime = 0.0f;
		Vector vecSrc, vecVelocity, vecAngles;

		CBasePlayer@ basePlayer = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
		
		if( basePlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 9 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.5f;
			return;
		}
		fPlasmaChargeTime = WeaponTimeBase() + 1.5f;
		g_SoundSystem.EmitSoundDyn( basePlayer.edict(), CHAN_WEAPON, plasma_SOUND_CHARGE_UP, 0.9, ATTN_NORM, 0, PITCH_NORM );
		self.SendWeaponAnim( plasma_SHOOT2, 0, 0 );
		
		basePlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		basePlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		basePlayer.pev.effects = EF_MUZZLEFLASH;
		basePlayer.SetAnimation( PLAYER_ATTACK1 );

		SetThink( ThinkFunction( this.ShootThink ) );
		self.pev.nextthink = g_Engine.time + 0.6f;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 2.0f;
	}

	void ShootThink()
	{
		CBasePlayer@ basePlayer = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
		Vector vecSrc, vecVelocity, vecAngles;
		
		SetThink( null );
		Math.MakeVectors( basePlayer.pev.v_angle + basePlayer.pev.punchangle );
		vecSrc = basePlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 6;
		
		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0f;
		else
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.75f;
		
		g_iInSpecialReload = 0;
		self.m_flNextSecondaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 2.0f;
		
		self.m_iClip = self.m_iClip - 10;
				
		ShootPlasmaProjectile2( basePlayer.pev, vecSrc, g_Engine.v_forward * (plasma_PLASMA_VELOCITY/2) );
			
		basePlayer.pev.punchangle.x = -7.0f;
	}
	
	void Reload()
	{
		CBasePlayer@ basePlayer = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
		if( basePlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= plasma_MAX_CLIP )
			return;
		
		self.DefaultReload( plasma_MAX_CLIP, plasma_RELOAD, 2, 0 );
		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();			
	}

	void WeaponIdle()
	{
		CBasePlayer@ basePlayer = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		switch( g_PlayerFuncs.SharedRandomLong( basePlayer.random_seed, 0, 2 ) )
		{
			case 0: self.SendWeaponAnim( plasma_IDLE, 0, 0 ); break;
			case 1: self.SendWeaponAnim( plasma_LONG_IDLE, 0, 0 ); break;
			case 2: self.SendWeaponAnim( plasma_LONG_IDLE, 0, 0 ); break;
		}
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 8.0f;
	}
}

class PlasmaCell : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();
		g_EntityFuncs.SetModel( self, plasma_MODEL_CLIP );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( plasma_MODEL_CLIP );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = plasma_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, "plasma_proj", plasma_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

void Registerplasma()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CWeaponplasma", "weapon_plasma" );
	g_ItemRegistry.RegisterWeapon( "weapon_plasma", "shl/weapons", "plasma_proj" );
}

void RegisterPlasmaCell()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "PlasmaCell", "ammo_plasma_cell" );
}