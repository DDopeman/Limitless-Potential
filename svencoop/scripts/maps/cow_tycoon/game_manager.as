#include "func_vehicle_flingfix"
#include "func_grain"
#include "weapons"
#include "..\point_checkpoint"

//CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue

int DAY_LENGTH = 5*60;

int COW_COST = 195;
int COW_MIN_HEALTH = 200;
int COW_MAX_HEALTH = 300;

int BANK_INTEREST_TIME = 1; //time, in days, in which the bank will take interest (unused)
int BANK_MAX_LOAN = 5000; //maximum loan that can be taken out
int BANK_LOAN_INCREMENT = 100; //amount of money you take out in loan at a time
int BANK_FLAT_INTEREST_RATE = 50; //amount of money the bank will charge in interest no matter what

int BARNEY_COST = 60;
int RESPAWN_COST = 550;
int FENCE_COST = 30;
int BUCKET_COST = 65;

int WHEAT_LINE = 20; //length of a wheat plot
int WHEAT_VAL = 5; //value per wheat
int WHEAT_X_VARIANCE = 50;
int WHEAT_DIST_X = 224;
int WHEAT_DIST_Y = 75;
int MAX_WHEAT_LEVEL = 5;
Vector WHEAT_START_POS = Vector(3642, 7002, 112);


int cash = 800;
int lumber = 0;
int grainCost = 10;
int night = 0;
float currentDay = 0.0;
int bankLoan = 0;
int nextBankInterestDay = BANK_INTEREST_TIME;
int hasKilledCivilian = 0;
int daysSinceMurder = 0;
int amishEnding = 1; //turns to 0 if you ever buy technology

int meat_upgrader_level = 0; //these numbers determine which triggers are active
int milk_upgrader_level = 0;
int grain_upgrader_level = 0;

int wheat_plot_level = 0; //how many wheat plots you own


float bankInterestRate = 0.25; //percentage

//indexes for these tables are stored in the "skin" property of the purchase button
//so skin 0 = weapon_m3, skin 1 = weapon_357, etc.
array<string>@ gun_names = {
"weapon_m3", 
"weapon_357", "weapon_p228", "weapon_fiveseven", 
"weapon_usp", "weapon_csdeagle", "weapon_mp5navy", 
"weapon_xm1014", "weapon_ak47", "weapon_m16", 
"weapon_m4a1", "weapon_p90", "weapon_crossbow",
"weapon_rpg", "weapon_awp", "weapon_csm249",
"weapon_medkit"};

array<int>@ gun_costs = {
450, 
200, 150, 500, 
200, 500, 650,
650, 2150, 850, 
2400, 2100, 1050,
10000, 7000, 5000,
1000};

array<string>@ ammo_names = {
"ammo_buckshot", 
"ammo_357", "ammo_9mmclip", "item_healthkit", 
"item_battery", "ammo_crossbow", "ammo_m4a1",
"ammo_ak47", "ammo_rpgclip", "ammo_awp",
"ammo_csm249"};

array<int>@ ammo_costs = {
30, 
15, 10, 55, 
150, 40, 30,
30, 105, 50,
50 };

array<int>@ meat_upgrader_amounts = {
0,
25, 50, 100, 250, 500, 1000, 2000
};

array<int>@ grain_upgrader_amounts = {
0,
25, 50, 150, 300, 650, 1500, 4000
};

array<int>@ milk_upgrader_amounts = {
0,
50, 100, 125, 150, 350, 650, 1500
};

HUDTextParams cash_hud_params;
HUDTextParams message_hud_params;
HUDSpriteParams message_bkg_hud_params;



void MapInit()
{
	//Helper method to register all weapons
	RegisterAll();
	VehicleMapInit(true, true);
	GrainMapInit();
	RegisterPointCheckPointEntity();
	
	g_SurvivalMode.EnableMapSupport();
}

