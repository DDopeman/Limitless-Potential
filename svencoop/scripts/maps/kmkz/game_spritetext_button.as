// button used by game_sprite_text

class CGameSpriteTextButton: ScriptBaseAnimating
{
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
		CBaseEntity@ TargetEntity = g_EntityFuncs.FindEntityByTargetname( @TargetEntity, self.pev.target);
				
		if (@TargetEntity != null)
		{
			g_EntityFuncs.FireTargets(self.pev.target, @pActivator, @self, USE_TOGGLE, 0.0f, 0.0f);
		}
		
		CBaseEntity@ CreatorEntity = g_EntityFuncs.Instance(self.pev.owner);
				
		if (@CreatorEntity != null)
		{
			g_EntityFuncs.FireTargets(CreatorEntity.pev.targetname, null, @self, USE_TOGGLE, 0.0f, 0.0f);
			CustomKeyvalues@ pKeyValues = CreatorEntity.GetCustomKeyvalues();
			for ( uint I = 1; I < 17; I++ ) {pKeyValues.SetKeyvalue( "$i_button" + string(I), 1 );}
		}	
		else
		{
			g_EntityFuncs.Remove(self);
			return;
		}
		
		g_EntityFuncs.FireTargets(self.pev.owner.vars.targetname, null, @self, USE_SET, 5.0f, 0.0f);
	}
}

void RegisterGameSpriteTextButton()
{
	g_CustomEntityFuncs.RegisterCustomEntity("CGameSpriteTextButton", "game_spritetext_button");
}
