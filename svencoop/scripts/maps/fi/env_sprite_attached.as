const int SF_SPRITE_STARTON = 0x0001;

class env_sprite_attached : ScriptBaseEntity
{
	EHandle spriteHandle;

	void Precache()
	{
		g_Game.PrecacheModel( pev.model );
	}
	void Spawn()
	{
		Precache();
	}
	void PostSpawn()
	{
		CSprite @sprite = g_EntityFuncs.CreateSprite(pev.model, pev.origin, false);
		if (sprite is null)
			return;
		sprite.pev.rendermode = pev.rendermode;
		sprite.pev.rendercolor = pev.rendercolor;
		sprite.pev.renderamt = pev.renderamt;
		sprite.pev.renderfx = pev.renderfx;
		sprite.pev.framerate = pev.framerate;
		sprite.pev.scale = pev.scale;

		if( pev.targetname != '' && ( pev.spawnflags & SF_SPRITE_STARTON ) == 0 )
			sprite.TurnOff();
		else
			sprite.TurnOn();

		AttachToEntity(sprite);
		spriteHandle = sprite;
	}
	void SelfRemove()
	{
		self.SUB_Remove();
	}
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		CBaseEntity@ pSprite = spriteHandle.GetEntity();
		if (pSprite !is null)
		{
			pSprite.Use(pActivator, pCaller, useType, value);
			if ((pSprite.pev.effects & EF_NODRAW) == 0)
			{
				AttachToEntity(cast<CSprite>(pSprite));
			}
		}
	}
	void UpdateOnRemove()
	{
		CBaseEntity@ pSprite = spriteHandle.GetEntity();
		if (pSprite !is null)
		{
			pSprite.SUB_Remove();
		}
	}
	void AttachToEntity(CSprite@ pSprite)
	{
		if (pev.message != '')
		{
			CBaseEntity @pTemp = g_EntityFuncs.FindEntityByTargetname(null, pev.message);
			if (pTemp !is null)
				pSprite.SetAttachment(pTemp.edict(), int(pev.frags));
		}
	}
}
