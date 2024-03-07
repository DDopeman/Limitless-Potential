/**
 * General purpose "trigger_observer" entity.
 * By Adam "Adambean" Reece
 *
 * This can either be a brush or point entity in game.
 * When used it accepts use types on/off to force start/stop observing, or toggle to swap.
 *
 * Shamelessly stolen and improved from BM:STS but don't tell Templer what I've done.
 */

/**
 * Map initialisation handler.
 * @return void
 */
//void MapInit()
//{
//    g_Module.ScriptInfo.SetAuthor("Adam \"Adambean\" Reece");
//    g_Module.ScriptInfo.SetContactInfo("www.svencoop.com");
//
//    TriggerObserver::Init();
//}

namespace TriggerObserver
{
    /** @const float Entity loop interval. */
    const float ENT_LOOP_INTERVAL = 0.1f;

    /** @const int Do not save position when starting to observe. (Only applies to "use" input.) */
    const int FLAG_NO_SAVE_POSITION = 1<<0;

    /** @enum string Observer states */
    enum eObserverState
    {
        off                     = 0,
        onThenRespawn           = 1,
        onThenResumeOrigin      = 2,
        leavingToResumeOrigin   = 3,
    };

    /** @var bool g_isInitialised Is initialised. */
    bool g_isInitialised = false;

    /**
     * Initialise.
     * @return void
     */
    void Init()
    {
        if (g_isInitialised) {
            g_Game.AlertMessage(at_warning, "[TriggerObserver] Already initialised.\n");
            return;
        }

        g_CustomEntityFuncs.RegisterCustomEntity("TriggerObserver::CTriggerObserver", "trigger_observer");
        g_Scheduler.SetInterval("ObserverThink", ENT_LOOP_INTERVAL, g_Scheduler.REPEAT_INFINITE_TIMES);
        g_isInitialised = true;
    }

    /**
     * Entity: trigger_observer
     */
    final class CTriggerObserver : ScriptBaseEntity
    {
        /**
         * Key value data handler.
         * @param  string szKey   Key
         * @param  string szValue Value
         * @return bool
         */
        bool KeyValue(const string& in szKey, const string& in szValue)
        {
            return BaseClass.KeyValue(szKey, szValue);
        }

        /**
         * Spawn.
         * @return void
         */
        void Spawn()
        {
            if (self.IsBSPModel()) {
                self.pev.solid      = SOLID_TRIGGER;
                self.pev.movetype   = MOVETYPE_NONE;
                self.pev.effects    = EF_NODRAW;

                g_EntityFuncs.SetOrigin(self, self.pev.origin);
                g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);
                g_EntityFuncs.SetModel(self, self.pev.model);
            }
        }

        /**
         * Touch handler.
         * @param  CBaseEntity@ pOther Toucher entity
         * @return void
         */
        void Touch(CBaseEntity@ pOther)
        {
            if (!self.IsBSPModel()) {
                return;
            }

            if (pOther is null or !pOther.IsPlayer()) {
                return;
            }

            CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
            if (!pPlayer.IsConnected() or !pPlayer.IsAlive()) {
                return;
            }

            g_Game.AlertMessage(at_aiconsole, "CTriggerObserver::Use(\"%1\");\n", g_Utility.GetPlayerLog(pPlayer.edict()));

            StartObserving(pPlayer, !self.IsBSPModel());
        }

