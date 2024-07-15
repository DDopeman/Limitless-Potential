#include "base"
#include "proj_ns_grenade"

/* Natural Selection Grenade Launcher Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_GRENADEGUN
{
enum gg_anims 
{
	IDLE_4OR0 = 0,
	IDLE_3,
	IDLE_2,
	IDLE_1,
	RELOAD_3,
	RELOAD_2,
	RELOAD_1,
	RELOAD_0,
	SHOOT_4,
	SHOOT_3,
	SHOOT_2,
	SHOOT_1,
	SHOOT_EMPTY,
	DRAW_4OR0,
	DRAW_3,
	DRAW_2,
	DRAW_1,
	CANCEL_RELOAD_1,
	CANCEL_RELOAD_2OR3
};

enum reload_status
{
	kSpecialReloadNone = 0,
	kSpecialReloadGotoReload,
	kSpecialReloadReloadShell
};

//Models
const string MODEL_P = "models/ns/p_gg.mdl";
const string MODEL_V = "models/ns/v_gg.mdl";
const string MODEL_W = "models/ns/w_gg.mdl";
const string MODEL_GREN = "models/ns/grenade.mdl";
const string MODEL_SHELL = "models/ns/shell.mdl";

//Sounds
const string SND_FIRE = "ns/weapons/gg/gg-1.wav";
const string SND_DRAW = "ns/weapons/gg/gg_draw.wav";
const string SND_INSERT = "ns/weapons/gg/gg_insert.wav";
const string SND_RELOAD_END = "ns/weapons/gg/gg_reload_end.wav";
const string SND_RELOAD_START = "ns/weapons/gg/gg_reload_start.wav";
const string SND_ROTATE = "ns/weapons/gg/gg_rotate.wav";

array<string> SOUNDS = {
	SND_FIRE,
	SND_DRAW,
	SND_INSERT,
	SND_RELOAD_END,
	SND_RELOAD_START,
	SND_ROTATE
};

array<string> SND_GREN_EXPLODE_ARR =
{
	"ns/weapons/explode3.wav",
	"ns/weapons/explode4.wav",
	"ns/weapons/explode5.wav"
};

//Anim timings
const float DEPLOY_TIME = 1.45f;
const float RELOAD_TIME = 7.5;

const float flDeployTime = 1.2f;
const float flGotoReloadTime = 0.8f;
const float flReloadShellTime = 1.1f;
const float flEndReloadTime = 1.0f;
const float flCancelReloadTime = 1.35f;

//Item info
const int MAX_AMMO = 32;
const int MAX_CLIP = 4;
const int SLOT = 3;
const int POSITION = 21;
const int DEFAULT_AMMO = MAX_CLIP;

//Stats
const int DAMAGE = 125;
const int iRange = 2000;
//const float ROF = 1.2;
const float ROF = 0.6;
const float	XPUNCH = 2;
//const Vector vecSpread = VECTOR_CONE_8DEGREES;

const float GRENADE_FORCE = 800;
const float DETONATE_TIME = 0.75;


class weapon_ns_grenadegun : ScriptBasePlayerWeaponEntity, NSBASE::WeaponBase
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

	private int m_iShell;
	private int mSpecialReload = kSpecialReloadNone;
	private float m_flNextReload;
	
	void Spawn()
	{
		Precache();
		self.m_iDefaultAmmo = DEFAULT_AMMO;
		g_EntityFuncs.SetModel( self, MODEL_W );
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_P );
		g_Game.PrecacheModel( MODEL_V );
		g_Game.PrecacheModel( MODEL_W );
		g_Game.PrecacheModel( MODEL_GREN );
		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );
		
		g_Game.PrecacheOther( "proj_ns_grenade" );

		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}

		//TODO REMOVE THEESE ARRRRRRAFEA
		
		//string BOUNCE_SOUND1     	= "ns/weapons/gr/grenade_hit1.wav";
		//string BOUNCE_SOUND2     	= "ns/weapons/gr/grenade_hit2.wav";
		//string BOUNCE_SOUND3     	= "ns/weapons/gr/grenade_hit3.wav";		
		//g_Game.PrecacheModel( "sprites/eexplo.spr" );
		//g_Game.PrecacheModel( "sprites/fexplo.spr" );
		//g_Game.PrecacheModel( "sprites/steam1.spr" );
		//g_Game.PrecacheModel( "sprites/WXplo1.spr" );
		//g_SoundSystem.PrecacheSound( BOUNCE_SOUND1 );
		//g_SoundSystem.PrecacheSound( BOUNCE_SOUND2 );
		//g_SoundSystem.PrecacheSound( BOUNCE_SOUND3 );	
		//
		//for( uint i = 0; i < SND_GREN_EXPLODE_ARR.length(); i++ )
		//	g_SoundSystem.PrecacheSound( SND_GREN_EXPLODE_ARR[i] );				
		
		CommonPrecache();
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MAX_AMMO;
		info.iAmmo1Drop	= MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= MAX_CLIP;
		info.iSlot 		= SLOT;
		info.iPosition 	= POSITION;
		info.iFlags 	= ITEM_FLAG_NOAUTOSWITCHEMPTY;
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
		return Deploy( MODEL_V, MODEL_P, GetDeployAnimation(), "mp5", GetBodygroup(), DEPLOY_TIME );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		mSpecialReload = kSpecialReloadNone;		
		BaseClass.Holster( skipLocal );
	}	
	
	int	GetDeployAnimation()
	{
		int iAnim = -1;
		
		switch( self.m_iClip )
		{
			case 4:
			case 0:
				iAnim = 13;
				break;
			case 3:
				iAnim = 14;
				break;
			case 2:
				iAnim = 15;
				break;
			case 1:
				iAnim = 16;
				break;
		}
		
		return iAnim;
	}
	
	float GetReloadTime()
	{
		int iShotsToLoad = MAX_CLIP - self.m_iClip;
		
		float flBaseReloadTime, flGrenadeLoadTime; 
		flBaseReloadTime = 2.28;
		flGrenadeLoadTime = 1.16;

		return flBaseReloadTime + iShotsToLoad*flGrenadeLoadTime;
	}	
	
	int	GetIdleAnimation()
	{
		int iAnim = -1;
		
		switch( self.m_iClip )
		{
			case 0:
			case 4:
				iAnim = 0;
				break;

			case 1:
				iAnim = 3;
				break;

			case 2:
				iAnim = 2;
				break;

			case 3:
				iAnim = 1;
				break;
		}
		
		return iAnim;
	}

	int	GetReloadAnimation()
	{
		int iAnim = -1;
		
		switch( self.m_iClip )
		{
		case 0:
			iAnim = 7;
			break;
			
		case 1:
			iAnim = 6;
			break;
			
		case 2:
			iAnim = 5;
			break;
			
		case 3:
			iAnim = 4;
			break;
		}
		
		return iAnim;
	}	
	
	int	GetShootAnimation()
	{
		int iAnim = -1;

		switch( self.m_iClip )
		{
		case 4:
			iAnim = 8;
			break;
		case 3:
			iAnim = 9;
			break;
		case 2:
			iAnim = 10;
			break;
		case 1:
			iAnim = 11;
			break;
		case 0:
			iAnim = 12;
			break;
		}

		return iAnim;
	}	

	void FireProjectiles()
	{
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAim = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		Vector vecVelocity = vecAim * GRENADE_FORCE;// + m_pPlayer.pev.velocity;
		
		NS_PROJ_GRENADE::CNSGrenade@ pGrenade = NS_PROJ_GRENADE::ShootExplosiveTimed( m_pPlayer.pev, vecSrc, vecVelocity, DETONATE_TIME, DMG_BLAST, MODEL_GREN );		
		pGrenade.pev.dmg = DAMAGE;
	}	
	
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == 3 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + ROF;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.SendWeaponAnim( SHOOT_EMPTY, 0, GetBodygroup() );
			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			return;
		}
			
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( GetShootAnimation(), 0, GetBodygroup() );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SND_FIRE, Math.RandomFloat( 0.95, 1.0 ), 0.8, 0, 94 + Math.RandomLong( 0, 0xf ) );
		
		FireProjectiles();
		
		--self.m_iClip;
		
		m_pPlayer.pev.punchangle.x = Math.RandomFloat( -XPUNCH, XPUNCH);
		
		//ShellEject( m_pPlayer, m_iShell, Vector( 16, 5, -4 ) );
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ROF;
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 10, 15 );		
			

	}

	void ItemPostFrame()
	{
		// Checks if the player pressed one of the attack buttons, stops the reload and then attack
		if( mSpecialReload != kSpecialReloadNone )
		{
			if( ( m_pPlayer.pev.button & (IN_ATTACK | IN_ATTACK2 | IN_ALT1) != 0 || ( self.m_iClip >= MAX_CLIP && m_pPlayer.pev.button & IN_RELOAD != 0 ) ) && m_flNextReload <= g_Engine.time )
			{
				//eh, this'll do
				if( self.m_iClip == 2 || self.m_iClip == 3 )
				{
					self.SendWeaponAnim( CANCEL_RELOAD_2OR3, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + flCancelReloadTime;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + ROF;
					mSpecialReload = kSpecialReloadNone;					
				}
				else if( self.m_iClip == 1 )
				{
					self.SendWeaponAnim( CANCEL_RELOAD_1, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + flCancelReloadTime;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + ROF;
					mSpecialReload = kSpecialReloadNone;					
				}
			}
		}
		BaseClass.ItemPostFrame();
	}			

	//void Reload()
	//{
	//	if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
	//		return;			
	//		
	//	Reload( MAX_CLIP, GetReloadAnimation(), GetReloadTime(), GetBodygroup() );
	//	
	//	BaseClass.Reload();
	//}

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
	
					self.SendWeaponAnim( GetReloadAnimation(), 0, GetBodygroup() );
	
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
						//self.SendWeaponAnim( RELOAD, 0, GetBodygroup() );
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
		
					//self.SendWeaponAnim( END_RELOAD, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + flEndReloadTime;
				}
			}
			else
			{
				// Hack to prevent idle animation from playing mid-reload.  Not sure how to fix this right, but all this special reloading is happening server-side, client doesn't know about it
				if( self.m_iClip == MAX_CLIP )
				{
					//self.SendWeaponAnim( GetIdleAnimation(), 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
				}
			}
		}
	}	
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_GRENADEGUN::weapon_ns_grenadegun", "weapon_ns_grenadegun" );
	g_ItemRegistry.RegisterWeapon( "weapon_ns_grenadegun", "ns", "ARgrenades", "", "ammo_ARgrenades" );
}
}