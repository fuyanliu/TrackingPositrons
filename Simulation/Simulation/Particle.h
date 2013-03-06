#ifndef PARTICLE_H
#define PARTICLE_H

namespace Simulation {

  typedef struct {
    float r[3];
    float p[3];
    float q;
    float m; // GeV
  } simple_particle_t;

}

#endif