#include 'CUtility'
#include 'CPlayerFuncs'
#include 'CEntityFuncs'
#include 'CMap'
#include 'CHooks'
#include 'CFileManager'
#include 'ScriptBaseCustomEntity'

CMKUtils mk;

class CMKUtils
{
    // So i can update it easly
    string GetDiscord()
	{
		return 'https://discord.gg/THDKrgBEny';
	}

    CMKPlayerFuncs PlayerFuncs;
    CMKEntityFuncs EntityFuncs;
    CMKFileManager FileManager;
    CMKHooks Hooks;
    CMKMap Map;

    CMKUtils()
    {
        PlayerFuncs = CMKPlayerFuncs();
        EntityFuncs = CMKEntityFuncs();
        FileManager = CMKFileManager();
        Hooks = CMKHooks();
        Map = CMKMap();
    }
}