void MapStart()
{
	g_SurvivalMode.Disable();
	
	cash_hud_params.x = 0;
	cash_hud_params.y = 0.1;
	cash_hud_params.channel = 1;
	cash_hud_params.fadeinTime = 0;
	cash_hud_params.r1 = 255;
	cash_hud_params.g1 = 255;
	cash_hud_params.b1 = 255;
	cash_hud_params.a1 = 200;
	cash_hud_params.holdTime = 9999;
	
	message_hud_params.x = -1.0;
	message_hud_params.y = 0.0;
	message_hud_params.channel = 2;
	message_hud_params.fadeinTime = 0;
	message_hud_params.r1 = 255;
	message_hud_params.g1 = 255;
	message_hud_params.b1 = 130;
	message_hud_params.a1 = 255;
	message_hud_params.holdTime = 3;
	message_hud_params.fxTime = 0.1;
	
	message_bkg_hud_params.spritename = "cow_tycoon/ann_bar.spr";
	message_bkg_hud_params.flags = HUD_SPR_OPAQUE | HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_X | HUD_ELEM_NO_BORDER;
	message_bkg_hud_params.x = -1.0;
	message_bkg_hud_params.y = 0.0;
	message_bkg_hud_params.channel = 0;
	message_bkg_hud_params.frame = 0;
	message_bkg_hud_params.fadeinTime = 0;
	message_bkg_hud_params.holdTime = 3;
	message_bkg_hud_params.fxTime = 0.1;
	message_bkg_hud_params.color1 = RGBA( 255, 255, 255, 255 );	
	


	updateCashVal();
	g_Scheduler.SetInterval("toggleDayNight", DAY_LENGTH, g_Scheduler.REPEAT_INFINITE_TIMES); //day night cycle
	g_Scheduler.SetInterval("updateCashVal", 3, g_Scheduler.REPEAT_INFINITE_TIMES); //display cash on player screens
}

void MapStartButtonPressed(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	Vote begin_vote("Start game?", "Vote yes if you are ready to start.", 5, 75);
	begin_vote.SetVoteEndCallback(@VoteEndFunc);
	begin_vote.Start();
	
}

void VoteEndFunc(Vote@ pVote, bool fResult, int iVoters)
{

	CBaseEntity@ start_button = null;
	@start_button = g_EntityFuncs.FindEntityByTargetname(start_button, "start_game");

	//using start_game button as a dummy activator and pcaller
	
	
	
	if (fResult == true)
	{
		
		g_EntityFuncs.FireTargets("game_start_scene_cam", start_button, start_button, USE_SET);
		g_EntityFuncs.FireTargets("game_start_weird_sound", start_button, start_button, USE_SET);
		g_EntityFuncs.Remove(start_button);
		g_EntityFuncs.FireTargets("pregame_spawn", start_button, start_button, USE_OFF);
		g_EntityFuncs.FireTargets("game_spawn", start_button, start_button, USE_ON);
		g_Scheduler.SetInterval("OpenSceneOver", 10, 1); //begin the actual game
	}
}

void OpenSceneOver()
{
	
	CBaseEntity@ game_logo = null;
	@game_logo = g_EntityFuncs.FindEntityByTargetname(game_logo, "game_logo");
	g_EntityFuncs.Remove(game_logo);
	g_PlayerFuncs.RespawnAllPlayers();
	
	g_SurvivalMode.Enable();
}

string end_message = "";
float end_message_y = 0.0;

void gameEnd(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	CBaseEntity@ start_button = null;
	@start_button = g_EntityFuncs.FindEntityByTargetname(start_button, "start_game");
	//using start_game button as a dummy activator and pcaller

	g_EntityFuncs.FireTargets("pregame_spawn", start_button, start_button, USE_ON);
	g_EntityFuncs.FireTargets("game_spawn", start_button, start_button, USE_OFF);

	g_PlayerFuncs.ScreenFadeAll(Vector(0,0,0), 1, 1, 255, 0);
	
	g_EntityFuncs.FireTargets("end_cut1", start_button, start_button, USE_SET);
	g_EntityFuncs.FireTargets("end_wind", start_button, start_button, USE_ON);
	
	end_message_y = 0.8;
	end_message = "With the death of the Cow God,\nall cows in the world died violently in an event known as the 'Red Shower'. \nThe global meat industry crashed. Major restaurants shut down. Millions lost their jobs.";
	g_Scheduler.SetInterval("displayEndingMessage", 1, 1);
	
	g_Scheduler.SetInterval("gameEndCut2", 20, 1);
}

