// Counter-Strike: Online Sawed-off M79 Grenade Launcher
// Author: Nero0

namespace cso_m79
{

enum M7SW_GrenLauncher_Anims
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT_EMPTY,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_MOVE_GRENADE,
	ANIM_GRENADE_SHOOT,
	ANIM_GRENADE_SHOOT_LAST
};

enum csowsounds_e
{
	SND_SHOOT_GRENADE
};

// Models
const string W_MODEL  	= "models/cso_edit/w_m79.mdl";
const string V_MODEL  	= "models/cso_edit/v_m79.mdl";
const string P_MODEL  	= "models/cso_edit/p_m79.mdl";
const string A_MODEL  	= "models/cso_edit/shell_svdex2.mdl";
const string S_MODEL    = "models/cso_edit/shell_svdex.mdl";
// Sounds
const array<string> pCSOWSounds =
{
	"cso_edit/m79-1.wav",
	"cso_edit/m79_clipin.wav",
	"cso_edit/m79_clipon.wav",
	"cso_edit/m79_clipout.wav",
	"cso_edit/m79_draw.wav"
};
const string GRENADE_DRYFIRE_SND      = "cso_edit/dryfire_rifle.wav";
// Sprites
const string SPRITE_BEAM			= "sprites/laserbeam.spr";
const string SPRITE_EXPLOSION1		= "sprites/fexplo.spr";
const string SPRITE_SMOKE			= "sprites/steam1.spr";
const string SPRITE_MUZZLE_GRENADE	= "sprites/cso_edit/muzzleflash12.spr";
// Weapon's Information
const string AMMO_TYPE              = "cso_40mm"; // Adjustable
const int M79SW_SLOT                = 1;
const int M79SW_POSITION            = 17;
const int M79SW_WEIGHT				= 20;
const int M79SW_FLAGS               = 0;
const int CSOW_DEFAULT_GIVE         = 1;
const int CSOW_MAX_CLIP             = WEAPON_NOCLIP;
const int CSOW_MAX_AMMO             = 12;
// Weapon's Physics
const float CSOW_TIME_DELAY1        = 2.8;
const float CSOW_GRENADE_DAMAGE     = 185.0;
const float CSOW_GRENADE_RADIUS     = 200.0;
const float CSOW_GRENADE_VELOCITY	= 1000.0;
const Vector CSOW_SHELL_ORIGIN		= Vector( 20.0, 10.0, -4.0 ); //forward, right, up
const Vector CSOW_MUZZLE_ORIGIN		= Vector( 16.0, 4.0, -4.0 ); //forward, right, up

class weapon_csom79 : CBaseCSOWeapon
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );

		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		self.FallInit(); //get ready to fall
	}

	// Always precache the stuff you're going to use
	void Precache()
	{
		self.PrecacheCustomModels();
		//Models
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( A_MODEL );
        g_Game.PrecacheModel( S_MODEL );

		//Sounds
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		//Sprites
		g_Game.PrecacheGeneric( "sprites/cso_edit/weapon_csom79.txt" );
		g_Game.PrecacheModel( SPRITE_BEAM );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_MUZZLE_GRENADE );
	}

	bool GetItemInfo( ItemInfo& out info ) // Weapon information goes here
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO; //Maximum primary ammo
		info.iMaxAmmo2 	= -1; //Maximum secondary ammo
		info.iMaxClip 	= CSOW_MAX_CLIP; //Weapon's primary magazine
		info.iAmmo1Drop	= CSOW_DEFAULT_GIVE; //How much ammo to drop
		info.iAmmo2Drop	= -1; //How much secondary ammo to drop
		info.iSlot   	= M79SW_SLOT; //Weapon's slot
		info.iPosition 	= M79SW_POSITION; //Weapon's position on the weapon bucket
		info.iFlags  	= 0; //Weapon's flags
		info.iWeight 	= M79SW_WEIGHT; //Weapon's weight
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage csom79( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			csom79.WriteLong( g_ItemRegistry.GetIdForName("weapon_csom79") ); // A better way than using self.m_iId
		csom79.End();

		return true;
	}

