// Based on Half-Life Featureful code

namespace FIDeadMonsters
{

class CDeadMonster : ScriptBaseMonsterEntity
{
	void SpawnHelper(string modelName, int bloodColor = BLOOD_COLOR_RED, int health = 8)
	{
		g_Game.PrecacheModel( modelName );
		g_EntityFuncs.SetModel(self, modelName);
		self.m_bloodColor = bloodColor;
		pev.health = health;
		pev.yaw_speed = 8;
		pev.sequence = 0;
		string seqName = getPos(m_iPose);
		int sequence = self.LookupSequence( seqName );
		if (sequence >= 0)
		{
			pev.sequence = sequence;
		}
		else
		{
			g_Game.AlertMessage( at_console, "%1 with bad pose (no %2 animation in %3)\n", self.GetClassname(), seqName, modelName );
		}
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "pose")
		{
			m_iPose = atoi(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	string getPos(int pose)
	{
		return '';
	}
	int m_iPose;
};

class monster_bullchicken_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/bullsquid.mdl", BLOOD_COLOR_YELLOW, 16);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_MONSTER); }
	string getPos(int pos)
	{
		return "die1";
	}
};

const array<string> alien_slave_dead_poses = {"dead_on_stomach", "dieheadshot", "diesimple", "diebackward", "dieforward"};

class monster_alien_slave_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/islave.mdl", BLOOD_COLOR_YELLOW);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_MILITARY); }
	string getPos(int pos)
	{
		return alien_slave_dead_poses[pos % alien_slave_dead_poses.length()];
	}
};

const array<string> alien_grunt_dead_poses = {"diesimple", "diebackward"};

class monster_alien_grunt_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/agrunt.mdl", BLOOD_COLOR_YELLOW, 16);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_MILITARY); }
	string getPos(int pos)
	{
		return alien_grunt_dead_poses[pos % alien_grunt_dead_poses.length()];
	}
};

class monster_alien_controller_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/controller.mdl", BLOOD_COLOR_YELLOW, 16);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_MILITARY); }
	string getPos(int pos)
	{
		return "die1";
	}
};

class monster_headcrab_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/headcrab.mdl", BLOOD_COLOR_YELLOW);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_PREY); }
	string getPos(int pos)
	{
		return "dieback";
	}
};

class monster_houndeye_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/fi/houndeye_dead.mdl", BLOOD_COLOR_YELLOW);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_MONSTER); }
	string getPos(int pos)
	{
		return "dead";
	}
};

const array<string> zombie_dead_poses = { "dieheadshot", "dieforward", "slidewall" };

class monster_zombie_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/zombie.mdl", BLOOD_COLOR_YELLOW);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_ALIEN_MONSTER); }
	string getPos(int pos)
	{
		return zombie_dead_poses[pos % zombie_dead_poses.length()];
	}
};

class monster_zombie_barney_dead : monster_zombie_dead
{
	void Spawn()
	{
		SpawnHelper("models/zombie_barney.mdl", BLOOD_COLOR_YELLOW);
		self.MonsterInitDead();
		pev.frame = 255;
	}
};

class monster_pitdrone_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/pit_drone.mdl", BLOOD_COLOR_YELLOW, 16);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_XRACE_PITDRONE); }
	string getPos(int pos)
	{
		return "die1";
	}
};

const array<string> shocktrooper_dead_poses = { "diesimple", "diebackwards" };

class monster_shocktrooper_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/strooper.mdl", BLOOD_COLOR_YELLOW, 16);
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_XRACE_SHOCK); }
	string getPos(int pos)
	{
		return shocktrooper_dead_poses[pos % shocktrooper_dead_poses.length()];
	}
};

// Weapon flags
const int MASSN_9MMAR = (1 << 0);
const int MASSN_HANDGRENADE = (1 << 1);
const int MASSN_GRENADELAUNCHER = (1 << 2);
const int MASSN_SNIPERRIFLE = (1 << 3);

// Body groups.
const int MASSN_HEAD_GROUP = 1;
const int MASSN_GUN_GROUP = 2;

// Gun values
const int MASSN_GUN_MP5 = 0;
const int MASSN_GUN_SNIPERRIFLE = 1;
const int MASSN_GUN_NONE = 2;

const int MASSN_HEAD_WHITE = 0;
const int MASSN_HEAD_BLACK = 1;
const int MASSN_HEAD_GOOGLES = 2;
const int MASSN_HEAD_COUNT = 3;

const array<string> male_assassin_dead_poses = { "deadstomach", "deadside", "deadsitting" };

class monster_male_assassin_dead : CDeadMonster
{
	private int m_iHead;

