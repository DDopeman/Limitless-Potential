/**
 * Polar Rescue
 *
 * Stolen and re-factored by Adam "Adambean" Reece from Hezus' "SND" map
 * Based on original work by Hezus
 * Based on original work by Tomas "GeckoN" Slavotinek
 */

#include "point_checkpoint"



/**
 * Map initialisation handler.
 * @return void
 */
void MapInit()
{
    g_Module.ScriptInfo.SetAuthor("Adam \"Adambean\" Reece");
    g_Module.ScriptInfo.SetContactInfo("www.reece.wales");

    PolarRescue::MapInit();
}

/**
 * Map activation handler.
 * @return void
 */
void MapActivate()
{
    PolarRescue::MapActivate();
}

namespace PolarRescue
{
    /*
     * -------------------------------------------------------------------------
     * Constants & enumerators
     * -------------------------------------------------------------------------
     */

    /** @var bool Enable debug messages printed to console. */
    const bool DEBUG_MODE = true;

    /** @var int HUD channel used for the timer. */
    const int HUD_CHAN_TIMER = 0;

    /** @var int Objectives count, also maps to HUD channels for objective indicators. */
    const int OBJECTIVE_COUNT = 5;

    /** @var string Entity target name for objective tracker's status, must be a "info_target". */
    const string ENT_OBJECTIVE_STATUS = "objectives_status";

    /** @var string Entity target name for objective tracker's counter, must be a "game_counter". */
    const string ENT_OBJECTIVE_COUNTER = "objectives_counter";

    /** @var string[] Objective name keys. */
    const array<string> ENT_OBVECTIVE_KEYS = {
        "hostage_secure",
        "disarm_warheads",
        "collect_documents",
        "clear_landing_zone",
        "hostage_refuge",
    };



    /*
     * -------------------------------------------------------------------------
     * Globals
     * -------------------------------------------------------------------------
     */

    /** @global ALERT_TYPE g_uiAlertType Alert mode to use for debugging messages. */
    ALERT_TYPE g_uiAlertType = DEBUG_MODE ? at_console : at_aiconsole;



    /*
     * -------------------------------------------------------------------------
     * Life cycle functions
     * -------------------------------------------------------------------------
     */

    /**
     * Map initialisation handler.
     * @return void
     */
    void MapInit()
    {
        for (int i = 1; i <= OBJECTIVE_COUNT; i++) {
            string szSprite;
            snprintf(szSprite, "sprites/adamr/polar_rescue/objective%1.spr", i);
            g_Game.PrecacheModel(szSprite);
        }

        RegisterPointCheckPointEntity();
        g_SurvivalMode.EnableMapSupport();
    }

