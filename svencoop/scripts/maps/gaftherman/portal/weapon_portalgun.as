/*

    INSTALL:
    
#include "gaftherman/portal/weapon_portalgun"

void MapInit()
{
    RegisterPortalGun();
}

*/
CCVar g_TeleportMode ( "teleport_mode", 1, "Alguna descripción funny", ConCommandFlag::AdminOnly );
CCVar g_Texture ( "textures", "", "Restrict to textures. Use space to separate them.", ConCommandFlag::AdminOnly );
CCVar g_PassMonsterClip ( "pass_monster_clip", 0, "Allow monsterclip to disable portals.", ConCommandFlag::AdminOnly );

namespace PortalSounds
{
    const string portal_shot_blue = "portalgun/portalgun_shoot_blue1.wav";
    const string portal_shot_orange = "portalgun/portalgun_shoot_orange1.wav";

    const array<string> SoundOpen =
    {
        "portalgun/portal_open1.wav",
        "portalgun/portal_open2.wav",
        "portalgun/portal_open3.wav"
    };

    const array<string> SoundClose =
    {
        "portalgun/portal_close1.wav",
        "portalgun/portal_close2.wav"
    };

    const array<string> SoundEnter =
    {
        "portalgun/portal_enter1.wav",
        "portalgun/portal_enter2.wav"
    };

    const string SoundInvalid = "portalgun/portal_invalid_surface3.wav";
}

namespace PortalGrab
{
    EHandle GetEntity( CBasePlayer@ pPlayer, float fldist )
    {
        TraceResult tr;

        Vector forward = pPlayer.GetAutoaimVector(0.0f);
        Vector vecSrc = pPlayer.GetGunPosition();
        Vector vecEnd = vecSrc + forward * fldist;
        CBaseEntity@ pEntity = null;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );

        if( tr.pHit is null )
            @pEntity = FindEntityForward( tr.vecEndPos ).GetEntity();
        else
            @pEntity = g_EntityFuncs.Instance( tr.pHit );

        if( pEntity.IsPlayer() )
            return EHandle(null);

        CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();

        if( pEntity.IsBSPModel() && pEntity.pev.movetype == MOVETYPE_PUSHSTEP && pCustom.GetKeyvalue("$i_afbentgrab").GetInteger() == 0 )
        {
            @pEntity.pev.owner = pPlayer.edict();
            pCustom.SetKeyvalue("$i_afbentgrab", 1);
            return EHandle( pEntity );
        }

        return EHandle(null);
    }

    EHandle FindEntityForward( Vector vecEndPos ) //https://github.com/Rizulix/Random-Plugins/blob/5bddcda3e71208d820539a66c9f971309eb125f9/TripminePickUp.as#L71
    {
        CBaseEntity@[] pEnts( 64 );
		Vector vecMin = vecEndPos + Vector( -8, -8, -8 ), vecMax = vecEndPos + Vector( 8, 8, 8 );
		int iEntitiesInBox = g_EntityFuncs.EntitiesInBox( @pEnts, vecMin, vecMax, 0 );

		for( int i = 0; i < iEntitiesInBox; i++ )
		{
            if( pEnts[i] !is null && !pEnts[i].IsPlayer() && pEnts[i].pev.classname != "worldspawn" && pEnts[i].IsBSPModel() && pEnts[i].pev.movetype == MOVETYPE_PUSHSTEP )
            {
                return EHandle(pEnts[i]);
            }
        }   
        return EHandle(null);
    }
}

