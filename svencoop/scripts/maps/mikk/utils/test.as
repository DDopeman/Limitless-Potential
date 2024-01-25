class VectorInt
{
    int x, y, z, r, g, b;

    VectorInt( int m_x, int m_y, int m_z )
    {
        x = m_x;
        y = m_y;
        z = m_z;
        r = m_x;
        g = m_y;
        b = m_z;
    }
}

VectorInt ToVectorInt( Vector v )
{
    VectorInt( 0, 0, 0 );
}

namespace test
{
    void MapLoad()
    {
        VectorInt myVector(10, 10, 5);

        // Accede a los componentes
        int xValue = myVector.x;
        int yValue = myVector.y;
        int zValue = myVector.z;

        g_Game.AlertMessage( at_console, "x "+xValue+"\n" );
        g_Game.AlertMessage( at_console, "y "+yValue+"\n" );
        g_Game.AlertMessage( at_console, "z "+zValue+"\n" );
        g_Game.AlertMessage( at_console, "r "+xValue+"\n" );
        g_Game.AlertMessage( at_console, "g "+yValue+"\n" );
        g_Game.AlertMessage( at_console, "b "+zValue+"\n" );
    }
}