void gameEndCut2()
{
	g_PlayerFuncs.RespawnAllPlayers();
	CBaseEntity@ start_button = null;
	@start_button = g_EntityFuncs.FindEntityByTargetname(start_button, "start_game");
	//using start_game button as a dummy activator and pcaller

	g_PlayerFuncs.ScreenFadeAll(Vector(0,0,0), 1, 1, 255, 0);
	
	g_EntityFuncs.FireTargets("end_cut2", start_button, start_button, USE_SET);
	
	end_message_y = 0.8;
	end_message = "Nobody knows the names of those who summoned the Cow God or why they did it.\nLocals of the immediate area disappeared and never resurfaced.\n All is silent. The concept of a 'hamburger' fades out of cultural memory.";
	g_Scheduler.SetInterval("displayEndingMessage", 1, 1);
	g_Scheduler.SetInterval("finishGame", 20, 1);
}

void displayEndingMessage()
{

	HUDTextParams end_par;
	end_par.x = -1.0;
	end_par.y = end_message_y;
	end_par.channel = 4;
	end_par.fadeinTime = 0.3;
	end_par.r1 = 255;
	end_par.g1 = 255;
	end_par.b1 = 255;
	end_par.a1 = 255;
	end_par.holdTime = 18;
	end_par.fxTime = 0.1;

	g_PlayerFuncs.HudMessageAll(end_par, end_message); 
}

void finishGame()
{
	CBaseEntity@ start_button = null;
	@start_button = g_EntityFuncs.FindEntityByTargetname(start_button, "start_game");
	//using start_game button as a dummy activator and pcaller

	g_PlayerFuncs.ScreenFadeAll(Vector(0,0,0), 1, 500, 255, 0);
	
	g_EntityFuncs.FireTargets("final_game_end", start_button, start_button, USE_SET);
}


//-----------------------------------------------------------------------------------------
//hud message stuff
//-----------------------------------------------------------------------------------------


void updateCashVal()
{
	if (bankLoan <= 0)
	{
		g_PlayerFuncs.HudMessageAll(cash_hud_params, "Cash: $" + cash + "\nDay " + currentDay);
	}
	else
	{
		g_PlayerFuncs.HudMessageAll(cash_hud_params, "Cash: $" + cash + "\nLoan: $" + bankLoan  + "\nDay " + currentDay);
	}
}

void displayHudMessage(CBasePlayer@ plr, string_t hud_text)
{
	g_PlayerFuncs.HudCustomSprite(plr, message_bkg_hud_params);
	g_PlayerFuncs.HudMessage(plr, message_hud_params, hud_text); 
}

void displayHudMessageAll(string_t hud_text)
{
	g_PlayerFuncs.HudCustomSprite(null, message_bkg_hud_params);
	g_PlayerFuncs.HudMessageAll(message_hud_params, hud_text); 
}

void updateCashValTriggerProxy(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue) //exists out of laziness
{
	updateCashVal();
}

//-----------------------------------------------------------------------------------------
//wheat stuff
//-----------------------------------------------------------------------------------------

void makeNewWheat(Vector pos)
{
	CBaseEntity@ new_Wheat;
	CBaseEntity@ world_Wheat;
		
	@world_Wheat = g_EntityFuncs.FindEntityByTargetname(world_Wheat,"world_wheat");
		
	dictionary keys;
		
	keys["origin"] = "" + pos.x + " " + pos.y + " " + pos.z;
	keys["model"] = string(world_Wheat.pev.model);
	keys["flags"] = string(world_Wheat.pev.flags);
		
	@new_Wheat = g_EntityFuncs.CreateEntity("func_breakable", keys, true);
	new_Wheat.pev.model = world_Wheat.pev.model;
	new_Wheat.pev.flags = world_Wheat.pev.flags;
	new_Wheat.pev.spawnflags = world_Wheat.pev.spawnflags;
	new_Wheat.pev.rendermode = 2;
	new_Wheat.pev.renderamt = 255;
	new_Wheat.pev.health = world_Wheat.pev.health;
	new_Wheat.pev.targetname = "breakable_Wheat";
	new_Wheat.pev.target = "wheat_broken_func";
	
	new_Wheat.KeyValue("material", matWood);
}

