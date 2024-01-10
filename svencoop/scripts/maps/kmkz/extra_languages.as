/*
Language support.
        Add keyvalues for your entities that can be used in conjunction with multi_language plugin
        so players decide what keyvalue they should be able to use.

		The language keys are the next:
		message_spanish
		message_spanish  <- refeer to this as "Spanish Latam"
		message_spanish2 <- refeer to this as "Spanish Spain"
		message_portuguese
		message_german
		message_french
		message_italian
		message_esperanto
		message_czech
		message_dutch
		message_indonesian
		message_romanian
		message_turkish
		message_albanian

        USAGE:

            class YourClass : ScriptBaseEntity, ScriptBaseLanguages
            {
                bool KeyValue( const string& in szKey, const string& in szValue )
                {
                    Languages( szKey, szValue );
                }
            }
        Then finally you just have to call the key.
        
            ReadLanguages( pPlayer );

        we must extract from this player a custom keyvalue "$s_lenguage"
        if it is "english" returns the "message" value.
        if it is "spanish" returns the "message_spanish" value. and so on.
*/

// Code by Gaftherman https://github.com/Gaftherman modified by kmkz
mixin class ScriptBaseLanguagesKm
{
    private string_t message_spanish,
    message_portuguese, message_german,
    message_french, message_italian,
    message_esperanto, message_czech,
    message_dutch, message_spanish2,
    message_indonesian, message_romanian,
    message_turkish, message_albanian;

    bool Languages( const string& in szKey, const string& in szValue )
    {
        if( szKey == "message_spanish" )
        {
            message_spanish = szValue;
        }
        else if( szKey == "message_spanish2" )
        {
            message_spanish2 = szValue;
        }
        else if( szKey == "message_portuguese" )
        {
            message_portuguese = szValue;
        }
        else if( szKey == "message_german" )
        {
            message_german = szValue;
        }
        else if( szKey == "message_french" )
        {
            message_french = szValue;
        }
        else if( szKey == "message_italian" )
        {
            message_italian = szValue;
        }
        else if( szKey == "message_esperanto" )
        {
            message_esperanto = szValue;
        }
        else if( szKey == "message_czech" )
        {
            message_czech = szValue;
        }
        else if( szKey == "message_dutch" )
        {
            message_dutch = szValue;
        }
        else if( szKey == "message_indonesian" )
        {
            message_indonesian = szValue;
        }
        else if( szKey == "message_romanian" )
        {
            message_romanian = szValue;
        }
        else if( szKey == "message_turkish" )
        {
            message_turkish = szValue;
        }
        else if( szKey == "message_albanian" )
        {
            message_albanian = szValue;
        }
        else
        {
            return BaseClass.KeyValue( szKey, szValue );
        }

        return true;
    }

	string_t ReadLanguages( CBasePlayer@ pPlayer )
    {
        // Lo que el plugin de multi_language utiliza -Mikk
        string sLanguage = pPlayer.GetCustomKeyvalues().GetKeyvalue( "$s_lenguage" ).GetString();

        // Ingles deberia ser por defecto.
        string eng = self.pev.message;
        bool asd;
		dictionary Languages =
        {
           { "english", eng },
           { "spanish", message_spanish == "" ? message_spanish2 == "" ? eng : string(message_spanish2) : string(message_spanish) },
           { "spanish2", message_spanish2 == "" ? message_spanish == "" ? eng : string(message_spanish) : string(message_spanish2) },
           { "portuguese", message_portuguese == "" ? eng : string(message_portuguese) },
           { "german", message_german == "" ? eng : string(message_german) },
           { "french", message_french == "" ? eng : string(message_french) },
           { "italian", message_italian == "" ? eng : string(message_italian) },
           { "esperanto", message_esperanto == "" ? eng : string(message_esperanto) },
           { "czech", message_czech == "" ? eng : string( message_czech) },
           { "dutch", message_dutch == "" ? eng : string(message_dutch) },
           { "indonesian", message_indonesian == "" ? eng : string(message_indonesian) },
           { "romanian", message_romanian == "" ? eng : string(message_romanian) },
           { "turkish", message_turkish == "" ? eng : string(message_turkish) },
           { "albanian", message_albanian == "" ? eng : string(message_albanian) }
        };
        // Si no hay elección retornemos ingles por defecto.
        if( string( sLanguage ).IsEmpty() )
        {
            return string_t( Languages[ "english" ] );
        }

        return string_t( Languages[ sLanguage ] );
    }
}
// End of mixin class