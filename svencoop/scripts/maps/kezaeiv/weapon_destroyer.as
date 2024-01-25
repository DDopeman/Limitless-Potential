const int SpawnAmmo = 10;
const int MaxAmmoCarry = 100;
const int MaxAmmoClip = WEAPON_NOCLIP;
const int Slot = 4;
const int Position = 11;
const int Weight = 20;

const float DeployTime = 0.20;
const string animation = "gauss"; // https://github.com/baso88/SC_AngelScript/wiki/Animation-Extensions

const int SubtractAmmo = 1; // per shoot
const int MaxDistanceShoot = 8192;
const int Damage = 1000;
const float DelayPerShoot = 1.2;

enum drestroyer_e
{
	DESTROYER_IDLE = 0,
	DESTROYER_IDLE2,
	DESTROYER_FIDGET,
	DESTROYER_SPINUP,
	DESTROYER_SPIN,
	DESTROYER_FIRE,
	DESTROYER_FIRE2,
	DESTROYER_HOLSTER,
	DESTROYER_DRAW
};

array<string> Models =
{
    "models/kezaeiv/custom_weapons/deic/p_destroyer.mdl", // Don't change this position
    "models/kezaeiv/custom_weapons/deic/w_destroyer.mdl", // Don't change this position
    "models/kezaeiv/custom_weapons/deic/v_destroyer.mdl" // Don't change this position
};

array<string> Sounds =
{
    "kezaeiv/c_wep/destr/rail.wav",
    "hl/weapons/357_cock1.wav"
};

