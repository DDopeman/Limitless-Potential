// CSO FG-Launcher
// Author: Nero0

namespace cso_fglauncher
{ // Namespace start

enum Fg_Launcher_Anims
{
	IDLE = 0,
	SHOOT,
	RELOAD,
	DRAW
};

// Models
const string W_MODEL = "models/cso_edit/w_fglauncher.mdl"; // World
const string V_MODEL = "models/cso_edit/v_fglauncher.mdl"; // View
const string P_MODEL = "models/cso_edit/p_fglauncher.mdl"; // Player
const string G_MODEL = "models/cso_edit/shell_svdex.mdl"; // Grenade
const string A_MODEL = "models/cso_edit/shell_svdex.mdl"; // Ammo
string AMMO_TYPE 	 = "cso_40mm";
// Sounds
const string GRENADE_SHOOT_SND   = "cso_edit/fglauncher-1.wav";
const string GRENADE_EXPLODE_SND = "cso_edit/firecracker_explode.wav";
const string GRENADE_WICK_SND    = "cso_edit/firecracker-wick.wav";
// Sprites
const string SPRITE_BEAM		    = "sprites/laserbeam.spr";
const string SPRITE_EXPLOSION1      = "sprites/cso_edit/fg_spark1.spr";
const string SPRITE_EXPLOSION2      = "sprites/cso_edit/fg_spark2.spr";
const string SPRITE_EXPLOSION3      = "sprites/cso_edit/fg_spark3.spr";
const string SPRITE_SMOKE			= "sprites/steam1.spr";
const string SPRITE_MUZZLE_GRENADE	= "sprites/cso_edit/muzzleflash12.spr";
// Weapon's Information
const int FGLAUNCHER_SLOT           = 4;
const int FGLAUNCHER_POSITION       = 20;
const int FGLAUNCHER_WEIGHT			= 20;
const int DEFAULT_GIVE 	            = 20;
const int MAX_CLIP  	            = 10;
const int MAX_CARRY 	            = 30;
// Weapon's Physics
const float CSOW_TIME_DELAY1 		= 0.7;
const float CSOW_GRENADE_DAMAGE     = 150.0;
const float CSOW_GRENADE_RADIUS     = 150.0;
//float CSOW_GRENADE_RADIUS           = Math.RandomFloat( 270.0, 350.0 );
const float CSOW_GRENADE_VELOCITY	= 1750.0;
const Vector CSOW_SHELL_ORIGIN		= Vector( 20.0, 10.0, -4.0 ); //forward, right, up
const Vector CSOW_MUZZLE_ORIGIN		= Vector( 16.0, 4.0, -4.0 ); //forward, right, up

class weapon_fglauncher : CBaseCSOWeapon
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

		self.m_iDefaultAmmo = DEFAULT_GIVE;

		self.FallInit(); //get ready to fall
	}

	// Always precache the stuff you're going to use
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( G_MODEL );

		// Precache here, because there's no late precache
		g_Game.PrecacheModel( A_MODEL );
		g_Game.PrecacheModel( SPRITE_BEAM );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
        g_Game.PrecacheModel( SPRITE_EXPLOSION2 );
        g_Game.PrecacheModel( SPRITE_EXPLOSION3 );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_MUZZLE_GRENADE );

		// Precaches the sound for the engine to use
		g_SoundSystem.PrecacheSound( GRENADE_SHOOT_SND );
        g_SoundSystem.PrecacheSound( GRENADE_EXPLODE_SND );
        g_SoundSystem.PrecacheSound( GRENADE_WICK_SND );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );

        // Precaches Generic items
        g_Game.PrecacheGeneric( "sprites/cso_edit/640hud7_2.spr" );
        g_Game.PrecacheGeneric( "sprites/cso_edit/640hud86_2.spr" );
        g_Game.PrecacheGeneric( "sprites/" + "cso_edit/weapon_fglauncher.txt" );
        g_Game.PrecacheGeneric( "sprites/cso_edit/scope_vip_grenade.spr" );
	}

	bool GetItemInfo( ItemInfo& out info ) // Weapon information goes here
	{
		info.iMaxAmmo1 	= MAX_CARRY; //Maximum primary ammo
		info.iMaxAmmo2 	= -1; //Maximum secondary ammo
		info.iMaxClip 	= MAX_CLIP; //Weapon's primary magazine
		info.iAmmo1Drop	= MAX_CLIP; //How much ammo to drop
		info.iAmmo2Drop	= -1; //How much secondary ammo to drop
		info.iSlot   	= FGLAUNCHER_SLOT; //Weapon's slot
		info.iPosition 	= FGLAUNCHER_POSITION; //Weapon's position on the weapon bucket
		info.iFlags  	= 0; //Weapon's flags
		info.iWeight 	= FGLAUNCHER_WEIGHT; //Weapon's weight
		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage fglauncher( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			fglauncher.WriteLong( g_ItemRegistry.GetIdForName("weapon_fglauncher") ); // A better way than using self.m_iId
		fglauncher.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "m16" );
		
			float deployTime = 1.25;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
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

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		self.SendWeaponAnim( DRAW, 0, 0 );
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		HandleAmmoReduction( 1 );
		bool bHasAmmo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0;

		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		//m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( SHOOT, 0, 0 );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, GRENADE_SHOOT_SND, VOL_NORM, 0.4 );
		
		LaunchGrenade();
			
		float flTime = bHasAmmo ? CSOW_TIME_DELAY1 : (CSOW_TIME_DELAY1 - 0.2);
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
		self.m_flTimeWeaponIdle = g_Engine.time + flTime + 0.5;
	}

	void LaunchGrenade()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0, -3.0);

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 2 + g_Engine.v_up * -6 + g_Engine.v_right * 8;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = 240.0 - vecAngles.x;

		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "fg_rocket", vecOrigin, vecAngles, false, m_pPlayer.edict() ); 
		fg_rocket@ pGrenade = cast<fg_rocket@>(CastToScriptClass(cbeGrenade));
		pGrenade.pev.velocity = g_Engine.v_forward * CSOW_GRENADE_VELOCITY;

		DoMuzzleflash( SPRITE_MUZZLE_GRENADE, CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );
	}

	void Reload()
	{
		// if the mag = the max mag, return
		if( self.m_iClip == MAX_CLIP )
			return;
		// if the reserve ammo pool = 0, return
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;
	
		self.DefaultReload( MAX_CLIP, RELOAD, 4.75, 0 );

		//Set 3rd person reloading animation -KernCore
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 6 ); // How much time to idle again
	}
}