void WheatBroken(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	addCash(WHEAT_VAL);
	g_Scheduler.SetTimeout("makeNewWheat", 50, pcaller.pev.origin);
}

void spawnWheatLine(Vector pos)
{
	//wheat generates horizontally from a high Y value to a low Y value
	for( int i = 0; i < WHEAT_LINE; ++i )
	{
		makeNewWheat(pos + Vector(0, (i*WHEAT_DIST_Y) * -1, 0) );
	}
}

void wheatUpgrade(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= pcaller.pev.skin)
	{
		CBaseEntity@ message_trigger;
		const string button_name = pcaller.pev.targetname;
		@message_trigger = g_EntityFuncs.FindEntityByTargetname(message_trigger, button_name + "_message");
		
		addCash(pcaller.pev.skin * -1);
		wheat_plot_level += 1;
		g_EntityFuncs.FireTargets(pcaller.pev.netname, activator, pcaller, USE_SET);
		g_EntityFuncs.FireTargets("WHEAT_PLOT_"+wheat_plot_level, activator, pcaller, USE_SET);
		
		spawnWheatLine(Vector(WHEAT_START_POS.x + wheat_plot_level*WHEAT_DIST_X, WHEAT_START_POS.y, WHEAT_START_POS.z));
		
		pcaller.pev.skin = int(float(pcaller.pev.skin) * 2);
		message_trigger.pev.netname = "Buy Wheat Plot ($" + pcaller.pev.skin + ")";
		displayHudMessageAll("Bought a new farming plot");

		if (wheat_plot_level == MAX_WHEAT_LEVEL)
		{
			g_EntityFuncs.Remove(pcaller);
			
			for(;;)
			{
			CBaseEntity@ ent;
			@ent = g_EntityFuncs.FindEntityByTargetname(ent, pcaller.pev.message);
			if (@ent != null)
			{
				g_EntityFuncs.Remove(ent);
			}
			else
			{
				break;
			}
			}
		}
		
	}
	else
	{
		CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
		displayHudMessage(plr, "Could not afford wheat plot!");
	}
	
}

//-----------------------------------------------------------------------------------------
//milk
//-----------------------------------------------------------------------------------------

void spawnMilkBucket()
{
	CBaseEntity@ new_bucket;
	CBaseEntity@ world_empt_bucket;
	CBaseEntity@ bucket_spawnloc;
	
	@world_empt_bucket = g_EntityFuncs.FindEntityByTargetname(world_empt_bucket,"world_bucket");
	@bucket_spawnloc = g_EntityFuncs.FindEntityByTargetname(bucket_spawnloc,"bucket_spawnloc");
		
	dictionary keys;
	Vector origin;
		
	origin = bucket_spawnloc.pev.origin;
	keys["origin"] = "" + origin.x + " " + origin.y + " " + origin.z;
	keys["model"] = string(world_empt_bucket.pev.model);
	keys["flags"] = string(world_empt_bucket.pev.flags);
		
	@new_bucket = g_EntityFuncs.CreateEntity("func_milk_bucket", keys, true);
	new_bucket.pev.model = world_empt_bucket.pev.model;
	new_bucket.pev.flags = world_empt_bucket.pev.flags;
	new_bucket.pev.spawnflags = world_empt_bucket.pev.spawnflags;
}

void buyMilkBucket(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= BUCKET_COST)
	{
		addCash(BUCKET_COST * -1);
		spawnMilkBucket();
	}
}

void upgradeMilk(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	//pcaller.pev.body determines the level of this meat upgrader
	//body of the meat determines the level of the meat
	int level = int(pcaller.pev.body);
	
	if (activator.pev.targetname == "filled_bucket" && milk_upgrader_level >= level)
	{
		if (int(activator.pev.body) < level)
		{
			activator.pev.body = level;
			activator.pev.impacttime += milk_upgrader_amounts[level]; //add value
		}
	}
}

