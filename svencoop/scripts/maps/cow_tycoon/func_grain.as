//moveable grain that can be fed to cows

int GRAIN_VALUE = 200; //amount of health grain adds
int MILK_VALUE = 150; //initial worth of a milk bucket

class func_grain : ScriptBaseEntity
{
	
	CBaseEntity@ holder = null;
	CBaseEntity@ attached_vehicle = null;
	Vector attach_pos = Vector(0,0,0);
	
	int ObjectCaps()
	{
	return FCAP_IMPULSE_USE;
	}
	
	void Spawn()
	{
		self.pev.flags = FL_ALWAYSTHINK | FL_ONGROUND;
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.gravity = 1.0;
		self.pev.friction = 1.0;
		
		g_EntityFuncs.SetModel( self, self.pev.model );

		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.nextthink = pev.ltime + 0.1;
		
		SetTouch( TouchFunction( GrainTouch ) );
		SetThink( ThinkFunction( GrainThink ) );
		SetUse( UseFunction( GrainUse ) );
	}
	
	void dropObj()
	{
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.solid = SOLID_BSP;
		self.pev.velocity = Vector(0,0,0);
	
		int got_vehc = 0;
		TraceResult vehicle_trace;
		edict_t@ vehicle_edict;
		CBaseEntity@ vehicle;
		
		g_Utility.TraceLine( self.pev.origin, self.pev.origin + Vector(0,0,-64), ignore_monsters, self.edict(), vehicle_trace );
		
		@vehicle_edict = vehicle_trace.pHit;
		
		if (@vehicle_edict != null)
		{
			@vehicle = g_EntityFuncs.Instance(vehicle_edict);
			
			//g_Game.AlertMessage(at_console, vehicle.GetClassname() + "\n");
			
			if (vehicle.GetClassname() == "func_vehicle_custom")
			{
				@attached_vehicle = vehicle;
					
				attached_vehicle.pev.skin = attached_vehicle.pev.skin + 1; //add weight
					
				attach_pos = (vehicle_trace.vecEndPos + Vector(0,0,16)) - attached_vehicle.pev.origin;
				got_vehc = 1;
				self.pev.movetype = MOVETYPE_NONE;
				self.pev.solid = SOLID_NOT;
				//usually becomes SOLID_NOT

			}
		}
		
		if (got_vehc == 0)
		{
			self.pev.movetype = MOVETYPE_PUSHSTEP;
			self.pev.solid = SOLID_BSP;

			if (@vehicle_edict != null)
			{
				g_EntityFuncs.SetOrigin( self, vehicle_trace.vecEndPos + Vector(0,0,16) );
			}
			@attached_vehicle = null;
		}
		
		@holder = null;
	}
	
	void GrainUse(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
	{
		if (@holder == null)
		{
			@holder = activator;
			if (@attached_vehicle != null)
			{
				attached_vehicle.pev.skin = attached_vehicle.pev.skin - 1; //remove weight
			}
			@attached_vehicle = null;
			self.pev.solid = SOLID_NOT;
		}
		else
		{
			//self.pev.velocity = holder.pev.velocity;
			dropObj();
		}
	}
	
	void GrainTouch(CBaseEntity@ pOther)
	{
		if (pOther.pev.ClassNameIs("monster_gonome") == true)
		{
			//add cow health and value
			pOther.pev.health += GRAIN_VALUE;
			pOther.pev.impacttime += GRAIN_VALUE;
			
			g_EntityFuncs.Remove(self);
		}
		//push this entity if its a player or something
		self.pev.velocity = self.pev.velocity + pOther.pev.velocity;
	}
	
	void GrainThink()
	{
		if (@holder != null)
		{
			CBaseEntity@ cow;
			
			g_EngineFuncs.MakeVectors(holder.pev.angles);
			self.pev.origin = holder.pev.origin + g_Engine.v_forward * Vector(64,64,-192);
			self.pev.origin = self.pev.origin + Vector(0,0,16); //slight vertical increase because its too low otherwise
			
			CBasePlayer@ player = cast<CBasePlayer@>(holder);
			int buttons = player.pev.button;
			if ( (buttons & IN_USE) == 0 ) //when stop holding e, drop this
			{
				dropObj();
			}
			
			@cow = g_EntityFuncs.FindEntityInSphere(cow, self.pev.origin, 30.0, "monster_cow");
			if (@cow != null)
			{
				cow.pev.health += GRAIN_VALUE;
				cow.pev.impacttime += GRAIN_VALUE;
				
				g_EntityFuncs.Remove(self);
			}
		}
		else
		{
			if (@attached_vehicle != null)
			{
				g_EngineFuncs.MakeVectors(attached_vehicle.pev.angles);
				g_EntityFuncs.SetOrigin( self, attached_vehicle.pev.origin + attach_pos );
			}
		}
		self.pev.nextthink = pev.ltime + 0.1;
		
		if (self.pev.origin.z < 80)
		{
			self.pev.origin.z = 80;
		}
	}
	
}

class func_pushable_custom : ScriptBaseEntity
{
	