namespace PortalMisc
{
    void CreatePortal( CBaseEntity@ pOwner, Vector vPlaneNormal ,Vector vEnd, Vector vAngles, int skin, string Targetname )
    {
        CBaseEntity@ pFindOtherPortal = null;
        CBaseEntity@ CreatePortal = null;

        while( (@pFindOtherPortal = g_EntityFuncs.FindEntityByClassname( pFindOtherPortal, "portal" )) !is null )
        {
            if( pFindOtherPortal.pev.owner is pOwner.edict() && pFindOtherPortal.pev.skin == skin )
            {
                g_EntityFuncs.Remove( pFindOtherPortal );
                @CreatePortal = g_EntityFuncs.Create( "portal", vEnd, vAngles, false, pOwner.edict() );
                CreatePortal.pev.skin = skin;
                CreatePortal.pev.targetname = Targetname;
                portal@ pPortal = cast<portal@>(CastToScriptClass(CreatePortal));
                pPortal.vecEndPos = vPlaneNormal;
                VisiblePortal( cast<CBasePlayer@>(pOwner), pPortal.pev.targetname );
                return;
            }
        }

        @CreatePortal = g_EntityFuncs.Create( "portal", vEnd, vAngles, false, pOwner.edict() );
        CreatePortal.pev.skin = skin;
        CreatePortal.pev.targetname = Targetname;
        portal@ pPortal = cast<portal@>(CastToScriptClass(CreatePortal));
        pPortal.vecEndPos = vPlaneNormal;
        VisiblePortal( cast<CBasePlayer@>(pOwner), pPortal.pev.targetname );
    }

    void ParseAngle( CBaseEntity@ pEntity, Vector SelfAngles, Vector OtherPortalAngles ) //wip
    {
        Vector vAngles = pEntity.pev.angles = ( pEntity.IsPlayer() ) ? pEntity.pev.v_angle : pEntity.pev.angles;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( vAngles, vecForward, vecRight, vecUp );
        vAngles = vecForward;

        Vector vNormalIn = -SelfAngles;
        Vector vNormalOut = OtherPortalAngles;

        vAngles = vAngles - vNormalIn;
        vAngles = vAngles + vNormalOut;

        //vAngles.y = -vAngles.y;

        g_EngineFuncs.VecToAngles( vAngles, vAngles );

        pEntity.pev.angles = vAngles;
        pEntity.pev.fixangle = FAM_FORCEVIEWANGLES;

        vAngles = pEntity.pev.velocity;
        float fSpeed = vAngles.Length();
        vAngles = vAngles.Normalize();

        vAngles = vAngles - vNormalIn;
        vAngles = vAngles + vNormalOut;

        vAngles = vAngles.Normalize();
        vAngles = vAngles * fSpeed;
        pEntity.pev.velocity = vAngles;
    }

    bool ValidWall( Vector vOrigin, Vector vNormal, float width = 40.0, float height = 75.0 )
    {
        Vector vInvNormal = -vNormal;

        Vector vPoint = vOrigin + vNormal;

        Vector vNormalUp; g_EngineFuncs.VecToAngles( vNormal, vNormalUp );
        vNormalUp.x = -vNormalUp.x;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( vNormalUp, vecForward, vecRight, vecUp );

        Vector vNormalRight = vecRight;
        vNormalUp = vecUp;

        vNormalUp = vNormalUp * (height/2);
        vNormalRight = vNormalRight * (width/2); 

        Vector vPoint2;
        vPoint2 = vPoint + vNormalUp;
        vPoint2 = vPoint2 + vNormalRight;

        if( !TraceToWall( vPoint2, vInvNormal) )
            return false;
        
        vPoint2 = vPoint + vNormalUp;
        vPoint2 = vPoint2 - vNormalRight;

        if( !TraceToWall( vPoint2, vInvNormal ) )
            return false;

        vPoint2 = vPoint - vNormalUp;
        vPoint2 = vPoint2 - vNormalRight;

        if( !TraceToWall( vPoint2, vInvNormal ) )
            return false;

        vPoint2 = vPoint - vNormalUp;
        vPoint2 = vPoint2 + vNormalRight;

        if( !TraceToWall( vPoint2, vInvNormal ) )
            return false;

        return true;
    }

    bool TraceToWall( Vector vOrigin, Vector Vec )
    {
        Vector vOrigin2;
        vOrigin2 = vOrigin + Vec;
        vOrigin2 = vOrigin2 + Vec;

        TraceResult tr;
        g_Utility.TraceLine( vOrigin, vOrigin2, ignore_monsters, ignore_glass, null, tr );

        if( abs(tr.flFraction - 0.5) <= 0.02 )
            return true;
        
        return false;
    }  

