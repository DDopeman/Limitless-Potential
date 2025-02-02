// Flare Projectile ( Counter-Strike 1.6's Grenade Projectile Base Modified )
// Author: KernCore, Mikk, RaptorSKA
// Rewrited by Rizulix for bts_rc (december 2024)
// and based on env_flare at:
// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/weapon_flaregun.cpp

namespace FLARE
{

class CFlare : ScriptBaseEntity // ScriptBaseMonsterEntity
{
    private float m_flBounceTime, m_flNextAttack;
    private int m_iBounces;

    bool m_fRemoveAfterHit = false;
    bool m_fAttachToWorld = false;

    void Spawn()
    {
        g_EntityFuncs.SetSize( pev, Vector( -2, -2, -2 ), Vector( 2, 2, 2 ) );

        pev.solid = SOLID_BBOX;
        pev.movetype = MOVETYPE_NONE;
        pev.friction = 0.6f;
        pev.gravity = 0.5f;

        pev.dmg = 1.0f;
        pev.dmgtime = g_Engine.time + 30.0f;
        pev.effects |= EF_NOSHADOW;

        IgniteSound();
    }

    int Classify()
    {
        return CLASS_NONE;
    }

    void FlareThink()
    {
        if( pev.dmgtime != -1.0f )
        {
            if( pev.dmgtime < g_Engine.time )
            {
                FlareLight( 2, 64 );
                g_EntityFuncs.Remove( self );
                return;
            }
        }

        if( pev.waterlevel > WATERLEVEL_FEET )
        {
            g_Utility.Bubbles( pev.absmin, pev.absmax, 1 );
        }
        else
        {
            if( Math.RandomLong( 0, 8 ) == 1 )
            {
                g_Utility.Sparks( pev.origin );
            }
        }

        FlareLight( 1, 1 );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void FlareTouch( CBaseEntity@ pOther )
    {
        if( @pOther.edict() == @pev.owner )
            return;

        if( ( m_iBounces < 10 ) && pev.waterlevel < WATERLEVEL_FEET )
        {
            g_Utility.Sparks( pev.origin );
        }

        TraceResult tr = g_Utility.GetGlobalTrace();
    Vector vecDir = pev.velocity.Normalize();
        Vector vecNewDir = vecDir - 2.0f * tr.vecPlaneNormal * DotProduct(tr.vecPlaneNormal, vecDir);
        pev.angles = Math.VecToAngles(vecNewDir);

        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            entvars_t@ pevOwner = pev;
            if( pev.owner !is null )
                @pevOwner = pev.owner.vars;

            g_WeaponFuncs.ClearMultiDamage();

            if( pOther.IsPlayer() )
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BURN | DMG_NEVERGIB );
            else
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_POISON | DMG_NEVERGIB );

            g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

            g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/weapons/flarehitbod1.wav", VOL_NORM, ATTN_NORM );

