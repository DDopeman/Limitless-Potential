namespace cso_xm8
{

const bool USE_CSLIKE_RECOIL						= false;
const bool USE_PENETRATION							= true;

const int CSOW_DEFAULT_GIVE						    = 60;
const int CSOW_MAX_CLIP 							= 30;
const int CSOW_MAX_AMMO							    = 720;
const int CSOW_TRACERFREQ							= 2;
const float CSOW_DAMAGE								= 32; //32-36
const float CSOW_TIME_DELAY1						= 0.0825;
const float CSOW_TIME_DELAY2						= 0.3;
const float CSOW_TIME_DELAY3						= 0.5;
const float CSOW_TIME_DELAY4						= 6.0; //switch RPM
const float CSOW_TIME_DRAW						= 0.75;
const float CSOW_TIME_IDLE							= 20.0;
const float CSOW_TIME_RELOAD					= 3.3;
const float CSOW_TIME_FIRE_TO_IDLE1		= 1.9;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.01785;
const float CSOW_SPREAD_WALKING				= 0.01785;
const float CSOW_SPREAD_STANDING			= 0.01718;
const float CSOW_SPREAD_DUCKING				= 0.01289;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_SHELL_ORIGIN				= Vector(17.0, 14.0, -8.0); //forward, right, up
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 22.414886, 5.827087, -2.659210 );

const string AMMO_TYPE                  = "cso_5.56nato";
const int XM8_SLOT                      = 5;
const int XM8_POSITION                  = 19;
const int XM8_WEIGHT                    = 25;

const string CSOW_ANIMEXT							= "m16";

const string MODEL_VIEW								= "models/cso_edit/v_xm8.mdl";
const string MODEL_PLAYER							= "models/cso_edit/p_xm8.mdl";
const string MODEL_WORLD							= "models/cso_edit/w_xm8.mdl";
const string MODEL_SHELL							= "models/cso_edit/pshell.mdl";
const string MODEL_AMMO                             = "models/w_9mmarclip.mdl";

const string XM8_CARBINE_SND                        = "cso_edit/xm8_carbine.wav";
const string XM8_SHARPSHOOTER_SND					= "cso_edit/xm8_shooter.wav";
const string XM8_DRYFIRE_SND                        = "custom_weapons/cs16/dryfire_rifle.wav";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_CHANGE_SHARPSHOOTER,
	ANIM_SHARPSHOOTER_IDLE,
	ANIM_SHARPSHOOTER_RELOAD,
	ANIM_SHARPSHOOTER_DRAW,
	ANIM_SHARPSHOOTER_SHOOT1,
	ANIM_SHARPSHOOTER_SHOOT2,
	ANIM_SHARPSHOOTER_SHOOT3,
	ANIM_CHANGE_CARBINE
};

enum csowmode_e
{
	MODE_GUN = 0,
	MODE_SHARPSHOOTER
};

class weapon_xm8 : CBaseCSOWeapon
{
	private float m_flAccuracy;
	private int m_iMode;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		m_flAccuracy = 0.2;
		m_iShotsFired = 0;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		m_iMode = MODE_GUN;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
        g_Game.PrecacheModel( MODEL_AMMO );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		g_Game.PrecacheGeneric( "sprites/cso_edit/weapon_xm8.txt" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud22.spr" );
		//g_Game.PrecacheGeneric( "sprites/cso_edit/640hud15.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/muzzleflash3.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_aug.txt" );

        g_SoundSystem.PrecacheSound( XM8_CARBINE_SND );
		g_SoundSystem.PrecacheSound( XM8_SHARPSHOOTER_SND );
        g_SoundSystem.PrecacheSound( XM8_DRYFIRE_SND );
	}