//-----------------------------------------------------------------------------------------
//meat
//-----------------------------------------------------------------------------------------

void cowSpawned(CBaseMonster@ cow_m, CBaseEntity@ cow	)
{
	//set random cow health and cow value to match
	int cow_health;
	cow_health = Math.RandomLong(COW_MIN_HEALTH, COW_MAX_HEALTH);
	cow.pev.health = cow_health;
	cow.pev.impacttime = cow_health; //cow value is stored in pev.impacttime
}

void sellMeatProxy(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (activator.pev.targetname == "meat_obj")
	{
		//if this is a valid meat, sell it and remove
		g_EntityFuncs.FireTargets("sell_noise", activator, activator, USE_SET);
		g_PlayerFuncs.ShowMessageAll("meat value:" + activator.pev.impacttime);
		addCash(int(activator.pev.impacttime));
		g_EntityFuncs.Remove(activator);
	}
	else if (activator.pev.targetname == "filled_bucket")
	{
		g_EntityFuncs.FireTargets("sell_noise", activator, activator, USE_SET);
		g_PlayerFuncs.ShowMessageAll("milk value:" + activator.pev.impacttime);
		addCash(int(activator.pev.impacttime));
		g_EntityFuncs.Remove(activator);
		spawnMilkBucket();
	}
	//else if (activator.pev.ClassNameIs("func_milk_bucket") == true)
	//{
		//g_Game.AlertMessage(at_console, "GOD HAS NOT FORSAKEN US");
	//}
}

void upgradeMeat(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	//pcaller.pev.body determines the level of this meat upgrader
	//body of the meat determines the level of the meat
	int level = int(pcaller.pev.body);
	if (activator.pev.targetname == "meat_obj" && meat_upgrader_level >= level)
	{
		g_Game.AlertMessage(at_console, "got meat \n");
		if (int(activator.pev.body) < level)
		{
			activator.pev.body = level;
			activator.pev.impacttime += meat_upgrader_amounts[level]; //add value
			
			CBaseEntity@ new_model;
			string_t name_search = "world_meat" + string(level);
			@new_model = g_EntityFuncs.FindEntityByTargetname(new_model, name_search);
			g_EntityFuncs.SetModel( activator, new_model.pev.model );
			
			if (level == 3)
			{
				activator.pev.rendermode = 2;
				activator.pev.renderamt = 200;
			}
			else if (level == 4)
			{
				activator.pev.rendermode = 2;
				activator.pev.renderamt = 100;
			}
			else
			{
				activator.pev.renderamt = 255;
			}
		}
	}
}

void spawnMeat(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	CBaseEntity@ new_meat;
	CBaseEntity@ world_meat;
	@world_meat = g_EntityFuncs.FindEntityByTargetname(world_meat,"world_meat");
	dictionary keys;
	Vector origin;
	
	origin = pcaller.pev.origin + Vector(0,0,100);
	
	keys["model"] = string(world_meat.pev.model);
	keys["flags"] = string(world_meat.pev.flags);
	keys["origin"] = "" + origin.x + " " + origin.y + " " + origin.z;
	@new_meat = g_EntityFuncs.CreateEntity("func_pushable_custom", keys, true);
	g_PlayerFuncs.ShowMessageAll("cow value:" + pcaller.pev.impacttime);
	new_meat.pev.model = world_meat.pev.model;
	new_meat.pev.flags = world_meat.pev.flags;
	new_meat.pev.spawnflags = world_meat.pev.spawnflags;
	new_meat.pev.targetname = "meat_obj";
	new_meat.pev.impacttime = pcaller.pev.impacttime;
	new_meat.pev.body = 0;
}

//-----------------------------------------------------------------------------------------
//grain
//-----------------------------------------------------------------------------------------

void upgradeGrain(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	//pcaller.pev.body determines the level of this meat upgrader
	//body of the meat determines the level of the meat
	int level = int(pcaller.pev.body);
	
	if (activator.pev.targetname == "grain_obj" && grain_upgrader_level >= level)
	{
		if (int(activator.pev.body) < level)
		{
			activator.pev.body = level;
			activator.pev.impacttime += grain_upgrader_amounts[level]; //add value
		}
	}
}

