/* func_loadstate
Author: kmkz (e-mail: al_basualdo@hotmail.com )

*/

#include "func_global"
#include "func_savestate"
#include "game_spritetext"
#include "utils"

array<array<string>> loadstate_array=
{
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"}
};
bool bloaded = false;

class CFuncLoadstate : ScriptBaseEntity
{
	string spritemodel;
	string m_iszMaster;
	string mapname;
	string map_label;
	string loadtarget;
	CBaseEntity@ LoadEvote;
	uint saveslot;
	
	void Spawn()
	{
		if (!LoadAllowed || CheckUniqueTargetname(@self)) {return;}
	
		SetUse(UseFunction(this.TriggerUse));
		
		if (string(self.pev.model).Length() != 0) {spritemodel = self.pev.model;} else {spritemodel = "sprites/gst/spritefont1.spr";}
				
		self.Precache();
		
		for (uint J = 0 ;J <ISlotsPages;J++){CreateSpritetext("_slots" +string(J*ISlotsPerPage)+"_"+ string((J+1)*ISlotsPerPage-1), 1);}
		CreateSpritetext("", 2);
		CreateSpritetext("load_in_progress", 0);
		CreateSpritetext("vote_failed", 0);
		CreateSpritetext("load_failed", 0);
		
		@LoadEvote = g_EntityFuncs.CreateEntity( "trigger_vote", null,  false);
		
		self.Use(null, null, USE_SET ,0.0); 			// initialize the entity
		SetThink(ThinkFunction(this.ThinkReset));
	}
	
	void Precache() 
	{
		g_Game.PrecacheModel( spritemodel );
	
		BaseClass.Precache();
	}
	
	void TriggerUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		
		if( !m_iszMaster.IsEmpty() && !g_EntityFuncs.IsMasterTriggered( m_iszMaster, self ) )
		{	
			return;
		}
		
		if( useType == USE_SET )
		{	
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_trigger_button" , null, @self, USE_ON, 0.0f, 0.5f);
			
			if (bloaded == false) 
			{	
				loadtarget = LoadstateReadTargetFromFile("scripts/maps/store/dataload_target_.txt");
				g_Scheduler.SetTimeout( "DestroyFile", 2, "scripts/maps/store/dataload_target_.txt");		
				g_EntityFuncs.FireTargets( loadtarget, null, null, USE_ON, 0.0f, 1.0f);
				bloaded = true; 
			}	
			return;
		}
		
