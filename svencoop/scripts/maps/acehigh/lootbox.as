namespace LOOTBOX
{

array<string> LootTable1 = 
{
	"weapon_ns_pistol",
	"weapon_ns_machinegun",
	"weapon_ns_shotgun"
};

dictionary itemKeys = 
{
	{ "solid", "0" },
	{ "movetype", "5" }
};

dictionary suitKeys = 
{
	{ "model", "models/chan_space_escape/items/w_heavy.mdl" },
	{ "spawnflags", "1280" },
	{ "target_on_collect", "suit_model_c" },
	{ "target_on_drop", "hud_drop" },
	{ "target_on_destroy", "hud_drop" },
	{ "targetname", "suit" },
	{ "item_name", "suit" },
	{ "holder_can_drop", "0" },
	{ "solid", "0" },
	{ "movetype", "5" },
	{ "return_timelimit", "-1" },
	{ "carried_hidden", "1" },
	{ "item_icon", "chan_space/items/heavy.spr" },
	{ "weight", "0" },
	{ "item_group", "suit" },
	{ "display_name", "Suit" },
	{ "description", "Allows the user to survive outside gaining access to vents" },
	{ "item_name_canthave", "suit" }
};

dictionary toolKeys = 
{
	{ "model", "models/chan_space_escape/items/new_toolbox.mdl" },
	{ "spawnflags", "1280" },
	{ "holder_can_drop", "1" },
	{ "target_on_collect", "hud_pickup" },
	{ "target_on_drop", "hud_drop" },
	{ "target_on_destroy", "hud_drop" },	
	{ "solid", "0" },
	{ "movetype", "5" },
	{ "return_timelimit", "-1" },
	{ "item_group", "tools" },
	{ "weight", "50" },
	{ "item_icon", "chan_space/items/tool.spr" },
	{ "carried_sequencename", "carried" },
	{ "scale", "1.5" },
	{ "targetname", "tools" },
	{ "display_name", "Tools" },
	{ "item_name_canthave", "tool_main" },
	{ "description", "Will permanently unlock any door, consumes on use" },
	{ "item_name", "tool_main" }
};

void Precache()
{
	//Models
	g_Game.PrecacheModel( "models/chan_space_escape/items/w_heavy.mdl" );
	g_Game.PrecacheModel( "models/chan_space_escape/items/new_toolbox.mdl" );	
	
	//Sprites
	g_Game.PrecacheModel( "sprites/chan_space/items/heavy.spr" );	
	g_Game.PrecacheModel( "sprites/chan_space/items/tool.spr" );	
}

Vector VecBModelOrigin( entvars_t@ pevBModel )
{
	Vector vecOut = pevBModel.absmin + ( pevBModel.size * 0.5 );
	vecOut.z = pevBModel.absmin.z + 1;
	return vecOut;
}
	
void SpawnLoot( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBaseEntity@ pLoot;
	string szClassname;
	dictionary dictKeys = {};
	
	Vector vecOrigin = VecBModelOrigin( pCaller.pev );
	
	CustomKeyvalues@ kvObject = pCaller.GetCustomKeyvalues();
	
	if( kvObject is null )
		return;
	
	uint iLootTable = kvObject.GetKeyvalue( "$i_loottable" ).GetInteger();
	
	if( !( iLootTable <= 2 ) )
		return;
	
	uint iRoll = Math.RandomLong( 1, 100 );
	//TODO: Improve below logic to avoid if else spam
	switch( iLootTable )
	{
		case 1:
		{
			if( iRoll <= 15 )
				szClassname = LootTable1[Math.RandomLong( 1, LootTable1.length() - 1 )];
			else if( iRoll <= 40 )
				szClassname = LootTable1[0];
			else if( iRoll <= 50 )
				szClassname = "weapon_ns_grenade";
			else if( iRoll <= 70 )
			{
				szClassname = Math.RandomLong( 0, 1 ) == 0 ? "item_healthkit" : "item_battery";
				dictKeys = itemKeys;
			}
			else if( iRoll <= 85 )
			{
				szClassname = "weaponbox";
				dictKeys = 
				{
					{ "bullet9mm", "50" },
					{ "buckshot", "8" },
					{ "bullet556", "75" },
					{ "ARgrenades", "4" }
				};
			}
			else if( iRoll <= 87 )
			{
				szClassname = "item_inventory";
				dictKeys = suitKeys;		
			}
			else
			{
				return; //You get NOTHING!!!
			}
			break;
		}
		case 2:
		{
			if( iRoll <= 10 )
				szClassname = Math.RandomLong( 0, 1 ) == 0 ? "weapon_medkit" : "weapon_sentry";
			else if( iRoll <= 35 )
				szClassname = "weapon_ns_heavymachinegun";
			else if( iRoll <= 50 )
				szClassname = "weapon_ns_grenadegun";
			else if( iRoll <= 70 )
				szClassname = "weapon_ns_shotgun";
			else if( iRoll <= 80 )
				szClassname = "weapon_ns_mine";
			else if( iRoll <= 85 )
			{
				szClassname = "item_inventory";
				dictKeys = suitKeys;				
			}
			else if( iRoll <= 90 )
			{
				szClassname = "item_inventory";
				dictKeys = toolKeys;	
			}
			else
			{
				szClassname = "weaponbox";
				dictKeys = 
				{
					{ "bullet9mm", "100" },
					{ "buckshot", "16" },
					{ "bullet556", "150" },
					{ "ARgrenades", "8" }
				};
			}
		}
	}

	@pLoot = g_EntityFuncs.CreateEntity( szClassname, dictKeys, true );
	pLoot.pev.origin = vecOrigin;
	pLoot.pev.angles = pCaller.pev.angles;
}
}