/*
	// Better ammo extraction --- Anggara_nothing
	bool CanHaveDuplicates()
	{
		return true;
	}

	private int m_iAmmoSave;
*/
	bool Deploy()
	{
		//m_iAmmoSave = 0;

		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), ANIM_DRAW, "onehanded" );
		
			float deployTime = 0.6f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, GRENADE_DRYFIRE_SND, 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	void Holster( int skipLocal = 0 )
	{
		self.SendWeaponAnim( ANIM_DRAW, 0, 0 );
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.1;
			return;
		}
		
		HandleAmmoReduction( 0, 1, 0, 0 ); //HandleAmmoReduction( PrimaryClip, PrimaryAmmo, SecondaryClip, SecondaryAmmo );
		bool bHasAmmo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0;

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		//m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		int iAnim = bHasAmmo ? ANIM_GRENADE_SHOOT : ANIM_GRENADE_SHOOT_LAST;
		self.SendWeaponAnim( iAnim, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT_GRENADE], VOL_NORM, 0.4 );
		
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 4 + g_Engine.v_up * -2;
		
		LaunchGrenade();
			
		float flTime = bHasAmmo ? CSOW_TIME_DELAY1 : (CSOW_TIME_DELAY1 - 0.2);
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
		self.m_flTimeWeaponIdle = g_Engine.time + flTime + 0.5;
	}

	void LaunchGrenade()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0, -3.0);

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 4 + g_Engine.v_up * -2;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = 240.0 - vecAngles.x;

		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "csom79_rocket", vecOrigin, vecAngles, false, m_pPlayer.edict() ); 
		csom79_rocket@ pGrenade = cast<csom79_rocket@>(CastToScriptClass(cbeGrenade));
		pGrenade.pev.velocity = g_Engine.v_forward * CSOW_GRENADE_VELOCITY;

		DoMuzzleflash( SPRITE_MUZZLE_GRENADE, CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );
	}

	void WeaponIdle()
	{
        self.ResetEmptySound();
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class csom79_rocket : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, S_MODEL );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_TOSS;
		pev.solid = SOLID_BBOX;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMFOLLOW );
			m1.WriteShort( self.entindex() );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAM) );
			m1.WriteByte( 20 ); // life
			m1.WriteByte( 4 );  // width
			m1.WriteByte( 200 ); // r
			m1.WriteByte( 200 ); // g
			m1.WriteByte( 200 ); // b
			m1.WriteByte( 200 ); // brightness
		m1.End();

		SetThink( ThinkFunction(this.GrenadeThink) );
		SetTouch( TouchFunction(this.GrenadeTouch) );

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( SPRITE_BEAM );
	}

	void GrenadeThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity.Normalize() );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void GrenadeTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.classname == "csom79_rocket" )
			return;

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Explode();
	}

	void Explode()
	{
		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;

		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0, 1) );

		int sparkCount = Math.RandomLong(0, 3);
		for( int i = 0; i < sparkCount; i++ )
			g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

		tr = g_Utility.GetGlobalTrace();

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0f);

		Vector vecOrigin = pev.origin;

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION1) );
			m1.WriteByte( 20 ); // scale * 10
			m1.WriteByte( 30 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NONE );
		m1.End();

		float flDamage = CSOW_GRENADE_DAMAGE;
		float flRadius = CSOW_GRENADE_RADIUS;

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_MORTAR );

		pev.effects |= EF_NODRAW;
		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetTouch( null );

		SetThink( ThinkFunction(this.Smoke) );
		pev.nextthink = g_Engine.time + 0.5;
	}

	void Smoke()
	{
		NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			msg1.WriteByte( TE_SMOKE );
			msg1.WriteCoord( pev.origin.x );
			msg1.WriteCoord( pev.origin.y );
			msg1.WriteCoord( pev.origin.z );
			msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
			msg1.WriteByte( 40 ); // scale * 10
			msg1.WriteByte( 6 ); // framerate
		msg1.End();

		g_EntityFuncs.Remove( self );
	}
}

// Ammo class
class M79SWGL_MAG : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, A_MODEL );

		pev.scale = 2.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = CSOW_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, AMMO_TYPE, CSOW_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetName()
{
	return "weapon_csom79";
}

string GetAmmoName()
{
	return "ammo_csom79";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m79::csom79_rocket", "csom79_rocket" ); // Register grenade projectile entity
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m79::weapon_csom79", GetName() ); // Register the weapon entity
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m79::M79SWGL_MAG", GetAmmoName() ); // Register the ammo entity
    g_ItemRegistry.RegisterWeapon( GetName(), "cso_edit", AMMO_TYPE, "", GetAmmoName() ); // Register the weapon
	//g_ItemRegistry.RegisterWeapon( GetName(), "cso_edit", (CS16BASE::ShouldUseCustomAmmo) ? AMMO_TYPE : CS16BASE::DF_AMMO_ARGR, "", GetAmmoName() ); // Register the weapon
}

} // Namespace end