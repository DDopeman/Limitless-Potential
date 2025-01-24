/* env_healthbar v1.1
Custom entity to draw a health bar above a target entity
by Outerbeast

For usage instructions, refer to env_healthbar.fgd
*/
namespace HEALTHBAR
{

const string ENTITY_CLASSNAME = "env_healthbar";
const string strDefaultSpriteName = "sprites/misc/healthbar.spr";

bool blHealthBarEntityRegistered = false;
bool blEntityCreatedHookRegister = false;
bool blPlayerSpawnHookRegister = false;

enum healthbarsettings
{
    PLAYERS     = 1 << 0,
    MONSTERS    = 1 << 1,
    BREAKABLES  = 1 << 2
};

enum healthbarflags
{
    STAY_ON = 1 << 0,
};

enum followtype
{
    FOLLOW_ORIGIN = 0,
    USE_ATTACHMENT,
    FIXED_POS
};

const array<string> STR_EXCLUDED_NPCS = 
{
    "monster_generic",
    "monster_gman",
    "monster_furniture",
    "monster_snark",
    "monster_sqknest",
    "monster_rat",
    "monster_cockroach",
    "monster_leech",
    "monster_handgrenade",
    "monster_satchel",
    "monster_tripmine",
    "monster_turret",
    "monster_miniturret"
};

void RegisterHealthBarEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HEALTHBAR::env_healthbar", ENTITY_CLASSNAME );
    blHealthBarEntityRegistered = g_CustomEntityFuncs.IsCustomEntity( ENTITY_CLASSNAME );
}

void StartHealthBarMode(const uint iHealthBarSettings, const Vector vecOriginOffset, const float flScale, const float flDrawDistance, const uint iSpawnFlags)
{
    if( !blHealthBarEntityRegistered )
        return;

    if( FlagSet( iHealthBarSettings, PLAYERS ) && !blPlayerSpawnHookRegister )
        blPlayerSpawnHookRegister = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawned );

    CBaseEntity@ pExistingHealthBar, pMonsterEntity, pBreakableEntity;

    while( ( @pExistingHealthBar = g_EntityFuncs.FindEntityByClassname( pExistingHealthBar, ENTITY_CLASSNAME ) ) !is null )
        g_EntityFuncs.Remove( pExistingHealthBar );

    if( FlagSet( iHealthBarSettings, MONSTERS ) )
    {
        while( ( @pMonsterEntity = g_EntityFuncs.FindEntityByClassname( pMonsterEntity, "monster_*" ) ) !is null )
        {   
            if( pMonsterEntity is null || !pMonsterEntity.IsMonster() )
                continue;

            if( STR_EXCLUDED_NPCS.find( pMonsterEntity.GetClassname() ) >= 0 )
                continue;
    
            SpawnEnvHealthBar( EHandle( pMonsterEntity ) );
        }

        if( !blEntityCreatedHookRegister )
            blEntityCreatedHookRegister = g_Hooks.RegisterHook( Hooks::Game::EntityCreated, @EntityCreated ); // Accounting for npcs spawning in later during the level
    }

    if( FlagSet( iHealthBarSettings, BREAKABLES ) )
    {   
        while( ( @pBreakableEntity = g_EntityFuncs.FindEntityByClassname( pBreakableEntity, "func_*" ) ) !is null )
        {
            if( !pBreakableEntity.IsBreakable() )
                continue;

            if( !pBreakableEntity.pev.SpawnFlagBitSet( 32 ) || pBreakableEntity.pev.SpawnFlagBitSet( 1 ) )
                continue;

            SpawnEnvHealthBar( EHandle( pBreakableEntity ) );
        }
    }
}

