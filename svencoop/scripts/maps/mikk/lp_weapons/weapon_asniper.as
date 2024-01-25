#include "base_tfc"

enum ASAnimation_e
{
	AUTOSNIPER_LONGIDLE = 0,
	AUTOSNIPER_IDLE1,
	AUTOSNIPER_SHOOT1,
	AUTOSNIPER_SHOOT2,
	AUTOSNIPER_RELOAD,
	AUTOSNIPER_DRAW
};

namespace AUTOSNIPER
{

const string AS_A_MODEL = "models/expanded_arsenal/w_autosniperclip.mdl";
const int AUTOSNIPER_DEFAULT_GIVE		= 20;
const int AUTOSNIPER_MAX_CARRY			= 600;
const int AUTOSNIPER_MAX_CLIP			= 20;
const int AUTOSNIPER_WEIGHT				= 30;
const int AUTOSNIPER_AMMO_GIVE 			= 20;

class weapon_asniper : ScriptBasePlayerWeaponEntity
{
	float m_flNextShellTime;
	int g_iCurrentMode;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/expanded_arsenal/w_autosniper.mdl" );
		
		self.m_iDefaultAmmo = AUTOSNIPER_DEFAULT_GIVE;
		g_iCurrentMode = CS16_MODE_NOSCOPE;
		m_flNextShellTime = 0.0;
		self.pev.scale = 1.3;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/expanded_arsenal/v_autosniper.mdl" );
		g_Game.PrecacheModel( "models/expanded_arsenal/w_autosniper.mdl" );
		g_Game.PrecacheModel( "models/expanded_arsenal/p_autosniper.mdl" );
		g_Game.PrecacheModel( AS_A_MODEL );
		
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/autosniper-1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/autosniper-2.wav" ); // precacha el nuevo -mikk .... okey mongol -kezaeiv
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/weapon_draw.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/autosniper_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/autosniper_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/zoom.wav" );
		
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/fidget_1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/fidget_2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/fidget_3.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/fidget_4.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/destroyer_draw.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/destroyer_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/destroyer_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/weapon_draw.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/weapon_catch.wav" );
		g_Game.PrecacheGeneric( "sound/" + "expanded_arsenal/weapon_holster.wav" );
		g_Game.PrecacheGeneric( "sound/" + "hlclassic/items/guncock1.wav" );
		
		g_SoundSystem.PrecacheSound( "expanded_arsenal/autosniper-1.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/autosniper-2.wav" ); // precacha el nuevo -mikk .... okey mongol -kezaeiv
	
		g_SoundSystem.PrecacheSound( "expanded_arsenal/autosniper-1.wav" );	
		g_SoundSystem.PrecacheSound( "expanded_arsenal/weapon_draw.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/autosniper_clipin.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/autosniper_clipout.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/zoom.wav" );
		
		g_SoundSystem.PrecacheSound( "expanded_arsenal/fidget_1.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/fidget_2.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/fidget_3.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/fidget_4.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/destroyer_draw.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/destroyer_clipout.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/destroyer_clipin.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/weapon_draw.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/weapon_catch.wav" );
		g_SoundSystem.PrecacheSound( "expanded_arsenal/weapon_holster.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/items/guncock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "expanded_arsenal/ammo_new.spr");
		g_Game.PrecacheGeneric( "sprites/" + "expanded_arsenal/autosniper.spr");
		g_Game.PrecacheGeneric( "sprites/" + "expanded_arsenal/autosniper_s.spr");
		g_Game.PrecacheGeneric( "sprites/" + "expanded_arsenal/sniper_scope.spr");
		g_Game.PrecacheGeneric( "sprites/" + "expanded_arsenal/weapon_asniper.txt");
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= AUTOSNIPER_MAX_CARRY;
		info.iAmmo1Drop = AUTOSNIPER_MAX_CLIP;
		info.iMaxAmmo2	= -1;
		info.iAmmo2Drop = -1;
		info.iMaxClip	= AUTOSNIPER_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 7;
		info.iFlags		= 0;
		info.iWeight	= AUTOSNIPER_WEIGHT;
		
		return true;
	}
	
