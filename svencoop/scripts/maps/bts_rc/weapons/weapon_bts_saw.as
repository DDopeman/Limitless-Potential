/*
* HECU Standard M249 SAW Light Machine Gun
* Author: Rizulix
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_saw
{
    enum m249_e
    {
        SLOWIDLE = 0,
        IDLE2,
        RELOAD_START,
        RELOAD_END,
        HOLSTER,
        DRAW,
        SHOOT1,
        SHOOT2,
        SHOOT3
    };

    // Weapon info
    int MAX_CARRY = 150;
    int MAX_CLIP = 100;
    // int DEFAULT_GIVE = Math.RandomLong( 19, 100 );
    int AMMO_GIVE = MAX_CLIP;
    int AMMO_DROP = AMMO_GIVE;
    int WEIGHT = 20;
    // Weapon HUD
    int SLOT = 5;
    int POSITION = 4;
    // Vars
    int DAMAGE = 19;
    Vector SHELL( 14.0f, 8.0f, -10.0f );

    const int m_iLink = g_Game.PrecacheModel( "models/saw_link.mdl" );

    // Knockback thing
    const CCVar@ g_M249Knockback = CCVar( "m249_knockback", 1, "", ConCommandFlag::AdminOnly ); // as_command m249_knockback

    class weapon_bts_saw : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        private bool m_bAlternatingEject;
        private int m_iTracerCount;

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_saw.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 19, MAX_CLIP );
            self.FallInit();

            m_iTracerCount = 0;
            m_bAlternatingEject = false;
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = AMMO_DROP;
            info.iMaxAmmo2 = -1;
            info.iAmmo2Drop = -1;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName( pev.classname );
            info.iFlags = m_flags;
            info.iWeight = WEIGHT;
            return true;
        }

        bool Deploy()
        {
            return bts_deploy( "models/bts_rc/weapons/v_saw.mdl", "models/bts_rc/weapons/p_saw.mdl", DRAW, "saw", 1 );
        }

        void Holster( int skiplocal = 0 )
        {
            SetThink( null );
            BaseClass.Holster( skiplocal );
        }

        void ItemPostFrame()
        {
            BaseClass.ItemPostFrame();

            // Speed up player reload anim
            // Surely no one will change anim_extensions :clueless:
            if( m_pPlayer.pev.sequence == 172 || m_pPlayer.pev.sequence == 176 ) // ref_reload_saw, crouch_reload_saw
                m_pPlayer.pev.framerate = 2.0f;
        }

        bool PlayEmptySound()
        {
            if( self.m_bPlayEmptySound )
            {
                self.m_bPlayEmptySound = false;
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
            }
            return false;
        }

        void PrimaryAttack()
        {
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.12f;
                return;
            }

            m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

            --self.m_iClip;
            m_bAlternatingEject = !m_bAlternatingEject;

            m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;

            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
            Vector vecSpread;

            bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

            float CONE = Accuracy( ( m_pPlayer.IsMoving() ? 0.02618f : 0.01f ), ( m_pPlayer.IsMoving() ? 0.1f : 0.05f ), 0.01f, 0.05f );

            float x, y;
            g_Utility.GetCircularGaussianSpread( x, y );

            Vector vecDir = vecAiming + x * CONE * g_Engine.v_right + y * CONE * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            bts_post_attack(tr);

            // each 2 bullets
            if( ( m_iTracerCount++ % 2 ) == 0 )
            {
                Vector vecTracerSrc = vecSrc + Vector( 0.0f, 0.0f, -4.0f ) + g_Engine.v_right * 2.0f + g_Engine.v_forward * 16.0f;
                NetworkMessage tracer( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc );
                    tracer.WriteByte( TE_TRACER );
                    tracer.WriteCoord( vecTracerSrc.x );
                    tracer.WriteCoord( vecTracerSrc.y );
                    tracer.WriteCoord( vecTracerSrc.z );
                    tracer.WriteCoord( tr.vecEndPos.x );
                    tracer.WriteCoord( tr.vecEndPos.y );
                    tracer.WriteCoord( tr.vecEndPos.z );
                tracer.End();
            }

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }

            self.SendWeaponAnim( Math.RandomLong( SHOOT1, SHOOT3 ), 0, pev.body );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/gun_fire4.wav", VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );
            m_pPlayer.pev.punchangle.x = is_trained_personal ? Math.RandomFloat( -2.0f, 2.0f ) : Math.RandomFloat( -10.0f, 2.0f );
            m_pPlayer.pev.punchangle.y = is_trained_personal ? Math.RandomFloat( -1.0f, 1.0f ) : Math.RandomFloat( -2.0f, 1.0f );

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
            Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_bAlternatingEject ? m_iLink : models::saw_shell, TE_BOUNCE_SHELL );

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate("!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = g_Engine.time + 0.099f;
            self.m_flTimeWeaponIdle = g_Engine.time + 0.2f;

            if( g_M249Knockback.GetBool() )
            {
                Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

                const float flZVel = m_pPlayer.pev.velocity.z;

                Vector vecInvPushDir = g_Engine.v_forward * ( is_trained_personal ? 60.0f : 35.0f );
                float flNewZVel = g_EngineFuncs.CVarGetFloat( "sv_maxspeed" );

                if( vecInvPushDir.z >= 10.0f )
                    flNewZVel = vecInvPushDir.z;

                // Yeah... no deathmatch knockback
                m_pPlayer.pev.velocity = m_pPlayer.pev.velocity - vecInvPushDir;
                m_pPlayer.pev.velocity.z = flZVel;
            }
        }

        void Reload()
        {
            if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 )
                return;

            self.DefaultReload( MAX_CLIP, RELOAD_START, 1.0f, pev.body );
            self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.78f;
            SetThink( ThinkFunction( this.FinishAnim ) );
            pev.nextthink = g_Engine.time + 1.33f;
            BaseClass.Reload();
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            const float flNextIdle = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );
            if( flNextIdle <= 0.95f )
            {
                self.SendWeaponAnim( SLOWIDLE, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
            }
            else
            {
                self.SendWeaponAnim( IDLE2, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 6.16f;
            }
        }

        private int RecalculateBody()
        {
            if( self.m_iClip <= 0 )
                return 8;
            else if( self.m_iClip > 0 && self.m_iClip < 8 )
                return 9 - self.m_iClip;
            else
                return 0;
        }

        private void FinishAnim()
        {
            SetThink( null );
            self.SendWeaponAnim( RELOAD_END, 0, pev.body );
        }
    }
}
