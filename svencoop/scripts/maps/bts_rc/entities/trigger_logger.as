namespace trigger_logger
{
    HUDTextParams HudParams;

    class trigger_logger : ScriptBaseEntity
    {
        void Spawn()
        {
            self.pev.solid = SOLID_TRIGGER;
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.effects |= EF_NODRAW;
            g_EntityFuncs.SetModel( self, string( self.pev.model ) );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }

        void Touch( CBaseEntity@ pOther )
        {
            if( pOther !is null && pOther.IsPlayer() )
            {
                HudParams.x = -1;
                HudParams.effect = 0;
                HudParams.r1 = RGBA_SVENCOOP.r;
                HudParams.g1 = RGBA_SVENCOOP.g;
                HudParams.b1 = RGBA_SVENCOOP.b;
                HudParams.a1 = 0;
                HudParams.r2 = RGBA_SVENCOOP.r;
                HudParams.g2 = RGBA_SVENCOOP.g;
                HudParams.b2 = RGBA_SVENCOOP.b;
                HudParams.a2 = 0;
                HudParams.fadeinTime = 0; 
                HudParams.fadeoutTime = 0.25;
                HudParams.fxTime = 0;
                HudParams.holdTime = 2;
                HudParams.channel = 3;
                HudParams.y = 0.90;

                g_PlayerFuncs.HudMessage( cast<CBasePlayer@>(pOther), HudParams, string( self.pev.message ) + "\n" );
            }
        }
    }
}
