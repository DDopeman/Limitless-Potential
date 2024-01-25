enum XM1014Animation

{

	XM1014_IDLE = 0,

	XM1014_SHOOT1,

	XM1014_SHOOT2,

	XM1014_INSERT,

	XM1014_AFTER_RELOAD,

	XM1014_START_RELOAD,

	XM1014_DRAW

};


const Vector VECTOR_CONE_DM_SHOTGUNNER( 0.07716, 0.04362, 0.00  );
		
// 10 degrees by 5 degrees

const int XM1014_DEFAULT_GIVE	= 7;

const int XM1014_MAX_CLIP   	= 7;

const int XM1014_WEIGHT     	= 20;


const uint SHOTGUN_SINGLE_PELLETCOUNTER = 8;


class weapon_xm1014 : ScriptBasePlayerWeaponEntity

{

	private CBasePlayer@ m_pPlayer = null;

	int m_iShell;

	float m_flPumpTime;

	float m_flNextReload;

	bool m_fPlayPumpSound;

	bool m_fShotgunReload;

	
	void Spawn()

	{

		Precache();

		g_EntityFuncs.SetModel( self, "models/cs16/xm1014/w_xm1014.mdl" );

		
self.m_iDefaultAmmo = XM1014_DEFAULT_GIVE;


		self.FallInit();

	}

	
	void Precache()

	{

		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/cs16/xm1014/v_xm1014.mdl" );

		g_Game.PrecacheModel( "models/cs16/xm1014/w_xm1014.mdl" );

		g_Game.PrecacheModel( "models/cs16/xm1014/p_xm1014.mdl" );
		//Precache the Sprites as well

		g_Game.PrecacheModel( "sprites/cs16/640hud7.spr" );

		g_Game.PrecacheModel( "sprites/cs16/640hud12.spr" );

		g_Game.PrecacheModel( "sprites/cs16/640hud13.spr" );


		m_iShell = g_Game.PrecacheModel( "models/hlclassic/shotgunshell.mdl" );


		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/dryfire_rifle.wav" );

		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/xm1014-1.wav" );

		g_Game.PrecacheGeneric( "sound/" + "weapons/cs16/de_deploy.wav" );

		g_Game.PrecacheGeneric( "sound/" + "hlclassic/weapons/reload3.wav" );

		g_Game.PrecacheGeneric( "sound/" + "hlclassic/weapons/reload1.wav" );

		
g_SoundSystem.PrecacheSound( "weapons/cs16/xm1014-1.wav" );

		g_SoundSystem.PrecacheSound( "weapons/cs16/de_deploy.wav" );

		g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload1.wav" );

		g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload3.wav" );

		g_SoundSystem.PrecacheSound( "weapons/cs16/dryfire_rifle.wav" );

		
		g_Game.PrecacheGeneric( "sprites/" + "cs16/640hud7.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "cs16/640hud12.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "cs16/640hud13.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "cs16/crosshairs.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "cs16/weapon_xm1014.txt" );

	}



	bool PlayEmptySound()

	{

		if( self.m_bPlayEmptySound )

		{

			self.m_bPlayEmptySound = false;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "weapons/cs16/dryfire_rifle.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );

		}

		
		return false;

	}

	
	bool AddToPlayer( CBasePlayer@ pPlayer )

	{

		if( BaseClass.AddToPlayer( pPlayer ) == true )

		{

			@m_pPlayer = pPlayer;

			NetworkMessage csautoshotty( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );

				csautoshotty.WriteLong( g_ItemRegistry.GetIdForName("weapon_xm1014") );

			csautoshotty.End();

			return true;

		}

		return false;

	}

	
	bool GetItemInfo( ItemInfo& out info )

	{

		info.iMaxAmmo1 	= 36;

		info.iMaxAmmo2 	= -1;

		info.iMaxClip 	= XM1014_MAX_CLIP;

		info.iSlot   	= 4;

		info.iPosition 	= 19;

		info.iFlags  	= 0;

		info.iWeight 	= XM1014_WEIGHT;


		return true;

	}

	
	bool Deploy()

	{

		bool bResult;

		{

			bResult = self.DefaultDeploy( self.GetV_Model( "models/cs16/xm1014/v_xm1014.mdl" ), self.GetP_Model( "models/cs16/xm1014/p_xm1014.mdl" ), XM1014_DRAW, "shotgun" );

			
			float deployTime = 0;

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;

			return bResult;

		}

	}

	
	float WeaponTimeBase()

	{

		return g_Engine.time;
	}


	void Holster( int skipLocal = 0 )

