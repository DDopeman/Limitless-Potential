// . Custom entity for echoes map series. 

/*
env_model_coop
Author: kmkz (e-mail: al_basualdo@hotmail.com )
this plays an animation. Similar to env_model of SOHL engine.

--------------------------------------
model: "Model name"
Model that will be displayed. 
m_iszSequence_On: "Sequence when on"
Name of the sequence that will play when it is on.
m_iszSequence_Off: "Sequence when off"
Name of the sequence that will play when it is off.
m_iAction_On: "Behaviour when on"
Behaviour of the enity when on, the are 3 options:
	0: "Freeze when sequence ends"
	The sequence will play once and then will stay quiet.
	1: "Loop"
	The sequence will play until the end and then will repeat.
	2: "Change state when sequence ends"
	The sequence will play once and then will the the oposite sequence 
m_iAction_Off: "Behaviour when off"
	same as above for the off sequence.
---------------------------------------
flags:
1: "Initially off"
instead of playing the on sequence this will play the off sequence
2: "Drop to floor"
Instead of floating in air this will drop to floor. 
4: "Solid"
Instead of being not solid this entity will be solid. 
---------------------------------------
note: if the sequence name is !none then no sequence will be played and the entity will stay frozen.
*/

enum AnimatingGenericSequenceSpawnFlag
	{
		SF_AG_INITIALLY_OFF 			= 1  << 0,
		SF_AG_DROP_TO_FLOOR 			= 2  << 0,
		SF_AG_SOLID 					= 4  << 0,
	}

class CEnvModelCoop : ScriptBaseAnimating
{
	string m_iszSequence_Off;
	string m_iszSequence_On;
	int m_iAction_Off;
	int m_iAction_On;
	string sequence_active; //sequence that should be played
	int action_mode;
	Vector Vminhullsize;
	Vector Vmaxhullsize;
	string m_iszMaster;
	
	void Precache()
	{
		BaseClass.Precache();
		g_Game.PrecacheModel(self.pev.model);
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "m_iszSequence_Off")
		{
		m_iszSequence_Off = szValue;
		return true;
		}
		else if(szKey == "m_iszSequence_On")
		{
		m_iszSequence_On = szValue;
		return true;
		}
		else if(szKey == "m_iAction_Off")
		{
		m_iAction_Off = atoi (szValue);
		return true;
		}
		else if(szKey == "m_iAction_On")
		{
		m_iAction_On = atoi (szValue);
		return true;
		}
		else if(szKey == "minhullsize")
		{
		string delimiter = " ";
		array<string> splitMinVector = {"","",""};
		splitMinVector = szValue.Split(delimiter);
		Vminhullsize.x = atof(splitMinVector[0]);
		Vminhullsize.y = atof(splitMinVector[1]);
		Vminhullsize.z = atof(splitMinVector[2]);
		return true;
		}
		else if(szKey == "maxhullsize")
		{
		string delimiter = " ";
		array<string> splitMaxVector = {"","",""};
		splitMaxVector = szValue.Split(delimiter);
		Vmaxhullsize.x = atof(splitMaxVector[0]);
		Vmaxhullsize.y = atof(splitMaxVector[1]);
		Vmaxhullsize.z = atof(splitMaxVector[2]);
		return true;
		}
		else if(szKey == "master")
		{
			m_iszMaster = szValue;
			return true;
		}
		else 
		{
			return BaseClass.KeyValue( szKey, szValue );
		}
	}
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel(self, self.pev.model);
		self.InitBoneControllers(); 					// used to avoid having rotated body parts.
		SetUse(UseFunction(this.TriggerUse));
		
		if (self.pev.SpawnFlagBitSet( SF_AG_INITIALLY_OFF ))	{sequence_active = m_iszSequence_Off;}	else {sequence_active = m_iszSequence_On;}
		if (self.pev.SpawnFlagBitSet( SF_AG_DROP_TO_FLOOR ))	{self.pev.movetype = MOVETYPE_TOSS;}	else {self.pev.movetype = MOVETYPE_NONE;}
		if (self.pev.SpawnFlagBitSet( SF_AG_SOLID  ))			{self.pev.solid = SOLID_SLIDEBOX; g_EntityFuncs.SetSize(self.pev, Vminhullsize, Vmaxhullsize);} 		else {self.pev.solid = SOLID_NOT;}
		
		if (sequence_active == "!none")
		{
			self.pev.sequence = -1;
		}
		else
		{
			self.Use(null, null, USE_SET ,0.0); 			// initialize the entity
		}
	}
	
	void TriggerUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		self.pev.frame = 0;
		
		if( !m_iszMaster.IsEmpty() && !g_EntityFuncs.IsMasterTriggered( m_iszMaster, self ) && useType != USE_SET)
		{	
			return;
		}
		
		if (useType == USE_OFF)
		{
			sequence_active = m_iszSequence_Off;
			action_mode = m_iAction_Off;
		}
		
		if (useType == USE_ON)
		{
			sequence_active = m_iszSequence_On;
			action_mode = m_iAction_On;
		}
		
		if (useType == USE_TOGGLE) // switch between off and on status then activate
		{
			if (sequence_active == m_iszSequence_Off)
			{
				sequence_active = m_iszSequence_On;
				action_mode = m_iAction_On;
			}
			else
			{
				sequence_active = m_iszSequence_Off;
				action_mode = m_iAction_Off;
			}
		}
		
		if (useType == USE_KILL)
		{
			g_EntityFuncs.Remove( self );
		}
		
		if (useType == USE_SET) // initializes the entity
		{
			if (sequence_active == m_iszSequence_Off)
			{
				sequence_active = m_iszSequence_Off;
				action_mode = m_iAction_Off;
			}
			else
			{
				sequence_active = m_iszSequence_On;
				action_mode = m_iAction_On;
			}
		}
		
		ActivateSequence (sequence_active, action_mode);
	}
	
	// play the sequence
	void ActivateSequence (string sequence_name, int acti_mode)
	{
		self.pev.frame = 0;
		if ( self.LookupSequence(sequence_name) != -1 ) // check if the animation name is valid
		{
			self.pev.sequence = self.LookupSequence(sequence_name);
		}
		else
		{
			self.pev.sequence = 0;
		}
		
		self.ResetSequenceInfo();
		if ( acti_mode != 0) 
		{
			self.m_fSequenceLoops = true;
			SetThink(ThinkFunction(this.RepeatSequenceThink));
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
	}
	
	// 
	void RepeatSequenceThink()
	{
		self.StudioFrameAdvance();
		if (self.m_fSequenceFinished)
		{	
		
			if (action_mode == 2)
			{
				self.m_fSequenceLoops = false;
				self.Use(null, null, USE_TOGGLE ,0.0); // instead of repeating switch off/on and activate
				self.pev.nextthink = g_Engine.time + 0.01f;
				return;
			}
			
			if (action_mode == 1)
			{
				self.pev.frame = 0;
				self.m_fSequenceFinished = false;
				self.ResetSequenceInfo();
				self.pev.nextthink = g_Engine.time + 0.01f;
			}
			else //action_mode = 0
			{
				//self.pev.nextthink = g_Engine.time + 0.1f;
			}
		}
		else
		{
			self.pev.nextthink = g_Engine.time + 0.01f;
		}
	}	
}

void RegisterEnvModelCoop()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CEnvModelCoop", "env_model_coop");
}