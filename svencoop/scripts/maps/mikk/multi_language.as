/*

INSTALL:

#include "mikk/entities/utils"
#include "mikk/multi_language"

void MapInit()
{
	MultiLanguageInit();
}

- Suggestions:
	- 
	- 
	- 
	- 
*/

// Read current map .ent localization script.
const string EntFileLoad = "multi_language/" + string( g_Engine.mapname ) + ".ent";

void MultiLanguageInit()
{
	// Wait a moment before deleting old entities.
	g_Scheduler.SetTimeout( "MultiLanguageActivate", 1.0f );
}

array<string> Names;

void MultiLanguageActivate()
{
	CBaseEntity@ pNewTexts = null;
	CBaseEntity@ pOldTexts = null;

	if( g_EntityLoader.LoadFromFile( EntFileLoad ) )
	{
		while ( ( @pNewTexts = g_EntityFuncs.FindEntityByClassname( pNewTexts, "game_text_custom" ) ) !is null )
		{
			// Find new entities and save their targetnames
			Names.insertLast(pNewTexts.GetTargetname());
		}
		
		// Find old entities and compare targetnames
		while ( ( @pOldTexts = g_EntityFuncs.FindEntityByClassname( pOldTexts, "game_text" ) ) !is null )
		{
			// Delete game_text/env_message that has the same targetnames as game_text_custom
			if( Names.find(pOldTexts.pev.targetname) >= 0 )
			{
				g_EntityFuncs.Remove( pOldTexts );
			}
		}
		// Ditto
		while ( ( @pOldTexts = g_EntityFuncs.FindEntityByClassname( pOldTexts, "env_message" ) ) !is null )
		{
			if( Names.find(pOldTexts.pev.targetname) >= 0 )
			{
				g_EntityFuncs.Remove( pOldTexts );
			}
		}
	}
	else
		g_EngineFuncs.ServerPrint( "Can't open multi-language script file " + EntFileLoad + "\n" );
}