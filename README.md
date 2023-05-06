## WARNING

This is a branch of the code aiming mainly [Viscous Filtering](https://doi.org/10.1016/j.jcp.2021.110115) and [Conjugate Heat Transfer](https://doi.org/10.1016/j.jcp.2023.112182) applications in Turbulent Pipe Flow. To access the main branch of the code, [click here](https://github.com/xcompact3d).


## The Xcompact3d code

Xcompact3d is a Fortran-based framework of high-order finite-difference flow solvers dedicated to the study of turbulent flows. Dedicated to Direct and Large Eddy Simulations (DNS/LES) for which the largest turbulent scales are simulated, it can combine the versatility of industrial codes with the accuracy of spectral codes. Its user-friendliness, simplicity, versatility, accuracy, scalability, portability and efficiency makes it an attractive tool for the Computational Fluid Dynamics community.

Xcompact3d is currently able to solve the incompressible and low-Mach number variable density Navier-Stokes equations using sixth-order compact finite-difference schemes with a spectral-like accuracy on a monobloc Cartesian mesh.  It was initially designed in France in the mid-90's for serial processors and later converted to HPC systems. It can now be used efficiently on hundreds of thousands CPU cores to investigate turbulence and heat transfer problems thanks to the open-source library 2DECOMP&FFT (a Fortran-based 2D pencil decomposition framework to support building large-scale parallel applications on distributed memory systems using MPI; the library has a Fast Fourier Transform module).
When dealing with incompressible flows, the fractional step method used to advance the simulation in time requires to solve a Poisson equation. This equation is fully solved in spectral space via the use of relevant 3D Fast Fourier transforms (FFTs), allowing the use of any kind of boundary conditions for the velocity field. Using the concept of the modified wavenumber (to allow for operations in the spectral space to have the same accuracy as if they were performed in the physical space), the divergence free condition is ensured up to machine accuracy. The pressure field is staggered from the velocity field by half a mesh to avoid spurious oscillations created by the implicit finite-difference schemes. The modelling of a fixed or moving solid body inside the computational domain is performed with a customised Immersed Boundary Method. It is based on a direct forcing term in the Navier-Stokes equations to ensure a no-slip boundary condition at the wall of the solid body while imposing non-zero velocities inside the solid body to avoid discontinuities on the velocity field. This customised IBM, fully compatible with the 2D domain decomposition and with a possible mesh refinement at the wall, is based on a 1D expansion of the velocity field from fluid regions into solid regions using Lagrange polynomials or spline reconstructions. In order to reach high velocities in a context of LES, it is possible to customise the coefficients of the second derivative schemes (used for the viscous term) to add extra numerical dissipation in the simulation as a substitute of the missing dissipation from the small turbulent scales that are not resolved.

## The Present Version

This is a branch of Xcompact3d for Direct and Large Eddy Simulation (DNS/LES) in circular pipe geometry (file `BC-Pipe-flow.f90`). If heat-transfer is to be considered, ideal thermal boundary conditions (BC) - Mixed-type (Dirichlet BC) or isoflux (Neumann BC) - or Conjugate Heat Transfer (CHT) may be considered. The Viscous Filtering (VF) technique in centred formulation is also implemented. For more details about the numerical methodology, see :

**[1]** R. Vicente Cruz, ‘High-fidelity simulation of conjugate heat transfer between a turbulent flow and a duct geometry’, Université de Poitiers, 2021. [Online]. Available: [https://inria.hal.science/tel-03605404/](https://inria.hal.science/tel-03605404/)

**[2]** R. Vicente Cruz and E. Lamballais, ‘A Versatile Immersed Boundary Method for High-Fidelity Simulation of Conjugate Heat Transfer’, Journal of Computational Physics, 2023, [doi: 10.1016/j.jcp.2023.112182](https://doi.org/10.1016/j.jcp.2023.112182).

**[3]** E. Lamballais, R. Vicente Cruz, and R. Perrin, ‘Viscous and hyperviscous filtering for direct and large-eddy simulation’, Journal of Computational Physics, vol. 431, p. 110115, Apr. 2021, [doi: 10.1016/j.jcp.2021.110115.](https://doi.org/10.1016/j.jcp.2021.110115)

We kindly ask you to cite the above works when using this version of the code or any of the numerical tools associated to it (IB-based Neumann BC technique, extrapolation schemes, ...).

## The input file (*input.i3d*)

Here are some important comments about the simulation inputs.

### Scalar Transport

For heat-transfer simulations with Mixed-type BC (Dirichlet BC) :

	set itbc=1

For heat-transfer simulations with isoflux BC (Neumann BC) :

	set itbc=2

For heat-transfer simulations with CHT BC (Dirichlet-Neumann BC) :

	set itbc=3

To disable scalar transport (no heat-transfer) :

	set numscalar=0

### Viscous Filter
Refer to the [paper](https://doi.org/10.1016/j.jcp.2021.110115) for all the details about the method.

To use scheme (36) :

	set ivf=1 

To use scheme (38) :

	set ivf=2 

To use VF1 instead of VF3, comment the corresponding lines in `subroutine int_time` file `time_integrators.f90` (requires recompilation).

To unset disable viscous filtering (use conventional 2nd derivative instead) : 
	
	set ivf=0

### Immersed Boundary Method
Note that because of the disconnection between mesh arrangement (regular Cartesian) and wall geometry (cylindrical), pipe flow simulations **require the use of an immersed boundary method**. Furthermore, the present version requires the use of *Lagrange polynomial reconstructions* by setting `iibm=2`, which is also more accurate than the *old school* option with `iibm=1`.

To use Lagrange polynomial reconstructions **across the domain periodicity**, set `new_rec=1` in `subroutine geomcomplex_pipe` (requires recompilation). This option further improves accuracy, see [1, 2] for a full description of the technique.


## Source Download and Compilation

To acquire the source code, clone the git repository :

	git clone https://github.com/rvicentecruz/Xcompact3d_Pipe_CHT.git

**For a first compilation**, refer to the following steps :

1. Select the correct options for your Fortran compiler in `Makefile`
1. Run `make clean` (to make sure that you will be compiling all the files)
1. Comment `USE intt` in `subroutine phis_condeq` (file `BC-Pipe-flow.f90`) 
1. Run `make` to build the preliminary `xcompact3d` executable
1. Uncomment `USE intt` in `subroutine phis_condeq` (i.e., reverse step *1*)
1. Run `make` once again to build the final `xcompact3d` executable (only the file `BC-Pipe-flow.f90` is going to be recompiled).

The compilation may take a while, but only has to be done once.