//-----------------------------------------------------------------------------------------
//adds
//-----------------------------------------------------------------------------------------

void addCash(int amount)
{
	//add amount to cash and then update player huds to show the new cash value
	cash += amount;
	updateCashVal();
}

void addLumber(int amount)
{
	//add amount to cash and then update player huds to show the new cash value
	lumber += amount;
	updateCashVal();
}

//-----------------------------------------------------------------------------------------
//misc
//-----------------------------------------------------------------------------------------

void upgradeConveyor(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= pcaller.pev.skin)
	{
		CBaseEntity@ message_trigger;
		const string button_name = pcaller.pev.targetname;
		
		@message_trigger = g_EntityFuncs.FindEntityByTargetname(message_trigger, button_name + "_message");
		
		addCash(pcaller.pev.skin * -1);
		
		pcaller.pev.skin = int(float(pcaller.pev.skin) * 1.5);
		message_trigger.pev.netname = "Upgrade Conveyor ($" + pcaller.pev.skin + ")";
		displayHudMessageAll("Upgraded conveyor");
	}
	else
	{
		CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
		displayHudMessage(plr, "Could not afford conveyor upgrade!");
	}
}

void onCivDeath(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (hasKilledCivilian == 0)
	{
		hasKilledCivilian = 1;
		displayHudMessageAll("A CIVILIAN HAS DIED! PREPARE FOR JUDGEMENT");
		
		g_EntityFuncs.FireTargets("fire_on_civdeath", activator,pcaller,USE_SET);
	}
}

void displayButtonInfo(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	//shows infos about the button the player walked up to
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	displayHudMessage(plr, pcaller.pev.netname); //message is stored in trigger's In-game Name value
}

//------------------------------------------------------------------------
//buy funcs
//------------------------------------------------------------------------

void buyCow(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= COW_COST)
	{
		//get the spawner and fire
		g_EntityFuncs.FireTargets("cow_spawner", activator, pcaller, USE_SET);
		
		addCash(COW_COST * -1);
		displayHudMessageAll("Bought a cow");
		
	}
	else
	{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	displayHudMessage(plr, "Could not afford cow!");
	}
}

void buyGrain(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= grainCost)
	{
		CBaseEntity@ new_grain;
		CBaseEntity@ world_grain;
		CBaseEntity@ silo_locator;
		
		@world_grain = g_EntityFuncs.FindEntityByTargetname(world_grain,"world_grain");
		@silo_locator = g_EntityFuncs.FindEntityByTargetname(silo_locator,"grain_silo_spawnloc");
		
		dictionary keys;
		Vector origin;
		
		origin = silo_locator.pev.origin;
		keys["origin"] = "" + origin.x + " " + origin.y + " " + origin.z;
		keys["model"] = string(world_grain.pev.model);
		keys["flags"] = string(world_grain.pev.flags);
		
		@new_grain = g_EntityFuncs.CreateEntity("func_grain", keys, true);
		new_grain.pev.model = world_grain.pev.model;
		new_grain.pev.flags = world_grain.pev.flags;
		new_grain.pev.spawnflags = world_grain.pev.spawnflags;
		new_grain.pev.targetname = "grain_obj";
		
		addCash(grainCost * -1);
		displayHudMessageAll("Bought grain");
	}
	else
	{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	displayHudMessage(plr, "Could not afford grain!");
	}

}