            if( m_fRemoveAfterHit )
            {
                pev.velocity = pev.velocity * 0.1f;
                // pev.movetype = MOVETYPE_FLY;
                pev.gravity = 1.0f;

                // Die( 0.5f );
                g_EntityFuncs.Remove( self );
                return;
            }
        }
        else
        {
            if( m_iBounces == 0 )
            {
                if( pOther.pev.ClassNameIs( "worldspawn" ) )
                {
                    float flSurfDot = DotProduct( tr.vecPlaneNormal, vecDir );
                    if( m_fAttachToWorld && !( tr.vecPlaneNormal.z < -0.5f && flSurfDot > -0.9f ) )
                    {
                        // g_EntityFuncs.SetOrigin( self, pev.origin - vecDir * 12.0f );

                        pev.velocity = g_vecZero;
                        pev.avelocity = g_vecZero;
                        pev.angles = Math.VecToAngles( vecDir );
                        // pev.angles.y -= 90.0f;
                        pev.movetype = MOVETYPE_NONE;
                        pev.effects |= EF_NODRAW;

                        SetTouch( TouchFunction( this.FlareBurnTouch ) );
                        // g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong( 0, 1 ) );
                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "bts_rc/weapons/flarehit1.wav", Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 7 ) );
                        return;
                    }
                }
            }

            // if( pev.velocity.Length() > 250.0f )
            // {
            //  g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong( 0, 1 ) );
            // }

            // pev.movetype = MOVETYPE_FLY;
            pev.gravity = 0.8f;

            m_iBounces++;
            if( pev.flags & FL_ONGROUND == 0 )
                BounceSounds();

            // @pev.owner = null;
            pev.velocity.x *= 0.8f;
            pev.velocity.y *= 0.8f;

            if( pev.velocity.Length() < 64.0f )
            {
                pev.velocity = g_vecZero;
                pev.angles.x = 0.0f;
                pev.angles.z = 0.0f;
                pev.movetype = MOVETYPE_NONE;

                SetTouch( TouchFunction( this.FlareBurnTouch ) );
            }
        }
    }

    void FlareBurnTouch( CBaseEntity@ pOther )
    {
        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            if( m_flNextAttack < g_Engine.time )
            {
                entvars_t@ pevOwner = pev;
                if( pev.owner !is null )
                    @pevOwner = pev.owner.vars;

                TraceResult tr = g_Utility.GetGlobalTrace();

                g_WeaponFuncs.ClearMultiDamage();
                pOther.TraceAttack( pevOwner, 1.0f, g_Engine.v_forward, tr, DMG_BURN | DMG_NEVERGIB );
                g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

                m_flNextAttack = g_Engine.time + 1.0f;
            }
        }
    }

    void Start( float flLifeTime )
    {
        IgniteSound();

        if ( flLifeTime > 0.0f )
            pev.dmgtime = g_Engine.time + flLifeTime;
        else
            pev.dmgtime = -1.0f;

        pev.effects &= ~EF_NODRAW;

        SetThink( ThinkFunction( FlareThink ) );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void Die( float flFadeTime )
    {
        pev.dmgtime = g_Engine.time + flFadeTime;

        SetThink( ThinkFunction( FlareThink ) );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void BounceSounds()
    {
        if( g_Engine.time < m_flBounceTime )
            return;

        m_flBounceTime = g_Engine.time + Math.RandomFloat( 0.2f, 0.3f );

        if( g_Utility.GetGlobalTrace().flFraction < 1.0f )
        {
            if( g_Utility.GetGlobalTrace().pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( g_Utility.GetGlobalTrace().pHit );
                if( pHit.IsBSPModel() )
                {
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "bts_rc/weapons/flare_bounce.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                }
            }
        }
    }

    void FlareTrail()
    {
        // RGBA(180, 10, 10)
        NetworkMessage msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            msg.WriteByte( TE_BEAMFOLLOW );
            msg.WriteShort( self.entindex() );
            msg.WriteShort( models::laserbeam );
            msg.WriteByte( 20 ); // life
            msg.WriteByte( 4 ); // width
            msg.WriteByte( 180 ); // r
            msg.WriteByte( 10 ); // g
            msg.WriteByte( 10 ); // b
            msg.WriteByte( 200 ); // brightness
        msg.End();
    }

    void FlareLight( uint8 life, uint8 decayRate )
    {
        // RGBA(255, 21, 18)
        NetworkMessage msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            msg.WriteByte( TE_DLIGHT ); // temp entity you want to implement
            msg.WriteCoord( pev.origin.x ); // vector x
            msg.WriteCoord( pev.origin.y ); // vector y
            msg.WriteCoord( pev.origin.z ); // vector z
            msg.WriteByte( pev.waterlevel > WATERLEVEL_FEET ? 9 : 18 ); // Radius
            msg.WriteByte( 255 ); // R
            msg.WriteByte( 21 ); // G
            msg.WriteByte( 18 ); // B
            msg.WriteByte( life ); // Life
            msg.WriteByte( decayRate ); // Decay
        msg.End();
    }

    void IgniteSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "bts_rc/weapons/flare_on.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
    }
}

CFlare@ Toss( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, float flDuration, float flSparkAfter )
{
    CFlare@ pFlare = cast<CFlare>( CastToScriptClass( g_EntityFuncs.CreateEntity( "flare" ) ) );
    if( pFlare is null )
        return null;

    g_EntityFuncs.SetModel( pFlare.self, "models/bts_rc/weapons/flare.mdl" );
    g_EntityFuncs.SetOrigin( pFlare.self, vecStart );
    g_EntityFuncs.DispatchSpawn( pFlare.self.edict() );

    pFlare.pev.dmg = flDmg;
    pFlare.pev.movetype = MOVETYPE_BOUNCE;

    pFlare.pev.velocity = vecVelocity;
    pFlare.pev.angles = Math.VecToAngles( pFlare.pev.velocity );
    @pFlare.pev.owner = pevOwner.pContainingEntity;;

    // Start up the flare
    pFlare.Start( flDuration );
    // Burn out time
    pFlare.pev.dmgtime = g_Engine.time + flDuration;

    pFlare.SetThink( ThinkFunction( pFlare.FlareThink ) );
    pFlare.pev.nextthink = g_Engine.time + flSparkAfter; // Don't start sparking immediately
    pFlare.SetTouch( TouchFunction( pFlare.FlareTouch ) );

    return pFlare;
}

CFlare@ Shoot( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, float flDuration )
{
    CFlare@ pFlare = cast<CFlare>( CastToScriptClass( g_EntityFuncs.CreateEntity( "flare" ) ) );
    if( pFlare is null )
        return null;

    g_EntityFuncs.SetModel( pFlare.self, "models/bts_rc/weapons/flare.mdl" );
    g_EntityFuncs.SetOrigin( pFlare.self, vecStart );
    g_EntityFuncs.DispatchSpawn( pFlare.self.edict() );

    pFlare.FlareTrail();
    pFlare.m_fAttachToWorld = true;
    pFlare.m_fRemoveAfterHit = true;

    pFlare.pev.dmg = flDmg;
    pFlare.pev.movetype = MOVETYPE_BOUNCE;

    pFlare.pev.velocity = vecVelocity;
    pFlare.pev.angles = Math.VecToAngles( pFlare.pev.velocity );
    @pFlare.pev.owner = pevOwner.pContainingEntity;;

    // Start up the flare
    pFlare.Start( flDuration );
    // Burn out time
    pFlare.pev.dmgtime = g_Engine.time + flDuration;

    pFlare.SetThink( ThinkFunction( pFlare.FlareThink ) );
    pFlare.pev.nextthink = g_Engine.time + 0.5f; // Don't start sparking immediately
    pFlare.SetTouch( TouchFunction( pFlare.FlareTouch ) );

    return pFlare;
}
}