
class info_entity_hint : ScriptBaseEntity
{
	void Precache()
	{
		spriteIndex = g_Game.PrecacheModel( string(pev.netname) );
	}
	void Spawn()
	{
		Precache();
	}
	void Use( CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float value )
	{
		if (!self.ShouldToggle(useType, pev.impulse != 0))
			return;
		if (pev.impulse == 0)
		{
			CBaseEntity@ subject = g_EntityFuncs.FindEntityByTargetname( null, pev.target );
			if (subject is null)
				return;
			ehandle = subject;
			SetThink(ThinkFunction(this.ShowThink));
			self.pev.nextthink = g_Engine.time;
		}
		else
		{
			SetThink(null);
			pev.impulse = 0;
		}
	}
	void ShowThink()
	{
		CBaseEntity@ target = ehandle;
		if (target is null)
		{
			// entity removed, stop tracking
			SetThink(null);
			pev.impulse = 0;
			return;
		}

		for (int i = 1; i <= g_Engine.maxClients; i++) {
			CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(i);
			if (player is null or !player.IsConnected()) {
				continue;
			}

			Vector observerHead = player.pev.origin + player.pev.view_ofs;
			Vector targetCenter = target.Center();

			TraceResult tr;
			g_Utility.TraceHull( observerHead, targetCenter, ignore_monsters, point_hull, player.edict(), tr );
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			Vector vecEndPos = tr.vecEndPos;
			bool canSee = pHit !is null and pHit.entindex() == target.entindex() or tr.flFraction == 1;
			if (!canSee)
			{
				Vector targetHead = target.pev.origin + target.pev.view_ofs;
				g_Utility.TraceHull( observerHead, targetHead, ignore_monsters, point_hull, player.edict(), tr );
				@pHit = g_EntityFuncs.Instance( tr.pHit );
				canSee = pHit !is null and pHit.entindex() == target.entindex() or tr.flFraction == 1;
			}
			if (!canSee)
			{
				/*Vector delta = targetCenter - observerHead;
				Vector pos = tr.vecEndPos - delta.Normalize() * 24;
				NetworkMessage m(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_TEMPENTITY, player.edict());
				m.WriteByte(TE_SPRITE);
				m.WriteCoord(pos.x);
				m.WriteCoord(pos.y);
				m.WriteCoord(pos.z);
				m.WriteShort(spriteIndex);
				m.WriteByte(10);
				m.WriteByte(255);
				m.End();*/

				Vector delta = observerHead - targetCenter;
				HUDSpriteParams params;

				Vector vecDir = delta.Normalize();
				vecDir = Vector(vecDir.x + 1, vecDir.y + 1, vecDir.z + 1).opDiv(2);

				g_EngineFuncs.MakeVectors( player.pev.v_angle );
				Vector vecAim = g_Engine.v_forward;

				if (DotProduct(vecAim, (targetCenter - observerHead)) < 0)
				{
					continue;
				}

				vecAim = Vector(vecAim.x + 1, vecAim.y + 1, vecAim.z + 1 ).opDiv(2);

				Vector2D vecHUD = ((vecDir + vecAim)/2).Make2D();

				params.channel = 6;
				params.spritename = "fi/biosci.spr";
				params.x = vecHUD.x ;
				params.y = vecHUD.y ;
				params.holdTime = 0.5;
				params.color1 = RGBA_WHITE;
				g_PlayerFuncs.HudCustomSprite( player, params );
			}
		}
		pev.nextthink = g_Engine.time + 0.5;
	}

	EHandle ehandle;
	int spriteIndex;
}