    /**
     * Map activation handler.
     * @return void
     */
    void MapActivate()
    {
        @g_pInstance = Map();

        if (!g_pInstance.Initialise()) {
            g_Game.AlertMessage(at_error, "[Polar Rescue] Map encountered errors initialising.\n");

            @g_pInstance = null;
            return;
        }

        g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @PolarRescue::ClientPutInServer);
    }



    /**
     * Polar Rescue map class.
     */
    final class Map
    {
        /*
         * -------------------------------------------------------------------------
         * Variables
         * -------------------------------------------------------------------------
         */

        /** @var CScheduledFunction@ m_pTimer Timer's scheduled function. */
        CScheduledFunction@ m_pTimer;

        /** @var bool m_fTimerRunning Timer's running state. */
        bool m_fTimerRunning;

        /** @var float m_flTimerCeiling Timer's time ceiling. (Start number.) */
        float m_flTimerCeiling;

        /** @var float m_flTimerRemaining Timer's time remaining. */
        float m_flTimerRemaining;

        /** @var float m_flTimerStartedAt Timer's started at time. */
        float m_flTimerStartedAt;

        /** @var CScheduledFunction@ m_pObjectives Objective tracker's scheduled function. */
        CScheduledFunction@ m_pObjectives;

        /** @var EHandle m_hObjectiveStatus Objective tracker status, must be a "info_target" */
        EHandle m_hObjectiveStatus;

        /** @var EHandle m_hObjectiveCounter Objective tracker counter, must be a "game_counter" */
        EHandle m_hObjectiveCounter;

        /** @var array<bool> m_fShowObjective Objective tracker visibility per objective */
        array<bool> m_fShowObjective(OBJECTIVE_COUNT, false);

        /** @var array<int> m_iObjective Objective tracker state per objective */
        array<int> m_iObjective(OBJECTIVE_COUNT, -1);

        /** @var array<int> m_iObjectiveLastSent Objective tracker last sent per objective */
        array<int> m_iObjectiveLastSent(OBJECTIVE_COUNT, -1);



        /*
         * -------------------------------------------------------------------------
         * Life cycle functions
         * -------------------------------------------------------------------------
         */

        /**
         * Constructor.
         */
        Map()
        {
            m_fTimerRunning     = false;
            m_flTimerCeiling    = 0.0f;
            m_flTimerRemaining  = 0.0f;
            m_flTimerStartedAt  = -1.0f;

            for (int i = 0; i < OBJECTIVE_COUNT; i++) {
                int iObjective = (i + 1);

                m_fShowObjective[i] = false;
                m_iObjective[i]     = 0;
            }
        }



        /*
         * -------------------------------------------------------------------------
         * Functions
         * -------------------------------------------------------------------------
         */

        /**
         * Initialise.
         * @return bool Success
         */
        bool Initialise()
        {
            uint uiErrors = 0;
            CBaseEntity@ pEntity;



            // Get status entity
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(null, ENT_OBJECTIVE_STATUS)) is null) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->Initialise(): Objectives status entity \"%1\" not found.\n", ENT_OBJECTIVE_STATUS);
                ++uiErrors;
            } else if (pEntity.pev.classname != "info_target") {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->Initialise(): Objectives status entity \"%1\" invalid. (Should be \"info_target\", actually a \"%2\".)\n", ENT_OBJECTIVE_STATUS, pEntity.pev.classname);
                ++uiErrors;
            } else {
                m_hObjectiveStatus = EHandle(pEntity);
            }

            // Get counter entity
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(null, ENT_OBJECTIVE_COUNTER)) is null) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->Initialise(): Objectives counter entity \"%1\" not found.\n", ENT_OBJECTIVE_COUNTER);
                ++uiErrors;
            } else if (pEntity.pev.classname != "game_counter") {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->Initialise(): Objectives counter entity \"%1\" invalid. (Should be \"game_counter\", actually a \"%2\".)\n", ENT_OBJECTIVE_COUNTER, pEntity.pev.classname);
                ++uiErrors;
            } else {
                m_hObjectiveCounter = EHandle(pEntity);
            }



            return (0 == uiErrors);
        }

        /**
         * Start the game.
         * @return void
         */
        void StartGame()
        {
            // Set-up schedules
            @m_pTimer       = g_Scheduler.SetInterval("RunTimer", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES);
            @m_pObjectives  = g_Scheduler.SetInterval("RunObjectives", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES);
        }

        /**
         * Run the timer.
         * @return void
         */
        void RunTimer()
        {
            if (m_fTimerRunning) {
                m_flTimerRemaining = m_flTimerCeiling - (g_Engine.time - m_flTimerStartedAt);
            }

            if (m_flTimerStartedAt >= 0.0f) {
                for (int p = 1; p <= g_Engine.maxClients; p++) {
                    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(p);
                    if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                        continue;
                    }

                    SendTimer(pPlayer);
                }
            }

            if (!m_fTimerRunning) {
                m_flTimerStartedAt = -1.0f;
            }
        }

        /**
         * Update timer.
         * @param  USE_TYPE useType New state (USE_ON: (re)start, USE_OFF: stop, USE_TOGGLE: (re)start/stop, USE_SET: set new time limit)
         * @param  float    flTime  New time limit (only for USE_SET)
         * @return void
         */
        void UpdateTimer(USE_TYPE useType, float flTime = -1.0f)
        {
            switch (useType) {
                case USE_ON:
                    m_fTimerRunning     = true;
                    m_flTimerRemaining  = m_flTimerCeiling;
                    m_flTimerStartedAt  = g_Engine.time;
                    break;

                case USE_OFF:
                    m_fTimerRunning     = false;
                    break;

                case USE_TOGGLE:
                    UpdateTimer(!m_fTimerRunning ? USE_ON : USE_OFF);
                    break;

                case USE_SET:
                    m_flTimerCeiling = Math.max(0.0f, flTime);
                    break;
            }
        }

        /**
         * Send timer state to player.
         * @param  CBasePlayer@ pPlayer Player entity
         * @return void
         */
        void SendTimer(CBasePlayer@ pPlayer)
        {
            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                g_Game.AlertMessage(
                    g_uiAlertType,
                    "PolarRescue::Map->SendTimer(): Skipping player \"%1\".\n",
                    g_Utility.GetPlayerLog(pPlayer.edict())
                );
                return;
            }

            g_Game.AlertMessage(
                g_uiAlertType,
                "PolarRescue::Map->SendTimer(): Sending timer to player \"%1\" in %2 state, %3 second(s) remaining.\n",
                g_Utility.GetPlayerLog(pPlayer.edict()),
                m_fTimerRunning ? "on" : "off",
                formatFloat(m_flTimerRemaining)
            );

            if (m_fTimerRunning) {
                HUDNumDisplayParams sHudTimer;

                sHudTimer.channel       = HUD_CHAN_TIMER;
                sHudTimer.flags         = HUD_ELEM_SCR_CENTER_X|HUD_ELEM_DEFAULT_ALPHA|HUD_TIME_MINUTES|HUD_TIME_SECONDS|HUD_TIME_COUNT_DOWN;
                sHudTimer.value         = m_flTimerRemaining;
                sHudTimer.x             = 0;
                sHudTimer.y             = 0.06;
                sHudTimer.color1        = RGBA_SVENCOOP;
                sHudTimer.spritename    = "stopwatch";

                if (m_flTimerRemaining <= 60.0f) {
                    sHudTimer.flags |= HUD_TIME_MILLISECONDS;
                    sHudTimer.color1 = RGBA_RED;
                }

                g_PlayerFuncs.HudTimeDisplay(null, sHudTimer);
            } else {
                g_PlayerFuncs.HudToggleElement(null, HUD_CHAN_TIMER, false);
            }
        }

        /**
         * Run the objectives.
         * @return void
         */
        void RunObjectives()
        {
            if (m_hObjectiveCounter.IsValid()) {
                UpdateObjectives();
            }

            for (int i = 0; i < OBJECTIVE_COUNT; i++) {
                int iObjective = (i + 1);

                if (m_fShowObjective[i]) {
                    if (m_iObjectiveLastSent[i] != m_iObjective[i]) {
                        g_Game.AlertMessage(
                            g_uiAlertType,
                            "PolarRescue::Map->RunObjectives(): Objective %1 (%2) changed (was %3 now %4), sending.\n",
                            iObjective,
                            ENT_OBVECTIVE_KEYS[i],
                            m_iObjectiveLastSent[i] >= 1 ? "complete" : "incomplete",
                            m_iObjective[i] >= 1 ? "complete" : "incomplete"
                        );

                        for (int p = 1; p <= g_Engine.maxClients; p++) {
                            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(p);
                            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                                continue;
                            }

                            SendObjective(pPlayer, iObjective);
                        }
                        m_iObjectiveLastSent[i] = m_iObjective[i];
                    }
                }
            }
        }

        /**
         * Update objectives.
         * @param  int|null iObjective Objective number, or 0 for all
         * @return void
         */
        void UpdateObjectives(int iObjective = 0)
        {
            if (iObjective < 0 || iObjective > OBJECTIVE_COUNT) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->UpdateObjectives(): Objective %1 out of bounds.\n", iObjective);
                return;
            }

            if (!m_hObjectiveCounter.IsValid()) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->UpdateObjectives(): Objectives counter not defined.\n");
                return;
            }

            CBaseEntity@ pObjectiveCounter = m_hObjectiveCounter.GetEntity();
            if (pObjectiveCounter.pev.frags >= pObjectiveCounter.pev.health) {
                return;
            }

            if (iObjective >= 1) {
                UpdateObjective(iObjective);
            } else {
                // g_Game.AlertMessage(g_uiAlertType, "PolarRescue::Map->UpdateObjectives(): Updating all objectives...\n");
                for (int i = 0; i < OBJECTIVE_COUNT; i++) {
                    UpdateObjective(i + 1);
                }
            }

            pObjectiveCounter.pev.frags = 0;
            for (int i = 0; i < OBJECTIVE_COUNT; i++) {
                if (m_iObjective[i] >= 1) {
                    pObjectiveCounter.Use(pObjectiveCounter, pObjectiveCounter, USE_ON);
                }
            }
            g_Game.AlertMessage(
                g_uiAlertType,
                "PolarRescue::Map->UpdateObjectives(): %1/%2 objectives completed.\n",
                pObjectiveCounter.pev.frags,
                pObjectiveCounter.pev.health
            );

            if (pObjectiveCounter.pev.frags >= pObjectiveCounter.pev.health) {
                g_Game.AlertMessage(g_uiAlertType, "PolarRescue::Map->UpdateObjectives(): All objectives completed.\n");
            }
        }

        /**
         * Update objective.
         * @param  int  iObjective Objective number
         * @return void
         */
        void UpdateObjective(int iObjective)
        {
            if (iObjective < 1 || iObjective > OBJECTIVE_COUNT) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->UpdateObjective(): Objective %1 out of bounds.\n", iObjective);
                return;
            }

            if (!m_hObjectiveStatus.IsValid()) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->UpdateObjective(): Objectives status not defined.\n");
                return;
            }

            CBaseEntity@        pObjectiveStatus        = m_hObjectiveStatus.GetEntity();
            CustomKeyvalues@    pObjectiveStatusExtra   = pObjectiveStatus.GetCustomKeyvalues();

            int i = (iObjective - 1);
            string szObjectiveKey;
            snprintf(szObjectiveKey, "$i_%1", ENT_OBVECTIVE_KEYS[i]);

            /*
            g_Game.AlertMessage(
                g_uiAlertType,
                "PolarRescue::Map->UpdateObjective(): Updating objective %1 (%2)...\n",
                iObjective,
                ENT_OBVECTIVE_KEYS[i]
            );
             */

            if (pObjectiveStatusExtra.HasKeyvalue(szObjectiveKey) && pObjectiveStatusExtra.GetKeyvalue(szObjectiveKey).Exists()) {
                m_iObjective[i] = pObjectiveStatusExtra.GetKeyvalue(szObjectiveKey).GetInteger();
                g_Game.AlertMessage(
                    g_uiAlertType,
                    "PolarRescue::Map->UpdateObjective(): Objective %1 (%2) is %3.\n",
                    iObjective,
                    ENT_OBVECTIVE_KEYS[i],
                    m_iObjective[i] >= 1 ? "complete" : "incomplete"
                );
            } else {
                g_Game.AlertMessage(
                    at_warning,
                    "PolarRescue::Map->UpdateObjective(): Objective %1 (%2) key not found in objectives status.\n",
                    iObjective,
                    ENT_OBVECTIVE_KEYS[i]
                );
            }
        }

        /**
         * Send objective state to player.
         * @param  CBasePlayer@ pPlayer    Player entity
         * @param  int          iObjective Objective number
         * @return void
         */
        void SendObjective(CBasePlayer@ pPlayer, int iObjective)
        {
            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                g_Game.AlertMessage(g_uiAlertType, "PolarRescue::Map->SendObjective(): Skipping player \"%1\".\n", g_Utility.GetPlayerLog(pPlayer.edict()));
                return;
            }

            if (iObjective < 1 || iObjective > OBJECTIVE_COUNT) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->SendObjective(): Objective %1 out of bounds.\n", iObjective);
                return;
            }

            int i = (iObjective - 1);
            g_Game.AlertMessage(g_uiAlertType, "PolarRescue::Map->SendObjective(): Sending player \"%1\" objective %2 (%3) in state %4.\n", g_Utility.GetPlayerLog(pPlayer.edict()), iObjective, ENT_OBVECTIVE_KEYS[i], m_iObjective[i]);

            m_fShowObjective[i] = true;

            HUDSpriteParams sHudSprite;

            sHudSprite.channel      = iObjective;
            sHudSprite.flags        = HUD_ELEM_SCR_CENTER_X|HUD_ELEM_DEFAULT_ALPHA;
            sHudSprite.x            = 1;
            sHudSprite.y            = 0.3 + (i * 0.1);
            sHudSprite.spritename   = "";
            snprintf(sHudSprite.spritename, "adamr/polar_rescue/objective%1.spr", (i + 1));

            switch (m_iObjective[i]) {
                case -1:
                    sHudSprite.color1 = RGBA_WHITE;
                    break;

                case 0:
                    sHudSprite.color1 = RGBA_RED;
                    break;

                case 1:
                    sHudSprite.color1 = RGBA_SVENCOOP;
                    break;

                default:
                    sHudSprite.color1 = RGBA_BLACK;
            }

            g_PlayerFuncs.HudCustomSprite(pPlayer, sHudSprite);
        }

        /**
         * Toggle objective display.
         * @param  int  iObjective Objective number
         * @param  bool fVisible   Visible or not
         * @return void
         */
        void ToggleObjectiveDisplay(int iObjective, bool fVisible)
        {
            if (iObjective < 1 || iObjective > OBJECTIVE_COUNT) {
                g_Game.AlertMessage(at_error, "PolarRescue::Map->ToggleObjectiveDisplay(): Objective %1 out of bounds.\n", iObjective);
                return;
            }

            int i = (iObjective - 1);

            m_fShowObjective[i] = fVisible;

            if (m_fShowObjective[i]) {
                SendObjective(null, i);
            } else {
                g_PlayerFuncs.HudToggleElement(null, iObjective, false);
            }
        }
    }

    Map@ g_pInstance;



    /*
     * -------------------------------------------------------------------------
     * Event hooks
     * -------------------------------------------------------------------------
     */

    /**
     * Player join handler.
     * @param  CBasePlayer@   pPlayer Player
     * @return HookReturnCode
     */
    HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
    {
        if (g_pInstance is null) {
            return HOOK_CONTINUE;
        }

        g_pInstance.SendTimer(pPlayer);

        for (int i = 0; i < OBJECTIVE_COUNT; i++) {
            int iObjective = (i + 1);

            g_pInstance.SendObjective(pPlayer, iObjective);
        }

        return HOOK_CONTINUE;
    }

    /**
     * Run objectives cycle.
     * @return void
     */
    void RunTimer()
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.RunTimer();
    }

    /**
     * Run objectives cycle.
     * @return void
     */
    void RunObjectives()
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.RunObjectives();
    }



    /*
     * -------------------------------------------------------------------------
     * Map hooks
     * -------------------------------------------------------------------------
     */

    /**
     * Map hook: Activate survival mode.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void ActivateSurvival(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        g_SurvivalMode.Activate();
    }

    /**
     * Map hook: Start game.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void StartGame(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.StartGame();
    }

    /**
     * Map hook: Update timer.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void UpdateTimer(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.UpdateTimer(useType, flValue);
    }

    /**
     * Map hook: Send timer.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void SendTimer(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        if (pActivator !is null && pActivator.IsPlayer()) {
            g_pInstance.SendTimer(cast<CBasePlayer@>(pActivator));
        } else {
            g_pInstance.SendTimer(null);
        }
    }

    /**
     * Map hook: Update objectives.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void UpdateObjectives(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.UpdateObjectives();
    }

    /**
     * Map hook: Send objective.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void SendObjective(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        if (pActivator !is null && pActivator.IsPlayer()) {
            g_pInstance.SendObjective(cast<CBasePlayer@>(pActivator), int(flValue));
        } else {
            g_pInstance.SendObjective(null, int(flValue));
        }
    }
}
