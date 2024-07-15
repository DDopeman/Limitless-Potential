#include "base"
#include "proj_ns_grenade"

/* Natural Selection Grenade Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_GRENADE
{

enum gr_anims 
{
	IDLEP = 0,
	FIDGET,
	FIDGET2,
	PINPULLS,
	THROW,
	DRAWPIN,
	PINPULLT,
	TOSS
};

//Models
const string MODEL_P = "models/ns/p_gr.mdl";
const string MODEL_V = "models/ns/v_gr.mdl";
const string MODEL_W = "models/ns/w_gr.mdl";

//Sounds
const string SND_DRAW = "ns/weapons/gr/grenade_draw.wav";
const string SND_PRIME = "ns/weapons/gr/grenade_prime.wav";
const string SND_THROW = "ns/weapons/gr/grenade_throw.wav";

array<string> SOUNDS = {
	SND_DRAW,
	SND_PRIME,
	SND_THROW
};

array<string> GrenExplodeSounds =
{
	"ns/weapons/explode3.wav",
	"ns/weapons/explode4.wav",
	"ns/weapons/explode5.wav"
};

//Anim timings
const float DEPLOY_TIME = 0.85f;
const float PRIME_TIME = 1.5f;
const float GRENADE_THROW_TIME = 1.5f;

//Item info
const int MAX_AMMO = 5;
const int MAX_CLIP = WEAPON_NOCLIP;
const int SLOT = 3;
const int POSITION = 20;
const int FLAGS = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
const int DEFAULT_AMMO = 1;

//Stats
const int DAMAGE = 150;
//const int RANGE = 35;
//const float ROF = 0.65;
//const float XPUNCH = .75;

const float THROW_TIME_BEFORE_RELEASE = .3f;
const float DETONATE_TIME = 0.75;
const int GRENADE_VELOCITY = 800;
const int GRENADE_ROLL_VELOCITY = 350;
const float	PARENT_VELOCITY_SCALE = .4f; //How much does the players movement speed affect the distance the grenade is thrown

const float GRENADE_GRAV = .8f;
const float GRENADE_ELAS = 0.6f;

const string PROJ_NAME = "proj_ns_grenade";

class weapon_ns_grenade : ScriptBasePlayerWeaponEntity, NSBASE::WeaponBase
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private bool m_blInAttack, m_blThrown;
	private float m_flReleaseThrow, m_flStartThrow;
	private int GetBodygroup()
	{
		return 0;
	}
	
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
		//for( uint i = 0; i < GrenExplodeSounds.length(); i++ )
		//{
		//	g_SoundSystem.PrecacheSound( GrenExplodeSounds[i] );
		//}
		
		CommonPrecache();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MAX_AMMO;
		info.iAmmo1Drop	= 1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= MAX_CLIP;
		info.iSlot 		= SLOT;
		info.iPosition 	= POSITION;
		info.iFlags 	= FLAGS;
		info.iWeight 	= 20;

		return true;
	} 
	
	bool CanHaveDuplicates()
	{
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

	private int m_iAmmoSave;
	bool Deploy()
	{	
		m_flStartThrow = 0;
		m_flReleaseThrow = -1;
		m_iAmmoSave = 0; // Zero out the ammo save 
		return Deploy( MODEL_V, MODEL_P, DRAWPIN, "gren", GetBodygroup(), DEPLOY_TIME );
	}
	
	private CBasePlayerItem@ DropItem()
	{
		m_iAmmoSave = m_pPlayer.AmmoInventory( self.m_iPrimaryAmmoType ); //Save the player's ammo pool in case it has any in DropItem

		//if( m_fExplode > 0 ) //just in case
		//	m_fExplode = 0;

		return self;
	}	

	void Holster( int skipLocal = 0 )
	{
		BaseClass.Holster( skipLocal );		
		
		m_flStartThrow = 0;
		m_flReleaseThrow = -1;

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 ) //Save the player's ammo pool in case it has any in Holster
		{
			m_iAmmoSave = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		}

		if( m_iAmmoSave <= 0 )
		{
			SetThink( ThinkFunction( DestroyThink ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM );	
	}		
	
	int	GetIdleAnimation()
	{
		int iAnim = -1;

		if( m_flStartThrow == 0 && m_flReleaseThrow == -1)
		{
			iAnim = g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 );
		}

		return iAnim;
	}

	bool ShouldRollGrenade() 
	{
		// If player is crouched, roll grenade instead
		return( m_pPlayer.pev.flags & FL_DUCKING != 0 );
	}

	int	GetShootAnimation()
	{
		int iAnim = 4;

		// If player is crouched, play roll animation
		if( ShouldRollGrenade() )
		{
			iAnim = 7;
		}

		return iAnim;

	}	

	int GetPrimeAnimation()
	{
		int iAnim = 3;

		// If player is crouched, play roll animation
		if( m_pPlayer.pev.flags & FL_DUCKING != 0 )
		{
			iAnim = 6;
		}

		return iAnim;
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;
		
		//if (this->ProcessValidAttack())
		//if (!this->mAttackButtonDownLastFrame)
		//{
		//	this->PlaybackEvent(this->mStartEvent);
		//	this->mAttackButtonDownLastFrame = true;
		//}
			
		if( m_flStartThrow == 0 )
		{
			m_flStartThrow = 1;
			
			//this->PlaybackEvent(this->mEvent, this->GetPrimeAnimation());
			self.SendWeaponAnim( GetPrimeAnimation(), 0, GetBodygroup() );
			
			// Set the animation and sound.
				
			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			//m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			// Don't idle/fire until we've finished prime animation
			self.m_flTimeWeaponIdle = g_Engine.time + PRIME_TIME;
		}
	}

	void CreateProjectile()
	{
		// Set position and velocity like we do in client event
		Vector vecStartPosition;
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		VectorMA( m_pPlayer.GetGunPosition(), 15, g_Engine.v_forward, vecStartPosition);
		
		// Offset it to the right a bit, so it emanates from your hand instead of the center of your body
		VectorMA( vecStartPosition, 5, g_Engine.v_right, vecStartPosition);
		VectorMA( vecStartPosition, 8, g_Engine.v_up, vecStartPosition);
		
		// Inherit player velocity for extra skill and finesse
		
		Vector vecVelocity;
		Vector vecInheritedVelocity;
		VectorScale( m_pPlayer.pev.velocity, PARENT_VELOCITY_SCALE, vecInheritedVelocity );
		
		if( !ShouldRollGrenade() )
		{
			VectorMA( vecInheritedVelocity, GRENADE_VELOCITY, g_Engine.v_forward, vecVelocity );
		}
		else
		{
			Vector vecTossVelocity( 0, 0, 40 );
			VectorAdd( vecInheritedVelocity, vecTossVelocity, vecInheritedVelocity );
			VectorMA( vecInheritedVelocity, GRENADE_ROLL_VELOCITY, g_Engine.v_forward, vecVelocity );
		}

		// How to handle this?  Only generate entity on server, but we should do SOMETHING on the client, no?
		//CGrenade@ pGrenade = AvHSUShootServerGrenade( m_pPlayer.pev, vecStartPosition, vecVelocity, BALANCE_VAR(kHandGrenDetonateTime), true);
		//ASSERT(pGrenade);
		

		NS_PROJ_GRENADE::CNSGrenade@ pGrenade = NS_PROJ_GRENADE::ShootExplosiveTimed( m_pPlayer.pev, vecStartPosition, vecVelocity, DETONATE_TIME, DMG_BLAST, MODEL_W, true );		
		pGrenade.pev.dmg = DAMAGE;

		// Make the grenade not very bouncy
		pGrenade.pev.gravity = GRENADE_GRAV;
		pGrenade.pev.friction = 1 - GRENADE_ELAS;

		g_EntityFuncs.SetModel( pGrenade.self, MODEL_W );

		pGrenade.pev.avelocity.x = Math.RandomLong( -300, -200 );
		
		// Rotate the grenade to the orientation it would be if it was thrown.
		VectorCopy( m_pPlayer.pev.angles, pGrenade.pev.angles );
		pGrenade.pev.angles[1] += 100;

	}	
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_flStartThrow == 1 )
		{
			// Throw it
			//this->PlaybackEvent(this->mEvent, GetShootAnimation());
			self.SendWeaponAnim( GetShootAnimation(), 0, GetBodygroup() );
			
			// Set the animation and sound.
			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			// Set time to shoot projectile, so it looks right with throw animation
			float flTimeToCreateGrenade = g_Engine.time + THROW_TIME_BEFORE_RELEASE;
			m_flReleaseThrow = flTimeToCreateGrenade;

			m_flStartThrow = -1;
		}
		else if( ( m_flStartThrow == -1 ) && ( m_flReleaseThrow <= g_Engine.time ) )
		{
			CreateProjectile();

			//this->DeductCostForShot();
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

			// Finish throw animation
			float flAnimationEnd = g_Engine.time + GRENADE_THROW_TIME;
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = flAnimationEnd;

			// We've finished the throw, don't do it again (set both inactive)
			m_flStartThrow = 0;
			m_flReleaseThrow = -1;
			self.Deploy();
		}
		else if( m_flStartThrow == 0 )
		{
			self.ResetEmptySound();
			m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			{
				// no more nades! 
				self.RetireWeapon();
				return;
			}
			
			self.SendWeaponAnim( IDLEP, 0, GetBodygroup() );
			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
		}		
	}
}
void Register()
{
	NS_PROJ_GRENADE::Register();
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_GRENADE::weapon_ns_grenade", "weapon_ns_grenade" );
	g_ItemRegistry.RegisterWeapon( "weapon_ns_grenade", "ns", "weapon_ns_grenade", "", "weapon_ns_grenade" );
}
}
