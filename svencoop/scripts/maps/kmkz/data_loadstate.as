/* data_loadstate
Author: kmkz (e-mail: al_basualdo@hotmail.com )

*/

#include "data_global"
#include "data_savestate"
#include "game_spritetext"
#include "utils"

array<array<string>> loadstate_array={{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"}};
bool bloaded = false;

class CDataLoadstate : ScriptBaseEntity
{
	string spritemodel;
	string m_iszMaster;
	string mapname;
	string map_label;
	string loadtarget;
	CBaseEntity@ LoadEvote;
	
	void Spawn()
	{
		if (!LoadAllowed || CheckUniqueTargetname(@self)) {return;}
	
		SetUse(UseFunction(this.TriggerUse));
		
		if (string(self.pev.model).Length() != 0) {spritemodel = self.pev.model;} else {spritemodel = "sprites/gst/spritefont1.spr";}
				
		self.Precache();
		
		CreateSpritetext("_slots0_2", 1);
		CreateSpritetext("_slots3_5", 1);
		CreateSpritetext("_slots6_8", 1);
		CreateSpritetext("_slots9_11", 1);
		CreateSpritetext("_slots12_14", 1);
		CreateSpritetext("_slots15_17", 1);
		CreateSpritetext("_slots18_20", 1);
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
		uint saveslot;
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
		
		if( useType == USE_ON )
		{	
			g_EngineFuncs.ChangeLevel(mapname);
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
		
		uint slot_sufix_lenght =string(pCaller.pev.targetname).Length();
		string slot_sufix = string(pCaller.pev.targetname).SubString(slot_sufix_lenght-17,slot_sufix_lenght-1);
		if (slot_sufix == "_slots0_2_button1"){saveslot = 0;} else
		if (slot_sufix == "_slots0_2_button2"){saveslot = 1;} else
		if (slot_sufix == "_slots0_2_button3"){saveslot = 2;} else
		if (slot_sufix == "_slots3_5_button1"){saveslot = 3;} else
		if (slot_sufix == "_slots3_5_button2"){saveslot = 4;} else
		if (slot_sufix == "_slots3_5_button3"){saveslot = 5;} else
		if (slot_sufix == "_slots6_8_button1"){saveslot = 6;} else
		if (slot_sufix == "_slots6_8_button2"){saveslot = 7;} else
		if (slot_sufix == "_slots6_8_button3"){saveslot = 8;} else
		if (slot_sufix == "slots9_11_button1"){saveslot = 9;} else
		if (slot_sufix == "slots9_11_button2"){saveslot = 10;} else
		if (slot_sufix == "slots9_11_button3"){saveslot = 11;} else
		if (slot_sufix == "lots12_14_button1"){saveslot = 12;} else
		if (slot_sufix == "lots12_14_button2"){saveslot = 13;} else
		if (slot_sufix == "lots12_14_button3"){saveslot = 14;} else
		if (slot_sufix == "lots15_17_button1"){saveslot = 15;} else
		if (slot_sufix == "lots15_17_button2"){saveslot = 16;} else
		if (slot_sufix == "lots15_17_button3"){saveslot = 17;} else
		if (slot_sufix == "lots18_20_button1"){saveslot = 18;} else
		if (slot_sufix == "lots18_20_button2"){saveslot = 19;} else
		if (slot_sufix == "lots18_20_button3"){saveslot = 20;}
		
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
		
		DataGlobalReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+ "_global_slot" + saveslot + ".txt");
		DataGlobalWriteLineToFile("scripts/maps/store/dataglobal_"+string(self.pev.netname)+".txt");
					
		if(!g_EngineFuncs.IsMapValid(mapname))
		{
			g_EngineFuncs.ServerPrint("Can't load: "+mapname+" doesn't exist!");
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_load_failed", null, @self, USE_ON, 0.0f, 0.0f);
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
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "5");
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
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget1", self.pev.targetname);
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget2", self.pev.targetname);
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget3", self.pev.targetname);
			
			Eslots.pev.message = "Choose a slot to load";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage4_english", "next");
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "Elige un slot para cargar"); 
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage4_spanish", "siguiente");
			
			if 		(slots == "_slots0_2"){for ( uint I = 0; I < 3; I++ ){SetSlot(Eslots,int(I));}}
			else if (slots == "_slots3_5"){for ( uint I = 3; I < 6; I++ ){SetSlot(Eslots,int(I));}}			
			else if (slots == "_slots6_8"){for ( uint I = 6; I < 9; I++ ){SetSlot(Eslots,int(I));}}
			else if (slots == "_slots9_11"){for ( uint I = 9; I < 12; I++ ){SetSlot(Eslots,int(I));}}
			else if (slots == "_slots12_14"){for ( uint I = 12; I < 15; I++ ){SetSlot(Eslots,int(I));}}			
			else if (slots == "_slots15_17"){for ( uint I = 15; I < 18; I++ ){SetSlot(Eslots,int(I));}}
			else if (slots == "_slots18_20"){for ( uint I = 18; I < 21; I++ ){SetSlot(Eslots,int(I));}}	
		
		}
		else if (intmode == 2 ) //trigger button
		{
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "cargar");
			Eslots.pev.message = "load";
			
			Eslots.pev.targetname = string(self.pev.targetname) + "_trigger_button";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget1", string(self.pev.targetname) +"_slots0_2");
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
		g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage" + string((slot%3)+1) + "_english", slot_name + slotn + " map: " + slot_map);
		g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage" + string((slot%3)+1) + "_spanish", slot_name + slotn + " mapa: " + slot_map);
	
		if(slot/3 == 0){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots3_5");}
		if(slot/3 == 1){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots6_8");}
		if(slot/3 == 2){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots9_11");}
		if(slot/3 == 3){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots12_14");}
		if(slot/3 == 4){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots15_17");}
		if(slot/3 == 5){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots18_20");}
		if(slot/3 == 6){g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget4", string(self.pev.targetname) +"_slots0_2");}
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

void RegisterDataLoadstate()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CDataLoadstate", "data_loadstate");
}