namespace M79_ROCKET
{
    class CM79Rocket : ScriptBaseEntity
    {
        void Spawn()
        {
            g_EntityFuncs.SetSize( pev, g_vecZero, g_vecZero );

            pev.movetype = MOVETYPE_TOSS;
            pev.solid = SOLID_BBOX;

            // RGBA(190, 190, 190)
            NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                m1.WriteByte( TE_BEAMFOLLOW );
                m1.WriteShort( self.entindex() );
                m1.WriteShort( models::laserbeam );
                m1.WriteByte( 20 ); // life
                m1.WriteByte( 4 ); // width
                m1.WriteByte( 190 ); // r
                m1.WriteByte( 190 ); // g
                m1.WriteByte( 190 ); // b
                m1.WriteByte( 200 ); // brightness
            m1.End();

            SetThink( ThinkFunction( this.GrenadeThink ) );
            pev.nextthink = g_Engine.time + 0.01f;
            SetTouch( TouchFunction( this.GrenadeTouch ) );
        }

        void GrenadeThink()
        {
            pev.angles = Math.VecToAngles( pev.velocity.Normalize() );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void GrenadeTouch( CBaseEntity@ pOther )
        {
            if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
            {
                self.UpdateOnRemove();
                self.pev.flags |= FL_KILLME;
                return;
            }

            Explode();
        }

        void Explode()
        {
            TraceResult tr;
            Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32.0f;
            Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64.0f;
            g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

            pev.model = string_t(); // invisible
            pev.solid = SOLID_NOT;

            pev.takedamage = DAMAGE_NO;

            // Pull out of the wall a bit
            if( tr.flFraction != 1.0f )
                pev.origin = tr.vecEndPos + ( tr.vecPlaneNormal * 24.0f );

            NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
                m1.WriteByte( TE_EXPLOSION );
                m1.WriteCoord( pev.origin.x );
                m1.WriteCoord( pev.origin.y );
                m1.WriteCoord( pev.origin.z );

                if( g_EngineFuncs.PointContents( pev.origin ) != CONTENTS_WATER )
                {
                    for( int i = Math.RandomLong( 0, 3 ); i <= 3; i++ )
                        g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

                    m1.WriteShort( models::zerogxplode );
                }
                else
                {
                    m1.WriteShort( models::WXplo1 );
                }

                m1.WriteByte( 15 ); // scale * 10
                m1.WriteByte( 30 ); // framerate
                m1.WriteByte( TE_EXPLFLAG_NONE );
            m1.End();

            CSoundEnt@ sound = GetSoundEntInstance();
            if( sound !is null )
                sound.InsertSound( bits_SOUND_COMBAT, pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0f, self );

            entvars_t@ pevOwner = pev;
            if( pev.owner !is null )
                @pevOwner = pev.owner.vars;

            g_WeaponFuncs.RadiusDamage( pev.origin, pev, pevOwner, pev.dmg, pev.fuser1, CLASS_NONE, DMG_MORTAR );

            g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong( 0, 1 ) );

            // debris sound?

            pev.effects |= EF_NODRAW;
            SetThink( ThinkFunction( this.Smoke ) );
            pev.velocity = g_vecZero;
            pev.nextthink = g_Engine.time + 0.5;
        }

        void Smoke()
        {
            if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_WATER )
            {
                g_Utility.Bubbles( pev.origin - Vector( 64, 64, 64 ), pev.origin + Vector( 64, 64, 64 ), 100 );
            }
            else
            {
                NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
                    msg1.WriteByte( TE_SMOKE );
                    msg1.WriteCoord( pev.origin.x );
                    msg1.WriteCoord( pev.origin.y );
                    msg1.WriteCoord( pev.origin.z );
                    msg1.WriteShort( models::steam1 );
                    msg1.WriteByte( 40 ); // scale * 10
                    msg1.WriteByte( 6 ); // framerate
                msg1.End();
            }
            self.UpdateOnRemove();
            self.pev.flags |= FL_KILLME;
        }
    }

    CM79Rocket@ Shoot( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, float flRadius, const string& in szModel )
    {
        CBaseEntity@ entity = g_EntityFuncs.CreateEntity( "m79_rocket" );

        if( entity is null )
            return null;

        CM79Rocket@ pRocket = cast<CM79Rocket@>( CastToScriptClass( entity ) );

        if( pRocket is null )
            return null;

        g_EntityFuncs.SetModel( pRocket.self, szModel );
        g_EntityFuncs.SetOrigin( pRocket.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pRocket.self.edict() );

        pRocket.pev.velocity = vecVelocity;
        pRocket.pev.angles = Math.VecToAngles( pRocket.pev.velocity );

        pRocket.pev.dmg = flDmg;
        pRocket.pev.fuser1 = flRadius;
        @pRocket.pev.owner = pevOwner.pContainingEntity;

        return pRocket;
    }
}
