enum ETAnimation
{
	ET_IDLE = 0,
	ET_RELOAD,
	ET_DRAW,
	ET_SHOOT1,
	ET_SHOOT2,
	ET_SHOOT3
};

const int ET_DEFAULT_GIVE 	= 20;
const int ET_MAX_AMMO		= 300;
const int ET_MAX_CLIP 		= 100;
const int ET_WEIGHT 		= 8;

class weapon_ethereal : ScriptBasePlayerWeaponEntity
{
	float m_flNextAnimTime;
	int m_iShell;
	int m_gLaserSprite;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/metalarena/weapons/w_ethereal.mdl" );

		self.m_iDefaultAmmo = ET_DEFAULT_GIVE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/metalarena/weapons/v_ethereal_mg.mdl" );
		g_Game.PrecacheModel( "models/metalarena/weapons/w_ethereal.mdl" );
		g_Game.PrecacheModel( "models/metalarena/weapons/p_ethereal.mdl" );

		m_gLaserSprite = g_Game.PrecacheModel("sprites/laserbeam.spr");

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		g_Game.PrecacheModel( "models/w_9mmARclip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "weapons/ethereal-1.wav" );

		g_SoundSystem.PrecacheSound( "weapons/ethereal_draw.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ethereal_idle.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ethereal_reload.wav" );

		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
	}
	
	CBasePlayer@ getPlayer()
	{
		CBaseEntity@ e_plr = self.m_hPlayer;
		return cast<CBasePlayer@>(e_plr);
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= ET_MAX_AMMO;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= ET_MAX_CLIP;
		info.iSlot 		= 3;
		info.iPosition 	= 8;
		info.iFlags 	= 0;
		info.iWeight 	= ET_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();
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

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/metalarena/weapons/v_ethereal_mg.mdl" ), self.GetP_Model( "models/metalarena/weapons/p_ethereal.mdl" ), ET_DRAW, "mp5" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( getPlayer().pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.05;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.05;
			return;
		}

		getPlayer().m_iWeaponVolume = NORMAL_GUN_VOLUME;
		getPlayer().m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		self.SendWeaponAnim( ET_SHOOT1 );
		
		g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "weapons/ethereal-1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		getPlayer().SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = getPlayer().GetGunPosition();
		Vector vecAiming = getPlayer().GetAutoaimVector( AUTOAIM_5DEGREES );
		
		// JonnyBoy0719: Added custom bullet damage.
		int m_iBulletDamage = 20;
		// JonnyBoy0719: End
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		getPlayer().FireBullets( 4, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 1, m_iBulletDamage );

		if( self.m_iClip == 0 && getPlayer().m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			getPlayer().SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		getPlayer().pev.punchangle.x = Math.RandomLong( -2, 2 );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.08;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.08;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( getPlayer().random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, getPlayer().edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					switch( Math.RandomLong(0,1) )
					{
						case 0:
							g_Utility.Sparks(tr.vecEndPos);
							break;
						case 1:
							g_Utility.Sparks(tr.vecEndPos);
							break;
					}
				}
			}
		}
	}

	void Reload()
	{
		self.DefaultReload( ET_MAX_CLIP, ET_RELOAD, 3.15, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		getPlayer().GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( ET_IDLE );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( getPlayer().random_seed,  10, 15 );// how long till we do this again.
	}
}

string GetWeaponName_ET()
{
	return "weapon_ethereal";
}

void RegisterWeapon_ET()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_ethereal", GetWeaponName_ET() );
	g_ItemRegistry.RegisterWeapon( GetWeaponName_ET(), "wpn", "uranium" );
}