HookReturnCode EntityCreated(CBaseEntity@ pEntity)
{
    if( pEntity !is null && pEntity.IsMonster() )
        g_Scheduler.SetTimeout( Schedulers(), "EntitySpawned", 0.05f, EHandle( pEntity ) );

    return HOOK_CONTINUE;
}
// workaround...
final class Schedulers
{
    private void EntitySpawned(EHandle hEntity)
    {
        NpcSpawned( null, hEntity.GetEntity() );
    }
}

void NpcSpawned(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster) // Trigger this from a squadmaker via "function_name"
{
    if( blHealthBarEntityRegistered && pMonster !is null )
        SpawnEnvHealthBar( EHandle( pMonster ) );
}

HookReturnCode PlayerSpawned(CBasePlayer@ pPlayer)
{
    if( pPlayer !is null )
        SpawnEnvHealthBar( EHandle( pPlayer ) );

    return HOOK_CONTINUE;
}
// Why is there no API method for this??
bool FlagSet( uint iTargetBits, uint iFlags )
{
    return ( ( iTargetBits & iFlags ) != 0 );
}

EHandle SpawnEnvHealthBar
(EHandle hTarget, 
string strSprite = strDefaultSpriteName, 
Vector vecOriginOffset = Vector( 0, 0, 16 ), 
Vector vecColor = g_vecZero, 
float flScale = 0.3f, 
float flDrawDistance = 12048,
uint iFollowType = 0,
uint iSpawnFlags = 0)
{
    if( !blHealthBarEntityRegistered || !hTarget ) 
       return EHandle( null );

    dictionary hlth =
    {
        { "sprite", strSprite },
        { "offset", vecOriginOffset.ToString() },
        { "rendercolor", vecColor.ToString() },
        { "scale", "" + flScale },
        { "distance", "" + flDrawDistance },
        { "followtype", "" + iFollowType },
        { "spawnflags", "" + iSpawnFlags }
    };

    CBaseEntity@ pEnvHealthBar = g_EntityFuncs.CreateEntity( ENTITY_CLASSNAME, hlth, false );

    if( pEnvHealthBar is null )
       return EHandle( null );

    @pEnvHealthBar.pev.owner = hTarget.GetEntity().edict();
    //g_Game.AlertMessage( at_notice, "target: " + pTarget.entindex() + "\n" );
    g_EntityFuncs.DispatchSpawn( pEnvHealthBar.edict() );

    if( g_EntityFuncs.IsValidEntity( pEnvHealthBar.edict() ) )
        return EHandle( pEnvHealthBar );
    else
        return EHandle( null );
}

class env_healthbar : ScriptBaseEntity
{
    private EHandle hTrackedEntity, hHealthBar;

    private string strSpriteName = strDefaultSpriteName;

    private bool m_blOnOffState, blFollowing = false;

    private uint iFollowType;

    private float m_flStartHealth;
    private float flDrawDistance = 12048;
    
