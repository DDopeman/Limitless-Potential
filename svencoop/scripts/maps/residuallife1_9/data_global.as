/* data_global: alternative to env_global.
Author: kmkz (e-mail: al_basualdo@hotmail.com )
this entity loads its state value from a file and that can be used to be passed across diferents maps.
---------------------------------------
targetname: "entity name"
Name of the entity. When triggered will switch on or off. 
netname: "global label"
this label tells how it will be stored on the file. For now this need to be prefixed with global and add a
3 digit number that will differenciate it from other global vars. Example valid labels: global004,global523,global097.
if the label is named !reset it will initialize all the states to off.
health: "global state"
this will store the state (on/off) of the entity. 0 means off and 1 means on. You will need something
like a trigger_condition to compare with the data_global.
---------------------------------------
flags:
none
---------------------------------------
note: if the sequence name is !none then no sequence will be played and the entity will stay frozen.
*/

array<int> file_array(50);

class CDataGlobal : ScriptBaseEntity
{
	float global_state;
	string global_name;	
	void Spawn()
	{
		SetUse(UseFunction(this.TriggerUse));
		self.Use(null, null, USE_SET ,0.0); 			// load the values at map start 
	}
	
	void TriggerUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		int a;
		int b;
		int c;
		int d;
		
		global_name = self.pev.netname; 
		
		if (self.pev.netname == "!reset") // reset to 0 all global
		{
			for ( uint I = 0; I < 50; I++ )
			{
				file_array[I] = 0;
			}
			WriteLineToFile();
			ReadFromFileToArray();
			return;
		}
		
		if (useType == USE_SET) // load state value
		{
			ReadFromFileToArray();
			a = int( global_name[8] - 48); // -48 is a weird fix to string to int conversion
			b = 10 * int( global_name[7] - 48);
			c = 100 * int( global_name[6] - 48);
			d = a+b+c;							// d is the var part of the netname keyvalue. In global017 d= 17.
			global_state = float(file_array[d]); 
			self.pev.health = global_state;
			return;
		}
		
		global_state = self.pev.health;
		
		if (useType == USE_OFF)
		{
			global_state = 0;
			self.pev.health = 0;
			a = int( global_name[8] - 48); 
			b = 10 * int( global_name[7] - 48);
			c = 100 * int( global_name[6] - 48);
			d = a+b+c;
			file_array[d] = int (global_state);
			WriteLineToFile();
			ReadFromFileToArray();
			return;
		}
		
		if (useType == USE_ON)
		{
			global_state = 1;
			self.pev.health = 1;
			a = int( global_name[8] - 48);
			b = 10 * int( global_name[7] - 48);
			c = 100 * int( global_name[6] - 48);
			d = a+b+c;
			file_array[d] = int (global_state);
			WriteLineToFile();
			ReadFromFileToArray();
			return;
		}
		
		if (useType == USE_TOGGLE) // switch between off and on status then activate
		{
			ReadFromFileToArray();
			a = int( global_name[8] - 48);
			b = 10 * int( global_name[7] - 48);
			c = 100 * int( global_name[6] - 48);
			d = a+b+c;
			global_state = float (file_array[d]);
			self.pev.health = global_state;
			
			if (global_state == 0)
			{
				global_state = 1;
				self.pev.health = 1;
				file_array[d] = int (global_state);
				WriteLineToFile();
				ReadFromFileToArray();
				return;
			}
			else
			{
				global_state = 0;
				self.pev.health = 0;
				file_array[d] = int (global_state);
				WriteLineToFile();
				ReadFromFileToArray();
				return;
			}
		}
		
		if (useType == USE_KILL) // this one does not work
		{
			g_EntityFuncs.Remove( self );
			return;
		}
	}
}

void WriteLineToFile()
{
	string StringToWrite;
	try 
	{
		File@ file = g_FileSystem.OpenFile("scripts/maps/store/ResidualGlobal.txt", OpenFile::READ);
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
	
	File@ file= g_FileSystem.OpenFile("scripts/maps/store/ResidualGlobal.txt", OpenFile::WRITE);
	if(file !is null && file.IsOpen()) //delete the file and write its values again
	{
		for ( uint I = 0; I < 50; I++ )
		{
			string prefix;
			if (I < 10) {prefix = "global00";} else {prefix = "global0";}
			
			StringToWrite = string(file_array[I]);
			file.Write( prefix + string(I) + "=" + StringToWrite+"\n");
		}
		file.Close();
	}
}

void ReadFromFileToArray()
{
	File@ file = g_FileSystem.OpenFile("scripts/maps/store/ResidualGlobal.txt", OpenFile::READ);
	uint i = 0;
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
			//g_EngineFuncs.ServerPrint("[read map storage line] : "+sLine);
			//Server console (developer 1)
			//g_Game.AlertMessage( at_console, "[read map storage line 2 ] : "+sLine+"\n" );
			
			file_array[i] = int (sLine[10]);
			file_array[i] = file_array[i] - 48;
			
			//g_EngineFuncs.ServerPrint("[array line] :" + string(file_array[i]));
			//g_EngineFuncs.ServerPrint("[sLine[10]] :" + string(int(sLine[10]))+"\n");
			i++;
		}
		file.Close();
	}
}

void RegisterDataGlobal()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CDataGlobal", "data_global");
}