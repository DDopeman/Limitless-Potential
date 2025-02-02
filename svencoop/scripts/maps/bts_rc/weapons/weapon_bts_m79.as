/**
>>>Credits<<<

->Model: Hellspike
->Textures: klla_syc3/flamshmizer
->Animations: Michael65
->Compile, Edits: Norman the Loli Pirate
->Colored Model: D.N.I.O. 071
->Sprites: Der Graue Fuchs
->Script author: KernCore, Nero0 ( CSO Grenade Projectile )
->Sounds: Resident Evil Cold Blood Team

* This script is a sample to be used in: https://github.com/baso88/SC_AngelScript/
* You're free to use this sample in any way you would like to
* Just remember to credit the people who worked to provide you this

**/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_m79
{
    enum hlm79_e
    {
        IDLE = 0,
        SHOOT,
        RELOAD,
        DRAW,
        HOLSTER
    };

    // Weapon info
    int MAX_CARRY = 10;
    int MAX_CLIP = 1;
    // int DEFAULT_GIVE = Math.RandomLong( 0, 3 );
    int AMMO_GIVE = 2;
    int AMMO_DROP = 1;
    int WEIGHT = 20;
    // Weapon HUD
    int SLOT = 3;
    int POSITION = 4;
    // Vars
    float DAMAGE = 125.0f;
    float RADIUS = 240.0f;
    float VELOCITY = 1200.0f;
    Vector OFFSET( 8.0f, 4.0f, -2.0f ); // for projectile

    // string SPRITE_MUZZLE_GRENADE = "sprites/bts_rc/muzzleflash12.spr";
    // Vector MUZZLE_ORIGIN = Vector( 16.0, 4.0, -4.0 ); // forward, right, up

    class weapon_bts_m79 : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_m79.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 0, 3 );
            self.FallInit(); // get ready to fall
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
            return bts_deploy( "models/bts_rc/weapons/v_m79.mdl", "models/bts_rc/weapons/p_m79.mdl", DRAW, "bow", 1, 1.03f );
        }

        void Holster( int skiplocal = 0 )
        {
            BaseClass.Holster( skiplocal );
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
            // don't fire underwater/without having ammo loaded
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
                return;
            }

            m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

            // Notify the monsters about the grenade
            m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
            m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

            --self.m_iClip;

            m_pPlayer.pev.effects |= EF_MUZZLEFLASH; // Add muzzleflash
            pev.effects |= EF_MUZZLEFLASH;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
            Vector vecVelocity = g_Engine.v_forward * VELOCITY;

            M79_ROCKET::Shoot( m_pPlayer.pev, vecSrc, vecVelocity, DAMAGE, RADIUS, "models/grenade.mdl" );
            // CreateMuzzleflash( SPRITE_MUZZLE_GRENADE, MUZZLE_ORIGIN.x, MUZZLE_ORIGIN.y, MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );

            // View model animation
            self.SendWeaponAnim( SHOOT, 0, pev.body );
            // Custom Volume and Pitch
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/m79_fire.wav", Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
            // m_pPlayer.pev.punchangle.x = -10.0; // Recoil
            m_pPlayer.pev.punchangle.x = Math.RandomFloat( -2.0, -3.0 );

            if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
            self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; // Idle pretty soon after shooting.
        }

        void Reload()
        {
            // if the mag = the max mag, return
            if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            self.DefaultReload( MAX_CLIP, RELOAD, 3.88f, pev.body );
            // Set 3rd person reloading animation -Sniper
            BaseClass.Reload();
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();
            m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            self.SendWeaponAnim( IDLE, 0, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5.0f, 6.0f ); // How much time to idle again
        }
    }
}