    void VisiblePortal( CBasePlayer@ pPlayer, string Targetname )
    {
        CBaseEntity@ pFindPortal = g_EntityFuncs.FindEntityByTargetname( pFindPortal, Targetname + "_render" );

        if( pFindPortal is null )
        {
            CBaseEntity@ pShowMyPortals = g_EntityFuncs.Create( "env_render_individual", Vector(WORLD_BOUNDARY, WORLD_BOUNDARY, WORLD_BOUNDARY), g_vecZero, false );
            pShowMyPortals.pev.target = Targetname;
            pShowMyPortals.pev.targetname = Targetname + "_render";
            pShowMyPortals.pev.spawnflags = (64);
            pShowMyPortals.pev.rendermode = 5;
            pShowMyPortals.pev.renderamt = 255;

            CBaseEntity@ pActivateRender = g_EntityFuncs.FindEntityByTargetname( pActivateRender, Targetname + "_render" );
            pActivateRender.Use( pPlayer, pPlayer, USE_ON );
        }
        else
        {
            pFindPortal.Use( pPlayer, pPlayer, USE_ON );
        }
    }

    bool CheckPlace( Vector vOrigin, int skin, CBaseEntity@ pOwner )
    {
        CBaseEntity@ pOtherPortal = null;

        while( ( @pOtherPortal = g_EntityFuncs.FindEntityInSphere( pOtherPortal, vOrigin, 45, "portal", "classname" ) ) !is null )
        {
            CBaseEntity@ pPortalOwner = g_EntityFuncs.Instance( pOtherPortal.pev.owner );

            if( pPortalOwner is pOwner && pOtherPortal.pev.skin != skin )
            {
                return false;
            }
        }

        return true;
    }

    void CreateParticle( Vector start, int skin )
    {
        for( int i = 1; i < 6; i++ )
        {
            NetworkMessage particle(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                particle.WriteByte(TE_SPRITETRAIL);
                particle.WriteCoord(start.x);
                particle.WriteCoord(start.y);
                particle.WriteCoord(start.z);
                particle.WriteCoord(start.x);
                particle.WriteCoord(start.y);
                particle.WriteCoord(start.z + 10);
                particle.WriteShort(( skin == 0 ) ? g_EngineFuncs.ModelIndex("sprites/portalgun/nieb.spr") : g_EngineFuncs.ModelIndex("sprites/portalgun/pom.spr"));
                particle.WriteByte(2);
                particle.WriteByte(1);
                particle.WriteByte(1);
                particle.WriteByte(Math.RandomLong( 5, 10 ));
                particle.WriteByte(5);
            particle.End();
        }
    }

    void CreateLight( CBaseEntity@ pEntity, int skin )
    {
        NetworkMessage light( MSG_ALL, NetworkMessages::SVC_TEMPENTITY, null );
            light.WriteByte(TE_DLIGHT);
            light.WriteCoord(pEntity.pev.origin.x); // position
            light.WriteCoord(pEntity.pev.origin.y);
            light.WriteCoord(pEntity.pev.origin.z);
            light.WriteByte(14); // radius
            light.WriteByte( (skin == 0) ? 0 : 255 );
            light.WriteByte( (skin == 0) ? 0 : 165 );
            light.WriteByte( (skin == 0) ? 255 : 0);
            light.WriteByte(1); // Duration
            light.WriteByte(0); // decay rate
        light.End();
    }

    array<string> TextureList()
    {
        return g_Texture.GetString().Split(" ");
    }

    string GetTextureName( Vector vOrigin, Vector vEndOrigin )
    {
        return g_Utility.TraceTexture( null, vOrigin, vEndOrigin );
    }

    string SteamID( CBasePlayer@ pPlayer )
    {
        return g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    }
}

enum portalgun_e 
{
	PORTAL_GUN_IDLE = 0,
	PORTAL_GUN_SHOOT,
	PORTAL_GUN_SHOOT_FAIL,
	PORTAL_GUN_HOLSTER,
	PORTAL_GUN_LAST_PORTAL,
	PORTAL_GUN_CAN_SHOOT,
	PORTAL_GUN_GRABING,
	PORTAL_GUN_IDK,
	PORTAL_GUN_DRAW
};

class CGPortal : ScriptBasePlayerWeaponEntity
{
    EHandle m_pCurrentEntity;
    float m_flPickUpDelay = 0.0f;
    
	private CBasePlayer@ m_pPlayer
	{
		get const	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

    //**********************************************
    //* Weapon spawn.                              *
    //**********************************************
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/portalgun/w_portalgun.mdl" ) );

        self.m_iDefaultAmmo = -1;
        self.m_iClip = -1;

        self.FallInit();// get ready to fall down.
    }