	CBaseEntity@ holder = null;
	CBaseEntity@ attached_vehicle = null;
	Vector attach_pos = Vector(0,0,0);
	
	int ObjectCaps()
	{
	return FCAP_IMPULSE_USE;
	}
	
	void Spawn()
	{
		self.pev.flags = FL_ALWAYSTHINK | FL_ONGROUND;
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.gravity = 1.0;
		self.pev.friction = 1.0;
		
		g_EntityFuncs.SetModel( self, self.pev.model );

		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.nextthink = pev.ltime + 0.1;
		
		SetTouch( TouchFunction( pushableTouch ) );
		SetThink( ThinkFunction( pushableThink ) );
		SetUse( UseFunction( pushableUse ) );
	}
	
	void dropObj()
	{
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.solid = SOLID_BSP;
		self.pev.velocity = Vector(0,0,0);
	
		int got_vehc = 0;
		TraceResult vehicle_trace;
		edict_t@ vehicle_edict;
		CBaseEntity@ vehicle;
		
		g_Utility.TraceLine( self.pev.origin, self.pev.origin + Vector(0,0,-64), ignore_monsters, self.edict(), vehicle_trace );
		
		@vehicle_edict = vehicle_trace.pHit;
		
		if (@vehicle_edict != null)
		{
			@vehicle = g_EntityFuncs.Instance(vehicle_edict);
			
			//g_Game.AlertMessage(at_console, vehicle.GetClassname() + "\n");
			
			if (vehicle.GetClassname() == "func_vehicle_custom")
			{
				
				@attached_vehicle = vehicle;
				vehicle.pev.skin = attached_vehicle.pev.skin + 1; //add weight
					
				attach_pos = (vehicle_trace.vecEndPos + Vector(0,0,16)) - attached_vehicle.pev.origin;
				got_vehc = 1;
				self.pev.movetype = MOVETYPE_NONE;
				self.pev.solid = SOLID_NOT;
				//usually becomes SOLID_NOT
				
			}
		}
		
		if (got_vehc == 0)
		{
			self.pev.movetype = MOVETYPE_PUSHSTEP;
			self.pev.solid = SOLID_BSP;

			if (@vehicle_edict != null)
			{
				g_EntityFuncs.SetOrigin( self, vehicle_trace.vecEndPos + Vector(0,0,16) );
			}
			@attached_vehicle = null;
		}
		
		@holder = null;
	}
	
	void pushableUse(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
	{
		if (@holder == null)
		{
			@holder = activator;
			if (@attached_vehicle != null)
			{
				attached_vehicle.pev.skin = attached_vehicle.pev.skin - 1; //remove weight
			}
			@attached_vehicle = null;
			self.pev.solid = SOLID_NOT;
			//usually becomes SOLID_NOT
		}
		else
		{
			//self.pev.velocity = holder.pev.velocity;
			dropObj();
		}
	}
	
	void pushableTouch(CBaseEntity@ pOther)
	{
		self.pev.velocity = self.pev.velocity + pOther.pev.velocity;
	}
	
	void pushableThink()
	{

		if (@holder != null)
		{
			g_EngineFuncs.MakeVectors(holder.pev.angles);
			g_EntityFuncs.SetOrigin( self, holder.pev.origin + g_Engine.v_forward * Vector(64,64,-192) );
			
			if (self.pev.targetname == "meat_obj")
			{
				CBasePlayer@ player = cast<CBasePlayer@>(holder);
				int buttons = player.pev.button;
				if ( (buttons & IN_USE) == 0 ) //when stop holding e, drop this
				{
					dropObj();
				}
			}
		}
		else
		{
			if (@attached_vehicle != null)
			{
				g_EngineFuncs.MakeVectors(attached_vehicle.pev.angles);
				g_EntityFuncs.SetOrigin( self, attached_vehicle.pev.origin + attach_pos );
			}
		}
		
		if (self.pev.origin.z < 80)
		{
			self.pev.origin.z = 80;
		}
		
		self.pev.nextthink = pev.ltime + 0.1;
	}
	
}

class func_milk_bucket : ScriptBaseEntity
{
	
