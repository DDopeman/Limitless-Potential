/*
* Glock 17 w/ Torchlight
* Author: Mikk, KernCore, RaptorSKA
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_glock17f
{
    enum btsg17f_e
    {
        IDLE1 = 0,
        IDLE2,
        IDLE3,
        SHOOT,
        SHOOT_EMPTY,
        RELOAD_EMPTY,
        RELOAD,
        DRAW,
        HOLSTER,
        ADD_SILENCER
    };

    enum modes_e
    {
        SEMI_AUTO = 0,
        FULL_AUTO
    };

    // Weapon info
    int MAX_CARRY = 120;
    int MAX_CARRY2 = 10;
    int MAX_CLIP = 17;
    int MAX_CLIP2 = WEAPON_NOCLIP;
    // int DEFAULT_GIVE = Math.RandomLong( 8, 17 );
    // int DEFAULT_GIVE2 = Math.RandomLong( 1, 2 );
    int AMMO_GIVE = MAX_CLIP;
    int AMMO_GIVE2 = 1;
    int AMMO_DROP = AMMO_GIVE;
    int AMMO_DROP2 = AMMO_GIVE2;
    int WEIGHT = 10;
    // Weapon HUD
    int SLOT = 1;
    int POSITION = 7;
    // Vars
    int DAMAGE = 13;
    float DRAIN_TIME = 0.8f;
    Vector SHELL( 32.0f, 6.0f, -12.0f );

    class weapon_bts_glock17f : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        private int m_iFlashBattery
        {
            get const {
                if( !m_pPlayer.GetUserData().exists( pev.classname ) ) {
                    m_pPlayer.GetUserData()[ pev.classname ] = Math.RandomLong( 0, 50 );
                }
                return int( m_pPlayer.GetUserData()[ pev.classname ] );
            }
            set { m_pPlayer.GetUserData()[ pev.classname ] = value; }
        }

        private float m_flFlashLightTime;
        private float m_flRestoreAfter = 0.0f;
        private int m_iCurrentBaterry;

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/hlclassic/w_9mmhandgun.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 8, MAX_CLIP );
            self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
            self.FallInit();
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = AMMO_DROP;
            info.iMaxAmmo2 = MAX_CARRY2;
            info.iAmmo2Drop = AMMO_DROP2;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName( pev.classname );
            info.iFlags = m_flags;
            info.iWeight = WEIGHT;
            return true;
        }

        bool CanDeploy()
        {
            return true;
        }

        bool Deploy()
        {
            m_iCurrentBaterry = m_iFlashBattery;
            m_pPlayer.pev.effects &= ~EF_DIMLIGHT; // just to be sure
            m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
                msg.WriteByte( 0 );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            return bts_deploy( "models/bts_rc/weapons/v_glock17f.mdl", "models/bts_rc/weapons/p_9mmhandgun.mdl", DRAW, "onehanded", 2 );
        }

        void Holster( int skiplocal = 0 )
        {
            SetThink( null );
            g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            if ( m_pPlayer.FlashlightIsOn() )
                FlashlightTurnOff();

            m_flRestoreAfter = 0.0f;
            m_iFlashBattery = m_iCurrentBaterry;
            m_pPlayer.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
            BaseClass.Holster( skiplocal );
        }

        void ItemPostFrame()
        {
            if( m_flFlashLightTime != 0.0f && m_flFlashLightTime <= g_Engine.time )
            {
                if( m_pPlayer.FlashlightIsOn() )
                {
                    if( m_iCurrentBaterry != 0 )
                    {
                        m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
                        --m_iCurrentBaterry;

                        if( m_iCurrentBaterry == 0 )
                            FlashlightTurnOff();
                    }
                }
                else
                {
                    m_flFlashLightTime = 0.0f;
                }

                NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
                    msg.WriteByte( m_iCurrentBaterry );
                msg.End();
            }

            if( m_flRestoreAfter != 0.0f && m_flRestoreAfter <= g_Engine.time )
            {
                m_flRestoreAfter = 0.0f;
                m_pPlayer.pev.effects |= EF_DIMLIGHT;
            }
            BaseClass.ItemPostFrame();
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
            if( self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
                return;
            }

            if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK ) == 0 )
                return;

            m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

            --self.m_iClip;

            m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

            float CONE = ( is_trained_personal ? 0.01f : 0.05f );

            float x, y;
            g_Utility.GetCircularGaussianSpread( x, y );

            Vector vecDir = vecAiming + x * CONE * g_Engine.v_right + y * CONE * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            bts_post_attack(tr);

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }

            self.SendWeaponAnim( self.m_iClip != 0 ? SHOOT : SHOOT_EMPTY, 0, pev.body );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/glock_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
            m_pPlayer.pev.punchangle.x = is_trained_personal ? -2.0f : -2.65f;

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
            Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, models::shell, TE_BOUNCE_SHELL );

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.3f;

            self.m_flNextPrimaryAttack = g_Engine.time + ( is_trained_personal ? 0.05f : 0.10f );

            self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        }

        void SecondaryAttack()
        {
            if( m_iCurrentBaterry == 0 )
            {
                if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
                {
                    self.PlayEmptySound();
                    self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                }
                else
                {
                    SetThink( null );
                    m_flRestoreAfter = 0.0f;
                    self.m_fInReload = false;
                    m_flFlashLightTime = 0.0f;

                    SetThink( ThinkFunction( BaterryRechargeStart ) );
                    pev.nextthink = g_Engine.time + ( 15.0f / 16.0f );

                    self.SendWeaponAnim( HOLSTER, 0, pev.body );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 20.0f; // just block
                }
            }
            else
            {
                if( m_pPlayer.FlashlightIsOn() )
                    FlashlightTurnOff();
                else
                    FlashlightTurnOn();

                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5f;
            }
        }

        void Reload()
        {
            if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            float flNextAttack = self.m_flNextPrimaryAttack - 0.3f;
            if( flNextAttack > g_Engine.time ) // uggly hax
                return;

            if( m_pPlayer.FlashlightIsOn() )
            {
                m_pPlayer.pev.effects &= ~EF_DIMLIGHT;
                m_flRestoreAfter = g_Engine.time + 1.6f;
            }

            self.DefaultReload( MAX_CLIP, self.m_iClip != 0 ? RELOAD : RELOAD_EMPTY, 1.5f, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
            BaseClass.Reload();
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
            {
                case 0: self.SendWeaponAnim( IDLE1, 0, pev.body ); break;
                case 1: self.SendWeaponAnim( IDLE2, 0, pev.body ); break;
                default: self.SendWeaponAnim( IDLE3, 0, pev.body ); break;
            }

            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
        }

        private void BaterryRechargeStart()
        {
            SetThink( ThinkFunction( BaterryRechargeEnd ) );
            pev.nextthink = g_Engine.time + 4.0f;

            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        }

        private void BaterryRechargeEnd()
        {
            SetThink( null );

            self.SendWeaponAnim( DRAW, 0, pev.body );
            m_iFlashBattery = m_iCurrentBaterry = 100;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            m_pPlayer.m_flNextAttack = 0.5f;
            m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 9.0f / 16.0f );
        }

        private void FlashlightTurnOn()
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/flashlight1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
            m_pPlayer.pev.effects |= EF_DIMLIGHT;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
                msg.WriteByte( 1 );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
        }

        private void FlashlightTurnOff()
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/flashlight1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
            m_pPlayer.pev.effects &= ~EF_DIMLIGHT;

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
                msg.WriteByte( 0 );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();

            m_flFlashLightTime = 0.0f;
        }
    }
}
