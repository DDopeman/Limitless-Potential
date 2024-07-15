
float M_PI = 3.14159265358979323846;
//Vector Multiplied Addition
void VectorMA( Vector& in vecA, float scale, Vector& in vecB, Vector& out vecC )
{
	vecC[0] = vecA[0] + scale*vecB[0];
	vecC[1] = vecA[1] + scale*vecB[1];
	vecC[2] = vecA[2] + scale*vecB[2];
}

void VectorScale( Vector& in vecIn, float scale, Vector& out vecOut )
{
	vecOut[0] = vecIn[0]*scale;
	vecOut[1] = vecIn[1]*scale;
	vecOut[2] = vecIn[2]*scale;
}

void VectorAdd( Vector& in vecA, Vector& in vecB, Vector& out vecC )
{
	vecC[0] = vecA[0] + vecB[0];
	vecC[1] = vecA[1] + vecB[1];
	vecC[2] = vecA[2] + vecB[2];
}

void VectorCopy( Vector& in vecA, Vector& out vecB )
{
	vecB[0] = vecA[0];
	vecB[1] = vecA[1];
	vecB[2] = vecA[2];
}

void VectorSubtract( Vector& in vecA, Vector& in vecB, Vector& out vecC)
{
	vecC[0] = vecA[0]-vecB[0];
	vecC[1] = vecA[1]-vecB[1];
	vecC[2] = vecA[2]-vecB[2];
}

void VectorsToAngles( Vector& in forward, Vector& in right, Vector& in up, Vector& out angles )
{
	float y,r,p;
	float sy;
	
	if( abs(forward[2]) < 0.9999 )
	{
		y = atan2(forward[1], forward[0]);
		sy = sin(y);
		if (abs(sy) < 0.1)
		{
			p = atan2(-forward[2], forward[0] / cos(y));
		}
		else
		{
			p = atan2(-forward[2], forward[1] / sy);
		}
		r = atan2(-right[2], up[2]);
	}
	else //gimbal lock; best we can do is assume roll = 0 and set pitch = pitch + actual roll
	{
		p = forward[2] > 0 ? -M_PI/2 : M_PI/2;
		y = atan2(right[0],-right[1]);
		r = 0;
	}

	angles[2] = r * (180 / M_PI); // Roll
	angles[0] = p * (180 / M_PI); // Pitch
	angles[1] = y * (180 / M_PI); // Yaw
}