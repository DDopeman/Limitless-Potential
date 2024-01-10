/* data_savestate
Author: kmkz (e-mail: al_basualdo@hotmail.com )

*/

#include "data_global"
#include "game_spritetext"
#include "utils"

array<array<string>> savestate_array =
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
{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"}
}; // initalizing to avoid errors 

class CDataSavestate : ScriptBaseEntity
{
	string spritemodel;
	string m_iszMaster;
	string mapname;
	string maplabel;
	CBaseEntity@ Evote;
	uint saveslot;
	CBaseEntity@ CEslots1;
	CBaseEntity@ CEslots2;
	CBaseEntity@ CEslots3;
	CBaseEntity@ CEslots4;
	CBaseEntity@ CEslots5;
	CBaseEntity@ CEslots6;
	CBaseEntity@ CEslots7;
	
	void Spawn()
	{
		if (!SaveAllowed ) {return;}
			
		SetUse(UseFunction(this.TriggerUse));
		
		if (string(self.pev.model).Length() != 0) {spritemodel = self.pev.model;} else {spritemodel = "sprites/gst/spritefont1.spr";}
				
		self.Precache();
		self.pev.team = 5473;
		
		CreateSpritetext("saved", 0);
		CreateSpritetext("_slots0_2", 1);
		CreateSpritetext("_slots3_5", 1);
		CreateSpritetext("_slots6_8", 1);
		CreateSpritetext("_slots9_11", 1);
		CreateSpritetext("_slots12_14", 1);
		CreateSpritetext("_slots15_17", 1);
		CreateSpritetext("_slots18_20", 1);
		CreateSpritetext("", 2);
		CreateSpritetext("save_in_progress", 0);
		CreateSpritetext("vote_failed", 0);
				
		@Evote = g_EntityFuncs.CreateEntity( "trigger_vote", null,  false);
		
		self.Use(null, null, USE_SET ,0.5); 			// initialize the entity
	}
	
