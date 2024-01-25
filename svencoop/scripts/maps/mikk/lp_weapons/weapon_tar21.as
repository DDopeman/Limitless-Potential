/* 	
*	AMX Mod X
*	Tavor Assault Rifle - 21.
*
* 	http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* 	This file is provided as is (no warranties)
*
*	Port by Gaftherman.
*/

// Weapon settings
string TAR21_NAME = "weapon_tar21";
string TAR21_PRIMARY_AMMO = "556";

int TAR21_PRIMARY_AMMO_MAX = 200;
int TAR21_SECONDARY_AMMO_MAX = -1;
int TAR21_DEFAULT_AMMO = 30;
int TAR21_MAX_CLIP = 30;
int TAR21_SLOT = 3;
int TAR21_POSITION = 5;
int TAR21_FLAGS = 0;
int TAR21_WEIGHT = 15;
int TAR21_DAMAGE = 15;

// Hud
string TAR21_NAME_SPR = "weapon_mod/weapon_tar21";
string TAR21_HUD_SPR = "sprites/weapon_mod/weapon_tar21/weapon_tar21.spr";
string TAR21_HUD_TXT = "sprites/weapon_mod/weapon_tar21/weapon_tar21.txt";

// Ammobox
string TAR21_AMMOBOX_CLASSNAME = "ammo_tar21clip";

// Models
string TAR_MODEL_WORLD = "models/weapon_mod/weapon_tar21/w_tar21_koshak.mdl";
string TAR_MODEL_VIEW = "models/weapon_mod/weapon_tar21/v_tar21_koshak_v2.mdl";
string TAR_MODEL_VIEW_SIGHT = "models/weapon_mod/weapon_tar21/v_tar21_sight_koshak.mdl";
string TAR_MODEL_PLAYER = "models/weapon_mod/weapon_tar21/p_tar21_koshak.mdl";
string TAR_MODEL_SHELL = "models/weapon_mod/weapon_tar21/shell_tar21.mdl";

// Sounds
string TAR_SOUND_SHOOT = "weapon_mod/weapon_tar21/tar21_shoot1.wav";
string TAR_SOUND_CLIP_IN = "weapon_mod/weapon_tar21/tar21_clipin.wav";
string TAR_SOUND_CLIP_OUT = "weapon_mod/weapon_tar21/tar21_clipout.wav";
string TAR_SOUND_BOLT_PULL = "weapon_mod/weapon_tar21/tar21_boltpull.wav";

// Animation
string TAR_ANIM_EXTENSION = "mp5";

enum tar21_e
{
	KOSHAK_HL = 0,
	
	ANIM_RELOAD,
	ANIM_RELOAD_2,
	ANIM_DRAW,
	
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_SHOOT_3,
	
	ANIM_FASTRUN_BEGIN,
	ANIM_FASTRUN_IDLE,
	ANIM_FASTRUN_END,
	
	ANIM_SIGHT_BEGIN,
	ANIM_SIGHT_END
};

