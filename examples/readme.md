## User Guide

To access *Xcompact3d's user-guide*, refer to the [official documentation](https://github.com/xcompact3d/Incompact3d/tree/master/docs) in the main branch. 

## READY-TO-RUN EXAMPLES

The folders `der2/` and `vf/` contain ready to run DNS cases using conventional second derivative computation (Lele's sixth-order scheme [1]) and Viscous Filter [2] respectively. 

### Important Information

In the *ready-to-run* cases, 4 (passive) scalar are being computed with a same velocity field [`numscalar=4`] in order to demonstrate the different types of thermal boundary conditions `itbc` that may be imposed at the pipe wall :

1. `itbc(1) = 1` : Mixed-type BC (Dirichlet)
1. `itbc(2) = 2` : Isoflux BC (Neumann)  
1. `itbc(3) = 3` : CHT BC (Dirichlet-Neumann)
1. `itbc(4) = 3` : CHT BC (Dirichlet-Neumann)

Different combinations of fluid-solid material properties `(g1, g2)` are being considered for CHT cases *3* and *4*. A same Prandtl (Schmidt) number `sc(:)=1.0` is being assigned for all the scalars. 

Note that in the present *dual-IBM* framework (see [3,4]), the present setup implies the computation of 6 different scalars :

	Scalar #1 : Fluid temperature field (Mixed-type BC)
	Scalar #2 : Fluid temperature field (Isoflux BC)
	Scalar #3 : Fluid temperature field (CHT-1 BC)
	Scalar #4 : Fluid temperature field (CHT-2 BC)
	Scalar #5 : Solid temperature field (CHT-1 BC)
	Scalar #6 : Solid temperature field (CHT-2 BC)

Initial conditions correspond to the laminar solution, superimposed by modulated white-noise (see Chapter 2 of [3] for more details) which shall therefore trigger the transition towards a fully developed turbulent state.

## References

**[1]** S. K. Lele, ‘Compact finite difference schemes with spectral-like resolution’, Journal of Computational Physics, vol. 103, no. 1, pp. 16–42, Nov. 1992, doi: [10.1016/0021-9991(92)90324-R](https://doi.org/10.1016/0021-9991(92)90324-R).

**[2]** E. Lamballais, R. Vicente Cruz, and R. Perrin, ‘Viscous and hyperviscous filtering for direct and large-eddy simulation’, Journal of Computational Physics, vol. 431, p. 110115, Apr. 2021, doi: [10.1016/j.jcp.2021.110115.](https://doi.org/10.1016/j.jcp.2021.110115)

**[3]** R. Vicente Cruz, ‘High-fidelity simulation of conjugate heat transfer between a turbulent flow and a duct geometry’, Université de Poitiers, 2021. [Online]. Available: [https://inria.hal.science/tel-03605404/](https://inria.hal.science/tel-03605404/)

**[4]** R. Vicente Cruz and E. Lamballais, ‘A Versatile Immersed Boundary Method for High-Fidelity Simulation of Conjugate Heat Transfer’, Journal of Computational Physics, [Accepted].
