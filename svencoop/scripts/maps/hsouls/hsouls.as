#include "../point_checkpoint"
#include "w00tguy/env_weather"
#include "../HLSPClassicMode"
#include "../hl_weapons/weapons"
#include "../hl_weapons/mappings"


const string strSnowSprite = "sprites/arctic_incident/ws_snow_fx.spr";
const bool blEnableSnowfall = false;
float flSurvivalVoteAllow = 0.0f; // Declare globally

EHandle hSnowFall;

void MapInit()
{
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
    RegisterPointCheckPointEntity();
    WeatherMapInit();
 	RegisterClassicWeapons();
	
	RegisterPointCheckPointEntity();
    ClassicModeMapInit();

    g_Game.PrecacheModel(strSnowSprite);
    g_Game.PrecacheGeneric(strSnowSprite);
	
    if (g_Engine.mapname == "hauntedsouls_c2")
    {
        g_SurvivalMode.SetStartOn(false);

        flSurvivalVoteAllow = g_EngineFuncs.CVarGetFloat("mp_survival_voteallow"); // Update global variable

        if (flSurvivalVoteAllow > 0)
            g_EngineFuncs.CVarSetFloat("mp_survival_voteallow", 0);
    }
}

void MapStart()
{
    if (blEnableSnowfall)
        hSnowFall = CreateSnowWeather();
}

EHandle CreateSnowWeather()
{
    dictionary snow =
    {
        { "angles", "90 0 0" },
        { "intensity", "16" },
        { "particle_spr", strSnowSprite },
        { "radius", "1280" },
        { "speed_mult", "1.3" },
        { "weather_type", "2" },
        { "spawnflags", "1" },
        { "targetname", "snow" }
    };

    EHandle hEnvWeather = g_EntityFuncs.CreateEntity("env_weather1", snow, true);

    if (!hEnvWeather.IsValid())
    {
        return EHandle(null);
    }

    g_Scheduler.SetTimeout("SnowThink", Math.RandomFloat(60.0f, 120.0f));

    return hEnvWeather;
}

void SnowThink()
{
    if (!hSnowFall.IsValid())
    {
        return;
    }

    CBaseEntity@ pSnow = hSnowFall.GetEntity();
    if (pSnow !is null)
    {
        pSnow.Use(pSnow, pSnow, USE_TOGGLE, 0.0f);
        g_Scheduler.SetTimeout("SnowThink", Math.RandomFloat(180.0f, 300.0f));
    }
}


// Trigger Script for Survival Mode
void TurnOnSurvival(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    g_EngineFuncs.CVarSetFloat("mp_survival_voteallow", flSurvivalVoteAllow); // Revert to the original cvar setting as per server

    if (g_EngineFuncs.CVarGetFloat("mp_survival_voteallow") > 0 && g_SurvivalMode.MapSupportEnabled() && !g_SurvivalMode.IsActive())
        g_SurvivalMode.Activate(true);
}

// Script conflicts means I have to copypaste this instead of loading directly from survival_generic.as -_-
void DisableSurvival(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if (g_SurvivalMode.IsActive()) // FIXED: Added a check before disabling
        g_SurvivalMode.Disable();
}