		if( useType == USE_OFF)
		{	
			CleanRelays();
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_vote_failed" , null, @self, USE_ON, 0.0f, 0.0f);
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_load_vote" , null, @self, USE_OFF, 0.0f, 0.0f);
			self.pev.nextthink = g_Engine.time + 5.0f;
			
			return;
		}		
		
				
		if( useType == USE_ON )
		{	
			FuncGlobalReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+ "_global_slot" + saveslot + ".txt");
			FuncGlobalWriteLineToFile("scripts/maps/store/dataglobal_"+string(self.pev.netname)+".txt");
			g_EngineFuncs.ChangeLevel(mapname);
			return;
		}
		
		uint J = 0;
		uint slot_sufix_lenght =string(pCaller.pev.targetname).Length();
		string slot_sufix = string(pCaller.pev.targetname).SubString(string(self.pev.targetname).Length(),slot_sufix_lenght-1);
		
		for (J; J<ISlotsPages*ISlotsPerPage;J++)
		{
			if (slot_sufix == "_slots" + string(J-J%ISlotsPerPage) + "_" + string(J-J%ISlotsPerPage+ISlotsPerPage-1) + "_button" + string(J%ISlotsPerPage+1))
			{
				saveslot = J;
				break;
			}
		}
		
		SavestateReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+".txt");
		array<string> str_array = {"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"};
		str_array = savestate_array[saveslot];
		
		mapname = str_array[0]; // map to load
		loadtarget = str_array[1]; // trigger on map start after loading
		map_label = str_array[2]; // map label
		//"" = str_array[3];
		//"" = str_array[4];
		//"" = str_array[5];
		//"" = str_array[6];
		//"" = str_array[7];
		//"" = str_array[8];
		//"" = str_array[9];
		
		if(!g_EngineFuncs.IsMapValid(mapname))
		{
			g_EngineFuncs.ServerPrint("Can't load: "+mapname+" doesn't exist!");
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_load_failed", null, @self, USE_ON, 0.0f, 0.0f);
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_load_failed", null, @self, USE_ON, 0.0f, 5.0f);
			self.pev.nextthink = g_Engine.time + 5.0f;
			return;
		}
		
		LoadstateWriteTargetToFile("scripts/maps/store/dataload_target_.txt", loadtarget);
		
		if (LoadVoteAlowed)
		{
			string slot_map = mapname;
			if(str_array[2] != "empty"){slot_map = str_array[2];}
			
			CBaseEntity@ Erelayyes = g_EntityFuncs.CreateEntity( "trigger_relay", null,  false);
			Erelayyes.pev.targetname = string(self.pev.targetname) + "_vote_relay_yes";
			Erelayyes.pev.target = self.pev.targetname;
			g_EntityFuncs.DispatchKeyValue(Erelayyes.edict(), "triggerstate", "1");
				
			CBaseEntity@ Erelayno = g_EntityFuncs.CreateEntity( "trigger_relay", null,  false);
			Erelayno.pev.targetname = string(self.pev.targetname) + "_vote_relay_no";
			Erelayno.pev.target = self.pev.targetname;
			g_EntityFuncs.DispatchKeyValue(Erelayno.edict(), "triggerstate", "0");
					
			g_EntityFuncs.SetOrigin( LoadEvote, self.pev.origin );
			LoadEvote.pev.targetname = string(self.pev.targetname) + "_vote";
			LoadEvote.pev.target = string(self.pev.targetname)+"_vote_relay_yes";
			LoadEvote.pev.netname = string(self.pev.targetname)+"_vote_relay_no";
			LoadEvote.pev.noise = string(self.pev.targetname)+"_vote_relay_no";
			LoadEvote.pev.health = LoadVotePercentage;
			LoadEvote.pev.frags = LoadVoteTime;
			if (iLanguage == LANGUAGE_SPANISH) {LoadEvote.pev.message = "¿Cargar en slot "+string(saveslot)+"?";g_EntityFuncs.DispatchKeyValue(LoadEvote.edict(), "m_iszYesString", "si");} else 
			if (iLanguage == LANGUAGE_ENGLISH) {LoadEvote.pev.message = "load slot "+string(saveslot)+"?: " + slot_map;}
			g_EntityFuncs.DispatchSpawn( LoadEvote.edict() );
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_vote" , null, @self, USE_ON, 0.0f, 0.5f);
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_load_vote" , null, @self, USE_ON, 0.0f, 0.5f);
		}
		else
		{
			g_EngineFuncs.ChangeLevel(mapname);
			FuncGlobalReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+ "_global_slot" + saveslot + ".txt");
			FuncGlobalWriteLineToFile("scripts/maps/store/dataglobal_"+string(self.pev.netname)+".txt");
		}
		
	}
	
	void ThinkReset() //
	{
		self.Use(null, @self, USE_SET ,0.0); // initialize entity
	}
	
	void CreateSpritetext(string slots, int intmode)
	{
		CBaseEntity@ Eslots = g_EntityFuncs.CreateEntity( "game_spritetext", null,  false);
		g_EntityFuncs.SetOrigin( Eslots, self.pev.origin );
		Eslots.pev.model = "sprites/gst/spritefont1.spr";
		Eslots.pev.target = "!self";
		Eslots.pev.angles = self.pev.angles;
		Eslots.pev.scale = self.pev.scale;
		Eslots.pev.armorvalue = intmode;
		Eslots.pev.rendermode = 5;
		Eslots.pev.renderamt = 255;
		Eslots.pev.renderfx = 0;
		Eslots.pev.frags = 16;
		Eslots.pev.dmg = 1;
		
		if (intmode == 0 ) //load vote text
		{
			if (slots =="load_failed")
			{
				Eslots.pev.message = "load failed!"; 
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "carga fallida!");
				Eslots.pev.targetname = string(self.pev.targetname) + "_load_failed";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "-1");
			}
			
			if (slots =="vote_failed")
			{
				Eslots.pev.message = "vote failed!"; 
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "¡votacion fallida!"); 
				Eslots.pev.targetname = string(self.pev.targetname) + "_vote_failed";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "5");
			}
			
			if (slots == "load_in_progress")
			{
				Eslots.pev.message = "load vote/nin progress!";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "votacion en progreso");
				Eslots.pev.targetname = string(self.pev.targetname) + "_load_vote";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "-1");
			}
		}
		else if (intmode == 1 ) //options
		{
			SavestateReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+"_save.txt");
			array <string> slot_array = {"10","slot","12","13","14","15","16","17","18","19"};
			string slot_map;
				
			Eslots.pev.targetname = string(self.pev.targetname) + slots;
			
			for (uint I = 1;I<ISlotsPerPage+1;I++)g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget" +string(I), self.pev.targetname);
			
			Eslots.pev.message = "Choose a slot to load";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage"+ string(ISlotsPerPage+1)+"_english", "next");
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "Elige un slot donde guardar"); 
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage"+ string(ISlotsPerPage+1)+"_spanish", "siguiente");
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "-1");
			
			uint J = 0;
			for (uint J = 0;J<(ISlotsPages);J++)
			{
				if 	(slots == "_slots"+string(J*ISlotsPerPage)+"_"+string((J+1)*ISlotsPerPage-1))
				{
					for ( uint I = J; I < (J+1)*(ISlotsPerPage); I++ )
					{
						SetSlot(@Eslots,int(I));
					}
					break;
				}
			}	
		
		}
		else if (intmode == 2 ) //trigger button
		{
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "cargar");
			Eslots.pev.message = "load";
			
			Eslots.pev.targetname = string(self.pev.targetname) + "_trigger_button";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget1", string(self.pev.targetname) +"_slots0_"+string(ISlotsPerPage-1));
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "-1");
		}
		g_EntityFuncs.DispatchSpawn( Eslots.edict() );
	}
	
	void SetSlot (CBaseEntity@ Eslots, int slot) // set displayed slots text information
	{
		SavestateReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+"_save.txt");
		array <string> slot_array = {"10","slot","12","13","14","15","16","17","18","19"};
		string slot_map;
		string slot_name = "slot ";
		string slotn = string(slot);
	
		slot_array = savestate_array[slot]; 
		
		/*if(slot == 0)
		{
			if( iLanguage == LANGUAGE_ENGLISH) slot_name = "autosave";
			if( iLanguage == LANGUAGE_SPANISH) slot_name = "autoguardado";
			slotn = "";
		}*/
		
		if(slot_array[2] != "empty")
		{
			slot_map = slot_array[2];
		}
		else if(g_EngineFuncs.IsMapValid(slot_array[0]))
		{
			slot_map = slot_array[0];
		}
		else
		{
			if( iLanguage == LANGUAGE_ENGLISH) slot_map = "empty slot"; else
			if( iLanguage == LANGUAGE_SPANISH) slot_map = "vacio";
		} 
		g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage" + string((slot%ISlotsPerPage)+1) + "_english", slot_name + slotn + " map: " + slot_map);
		g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage" + string((slot%ISlotsPerPage)+1) + "_spanish", slot_name + slotn + " mapa: " + slot_map);
		
		uint J = 0;
		
		if(slot/ISlotsPerPage == ISlotsPages-1)
		{
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget"+ string(ISlotsPerPage+1), string(self.pev.targetname) +"_slots0_"+string(ISlotsPerPage-1));
		}
		else for (J ;J<ISlotsPages;J++) 
		{
			if(slot/ISlotsPerPage == J) 
			{
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget"+ string(ISlotsPerPage+1), string(self.pev.targetname) +"_slots"+string((J+1)*ISlotsPerPage)+"_"+string((J+2)*ISlotsPerPage-1));
				break;
			}
		}

		if(slot/ISlotsPerPage == ISlotsPages){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), string(ISlotsPerPage+1), string(self.pev.targetname) +"_slots"+string((J+1)*ISlotsPerPage)+"_"+string((J+2)*ISlotsPerPage-1));}
	}
	
	void CleanRelays() // remove vote relays
	{
		CBaseEntity@ relay_entity_yes = (g_EntityFuncs.FindEntityByTargetname( @relay_entity_yes, string(self.pev.targetname) + "_vote_relay_yes"));
		if(@relay_entity_yes != null ) g_EntityFuncs.Remove( relay_entity_yes );
		CBaseEntity@ relay_entity_no = (g_EntityFuncs.FindEntityByTargetname( @relay_entity_no, string(self.pev.targetname) + "_vote_relay_no"));
		if(@relay_entity_no != null ) g_EntityFuncs.Remove( relay_entity_no );
	}	
}