	void Precache() 
	{
		g_Game.PrecacheModel( spritemodel );
	
		BaseClass.Precache();
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "map_label_english")
		{
			if (iLanguage == LANGUAGE_ENGLISH) 
			{
				maplabel = szValue;
			}
			return true;
		}
		else if(szKey == "map_label_spanish")
		{
			if (iLanguage == LANGUAGE_SPANISH) 
			{
				maplabel = szValue;
			}
			return true;
		}
		else
		{
			return BaseClass.KeyValue( szKey, szValue );
		}
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
			return;
		}
		
		if( useType == USE_ON )
		{	
			SavestateWriteLineToFile("scripts/maps/store/datasave_"+string(self.pev.netname)+"_save.txt");
			SavestateReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+"_save.txt");
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_save_vote" , null, @self, USE_OFF, 0.0f, 0.0f);
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_saved" , null, @self, USE_ON, 0.0f, 0.1f);
			CleanRelays();
			
			string series = string(self.pev.netname);
			
			CBaseEntity@ update_save_entity = g_EntityFuncs.FindEntityByString(@update_save_entity,"netname", series);
			
			while(@update_save_entity !is null)
			{
				UpdateSlotText(@update_save_entity, saveslot);
				update_save_entity.pev.netname = "data_savestate_updating";
				@update_save_entity = g_EntityFuncs.FindEntityByString(@update_save_entity,"netname", series);
			}
			
			@update_save_entity = g_EntityFuncs.FindEntityByString(@update_save_entity,"netname","data_savestate_updating");
			while(@update_save_entity !is null)
			{
				
				if(@update_save_entity !is null)
				{
					update_save_entity.pev.netname = series;
				}
				
				@update_save_entity = g_EntityFuncs.FindEntityByString(@update_save_entity,"netname", "data_savestate_updating");
				
			}
			
			self.pev.nextthink = g_Engine.time + 5.0f;
			
			return;
		}
		
		if( useType == USE_OFF)
		{	
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_vote_failed" , null, @self, USE_ON, 0.0f, 0.0f);
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_save_vote" , null, @self, USE_OFF, 0.0f, 0.0f);
			CleanRelays();
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
		
		CBaseEntity@ saved_entity = g_EntityFuncs.FindEntityByTargetname(@saved_entity, string(self.pev.targetname) + "_saved");
		g_EntityFuncs.DispatchKeyValue(saved_entity.edict(), "message_spanish", "guardado en slot " + string(saveslot) + "/n/nmapa: " + string(self.pev.message)+ "/n/nserie: " + string(self.pev.netname));
		saved_entity.pev.message = "saved slot " + string(saveslot) + "/n/nmap: " + string(self.pev.message) + "/n/nseries: " + string(self.pev.netname);
		
		mapname = string(self.pev.message);
			
		if(!g_EngineFuncs.IsMapValid(mapname))
		{
			g_EngineFuncs.ServerPrint("Can't save: "+mapname+" doesn't exist!");
			self.pev.nextthink = g_Engine.time + 5.0f;
			return;
		}
		
		array<string> str_array = {"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"}; // modify the slot chosen data
		if (string(self.pev.message).Length() != 0) str_array[0] = self.pev.message; // map to load
		if (string(self.pev.target ).Length() != 0) str_array[1] = self.pev.target; // trigger on map start after loading
		if (				maplabel.Length() != 0) str_array[2] = maplabel; // map label
		/*str_array[3] = "empty";
		str_array[4] = "empty";
		str_array[5] = "empty";
		str_array[6] = "empty";
		str_array[7] = "empty";
		str_array[8] = "empty";
		str_array[9] = "empty";*/
		
		SavestateReadFromFileToArray("scripts/maps/store/datasave_"+string(self.pev.netname)+"_save.txt"); // load the data from file
		DataGlobalReadFromFileToArray("scripts/maps/store/dataglobal_"+string(self.pev.netname)+".txt");
		DataGlobalWriteLineToFile("scripts/maps/store/datasave_"+string(self.pev.netname)+ "_global_slot" + saveslot + ".txt");
			
		savestate_array[saveslot] = str_array;
		
		if (SaveVoteAlowed)
		{
			CBaseEntity@ Erelayyes = g_EntityFuncs.CreateEntity( "trigger_relay", null,  false);
			Erelayyes.pev.targetname = string(self.pev.targetname) + "_vote_relay_yes";
			Erelayyes.pev.target = self.pev.targetname;
			g_EntityFuncs.DispatchKeyValue(Erelayyes.edict(), "triggerstate", "1");
							
			CBaseEntity@ Erelayno = g_EntityFuncs.CreateEntity( "trigger_relay", null,  false);
			Erelayno.pev.targetname = string(self.pev.targetname) + "_vote_relay_no";
			Erelayno.pev.target = self.pev.targetname;
			g_EntityFuncs.DispatchKeyValue(Erelayno.edict(), "triggerstate", "0");
								
			g_EntityFuncs.SetOrigin( Evote, self.pev.origin );
			Evote.pev.targetname = string(self.pev.targetname) + "_vote";
			Evote.pev.target = string(self.pev.targetname)+"_vote_relay_yes";
			Evote.pev.netname = string(self.pev.targetname)+"_vote_relay_no";
			Evote.pev.noise = string(self.pev.targetname)+"_vote_relay_no";
			Evote.pev.health = SaveVotePercentage;
			Evote.pev.frags = SaveVoteTime;
			if (iLanguage == LANGUAGE_SPANISH) {Evote.pev.message = "Guardar en slot "+string(saveslot)+"?" + maplabel;g_EntityFuncs.DispatchKeyValue(Evote.edict(), "m_iszYesString", "si");} else 
			if (iLanguage == LANGUAGE_ENGLISH) {Evote.pev.message = "Save slot "+string(saveslot)+"? " + maplabel;}
			g_EntityFuncs.DispatchSpawn( Evote.edict() );
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_vote" , null, @self, USE_ON, 0.0f, 0.5f);
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_save_vote" , null, @self, USE_ON, 0.0f, 0.5f);
		}
		else
		{
			SavestateWriteLineToFile("scripts/maps/store/datasave_"+string(self.pev.netname)+"_save.txt");
			g_EntityFuncs.FireTargets(string(self.pev.targetname)+ "_saved" , null, @self, USE_ON, 0.0f, 0.0f);
			self.pev.nextthink = g_Engine.time + 5.0f;
		}
	}
	
	void Think()
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
		g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget1", self.pev.targetname);
		
		if (intmode == 0 ) //saved! text
		{
			if (slots =="saved")
			{
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "guardado en slot " + string(saveslot) + "/n/nmapa: " + string(self.pev.message)+ "/n/nserie: " + string(self.pev.netname));
				Eslots.pev.message = "saved slot " + string(saveslot) + "/n/nmap: " + string(self.pev.message) + "/n/nseries: " + string(self.pev.netname);
				Eslots.pev.targetname = string(self.pev.targetname) + "_saved";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "5");
			}
			
			if (slots =="save_failed")
			{
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "guardado fallido!"); 
				Eslots.pev.message = "save failed!"; 
				Eslots.pev.targetname = string(self.pev.targetname) + "_save_failed";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "5");
			}
			
			if (slots =="vote_failed")
			{
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "¡votacion fallida!"); 
				Eslots.pev.message = "vote failed!"; 
				Eslots.pev.targetname = string(self.pev.targetname) + "_vote_failed";
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "holdtime", "5");
			}
			
			if (slots =="save_in_progress")
			{
				g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "votacion de/nguardado en progreso"); 
				Eslots.pev.message = "save vote/nin progress"; 
				Eslots.pev.targetname = string(self.pev.targetname) + "_save_vote";
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
			
			Eslots.pev.message = "Choose a slot to save";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage4_english", "next");
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "Elige un slot donde guardar"); 
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage4_spanish", "siguiente");
			
			if 		(slots == "_slots0_2"){for ( uint I = 0; I < 3; I++ ){SetSlot(@Eslots,int(I));}}
			else if (slots == "_slots3_5"){for ( uint I = 3; I < 6; I++ ){SetSlot(@Eslots,int(I));}}			
			else if (slots == "_slots6_8"){for ( uint I = 6; I < 9; I++ ){SetSlot(@Eslots,int(I));}}
			else if (slots == "_slots9_11"){for ( uint I = 9; I < 12; I++ ){SetSlot(@Eslots,int(I));}}
			else if (slots == "_slots12_14"){for ( uint I = 12; I < 15; I++ ){SetSlot(@Eslots,int(I));}}			
			else if (slots == "_slots15_17"){for ( uint I = 15; I < 18; I++ ){SetSlot(@Eslots,int(I));}}
			else if (slots == "_slots18_20"){for ( uint I = 18; I < 21; I++ ){SetSlot(@Eslots,int(I));}}						
		}
		else if (intmode == 2 ) //trigger button
		{
			Eslots.pev.message = "save";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "message_spanish", "guardar" );
			Eslots.pev.targetname = string(self.pev.targetname) + "_trigger_button";
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optiontarget1", string(self.pev.targetname) +"_slots0_2");
			g_EntityFuncs.DispatchKeyValue(Eslots.edict(), "optionmessage1", string(self.pev.targetname) +"_slots0_2");
		}
		
		g_EntityFuncs.DispatchSpawn( Eslots.edict() );
	}
	
	void SetSlot (CBaseEntity@ Eslots, int slot)
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
		
		if(slot/3 == 0){@CEslots1 = @Eslots;}
		if(slot/3 == 1){@CEslots2 = @Eslots;}
		if(slot/3 == 2){@CEslots3 = @Eslots;}
		if(slot/3 == 3){@CEslots4 = @Eslots;}
		if(slot/3 == 4){@CEslots5 = @Eslots;}
		if(slot/3 == 5){@CEslots6 = @Eslots;}
		if(slot/3 == 6){@CEslots7 = @Eslots;}
		
	}
	
	void UpdateSlotText(CBaseEntity@ UpdateEntity, int saveslot)
	{
		string slot_map = "";
		string slot_name = "slot "; 		if(iLanguage == LANGUAGE_SPANISH) slot_name = "slot ";
		string slotn = string(saveslot);	
		
		if( maplabel != "")
		{
			slot_map = maplabel;			
		}
		else 
		{
			slot_map = string(UpdateEntity.pev.message);
		}
		
		if 	   (saveslot/3 == 0){@CEslots1 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots0_2");g_EntityFuncs.DispatchKeyValue(CEslots1.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
		else if(saveslot/3 == 1){@CEslots2 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots3_5");g_EntityFuncs.DispatchKeyValue(CEslots2.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
		else if(saveslot/3 == 2){@CEslots3 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots6_8");g_EntityFuncs.DispatchKeyValue(CEslots3.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
		else if(saveslot/3 == 3){@CEslots4 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots9_11");g_EntityFuncs.DispatchKeyValue(CEslots4.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
		else if(saveslot/3 == 4){@CEslots5 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots12_14");g_EntityFuncs.DispatchKeyValue(CEslots5.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
		else if(saveslot/3 == 5){@CEslots6 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots15_17");g_EntityFuncs.DispatchKeyValue(CEslots6.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
		else if(saveslot/3 == 6){@CEslots7 = g_EntityFuncs.FindEntityByTargetname( @UpdateEntity, string(UpdateEntity.pev.targetname) +"_slots18_20");g_EntityFuncs.DispatchKeyValue(CEslots7.edict(), "optionmessage" + string((saveslot%3)+1)+ "_english", slot_name + slotn + " map: " + slot_map);}
	}
	
	void CleanRelays()
	{
		CBaseEntity@ relay_entity_yes = (g_EntityFuncs.FindEntityByTargetname( @relay_entity_yes, string(self.pev.targetname) + "_vote_relay_yes"));
		if(@relay_entity_yes != null ) g_EntityFuncs.Remove( relay_entity_yes );
		CBaseEntity@ relay_entity_no = (g_EntityFuncs.FindEntityByTargetname( @relay_entity_no, string(self.pev.targetname) + "_vote_relay_no"));
		if(@relay_entity_no != null ) g_EntityFuncs.Remove( relay_entity_no );
	}
}

void SavestateWriteLineToFile(string filename)
{
	string StringToWrite;
	array <string> str_array = {"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"};
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
				StringToWrite = StringToWrite+sLine+"\n";
			}
		}
	}
	catch{}
	
	File@ file= g_FileSystem.OpenFile(filename, OpenFile::WRITE);
	if(file !is null && file.IsOpen()) //delete the file and write its values again
	{
		for ( uint I = 0; I < 21; I++ )
		{
		str_array = savestate_array[I];
			for ( uint K = 0; K < 10; K++ )
			{
				StringToWrite = str_array[K];
				//g_EngineFuncs.ServerPrint("[str_array[K] : "+ str_array[K] + "\n");
				file.Write( StringToWrite+"\n");
			}
		}
		
		file.Close();
	}
}

void SavestateReadFromFileToArray(string filename)
{
	File@ file = g_FileSystem.OpenFile(filename, OpenFile::READ);
	uint i = 0;
	uint j = 0;
	uint k = 0;
	array<string> str_array = {"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"};
	/*if(file is null)
	{
		g_EngineFuncs.ServerPrint("state entity: null file" + "\n");
	}*/
	if(file !is null && file.IsOpen())
	{
		while(!file.EOFReached())
		{
			string sLine;
			file.ReadLine(sLine);
			//fix for linux
			string sFix = sLine.SubString(sLine.Length()-1,1);
			if(sFix == " " || sFix == "\n" || sFix == "\r" || sFix == "\t")
				sLine = sLine.SubString(0, sLine.Length()-1);
			if(sLine.SubString(0,1) == "#" || sLine.IsEmpty())
			{
				continue;
			}
			//Server console (developer 0)
			
			//Server console (developer 1)
			//g_Game.AlertMessage( at_console, "[read map storage] : "+sLine+"\n" );
			//g_Game.AlertMessage( at_console, "[read map storage] : "+j+"\n" );
			
			str_array[k] = sLine;
					
			i++;
			if (k == 9) 
			{
				k = 0;
				savestate_array[j] = str_array;
				//g_EngineFuncs.ServerPrint("[str_array[k] : "+ str_array[k] + "\n");
				j++;
			}
			else
			{
				k++;
			}
		}
		file.Close();
	}
}

void RegisterDataSavestate()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CDataSavestate", "data_savestate");
}