#define d_sxx(z,x) d_sxx[(x)*(nz)+(z)]
#define d_szz(z,x) d_szz[(x)*(nz)+(z)]
#define d_Lambda(z,x)  d_Lambda[(x)*(nz)+(z)]
#define d_Cp(z,x)  d_Cp[(x)*(nz)+(z)]
#include<stdio.h>

__global__ void add_source(float *d_szz, float *d_sxx, float amp, int nz, bool isFor, \
	int z_loc, int x_loc, float dt, float *d_Cp) {

	int id = threadIdx.x + blockDim.x*blockIdx.x;
	float scale = pow(1500.0,2);;
	// float scale = pow(d_Cp(z_loc,x_loc),2);
	// float scale = d_Lambda(z_loc, x_loc);
	// float scale = 10890000.0;
	if (isFor) {
		if(id==0) {	
			// printf("amp = %f  ", amp);
			d_szz(z_loc,x_loc) += scale*amp * dt;
			d_sxx(z_loc,x_loc) += scale*amp * dt;
		}
		else{
			return;
		}
	}
	else {
		if(id==0) {	
			// printf("amp = %f  ", amp);
			d_szz(z_loc,x_loc) -= scale*amp * dt;
			d_sxx(z_loc,x_loc) -= scale*amp * dt;
		}
		else{
			return;
		}
	}
}


// __global__ void add_source(float *d_szz, float *d_sxx, int nz, float *d_source, bool isFor, \
// 	int z_loc, int x_loc, float dt, float *d_Cp) {

// 	int iSrc = threadIdx.x + blockDim.x*blockIdx.x;
// 	float scale = pow(d_Cp(z_loc,x_loc),2);

// 	if (isFor) {
// 		if(id==0) {	
// 			// printf("amp = %f  ", amp);
// 			d_szz(z_loc,x_loc) += scale*amp * dt;
// 			d_sxx(z_loc,x_loc) += scale*amp * dt;
// 		}
// 		else{
// 			return;
// 		}
// 	}
// 	else {
// 		if(id==0) {	
// 			// printf("amp = %f  ", amp);
// 			d_szz(z_loc,x_loc) -= scale*amp * dt;
// 			d_sxx(z_loc,x_loc) -= scale*amp * dt;
// 		}
// 		else{
// 			return;
// 		}
// 	}
// }