/**
 * file: CTriggerSound.as
 *
 * @author AnggaraNothing
 *
 * @brief A brush entity wrapper for `env_sound`.
 *
 * @date 2020-10-07
 *
 * Based on Admer456's Spirit of Half-Life 1.2.
 *
 * https://github.com/Admer456/halflife-vs2019-sohl12/blob/c82854db26091b86c1f8f6126ae56580e6c533fe/dlls/sound.cpp#L1093-L1165
 */


/**
 * namespace: TRIGGER_SOUND
 */
namespace TRIGGER_SOUND
{

/**
 * str: USERDATA_KEY
 * The entity userdata key for storing last sound entity.
 */
const string USERDATA_KEY   = "m_pentSndLast";

/**
 * str: CLASSNAME
 * The entity classname.
 */
const string CLASSNAME      = "trigger_sound";

/**
 * str: SCRIPTNAME
 * The entity script class name.
 */
const string SCRIPTNAME     = "TRIGGER_SOUND::CTriggerSound";

/**
 * int: RADIUS
 * Maximum radius of effect.
 */
const int RADIUS            = 2;

/**
 * class: CTriggerSound
 * A brush entity wrapper for `env_sound`.
 */
class CTriggerSound : ScriptBaseEntity /* Supposed to be CBaseDelay but it's not available. */
{

    /**
     * str: m_iszMaster
     * The trigger master name.
     */
    string  m_iszMaster();

    /**
     * obj: m_hSound
     * Entity handle for storing dummy `env_sound`.
     */
    EHandle m_hSound();

    /**
     * ptr: m_pSound
     * Property accessor for `m_hSound`.
     */
    CBaseEntity@ m_pSound
    {
        get const   { return m_hSound.GetEntity(); }
        set         { m_hSound = EHandle( @value ); }
    };

    /**
     * func: KeyValue
     *
     * @param szKeyName
     * @param szValue
     * @return true
     * @return false
     */
    bool KeyValue (const string& in szKeyName, const string& in szValue)
    {
        if (szKeyName == "roomtype")
        {
            self.pev.health = atof(szValue);
            return true;
        }
        else
        if (szKeyName == "master")
        {
            this.m_iszMaster = szValue;
            return true;
        }
        else
            return BaseClass.KeyValue( szKeyName, szValue );
    }

    /**
     * func: Touch
     *
     * @param pOther
     */
    void Touch (CBaseEntity@ pOther)
    {
        if (!m_iszMaster.IsEmpty() && !g_EntityFuncs.IsMasterTriggered( m_iszMaster, @pOther )) return;

        if (pOther.IsPlayer())
        {
            auto@ pPlayer = cast<CBasePlayer@>( @pOther );
            if (pPlayer is null) return;

            EHandle hLastSnd();
            pPlayer.GetUserData().get( USERDATA_KEY, hLastSnd );

            if (cast<CBaseEntity@>( hLastSnd ) !is self)
            {
                pPlayer.GetUserData().set( USERDATA_KEY, EHandle(self) );
                ApplyRoomSoundEffect( @pPlayer );
                /*pPlayer.m_pentSndLast = ENT(pev);
                pPlayer.m_flSndRoomtype = self.pev.health;
                pPlayer.m_flSndRange = 0;

                MESSAGE_BEGIN( MSG_ONE, SVC_ROOMTYPE, NULL, pPlayer.edict() );		// use the magic #1 for "one client"
                    WRITE_SHORT( (short)self.pev.health );					// sequence number
                MESSAGE_END();*/

                self.SUB_UseTargets( @pPlayer, USE_TOGGLE, 0 );
            }
        }
    }

    /**
     * func: Spawn
     */
    void Spawn ()
    {
        BaseClass.Spawn();

        self.pev.solid      = SOLID_TRIGGER;
        self.pev.movetype   = MOVETYPE_NONE;
        g_EntityFuncs.SetModel( self, self.pev.model ); // set size and link into world.
        self.pev.effects    |= EF_NODRAW;

        CreateSoundEntity();
    }

    /**
     * func: CreateSoundEntity
     * Create the dummy `env_sound`.
     */
    private void CreateSoundEntity ()
    {
        const Vector vecOrigin = self.pev.origin;
        @m_pSound = g_EntityFuncs.CreateEntity(
            "env_sound",
            {
                {"origin",          string(vecOrigin.x) + " " + string(vecOrigin.y) + " " + string(vecOrigin.z)}
                , {"roomtype",      string(int(self.pev.health))}
                , {"radius",        string(RADIUS)}
                , {"spawnflags",    "1"}
            },
            true
        );
    }

    /**
     * func: ApplyRoomSoundEffect
     * This is where the black magic happens.
     */
    private void ApplyRoomSoundEffect (CBasePlayer@ pPlayer)
    {
        if (pPlayer is null) return;
        if (m_pSound is null) return;

        // Correctly positioning based on these logic.
        // https://github.com/Admer456/halflife-vs2019-sohl12/blob/c82854db26091b86c1f8f6126ae56580e6c533fe/dlls/sound.cpp#L954-L955
        const Vector vecNewOrigin = (pPlayer.pev.origin + pPlayer.pev.view_ofs) - m_pSound.pev.view_ofs;
        g_EntityFuncs.SetOrigin( m_pSound, vecNewOrigin );

        // Calling `Think` should be enough, also don't forget to nullify nextthink to prevent thinking automatically.
        // https://github.com/Admer456/halflife-vs2019-sohl12/blob/c82854db26091b86c1f8f6126ae56580e6c533fe/dlls/sound.cpp#L992-L1080
        m_pSound.Think();
        m_pSound.pev.nextthink = 0.f;

        g_EntityFuncs.SetOrigin( m_pSound, self.pev.origin );
    }

}

}


/**
 * func: RegisterTriggerSoundEntity
 * Register the `trigger_sound` entity.
 */
void RegisterTriggerSoundEntity ()
{
    g_CustomEntityFuncs.RegisterCustomEntity( TRIGGER_SOUND::SCRIPTNAME, TRIGGER_SOUND::CLASSNAME );
}

