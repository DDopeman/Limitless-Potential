#include "base"
#include "item_ns_mine"

/* Natural Selection Mine Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_MINE
{

enum mine_anims 
{
	IDLE = 0,
	IDLE2,
	DRAW,
	ACTIVATE,
	PLANT
};

//Models
const string MODEL_P = "models/ns/p_mine.mdl";
const string MODEL_V = "models/ns/v_mine.mdl";
const string MODEL_W = "models/ns/w_mine.mdl";
const string MODEL_W2 = "models/ns/w_mine2.mdl";

//Sounds
const string SND_DRAW = "ns/weapons/mine/mine_draw.wav";
const string SND_DEPLOY = "ns/weapons/mine/mine_deploy.wav";
const string SND_ACTIVATE = "ns/weapons/mine/mine_activate.wav";
const string SND_CHARGE = "ns/weapons/mine/mine_charge.wav";
const string SND_STEP = "ns/weapons/mine/mine_step.wav";

array<string> SOUNDS = {
	SND_DRAW,
	SND_DEPLOY,
	SND_ACTIVATE,
	SND_CHARGE,
	SND_STEP
};

//Anim timings
const float DEPLOY_TIME = 3.1f;
//Item info
const int MAX_AMMO = 3;
const int MAX_CLIP = WEAPON_NOCLIP;
const int SLOT = 3;
const int POSITION = 22;
const int FLAGS = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
const int DEFAULT_AMMO = 1;

//Stats
const int DAMAGE = 125;
const int RANGE = 128;
const float ROF = 1;
const float XPUNCH = .75;


class weapon_ns_mine : ScriptBasePlayerWeaponEntity, NSBASE::WeaponBase
{
	private bool m_blPlanted = false;

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
		self.m_iDefaultAmmo = DEFAULT_AMMO;
		g_EntityFuncs.SetModel( self, MODEL_W );
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_P );
		g_Game.PrecacheModel( MODEL_V );
		g_Game.PrecacheModel( MODEL_W );
		g_Game.PrecacheModel( MODEL_W2 );
		
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

	bool Deploy()
	{	
		return Deploy( MODEL_V, MODEL_P, DRAW, "trip", GetBodygroup(), DEPLOY_TIME );
	}

	void Holster( int skipLocal = 0 )
	{
		BaseClass.Holster( skipLocal );		
		m_blPlanted = false;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM );	
	}
	
	int	GetIdleAnimation()
	{
		int iAnim = 0;
		int iRandomNum = g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 );

		switch(iRandomNum)
		{
		case 0:
			iAnim = IDLE;
			break;
		case 1:
			iAnim = IDLE2;
			break;
		}
		
		return iAnim;
	}	

	bool GetDropLocation( Vector& out vecLocation, Vector& out vecAngles )
	{
		bool blSuccess = false;

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc	 = m_pPlayer.GetGunPosition( );
		Vector vecAiming = g_Engine.v_forward;
		
		TraceResult tr;

		g_Utility.TraceLine( vecSrc, vecSrc + vecAiming*RANGE, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			// Mines can't be planted on players or buildings
			if( !pHit.IsPlayer() )
			{
				int kOffset = 8;
				Vector vecPotentialOrigin = tr.vecEndPos + tr.vecPlaneNormal * kOffset;

				array<CBaseEntity@> pEntityList;
				pEntityList.insertLast( pHit );

				// Make sure there isn't an entity nearby that this would block
				@pHit = null;
				const int kMineSearchRadius = 30;
				while( ( @pHit = g_EntityFuncs.FindEntityInSphere( pHit, vecPotentialOrigin, kMineSearchRadius, "*", "classname" ) ) !is null )
				{		
					pEntityList.insertLast( pHit );
				}
				
				// For the mine placement to be valid, the entity it hit, and all the entities nearby must be valid and non-blocking
				blSuccess = true;
				for( uint i = 0; i < pEntityList.length(); i++ )
				{
					CBaseEntity@ pCurrentEntity = pEntityList[i];
					if( pCurrentEntity is null || ( pCurrentEntity.pev.flags & FL_CONVEYOR > 0 ) 
						|| pCurrentEntity.pev.classname == "func_door" || pCurrentEntity.pev.classname == "func_rot_door"
						|| pCurrentEntity.pev.classname == "monster_ns_mine" 
						)
					{
						blSuccess = false;
						break;
					}
				}

				if( blSuccess )
				{
					VectorCopy( vecPotentialOrigin, vecLocation );
					g_EngineFuncs.VecToAngles( tr.vecPlaneNormal, vecAngles );
				}

			}

		}

		return blSuccess;
	}	
	
	bool FireProjectiles()
	{
		Vector vecMineOrigin;
		Vector vecMineAngles;
		if( GetDropLocation( vecMineOrigin, vecMineAngles ) )
		{
			//GetGameRules()->MarkDramaticEvent(kMinePlacePriority, this->m_pPlayer);
			
			dictionary dKeyvalues;
			
			dKeyvalues =
			{
				{ "origin", "" + ( vecMineOrigin ).ToString() },
				{ "angles", "" + ( vecMineAngles ).ToString() }
			};
			
			CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "monster_ns_mine", dKeyvalues, true );
			if( pEntity is null )
				return false;
				
			@pEntity.pev.euser1 = m_pPlayer.edict();
			pEntity.pev.team = m_pPlayer.pev.team;
				
			g_EntityFuncs.DispatchSpawn( pEntity.edict() );
			
			//NS_DEPLOYED_MINE::CNSMine@ pMine = cast<NS_DEPLOYED_MINE::CNSMine@>( g_EntityFuncs.CastToScriptClass( pEntity ) );
			
			
			//g_EntityFuncs.SetOrigin( pEntity, pEntity.pev.origin );
			//g_EntityFuncs.SetSize( pEntity.pev, Vector( -8, -8, -8 ), Vector( 8, 8, 8 ) );
			
			//g_EntityFuncs.SetOrigin( pMine.self, vecMineOrigin );
			//pMine.pev.angles = vecMineAngles;
			//@pMine.pev.owner = m_pPlayer.edict();

			// Set the team so it doesn't blow us up, remember the owner so proper credit can be given
			//pMine.pev.team = m_pPlayer.pev.team;
			//pMine.SetPlacer( m_pPlayer.pev );
			
			return true;
		}
		else
			return false;
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == 3 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + ROF;
			return;
		}
		
		if( m_blPlanted )
			return;

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		if( !FireProjectiles() )
			return;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_blPlanted = true;
		self.SendWeaponAnim( PLANT, 0, GetBodygroup() );		
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
		{
			// no more mines! 
			m_blPlanted = false;
			self.RetireWeapon();
			return;
		}	
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ROF;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.5;		
	}	
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{			
			if( m_blPlanted )
			{
				self.SendWeaponAnim( DRAW, 0, GetBodygroup() );
				self.m_flTimeWeaponIdle = g_Engine.time + DEPLOY_TIME;
				self.m_flNextPrimaryAttack = g_Engine.time + ROF;
				m_blPlanted = false;
			}
			else
			{
				self.SendWeaponAnim( GetIdleAnimation(), 0, GetBodygroup() );
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 12 );
			}
		}
	}
}
void Register()
{
	NS_DEPLOYED_MINE::Register();
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_MINE::weapon_ns_mine", "weapon_ns_mine" );
	g_ItemRegistry.RegisterWeapon( "weapon_ns_mine", "ns", "weapon_ns_mine", "", "weapon_ns_mine" );
}
}
