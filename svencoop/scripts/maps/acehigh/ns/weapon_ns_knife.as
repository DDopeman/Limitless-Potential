#include "base"

/* Natural Selection Knife Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_KNIFE
{
	
enum kn_anims 
{
	IDLE1 = 0,
	IDLE2,
	ATTACK1,
	ATTACK2,
	DRAW,
	FLOURISH
};	

//Models
const string szModelP = "models/ns/p_kn.mdl";
const string szModelV = "models/ns/v_kn.mdl";
const string szModelW = "models/ns/w_kn.mdl";

//Sounds
const string SND_FIRE1 = "ns/weapons/kn/kn-1.wav";
const string SND_FIRE2 = "ns/weapons/kn/kn-2.wav";
const string SND_HIT1 = "ns/weapons/kn/kn-hit-1.wav";
const string SND_HIT2 = "ns/weapons/kn/kn-hit-2.wav";
const string SND_HIT_WALL = "ns/weapons/kn/kn-hit-wall.wav";
const string SND_DRAW = "ns/weapons/kn/kn-deploy.wav";

array<string> SOUNDS = {
	SND_FIRE1,
	SND_FIRE2,
	SND_HIT1,
	SND_HIT2,
	SND_HIT_WALL,
	SND_DRAW
};

array<string> pKnifeAttackSounds = {
	"ns/weapons/kn/kn-1.wav",
	"ns/weapons/kn/kn-2.wav"
};
array<string> pKnifeHitSounds = {
	"ns/weapons/kn/kn-hit-1.wav",
	"ns/weapons/kn/kn-hit-2.wav"
};

//Anim timings
const float flDeployTime = 1.2f;

//Item info
const int iMaxAmmo = -1;
const int iMaxClip = WEAPON_NOCLIP;
const int iSlot = 0;
const int iPosition = 20;
const int iDefaultAmmo = 0;

//Stats
const int iDamage = 30;
const int iRange = 35;
const float flROF = 0.65;
const float	flXPunch = .75;

class weapon_ns_knife : ScriptBasePlayerWeaponEntity, NSBASE::WeaponBase, NSBASE::MeleeWeaponBase
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
		
		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}
		
		for( uint i = 0; i < pKnifeAttackSounds.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( pKnifeAttackSounds[i] );
			g_Game.PrecacheGeneric( "sound/" + pKnifeAttackSounds[i] );
		}
	
		for( uint i = 0; i < pKnifeHitSounds.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( pKnifeHitSounds[i] );
			g_Game.PrecacheGeneric( "sound/" + pKnifeHitSounds[i] );
		}
		
		CommonPrecache();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= iMaxAmmo;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= iMaxClip;
		info.iSlot 		= iSlot;
		info.iPosition 	= iPosition;
		info.iFlags 	= -1;
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

	bool Deploy()
	{
		return Deploy( szModelV, szModelP, DRAW, "crowbar", GetBodygroup(), flDeployTime );
	}

	void Holster( int skipLocal = 0 )
	{
		BaseClass.Holster( skipLocal );
	}	
	
	int	GetIdleAnimation()
	{
		// Only play the poking-finger animation once in awhile and play the knife flourish once in a blue moon, it's a special treat
		int iAnim = 0;
		int iRandomNum = g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 200 );

		if( iRandomNum == 0 )
		{
			iAnim = FLOURISH;
		}
		else if( iRandomNum < 16 )
		{
			iAnim = IDLE2;	
		}
		else
		{
			iAnim = IDLE1;
		}
		
		return iAnim;	
	}	
			

	void PrimaryAttack()
	{
		Swing( iDamage, pKnifeAttackSounds[Math.RandomLong( 0, pKnifeAttackSounds.length() - 1 )], pKnifeHitSounds[Math.RandomLong( 0, pKnifeAttackSounds.length() - 1 )], 
			SND_HIT_WALL, ATTACK1, ATTACK2, GetBodygroup(), iRange, flROF, flROF, flROF );
		
		m_pPlayer.pev.punchangle.x = Math.RandomFloat( -flXPunch, flXPunch);

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 10, 15 );		
	}	
	
	void WeaponIdle()
	{			
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		
		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			self.SendWeaponAnim( GetIdleAnimation(), 0, GetBodygroup() );		
			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
		}
	}	
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_KNIFE::weapon_ns_knife", "weapon_ns_knife" );
	g_ItemRegistry.RegisterWeapon( "weapon_ns_knife", "ns" );	
}
}