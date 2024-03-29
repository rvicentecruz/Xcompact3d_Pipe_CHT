!################################################################################
!This file is part of Xcompact3d.
!
!Xcompact3d
!Copyright (c) 2012 Eric Lamballais and Sylvain Laizet
!eric.lamballais@univ-poitiers.fr / sylvain.laizet@gmail.com
!
!    Xcompact3d is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation.
!
!    Xcompact3d is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with the code.  If not, see <http://www.gnu.org/licenses/>.
!-------------------------------------------------------------------------------
!-------------------------------------------------------------------------------
!    We kindly request that you cite Xcompact3d/Incompact3d in your
!    publications and presentations. The following citations are suggested:
!
!    1-Laizet S. & Lamballais E., 2009, High-order compact schemes for
!    incompressible flows: a simple and efficient method with the quasi-spectral
!    accuracy, J. Comp. Phys.,  vol 228 (15), pp 5989-6015
!
!    2-Laizet S. & Li N., 2011, Incompact3d: a powerful tool to tackle turbulence
!    problems with up to 0(10^5) computational cores, Int. J. of Numerical
!    Methods in Fluids, vol 67 (11), pp 1735-1757
!################################################################################

module time_integrators

  implicit none

  private
  !public :: int_time
  !====DEBUG
  public :: intt,int_time

contains

  subroutine intt(var1,dvar1,forcing1)

    USE param
    USE variables
    USE decomp_2d
    implicit none

    !! INPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: var1

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: dvar1

    real(mytype),dimension(xsize(1),xsize(2),xsize(3)), optional :: forcing1

#ifdef DEBG
    if (nrank .eq. 0) print *,'# intt start'
