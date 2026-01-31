namespace cso_vsk94
{

const bool USE_PENETRATION					= true;
const string CSOW_NAME						= "weapon_vsk94";
const string AMMO_TYPE						= "cso_9mm"; //adjustable

const int VSK94_SLOT					= 6;
const int VSK94_POSITION				= 17;
const int VSK94_WEIGHT					= 25;

const int CSOW_DEFAULT_GIVE				= 60;
const int CSOW_DEFAULT_AMMO             = 30;
const int CSOW_MAX_CLIP 				= 20;
const int CSOW_MAX_AMMO					= 720;
const int CSOW_TRACERFREQ				= 2;
const float CSOW_DAMAGE					= 21;
const float CSOW_TIME_DELAY1			= 0.125;
const float CSOW_TIME_DELAY2			= 0.6;
const float CSOW_TIME_DRAW				= 1.3;
const float CSOW_TIME_IDLE				= 60.0;
const float CSOW_TIME_RELOAD			= 3.5;
const float CSOW_SPREAD_JUMPING		= 0.185;
const float CSOW_SPREAD_RUNNING		= 0.025;
const float CSOW_SPREAD_WALKING		= 0.01;
const float CSOW_SPREAD_STANDING	= 0.001;
const float CSOW_SPREAD_DUCKING		= 0.0;
const float CSOW_RECOIL_X			= 2.0;
const float CSOW_RECOIL_Y			= 2.25;
const Vector CSOW_SHELL_ORIGIN		= Vector(20.0, 12.0, -4.0); //forward, right, up
const string CSOW_ANIMEXT					= "m16"; //rifle

const string MODEL_VIEW						= "models/cso_edit/v_vsk94.mdl";
const string MODEL_PLAYER					= "models/cso_edit/p_vsk94.mdl";
const string MODEL_WORLD					= "models/cso_edit/w_vsk94.mdl";
const string MODEL_SHELL					= "models/cso_edit/pshell.mdl";
const string MODEL_AMMO  					= "models/w_9mmarclip.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_ZOOM,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"cso_edit/zoom.wav",
	"cso_edit/vsk-1.wav",
	"cso_edit/vsk_draw.wav"
};

class weapon_vsk94 : CBaseCSOWeapon
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/cso_edit/weapon_vsk94.txt" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud25.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/sniper_scope.spr" );
	}

	bool GetItemInfo( ItemInfo& out info ) // Weapon information goes here
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO; //Maximum primary ammo
		info.iMaxAmmo2 	= -1; //Maximum secondary ammo
		info.iMaxClip 	= CSOW_MAX_CLIP; //Weapon's primary magazine
		info.iAmmo1Drop	= CSOW_MAX_CLIP; //How much ammo to drop
		info.iAmmo2Drop	= -1; //How much secondary ammo to drop
		info.iSlot   	= VSK94_SLOT; //Weapon's slot
		info.iPosition 	= VSK94_POSITION; //Weapon's position on the weapon bucket
		info.iFlags  	= 0; //Weapon's flags
		info.iWeight 	= VSK94_WEIGHT; //Weapon's weight
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName(CSOW_NAME) );
		m.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], VOL_NORM, ATTN_NORM );
		}

		return false;
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			ResetZoom();

		BaseClass.Holster( skiplocal );
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = g_Engine.time + (CSOW_TIME_DRAW - 0.4);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		self.SendWeaponAnim( ANIM_SHOOT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.4, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 1 : 1;
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_9MM, CSOW_TRACERFREQ, flDamage, 1.0, CSOF_ALWAYSDECAL );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false, true );

		self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1/2;

		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		m_pPlayer.pev.punchangle.x -= CSOW_RECOIL_X;
		//m_pPlayer.pev.punchangle.y -= CSOW_RECOIL_Y;
	}

	void SecondaryAttack()
	{
		switch( m_pPlayer.m_iFOV )
		{
			case 0: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40; m_pPlayer.m_szAnimExtension = "sniperscope"; break;
			case 40: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10; break;
			default: ResetZoom(); break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_ZOOM], 0.2, 2.4 );
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10;
			SecondaryAttack();
		}

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD + 0.5);

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( self.m_iClip > 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
			self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}

	void ResetZoom()
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		m_pPlayer.m_szAnimExtension = "sniper";
	}
}

// Ammo class
class VSK_MAG : ScriptBasePlayerAmmoEntity
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
	return "weapon_vsk94";
}

string GetAmmoName()
{
	return "ammo_vsk94";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_vsk94::weapon_vsk94", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_vsk94::VSK_MAG", GetAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "cso_edit", AMMO_TYPE, "", GetAmmoName() );
}

} //namespace cso_vsk94 END