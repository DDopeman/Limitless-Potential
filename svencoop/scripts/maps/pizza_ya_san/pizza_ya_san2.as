#include "weapon_as_shotgun"
#include "weapon_as_jetpack"
#include "weapon_as_soflam"
#include "../point_checkpoint"

array<ItemMapping@> g_ItemMappings = {
    ItemMapping("weapon_shotgun", GetASShotgunName()),
    ItemMapping("weapon_as_jetpack", GetJetPackName()),
    ItemMapping("weapon_as_soflam", GetSoflamName())
};

void MapInit() {
    // ÉJÉXÉ^ÉÄïêäÌí«â¡
    RegisterASShotgun();
    RegisterJetPack();
    RegisterSoflam();
	RegisterPointCheckPointEntity();
    
    g_EngineFuncs.ServerPrint("[map script] weapon scripts working! ....(^^;)b\n");
}
