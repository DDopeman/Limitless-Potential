/*
* Author(s): Sam "Solokiller" Vanheer
* www.svencoop.com
* This code handles the processing of strings, specifically, the conversion of escape sequences
* Note: this class has terrible performance and memory usage compared to a natively implemented version
* Do not use this as an example for similar code if you can do better!
*/
namespace EscapeSequences
{
enum EscapeSequenceMode
{
	StringToSeq,
	SeqToString
}
class EscapeSequences
{
	/*
	* Maps strings to sequences
	* e.g.: "\n" => \n
	*/
	private dictionary m_StringToSequence;

	/*
	* Maps sequences to strings
	* e.g.: \n => "\n"
	*/
	private dictionary m_SequenceToString;
	
	EscapeSequences()
	{
		InitMaps();
	}
	
	private void InitMaps()
	{
		AddMapping( "\\\'", "\'" );
		AddMapping( "\\\"", "\"" );
		AddMapping( "\\\\", "\\" );
		AddMapping( "\\n", "\n" );
		AddMapping( "\\r", "\r" );
		AddMapping( "\\t", "\t" );
	}
	
	private void AddMapping( const string& in szString, const string& in szSequence )
	{
		m_StringToSequence[ szString ] = szSequence;
		m_SequenceToString[ szSequence ] = szString;
	}
	
	bool Convert( string& out szResult, const string& in szString, EscapeSequenceMode mode = StringToSeq ) const
	{
		switch( mode )
		{
		case StringToSeq: return ConvertStringToSeq( szResult, szString );
		case SeqToString: return ConvertSeqToString( szResult, szString );
		default: return false;
		}
		
		return false;
	}
	
	private bool ConvertStringToSeq( string& out szResult, const string& in szString ) const
	{
		bool fSuccess = true;
		
		const uint uiLength = szString.Length();
		
		for( uint uiIndex = 0; fSuccess && uiIndex < uiLength; ++uiIndex )
		{
			if( szString[ uiIndex ] == '\\' )
			{
				const string szChar = szString.SubString( uiIndex, 2 );
				
				if( m_StringToSequence.exists( szChar ) )
				{
					szResult += string( m_StringToSequence[ szChar ] );
					++uiIndex;
				}
				else
					fSuccess = false;
			}
			else
				szResult += szString[ uiIndex ];
		}
		
		return fSuccess;
	}
	
	private bool ConvertSeqToString( string& out szResult, const string& in szString ) const
	{
		bool fSuccess = true;
		
		const uint uiLength = szString.Length();
		
		for( uint uiIndex = 0; fSuccess && uiIndex < uiLength; ++uiIndex )
		{
			const string szChar = szString[ uiIndex ];
			
			if( m_SequenceToString.exists( szChar ) )
				szResult += string( m_SequenceToString[ szChar ] );
			else
				szResult += szChar;
		}
		
		return fSuccess;
	}
}
}

/*
* Global instance of this class.
*/
EscapeSequences::EscapeSequences g_EscapeSequences;