    //**********************************************
    //* Precache resources.                        *
    //**********************************************
    void Precache()
    {
        g_Game.PrecacheModel( "models/portalgun/v_portalgun.mdl" );
        g_Game.PrecacheModel( "models/portalgun/p_portalgun.mdl" );
        g_Game.PrecacheModel( "models/portalgun/w_portalgun.mdl" );

        g_Game.PrecacheModel( "models/portalgun/portal.mdl" );

        g_Game.PrecacheModel( "sprites/portalgun/nieb.spr" );
        g_Game.PrecacheModel( "sprites/portalgun/pom.spr" );
		
		g_Game.PrecacheGeneric( "sprites/portalgun/weapon_portalgun.txt" );
        g_Game.PrecacheModel( "sprites/portalgun/portalgunxhair.spr" );
        g_Game.PrecacheModel( "sprites/portalgun/portalgunhud.spr" );
		
        g_Game.PrecacheModel( "sprites/white.spr" );
        g_Game.PrecacheModel( "sprites/smoke.spr" );

        for( uint i = 0; i < PortalSounds::SoundClose.length(); i++ )
        {
            g_SoundSystem.PrecacheSound( PortalSounds::SoundClose[i] );
            g_Game.PrecacheGeneric( "sound/" + PortalSounds::SoundClose[i] );
        }

        g_SoundSystem.PrecacheSound( PortalSounds::portal_shot_blue );
        g_Game.PrecacheGeneric( "sound/" + PortalSounds::portal_shot_blue );

        g_SoundSystem.PrecacheSound( PortalSounds::portal_shot_orange );
        g_Game.PrecacheGeneric( "sound/" + PortalSounds::portal_shot_orange );
    }

    //**********************************************
    //* Register weapon.                           *
    //**********************************************
	bool GetItemInfo( ItemInfo& out info )
	{
        info.iMaxAmmo1  = -1;
		info.iMaxAmmo2	= -1;
        info.iMaxClip   = WEAPON_NOCLIP;
        info.iSlot      = 0;
        info.iPosition  = 6;
        info.iFlags     = 0;
        info.iWeight    = 23;

        return true;
    }

    //**********************************************
    //* Add the weapon to the player.              *
    //**********************************************
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
        ResetKV();
        return self.DefaultDeploy( self.GetV_Model( "models/portalgun/v_portalgun.mdl" ), self.GetP_Model( "models/portalgun/p_portalgun.mdl" ), PORTAL_GUN_DRAW, "gauss" );
	}

    //**********************************************
    //* Holster the weapon                         *
    //**********************************************
    void Holster( int skipLocal = 0 )
    {
        ResetKV();
        BaseClass.Holster( skipLocal );
    }

    //**********************************************
    //* Left click attack of the weapon.           *
    //**********************************************
    void PrimaryAttack()
    {
        g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle );

        ShootPrePortal( m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 0 + g_Engine.v_right * 0 + g_Engine.v_up * 0, g_Engine.v_forward * 3500, 0 );