class TAR21 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private int m_iShell;
    private int g_CvarMaxSpeed = int(g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ));
    private int MaxSpeed = g_CvarMaxSpeed - 20;

    //**********************************************
    //* Weapon spawn.                              *
    //**********************************************
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( TAR_MODEL_WORLD ) );

        self.m_iDefaultAmmo = TAR21_DEFAULT_AMMO;

        self.FallInit();// get ready to fall down.
    }

    //**********************************************
    //* Precache resources                         *
    //**********************************************
    void Precache()
    {
        m_iShell = g_Game.PrecacheModel(TAR_MODEL_SHELL);

        g_Game.PrecacheModel(TAR_MODEL_VIEW);
        g_Game.PrecacheModel(TAR_MODEL_WORLD);
        g_Game.PrecacheModel(TAR_MODEL_PLAYER);
        g_Game.PrecacheModel(TAR_MODEL_VIEW_SIGHT);
        
        g_SoundSystem.PrecacheSound(TAR_SOUND_SHOOT);
        g_SoundSystem.PrecacheSound(TAR_SOUND_CLIP_IN);
        g_SoundSystem.PrecacheSound(TAR_SOUND_CLIP_OUT);
        g_SoundSystem.PrecacheSound(TAR_SOUND_BOLT_PULL);
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        
        g_Game.PrecacheGeneric(TAR21_HUD_SPR);
        g_Game.PrecacheGeneric(TAR21_HUD_TXT);
    }

	float WeaponTimeBase() // map time
	{
		return g_Engine.time;
	}

    //**********************************************
    //* Register weapon.                           *
    //**********************************************
	bool GetItemInfo( ItemInfo& out info )
	{
        info.iMaxAmmo1  = TAR21_PRIMARY_AMMO_MAX;
		info.iAmmo1Drop = TAR21_MAX_CLIP;
		info.iMaxAmmo2	= TAR21_SECONDARY_AMMO_MAX;
		info.iAmmo2Drop	= TAR21_SECONDARY_AMMO_MAX;
        info.iMaxClip   = TAR21_MAX_CLIP;
        info.iSlot      = TAR21_SLOT;
        info.iPosition  = TAR21_POSITION;
        info.iFlags     = TAR21_FLAGS;
        info.iWeight    = TAR21_WEIGHT;

        return true;
    }

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
			
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		return true;
	}

    //**********************************************
    //* Deploys the weapon.                        *
    //**********************************************
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( TAR_MODEL_VIEW ), self.GetP_Model( TAR_MODEL_PLAYER ), ANIM_DRAW, TAR_ANIM_EXTENSION );
		
			float deployTime = 1.05;
            m_pPlayer.SetMaxSpeedOverride( -1 ); //m_pPlayer.pev.maxspeed = -1;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + deployTime;
			return bResult;
		}
	}
	

    //**********************************************
    //* Called when the weapon is holster.         *
    //**********************************************
    void Holster( int skiplocal /* = 0 */ )
    {
        if( self.m_fInZoom )
        {
            SecondaryAttack();
            m_pPlayer.SetMaxSpeedOverride( -1 ); //m_pPlayer.pev.maxspeed = -1;
        }

        SetThink( null );

	    // Cancel any reload in progress.
        self.m_fInReload = false;

		BaseClass.Holster( skiplocal );
    }

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}

		return false;
	}

    //**********************************************
    //* Displays the idle animation for the weapon.*
    //**********************************************
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

        self.SendWeaponAnim( KOSHAK_HL );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 ); // how long till we do this again.
    }

	void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float upScale, float rightScale )
	{
		Vector vecForward, vecRight, vecUp;

		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

		const float fR = Math.RandomFloat( 50, 70 );
		const float fU = Math.RandomFloat( 100, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}

    //**********************************************
    //* The main attack of a weapon is triggered.  *
    //**********************************************
    void PrimaryAttack()
    {
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}

        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        --self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( ANIM_SHOOT_1 + Math.RandomLong( 0, 2 ), 0, self.pev.body );

		Vector vecShellVelocity, vecShellOrigin;

		GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 16.0, -20.0, 6.0 );

		vecShellVelocity.y *= 1;

		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, TAR_SOUND_SHOOT , 1.0, ATTN_NORM, 0, PITCH_NORM );

        Vector vecSrc	 = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if(!self.m_fInZoom)
        {
		    m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 4, TAR21_DAMAGE );
            m_pPlayer.pev.punchangle.x = Math.RandomFloat( -0.5, 1.5 );
		    m_pPlayer.pev.punchangle.y = Math.RandomFloat( -0.25f, -0.15f );
        }
        else
        {
            m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 4, TAR21_DAMAGE );
            m_pPlayer.pev.punchangle.x = Math.RandomFloat( -0.5, 1 );
		    m_pPlayer.pev.punchangle.y = Math.RandomFloat( -0.15f, -0.1f );
        }

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.06;

		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.06;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 ); // how long till we do this again.

		TraceResult tr;

		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

        Vector vecDir;
        if(!self.m_fInZoom)
		    vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;
        else
            vecDir = vecAiming + x * g_vecZero.x * g_Engine.v_right + y * g_vecZero.y * g_Engine.v_up;

		Vector vecEnd = vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
			}
		}
    }

    //**********************************************
    //* Secondary attack of a weapon is triggered. *
    //**********************************************
    void SecondaryAttack()
    {
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.50;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.50;

		if( m_pPlayer.pev.fov != 0 )
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; 
            m_pPlayer.pev.viewmodel = TAR_MODEL_VIEW;
            m_pPlayer.SetMaxSpeedOverride( -1 ); //m_pPlayer.pev.maxspeed = -1;      
            SetThink( null );
		}
		else if( m_pPlayer.pev.fov != 49 )
		{
			self.m_fInZoom = true;
			SetThink( ThinkFunction( TAR_SightThink ) );
			self.pev.nextthink = WeaponTimeBase() + 0.35;
		}

        self.SendWeaponAnim( (self.m_fInZoom) ? ANIM_SIGHT_BEGIN : ANIM_SIGHT_END , 0, self.pev.body );
    }

    //**********************************************
    //* Enable sight.                              *
    //**********************************************
    void TAR_SightThink()
    {
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 49;
        m_pPlayer.pev.viewmodel = TAR_MODEL_VIEW_SIGHT;
        m_pPlayer.SetMaxSpeedOverride( MaxSpeed ); //m_pPlayer.pev.maxspeed = MaxSpeed;
    }

    //**********************************************
    //* Called when the weapon is reloaded.        *
    //**********************************************
	void Reload()
	{
        bool iResult;
        
		if( m_pPlayer.pev.fov != 0 && self.m_iClip < TAR21_MAX_CLIP)
		{
            SecondaryAttack();
            iResult = self.DefaultReload( TAR21_MAX_CLIP, ANIM_RELOAD_2, 3.48 );
		}
        else if( m_pPlayer.pev.fov != 49 && self.m_iClip < TAR21_MAX_CLIP)
		{
			self.m_fInZoom = false;
            iResult = self.DefaultReload( TAR21_MAX_CLIP, ANIM_RELOAD, 3.14 );
        }

        if ( iResult )
        {
            self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 ); // how long till we do this again.
        }

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
    }
}

void RegisterTar21()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "TAR21", TAR21_NAME );
	g_ItemRegistry.RegisterWeapon( TAR21_NAME, TAR21_NAME_SPR, TAR21_PRIMARY_AMMO, "", TAR21_AMMOBOX_CLASSNAME );
}