    private Vector vecOffset = Vector( 0, 0, 16 );

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "sprite" ) 
        {
            strSpriteName = szValue;
            return true;
        }
        else if( szKey == "offset" ) 
        {
            g_Utility.StringToVector( vecOffset, szValue );
            return true;
        }
        else if( szKey == "distance" ) 
        {
            flDrawDistance = atof( szValue );
            return true;
        }
        else if( szKey == "followtype" ) 
        {
            iFollowType = atoui( szValue );
            return true;
        }
        else
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Precache()
    {
        BaseClass.Precache();
        g_Game.PrecacheModel( strSpriteName );
        g_Game.PrecacheGeneric( strSpriteName );
    }

    void Spawn()
    {
        self.Precache();
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        self.pev.scale      = self.pev.scale <= 0.0f ? 0.3f : self.pev.scale;
        self.pev.renderamt  = self.pev.renderamt <= 0.0f ? 255.0f : self.pev.renderamt;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        SetUse( UseFunction( this.TrackUse ) );
        SetThink( ThinkFunction( this.TrackEntity ) );
        //  Run automatically if this has no targetname.
        if( self.GetTargetname().IsEmpty() )
            self.Use( self, self, USE_ON );
    }

    void UpdateOnRemove()
    {
        if( hHealthBar )
        {   // Fadeout not working, unable to find reason why (proofreading wanted!)
            //cast<CSprite@>( hHealthBar.GetEntity() ).Expand( 0.0f, 0.1f );
            //hHealthBar.GetEntity().SUB_FadeOut();
            //hHealthBar.GetEntity().SUB_StartFadeOut();
            g_EntityFuncs.Remove( hHealthBar.GetEntity() );
        }

        BaseClass.UpdateOnRemove();
    }

    void TrackEntity()
    {
        CBaseEntity@ pTrackedEntity = hTrackedEntity.GetEntity();

        if( pTrackedEntity !is null && ( pTrackedEntity.IsPlayer() || pTrackedEntity.IsMonster() || pTrackedEntity.IsBreakable() ) )
        {
            if( !hHealthBar )
                hHealthBar = CreateHealthBar();

            if( hHealthBar )
            {
                CSprite@ pHealthBar = cast<CSprite@>( hHealthBar.GetEntity() );

                if( !pTrackedEntity.IsAlive() )
                {
                    if( pTrackedEntity.IsRevivable() )
                        Hide();
                    else
                    {
                        hHealthBar.GetEntity().pev.frame = 0.0f;
                        g_EntityFuncs.Remove( self );
                        return;
                    }
                }
                else// Save more cpu speed because we only need to adjust it when it's alive.
                {
                    // 1.0 = 100%
                    float flPercentHealth   = Math.min( 1.0f, GetHealth() / GetMaxHealth() );
                    float flCurrentFrame    = flPercentHealth * GetMaxFrame();

                    // Fix zero current frame if it's still alive.
                    if( floor( flCurrentFrame ) <= 0 && flPercentHealth > 0 )
                        flCurrentFrame = Math.min( 0, GetMaxFrame() );
                    // This is horribly wrong.
                    // From API doc: `Advances this sprite's frame by the given amount of frames.
                    //pHealthBar.Animate(iPercentHealth);

                    //  This is correct(?).
                    pHealthBar.pev.frame = flCurrentFrame;
                    pHealthBar.SetScale( self.pev.scale );

                    if( !blFollowing )
                    {
                        if( pTrackedEntity.IsBSPModel() )
                            g_EntityFuncs.SetOrigin( pHealthBar, pTrackedEntity.pev.absmin + ( pTrackedEntity.pev.size * 0.5 ) + Vector( 0, 0, pTrackedEntity.pev.absmax.z ) );
                        else
                        {
                            CBaseMonster@ pTemp = cast<CBaseMonster@>( pTrackedEntity );

                            switch( iFollowType )
                            {
                                case USE_ATTACHMENT:
                                    pHealthBar.SetAttachment( pTemp.edict(), cast<CBaseMonster@>( pTemp ).GetAttachmentCount() );
                                    blFollowing = true;
                                    break;

                                case FIXED_POS:
                                    g_EntityFuncs.SetOrigin( pHealthBar, self.GetOrigin() + vecOffset );
                                    blFollowing = true;
                                    break;

                                default:
                                    g_EntityFuncs.SetOrigin( pHealthBar, pTemp.GetOrigin() + pTemp.pev.view_ofs + vecOffset );
                                    blFollowing = false;
                                    break;
                            }
                        }
                    }
                }
            }
        }
        else
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        if( hHealthBar )
        {
            if( self.pev.SpawnFlagBitSet( STAY_ON ) )
                Show();
            else
                AimThink();
        }

        self.pev.nextthink = g_Engine.time + 0.01f;
    }
    // Trigger-able.
    void TrackUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
    {
        if( !self.ShouldToggle( useType, m_blOnOffState ) )
            return;

        m_blOnOffState = ( useType == USE_TOGGLE ? !m_blOnOffState : useType == USE_ON );

        if( !m_blOnOffState )
        {
            self.pev.nextthink = 0;
            Hide();
            return;
        }

        CBaseEntity@ pTrackedEntity;
        string strTarget = string( self.pev.target );
        strTarget.Trim();

        if( !strTarget.IsEmpty() && strTarget != self.GetTargetname() )
            @pTrackedEntity = g_EntityFuncs.FindEntityByTargetname( pTrackedEntity, strTarget );
        else
            @pTrackedEntity = g_EntityFuncs.Instance( self.pev.owner );

        if( pTrackedEntity !is null )
        {
            m_flStartHealth = pTrackedEntity.pev.health;
            hTrackedEntity = pTrackedEntity;
        }
        self.pev.nextthink = g_Engine.time + 0.01f;
    }

    void AimThink()
    {
        for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

            if( pPlayer is null || !pPlayer.IsAlive() )
                continue;
            // If a player is aiming at an npc, draw healthbar, else hide
            CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer, flDrawDistance );

            if( pAimedEntity is hTrackedEntity.GetEntity() )
                Show();
            else
                Hide();
        }
    }

    void Show()
    {
        if( !hHealthBar )
            return;
        
        hHealthBar.GetEntity().pev.renderamt = self.pev.renderamt;
    }

    void Hide()
    {
        if( !hHealthBar || self.pev.SpawnFlagBitSet( STAY_ON ) )
            return;
        
        hHealthBar.GetEntity().pev.renderamt = 0.0f;
    }

    EHandle CreateHealthBar()
    {
        if( !hTrackedEntity )
            return EHandle( null );

        CSprite@ pHealthBar = g_EntityFuncs.CreateSprite( strSpriteName, hTrackedEntity.GetEntity().GetOrigin(), false, 0.0f );
        pHealthBar.SetScale( self.pev.scale );
        pHealthBar.pev.rendermode = self.pev.rendermode == 0 ? 5 : self.pev.rendermode; // Using the enums here instead thows exception: "Can't implicitly convert from 'int' to 'RenderModes'" - wtf?
        pHealthBar.pev.renderamt = self.pev.renderamt;
        pHealthBar.pev.rendercolor = self.pev.rendercolor;
        pHealthBar.pev.nextthink = 0.0f;
        // `CSprite::Frames` is broken.
        //g_Game.AlertMessage( at_notice, "pHealthBar Frames(): " + pHealthBar.Frames() + "\n" );

        // Is this really necessary ???
        pHealthBar.pev.frame = GetMaxFrame();
        //g_Game.AlertMessage( at_notice, "env_healthbar GetMaxFrame(): " + GetMaxFrame() + "\n" );

        if( self.pev.SpawnFlagBitSet( STAY_ON ) )
            Show();

        return EHandle( pHealthBar );
    }

    float GetHealth()
    {
        if( hTrackedEntity ) return Math.clamp( 0, hTrackedEntity.GetEntity().pev.health, GetMaxHealth() );
            return 0;
    }

    float GetMaxHealth()
    {
        if( hTrackedEntity )
        {
            float flMaxHP = hTrackedEntity.GetEntity().pev.max_health;
            if( flMaxHP <= 0 ) flMaxHP = m_flStartHealth;
            if( flMaxHP <= 0 ) flMaxHP = 1; // "Divided by Zero" still haunts you...
            return flMaxHP;
        }
        return 1;
    }

    int GetMaxFrame()
    {
        // Zero is minimum.
        if( hHealthBar ) return Math.max( 0, g_EngineFuncs.ModelFrames( g_EngineFuncs.ModelIndex( hHealthBar.GetEntity().pev.model ) ) - 1 );
        return 0;
    }
}

}
/* Special thanks to:
- Cadaver: default sprite
- Snarkeh: original concept and implementation in Command&Conquer campaign
- Trempler: testing and feedback
- AnggaraNothing and H2 for scripting support 
*/
