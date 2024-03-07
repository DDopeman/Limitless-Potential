
const int SF_STOMPSHOOTER_FIRE_ONCE = 1;

class env_stompshooter : ScriptBaseEntity
{
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value = 0.0f )
	{
		Vector vecStart = pev.origin;
		Vector vecEnd;
		if (pev.target == "")
		{
			g_EngineFuncs.MakeVectors( pev.angles );
			vecEnd = (g_Engine.v_forward * 1024) + vecStart;
			TraceResult tr;
			g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, self.edict(), tr );
			vecEnd = tr.vecEndPos;
			vecEnd.z = vecStart.z;
		}
		else
		{
			CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname(null, pev.target);
			if (pEntity !is null)
			{
				vecEnd = pEntity.pev.origin;
			}
			else
			{
				g_Game.AlertMessage(at_error, "%1: can't find target '%2'", pev.classname, pev.target);
				return;
			}
		}

		CBaseEntity@ pOwner = null;
		if (pev.netname != "")
		{
			@pOwner = g_EntityFuncs.FindEntityByTargetname(null, pev.netname);
		}

		CBaseEntity@ stomp = g_EntityFuncs.Create("garg_stomp", vecStart, pev.angles, true, pOwner is null ? null : pOwner.edict());
		if (stomp is null)
		{
			g_Game.AlertMessage(at_console, "Failed to create stomp at %1!", vecStart);
		}
		else
		{
			Vector dir = (vecEnd - vecStart);
			stomp.pev.movedir = dir.Normalize();
			stomp.pev.scale = dir.Length();
			stomp.pev.speed = pev.speed;
			g_EntityFuncs.DispatchSpawn(stomp.edict());
		}
		if ((pev.spawnflags & SF_STOMPSHOOTER_FIRE_ONCE) != 0)
		{
			self.SUB_Remove();
		}
	}
}