	{

		self.m_fInReload = false;

		m_fShotgunReload = false;

		BaseClass.Holster( skipLocal );

	}

	
	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )

	{
		TraceResult tr;

		
		float x, y;

		
		for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )

		{

			g_Utility.GetCircularGaussianSpread( x, y );

			
			Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;


			Vector vecEnd	= vecSrc + vecDir * 2048;

			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

			
			if( tr.flFraction < 1.0 )

			{

				if( tr.pHit !is null )

				{

					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					
					if( pHit is null || pHit.IsBSPModel() == true )

					{

						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );

					}

				}

			}

		}

	}

	
	void PrimaryAttack()

	{

		// don't fire underwater

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )

		{

			self.PlayEmptySound();

			self.m_flNextPrimaryAttack = g_Engine.time + 0.159;

			return;

		}

		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )

		{

			case 0: self.SendWeaponAnim( XM1014_SHOOT1, 0, 0 );
 break;

			case 1: self.SendWeaponAnim( XM1014_SHOOT2, 0, 0 );
 break;
		}

		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cs16/xm1014-1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );

	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

	
		--self.m_iClip;


		// player "shoot" animation

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );


		Vector vecSrc	 = m_pPlayer.GetGunPosition();

		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		
		// JonnyBoy0719: Added custom bullet damage.

		int m_iBulletDamage = 4;

		// JonnyBoy0719: End


		m_pPlayer.FireBullets( SHOTGUN_SINGLE_PELLETCOUNTER, vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUNNER, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );


		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )

			// HEV suit - indicate out of ammo condition

			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );


		if( self.m_iClip != 0 )

			m_flPumpTime = WeaponTimeBase() + 1;

			
		m_pPlayer.pev.punchangle.x = -5.0;


		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.40;

		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.3;


		if( self.m_iClip != 0 )

			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0;

		else

			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.21;


		m_fShotgunReload = false;

		m_fPlayPumpSound = true;

		
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUNNER, SHOTGUN_SINGLE_PELLETCOUNTER );

		
		Vector vecShellVelocity, vecShellOrigin;
 
      
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).

		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 19, 12, -7, true, false );
 
      
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
 
      
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHOTSHELL );

	}

	
	void Reload()
	{

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == XM1014_MAX_CLIP )

			return;


		if( m_flNextReload >  WeaponTimeBase() )

			return;


		// don't reload until recoil is done

		if( self.m_flNextPrimaryAttack > WeaponTimeBase() && !m_fShotgunReload )

			return;


		// check to see if we're ready to reload

		if( !m_fShotgunReload )

		{

			self.SendWeaponAnim( XM1014_START_RELOAD, 0, 0 );

			m_pPlayer.m_flNextAttack 	= 0.25;
	//Always uses a relative time due to prediction

			self.m_flTimeWeaponIdle
		= WeaponTimeBase() + 0.25;

			self.m_flNextPrimaryAttack 		= WeaponTimeBase() + 1.0;

			m_fShotgunReload = true;

			return;

		}

		else if( m_fShotgunReload )

		{

			if( self.m_flTimeWeaponIdle > WeaponTimeBase() )

				return;


			if( self.m_iClip == XM1014_MAX_CLIP )

			{
				m_fShotgunReload = false;
				return;
			}

			self.SendWeaponAnim( XM1014_INSERT, 0 );
			m_flNextReload 					= WeaponTimeBase() + 0.33;
			self.m_flNextPrimaryAttack 		= WeaponTimeBase() + 0.33;
			self.m_flTimeWeaponIdle 		= WeaponTimeBase() + 0.33;
				
			// Add them to the clip
			self.m_iClip += 1;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
			
			switch( Math.RandomLong( 0, 1 ) )
			{
			case 0:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/reload1.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/reload3.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			}
		}
		BaseClass.Reload();
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				self.Reload();
			}
			else if( m_fShotgunReload )
			{
				if( self.m_iClip != XM1014_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( XM1014_AFTER_RELOAD, 0, 0 );
					m_fShotgunReload = false;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
				}
			}
			else
			{
				int iAnim;
				float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
				if( flRand <= 0.8 )
				{
					iAnim = XM1014_IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time + (60.0/12.0);// * RANDOM_LONG(2, 5);
				}
			}
		}
	}
}

string GetXM1014Shotty()
{
	return "weapon_xm1014";
}

void RegisterXM1014Shotty()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetXM1014Shotty(), GetXM1014Shotty() );
	g_ItemRegistry.RegisterWeapon( GetXM1014Shotty(), "cs16", "buckshot" );
}