/*
 *
 * func_throwable
 *
 * Author: w00tguy (w00tguy123 - forums.svencoop.com)
 *
 */

void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }

Vector parseVector(string s) {
	array<string> values = s.Split(" ");
	Vector v(0,0,0);
	if (values.length() > 0) v.x = atof( values[0] );
	if (values.length() > 1) v.y = atof( values[1] );
	if (values.length() > 2) v.z = atof( values[2] );
	return v;
}

class func_throwable : ScriptBaseEntity
{
	EHandle owner;
	float holdDistance = 128.0f;
	float throwSpeed = 512.0f;
	int explodeDamage = 0;
	float life = 0;
	float startLife = 0;
	bool countdown = false;
	float lastCountdown = 0;
	int frameOffset = 0;
	bool dead = false;
	bool breakOnMonsters = false;
	Vector minHull;
	Vector maxHull;
	bool isBrushModel = false;
	bool invertTimer = false;
	
	float m_maxSpeed = 0;
	float m_soundTime = 0;
	int	m_lastSound = 0;
	int m_Material = matGlass;
	string pGibName = "models/woodgibs.mdl";
	
	array<string> m_soundNames = { "debris/pushbox1.wav", "debris/pushbox2.wav", "debris/pushbox3.wav" };
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{	
		if (szKey == "material")
		{
			m_Material = atoi(szValue);
			if ((m_Material < 0) || (m_Material >= matLastMaterial))
				m_Material = 0;
		}
		else if (szKey == "hold_distance") holdDistance = atof(szValue);
		else if (szKey == "min_hull") minHull = parseVector(szValue);
		else if (szKey == "max_hull") maxHull = parseVector(szValue);
		else if (szKey == "throw_speed") throwSpeed = atof(szValue);
		else if (szKey == "life_time") life = atof(szValue);
		else if (szKey == "explode_damage") explodeDamage = atoi(szValue);
		else if (szKey == "timer_offset") frameOffset = atoi(szValue);
		else if (szKey == "invert_timer") invertTimer = atoi(szValue) != 0;
		else if (szKey == "break_on_monsters") breakOnMonsters = atoi(szValue) != 0;
		else return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	int ObjectCaps() { return (BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION) | FCAP_DIRECTIONAL_USE; }
	
	void Spawn()
	{				
		self.pev.solid = SOLID_BBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		//self.pev.effects = EF_NODECALS;
		self.pev.effects = EF_FRAMEANIMTEXTURES;
		if (!invertTimer)
			pev.frame = pev.skin = 0;
		else
			pev.frame = pev.skin = int(life) + frameOffset;
			
		if (pev.friction > 399)
			pev.friction = 399;
		m_maxSpeed = 400 - pev.friction;
		pev.friction = 0;
		pev.origin.z += 1;
		startLife = life;
		
		isBrushModel = string(pev.model).Length() > 0 and string(pev.model)[0] == '*';
		
		Precache();

		g_EntityFuncs.SetModel(self, self.pev.model);
		if (isBrushModel)
			g_EntityFuncs.SetSize(self.pev, pev.mins, pev.maxs);
		else
			g_EntityFuncs.SetSize(self.pev, minHull, maxHull);
		g_EntityFuncs.SetOrigin(self, self.pev.origin);
		
		SetThink( ThinkFunction( ThrowableThink ) );
		self.pev.nextthink = g_Engine.time;
	}
	
	void Precache()
	{
		for (uint i = 0; i < m_soundNames.length(); i++)
			g_SoundSystem.PrecacheSound(m_soundNames[i]);
			
		if (!isBrushModel)
			g_Game.PrecacheModel( pev.model );
	
		switch (m_Material) 
		{
		case matWood:
			pGibName = "models/woodgibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustcrate1.wav");
			g_SoundSystem.PrecacheSound("debris/bustcrate2.wav");
			g_SoundSystem.PrecacheSound("debris/wood1.wav");
			g_SoundSystem.PrecacheSound("debris/wood2.wav");
			g_SoundSystem.PrecacheSound("debris/wood3.wav");
			break;
		case matFlesh:
			pGibName = "models/fleshgibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustflesh1.wav");
			g_SoundSystem.PrecacheSound("debris/bustflesh2.wav");
			g_SoundSystem.PrecacheSound("debris/flesh1.wav");
			g_SoundSystem.PrecacheSound("debris/flesh2.wav");
			g_SoundSystem.PrecacheSound("debris/flesh3.wav");
			g_SoundSystem.PrecacheSound("debris/flesh4.wav");
			g_SoundSystem.PrecacheSound("debris/flesh5.wav");
			g_SoundSystem.PrecacheSound("debris/flesh6.wav");
			g_SoundSystem.PrecacheSound("debris/flesh7.wav");
			break;
		case matComputer:
			g_SoundSystem.PrecacheSound("buttons/spark5.wav");
			g_SoundSystem.PrecacheSound("buttons/spark6.wav");
			pGibName = "models/computergibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustmetal1.wav");
			g_SoundSystem.PrecacheSound("debris/metal1.wav");
			g_SoundSystem.PrecacheSound("debris/metal2.wav");
			g_SoundSystem.PrecacheSound("debris/metal3.wav");
			break;

