class env_render_pulse : ScriptBaseEntity
{
	private EHandle m_renderTarget;
	private int m_InitialRenderAmount = 255;
	private bool m_increasing = false;
	void Spawn()
	{
		SetThink( ThinkFunction(this.FindTargetEntity) );
		pev.nextthink = g_Engine.time + 0.5f;
	}
	void FindTargetEntity()
	{
		CBaseEntity@ subject = g_EntityFuncs.FindEntityByTargetname( null, pev.target );
		m_renderTarget = EHandle(subject);
		if (subject !is null)
		{
			m_InitialRenderAmount = int(subject.pev.renderamt);
			SetThink( ThinkFunction(this.Pulsate) );
			pev.nextthink = g_Engine.time + 0.1f;
		}
	}
	void Pulsate()
	{
		CBaseEntity@ subject = m_renderTarget.GetEntity();
		if (subject !is null)
		{
			if (m_increasing)
			{
				subject.pev.renderamt += 7;
				if (subject.pev.renderamt >= m_InitialRenderAmount)
				{
					subject.pev.renderamt = m_InitialRenderAmount;
					m_increasing = false;
				}
			}
			else
			{
				subject.pev.renderamt -= 7;
				if (subject.pev.renderamt <= m_InitialRenderAmount/2)
				{
					subject.pev.renderamt = m_InitialRenderAmount/2;
					m_increasing = true;
				}
			}
			pev.nextthink = g_Engine.time + 0.1f;
		}
		else
		{
			self.SUB_Remove();
		}
	}
}