        g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, PortalSounds::portal_shot_blue, VOL_NORM, ATTN_NORM, 0, PITCH_NORM, m_pPlayer.entindex(), true, m_pPlayer.GetOrigin() );

        self.SendWeaponAnim( PORTAL_GUN_SHOOT, 0, 0 );

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.33;
    }

    //**********************************************
    //* Right click attack of the weapon.          *
    //**********************************************
    void SecondaryAttack()
    {
        g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle );

        ShootPrePortal( m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 0 + g_Engine.v_right * 0 + g_Engine.v_up * 0, g_Engine.v_forward * 3500, 1 );

        g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, PortalSounds::portal_shot_orange, VOL_NORM, ATTN_NORM, 0, PITCH_NORM, m_pPlayer.entindex(), true, m_pPlayer.GetOrigin() );

        self.SendWeaponAnim( PORTAL_GUN_SHOOT, 0, 0 );

        self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.33;
    }

    //**********************************************
    //* Middle click attack of the weapon.          *
    //**********************************************
    void TertiaryAttack()
    {
        CBaseEntity@ pFindPortals = null;
        while( (@pFindPortals = g_EntityFuncs.FindEntityByClassname( pFindPortals, "portal" )) !is null )
        {
            if( pFindPortals.pev.owner is m_pPlayer.edict() )
            {
                g_EntityFuncs.Remove( pFindPortals );
                self.SendWeaponAnim( PORTAL_GUN_SHOOT_FAIL, 0, 0 );
                g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_AUTO, PortalSounds::SoundClose[Math.RandomLong( 0, PortalSounds::SoundClose.length()-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM, m_pPlayer.entindex(), true, m_pPlayer.GetOrigin() );
            }
        }

        CBaseEntity@ pFindPrePortals = null;
        while( (@pFindPrePortals = g_EntityFuncs.FindEntityByClassname( pFindPrePortals, "pre_portal" )) !is null )
        {
            if( pFindPrePortals.pev.owner is m_pPlayer.edict() )
            {
                g_EntityFuncs.Remove( pFindPrePortals );
                self.SendWeaponAnim( PORTAL_GUN_SHOOT_FAIL, 0, 0 );
                g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_AUTO, PortalSounds::SoundClose[Math.RandomLong( 0, PortalSounds::SoundClose.length()-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM, m_pPlayer.entindex(), true, m_pPlayer.GetOrigin() );
            }
        }
    }

    void ItemPostFrame()
    {
        if( m_pCurrentEntity.GetEntity() !is null )
        {
            if( (m_pPlayer.pev.origin - m_pCurrentEntity.GetEntity().Center()).Length() <= 145 )
            {
                m_pCurrentEntity.GetEntity().pev.velocity = ((m_pPlayer.pev.origin - m_pCurrentEntity.GetEntity().Center()) + g_Engine.v_forward * 86) * 35;

                if( (m_pPlayer.m_afButtonReleased & IN_USE) != 0 && m_flPickUpDelay <= g_Engine.time )
                {
                    ResetKV();
                    m_flPickUpDelay = g_Engine.time + 0.5;
                }
            }
            else
            {
                ResetKV();
            }

        }
        else if( (m_pPlayer.m_afButtonReleased & IN_USE) != 0 && m_flPickUpDelay <= g_Engine.time )
        {
            m_pCurrentEntity = PortalGrab::GetEntity( m_pPlayer, 64 ).GetEntity();

            if( m_pCurrentEntity.GetEntity() !is null )
            {
                m_pCurrentEntity.GetEntity().pev.origin.y += 0.2f;
            }

            m_flPickUpDelay = g_Engine.time + 0.5;
        }

		BaseClass.ItemPostFrame();
	}

    void ResetKV()
    {
        if( m_pCurrentEntity.GetEntity() !is null )
        {
            CustomKeyvalues@ pCustom = m_pCurrentEntity.GetEntity().GetCustomKeyvalues();
            pCustom.SetKeyvalue("$i_afbentgrab", 0);
            m_pCurrentEntity.GetEntity().pev.velocity = m_pPlayer.pev.velocity;
            @m_pCurrentEntity.GetEntity().pev.owner = null;
            m_pCurrentEntity = null;
        }
    }
}

class portal : ScriptBaseEntity
{
	private CBaseEntity@ pMyOwner
	{
		get const { return g_EntityFuncs.Instance( self.pev.owner ); }
	}

    float DelayBeforeJoin = 0;
    Vector vecEndPos;

    void Spawn()
    {
        self.Precache();

        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_TRIGGER;

        self.pev.rendermode = 5;
        self.pev.renderamt = 20;

		g_EntityFuncs.SetModel( self, "models/portalgun/portal.mdl" );

        g_EntityFuncs.SetOrigin( self, self.pev.origin );
        g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -16 ), Vector( 16, 16, 16 ) );

        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( "models/portalgun/portal.mdl" );

        for( uint i = 0; i < PortalSounds::SoundEnter.length(); i++ )
        {
            g_SoundSystem.PrecacheSound( PortalSounds::SoundEnter[i] );
            g_Game.PrecacheGeneric( "sound/" + PortalSounds::SoundEnter[i] );
        }

        BaseClass.Precache();
    }

	void Touch( CBaseEntity@ pOther )
	{
        if( pOther is null )
            return;

        Teleport( pOther );

        BaseClass.Touch( pOther );
	}

    void Teleport( CBaseEntity@ pEntity )
    {
        CBaseEntity@ pEntityOwner = g_EntityFuncs.Instance( pEntity.pev.owner );

        if( pEntity.GetClassname() != "pre_portal" && ( pEntityOwner is pMyOwner || pMyOwner is pEntity  )  )
        {
            CBaseEntity@ pFindExitPortal = null;
            while( (@pFindExitPortal = g_EntityFuncs.FindEntityByClassname( pFindExitPortal, "portal" )) !is null )
            {
                if( g_EntityFuncs.Instance( pFindExitPortal.pev.owner ) is pMyOwner && pFindExitPortal.pev.skin != self.pev.skin && DelayBeforeJoin <= g_Engine.time )
                {
                    portal@ pFindExitPortalDelay = cast<portal@>( CastToScriptClass( pFindExitPortal ) );
                    pFindExitPortalDelay.DelayBeforeJoin = g_Engine.time + 0.3;
                    DelayBeforeJoin = g_Engine.time + 0.3;
			
                    if( pEntity.IsBSPModel() )
                    {                    
                        Vector pushMiddle = pEntity.pev.mins + (pEntity.pev.maxs - pEntity.pev.mins) / 2.0f;
                        Vector pushOri = pEntity.pev.origin + pushMiddle;       
                        Vector offset = pEntity.pev.origin - pushOri;

                        pEntity.pev.origin = pFindExitPortalDelay.VerifyDirection() + offset + Vector(0, 0, -18);

                        CBasePlayerItem@ pItem = cast<CBasePlayer@>(pEntityOwner).HasNamedPlayerItem( "weapon_portalgun" );

                        if( pItem !is null )
                        {
                            CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pItem);
                            CGPortal@ wPortal = cast<CGPortal@>(CastToScriptClass(pWeapon));
                            wPortal.ResetKV();
                        }

                        Math.MakeAimVectors( pFindExitPortal.pev.angles );
                        pEntity.pev.velocity = g_Engine.v_forward * 450;
                    }
                    else
                    {
                        g_EntityFuncs.SetOrigin( pEntity, pFindExitPortalDelay.VerifyDirection() );

                        if( g_TeleportMode.GetInt() == 0 )
                        {
                            PortalMisc::ParseAngle( pEntity, vecEndPos, pFindExitPortalDelay.vecEndPos );
                        }
                        else
                        {
                            pEntity.pev.angles = ( pEntity.IsPlayer() ) ? pEntity.pev.v_angle : pEntity.pev.angles;
                            pEntity.pev.angles.y = pFindExitPortal.pev.angles.y;
                            pEntity.pev.fixangle = FAM_FORCEVIEWANGLES;

                            Math.MakeAimVectors( pFindExitPortal.pev.angles );

                            if( pEntity.pev.velocity.Length() > 100 )
                                pEntity.pev.velocity = g_Engine.v_forward * pEntity.pev.velocity.Length() * 1.1;
                            else
                                pEntity.pev.velocity = g_Engine.v_forward * 150;
                        }
                    }
                    g_SoundSystem.PlaySound( pFindExitPortal.edict(), CHAN_AUTO, PortalSounds::SoundEnter[Math.RandomLong( 0, PortalSounds::SoundEnter.length()-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM, pMyOwner.entindex(), true, pFindExitPortal.GetOrigin() );
                }
            }
        }
    }

    Vector VerifyDirection()
    {
        Math.MakeAimVectors( self.pev.angles );

        TraceResult tr;
        g_Utility.TraceLine( self.pev.origin, self.pev.origin + g_Engine.v_forward * 38, ignore_monsters, self.edict(), tr );

        return tr.vecEndPos;
    }
}