	CBaseEntity@ holder = null;
	int filled = 0;
	
	int ObjectCaps()
	{
	return FCAP_IMPULSE_USE;
	}
	
	void Spawn()
	{
		self.pev.flags = FL_ALWAYSTHINK | FL_ONGROUND;
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.gravity = 1.0;
		self.pev.friction = 1.0;
		
		g_EntityFuncs.SetModel( self, self.pev.model );

		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.nextthink = pev.ltime + 0.1;
		
		SetTouch( TouchFunction( bucketTouch ) );
		SetThink( ThinkFunction( bucketThink ) );
		SetUse( UseFunction( bucketUse ) );
	}
	
	void bucketUse(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
	{
		if (@holder == null)
		{
			@holder = activator;
		}
		else
		{
			self.pev.velocity = holder.pev.velocity;
			@holder = null;
		}
	}
	
	void bucketTouch(CBaseEntity@ pOther)
	{
		//g_Game.AlertMessage(at_console, "touch hit " + pOther.pev.targetname + "\n");
		if (pOther.pev.ClassNameIs("monster_gonome") == true && filled == 0 )
		{
			filled = 1;
			//g_Game.AlertMessage(at_console, "milk add");
			//milk the cow
			CBaseEntity@ world_filled_bucket;
			@world_filled_bucket = g_EntityFuncs.FindEntityByTargetname(world_filled_bucket, "world_filled_bucket");
			
			g_EntityFuncs.SetModel( self, world_filled_bucket.pev.model ); //display bucket as full
			self.pev.model = world_filled_bucket.pev.model;
			self.pev.targetname = "filled_bucket";
			self.pev.impacttime = MILK_VALUE;
		}
	
		self.pev.velocity = self.pev.velocity + pOther.pev.velocity;
	}
	
	void bucketThink()
	{
		if (@holder != null)
		{
			g_EngineFuncs.MakeVectors(holder.pev.angles);
			self.pev.origin = holder.pev.origin + g_Engine.v_forward * Vector(64,64,-192);
			
			CBasePlayer@ player = cast<CBasePlayer@>(holder);
			int buttons = player.pev.button;
			if ( (buttons & IN_USE) == 0 ) //when stop holding e, drop this
			{
				self.pev.velocity = holder.pev.velocity;
				@holder = null;
			}
		}
		self.pev.nextthink = pev.ltime + 0.1;
	}
	
}

class trigger_seller : ScriptBaseEntity
{
	
	int ObjectCaps()
	{
	return FCAP_IMPULSE_USE;
	}
	
	void Spawn()
	{
		//self.pev.flags = FL_ALWAYSTHINK | FL_ONGROUND;
		
		self.pev.solid = SOLID_TRIGGER;
		self.pev.movetype = MOVETYPE_NONE;
		//self.pev.gravity = 1.0;
		//self.pev.friction = 1.0;
		
		g_EntityFuncs.SetModel( self, self.pev.model );

		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.nextthink = pev.ltime + 0.1;
		
		SetTouch( TouchFunction( triggerTouch ) );
		SetThink( ThinkFunction( triggerThink ) );
		SetUse( UseFunction( triggerUse ) );
	}
	
	void triggerUse(CBaseEntity@ activator, CBaseEntity@ pcaller, USE_TYPE usetype, float flValue)
	{
		g_EntityFuncs.FireTargets(self.pev.target, activator, self, USE_SET);
	}
	
	void triggerTouch(CBaseEntity@ pOther)
	{
		//g_Game.AlertMessage(at_console, "trigger hit " + pOther.pev.targetname + "\n");
		g_EntityFuncs.FireTargets(self.pev.target, pOther, self, USE_SET);
	}
	
	void triggerThink()
	{
		self.pev.nextthink = pev.ltime + 0.1;
	}
	
}

void GrainMapInit()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "func_grain", "func_grain" );
	g_CustomEntityFuncs.RegisterCustomEntity( "func_pushable_custom", "func_pushable_custom" );
	g_CustomEntityFuncs.RegisterCustomEntity( "func_milk_bucket", "func_milk_bucket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_seller", "trigger_seller" );
}