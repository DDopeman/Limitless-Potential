namespace UTILS
{

	// UTILS::InsideZone( player to be inside, brush/hullsizes reference);
	bool InsideZone(CBasePlayer@ pPlayer, CBaseEntity@ self)
	{
		bool blInside = true;
		blInside = blInside && pPlayer.pev.origin.x + pPlayer.pev.maxs.x >= self.pev.origin.x + self.pev.mins.x;
		blInside = blInside && pPlayer.pev.origin.y + pPlayer.pev.maxs.y >= self.pev.origin.y + self.pev.mins.y;
		blInside = blInside && pPlayer.pev.origin.z + pPlayer.pev.maxs.z >= self.pev.origin.z + self.pev.mins.z;
		blInside = blInside && pPlayer.pev.origin.x + pPlayer.pev.mins.x <= self.pev.origin.x + self.pev.maxs.x;
		blInside = blInside && pPlayer.pev.origin.y + pPlayer.pev.mins.y <= self.pev.origin.y + self.pev.maxs.y;
		blInside = blInside && pPlayer.pev.origin.z + pPlayer.pev.mins.z <= self.pev.origin.z + self.pev.maxs.z;

		return blInside;
	}
	
	// UTILS::SetSize( self );
	void SetSize( CBaseEntity@ self )
	{
		if( self.GetClassname() == string(self.pev.classname) && string( self.pev.model )[0] == "*" && self.IsBSPModel() )
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
		else
		{
			g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );		
		}
	}

} // End of namespace

namespace MLAN
{
	/*
	
	call values. should be used as...
	
	class yourclassentity : ScriptBaseEntity, MLAN::MoreKeyValues

	*/
    mixin class MoreKeyValues
    {
        private string_t message_spanish, message_portuguese, message_german, message_french, message_italian, message_esperanto;

        bool SexKeyValues( const string& in szKey, const string& in szValue )
        {
            if(szKey == "message_spanish")
            {
                message_spanish = szValue;
            }
            else if(szKey == "message_portuguese")
            {
                message_portuguese = szValue;
            }
            else if(szKey == "message_german")
            {
                message_german = szValue;
            }
            else if(szKey == "message_french")
            {
                message_french = szValue;
            }
            else if(szKey == "message_italian")
            {
                message_italian = szValue;
            }
            else if(szKey == "message_esperanto")
            {
                message_esperanto = szValue;
            }
            else
            {
                return BaseClass.KeyValue( szKey, szValue );
            }

            return true;
        }
		
		/*
			Then add those keys to your bool KeyValues as...
			
			bool KeyValue( const string& in szKey, const string& in szValue )
			{
				SexKeyValues(szKey, szValue);

				return true;
				
				if( your things )
				else if( your things )
			}
		*/
        string_t ReadLanguages( int iLanguage )
        {
            dictionary Languages =
            {
                {"0", self.pev.message},
                {"1", message_spanish},
                {"2", message_portuguese},
                {"3", message_german},
                {"4", message_french},
                {"5", message_italian},
                {"6", message_esperanto}
            };

            return string_t(Languages[ iLanguage ]);
        }
    }

	/*

	call custom keyvalues from players. should be used as...
	
	for( player for )
	
		int iLanguage = MLAN::GetCKV(pPlayer, "$f_lenguage");
		
		then do your things and call the array as...
		
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, string(ReadLanguages(iLanguage))+"\n");

	*/
	
    int GetCKV(CBasePlayer@ pPlayer, string valuename)
    {
        CustomKeyvalues@ ckvSpawns = pPlayer.GetCustomKeyvalues();
        return int(ckvSpawns.GetKeyvalue(valuename).GetFloat());
    }
} // End of namespace