/*
* Author(s): Sam "Solokiller" Vanheer
* www.svencoop.com
* String utility functions, constants and classes
*/

namespace StringUtils
{
const string TOKEN_COMMENT = "//";
const uint TOKEN_COMMENT_LENGTH = TOKEN_COMMENT.Length();

/*
* Parses in a token, quoted or not
* Will skip whitespace before the token
* Handles comments in the style of "//"
* Input:	szString		- 	Input string
*			uiEndIndex		-	The index of the character after the last character that was parsed
* 			uiStartIndex	-	The index at which to start parsing
* Output:	The parsed token, or an empty string if no token could be parsed
*/
string ParseToken( const string& in szString, uint& out uiEndIndex, uint uiStartIndex = 0 )
{
	string szToken;
	
	uint uiIndex = uiStartIndex;
	
	const uint uiLength = szString.Length();
	
	if( uiIndex < uiLength )
	{
		//Skip whitespace
		while( uiIndex < uiLength && isspace( szString[ uiIndex ] ) )
			++uiIndex;
			
		if( uiIndex < uiLength )
		{
			bool fInQuote = false;
			
			char character;
			
			for( ; uiIndex < uiLength; ++uiIndex )
			{
				character = szString[ uiIndex ];
				
				if( character == "\"" )
					fInQuote = !fInQuote;
				else
				{
					if( !fInQuote && isspace( character ) )
						break;
					else if( character == "/" && szString.SubString( uiIndex, 2 ) == TOKEN_COMMENT )
					{
						break;
					}
					else
						szToken += character;
				}
			}
		}
	}
	
	uiEndIndex = uiIndex;
		
	return szToken;
}
}