#endif

    if (itimescheme.eq.1) then
       !>>> Euler
       var1(:,:,:)=gdt(itr)*dvar1(:,:,:,1)+var1(:,:,:)
    elseif(itimescheme.eq.2) then
       !>>> Adam-Bashforth second order (AB2)

       ! Do first time step with Euler
       if(itime.eq.1.and.irestart.eq.0) then
          var1(:,:,:)=gdt(itr)*dvar1(:,:,:,1)+var1(:,:,:)
       else
          var1(:,:,:)=adt(itr)*dvar1(:,:,:,1)+bdt(itr)*dvar1(:,:,:,2)+var1(:,:,:)
       endif
       dvar1(:,:,:,2)=dvar1(:,:,:,1)
    elseif(itimescheme.eq.3) then
       !>>> Adams-Bashforth third order (AB3)

       ! Do first time step with Euler
       !if(itime.eq.1.and.irestart.eq.0) then
       if(itime.eq.1) then
          !====Debug
          if (nrank.eq.0) print*,'    **with Euler**'
          var1(:,:,:)=dt*dvar1(:,:,:,1)+var1(:,:,:)
       !elseif(itime.eq.2.and.irestart.eq.0) then
       elseif(itime.eq.2) then
          ! Do second time step with AB2
          !====Debug
          if (nrank.eq.0) print*,'    **with AB2**'
          var1(:,:,:)=onepfive*dt*dvar1(:,:,:,1)-half*dt*dvar1(:,:,:,2)+var1(:,:,:)
          dvar1(:,:,:,3)=dvar1(:,:,:,2)
       else
          ! Finally using AB3
          var1(:,:,:)=adt(itr)*dvar1(:,:,:,1)+bdt(itr)*dvar1(:,:,:,2)+cdt(itr)*dvar1(:,:,:,3)+var1(:,:,:)
          dvar1(:,:,:,3)=dvar1(:,:,:,2)
       endif
       dvar1(:,:,:,2)=dvar1(:,:,:,1)
    elseif(itimescheme.eq.4) then
       !>>> Adams-Bashforth fourth order (AB4)

       if (nrank.eq.0) then
          print *, "AB4 not implemented!"
          STOP
       endif

       !if (itime.eq.1.and.ilit.eq.0) then
       !var(:,:,:)=gdt(itr)*hx(:,:,:)+var(:,:,:)
       !uy(:,:,:)=gdt(itr)*hy(:,:,:)+uy(:,:,:)
       !uz(:,:,:)=gdt(itr)*hz(:,:,:)+uz(:,:,:)
       !gx(:,:,:)=hx(:,:,:)
       !gy(:,:,:)=hy(:,:,:)
       !gz(:,:,:)=hz(:,:,:)
       !elseif (itime.eq.2.and.ilit.eq.0) then
       !var(:,:,:)=adt(itr)*hx(:,:,:)+bdt(itr)*gx(:,:,:)+var(:,:,:)
       !uy(:,:,:)=adt(itr)*hy(:,:,:)+bdt(itr)*gy(:,:,:)+uy(:,:,:)
       !uz(:,:,:)=adt(itr)*hz(:,:,:)+bdt(itr)*gz(:,:,:)+uz(:,:,:)
       !gox(:,:,:)=gx(:,:,:)
       !goy(:,:,:)=gy(:,:,:)
       !goz(:,:,:)=gz(:,:,:)
       !gx(:,:,:)=hx(:,:,:)
       !gy(:,:,:)=hy(:,:,:)
       !gz(:,:,:)=hz(:,:,:)
       !elseif (itime.eq.3.and.ilit.eq.0) then
       !var(:,:,:)=adt(itr)*hx(:,:,:)+bdt(itr)*gx(:,:,:)+cdt(itr)*gox(:,:,:)+var(:,:,:)
       !uy(:,:,:)=adt(itr)*hy(:,:,:)+bdt(itr)*gy(:,:,:)+cdt(itr)*goy(:,:,:)+uy(:,:,:)
       !uz(:,:,:)=adt(itr)*hz(:,:,:)+bdt(itr)*gz(:,:,:)+cdt(itr)*goz(:,:,:)+uz(:,:,:)
       !gox(:,:,:)=gx(:,:,:)
       !goy(:,:,:)=gy(:,:,:)
       !goz(:,:,:)=gz(:,:,:)
       !gx(:,:,:)=hx(:,:,:)
       !gy(:,:,:)=hy(:,:,:)
       !gz(:,:,:)=hz(:,:,:)
       !else
       !var(:,:,:)=adt(itr)*hx(:,:,:)+bdt(itr)*gx(:,:,:)+cdt(itr)*gox(:,:,:)+ddt(itr)*gax(:,:,:)+var(:,:,:)
       !uy(:,:,:)=adt(itr)*hy(:,:,:)+bdt(itr)*gy(:,:,:)+cdt(itr)*goy(:,:,:)+ddt(itr)*gay(:,:,:)+uy(:,:,:)
       !uz(:,:,:)=adt(itr)*hz(:,:,:)+bdt(itr)*gz(:,:,:)+cdt(itr)*goz(:,:,:)+ddt(itr)*gaz(:,:,:)+uz(:,:,:)
       !gax(:,:,:)=gox(:,:,:)
       !gay(:,:,:)=goy(:,:,:)
       !gaz(:,:,:)=goz(:,:,:)
       !gox(:,:,:)=gx(:,:,:)
       !goy(:,:,:)=gy(:,:,:)
       !goz(:,:,:)=gz(:,:,:)
       !gx(:,:,:)=hx(:,:,:)
       !gy(:,:,:)=hy(:,:,:)
       !gz(:,:,:)=hz(:,:,:)
       !endif
       !>>> Runge-Kutta (low storage) RK3
    elseif(itimescheme.eq.5) then
       if(itr.eq.1) then
          var1(:,:,:)=gdt(itr)*dvar1(:,:,:,1)+var1(:,:,:)
       else
          var1(:,:,:)=adt(itr)*dvar1(:,:,:,1)+bdt(itr)*dvar1(:,:,:,2)+var1(:,:,:)
       endif
       dvar1(:,:,:,2)=dvar1(:,:,:,1)
       !>>> Runge-Kutta (low storage) RK4
    elseif(itimescheme.eq.6) then

       if (nrank.eq.0) then
          print *, "RK4 not implemented!"
          STOP
       endif
       !>>> Semi-implicit
    elseif(itimescheme.eq.7) then

       call inttimp(var1,dvar1,forcing1)

    else

       if (nrank.eq.0) then
          print *, "Unrecognised itimescheme: ", itimescheme
          STOP
       endif

    endif

#ifdef DEBG
    if (nrank .eq. 0) print *,'# intt done'