	bool GetItemInfo( ItemInfo& out info ) // Weapon information goes here
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO; //Maximum primary ammo
		info.iMaxAmmo2 	= -1; //Maximum secondary ammo
		info.iMaxClip 	= CSOW_MAX_CLIP; //Weapon's primary magazine
		info.iAmmo1Drop	= CSOW_MAX_CLIP; //How much ammo to drop
		info.iAmmo2Drop	= -1; //How much secondary ammo to drop
		info.iSlot   	= XM8_SLOT; //Weapon's slot
		info.iPosition 	= XM8_POSITION; //Weapon's position on the weapon bucket
		info.iFlags  	= 0; //Weapon's flags
		info.iWeight 	= XM8_WEIGHT; //Weapon's weight
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_xm8") );
		m.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, XM8_DRYFIRE_SND, VOL_NORM, ATTN_NORM );
		}

		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			m_flAccuracy = 0.2;
			m_iShotsFired = 0;

			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ( m_iMode == MODE_GUN ) ? ANIM_DRAW : ANIM_SHARPSHOOTER_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW*2);

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( m_iMode == MODE_GUN )
		{
			if( !USE_CSLIKE_RECOIL )
			{
				HandleAmmoReduction( 1 );

				m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
				m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
				m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH; //Needed??
				self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, XM8_CARBINE_SND, VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

				Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
				Vector vecSrc = m_pPlayer.GetGunPosition();
				Vector vecAiming = g_Engine.v_forward;

				int iPenetration = USE_PENETRATION ? 2 : 1;
				FireBullets3( vecSrc, g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_556MM, CSOW_TRACERFREQ, CSOW_DAMAGE, 1.0, 0, CSOW_OFFSETS_MUZZLE );

				EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

				HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

				if( m_pPlayer.pev.fov == 0 )
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
				}
				else
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.135;
				}

				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;
			}
			else
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
					XM8Fire( 0.035 + (0.4) * m_flAccuracy, CSOW_TIME_DELAY1 );
				else if( m_pPlayer.pev.velocity.Length2D() > 140 )
					XM8Fire( 0.035 + (0.07) * m_flAccuracy, CSOW_TIME_DELAY1 );
				else if( m_pPlayer.pev.fov == 0 )
					XM8Fire( (0.02) * m_flAccuracy, CSOW_TIME_DELAY1 );
				else
					XM8Fire( (0.02) * m_flAccuracy, 0.135 );
			}
		}
		else if( m_iMode == MODE_SHARPSHOOTER )
		{
			if( !USE_CSLIKE_RECOIL )
			{
				HandleAmmoReduction( 1 );

				m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
				m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
				m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH; //Needed??
				self.SendWeaponAnim( Math.RandomLong(ANIM_SHARPSHOOTER_SHOOT1, ANIM_SHARPSHOOTER_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, XM8_SHARPSHOOTER_SND, VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

				Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
				Vector vecSrc = m_pPlayer.GetGunPosition();
				Vector vecAiming = g_Engine.v_forward;

				int iPenetration = USE_PENETRATION ? 2 : 1;
				FireBullets3( vecSrc, g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_556MM, CSOW_TRACERFREQ, CSOW_DAMAGE, 1.0, 0, CSOW_OFFSETS_MUZZLE );

				EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

				HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

				if( m_pPlayer.pev.fov == 0 )
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY3;
				}
				else
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.4;
				}

				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;
			}
			else
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
					XM8Fire( 0.01 + (0.04) * m_flAccuracy, CSOW_TIME_DELAY3 );
				else if( m_pPlayer.pev.velocity.Length2D() > 140 )
					XM8Fire( 0.01 + (0.0) * m_flAccuracy, CSOW_TIME_DELAY3 );
				else if( m_pPlayer.pev.fov == 0 )
					XM8Fire( (0.01) * m_flAccuracy, CSOW_TIME_DELAY3 );
				else
					XM8Fire( (0.01) * m_flAccuracy, 0.01 );
			}
		}
	}

	void XM8Fire( float flSpread, float flCycleTime )
	{
		m_bDelayFire = true;
		m_iShotsFired++;
		m_flAccuracy = float((m_iShotsFired * m_iShotsFired * m_iShotsFired) / 215.0) + 0.3;

		if( m_flAccuracy > 1 )
			m_flAccuracy = 1;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		int iPenetration = USE_PENETRATION ? 2 : 0;
		FireBullets3( vecSrc, g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_556MM, CSOW_TRACERFREQ, CSOW_DAMAGE, 0.96 );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

		if( m_iMode == MODE_GUN )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, XM8_CARBINE_SND, VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );
		}
		else if( m_iMode == MODE_SHARPSHOOTER )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, XM8_SHARPSHOOTER_SND, VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 15 ) );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;

		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 1.0, 0.45, 0.275, 0.05, 4.0, 2.5, 7 );
		else if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			KickBack( 1.25, 0.45, 0.22, 0.18, 5.5, 4.0, 5 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			KickBack( 0.575, 0.325, 0.2, 0.011, 3.25, 2.0, 8 );
		else
			KickBack( 0.625, 0.375, 0.25, 0.0125, 3.5, 2.25, 8 );
	}

	void SecondaryAttack()
	{
		if( m_iMode == MODE_GUN)
		{
			if( m_pPlayer.m_iFOV != 0 )
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
			else
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40;
		}
		else if( m_iMode == MODE_SHARPSHOOTER )
		{
			if( m_pPlayer.m_iFOV != 0 )
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
			else
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 20;
		}

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void TertiaryAttack()
	{
		if( m_iMode == MODE_GUN )
		{
			m_iMode = MODE_SHARPSHOOTER;
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, " Switched to Sharpshooter Mode \n" );
			self.SendWeaponAnim( ANIM_CHANGE_SHARPSHOOTER, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
		else
		{
			m_iMode = MODE_GUN;
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, " Switched to Rifle Mode \n" );
			self.SendWeaponAnim( ANIM_CHANGE_CARBINE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY4;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY4 + 0.5;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		m_flAccuracy = 0;
		m_iShotsFired = 0;
		m_bDelayFire = false;

		self.DefaultReload( CSOW_MAX_CLIP, (m_iMode == MODE_GUN) ? ANIM_RELOAD : ANIM_SHARPSHOOTER_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
		self.SendWeaponAnim( (m_iMode == MODE_GUN) ? ANIM_IDLE : ANIM_SHARPSHOOTER_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
	}

	void ItemPostFrame()
	{
		if( m_pPlayer.pev.button & (IN_ATTACK | IN_ATTACK2) == 0 )
		{
			if( m_bDelayFire )
			{
				m_bDelayFire = false;

				if( m_iShotsFired > 15 )
					m_iShotsFired = 15;

				m_flDecreaseShotsFired = g_Engine.time + 0.4;
			}

			self.m_bFireOnEmpty = false;

			if( m_iShotsFired > 0 )
			{
				if( g_Engine.time > m_flDecreaseShotsFired )
				{
					m_iShotsFired--;
					m_flDecreaseShotsFired = g_Engine.time + 0.0225;
				}
			}

			WeaponIdle();
		}

		BaseClass.ItemPostFrame();
	}
}

// Ammo class
class XM8_MAG : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 1.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = CSOW_MAX_CLIP;

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
    return "weapon_xm8";
}

string GetAmmoName()
{
    return "ammo_xm8";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_xm8::weapon_xm8", GetName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "cso_xm8::XM8_MAG", GetAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "cso_edit", AMMO_TYPE, "", GetAmmoName() );
}

} //namespace cso_xm8 END