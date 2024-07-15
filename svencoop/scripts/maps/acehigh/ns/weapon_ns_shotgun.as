#include "base"

/* Natural Selection Shotgun Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_SHOTGUN
{
enum sg_anims 
{
	IDLE1 = 0,
	IDLE2,
	GOTO_RELOAD,
	RELOAD,
	END_RELOAD,
	SHOOT,
	SHOOT_EMPTY,
	DRAW
};

enum reload_status
{
	kSpecialReloadNone = 0,
	kSpecialReloadGotoReload,
	kSpecialReloadReloadShell
};

//Models
const string szModelP = "models/ns/p_sg.mdl";
const string szModelV = "models/ns/v_sg.mdl";
const string szModelW = "models/ns/w_sg.mdl";
const string szShell = "models/ns/shotshell.mdl";

//Sounds
const string szSoundPrimaryFire = "ns/weapons/sg/sg-1.wav";
const string szSoundReload = "ns/weapons/sg/shotgun_reload.wav";
const string szSoundDraw = "ns/weapons/sg/shotgun_draw.wav";
const string szSoundPump = "ns/weapons/sg/shotgun_pump.wav";
const string szSoundCock = "ns/weapons/sg/sg-cock.wav";
const string szSoundStockRelease = "ns/weapons/sg/shotgun_stock_release.wav";

array<string> SOUNDS = {
	szSoundPrimaryFire,
	szSoundReload,
	szSoundDraw,
	szSoundPump,
	szSoundCock,
	szSoundStockRelease
};

//Anim timings
const float flDeployTime = 1.6f;
const float flGotoReloadTime = 0.8f;
const float flReloadShellTime = 0.6f;
const float flEndReloadTime = 1.4f;

//Item info
const int MAX_AMMO = 40;
const int MAX_CLIP = 8;
const int iSlot = 2;
const int iPosition = 20;
const int iDefaultAmmo = MAX_CLIP;

//Stats
const int iBulletsPerShot = 10;
const int iDamage = 10;
const int iRange = 4096;
//const float flROF = 1.3;
const float flROF = 0.6;
const float flReloadTime = .22f;
const float	flXPunch = 5;
const int iBarrelLength = 25;
const Vector vecSpread = VECTOR_CONE_20DEGREES;
const Vector vecMidSpread = VECTOR_CONE_8DEGREES;
const Vector vecInnerSpread = VECTOR_CONE_3DEGREES;

class weapon_ns_shotgun : ScriptBasePlayerWeaponEntity, NSBASE::WeaponBase
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private int GetBodygroup()
	{
		return 0;
	}	
	
	private int mSpecialReload = kSpecialReloadNone;
	private float m_flNextReload;
	private int m_iShell;
	
	void Spawn()
	{
		Precache();
		self.m_iDefaultAmmo = iDefaultAmmo;
		g_EntityFuncs.SetModel( self, szModelW );		
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( szModelP );
		g_Game.PrecacheModel( szModelV );
		g_Game.PrecacheModel( szModelW );
		m_iShell = g_Game.PrecacheModel( szShell );
		
		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}
		
		CommonPrecache();
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MAX_AMMO;
		info.iAmmo1Drop	= MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= MAX_CLIP;
		info.iSlot 		= iSlot;
		info.iPosition 	= iPosition;
		info.iFlags 	= ITEM_FLAG_NOAUTOSWITCHEMPTY;;
		info.iWeight 	= 20;

		return true;
	} 

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
		message.End();

		return true;
	}	
	
	bool PlayEmptySound()
	{
		return CommonPlayEmptySound();
	}	
	
	bool Deploy()
	{	
		return Deploy( szModelV, szModelP, DRAW, "shotgun", GetBodygroup(), flDeployTime );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		mSpecialReload = kSpecialReloadNone;
		BaseClass.Holster( skipLocal );
	}	
	
	Vector GetProjectileSpread()
	{
		return vecMidSpread;
	}
	
	int	GetIdleAnimation()
	{
		int iAnim = 0;
		int iRandomNum = g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 );

		switch(iRandomNum)
		{
		case 0:
			iAnim = IDLE1;
			break;
		case 1:
			iAnim = IDLE2;
			break;
		}
		
		return iAnim;
	}
	
	void DropItem()
	{
		return;
	}

	void FireProjectiles()
	{
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		// Fire the bullets and apply damage
		m_pPlayer.FireBullets( iBulletsPerShot, vecSrc, vecAiming, GetProjectileSpread(), iRange, BULLET_PLAYER_CUSTOMDAMAGE, 0, iDamage );
		
		ShootWeapon( vecSrc, vecAiming, iBulletsPerShot, GetProjectileSpread(), 4096, iDamage, false, DMG_BULLET | DMG_NEVERGIB );
	}	
	
	
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == 3 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + flROF;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.SendWeaponAnim( SHOOT_EMPTY, 0, GetBodygroup() );
			self.m_flNextPrimaryAttack = g_Engine.time + flROF;
			return;
		}
		
		if( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 )
			return;	
			
		--self.m_iClip;
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, szSoundPrimaryFire, Math.RandomFloat( 0.95, 1.0 ), 0.8, 0, 94 + Math.RandomLong( 0, 0xf ) );
		
		FireProjectiles();
		
		m_pPlayer.pev.punchangle.x = Math.RandomFloat( -flXPunch, flXPunch);
		
		ShellEject( m_pPlayer, m_iShell, Vector( 15, 8, -4 ), TE_BOUNCE_SHOTSHELL );
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flROF;
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 10, 15 );		
			

	}
	
	void ItemPostFrame()
	{
		// Checks if the player pressed one of the attack buttons, stops the reload and then attack
		if( mSpecialReload != kSpecialReloadNone )
		{
			if( ( m_pPlayer.pev.button & (IN_ATTACK | IN_ATTACK2 | IN_ALT1) != 0 || ( self.m_iClip >= MAX_CLIP && m_pPlayer.pev.button & IN_RELOAD != 0 ) ) && m_flNextReload <= g_Engine.time )
			{
				self.SendWeaponAnim( END_RELOAD, 0, GetBodygroup() );

				self.m_flTimeWeaponIdle = g_Engine.time + flEndReloadTime;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + flROF;
				mSpecialReload = kSpecialReloadNone;
			}
		}
		BaseClass.ItemPostFrame();
	}	

	void Reload()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( self.m_iClip == MAX_CLIP || iAmmo <= 0 )
			return;
			
		if( m_flNextReload > g_Engine.time )
			return;			
			
		if( ( iAmmo != 0 ) && ( self.m_iClip < MAX_CLIP ) )
		{
			// don't reload until recoil is done
			if( self.m_flNextPrimaryAttack <= g_Engine.time )
			{
				if( mSpecialReload == kSpecialReloadNone )
				{
					// Start reload
					mSpecialReload = kSpecialReloadGotoReload;
	
					self.SendWeaponAnim( GOTO_RELOAD, 0, GetBodygroup() );
	
					//m_pPlayer.m_flNextAttack = g_Engine.time + flGotoReloadTime;
					m_flNextReload = g_Engine.time + flGotoReloadTime;
					self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flGotoReloadTime;
				
				}
				else if( mSpecialReload == kSpecialReloadGotoReload )
				{
					if( self.m_flTimeWeaponIdle <= g_Engine.time )
					{
						// was waiting for gun to move to side
						mSpecialReload = kSpecialReloadReloadShell;
						self.SendWeaponAnim( RELOAD, 0, GetBodygroup() );
						m_flNextReload = g_Engine.time + flReloadShellTime;
						self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flReloadShellTime;
					}
				}
				else if( mSpecialReload == kSpecialReloadReloadShell )
				{
					//DefaultReload(MAX_CLIP, theReloadAnimation, theReloadTime);
	
					// Don't idle for a bit
					//this->SetNextIdle();
	
					// Add them to the clip
					self.m_iClip++;
					iAmmo -= 1;
					mSpecialReload = kSpecialReloadGotoReload;
				}
		
				
			}
		}
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );		
		BaseClass.Reload();
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( ( self.m_iClip == 0 ) && ( mSpecialReload == kSpecialReloadNone ) && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
				self.Reload();
			else if( mSpecialReload != kSpecialReloadNone )
			{
				if( self.m_iClip != MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
					self.Reload();
				else
				{
					// reload debounce has timed out
					mSpecialReload = kSpecialReloadNone;
		
					self.SendWeaponAnim( END_RELOAD, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + flEndReloadTime;
				}
			}
			else
			{
				// Hack to prevent idle animation from playing mid-reload.  Not sure how to fix this right, but all this special reloading is happening server-side, client doesn't know about it
				if( self.m_iClip == MAX_CLIP )
				{
					self.SendWeaponAnim( GetIdleAnimation(), 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
				}
			}
		}
	}	
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_SHOTGUN::weapon_ns_shotgun", "weapon_ns_shotgun" );
	g_ItemRegistry.RegisterWeapon( "weapon_ns_shotgun", "ns", "buckshot", "", "ammo_buckshot" );
}
}