void buyFenceObj(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= FENCE_COST)
	{
		CBaseEntity@ new_fence;
		CBaseEntity@ world_fence;
		CBaseEntity@ fence_locator;
		
		if (pcaller.pev.skin == 0)
		{
			@world_fence = g_EntityFuncs.FindEntityByTargetname(world_fence,"x_world_fence");
		}
		else if (pcaller.pev.skin == 1)
		{
			@world_fence = g_EntityFuncs.FindEntityByTargetname(world_fence,"y_world_fence");
		}
		@fence_locator = g_EntityFuncs.FindEntityByTargetname(fence_locator,"ranchpro_spawnloc");
		
		dictionary keys;
		Vector origin;
		
		origin = fence_locator.pev.origin;
		keys["origin"] = "" + origin.x + " " + origin.y + " " + origin.z;
		keys["model"] = string(world_fence.pev.model);
		keys["flags"] = string(world_fence.pev.flags);
		
		@new_fence = g_EntityFuncs.CreateEntity("func_pushable_custom", keys, true);
		new_fence.pev.model = world_fence.pev.model;
		new_fence.pev.flags = world_fence.pev.flags;
		new_fence.pev.spawnflags = world_fence.pev.spawnflags;
		
		addCash(FENCE_COST * -1);
		displayHudMessageAll("Bought fence");
	}
	else
	{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	displayHudMessage(plr, "Could not afford fence!");
	}


}

void buyRespawner(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= grainCost)
	{
		CBaseEntity@ new_spawner;
		CBaseEntity@ lambda_locator;
		
		@lambda_locator = g_EntityFuncs.FindEntityByTargetname(lambda_locator,"respawn_point_spawnloc");
		
		dictionary keys;
		Vector origin;
		
		origin = lambda_locator.pev.origin;
		keys["origin"] = "" + origin.x + " " + origin.y + " " + origin.z;
		
		@new_spawner = g_EntityFuncs.CreateEntity("point_checkpoint", keys, true);
		
		addCash(RESPAWN_COST * -1);
		displayHudMessageAll("TEAM REVIVED!");
	}
	else
	{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	displayHudMessage(plr, "Could not afford team respawn!");
	}

}


void buyBarney(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	if (cash >= BARNEY_COST)
	{
		//get the spawner and fire
		g_EntityFuncs.FireTargets("barney_spawner", activator, pcaller, USE_SET);
		
		addCash(BARNEY_COST * -1);
		displayHudMessageAll("Hired a Security Guard");
		
	}
	else
	{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	displayHudMessage(plr, "Could not afford Security Guard!");
	}
}

void buyWeapon(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	
	int gun_cost = gun_costs[pcaller.pev.skin];
	string gun_name = gun_names[pcaller.pev.skin];

	if (cash >= gun_cost)
	{
		plr.GiveNamedItem(gun_name);
	
		addCash(gun_cost * -1);
		displayHudMessageAll("Bought a " + gun_name + " for $" + gun_cost);
	}
	else
	{
		displayHudMessage(plr, "Could not afford gun!");
	}
}

void buyAmmo(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	
	int ammo_cost = ammo_costs[pcaller.pev.skin];
	string ammo_name = ammo_names[pcaller.pev.skin];

	if (cash >= ammo_cost)
	{
		plr.GiveNamedItem(ammo_name);
	
		addCash(ammo_cost * -1);
		displayHudMessageAll("Bought a " + ammo_name + " for $" + ammo_cost);
	}
	else
	{
		displayHudMessage(plr, "Could not afford ammo!");
	}
}

void buyBuilding(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	//cost is stored in button skin
	//target is stored in button netname
	//objects to be removed upon pressing this button are stored in button message
	
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player

	int building_cost = pcaller.pev.skin;
	
	if (cash >= building_cost)
	{
		g_EntityFuncs.FireTargets(pcaller.pev.netname, activator, pcaller, USE_SET);
		addCash(building_cost * -1);
		displayHudMessageAll("Bought a " + pcaller.pev.netname + " for $" + building_cost);
		for(;;)
		{
			CBaseEntity@ ent;
			@ent = g_EntityFuncs.FindEntityByTargetname(ent, pcaller.pev.message);
			if (@ent != null)
			{
				g_EntityFuncs.Remove(ent);
			}
			else
			{
				break;
			}
		}
		g_EntityFuncs.Remove(pcaller);
	}
	else
	{
		displayHudMessage(plr, "Could not afford building!");
	}
}

