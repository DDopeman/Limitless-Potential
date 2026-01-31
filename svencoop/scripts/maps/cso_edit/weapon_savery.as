namespace cso_savery
{

const int SAVERY_DEFAULT_GIVE			= 7;
const int SAVERY_MAX_AMMO				= 90;
const int SAVERY_MAX_CLIP 				= 7;
const float SAVERY_DAMAGE				= 50;
const float SAVERY_DELAY				= 0.1f;
const float SAVERY_TIME_RELOAD			= 3.0f;
const float SAVERY_TIME_IDLE			= 2.7f;
const float SAVERY_TIME_DRAW			= 1.03f;
const float SAVERY_TIME_FIRE_TO_IDLE	= 0.8f;
const float SAVERY_RECOIL_X				= Math.RandomFloat( -2, 2 );
const float SAVERY_RECOIL_Y				= 0;

const string MODEL_VIEW					= "models/cso_edit/v_savery.mdl";
const string MODEL_PLAYER				= "models/cso_edit/p_savery.mdl";
const string MODEL_WORLD				= "models/cso_edit/w_savery.mdl";
const string MODEL_SHELL				= "models/cso_edit/shell_savery.mdl";
const string MODEL_CLIP					= "models/cso_edit/clip_savery.mdl";
const string MODEL_AMMO					= "models/cso_edit/mag_ak47.mdl";
const string CSOW_ANIMEXT				= "sniper";

enum csow_e
{
	ANIM_IDLE1 = 0,
	ANIM_SHOOT1,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_IDLE = 1,
	SND_SHOOT,
	SND_ZOOM
};

const array<string> pCSOWSounds =
{
	"cso_edit/cs16/dryfire_rifle.wav", //only here for the precache
	"cso_edit/savery_idle.wav",
	"cso_edit/savery-1.wav",
	"cso_edit/zoom.wav",
	"cso_edit/savery_clipin.wav",
	"cso_edit/savery_clipout.wav",
	"cso_edit/savery_draw.wav"
};

class weapon_savery : CBaseCSOWeapon
{
	int m_iDroppedClip, m_iZoomMode;
	bool bIsFiring = false;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = SAVERY_DEFAULT_GIVE*4;
		m_iZoomMode = MODE_NOZOOM;
		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_SHELL );
		g_Game.PrecacheModel( MODEL_CLIP );
		g_Game.PrecacheModel( MODEL_AMMO );
		
		for( uint i = 0; i < cso::pSmokeSprites.length(); i++ )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );

		for( uint i = 0; i < pCSOWSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/cso_edit/weapon_savery.txt" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/640hud101.spr" );
		g_Game.PrecacheGeneric( "sprites/cso_edit/sniper_savery.spr" );

		g_Game.PrecacheGeneric( "sprites/cso_edit/scope_circle.tga" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SAVERY_MAX_AMMO;
		info.iMaxClip 	= SAVERY_MAX_CLIP;
		info.iSlot 		= cso::SAVERY_SLOT - 1;
		info.iPosition 	= cso::SAVERY_POSITION - 1;
		info.iWeight 	= cso::SAVERY_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage savery( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			savery.WriteLong( g_ItemRegistry.GetIdForName("weapon_savery") );
		savery.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( MODEL_VIEW ), self.GetP_Model( MODEL_PLAYER ), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + SAVERY_TIME_DRAW;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], 0.5f, ATTN_NORM );
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );
		self.m_fInReload = false;
		m_iZoomMode = MODE_NOZOOM;
		ToggleZoom( 0 );

		SetThink(null);

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		const array<Vector> g_vecShootCone =
		{
			Vector(VECTOR_CONE_8DEGREES),
			Vector(VECTOR_CONE_3DEGREES),
			Vector(VECTOR_CONE_1DEGREES),
			g_vecZero
		};

		int playerState = 0;//standing

		if( m_pPlayer.pev.flags & FL_DUCKING != 0 ) playerState++;
		if( m_iZoomMode == MODE_ZOOM1 ) playerState++;
		if( m_iZoomMode == MODE_ZOOM2 ) playerState += 2;

		Vector vecShootCone = g_vecShootCone[playerState];

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if(bIsFiring)
			return;
			
		if(!bIsFiring)
			bIsFiring = true;

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		self.SendWeaponAnim( ANIM_SHOOT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1, ATTN_NORM );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, SAVERY_DAMAGE );

		DoDecalGunshot( vecSrc, vecAiming, g_vecZero.x, g_vecZero.y, BULLET_PLAYER_MP5 );

		cso::DoGunSmoke( vecSrc + g_Engine.v_forward * 8 + g_Engine.v_up * -10, SMOKE_RIFLE );

		if( self.m_iClip == 0 and m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = SAVERY_RECOIL_X;
		m_pPlayer.pev.punchangle.y = SAVERY_RECOIL_Y;
		self.m_flNextPrimaryAttack = g_Engine.time + SAVERY_DELAY;
		self.m_flNextSecondaryAttack = g_Engine.time + SAVERY_DELAY/2;
		self.m_flTimeWeaponIdle = g_Engine.time + SAVERY_TIME_FIRE_TO_IDLE;
		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;
	}	

    void SecondaryAttack()
    {
        switch( m_iZoomMode )
        {
            case MODE_NOZOOM:
            {
                m_iZoomMode = MODE_ZOOM1;
                ToggleZoom( 30 );
                m_pPlayer.m_szAnimExtension = "sniperscope";
                break;
            }
        
            case MODE_ZOOM1:
            {
                m_iZoomMode = MODE_ZOOM2;
                ToggleZoom( 10 );
                m_pPlayer.m_szAnimExtension = "sniperscope";
                break;
            }
            
            case MODE_ZOOM2:
            {
                m_iZoomMode = MODE_NOZOOM;
                ToggleZoom( 0 );
                m_pPlayer.m_szAnimExtension = "sniper";
                break;
            }
        }

        g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_BODY, pCSOWSounds[SND_ZOOM], 1, ATTN_NORM );

        self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.3f;
    }

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 or self.m_iClip >= SAVERY_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		m_iZoomMode = MODE_NOZOOM;
		m_pPlayer.m_szAnimExtension = "sniper";
		ToggleZoom( 0 );

		self.DefaultReload( SAVERY_MAX_CLIP, ANIM_RELOAD, SAVERY_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + SAVERY_TIME_RELOAD;

		self.pev.nextthink = g_Engine.time + 0.5f;
		SetThink( ThinkFunction(EjectClipThink) );

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		
		if( m_iDroppedClip == 1)
			m_iDroppedClip = 0;

		bIsFiring = false;
		
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + SAVERY_TIME_IDLE;
	}

	void EjectClipThink()
	{
		ClipCasting( m_pPlayer.pev.origin );
	}
	
	void ClipCasting( Vector origin )
	{
		if( m_iDroppedClip == 1 )
			return;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		Vector vecShellVelocity, vecShellOrigin;

		for( uint i = 0; i <= 5; i++ )
		{
			CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 6, -5, 15, true, false );
			g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[1], g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHELL );
		}

		int lifetime = 69;
		
		NetworkMessage saveryclip( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
				saveryclip.WriteByte( TE_BREAKMODEL );
				saveryclip.WriteCoord( vecShellOrigin.x );
				saveryclip.WriteCoord( vecShellOrigin.y );
				saveryclip.WriteCoord( vecShellOrigin.z );
				saveryclip.WriteCoord( 0 );//size
				saveryclip.WriteCoord( 0 );//size
				saveryclip.WriteCoord( 0 );//size
				saveryclip.WriteCoord( 0 );//velocity
				saveryclip.WriteCoord( 0 );//velocity
				saveryclip.WriteCoord( 0 );//velocity
				saveryclip.WriteByte( 0 );//random velocity
				saveryclip.WriteShort( g_EngineFuncs.ModelIndex(MODEL_CLIP) );
				saveryclip.WriteByte( 1 );//count
				saveryclip.WriteByte( int(lifetime) );
				saveryclip.WriteByte( 2 );//flags
				/*flags
				1: glass bounce sound
				2: metallic bounce sound
				4: fleshy bounce sound
				8: wooden bounce sound
				16: smoketrails
				32: transparent models
				64: rock bounce sound
				*/
		saveryclip.End();

		m_iDroppedClip = 1;
	}

    void SetFOV( int fov )
    {
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
    }
    
    void ToggleZoom( int zoomedFOV )
    {
        if( self.m_fInZoom == true )
        {
            SetFOV( 0 );
			m_pPlayer.m_szAnimExtension = "sniperscope";
        }
        else if( self.m_fInZoom == false )
        {
            SetFOV( zoomedFOV );
			m_pPlayer.m_szAnimExtension = "sniper";
        }
    }
}

class ammo_cso_sniper2 : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 2.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = SAVERY_MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "cso_sniper2", SAVERY_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_savery::ammo_cso_sniper2", "ammo_cso_sniper2" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_savery::weapon_savery", "weapon_savery" );
	g_ItemRegistry.RegisterWeapon( "weapon_savery", "cso_edit", "cso_sniper2", "" , "ammo_cso_sniper2" );
	
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_savery END