        /**
         * Use handler.
         * @param  CBaseEntity@ pActivator Activator entity
         * @param  CBaseEntity@ pCaller    Caller entity
         * @param  USE_TYPE     useType    Use type
         * @param  float        flValue    Use value
         * @return void
         */
        void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
        {
            CBaseEntity@ pTarget;

            if ("!activator" == pev.target or "" == pev.target) {
                @pTarget = pActivator;
            } else if ("!caller" == pev.target) {
                @pTarget = pCaller;
            } else {
                @pTarget = g_EntityFuncs.FindEntityByTargetname(null, pev.target);
            }

            if (pTarget is null or !pTarget.IsPlayer()) {
                return;
            }

            CBasePlayer@ pPlayer = cast<CBasePlayer@>(pTarget);
            if (!pPlayer.IsConnected()) {
                return;
            }

            g_Game.AlertMessage(at_aiconsole, "CTriggerObserver::Use(\"%1\", %2, %3, %4);\n", g_Utility.GetPlayerLog(pPlayer.edict()), null, useType, flValue);

            switch (useType) {
                case USE_ON:
                    StartObserving(pPlayer, !self.pev.SpawnFlagBitSet(FLAG_NO_SAVE_POSITION));
                    break;

                case USE_OFF:
                    StopObserving(pPlayer);
                    break;

                case USE_TOGGLE:
                    IsObserving(pPlayer)
                        ? StopObserving(pPlayer)
                        : StartObserving(pPlayer, !self.pev.SpawnFlagBitSet(FLAG_NO_SAVE_POSITION))
                    ;
                    break;
            }
        }
    }

    /**
     * Check if a player is currently observing.
     * @param  CBasePlayer@ pPlayer Player entity
     * @return bool                 Player is observing or not
     */
    bool IsObserving(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null or !pPlayer.IsPlayer() or !pPlayer.IsConnected()) {
            return false;
        }

        return pPlayer.GetObserver().IsObserver();
    }

    /**
     * Start observer mode for a player.
     * @param  CBasePlayer@ pPlayer       Player entity
     * @param  bool         fSavePosition Save the player's current position, so the player can be placed back there when they stop observing
     * @return void
     */
    void StartObserving(CBasePlayer@ pPlayer, bool fSavePosition = false)
    {
        if (pPlayer is null or !pPlayer.IsPlayer() or !pPlayer.IsConnected()) {
            return;
        }

        g_Game.AlertMessage(at_aiconsole, "CTriggerObserver::StartObserving(\"%1\", %2);\n", g_Utility.GetPlayerLog(pPlayer.edict()), fSavePosition);

        CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
        CustomKeyvalue pCustomIsObserving(pCustom.GetKeyvalue("$i_is_observer"));
        CustomKeyvalue pCustomObserverPriorOrigin(pCustom.GetKeyvalue("$v_observer_prior_origin"));
        CustomKeyvalue pCustomObserverPriorAngles(pCustom.GetKeyvalue("$v_observer_prior_angles"));

        if (IsObserving(pPlayer)) {
            g_Game.AlertMessage(at_logged, "\"%1\" cannot start observing: Already is observing.\n", g_Utility.GetPlayerLog(pPlayer.edict()));
            return;
        }

        if (fSavePosition) {
            pPlayer.KeyValue("$i_is_observer", eObserverState::onThenResumeOrigin);
            g_Game.AlertMessage(at_logged, "\"%1\" has started observing, and will be returned to %2 %3 %4 when finished.\n", g_Utility.GetPlayerLog(pPlayer.edict()), pPlayer.pev.origin.x, pPlayer.pev.origin.y, pPlayer.pev.origin.z);
        } else {
            pPlayer.KeyValue("$i_is_observer", eObserverState::onThenRespawn);
            g_Game.AlertMessage(at_logged, "\"%1\" has started observing, and will be respawned when finished.\n", g_Utility.GetPlayerLog(pPlayer.edict()));
        }

        pPlayer.GetObserver().StartObserver(pPlayer.pev.origin, pPlayer.pev.angles, false);
        pPlayer.pev.nextthink = (g_Engine.time + (ENT_LOOP_INTERVAL * 2));

        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "* Press TERTIARY ATTACK to leave observer mode.\n");
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "* This is usually done by pressing the MIDDLE BUTTON (wheel) of your mouse.\n");

        pCustom.SetKeyvalue("$v_observer_prior_origin", pPlayer.pev.origin);
        pCustom.SetKeyvalue("$v_observer_prior_angles", pPlayer.pev.angles);
    }

    /**
     * Stop observer mode for a player.
     * @param  CBasePlayer@ pPlayer Player entity
     * @return void
     */
    void StopObserving(CBasePlayer@ pPlayer, bool fIgnoreSavedPosition = false)
    {
        if (pPlayer is null or !pPlayer.IsPlayer() or !pPlayer.IsConnected()) {
            return;
        }

        g_Game.AlertMessage(at_aiconsole, "CTriggerObserver::StopObserving(\"%1\", %2);\n", g_Utility.GetPlayerLog(pPlayer.edict()), fIgnoreSavedPosition);

        CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
        CustomKeyvalue pCustomIsObserving(pCustom.GetKeyvalue("$i_is_observer"));
        CustomKeyvalue pCustomObserverPriorOrigin(pCustom.GetKeyvalue("$v_observer_prior_origin"));
        CustomKeyvalue pCustomObserverPriorAngles(pCustom.GetKeyvalue("$v_observer_prior_angles"));

        bool fResumePosition = (pCustomIsObserving.GetInteger() == 2);

        if (!IsObserving(pPlayer)) {
            g_Game.AlertMessage(at_logged, "\"%1\" cannot finish observing: Isn't current observing.\n", g_Utility.GetPlayerLog(pPlayer.edict()));
            return;
        }

        pPlayer.GetObserver().StopObserver(!fResumePosition);

        if (
            !fIgnoreSavedPosition
            && fResumePosition
            && pCustomObserverPriorOrigin.Exists()
            && pCustomObserverPriorAngles.Exists()
        ) {
            pPlayer.KeyValue("$i_is_observer", eObserverState::leavingToResumeOrigin);
            g_Game.AlertMessage(at_logged, "\"%1\" has finished observing, and will be returned to %2 %3 %4.\n", g_Utility.GetPlayerLog(pPlayer.edict()), pPlayer.pev.origin.x, pPlayer.pev.origin.y, pPlayer.pev.origin.z);
        } else {
            pPlayer.KeyValue("$i_is_observer", eObserverState::off);
            g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
            g_Game.AlertMessage(at_logged, "\"%1\" has finished observing, and will be respawned.\n", g_Utility.GetPlayerLog(pPlayer.edict()));
        }

        pPlayer.pev.nextthink = (g_Engine.time + 0.01);
    }

    /**
     * Global player observer handler.
     * @return void
     */
    void ObserverThink()
    {
        for (int i = 1; i <= g_Engine.maxClients; i++) {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if (pPlayer is null or !pPlayer.IsPlayer() or !pPlayer.IsConnected()) {
                continue;
            }

            CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
            CustomKeyvalue pCustomIsObserving(pCustom.GetKeyvalue("$i_is_observer"));
            if (pCustomIsObserving.GetInteger() == 3) {
                CustomKeyvalue pCustomObserverPriorOrigin(pCustom.GetKeyvalue("$v_observer_prior_origin"));
                CustomKeyvalue pCustomObserverPriorAngles(pCustom.GetKeyvalue("$v_observer_prior_angles"));

                if (pCustomObserverPriorOrigin.Exists() && pCustomObserverPriorAngles.Exists()) {
                    g_EntityFuncs.SetOrigin(pPlayer, pCustomObserverPriorOrigin.GetVector());
                    pPlayer.pev.angles      = pCustomObserverPriorAngles.GetVector();
                    pPlayer.pev.fixangle    = FAM_FORCEVIEWANGLES;
                }

                pPlayer.pev.nextthink = (g_Engine.time + 0.01);
                pPlayer.KeyValue("$i_is_observer", eObserverState::off);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Stopped observing.");
                continue;
            }

            if (!IsObserving(pPlayer)) {
                continue;
            }

            if ((pPlayer.pev.button & IN_ALT1) != 0) {
                StopObserving(pPlayer);
                continue;
            }

            HUDTextParams sHudTextObserverExitReminder;

            sHudTextObserverExitReminder.channel        = 3;
            sHudTextObserverExitReminder.x              = -1;
            sHudTextObserverExitReminder.y              = 0.9;
            sHudTextObserverExitReminder.effect         = 1;
            sHudTextObserverExitReminder.r1             = 100;
            sHudTextObserverExitReminder.g1             = 100;
            sHudTextObserverExitReminder.b1             = 100;
            sHudTextObserverExitReminder.r2             = 240;
            sHudTextObserverExitReminder.g2             = 240;
            sHudTextObserverExitReminder.b2             = 240;
            sHudTextObserverExitReminder.fadeinTime     = 0;
            sHudTextObserverExitReminder.fadeoutTime    = 0;
            sHudTextObserverExitReminder.holdTime       = (ENT_LOOP_INTERVAL * 3);
            sHudTextObserverExitReminder.fxTime         = 0.1;

            g_PlayerFuncs.HudMessage(pPlayer, sHudTextObserverExitReminder, "Press TERTIARY ATTACK to leave observer mode.");

            pPlayer.pev.nextthink = (g_Engine.time + (ENT_LOOP_INTERVAL * 2));
        }
    }
}