void buyMachineBuilding(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	//cost is stored in button skin
	//target is stored in button netname
	//objects to be removed upon pressing this button are stored in button message
	//machine to be upgraded is stored in button body
	
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player

	int building_cost = pcaller.pev.skin;
	
	if (cash >= building_cost)
	{
		g_EntityFuncs.FireTargets(pcaller.pev.netname, activator, pcaller, USE_SET);
		addCash(building_cost * -1);
		displayHudMessageAll("Bought a " + pcaller.pev.netname + " for $" + building_cost);
		for(;;)
		{
			CBaseEntity@ ent;
			@ent = g_EntityFuncs.FindEntityByTargetname(ent, pcaller.pev.message);
			if (@ent != null)
			{
				g_EntityFuncs.Remove(ent);
			}
			else
			{
				break;
			}
		}
		g_EntityFuncs.Remove(pcaller);
		
		//give corresponding machine upgrade
		if (int(pcaller.pev.body) == 0)
		{
			meat_upgrader_level += 1;
		}
		else if (int(pcaller.pev.body) == 1)
		{
			milk_upgrader_level += 1;
		}
		else if (int(pcaller.pev.body) == 2)
		{
			grain_upgrader_level += 1;
		}
	}
	else
	{
		displayHudMessage(plr, "Could not afford building!");
	}
}

//------------------------------------------------------------
//day/night cycle related
//------------------------------------------------------------

void toggleDayNight()
{
	CBaseEntity@ trigger_night = null;
	@trigger_night = g_EntityFuncs.FindEntityByTargetname(trigger_night, "trigger_night");

	//using trigger_night as a dummy activator and pcaller
	if (night == 0)
	{
		g_EntityFuncs.FireTargets("trigger_night", trigger_night, trigger_night, USE_SET);
		night = 1;
	}
	else
	{
		g_EntityFuncs.FireTargets("trigger_day", trigger_night, trigger_night, USE_SET);
		night = 0;
		currentDay += 1;
		if (bankLoan > 0)
		{
			float bank_payment = (bankLoan * bankInterestRate) + BANK_FLAT_INTEREST_RATE;
		
			addCash(int(-bank_payment));
			displayHudMessageAll("Bank took $" + bank_payment + " in interest");
			//nextBankInterestDay = currentDay + BANK_INTEREST_TIME;
		}
		if (Math.Floor(currentDay/3) == currentDay/3)
		{
			g_EntityFuncs.FireTargets("hog_spawner_1", trigger_night, trigger_night, USE_SET);
			if (currentDay >= 9)
			{
				g_EntityFuncs.FireTargets("hog_spawner_2", trigger_night, trigger_night, USE_SET);
			}
			if (currentDay >= 15)
			{
				g_EntityFuncs.FireTargets("hog_spawner_3", trigger_night, trigger_night, USE_SET);
			}
		}
		if (Math.Floor(currentDay/2) == currentDay/2)
		{
			if (currentDay >= 15)
			{
				g_EntityFuncs.FireTargets("rival_farmer_spawner", trigger_night, trigger_night, USE_SET);
			}
		}
		if (cash < 0)
		{
			g_EntityFuncs.FireTargets("irs_spawner", trigger_night, trigger_night, USE_SET);
		
		}
	}
}

void takeOutLoan(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{
	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	
	if (bankLoan < BANK_MAX_LOAN)
	{
		addCash(BANK_LOAN_INCREMENT);
		bankLoan += BANK_LOAN_INCREMENT;
		displayHudMessageAll("Took out $" + BANK_LOAN_INCREMENT + ".. Current loan: $" + bankLoan);
	}
	else
	{
		displayHudMessage(plr, "Cannot take out more loan!");
	}
}

void payBackLoan(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
{

	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByName(activator.pev.netname, false); //find player
	
	if (cash >= BANK_LOAN_INCREMENT && bankLoan > 0)
	{
		addCash(-BANK_LOAN_INCREMENT);
		bankLoan -= BANK_LOAN_INCREMENT;
		displayHudMessageAll("Paid off $" + BANK_LOAN_INCREMENT + ".. Current loan: $" + bankLoan);
	}
	else if (bankLoan <= 0)
	{
		displayHudMessage(plr, "No loan to pay off!");
	}
	else if (cash < BANK_LOAN_INCREMENT)
	{
		displayHudMessage(plr, "Not enough money to pay loan!");
	}
}