#endif

    return

  end subroutine intt

  SUBROUTINE int_time(rho1, ux1, uy1, uz1, phi1, drho1, dux1, duy1, duz1, dphi1)

    USE decomp_2d, ONLY : mytype, xsize
    USE param, ONLY : zero, one
    USE param, ONLY : ntime, nrhotime, ilmn, iscalar, ilmn_solve_temp,itimescheme,ivf
    USE param, ONLY : primary_species, massfrac
    use param, only : scalar_lbound, scalar_ubound
    USE variables, ONLY : numscalar,nu0nu
    USE var, ONLY : ta1, tb1
    USE param, ONLY: itime

    IMPLICIT NONE

    !! INPUT/OUTPUT
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), ntime) :: drho1, dux1, duy1, duz1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), ntime, numscalar) :: dphi1

    !! OUTPUT
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), nrhotime) :: rho1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ux1, uy1, uz1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), numscalar) :: phi1

    !! LOCAL
    INTEGER :: is, i, j, k, it

    !Viscous filtering convective terms from previous time steps (VF3)
    !-----------------------------------------------------------------
    !Comment lines to use VF1 instead (accuracy compromise for improved 
    !performance). See (Lamballais et al. 2021, JCP) for more details
    IF (ivf.NE.0) THEN 
        DO it=2,ntime
            IF (itime.GE.it) THEN
                call viscous_filter(dux1(:,:,:,it),0,0)
                call viscous_filter(duy1(:,:,:,it),0,0)
                call viscous_filter(duz1(:,:,:,it),0,0)
                IF (iscalar.NE.0) then
                    DO is=1,numscalar
                        call viscous_filter(dphi1(:,:,:,it,is),is,1)
                    ENDDO
                ENDIF
            ENDIF
        ENDDO
    ENDIF
    !-----------------------------------------------------------------

    CALL int_time_momentum(ux1, uy1, uz1, dux1, duy1, duz1)

    IF (ilmn) THEN
       IF (ilmn_solve_temp) THEN
          CALL int_time_temperature(rho1, drho1, dphi1, phi1)
       ELSE
          CALL int_time_continuity(rho1, drho1)
       ENDIF
    ENDIF


    IF (iscalar.NE.0) THEN
       IF (ilmn.and.ilmn_solve_temp) THEN
          !! Compute temperature
          call calc_temp_eos(ta1, rho1(:,:,:,1), phi1, tb1, xsize(1), xsize(2), xsize(3))
       ENDIF

       DO is = 1, numscalar
          IF (is.NE.primary_species) THEN
             IF (itimescheme.ne.7) THEN
                CALL intt(phi1(:,:,:,is), dphi1(:,:,:,:,is))
             ELSE
            !!TO BE DONE: when sc is not one
                CALL scalarimp(ux1,uy1,uz1,phi1(:,:,:,is),dphi1(:,:,:,:,is),is)
             ENDIF

             DO k = 1, xsize(3)
                DO j = 1, xsize(2)
                   DO i = 1, xsize(1)
                      phi1(i,j,k,is) = max(phi1(i,j,k,is),scalar_lbound(is))
                      phi1(i,j,k,is) = min(phi1(i,j,k,is),scalar_ubound(is))
                   ENDDO
                ENDDO
             ENDDO
          ENDIF
       ENDDO

       IF (primary_species.GE.1) THEN
          phi1(:,:,:,primary_species) = one
          DO is = 1, numscalar
             IF ((is.NE.primary_species).AND.massfrac(is)) THEN
                phi1(:,:,:,primary_species) = phi1(:,:,:,primary_species) - phi1(:,:,:,is)
             ENDIF
          ENDDO

          DO k = 1, xsize(3)
             DO j = 1, xsize(2)
                DO i = 1, xsize(1)
                   phi1(i,j,k,primary_species) = max(phi1(i,j,k,primary_species),zero)
                   phi1(i,j,k,primary_species) = min(phi1(i,j,k,primary_species),one)
                ENDDO
             ENDDO
          ENDDO
       ENDIF

       IF (ilmn.and.ilmn_solve_temp) THEN
          !! Compute rho
          call calc_temp_eos(rho1(:,:,:,1), ta1, phi1, tb1, xsize(1), xsize(2), xsize(3))
       ENDIF
    ENDIF

    !Viscous filtering ux1,uy1,uz1 and scalar at n+1 (VF3 and VF1)
    !-----------------------------------------------------------------
    !See Lamballais et al. 2021, JCP for more details
    IF (ivf.NE.0) THEN
        call viscous_filter(ux1,0,0)
        call viscous_filter(uy1,0,0)
        call viscous_filter(uz1,0,0)
        IF (iscalar.NE.0) then
            DO is=1,numscalar
                call viscous_filter(phi1(:,:,:,is),is,1)
            ENDDO
        ENDIF
    ENDIF
    !-----------------------------------------------------------------

  ENDSUBROUTINE int_time

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!
  !!  SUBROUTINE: int_time_momentum
  !! DESCRIPTION: Integrates the momentum equations in time by calling time
  !!              integrator.
  !!      INPUTS: dux1, duy1, duz1 - the RHS(s) of the momentum equations
  !!     OUTPUTS: ux1,   uy1,  uz1 - the intermediate momentum state.
  !!       NOTES: This is integrating the MOMENTUM in time (!= velocity)
  !!      AUTHOR: Paul Bartholomew
  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  subroutine int_time_momentum(ux1, uy1, uz1, dux1, duy1, duz1)

    USE param
    USE variables
    USE var, ONLY: px1, py1, pz1
    USE decomp_2d

    implicit none

    !! INPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ux1, uy1, uz1

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: dux1, duy1, duz1

    if (itimescheme.eq.7) then
       call intt(ux1, dux1, px1)
       call intt(uy1, duy1, py1)
       call intt(uz1, duz1, pz1)
    else
       call intt(ux1, dux1)
       call intt(uy1, duy1)
       call intt(uz1, duz1)
    endif

  endsubroutine int_time_momentum

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!
  !!  SUBROUTINE: int_time_continuity
  !! DESCRIPTION: Integrates the continuity (aka density transport) equation in
  !!              time
  !!      INPUTS: drho1 - the RHS(s) of the continuity equation.
  !!     OUTPUTS:  rho1 - the density at new time.
  !!      AUTHOR: Paul Bartholomew
  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  subroutine int_time_continuity(rho1, drho1)

    USE param
    USE variables
    USE decomp_2d

    implicit none

    integer :: it, i, j, k
    real(mytype) :: rhomin, rhomax

    !! INPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),nrhotime) :: rho1

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: drho1

    !! First, update old density / store old transients depending on scheme
    if (itimescheme.lt.5) then
       !! Euler/AB - Store old density values
       do it = nrhotime, 2, -1
          rho1(:,:,:,it) = rho1(:,:,:,it-1)
       enddo
    elseif (itimescheme.eq.5) then
       !! RK3 - Stores old transients
       if (itr.eq.1) then
          do it = nrhotime, 2, -1
             rho1(:,:,:,it) = rho1(:,:,:,it-1)
          enddo
          rho1(:,:,:,2) = drho1(:,:,:,1)
       endif
    else
       if (nrank.eq.0) then
          print *, "int_time_continuity not implemented for itimescheme", itimescheme
          stop
       endif
    endif

    !! Now we can update current density
    call intt(rho1(:,:,:,1), drho1)

    !! Enforce boundedness on density
    if (ilmn_bound) then
       rhomin = min(dens1, dens2)
       rhomax = max(dens1, dens2)
       do k = 1, xsize(3)
          do j = 1, xsize(2)
             do i = 1, xsize(1)
                rho1(i, j, k, 1) = max(rho1(i, j, k, 1), rhomin)
                rho1(i, j, k, 1) = min(rho1(i, j, k, 1), rhomax)
             enddo
          enddo
       enddo
    endif

  endsubroutine int_time_continuity

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!
  !!  SUBROUTINE: int_time_temperature
  !! DESCRIPTION: Integrates the temperature equation in time
  !!      INPUTS: drho1 - the RHS(s) of the temperature equation.
  !!     OUTPUTS:  rho1 - the density at new time.
  !!      AUTHOR: Paul Bartholomew
  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  subroutine int_time_temperature(rho1, drho1, dphi1, phi1)

    USE param
    USE variables
    USE decomp_2d

    USE navier, ONLY : lmn_t_to_rho_trans
    USE var, ONLY : tc1, tb1

    implicit none

    integer :: it, i, j, k

    !! INPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),nrhotime) :: rho1
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),numscalar) :: phi1
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime,numscalar) :: dphi1

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: drho1

    !! First, update old density / store old transients depending on scheme
    if (itimescheme.lt.5) then
       !! Euler/AB - Store old density values
       do it = nrhotime, 2, -1
          rho1(:,:,:,it) = rho1(:,:,:,it-1)
       enddo
    elseif (itimescheme.eq.5) then
       !! RK3 - Stores old transients
       if (itr.eq.1) then
          do it = nrhotime, 2, -1
             rho1(:,:,:,it) = rho1(:,:,:,it-1)
          enddo

          !! Convert temperature transient to density transient and store it.
          call lmn_t_to_rho_trans(rho1(:,:,:,2), drho1(:,:,:,1), rho1(:,:,:,1), dphi1, phi1)
       endif
    else
       if (nrank.eq.0) then
          print *, "int_time_continuity not implemented for itimescheme", itimescheme
          stop
       endif
    endif

    !!-------------------------------------------------------------------
    !! XXX We are integrating the temperature equation - get temperature
    !!-------------------------------------------------------------------
    call calc_temp_eos(tc1, rho1(:,:,:,1), phi1, tb1, xsize(1), xsize(2), xsize(3))

    !! Now we can update current temperature
    call intt(tc1, drho1)

    !! Temperature >= 0
    do k = 1, xsize(3)
       do j = 1, xsize(2)
          do i = 1, xsize(1)
             tc1(i,j,k) = max(tc1(i,j,k), zero)
          enddo
       enddo
    enddo

    !!-------------------------------------------------------------------
    !! XXX We are integrating the temperature equation - get back to rho
    !!-------------------------------------------------------------------
    call calc_rho_eos(rho1(:,:,:,1), tc1, phi1, tb1, xsize(1), xsize(2), xsize(3))

  endsubroutine int_time_temperature

end module time_integrators