void LoadstateWriteTargetToFile(string filename, string Ltarget)
{
	try 
	{
		File@ file = g_FileSystem.OpenFile(filename, OpenFile::READ);
		if(file !is null && file.IsOpen())
		{
			while(!file.EOFReached())
			{
				string sLine;
				file.ReadLine(sLine);
				if(sLine.SubString(0,1) == "#" || sLine.IsEmpty())
					continue;
				Ltarget = Ltarget+sLine+"\n";
			}
		}
	}
	catch{}
	
	File@ file= g_FileSystem.OpenFile(filename, OpenFile::WRITE);
	if(file !is null && file.IsOpen()) //delete the file and write its values again
	{
	file.Write( Ltarget+"\n");
	file.Close();
	}
}

string LoadstateReadTargetFromFile(string filename)
{
	string Ltarget;
	File@ file = g_FileSystem.OpenFile(filename, OpenFile::READ);
	if(file !is null && file.IsOpen())
	{
		string sLine;
		file.ReadLine(sLine);
		Ltarget = sLine;
		
		file.Close();
		
	}
	return Ltarget;
}

void DestroyFile(string filename)
{
	File@ file = g_FileSystem.OpenFile(filename, OpenFile::WRITE);
	if(file !is null && file.IsOpen())
	{
		file.Remove();
	}
}

void RegisterFuncLoadstate()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CFuncLoadstate", "func_loadstate");
}