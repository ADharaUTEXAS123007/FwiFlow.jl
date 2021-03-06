#define d_vx(z,x)  d_vx[(x)*(nz)+(z)]
#define d_vy(z,x)  d_vy[(x)*(nz)+(z)]
#define d_vz(z,x)  d_vz[(x)*(nz)+(z)]
#define d_sxx(z,x) d_sxx[(x)*(nz)+(z)]
#define d_szz(z,x) d_szz[(x)*(nz)+(z)]
#define d_sxz(z,x) d_sxz[(x)*(nz)+(z)]
#define d_mem_dvz_dz(z,x) d_mem_dvz_dz[(x)*(nz)+(z)]
#define d_mem_dvz_dx(z,x) d_mem_dvz_dx[(x)*(nz)+(z)]
#define d_mem_dvx_dz(z,x) d_mem_dvx_dz[(x)*(nz)+(z)]
#define d_mem_dvx_dx(z,x) d_mem_dvx_dx[(x)*(nz)+(z)]
#define d_Lambda(z,x)     d_Lambda[(x)*(nz)+(z)]
#define d_Mu(z,x)         d_Mu[(x)*(nz)+(z)]
#define d_ave_Mu(z,x)     d_ave_Mu[(x)*(nz)+(z)]
#define d_Den(z,x)        d_Den[(x)*(nz)+(z)]
#include "utilities.h"
#define sh_vz(z,x)  			sh_vz[(x)*(localz)+(z)]
#define sh_vx(z,x)  			sh_vx[(x)*(localz)+(z)]

__global__ void el_stress(float *d_vz, float *d_vx, float *d_szz, \
	float *d_sxx, float *d_sxz, float *d_mem_dvz_dz, float *d_mem_dvz_dx, \
	float *d_mem_dvx_dz, float *d_mem_dvx_dx, float *d_Lambda, float *d_Mu, float *d_ave_Mu,\
	float *d_Den, float *d_K_z, float *d_a_z, float *d_b_z, float *d_K_z_half, \
	float *d_a_z_half, float *d_b_z_half, float *d_K_x, float *d_a_x, float *d_b_x, \
	float *d_K_x_half, float *d_a_x_half, float *d_b_x_half, \
	int nz, int nx, float dt, float dz, float dx, int nPml, int nPad, bool isFor){


  int gidz = blockIdx.x*blockDim.x + threadIdx.x;
  int gidx = blockIdx.y*blockDim.y + threadIdx.y;

  float dvz_dz = 0.0;
  float dvx_dx = 0.0;
  float dvx_dz = 0.0;
  float dvz_dx = 0.0;

  float c1 = 9.0/8.0;
  float c2 = 1.0/24.0;
  // float c1 = coef[0];
  // float c2 = coef[1];

  float lambda = d_Lambda(gidz,gidx);
  float mu = d_Mu(gidz,gidx);

  if (isFor) {

		if(gidz>=2 && gidz<=nz-nPad-3 && gidx>=2 && gidx<=nx-3) {

		  dvz_dz = (c1*(d_vz(gidz+1,gidx)-d_vz(gidz,gidx)) - c2*(d_vz(gidz+2,gidx)-d_vz(gidz-1,gidx)))/dz;
		  dvx_dx = (c1*(d_vx(gidz,gidx)-d_vx(gidz,gidx-1)) - c2*(d_vx(gidz,gidx+1)-d_vx(gidz,gidx-2)))/dx;

		  if(gidz<nPml || (gidz>nz-nPml-nPad-1)){
			  d_mem_dvz_dz(gidz,gidx) = d_b_z_half[gidz]*d_mem_dvz_dz(gidz,gidx) + d_a_z_half[gidz]*dvz_dz;
			  dvz_dz = dvz_dz / d_K_z_half[gidz] + d_mem_dvz_dz(gidz,gidx);
			}
			if(gidx<nPml || gidx>nx-nPml){
			  d_mem_dvx_dx(gidz,gidx) = d_b_x[gidx]*d_mem_dvx_dx(gidz,gidx) + d_a_x[gidx]*dvx_dx;
			  dvx_dx = dvx_dx / d_K_x[gidx] + d_mem_dvx_dx(gidz,gidx);
			}

		  d_szz(gidz,gidx) += ((lambda+2.0*mu)*dvz_dz + lambda*dvx_dx) * dt;
		  d_sxx(gidz,gidx) += (lambda*dvz_dz + (lambda+2.0*mu)*dvx_dx) * dt;



		  dvx_dz = (c1*(d_vx(gidz,gidx)-d_vx(gidz-1,gidx)) - c2*(d_vx(gidz+1,gidx)-d_vx(gidz-2,gidx)))/dz;
		  dvz_dx = (c1*(d_vz(gidz,gidx+1)-d_vz(gidz,gidx)) - c2*(d_vz(gidz,gidx+2)-d_vz(gidz,gidx-1)))/dx;

		  if(gidz<nPml || (gidz>nz-nPml-nPad-1)){
			  d_mem_dvx_dz(gidz,gidx) = d_b_z[gidz]*d_mem_dvx_dz(gidz,gidx) + d_a_z[gidz]*dvx_dz;
			  dvx_dz = dvx_dz / d_K_z[gidz] + d_mem_dvx_dz(gidz,gidx);
			}
			if(gidx<nPml || gidx>nx-nPml){
			  d_mem_dvz_dx(gidz,gidx) = d_b_x_half[gidx]*d_mem_dvz_dx(gidz,gidx) + d_a_x_half[gidx]*dvz_dx;
			  dvz_dx = dvz_dx / d_K_x_half[gidx] + d_mem_dvz_dx(gidz,gidx);
			}

		  d_sxz(gidz,gidx) = d_sxz(gidz,gidx) + d_ave_Mu(gidz,gidx) * (dvx_dz + dvz_dx) * dt;
		}
		else{
			return;
		}
	}

	else {

		// ========================================BACKWARD PROPAGATION====================================
		if(gidz>=2+nPml && gidz<=nz-nPad-3-nPml && gidx>=2+nPml && gidx<=nx-3-nPml) {

		  dvz_dz = (c1*(d_vz(gidz+1,gidx)-d_vz(gidz,gidx)) - c2*(d_vz(gidz+2,gidx)-d_vz(gidz-1,gidx)))/dz;
		  dvx_dx = (c1*(d_vx(gidz,gidx)-d_vx(gidz,gidx-1)) - c2*(d_vx(gidz,gidx+1)-d_vx(gidz,gidx-2)))/dx;

		  d_szz(gidz,gidx) -= ((lambda+2.0*mu)*dvz_dz + lambda*dvx_dx) * dt;
		  d_sxx(gidz,gidx) -= (lambda*dvz_dz + (lambda+2.0*mu)*dvx_dx) * dt;


		  dvx_dz = (c1*(d_vx(gidz,gidx)-d_vx(gidz-1,gidx)) - c2*(d_vx(gidz+1,gidx)-d_vx(gidz-2,gidx)))/dz;
		  dvz_dx = (c1*(d_vz(gidz,gidx+1)-d_vz(gidz,gidx)) - c2*(d_vz(gidz,gidx+2)-d_vz(gidz,gidx-1)))/dx;

		  d_sxz(gidz,gidx) -= d_ave_Mu(gidz,gidx) * (dvx_dz + dvz_dx) * dt;
		}
		else{
			return;
		}

	}

}
