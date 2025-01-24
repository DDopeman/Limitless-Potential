//=============================================================================
// Various RNG-based math functions
//
// Created by Tomas "GeckoN" Slavotinek
//=============================================================================

namespace RandNumMath
{

//-----------------------------------------------------------------------------
// ShuffleIntArray - shuffles array of integers
//-----------------------------------------------------------------------------
void ShuffleIntArray( array<int>& arr )
{
	uint n = arr.length();
	
	if ( n <= 1 )
		return;
	
	for ( uint i = 0; i < n - 1; i++ )
	{
		uint j = i + Math.RandomLong( 0, Math.INT32_MAX ) / ( Math.INT32_MAX / ( n - i ) + 1 );
		int t = arr[ j ];
		arr[ j ] = arr[ i ];
		arr[ i ] = t;
	}
}

//-----------------------------------------------------------------------------
// IncreasingSequence
// Generates parametrized pseudo-random monotonically increasing sequence
// of numbers ( non-repeating if iMinEventDist > 0 )
//
// iNumTerms: total number of terms
// iRangeMin: term range - min. value
// iRangeMax: term range - max. value
// iMinEventDist: min. distance between two terms (same units as term range)
// flMaxEventDev: max. relative deviation of interval* length <0, 1.0)
//
// * Terms are randomly picked from a sequential intervals.
// Avg. interval length:
// ( iRangeMax - iRangeMin ) / iNumTerms - iMinEventDist * ( iNumInts - 1 )
//-----------------------------------------------------------------------------
array<int> IncreasingSequence( uint iNumTerms, int iRangeMin, int iRangeMax, int iMinEventDist, float flMaxEventDev )
{
	array<int> terms;
	
	int iRange = iRangeMax - iRangeMin;
	int iTotalEventDist = iMinEventDist * ( iNumTerms - 1 );
	float flHalfEventDev = flMaxEventDev * 0.5;

	// Do some basic sanity checks
	if ( iNumTerms == 0 || iRange < 0 || int( iNumTerms ) > iRange ||
		iMinEventDist < 0 || iTotalEventDist >= iRange ||
		flMaxEventDev < 0.0f || flMaxEventDev >= 1.0f )
	{
		g_Game.AlertMessage( at_console, "[RandNumMath] IncreasingSequence: ERROR: Invalid parameter(s)!\n" );
		return terms;
	}
	
	terms.resize( iNumTerms );
	
	int iIntsLeft = iNumTerms;
	float flIntMin = iRangeMin;
	float flIntMax = flIntMin - iTotalEventDist;

	for ( uint i = 0; i < iNumTerms; i++, iIntsLeft-- )
	{
		float flRangeLeft = float( iRangeMax ) - flIntMax;
		float flAvgRange = flRangeLeft / iIntsLeft;
		
		if ( iIntsLeft > 1 )
			flIntMax = flIntMin + flAvgRange * ( 1.0f + Math.RandomFloat( -flHalfEventDev, +flHalfEventDev ) );
		else
			flIntMax = iRangeMax; // Just use the maximum for the last interval
		
		terms[ i ] = int( Math.RandomFloat( flIntMin, flIntMax ) );
		/*g_Game.AlertMessage( at_console, "IncTerm[%1] min: %2 max: %3 len: %4 rnd: %5\n",
			i, flIntMin, flIntMax, flIntMax - flIntMin, terms[ i ] );*/
		
		flIntMin = flIntMax;
	}
	
	return terms;
}

//-----------------------------------------------------------------------------
// ShuffledSequence
//
// iNumTerms: total number of terms
// iFirst: initial term in the sequence (before shuffling)
// iStep: increment between two terms
//-----------------------------------------------------------------------------
array<int> ShuffledSequence( uint iNumTerms, int iFirst = 0, int iStep = 1 )
{
	array<int> terms( iNumTerms );
	for ( uint i = 0; i < iNumTerms; i++ )
		terms[ i ] = iFirst + i * iStep;
	
	ShuffleIntArray( terms );
	
	/*for ( uint i = 0; i < iNumTerms; i++ )
		g_Game.AlertMessage( at_console, "SflTerm [%1] %2\n", i, terms[ i ] );*/
	
	return terms;
}

} // end of namespace

