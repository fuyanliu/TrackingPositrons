#include <iostream>
#include <string>
#include <curand_kernel.h>
#include "Simulation/LandauCUDA.cuh"
#include "Simulation/Landau.hh"
#include "Simulation/GetTime.hh"

#include <TApplication.h>
#include <TCanvas.h>
#include <TGraph.h>
#include <TH1.h>
#include <TF1.h>
#include <TRandom3.h>

__global__
void GenerateLandau(curandState* states, unsigned steps, float* output) {
  unsigned index = threadIdx.x + blockDim.x * blockIdx.x;
  curandState *state = &states[index];
  curand_init(5,index,0,state);
  for (int i=0;i<steps;i++) {
    output[steps*index + i] = na63::ThrowLandau(5,1,curand_uniform(state));
  }
}

__host__
int CudaError(cudaError_t error) {
  if (error == cudaSuccess) return 0;
  std::cerr << "CUDA Error: " << cudaGetErrorString(error) << std::endl;
  return -1;
}

__host__
int main(int argc, char** argv) {

  bool gpu = true;

  for (int i=1;i<argc;i++) {
    std::string s(argv[i]);
    if (s == "CPU") {
      gpu = false;
    }
  }

  std::cout << "Generating numbers on " << ((gpu) ? "GPU" : "CPU") << "..." << std::endl;

  const unsigned N = 1 << 26;
  float *output = new float[N];

  double elapsed;

  if (gpu) {

    const unsigned threads = 1 << 13;    // 8192
    const unsigned threadsPerBlock = 256;
    const unsigned blocksPerGrid = (threads - 1) / threadsPerBlock + 1;
    const unsigned steps = N / threads; // 128

    curandState *states;
    float *device_output;

    if (CudaError(cudaMalloc(&states,threads*sizeof(curandState)))) return -1;
    if (CudaError(cudaMalloc(&device_output,N*sizeof(float)))) return -1;

    elapsed = na63::InSeconds(na63::GetTime());

    GenerateLandau<<<blocksPerGrid,threadsPerBlock>>>(states,steps,device_output);

    if (CudaError(cudaMemcpy(output,device_output,N*sizeof(float),cudaMemcpyDeviceToHost))) return -1;
    if (CudaError(cudaFree(states))) return -1;
    if (CudaError(cudaFree(device_output))) return -1;

    cudaDeviceSynchronize();

  } else {

    TRandom3 rng;

    elapsed = na63::InSeconds(na63::GetTime());

    for (int i=0;i<N;i++) {
      output[i] = na63::ThrowLandauHost(5,1,rng.Rndm());
    }

  }

  elapsed = na63::InSeconds(na63::GetTime()) - elapsed;
  std::cout << "Ran in " << elapsed << " seconds." << std::endl;

  TApplication app("app",nullptr,nullptr);
  TCanvas c;
  TPad p;
  TH1F *h1 = new TH1F("Landau","Landau distributed random numbers",2000,0,40);
  for (int i=0;i<N;i++) {
    h1->Fill(output[i]);
  }
  h1->Draw();
  h1->Fit("landau");
  TF1 *f = h1->GetFunction("landau");
  f->SetLineColor(kGreen);
  f->SetLineStyle(7);
  f->Draw("same");
  c.Update();
  c.SaveAs("Plots/rng_landau_gpu.png");

  return 0;
}