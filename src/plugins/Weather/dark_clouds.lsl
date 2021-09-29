// large dark storm cloud

getParticles1()
{
    llParticleSystem([
        PSYS_SRC_PATTERN,
        PSYS_SRC_PATTERN_ANGLE,
        PSYS_SRC_BURST_RATE, 0.01,                  // How long before the next particle is emmited (in seconds)
        PSYS_SRC_BURST_RADIUS, 0.1,                 // How far from the source to start emmiting particles
        PSYS_SRC_BURST_PART_COUNT, 100,             // How many particles to emit per BURST
        PSYS_SRC_OUTERANGLE, 3.14,                  // The area that will be filled with particles
        PSYS_SRC_INNERANGLE, 0.00,                  // A slice of the circle (hole) where particles will not be created
        PSYS_SRC_MAX_AGE, 0.0,                      // How long in seconds the system will make particles, 0 means no time limit.
        PSYS_PART_MAX_AGE, 50.0,                    // How long each particle will last before dying
        PSYS_SRC_BURST_SPEED_MAX, 2.0,              // Max speed each particle can travel at
        PSYS_SRC_BURST_SPEED_MIN, 1.0,              // Min speed each particle can travel at
        PSYS_SRC_TEXTURE, "5b9295d0-791f-4fa2-ba37-f16a73f3b2c6",                   // Texture used as a particle.  For no texture use null string ""
        PSYS_PART_START_ALPHA, 1.0,                 // Alpha (transparency) value at birth
        PSYS_PART_END_ALPHA, 0.0,                   // Alpha (transparency) value at death
        PSYS_PART_START_SCALE, <15.0, 15.0, 1>,     // Start size of particles
        PSYS_PART_END_SCALE, <25.0, 25.0, 1>,       // End size (--requires PSYS_PART_INTERP_SCALE_MASK)
        PSYS_PART_START_COLOR, <0.3, 0.3, 0.3>,      // Start color of particles <R,G,B>
        PSYS_PART_END_COLOR, <1.4, 1.4, 1.4>,        // End color <R,G,B> (--requires PSYS_PART_INTERP_COLOR_MASK)
        PSYS_PART_FLAGS,
        PSYS_PART_EMISSIVE_MASK                     // Make the particles glow
        | PSYS_PART_BOUNCE_MASK                     // Make particles bounce on Z plan of object
        | PSYS_PART_INTERP_SCALE_MASK               // Change from starting size to end size
        | PSYS_PART_INTERP_COLOR_MASK               // Change from starting color to end color
        //| PSYS_PART_WIND_MASK                     // Particles effected by wind
        ]);
}

default
{

    state_entry()
    {
        getParticles1();
    }

}