class fg_rocket : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, G_MODEL );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_TOSS;
		pev.solid = SOLID_BBOX;

        g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, GRENADE_WICK_SND, VOL_NORM, ATTN_NORM );

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMFOLLOW );
			m1.WriteShort( self.entindex() );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAM) );
			m1.WriteByte( 20 ); // life
			m1.WriteByte( 4 );  // width
			m1.WriteByte( 255 ); // r
			m1.WriteByte( 127 ); // g
			m1.WriteByte( 127 ); // b
			m1.WriteByte( 200 ); // brightness
		m1.End();

		SetThink( ThinkFunction(this.GrenadeThink) );
		SetTouch( TouchFunction(this.GrenadeTouch) );

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( G_MODEL );
		g_Game.PrecacheModel( SPRITE_BEAM );
	}

	void GrenadeThink()
	{
        Vector vecOrigin = pev.origin;
        
        NetworkMessage s1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            s1.WriteByte( TE_SPARKS );
            s1.WriteCoord( vecOrigin.x );
            s1.WriteCoord( vecOrigin.y );
            s1.WriteCoord( vecOrigin.z );
		s1.End();

		pev.angles = Math.VecToAngles( pev.velocity.Normalize() );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void GrenadeTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.classname == "fg_rocket" )
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

        int iNum = Math.RandomLong( 1, 3 );
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/cso_edit/fg_spark" + string(iNum) + ".spr") );
			m1.WriteByte( Math.RandomLong( 15, 30 ) ); // scale * 10
			m1.WriteByte( 30 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NONE | TE_EXPLFLAG_NOSOUND );
		m1.End();

        NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_EXPLOSION );
			m2.WriteCoord( vecOrigin.x + 30.0f );
			m2.WriteCoord( vecOrigin.y + 10.0f );
			m2.WriteCoord( vecOrigin.z + 20.0f );
			m2.WriteShort( g_EngineFuncs.ModelIndex("sprites/cso_edit/fg_spark" + string(iNum) + ".spr") );
			m2.WriteByte( Math.RandomLong( 15, 30 ) ); // scale * 10
			m2.WriteByte( 30 ); // framerate
			m2.WriteByte( TE_EXPLFLAG_NONE | TE_EXPLFLAG_NOSOUND );
		m2.End();

        NetworkMessage m3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m3.WriteByte( TE_EXPLOSION );
			m3.WriteCoord( vecOrigin.x - 90.0f );
			m3.WriteCoord( vecOrigin.y - 30.0f );
			m3.WriteCoord( vecOrigin.z + 40.0f );
			m3.WriteShort( g_EngineFuncs.ModelIndex("sprites/cso_edit/fg_spark" + string(iNum) + ".spr") );
			m3.WriteByte( Math.RandomLong( 15, 30 ) ); // scale * 10
			m3.WriteByte( 30 ); // framerate
			m3.WriteByte( TE_EXPLFLAG_NONE | TE_EXPLFLAG_NOSOUND );
		m3.End();

		float flDamage = CSOW_GRENADE_DAMAGE;
		float flRadius = CSOW_GRENADE_RADIUS;

        // Play custom explosion sound
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, GRENADE_EXPLODE_SND, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_MORTAR );
        
        g_PlayerFuncs.ScreenShake( self.pev.origin, 80, 8, 5, flRadius ); // Target that received this damage will have heavy screenshake

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
class FGLauncherAmmo : ScriptBasePlayerAmmoEntity
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

		iGive = MAX_CLIP;

		if( pOther.GiveAmmo( iGive, AMMO_TYPE, MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetName()
{
	return "weapon_fglauncher";
}

string GetAmmoName()
{
	return "ammo_fglauncher";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_fglauncher::fg_rocket", "fg_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_fglauncher::weapon_fglauncher", GetName() ); // Register the weapon entity
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_fglauncher::FGLauncherAmmo", GetAmmoName() ); // Register the ammo entity
    g_ItemRegistry.RegisterWeapon( GetName(), "cso_edit", AMMO_TYPE, "", GetAmmoName() ); // Register the weapon
	//g_ItemRegistry.RegisterWeapon( GetName(), "cso_edit", (CS16BASE::ShouldUseCustomAmmo) ? AMMO_TYPE : CS16BASE::DF_AMMO_ARGR, "", GetAmmoName() ); // Register the weapon
}

} // Namespace end