		case matUnbreakableGlass:
		case matGlass:
			pGibName = "models/glassgibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustglass1.wav");
			g_SoundSystem.PrecacheSound("debris/bustglass2.wav");
			g_SoundSystem.PrecacheSound("debris/glass1.wav");
			g_SoundSystem.PrecacheSound("debris/glass2.wav");
			g_SoundSystem.PrecacheSound("debris/glass3.wav");
			break;
		case matMetal:
			pGibName = "models/metalplategibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustmetal1.wav");
			g_SoundSystem.PrecacheSound("debris/bustmetal2.wav");
			g_SoundSystem.PrecacheSound("debris/metal1.wav");
			g_SoundSystem.PrecacheSound("debris/metal2.wav");
			g_SoundSystem.PrecacheSound("debris/metal3.wav");
			break;
		case matCinderBlock:
			pGibName = "models/cindergibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustconcrete1.wav");
			g_SoundSystem.PrecacheSound("debris/bustconcrete2.wav");
			g_SoundSystem.PrecacheSound("debris/concrete1.wav");
			g_SoundSystem.PrecacheSound("debris/concrete2.wav");
			g_SoundSystem.PrecacheSound("debris/concrete3.wav");
			break;
		case matRocks:
			pGibName = "models/rockgibs.mdl";
			
			g_SoundSystem.PrecacheSound("debris/bustconcrete1.wav");
			g_SoundSystem.PrecacheSound("debris/bustconcrete2.wav");
			g_SoundSystem.PrecacheSound("debris/concrete1.wav");
			g_SoundSystem.PrecacheSound("debris/concrete2.wav");
			g_SoundSystem.PrecacheSound("debris/concrete3.wav");
			break;
		case matCeilingTile:
			pGibName = "models/ceilinggibs.mdl";
			
			g_SoundSystem.PrecacheSound ("debris/bustceiling.wav");  
			break;
		default:
			break;
		}
		
		if ( pGibName.Length() > 0 )
			g_Game.PrecacheModel( pGibName );
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if (pOther.pev.classname == "worldspawn")
			return;
			
		//println("TOUCHED BY " + pOther.pev.classname + " " + pev.velocity.Length());
		
		Move(pOther, 1);
		
		if (breakOnMonsters and pOther.IsMonster() and !pOther.IsPlayer())
			TakeDamage(pev, pev, pev.health, 0);
	}
	
	void Move( CBaseEntity@ pOther, int push )
	{
		entvars_t@ pevToucher = pOther.pev;
		bool playerTouch = false;

		// Is entity standing on this pushable ?
		CBaseEntity@ groundEnt = null;
		if (pevToucher.groundentity !is null)
			@groundEnt = g_EntityFuncs.Instance( pevToucher.groundentity );
		if ( pevToucher.flags & FL_ONGROUND != 0 && groundEnt.entindex() == self.entindex() )
		{
			// Only push if floating
			if ( pev.waterlevel > 0 )
				pev.velocity.z += pevToucher.velocity.z * 0.1;

			return;
		}

		if ( pOther.IsPlayer() )
		{
			if ( push != 0 && (pevToucher.button & (IN_FORWARD|IN_USE)) == 0 )	// Don't push unless the player is pushing forward and NOT use (pull)
				return;
			playerTouch = true;
		}

		float factor;

		if (playerTouch)
		{
			if ( pevToucher.flags & FL_ONGROUND == 0 )	// Don't push away from jumping/falling players unless in water
			{
				if ( pev.waterlevel < 1 )
					return;
				else 
					factor = 0.1;
			}
			else
				factor = 1;
		}
		else 
			factor = 0.25;

		pev.velocity.x += pevToucher.velocity.x * factor;
		pev.velocity.y += pevToucher.velocity.y * factor;

		float length = sqrt( pev.velocity.x * pev.velocity.x + pev.velocity.y * pev.velocity.y );
		if ( push != 0 && (length > m_maxSpeed) )
		{
			pev.velocity.x = (pev.velocity.x * m_maxSpeed / length );
			pev.velocity.y = (pev.velocity.y * m_maxSpeed / length );
		}
		if ( playerTouch )
		{
			pevToucher.velocity.x = pev.velocity.x;
			pevToucher.velocity.y = pev.velocity.y;
			if ( (g_Engine.time - m_soundTime) > 0.7 )
			{
				m_soundTime = g_Engine.time;
				if ( length > 0 && pev.flags & FL_ONGROUND != 0 )
				{
					m_lastSound = Math.RandomLong(0,m_soundNames.length()-1);
					g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, m_soundNames[m_lastSound], 1.0f, 1.0f, 0, 100);
				}
				else
					g_SoundSystem.StopSound(self.edict(), CHAN_WEAPON, m_soundNames[m_lastSound] );
			}
		}
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		//println("USED BY " + pCaller.pev.classname);
		
		if (pCaller.IsPlayer())
		{
			if (owner and owner.GetEntity().entindex() == pCaller.entindex())
			{
				Math.MakeVectors( pCaller.pev.v_angle );
				pev.velocity = g_Engine.v_forward*throwSpeed;
				owner = null;
				return;
			}
			owner = pCaller;
		}
		else
		{
			countdown = !countdown;
			lastCountdown = g_Engine.time;
		}
	}
	
	void ThrowableThink()
	{		
		if (owner)
		{
			CBaseEntity@ plr = owner;
			Math.MakeVectors( plr.pev.v_angle );
			Vector target = plr.pev.origin + g_Engine.v_forward*holdDistance + Vector(0,0,0);
			Vector delta = target - pev.origin;
			float dist = delta.Length();
			if (dist > 96.0f)
				owner = null;
			else
			{
				pev.velocity = delta.Normalize()*(delta.Length()*32);
			}
		}
		
		if (countdown)
		{
			life -= (g_Engine.time - lastCountdown); 
			lastCountdown = g_Engine.time;
			if (!invertTimer)
				pev.frame = pev.skin = int(startLife - life) + frameOffset;
			else
				pev.frame = pev.skin = int(life) + frameOffset;
			if (life < 0)
			{
				TakeDamage(pev, pev, pev.health, 0);
			}
		}
		
		self.pev.nextthink = g_Engine.time;
	}
	
	void DamageSound()
	{
		int pitch;
		float fvol;
		array<string> rgpsz(6);
		int i = 0;
		int material = m_Material;

		if (Math.RandomLong(0,2) != 0)
			pitch = PITCH_NORM;
		else
			pitch = 95 + Math.RandomLong(0,34);

		fvol = Math.RandomFloat(0.75, 1.0);

		if (material == matComputer && Math.RandomLong(0,1) != 0)
			material = matMetal;

		switch (material)
		{
		case matComputer:
		case matGlass:
		case matUnbreakableGlass:
			rgpsz[0] = "debris/glass1.wav";
			rgpsz[1] = "debris/glass2.wav";
			rgpsz[2] = "debris/glass3.wav";
			i = 3;
			break;

		case matWood:
			rgpsz[0] = "debris/wood1.wav";
			rgpsz[1] = "debris/wood2.wav";
			rgpsz[2] = "debris/wood3.wav";
			i = 3;
			break;

		case matMetal:
			rgpsz[0] = "debris/metal1.wav";
			rgpsz[1] = "debris/metal3.wav";
			rgpsz[2] = "debris/metal2.wav";
			i = 2;
			break;

		case matFlesh:
			rgpsz[0] = "debris/flesh1.wav";
			rgpsz[1] = "debris/flesh2.wav";
			rgpsz[2] = "debris/flesh3.wav";
			rgpsz[3] = "debris/flesh5.wav";
			rgpsz[4] = "debris/flesh6.wav";
			rgpsz[5] = "debris/flesh7.wav";
			i = 6;
			break;

		case matRocks:
		case matCinderBlock:
			rgpsz[0] = "debris/concrete1.wav";
			rgpsz[1] = "debris/concrete2.wav";
			rgpsz[2] = "debris/concrete3.wav";
			i = 3;
			break;

		case matCeilingTile:
			// UNDONE: no ceiling tile shard sound yet
			i = 0;
			break;
		}

		if (i != 0)
			g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, rgpsz[Math.RandomLong(0,i-1)], fvol, ATTN_NORM, 0, pitch);
	}
	
	void BreakSound()
	{
		int pitch;
		float fvol;
	
		pitch = 95 + Math.RandomLong(0,29);
		if (pitch > 97 && pitch < 103)
			pitch = 100;
			
		fvol = Math.RandomFloat(0.85, 1.0) + (abs(pev.health) / 100.0f);
		if (fvol > 1.0)
			fvol = 1.0;
		
		switch (m_Material)
		{
		case matGlass:
			switch ( Math.RandomLong(0,1) )
			{
			case 0:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustglass1.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			case 1:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustglass2.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			}
			break;

		case matWood:
			switch ( Math.RandomLong(0,1) )
			{
			case 0:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustcrate1.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			case 1:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustcrate2.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			}
			break;

		case matComputer:
		case matMetal:
			switch ( Math.RandomLong(0,1) )
			{
			case 0:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustmetal1.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			case 1:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustmetal2.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			}
			break;

		case matFlesh:
			switch ( Math.RandomLong(0,1) )
			{
			case 0:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustflesh1.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			case 1:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustflesh2.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			}
			break;

		case matRocks:
		case matCinderBlock:
			switch ( Math.RandomLong(0,1) )
			{
			case 0:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustconcrete1.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			case 1:	g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustconcrete2.wav", fvol, ATTN_NORM, 0, pitch);	
				break;
			}
			break;

		case matCeilingTile:
			g_SoundSystem.PlaySound(self.edict(), CHAN_VOICE, "debris/bustceiling.wav", fvol, ATTN_NORM, 0, pitch);
			break;

		default:
			break;
		}
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{		
		if (dead)
			return 0;
			
		pev.health -= flDamage;
		
		if (pev.health <= 0)
		{
			dead = true;
			BreakSound();
			
			Vector center = pev.origin + ((pev.mins + pev.maxs) * 0.5f);
			Vector mins = pev.mins;
			
			int flags = 1;
			switch (m_Material) 
			{
				case matWood: flags = 8; break;
				case matFlesh: flags = 4; break;
				case matMetal: case matComputer: flags = 2; break;
				case matUnbreakableGlass: case matGlass: flags = 1; break;
				case matRocks: case matCinderBlock: flags = 64; break;
				case matCeilingTile: flags = 0; break;
				default: break;
			}
			
			te_breakmodel(center, pev.maxs - pev.mins, Vector(0,0,0), Math.min(explodeDamage/2, 255), pGibName, 0, 0, flags);
			
			if (explodeDamage > 0)
				g_EntityFuncs.CreateExplosion(center, Vector(0,0,0), self.edict(), explodeDamage, true);
			
			g_EntityFuncs.FireTargets(pev.target, self, self, USE_TOGGLE);
			g_EntityFuncs.Remove(self);
		}
		else
		{
			DamageSound();
		}
		
		return 0;
	}
};

void te_breakmodel(Vector pos, Vector size, Vector velocity, 
	uint8 speedNoise=16, string model="models/hgibs.mdl", 
	uint8 count=8, uint8 life=0, uint8 flags=20,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BREAKMODEL);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(size.x);
	m.WriteCoord(size.y);
	m.WriteCoord(size.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteByte(speedNoise);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteByte(count);
	m.WriteByte(life);
	m.WriteByte(flags);
	m.End();
}