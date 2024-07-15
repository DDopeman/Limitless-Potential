//What are Quat(ernion)s? - https://www.youtube.com/watch?v=3BR8tK-LuB0
//The below was shamelessly ripped from the Natural Selection Source Code, by Unknown Worlds. 
class Quat
{
	float x;
	float y;
	float z;
	float w;

	Quat()
	{

	}

	Quat( float _x, float _y, float _z, float _w )
	{
		x = _x;
		y = _y;
		z = _z;
		w = _w;
	}

	Quat( Vector& in angles )
	{
		Vector xAxis;
		Vector yAxis;
		Vector zAxis;

		g_EngineFuncs.AngleVectors( angles, yAxis, xAxis, zAxis );
		//Quat( xAxis, yAxis, zAxis );

		//TODO: FIX THIS LEARN WHY I CANT REFER TO ANOTHER CONSTRUCTORRRRR
		float t = xAxis[0] + yAxis[1] + zAxis[2];
		
		if( t > 0 ) 
		{
			float s = sqrt( t + 1 );
			
			x = ( zAxis[1] - yAxis[2] ) * ( 0.5f / s );
			y = ( xAxis[2] - zAxis[0] ) * ( 0.5f / s );
			z = ( yAxis[0] - xAxis[1] ) * ( 0.5f / s );
			w = s * 0.5f;
		} 
		else 
		{
			if( xAxis[0] > yAxis[1] && xAxis[0] > zAxis[2] ) 
			{
				float s = sqrt( xAxis[0] - yAxis[1] - zAxis[2] + 1 );
				
				x = 0.5f * s;
				y = ( yAxis[0] + xAxis[1] ) * ( 0.5f / s );
				z = ( zAxis[0] + xAxis[2] ) * ( 0.5f / s );
				w = ( zAxis[1] - yAxis[2] ) * ( 0.5f / s );
			} 
			else if ( yAxis[1] > xAxis[0] && yAxis[1] > zAxis[2] ) 
			{
				float s = sqrt( yAxis[1] - xAxis[0] - zAxis[2] + 1 );
		
				x = ( xAxis[1] + yAxis[0] ) * ( 0.5f / s );
				y = 0.5f * s;
				z = ( zAxis[1] + yAxis[2] ) * ( 0.5f / s );
				w = ( xAxis[2] - zAxis[0] ) * ( 0.5f / s );
			} 
			else 
			{
				float s = sqrt( zAxis[2] - xAxis[0] - yAxis[1] + 1 );
				
				x = ( xAxis[2] + zAxis[0] ) * ( 0.5f / s );
				y = ( yAxis[2] + zAxis[1] ) * ( 0.5f / s );
				z = 0.5f * s;
				w = ( yAxis[0] - xAxis[1] ) * ( 0.5f / s );
			}   
		}        
	}

	Quat( Vector xAxis, Vector yAxis, Vector zAxis )
	{
		float t = xAxis[0] + yAxis[1] + zAxis[2];
		
		if( t > 0 ) 
		{
			float s = sqrt( t + 1 );
			
			x = ( zAxis[1] - yAxis[2] ) * ( 0.5f / s );
			y = ( xAxis[2] - zAxis[0] ) * ( 0.5f / s );
			z = ( yAxis[0] - xAxis[1] ) * ( 0.5f / s );
			w = s * 0.5f;
		} 
		else 
		{
			if( xAxis[0] > yAxis[1] && xAxis[0] > zAxis[2] ) 
			{
				float s = sqrt( xAxis[0] - yAxis[1] - zAxis[2] + 1 );
				
				x = 0.5f * s;
				y = ( yAxis[0] + xAxis[1] ) * ( 0.5f / s );
				z = ( zAxis[0] + xAxis[2] ) * ( 0.5f / s );
				w = ( zAxis[1] - yAxis[2] ) * ( 0.5f / s );
			} 
			else if ( yAxis[1] > xAxis[0] && yAxis[1] > zAxis[2] ) 
			{
				float s = sqrt( yAxis[1] - xAxis[0] - zAxis[2] + 1 );
		
				x = ( xAxis[1] + yAxis[0] ) * ( 0.5f / s );
				y = 0.5f * s;
				z = ( zAxis[1] + yAxis[2] ) * ( 0.5f / s );
				w = ( xAxis[2] - zAxis[0] ) * ( 0.5f / s );
			} 
			else 
			{
				float s = sqrt( zAxis[2] - xAxis[0] - yAxis[1] + 1 );
				
				x = ( xAxis[2] + zAxis[0] ) * ( 0.5f / s );
				y = ( yAxis[2] + zAxis[1] ) * ( 0.5f / s );
				z = 0.5f * s;
				w = ( yAxis[0] - xAxis[1] ) * ( 0.5f / s );
			}   
		}
	}