class pre_portal : ScriptBaseEntity
{
	private CBaseEntity@ pMyOwner
	{
		get const { return g_EntityFuncs.Instance( self.pev.owner ); }
	}
    
	void Spawn()
	{
		Precache();
		
        self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
        self.pev.flags = (g_PassMonsterClip.GetInt() == 0) ? 0 : FL_MONSTERCLIP;

		self.pev.rendermode = 5;
		self.pev.renderamt = 255;

        if( self.pev.skin == 0 )
            g_EntityFuncs.SetModel( self, "sprites/portalgun/nieb.spr" );
        else
            g_EntityFuncs.SetModel( self, "sprites/portalgun/pom.spr" );

		g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );

        self.pev.nextthink = 0.1;

        BaseClass.Spawn();
	}

    void Precache()
    {
        g_Game.PrecacheModel( "models/rpgrocket.mdl" );

        for( uint i = 0; i < PortalSounds::SoundOpen.length(); i++ )
        {
            g_SoundSystem.PrecacheSound( PortalSounds::SoundOpen[i] );
            g_Game.PrecacheGeneric( "sound/" + PortalSounds::SoundOpen[i] );
        }
    }

    void Touch( CBaseEntity@ pOther )
    {
        if( pOther.pev.classname != "worldspawn" || g_EngineFuncs.PointContents(self.pev.origin) == CONTENTS_SKY )
        {
            PortalMisc::CreateParticle( self.pev.origin, self.pev.skin );
        }
        else
        {       
            Vector vOrigin = self.pev.origin;
            Vector vVelo = self.pev.velocity;
            Vector vEndOrigin;
            vVelo = vVelo * 50;
            vEndOrigin = vOrigin + vVelo;

            TraceResult tr;

            g_Utility.TraceLine( vOrigin, vEndOrigin, ignore_monsters, ignore_glass, pMyOwner.edict(), tr );

            //if( PortalMisc::ValidWall( tr.vecEndPos, tr.vecPlaneNormal ) && PortalMisc::CheckPlace( self.Center(), self.pev.skin, pMyOwner ) && PortalMisc::TextureList().find(PortalMisc::GetTextureName( vOrigin, vEndOrigin )) >= 0 ) 

            if( PortalMisc::ValidWall( tr.vecEndPos, tr.vecPlaneNormal ) && PortalMisc::CheckPlace( self.Center(), self.pev.skin, pMyOwner ) ) 
            {
                Vector angles;
                g_EngineFuncs.VecToAngles( tr.vecPlaneNormal, angles );

                PortalMisc::CreatePortal( pMyOwner, tr.vecPlaneNormal, tr.vecEndPos + tr.vecPlaneNormal, angles, self.pev.skin, PortalMisc::SteamID(cast<CBasePlayer@>(pMyOwner)) );
                
                g_SoundSystem.PlaySound( self.edict(), CHAN_AUTO, PortalSounds::SoundOpen[Math.RandomLong( 0, PortalSounds::SoundOpen.length()-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM, pMyOwner.entindex(), true, self.GetOrigin() );
            }
            else
            {
                PortalMisc::CreateParticle( tr.vecEndPos, self.pev.skin );
            }
        }
        g_EntityFuncs.Remove( self );
    }

/*
    void Think()
    {
		PortalMisc::CreateLight( self, self.pev.skin );

        self.pev.nextthink = g_Engine.time + 0.01;
    }
*/
}

pre_portal@ ShootPrePortal( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity, int skin )
{
    dictionary dSkin = { {"skin", "" + skin} };
    CBaseEntity@ pre_portal = g_EntityFuncs.CreateEntity( "pre_portal", dSkin,  false );
    pre_portal@ pPre_Portal = cast<pre_portal@>(CastToScriptClass(pre_portal));

	g_EntityFuncs.DispatchSpawn( pPre_Portal.self.edict() );	
	g_EntityFuncs.SetOrigin( pPre_Portal.self, vecStart );

	pPre_Portal.pev.velocity = vecVelocity;	
	pPre_Portal.pev.angles = Math.VecToAngles( pPre_Portal.pev.velocity );	
    pPre_Portal.pev.gravity = 0;

	@pPre_Portal.pev.owner = pevOwner.pContainingEntity;

    return pPre_Portal;
}

void RegisterPortalGun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CGPortal", "weapon_portalgun" );
	g_ItemRegistry.RegisterWeapon( "weapon_portalgun", "portalgun", "", "" );

	g_CustomEntityFuncs.RegisterCustomEntity( "portal", "portal" );
    g_Game.PrecacheOther( "portal" );

	g_CustomEntityFuncs.RegisterCustomEntity( "pre_portal", "pre_portal" );
    g_Game.PrecacheOther( "pre_portal" );
}