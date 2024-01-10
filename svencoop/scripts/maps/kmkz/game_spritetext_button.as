// button used by game_sprite_text

class CGameSpriteTextButton: ScriptBaseAnimating
{
	EHandle TargetEntity_EHandle;
	EHandle CreatorEntity_EHandle;

	void Precache()
	{

	}

	int ObjectCaps()
	{
		return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE) & ~FCAP_ACROSS_TRANSITION;
	}

	void Spawn()
	{
		Precache();
		pev.solid = SOLID_NOT;
		self.pev.rendermode = 4;
		self.pev.renderamt = 0;
		g_EntityFuncs.SetOrigin(self, pev.origin);
		g_EntityFuncs.SetModel(self, "sprites/dot.spr"); 
		
		pev.movetype = MOVETYPE_FLY;		
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		//string but_target = self.pev.target;
		CBaseEntity@ TargetEntity = g_EntityFuncs.FindEntityByTargetname( @TargetEntity, self.pev.target);
		TargetEntity_EHandle = TargetEntity;
		
		//GameSpritetext::game_spritetext.nothing();
		
		if (TargetEntity_EHandle)
		{
			g_EntityFuncs.FireTargets(self.pev.target, null, @self, USE_TOGGLE, 0.0f, 0.0f);
			
			string selfname = self.pev.targetname;
			string creator = selfname.SubString(0, uint(selfname.Length())- 8);
			CBaseEntity@ CreatorEntity = g_EntityFuncs.FindEntityByTargetname( @CreatorEntity, creator);
			CreatorEntity_EHandle = CreatorEntity;
			//g_Game.AlertMessage(at_console, "creator: " + creator, g_Engine.time);
			if (CreatorEntity_EHandle) 
			{
				g_EntityFuncs.FireTargets(CreatorEntity.pev.targetname, null, @self, USE_TOGGLE, 0.0f, 0.0f);
			}
			
			CreatorEntity.pev.iuser1 = 1;
			CreatorEntity.pev.iuser2 = 1;
			CreatorEntity.pev.iuser3 = 1;
			CreatorEntity.pev.iuser4 = 1;
			CBaseEntity@ Button1Entity = g_EntityFuncs.FindEntityByTargetname( @Button1Entity, creator + "_button1");
			CBaseEntity@ Button2Entity = g_EntityFuncs.FindEntityByTargetname( @Button2Entity, creator + "_button2");
			CBaseEntity@ Button3Entity = g_EntityFuncs.FindEntityByTargetname( @Button3Entity, creator + "_button3");
			CBaseEntity@ Button4Entity = g_EntityFuncs.FindEntityByTargetname( @Button4Entity, creator + "_button4");
			g_EntityFuncs.Remove( @Button1Entity );
			g_EntityFuncs.Remove( @Button2Entity );
			g_EntityFuncs.Remove( @Button3Entity );
			g_EntityFuncs.Remove( @Button4Entity );
		}
	}
}

void RegisterGameSpriteTextButton()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CGameSpriteTextButton", "game_spritetext_button");
}