class weapon_destroyer : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer
	{
		get const	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	CBeam@ m_pRailBeam, m_pRailBeam2;
	Vector railStart;
	TraceResult railtr;
	int railbr;

    //**********************************************
    //* Weapon spawn                               *
    //**********************************************
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( Models[1] ) );

        self.m_iDefaultAmmo = SpawnAmmo;

        self.FallInit();// get ready to fall down.
    }

    //**********************************************
    //* Precache resources                         *
    //**********************************************
	void Precache()
	{
        for( uint i = 0; i < Models.length(); ++i )
        {
		    g_Game.PrecacheModel( Models[i] );
            g_Game.PrecacheGeneric( Models[i] );
        }
        
        /*for( uint i = 0; i < Sounds.length(); ++i )
        {
            g_SoundSystem.PrecacheSound( Sounds[i] );
            g_Game.PrecacheGeneric( "sound/" + Sounds[i] );
        }*/
		
		g_SoundSystem.PrecacheSound( "kezaeiv/c_wep/destr/rail.wav" );
		g_Game.PrecacheGeneric( "kezaeiv/c_wep/destr/rail.wav" );
	}

    //**********************************************
    //* Register weapon                            *
    //**********************************************
	bool GetItemInfo( ItemInfo& out info )
	{
        info.iMaxAmmo1  = MaxAmmoCarry;
		info.iMaxAmmo2	= -1;
        info.iMaxClip   = MaxAmmoClip;
        info.iSlot      = Slot-1;
        info.iPosition  = Position;
        info.iFlags     = 0;
        info.iWeight    = Weight;

        return true;
    }

    //**********************************************
    //* Add the weapon to the player               *
    //**********************************************
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
			
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		@m_pRailBeam = null;
		@m_pRailBeam2 = null;

		return true;
	}

    //**********************************************
    //* Deploy the weapon                          *
    //**********************************************
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( Models[2] ), self.GetP_Model( Models[0] ), DESTROYER_DRAW, animation );
			float deployTime = 0.40f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + DeployTime;

			return bResult;
		}
	}

	
    //**********************************************
    //* Play empty sound                           *
    //**********************************************
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

    //**********************************************
    //* Holster the weapon                         *
    //**********************************************
	void Holster( int skiplocal /* = 0 */ )
	{
		m_pPlayer.m_flNextAttack = g_Engine.time + 0.5;
		
		self.SendWeaponAnim( DESTROYER_DRAW );
	}

    //**********************************************
    //* Left click attack of the weapon            *
    //**********************************************
	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == 3 )
		{
            self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < SubtractAmmo )
		{
            self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			return;
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
		    case 0: self.SendWeaponAnim( DESTROYER_FIRE, 0, 0 ); break;
            case 1: self.SendWeaponAnim( DESTROYER_FIRE2, 0, 0 ); break;
        }

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - SubtractAmmo );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "kezaeiv/c_wep/destr/rail.wav", 1, ATTN_NORM );
		
        Shoot();
		
        self.m_flNextPrimaryAttack = g_Engine.time + DelayPerShoot;
        self.m_flTimeWeaponIdle = g_Engine.time + 1.40;
    }

    void Shoot()
    {
		TraceResult tr;
		Vector vecStart = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 12 + g_Engine.v_right * 3 + g_Engine.v_up * -3.5f;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecEnd = vecStart + g_Engine.v_forward * MaxDistanceShoot;
		railStart = vecStart;
		
		edict_t@ ignore = m_pPlayer.edict();
		
		while( ignore !is null )
		{
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore, tr );

			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit.IsMonster() || pHit.IsPlayer() || tr.pHit.vars.solid == SOLID_BBOX || (tr.pHit.vars.ClassNameIs( "func_breakable" ) && tr.pHit.vars.takedamage != DAMAGE_NO) )
				@ignore = tr.pHit;
			else
				@ignore = null;

			g_WeaponFuncs.ClearMultiDamage();

			if( tr.pHit !is m_pPlayer.edict() && pHit.pev.takedamage != DAMAGE_NO )
				pHit.TraceAttack( m_pPlayer.pev, Damage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			vecStart = tr.vecEndPos;
		}

		railtr = tr;
		UpdateRailEffect();

		g_Scheduler.SetTimeout( @this, "DestroyRailEffect", 1.00f );

        if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null || pHit.IsBSPModel() == true )
			{
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SNIPER );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );

				NetworkMessage railimpact( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
					railimpact.WriteByte( TE_DLIGHT );
					railimpact.WriteCoord( tr.vecEndPos.x );
					railimpact.WriteCoord( tr.vecEndPos.y );
					railimpact.WriteCoord( tr.vecEndPos.z );
					railimpact.WriteByte( 5 );//radius
					railimpact.WriteByte( 155 );
					railimpact.WriteByte( 255 );
					railimpact.WriteByte( 255 );
					railimpact.WriteByte( 48 );//life
					railimpact.WriteByte( 12 );//decay
				railimpact.End();
            }
        }
    }

    //**********************************************
    //* Weapon idle animation                      *
    //**********************************************
	void WeaponIdle()
	{
		self.ResetEmptySound();

		if ( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
        int iAnim;
        float flRand = Math.RandomFloat( 0, 1 );
        
        if( flRand <= 0.5 )
        {
            iAnim = DESTROYER_IDLE;
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
        }
        else if( flRand <= 0.75 )
        {
            iAnim = DESTROYER_IDLE2;
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
        }
        else
        {
            iAnim = DESTROYER_FIDGET;
            self.m_flTimeWeaponIdle = g_Engine.time + 3;
        }
        self.SendWeaponAnim( iAnim );
	}

	void RailEffect()
	{
		DestroyRailEffect();

		@m_pRailBeam = @g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 30 );
		m_pRailBeam.pev.spawnflags |= SF_BEAM_TEMPORARY;
		//@m_pRailBeam.pev.owner = @m_pPlayer.edict();
		m_pRailBeam.SetEndAttachment( 1 );
		m_pRailBeam.SetScrollRate( 50 );
		m_pRailBeam.SetBrightness( 255 );
		m_pRailBeam.SetColor( 255, 0, 77 );
		m_pRailBeam.SetStartPos( railtr.vecEndPos );
		m_pRailBeam.SetEndPos( railStart );

		@m_pRailBeam2 = @g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 5 );
		m_pRailBeam2.SetFlags( BEAM_FSINE );
		m_pRailBeam2.pev.spawnflags |= SF_BEAM_TEMPORARY;
		//@m_pRailBeam2.pev.owner = @m_pPlayer.edict();
		m_pRailBeam2.SetEndAttachment( 1 );
		m_pRailBeam2.SetScrollRate( 85 );
		m_pRailBeam2.SetNoise( 20 );
		m_pRailBeam2.SetBrightness( 255 );
		m_pRailBeam2.SetColor( 0, 255, 120 );
		m_pRailBeam2.SetStartPos( railtr.vecEndPos );
		m_pRailBeam2.SetEndPos( railStart );

		railbr = 255;
	}

	void UpdateRailEffect()
	{
		if( m_pRailBeam is null ) RailEffect();

		m_pRailBeam.SetBrightness( railbr );
		m_pRailBeam2.SetBrightness( railbr );

		if( railbr > 0 )
			railbr -= 2;
	}

	void DestroyRailEffect()
	{
		if( m_pRailBeam is null ) return;

		g_EntityFuncs.Remove( m_pRailBeam );
		g_EntityFuncs.Remove( m_pRailBeam2 );
		@m_pRailBeam = null;
		@m_pRailBeam2 = null;
	}

	void ItemPreFrame()
	{
		if( m_pRailBeam !is null ) UpdateRailEffect();
		
		BaseClass.ItemPreFrame();
	}
}

void RegisterDestroyer()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_destroyer", "weapon_destroyer" );
	g_ItemRegistry.RegisterWeapon( "weapon_destroyer", "kezaeiv/c_wep", "kzwpns_ion_cell" );
}