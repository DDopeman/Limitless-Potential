/*
* Mossberg 500 w/ Torchlight Attached
* Models: ZikShadow
* Scripts: Mikk, RaptorSKA
* Sound: RaptorSKA
* Sprites: ZikShadow
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_sbshotgun
{
    enum sbshotgun_e
    {
        IDLE = 0,
        SHOOT,
        SHOOT2,
        RELOAD,
        PUMP,
        START_RELOAD,
        DRAW,
        HOLSTER,
        IDLE4,
        IDLE_DEEP
    };

    // Weapon info
    int MAX_CARRY = 30;
    int MAX_CARRY2 = 10;
    int MAX_CLIP = 6;
    int MAX_CLIP2 = WEAPON_NOCLIP;
    // int DEFAULT_GIVE = Math.RandomLong( 1, 6 );
    // int DEFAULT_GIVE2 = Math.RandomLong( 1, 2 );
    int AMMO_GIVE = MAX_CLIP;
    int AMMO_GIVE2 = 1;
    int AMMO_DROP = AMMO_GIVE;
    int AMMO_DROP2 = AMMO_GIVE2;
    int WEIGHT = 15;
    // Weapon HUD
    int SLOT = 2;
    int POSITION = 6;
    // Vars
    int DAMAGE = 22;
    int PELLETS = 4;
    float DRAIN_TIME = 0.8f;
    Vector CONE( 0.08716f, 0.04362f, 0.0f );
    Vector SHELL( 14.0f, 6.0f, -34.0f );

    class weapon_bts_sbshotgun : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
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

        private float m_flTimeWeaponReload;
        private float m_flFlashLightTime;
        private float m_flRestoreAfter = 0.0f;
        private int m_iCurrentBaterry;
        private int m_fInReloadState;

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_sbshotgun.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 1, MAX_CLIP );
            self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
            self.FallInit();

            m_fInReloadState = 0;
            m_flTimeWeaponReload = 0.0f;
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

            return bts_deploy( "models/bts_rc/weapons/v_sbshotgun.mdl", "models/bts_rc/weapons/p_sbshotgun.mdl", DRAW, "shotgun", 2 );
        }

        void Holster( int skiplocal = 0 )
        {
            SetThink( null );
            g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            if ( m_pPlayer.FlashlightIsOn() )
                FlashlightTurnOff();

            m_fInReloadState = 0;
            m_flRestoreAfter = 0.0f;
            self.m_fInReload = false;
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

            if( m_flRestoreAfter > 0.0f && m_flRestoreAfter <= g_Engine.time )
            {
                m_flRestoreAfter = 0.0f;
                m_pPlayer.pev.effects |= EF_DIMLIGHT;
            }
            BaseClass.ItemPostFrame();

            if( self.m_fInReload && m_fInReloadState != 0 )
                self.Reload();
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
            // don't fire underwater
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.12f;
                return;
            }

            if( self.m_iClip <= 0 )
            {
                self.Reload();
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
                return;
            }

            // force reload end (PUMP)
            if( FinishReload( true ) )
                return;

            m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

            --self.m_iClip;

            m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            float x, y;
            Vector vecDir, vecEnd;
            TraceResult tr;
            CBaseEntity@ pHit;
            for( int i = 0; i < PELLETS; i++ )
            {
                g_Utility.GetCircularGaussianSpread( x, y );

                vecDir = vecAiming + x * CONE.x * g_Engine.v_right + y * CONE.y * g_Engine.v_up;
                vecEnd = vecSrc + vecDir * 2048.0f;

                g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
                self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 2048.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
                bts_post_attack(tr);

                if( tr.flFraction < 1.0f && tr.pHit !is null )
                {
                    @pHit = g_EntityFuncs.Instance( tr.pHit );
                    if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                        g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
                }
            }

            bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

            self.SendWeaponAnim( SHOOT, 0, pev.body );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/sbshotgun_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
            m_pPlayer.pev.punchangle.x = is_trained_personal ? -5.0f : -11.0f;

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
            Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.85f;
            self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;

            if( !is_trained_personal )
            {
                const float flZVel = m_pPlayer.pev.velocity.z;
                m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * -64.0f; // Knockback!
                m_pPlayer.pev.velocity.z = flZVel;
            }

            if( self.m_iClip != 0 )
            {
                SetThink( ThinkFunction( PumpWeapon ) );
                pev.nextthink = g_Engine.time + 0.5f;
            }
        }

        void SecondaryAttack()
        {
            if( self.m_fInReload )
                return;

            if( m_iCurrentBaterry == 0 )
            {
                if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 || FinishReload( true ) ) // force reload end (PUMP)
                {
                    self.PlayEmptySound();
                    self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                }
                else
                {
                    SetThink( null );
                    m_fInReloadState = 0;
                    m_flRestoreAfter = 0.0f;
                    self.m_fInReload = false;
                    m_flFlashLightTime = 0.0f;

                    SetThink( ThinkFunction( BaterryRechargeStart ) );
                    pev.nextthink = g_Engine.time + ( 10.0f / 30.0f );

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

            // don't reload until recoil is done
            if( self.m_flNextPrimaryAttack > g_Engine.time )
                return;

            if( m_flTimeWeaponReload > g_Engine.time )
                return;

            if( m_pPlayer.FlashlightIsOn() )
            {
                m_pPlayer.pev.effects &= ~EF_DIMLIGHT;
                m_flRestoreAfter = -1.0f;
            }

            switch( m_fInReloadState )
            {
            case 0:
                self.SendWeaponAnim( START_RELOAD, 0, pev.body );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
                m_flTimeWeaponReload = g_Engine.time + 0.6f;
                m_fInReloadState = 1;
                break;
            case 1:
                self.SendWeaponAnim( RELOAD, 0, pev.body );
                switch( Math.RandomLong( 0, 1 ) )
                {
                    case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/reload1.wav", 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
                    case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/reload3.wav", 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
                }
                m_flTimeWeaponReload = g_Engine.time + 0.4f;
                m_fInReloadState = 2;
                BaseClass.Reload();
                break;
            case 2:
                // Add them to the clip
                self.m_iClip += 1;
                m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
                m_fInReloadState = 1;
                break;
            }

            self.m_fInReload = true;
            self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
        }

        void FinishReload()
        {
            FinishReload( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 );
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
            {
                case 0:
                self.SendWeaponAnim( IDLE_DEEP, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; // ( 60.0f / 12.0f );
                break;

                case 1:
                self.SendWeaponAnim( IDLE, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.22f; // ( 20.0f / 9.0f );
                break;

                case 2:
                self.SendWeaponAnim( IDLE4, 0, pev.body );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.22f; // ( 20.0f / 9.0f );
                break;
            }
        }

        private void PumpWeapon()
        {
            SetThink( null );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/sbscock1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0x1f ) );
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
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 12.0f / 24.0f );
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

        private bool FinishReload( bool fCondition )
        {
            if ( self.m_fInReload )
            {
                if ( m_fInReloadState != 0 )
                {
                    if ( fCondition )
                    {
                        if( m_flRestoreAfter == -1.0f )
                            m_flRestoreAfter = g_Engine.time + 1.0f;

                        m_fInReloadState = 0;
                        self.m_fInReload = false;
                        self.SendWeaponAnim( PUMP, 0, pev.body );
                        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/sbscock1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0x1f ) );
                        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.85f; // pump after
                        self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
                        return true;
                    }
                }
                else
                {
                    BaseClass.FinishReload();
                    return true;
                }
            }
            return false;
        }
    }
}