	CBasePlayer@ getPlayer()
	{
		CBaseEntity@ e_plr = self.m_hPlayer;
		return cast<CBasePlayer@>(e_plr);
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage cs25( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				cs25.WriteLong( self.m_iId );
			cs25.End();
			return true;
		}
		
		return false;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	void Holster( int skipLocal = 0 ) 
    {     
		self.m_fInReload = false;
		
		if ( self.m_fInZoom )
		{
			SecondaryAttack();
		}

		g_iCurrentMode = 0;
		getPlayer().pev.maxspeed = 0;
		SetThink( null );
		ToggleZoom( 0 );
		getPlayer().pev.velocity = getPlayer().pev.velocity * 1 ;
		getPlayer().SetMaxSpeedOverride( -1 );
		
		BaseClass.Holster( skipLocal );
    }
	
	void SetFOV( int fov )
	{
		getPlayer().pev.fov = getPlayer().m_iFOV = fov;
	}
	
	void ToggleZoom( int zoomedFOV )
	{
		if ( self.m_fInZoom == true )
		{
			SetFOV( 0 ); // 0 means reset to default fov
		}
		else if ( self.m_fInZoom == false )
		{
			SetFOV( zoomedFOV );
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	protected bool m_fDropped;
	CBasePlayerItem@ DropItem() // drops the item
	{
		m_fDropped = true;
		self.pev.scale = 1.3;
		SetThink( null );
		return self;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/expanded_arsenal/v_autosniper.mdl" ), self.GetP_Model( "models/expanded_arsenal/p_autosniper.mdl" ), AUTOSNIPER_DRAW, "mp5" );
		
			float deployTime = 0.55;
			self.pev.scale = 0;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
		
	void PrimaryAttack()
	{
		if( getPlayer().pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1f;
		
		--self.m_iClip;
		
		getPlayer().pev.effects |= EF_MUZZLEFLASH;
		getPlayer().m_iWeaponVolume = LOUD_GUN_VOLUME;
		getPlayer().m_iWeaponFlash = BRIGHT_GUN_FLASH;
		getPlayer().SetAnimation( PLAYER_ATTACK1 );
		
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.01f;
		
		switch ( g_PlayerFuncs.SharedRandomLong( getPlayer().random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( AUTOSNIPER_SHOOT1, 0, 0 ); break;
			case 1: self.SendWeaponAnim( AUTOSNIPER_SHOOT2, 0, 0 ); break;
		}
		
		if(g_iCurrentMode == CS16_MODE_NOSCOPE)
		{
			g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "expanded_arsenal/autosniper-1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM ); // idk- testea -mikk .... okey mongol -kezaeiv
		}
		else{
			g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "expanded_arsenal/autosniper-2.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		Vector vecSrc	 = getPlayer().GetGunPosition();
		Vector vecAiming = getPlayer().GetAutoaimVector( AUTOAIM_5DEGREES );
		
			int m_iBulletDamage = 15;
		
		if ( g_iCurrentMode == CS16_MODE_NOSCOPE )
		{
			getPlayer().FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.08f;
		}
		else
		{
			getPlayer().FireBullets( 2, vecSrc, vecAiming, VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.25f;
		}
		
		if( self.m_iClip == 0 && getPlayer().m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			getPlayer().SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		getPlayer().pev.punchangle.x = Math.RandomLong( 0, 0 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.3f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir;
		
		if ( g_iCurrentMode == CS16_MODE_NOSCOPE )
		{
			vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;
		}
		else
		{
			vecDir = vecAiming + x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;
		}


		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, getPlayer().edict(), tr );

		SetThink( ThinkFunction( EjectBrassThink ) );
		self.pev.nextthink = WeaponTimeBase() + 0.07;
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
	}

	void EjectBrassThink()
	{
		Vector vecShellVelocity, vecShellOrigin;
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
		CS16GetDefaultShellInfo( getPlayer(), vecShellVelocity, vecShellOrigin, 13, 9, -8, true, false );
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;

		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, getPlayer().pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void SecondaryAttack()
	{
	

	
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.40f;
		switch ( g_iCurrentMode )
		{
			case CS16_MODE_NOSCOPE:
			{
				g_iCurrentMode = CS16_MODE_SCOPED;
			//	getPlayer().pev.maxspeed = 140;
				getPlayer().pev.velocity = getPlayer().pev.velocity * 0.6;	// modify this for velocity -mikk .... okey mongol -kezaeiv
				getPlayer().SetMaxSpeedOverride( 220 );						// modify this for speed -mikk .... okey mongol -kezaeiv
				ToggleZoom( 25 );
				getPlayer().m_szAnimExtension = "sniperscope";
				break;
			}
			case CS16_MODE_SCOPED:
			{
				g_iCurrentMode = CS16_MODE_NOSCOPE;
			//	getPlayer().pev.maxspeed = 0;
				getPlayer().pev.velocity = getPlayer().pev.velocity * 1 ;
				getPlayer().SetMaxSpeedOverride( -1 );	// -1 mean default -mikk .... okey mongol -kezaeiv
				ToggleZoom( 0 );
				getPlayer().m_szAnimExtension = "sniper";
				break;
			}
		}
		g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "expanded_arsenal/zoom.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void Reload()
	{
		if( self.m_iClip == AUTOSNIPER_MAX_CLIP ) //Can't reload if the magazine is full
			return;
		if( getPlayer().m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 ) //Can't reload if the reserve ammo is 0
			return;

		getPlayer().m_szAnimExtension = "mp5";
		getPlayer().pev.maxspeed = 0;
		BaseClass.Reload();
		getPlayer().pev.velocity = getPlayer().pev.velocity * 1 ;
		getPlayer().SetMaxSpeedOverride( -1 );
		g_iCurrentMode = 0;
		ToggleZoom( 0 );

		self.DefaultReload( AUTOSNIPER_MAX_CLIP, AUTOSNIPER_RELOAD, 0.9, 0 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		getPlayer().GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( getPlayer().random_seed,  0, 1 ) )
		{
		case 0:	
			iAnim = AUTOSNIPER_LONGIDLE;	
			break;
		
		case 1:
			iAnim = AUTOSNIPER_IDLE1;
			break;
			
		default:
			iAnim = AUTOSNIPER_LONGIDLE;
			break;
		}

		self.SendWeaponAnim( iAnim );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( getPlayer().random_seed,  15, 25 );// how long till we do this again.
	}
}

class ASAmmo : ScriptBasePlayerAmmoEntity // Nombre de la municion
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, AS_A_MODEL );
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( AS_A_MODEL );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		int iGive;

		iGive = AUTOSNIPER_AMMO_GIVE;

		if( pOther.GiveAmmo( iGive, "556", AUTOSNIPER_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetASNIPERName()
{
	return "weapon_asniper";
}

string GetASAmmoName() // Registrar la municion y su nombre
{
	return "ammo_as";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "AUTOSNIPER::weapon_asniper", GetASNIPERName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "AUTOSNIPER::ASAmmo", GetASAmmoName() ); // Register la municion como entidad
	g_ItemRegistry.RegisterWeapon( GetASNIPERName(), "expanded_arsenal", "556", "", GetASAmmoName() );
}

}