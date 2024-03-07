// Based on Field Intensity code, ported to AngelScript

const string EXTINGUISHER_EXPLO_SOUND = "weapons/explode3.wav";
const string EXTINGUISHER_STEAM_SOUND = "ambience/steamjet1.wav";
const string EXTINGUISHER_SPRITE = "sprites/xsmoke1.spr";

const int SF_EXTINGUISHER_REPEATABLE = 1;

class env_extinguisher : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();
		SetUse(UseFunction(this.ExtinguisherUse));
	}
	void Precache()
	{
		g_Game.PrecacheModel(EXTINGUISHER_SPRITE);
		g_SoundSystem.PrecacheSound(EXTINGUISHER_EXPLO_SOUND);
		g_SoundSystem.PrecacheSound(EXTINGUISHER_STEAM_SOUND);
	}

	void ExtinguisherUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, EXTINGUISHER_EXPLO_SOUND, 1.0, ATTN_STATIC );
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, EXTINGUISHER_STEAM_SOUND, 1.0, ATTN_STATIC );

		g_EngineFuncs.MakeVectors(self.pev.angles);

		array<float> scales = {1.0, 1.5, 1.75};
		const float turnoffTime = g_Engine.time + 1.5;

		for (uint i=0; i<scales.length(); ++i)
		{
			CSprite @blastSprite = g_EntityFuncs.CreateSprite(EXTINGUISHER_SPRITE, pev.origin + i*(g_Engine.v_forward * 16.0), false);
			if (blastSprite !is null)
			{
				blastSprite.AnimateAndDie(10.0);
				blastSprite.pev.dmgtime = turnoffTime;
				blastSprite.pev.renderamt = 125;
				blastSprite.pev.rendermode = kRenderTransAdd;
				blastSprite.pev.scale = scales[i];
			}
		}

		if (pev.target != '')
		{
			if (self.GetTargetname() == pev.target) {
				g_Game.AlertMessage(at_error, "%1 (%2) triggers itself!\n", pev.classname, pev.targetname);
			} else {
				g_EntityFuncs.FireTargets(pev.target, self, self, USE_ON);
			}
		}

		SetThink(ThinkFunction(this.TurnOff));
		self.pev.nextthink = turnoffTime;
		SetUse(null);
	}
	void TurnOff()
	{
		if (pev.target != '')
		{
			g_EntityFuncs.FireTargets(self.pev.target, self, self, USE_OFF);
		}

		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, EXTINGUISHER_STEAM_SOUND );

		SetThink(null);
		if ((pev.spawnflags & SF_EXTINGUISHER_REPEATABLE) != 0)
		{
			SetUse(UseFunction(this.ExtinguisherUse));
		}
		else
		{
			self.SUB_Remove();
		}
	}
};