	void Spawn()
	{
		SpawnHelper("models/massn.mdl");

		if ( pev.weapons <= 0 )
		{
			self.SetBodygroup( MASSN_GUN_GROUP, MASSN_GUN_NONE );
		}
		if (( pev.weapons & MASSN_9MMAR ) != 0)
		{
			self.SetBodygroup(MASSN_GUN_GROUP, MASSN_GUN_MP5);
		}
		if (( pev.weapons & MASSN_SNIPERRIFLE ) != 0)
		{
			self.SetBodygroup(MASSN_GUN_GROUP, MASSN_GUN_SNIPERRIFLE);
		}

		if ( m_iHead < 0 || m_iHead >= MASSN_HEAD_COUNT ) {
			m_iHead = Math.RandomLong(MASSN_HEAD_WHITE, MASSN_HEAD_BLACK);  // never random night googles
		}

		self.SetBodygroup( MASSN_HEAD_GROUP, m_iHead );

		self.MonsterInitDead();
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "head")
		{
			m_iHead = atoi(szValue);
			return true;
		}
		else
			return CDeadMonster::KeyValue( szKey, szValue );
	}
	int Classify() { return self.GetClassification(CLASS_HUMAN_MILITARY); }
	string getPos(int pos)
	{
		return male_assassin_dead_poses[pos % male_assassin_dead_poses.length()];
	}
};

const array<string> human_assassin_dead_poses = { "death_during_run", "die_backwards", "die_simple" };

class monster_human_assassin_dead : CDeadMonster
{
	void Spawn()
	{
		SpawnHelper("models/hassassin.mdl");
		self.MonsterInitDead();
		pev.frame = 255;
	}
	int Classify() { return self.GetClassification(CLASS_HUMAN_MILITARY); }
	string getPos(int pos)
	{
		return human_assassin_dead_poses[pos % human_assassin_dead_poses.length()];
	}
};

const int TURRET_ANIM_DIE = 5;

class CBaseDeadTurret : ScriptBaseAnimating
{
	void SpawnTurret(string defaultModel)
	{
		if (pev.model == "") {
			g_Game.PrecacheModel(defaultModel);
		} else {
			g_Game.PrecacheModel(pev.model);
		}

		pev.movetype = MOVETYPE_FLY;
		pev.solid = SOLID_SLIDEBOX;
		pev.sequence = TURRET_ANIM_DIE;
		pev.frame = 255.0f;
		pev.takedamage = DAMAGE_NO;

		self.ResetSequenceInfo();

		if (pev.model == "") {
			g_EntityFuncs.SetModel(self, defaultModel);
		} else {
			g_EntityFuncs.SetModel(self, pev.model);
		}

		self.SetBoneController( 0, 0 );
		if (m_iOrientation == 0)
			self.SetBoneController( 1, 0 );
		else
			self.SetBoneController( 1, -90 );

		if(m_iOrientation == 1)
		{
			pev.idealpitch = 180;
			pev.angles.x = 180;
			pev.effects |= EF_INVLIGHT;
			pev.angles.y = pev.angles.y + 180;
			if( pev.angles.y > 360 )
				pev.angles.y = pev.angles.y - 360;
		}
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "orientation")
		{
			m_iOrientation = atoi(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue(szKey, szValue);
	}
	void TraceAttack(entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType)
	{
		if( ptr.iHitgroup == 10 )
		{
			// hit armor
			if( pev.dmgtime != g_Engine.time || (Math.RandomLong( 0, 10 ) < 1 ) )
			{
				g_Utility.Ricochet( ptr.vecEndPos, Math.RandomLong( 1, 2 ) );
				pev.dmgtime = g_Engine.time;
			}
		}
	}

	int m_iOrientation;
};

class monster_turret_dead : CBaseDeadTurret
{
	void Spawn() {
		SpawnTurret("models/turret.mdl");
		g_EntityFuncs.SetSize(pev, Vector(-32, -32, -16), Vector(32, 32, 16));
	}
};

class monster_miniturret_dead : CBaseDeadTurret
{
	void Spawn() {
		SpawnTurret("models/miniturret.mdl");
		g_EntityFuncs.SetSize(pev, Vector(-16, -16, -16), Vector(16, 16, 16));
	}
};

void Register()
{
	const array<string> entities = {
		"monster_bullchicken_dead",
		"monster_alien_slave_dead",
		"monster_alien_grunt_dead",
		"monster_headcrab_dead",
		"monster_houndeye_dead",
		"monster_zombie_dead",
		"monster_zombie_barney_dead",
		"monster_pitdrone_dead",
		"monster_shocktrooper_dead",
		"monster_male_assassin_dead",
		"monster_human_assassin_dead",
		"monster_turret_dead",
		"monster_miniturret_dead"
	};
	for (uint i=0; i<entities.length(); ++i)
	{
		if (!g_CustomEntityFuncs.IsCustomEntity(entities[i]))
		{
			g_CustomEntityFuncs.RegisterCustomEntity('FIDeadMonsters::'+entities[i], entities[i]);
		}
	}
}
}
