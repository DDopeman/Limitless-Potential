enum M4Animation
{
	M4_IDLE = 0,
	M4_RELOAD,
	M4_DRAW,
	M4_SHOOT1,
	M4_SHOOT2,
	M4_SHOOT3
};

const int M4_DEFAULT_GIVE		= 30;
const int M4_MAX_CARRY			= 600;
const int M4_MAX_CLIP			= 30;
const int M4_WEIGHT			= 8;

class weapon_m4a1scope : ScriptBasePlayerWeaponEntity
{
	float m_flNextShellTime;
	int g_iCurrentMode;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/metalarena/weapons/w_m4a1scope.mdl" );
		
		self.m_iDefaultAmmo = M4_DEFAULT_GIVE;
		g_iCurrentMode = CS16_MODE_NOSCOPE;
		m_flNextShellTime = 0.0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/metalarena/weapons/v_m4a1scope.mdl" );
		g_Game.PrecacheModel( "models/metalarena/weapons/w_m4a1scope.mdl" );
		g_Game.PrecacheModel( "models/metalarena/weapons/p_m4a1scope.mdl" );
		
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/dryfire_rifle.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m4a1_unsil-1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m4a1_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m4a1_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m4a1_deploy.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/m4a1_boltpull.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/zoom.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/dryfire_rifle.wav" );
		g_SoundSystem.PrecacheSound( "weapons/m4a1_unsil-1.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/m4a1_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/m4a1_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/m4a1_deploy.wav" );
		g_SoundSystem.PrecacheSound( "weapons/m4a1_boltpull.wav" );
		g_SoundSystem.PrecacheSound( "weapons/zoom.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "wpnhuds/weapon_m4a1scope.spr");
		g_Game.PrecacheGeneric( "sprites/" + "wpnhuds/weapon_m4a1scope.spr");
		g_Game.PrecacheGeneric( "sprites/" + "wpn/weapon_m4a1scope.txt");
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= M4_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= M4_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 6;
		info.iFlags		= 0;
		info.iWeight	= M4_WEIGHT;
		
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
			
			g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "weapons/dryfire_rifle.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
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
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/metalarena/weapons/v_m4a1scope.mdl" ), self.GetP_Model( "models/metalarena/weapons/p_m4a1scope.mdl" ), M4_DRAW, "mp5" );
		
			float deployTime = 1;
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.08f;
		
		--self.m_iClip;
		
		getPlayer().pev.effects |= EF_MUZZLEFLASH;
		getPlayer().m_iWeaponVolume = LOUD_GUN_VOLUME;
		getPlayer().m_iWeaponFlash = BRIGHT_GUN_FLASH;
		getPlayer().SetAnimation( PLAYER_ATTACK1 );
		
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.08f;
		
		switch ( g_PlayerFuncs.SharedRandomLong( getPlayer().random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( M4_SHOOT1, 0, 0 ); break;
			case 1: self.SendWeaponAnim( M4_SHOOT2, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "weapons/m4a1_unsil-1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = getPlayer().GetGunPosition();
		Vector vecAiming = getPlayer().GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 20;
		
		if ( g_iCurrentMode == CS16_MODE_NOSCOPE )
		{
			getPlayer().FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_8DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
		}
		else
		{
			getPlayer().FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
		}

		if( self.m_iClip == 0 && getPlayer().m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			getPlayer().SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		getPlayer().pev.punchangle.x = Math.RandomLong( -2, -2 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.08f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.08f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir;
		
		if ( g_iCurrentMode == CS16_MODE_NOSCOPE )
		{
			vecDir = vecAiming + x * VECTOR_CONE_8DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_8DEGREES.y * g_Engine.v_up;
		}
		else
		{
			vecDir = vecAiming + x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;
		}

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, getPlayer().edict(), tr );

		SetThink( ThinkFunction( EjectBrassThink ) );
		self.pev.nextthink = WeaponTimeBase() + 0.68;
		
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
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3f;
		switch ( g_iCurrentMode )
		{
			case CS16_MODE_NOSCOPE:
			{
				g_iCurrentMode = CS16_MODE_SCOPED;
				getPlayer().pev.maxspeed = 150;
				ToggleZoom( 40 );
				getPlayer().m_szAnimExtension = "sniperscope";
				break;
			}
		
			case CS16_MODE_SCOPED:
			{
				g_iCurrentMode = CS16_MODE_MORESCOPE;
				getPlayer().pev.maxspeed = 150;
				ToggleZoom( 10 );
				getPlayer().m_szAnimExtension = "sniperscope";
				break;
			}
			
			case CS16_MODE_MORESCOPE:
			{
				g_iCurrentMode = CS16_MODE_NOSCOPE;
				getPlayer().pev.maxspeed = 0;
				ToggleZoom( 0 );
				getPlayer().m_szAnimExtension = "sniper";
				break;
			}
		}
		g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "weapons/zoom.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void Reload()
	{
		if( self.m_iClip == M4_MAX_CLIP ) //Can't reload if the magazine is 10
			return;
		if( getPlayer().m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 ) //Can't reload if the reserve ammo is 0
			return;

		getPlayer().m_szAnimExtension = "mp5";
		getPlayer().pev.maxspeed = 0;
		BaseClass.Reload();
		g_iCurrentMode = 0;
		ToggleZoom( 0 );

		self.DefaultReload( M4_MAX_CLIP, M4_RELOAD, 3.08, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		getPlayer().GetAutoaimVector( AUTOAIM_5DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( M4_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetM4Name()
{
	return "weapon_m4a1scope";
}

void RegisterM4()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetM4Name(), GetM4Name() );
	g_ItemRegistry.RegisterWeapon( GetM4Name(), "wpn", "ammo_45acp" );
}