	Quat( float angle, Vector axis )
	{
		float sa = sin(angle / 2);
		float ca = cos(angle / 2);

		x = axis[0] * sa;
		y = axis[1] * sa;
		z = axis[2] * sa;
		w = ca;
	}    

	Quat Conjugate()
	{
		return Quat( -x, -y, -z, w );
	}


	Quat Unit()
	{
		float l = sqrt( x * x + y * y + z * z + w * w );
		return Quat( x / l, y / l, z / l, w / l );
	}    

	void GetVectors( Vector& out xAxis, Vector& out yAxis, Vector& out zAxis ) 
	{
		float xx = x * x;
		float xy = x * y;
		float xz = x * z;
		float xw = x * w;
		float yy = y * y;
		float yz = y * z;
		float yw = y * w;
		float zz = z * z;
		float zw = z * w;
		float ww = w * w;
		
		xAxis[0] = 1 - 2 * (yy + zz);
		xAxis[1] = 2 * (xy - zw);
		xAxis[2] = 2 * (xz + yw);
		
		yAxis[0] = 2 * (xy + zw);
		yAxis[1] = 1 - 2 * (xx + zz);
		yAxis[2] = 2 * (yz - xw);

		zAxis[0] = 2 * (xz - yw);
		zAxis[1] = 2 * (yz + xw);
		zAxis[2] = 1 - 2 * (xx + yy);    
	}    

	void GetAngles( Vector& out vecAngles )
	{
		Vector xAxis;
		Vector yAxis;
		Vector zAxis;
		
		GetVectors( xAxis, yAxis, zAxis );
		
		VectorsToAngles( yAxis, xAxis, zAxis, vecAngles );
	}

	Quat opMul( const Quat& in q1 )
	{
		return Quat(w * q1.x + x * q1.w + y * q1.z - z * q1.y,
					w * q1.y + y * q1.w + z * q1.x - x * q1.z,
					w * q1.z + z * q1.w + x * q1.y - y * q1.x,
					w * q1.w - x * q1.x - y * q1.y - z * q1.z);        
	}                
}

Quat ConstantRateLerp( Quat& src, Quat& dst, float amount )
{ 
	Quat rot = ( dst * src.Conjugate() ).Unit();
	
	// Compute the axis and angle we need to rotate about to go from src
	// to dst.
	float angle = acos(rot.w) * 2;
	float sinAngle = sqrt(1.0f - rot.w * rot.w);
	
	if( abs( sinAngle ) < 0.0005f )
	{
		sinAngle = 1;
	}
	
	Vector axis;
	
	axis.x = rot.x / sinAngle;
	axis.y = rot.y / sinAngle;
	axis.z = rot.z / sinAngle;
	
	// Wrap the angle to the range -PI to PI
	angle = WrapFloat( angle, -M_PI, M_PI );
	
	// Amount to rotate this frame.
	float frameAngle = amount;
	
	if( abs( angle ) <= frameAngle )
	{
		// If we are very close, just jump to the goal orientation.
		return dst;
	}
	else
	{
		Quat final;
		
		if( angle < 0 )
		{
			final = Quat( -frameAngle, axis ) * src;
		}
		else
		{
			final = Quat( frameAngle, axis ) * src;
		}

		return final;
	}
}

float WrapFloat( float value, float min, float max )
{
	const float theRange = max - min;
	
	if (value < min)
	{
		value += floor((max - value) / theRange) * theRange;
	}    
	
	if (value >= max)
	{
		value -= floor(((value - min) / theRange)) * theRange;
	}
	
	return value;
}

