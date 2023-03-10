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

MODULE transeq

  PRIVATE
  PUBLIC :: calculate_transeq_rhs

CONTAINS

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!  SUBROUTINE: calculate_transeq_rhs
  !!      AUTHOR: Paul Bartholomew
  !! DESCRIPTION: Calculates the right hand sides of all transport
  !!              equations - momentum, scalar transport, etc.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE calculate_transeq_rhs(drho1,dux1,duy1,duz1,dphi1,rho1,ux1,uy1,uz1,ep1,phi1,divu3)

    USE decomp_2d, ONLY : mytype, xsize, zsize
    USE variables, ONLY : numscalar
    USE param, ONLY : ntime, ilmn, nrhotime, ilmn_solve_temp,itimescheme

    IMPLICIT NONE

    !! Inputs
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: ux1, uy1, uz1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), nrhotime), INTENT(IN) :: rho1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), numscalar), INTENT(IN) :: phi1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: ep1
    REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)), INTENT(IN) :: divu3

    !! Outputs
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), ntime) :: dux1, duy1, duz1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), ntime) :: drho1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), ntime, numscalar) :: dphi1

    !! Momentum equations
    CALL momentum_rhs_eq(dux1,duy1,duz1,rho1,ux1,uy1,uz1,ep1,phi1,divu3)

    !! Scalar equations
    !! XXX Not yet LMN!!!
    if (itimescheme.ne.7) then
       CALL scalar(dphi1, rho1, ux1, phi1)
    endif

    !! Other (LMN, ...)
    IF (ilmn) THEN
       IF (ilmn_solve_temp) THEN
          CALL temperature_rhs_eq(drho1, rho1, ux1, phi1)
       ELSE
          CALL continuity_rhs_eq(drho1, rho1, ux1, divu3)
       ENDIF
    ENDIF

  END SUBROUTINE calculate_transeq_rhs
  !############################################################################
  !############################################################################
  !!
  !!  SUBROUTINE: momentum_rhs_eq
  !!      AUTHOR: ?
  !!    MODIFIED: Kay Schäfer
  !! DESCRIPTION: Calculation of convective and diffusion terms of momentum
  !!              equation
  !!
  !############################################################################
  !############################################################################
  subroutine momentum_rhs_eq(dux1,duy1,duz1,rho1,ux1,uy1,uz1,ep1,phi1,divu3)

    USE param
    USE variables
    USE decomp_2d
    USE var, only : ta1,tb1,tc1,td1,te1,tf1,tg1,th1,ti1,di1,mu1,mu2,mu3
    USE var, only : rho2,ux2,uy2,uz2,ta2,tb2,tc2,td2,te2,tf2,tg2,th2,ti2,tj2,di2
    USE var, only : rho3,ux3,uy3,uz3,ta3,tb3,tc3,td3,te3,tf3,tg3,th3,ti3,di3
    USE var, only : sgsx1,sgsy1,sgsz1
    USE les, only : compute_SGS

    USE case, ONLY : momentum_forcing

    implicit none

    !! INPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ux1,uy1,uz1,ep1
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),numscalar) :: phi1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3),nrhotime) :: rho1
    real(mytype),intent(in),dimension(zsize(1),zsize(2),zsize(3)) :: divu3

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: dux1,duy1,duz1


    integer :: i,j,k,is

    !SKEW SYMMETRIC FORM
    !WORK X-PENCILS
    if (ilmn) then
      ta1(:,:,:) = rho1(:,:,:,1) * ux1(:,:,:) * ux1(:,:,:)
      tb1(:,:,:) = rho1(:,:,:,1) * ux1(:,:,:) * uy1(:,:,:)
      tc1(:,:,:) = rho1(:,:,:,1) * ux1(:,:,:) * uz1(:,:,:)
    else
      ta1(:,:,:) = ux1(:,:,:) * ux1(:,:,:)
      tb1(:,:,:) = ux1(:,:,:) * uy1(:,:,:)
      tc1(:,:,:) = ux1(:,:,:) * uz1(:,:,:)
    endif

    call derx (td1,ta1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (te1,tb1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (tf1,tc1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (ta1,ux1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (tb1,uy1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (tc1,uz1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    !!====DEBUG
    !do k=1,xsize(3)
    !    do j=1,xsize(2)
    !        !if (xstart(2)+j-1.eq.ny/2+1.and.xstart(3)+k-1.eq.nz/2+1) then
    !        if (xstart(2)+j-1.eq.20.and.xstart(3)+k-1.eq.nz/2+1) then
    !            do i=1,xsize(1)
    !                print*,'ux1:',(i-1)*dx,ux1(i,j,k)
    !            enddo
    !        endif
    !    enddo
    !enddo
    !!stop
    !!====

    ! Convective terms of x-pencil are stored in tg1,th1,ti1
    if (ilmn) then
      tg1(:,:,:) = td1(:,:,:) + rho1(:,:,:,1) * ux1(:,:,:) * ta1(:,:,:)
      th1(:,:,:) = te1(:,:,:) + rho1(:,:,:,1) * ux1(:,:,:) * tb1(:,:,:)
      ti1(:,:,:) = tf1(:,:,:) + rho1(:,:,:,1) * ux1(:,:,:) * tc1(:,:,:)
    else
      tg1(:,:,:) = td1(:,:,:) + ux1(:,:,:) * ta1(:,:,:)
      th1(:,:,:) = te1(:,:,:) + ux1(:,:,:) * tb1(:,:,:)
      ti1(:,:,:) = tf1(:,:,:) + ux1(:,:,:) * tc1(:,:,:)
    endif
    ! TODO: save the x-convective terms already in dux1, duy1, duz1

    if (ilmn) then
       !! Quasi-skew symmetric terms
       call derx (td1,rho1(:,:,:,1),di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
       tg1(:,:,:) = tg1(:,:,:) + ux1(:,:,:) * ux1(:,:,:) * td1(:,:,:)
       th1(:,:,:) = th1(:,:,:) + uy1(:,:,:) * ux1(:,:,:) * td1(:,:,:)
       ti1(:,:,:) = ti1(:,:,:) + uz1(:,:,:) * ux1(:,:,:) * td1(:,:,:)
    endif

    call transpose_x_to_y(ux1,ux2)
    call transpose_x_to_y(uy1,uy2)
    call transpose_x_to_y(uz1,uz2)

    if (ilmn) then
       call transpose_x_to_y(rho1(:,:,:,1),rho2)
       call transpose_x_to_y(mu1,mu2)
    else
       rho2(:,:,:) = one
    endif

    !WORK Y-PENCILS
    if (ilmn) then
      td2(:,:,:) = rho2(:,:,:) * ux2(:,:,:) * uy2(:,:,:)
      te2(:,:,:) = rho2(:,:,:) * uy2(:,:,:) * uy2(:,:,:)
      tf2(:,:,:) = rho2(:,:,:) * uz2(:,:,:) * uy2(:,:,:)
    else
      td2(:,:,:) = ux2(:,:,:) * uy2(:,:,:)
      te2(:,:,:) = uy2(:,:,:) * uy2(:,:,:)
      tf2(:,:,:) = uz2(:,:,:) * uy2(:,:,:)
    endif

    call dery (tg2,td2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call dery (th2,te2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    call dery (ti2,tf2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call dery (td2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    call dery (te2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call dery (tf2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    !!====DEBUG
    !do i=1,ysize(1)
    !    do k=1,ysize(3)
    !        if (ystart(1)+i-1.eq.nx/2+1.and.ystart(3)+k-1.eq.nz/2+1) then
    !            do j=1,ysize(2)
    !                print*,'ux2:' ,yp(j),ux2(i,j,k)
    !            enddo
    !        endif
    !    enddo
    !enddo
    !!stop
    !!====

    ! Convective terms of y-pencil in tg2,th2,ti2
    if (ilmn) then
      tg2(:,:,:) = tg2(:,:,:) + rho2(:,:,:) * uy2(:,:,:) * td2(:,:,:)
      th2(:,:,:) = th2(:,:,:) + rho2(:,:,:) * uy2(:,:,:) * te2(:,:,:)
      ti2(:,:,:) = ti2(:,:,:) + rho2(:,:,:) * uy2(:,:,:) * tf2(:,:,:)
    else
      tg2(:,:,:) = tg2(:,:,:) + uy2(:,:,:) * td2(:,:,:)
      th2(:,:,:) = th2(:,:,:) + uy2(:,:,:) * te2(:,:,:)
      ti2(:,:,:) = ti2(:,:,:) + uy2(:,:,:) * tf2(:,:,:)
    endif

    if (ilmn) then
       !! Quasi-skew symmetric terms
       call dery (te2,rho2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
       tg2(:,:,:) = tg2(:,:,:) + ux2(:,:,:) * uy2(:,:,:) * te2(:,:,:)
       th2(:,:,:) = th2(:,:,:) + uy2(:,:,:) * uy2(:,:,:) * te2(:,:,:)
       ti2(:,:,:) = ti2(:,:,:) + uz2(:,:,:) * uy2(:,:,:) * te2(:,:,:)
    endif

    call transpose_y_to_z(ux2,ux3)
    call transpose_y_to_z(uy2,uy3)
    call transpose_y_to_z(uz2,uz3)

    !WORK Z-PENCILS
    if (ilmn) then
       call transpose_y_to_z(rho2,rho3)
       call transpose_y_to_z(mu2,mu3)

       td3(:,:,:) = rho3(:,:,:) * ux3(:,:,:) * uz3(:,:,:)
       te3(:,:,:) = rho3(:,:,:) * uy3(:,:,:) * uz3(:,:,:)
       tf3(:,:,:) = rho3(:,:,:) * uz3(:,:,:) * uz3(:,:,:)
    else
       td3(:,:,:) = ux3(:,:,:) * uz3(:,:,:)
       te3(:,:,:) = uy3(:,:,:) * uz3(:,:,:)
       tf3(:,:,:) = uz3(:,:,:) * uz3(:,:,:)
    endif

    call derz (tg3,td3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    call derz (th3,te3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    call derz (ti3,tf3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (td3,ux3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (te3,uy3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (tf3,uz3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    !!====DEBUG
    !do i=1,zsize(1)
    !    do j=1,zsize(2)
    !        if (zstart(1)+i-1.eq.nx/2+1.and.zstart(2)+j-1.eq.ny/2+1) then
    !            do k=1,zsize(3)
    !                print*,'ux3:' ,(k-1)*dz,ux3(i,j,k)
    !            enddo
    !        endif
    !    enddo
    !enddo
    !!stop
    !!====

    ! Convective terms of z-pencil in ta3,tb3,tc3
    if (ilmn) then
      ta3(:,:,:) = tg3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * td3(:,:,:)
      tb3(:,:,:) = th3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * te3(:,:,:)
      tc3(:,:,:) = ti3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * tf3(:,:,:)
    else
      ta3(:,:,:) = tg3(:,:,:) + uz3(:,:,:) * td3(:,:,:)
      tb3(:,:,:) = th3(:,:,:) + uz3(:,:,:) * te3(:,:,:)
      tc3(:,:,:) = ti3(:,:,:) + uz3(:,:,:) * tf3(:,:,:)
    endif

    if (ilmn) then
       !! Quasi-skew symmetric terms
       call derz (tf3,rho3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
       ta3(:,:,:) = ta3(:,:,:) + ux3(:,:,:) * uz3(:,:,:) * tf3(:,:,:)
       tb3(:,:,:) = tb3(:,:,:) + uy3(:,:,:) * uz3(:,:,:) * tf3(:,:,:)
       tc3(:,:,:) = tc3(:,:,:) + uz3(:,:,:) * uz3(:,:,:) * tf3(:,:,:)

       !! Add the additional divu terms
       ta3(:,:,:) = ta3(:,:,:) + rho3(:,:,:) * ux3(:,:,:) * divu3(:,:,:)
       tb3(:,:,:) = tb3(:,:,:) + rho3(:,:,:) * uy3(:,:,:) * divu3(:,:,:)
       tc3(:,:,:) = tc3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * divu3(:,:,:)
    endif

    ! Convective terms of z-pencil are in ta3 -> td3, tb3 -> te3, tc3 -> tf3
    td3(:,:,:) = ta3(:,:,:)
    te3(:,:,:) = tb3(:,:,:)
    tf3(:,:,:) = tc3(:,:,:)

    !DIFFUSIVE TERMS IN Z
    if (ivf.eq.0) then
        call derzz (ta3,ux3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
        call derzz (tb3,uy3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
        call derzz (tc3,uz3,di3,sz,sfz ,ssz ,swz ,zsize(1),zsize(2),zsize(3),0)
    endif

    ! Add convective and diffusive terms of z-pencil (half for skew-symmetric)
    if (ilmn) then
      td3(:,:,:) = mu3(:,:,:) * xnu*ta3(:,:,:) - half * td3(:,:,:)
      te3(:,:,:) = mu3(:,:,:) * xnu*tb3(:,:,:) - half * te3(:,:,:)
      tf3(:,:,:) = mu3(:,:,:) * xnu*tc3(:,:,:) - half * tf3(:,:,:)
    else
      if (ivf.eq.0) then
          td3(:,:,:) = xnu*ta3(:,:,:) - half * td3(:,:,:)
          te3(:,:,:) = xnu*tb3(:,:,:) - half * te3(:,:,:)
          tf3(:,:,:) = xnu*tc3(:,:,:) - half * tf3(:,:,:)
      else !Only convective terms when viscous filtering
          td3(:,:,:) = - half * td3(:,:,:)
          te3(:,:,:) = - half * te3(:,:,:)
          tf3(:,:,:) = - half * tf3(:,:,:)
      endif
    endif

    !WORK Y-PENCILS
    call transpose_z_to_y(td3,td2)
    call transpose_z_to_y(te3,te2)
    call transpose_z_to_y(tf3,tf2)

    ! Convective terms of y-pencil (tg2,th2,ti2) and sum of convective (and diffusive - if ivf=0) terms of z-pencil (td2,te2,tf2) are now in tg2, th2, ti2 (half for skew-symmetric)
    tg2(:,:,:) = td2(:,:,:) - half * tg2(:,:,:)
    th2(:,:,:) = te2(:,:,:) - half * th2(:,:,:)
    ti2(:,:,:) = tf2(:,:,:) - half * ti2(:,:,:)

    !DIFFUSIVE TERMS IN Y
    if (itimescheme.ne.7.and.ivf.eq.0) then
       !-->for ux
       call deryy (td2,ux2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
       if (istret.ne.0) then
          call dery (te2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
          do k = 1,ysize(3)
             do j = 1,ysize(2)
                do i = 1,ysize(1)
                   td2(i,j,k) = td2(i,j,k)*pp2y(j)-pp4y(j)*te2(i,j,k)
                enddo
             enddo
          enddo
       endif

       !-->for uy
       call deryy (te2,uy2,di2,sy,sfy,ssy,swy,ysize(1),ysize(2),ysize(3),0)
       if (istret.ne.0) then
          call dery (tf2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
          do k = 1,ysize(3)
             do j = 1,ysize(2)
                do i = 1,ysize(1)
                   te2(i,j,k) = te2(i,j,k)*pp2y(j)-pp4y(j)*tf2(i,j,k)
                enddo
             enddo
          enddo
       endif

       !-->for uz
       call deryy (tf2,uz2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
       if (istret.ne.0) then
          call dery (tj2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
          do k = 1,ysize(3)
             do j = 1,ysize(2)
                do i = 1,ysize(1)
                   tf2(i,j,k) = tf2(i,j,k)*pp2y(j)-pp4y(j)*tj2(i,j,k)
                enddo
             enddo
          enddo
       endif
    else !Semi-implicit
       if (istret.ne.0) then

          !-->for ux
          call dery (te2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
          do k=1,ysize(3)
             do j=1,ysize(2)
                do i=1,ysize(1)
                   td2(i,j,k)=-pp4y(j)*te2(i,j,k)
                enddo
             enddo
          enddo
          !-->for uy
          call dery (tf2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
          do k=1,ysize(3)
             do j=1,ysize(2)
                do i=1,ysize(1)
                   te2(i,j,k)=-pp4y(j)*tf2(i,j,k)
                enddo
             enddo
          enddo
          !-->for uz
          call dery (tj2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
          do k=1,ysize(3)
             do j=1,ysize(2)
                do i=1,ysize(1)
                   tf2(i,j,k)=-pp4y(j)*tj2(i,j,k)
                enddo
             enddo
          enddo

       endif
    endif

    ! Add diffusive terms of y-pencil to convective (and diffusive) terms of y- and z-pencil
    if (ilmn) then
      ta2(:,:,:) = mu2(:,:,:) * xnu*td2(:,:,:) + tg2(:,:,:)
      tb2(:,:,:) = mu2(:,:,:) * xnu*te2(:,:,:) + th2(:,:,:)
      tc2(:,:,:) = mu2(:,:,:) * xnu*tf2(:,:,:) + ti2(:,:,:)
    else
      if (ivf.eq.0) then
          ta2(:,:,:) = xnu*td2(:,:,:) + tg2(:,:,:)
          tb2(:,:,:) = xnu*te2(:,:,:) + th2(:,:,:)
          tc2(:,:,:) = xnu*tf2(:,:,:) + ti2(:,:,:)
      else !Only convective terms when viscous filtering
          ta2(:,:,:) = tg2(:,:,:)
          tb2(:,:,:) = th2(:,:,:)
          tc2(:,:,:) = ti2(:,:,:)
      endif
    endif

    !WORK X-PENCILS
    call transpose_y_to_x(ta2,ta1)
    call transpose_y_to_x(tb2,tb1)
    call transpose_y_to_x(tc2,tc1) !diff+conv. terms (only conv if ivf.ne.0)

    !DIFFUSIVE TERMS IN X
    if (ivf.eq.0) then
        call derxx (td1,ux1,di1,sx,sfx ,ssx ,swx ,xsize(1),xsize(2),xsize(3),0)
        call derxx (te1,uy1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
        call derxx (tf1,uz1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
    endif

    if (ilmn) then
      td1(:,:,:) = mu1(:,:,:) * xnu * td1(:,:,:)
      te1(:,:,:) = mu1(:,:,:) * xnu * te1(:,:,:)
      tf1(:,:,:) = mu1(:,:,:) * xnu * tf1(:,:,:)
    else
      if (ivf.eq.0) then
          td1(:,:,:) = xnu * td1(:,:,:)
          te1(:,:,:) = xnu * te1(:,:,:)
          tf1(:,:,:) = xnu * tf1(:,:,:)
      endif
    endif

    !FINAL SUM: DIFF TERMS + CONV TERMS 
    if (ivf.eq.0) then
        dux1(:,:,:,1) = ta1(:,:,:) - half*tg1(:,:,:)  + td1(:,:,:)
        duy1(:,:,:,1) = tb1(:,:,:) - half*th1(:,:,:)  + te1(:,:,:)
        duz1(:,:,:,1) = tc1(:,:,:) - half*ti1(:,:,:)  + tf1(:,:,:)
    else !Only convective terms when viscous filtering
        dux1(:,:,:,1) = ta1(:,:,:) - half*tg1(:,:,:)
        duy1(:,:,:,1) = tb1(:,:,:) - half*th1(:,:,:)
        duz1(:,:,:,1) = tc1(:,:,:) - half*ti1(:,:,:)
    endif

    if (ilmn) then
       call momentum_full_viscstress_tensor(dux1(:,:,:,1), duy1(:,:,:,1), duz1(:,:,:,1), divu3, mu1)
    endif

    ! If LES modelling is enabled, add the SGS stresses
    if (ilesmod.ne.0.and.jles.le.3.and.jles.gt.0) then
       ! Wall model for LES
       if (iwall.eq.1) then
          call compute_SGS(sgsx1,sgsy1,sgsz1,ux1,uy1,uz1,ep1,1)
       else
          call compute_SGS(sgsx1,sgsy1,sgsz1,ux1,uy1,uz1,ep1,0)
       endif
       ! Calculate SGS stresses (conservative/non-conservative formulation)
       dux1(:,:,:,1) = dux1(:,:,:,1) + sgsx1(:,:,:)
       duy1(:,:,:,1) = duy1(:,:,:,1) + sgsy1(:,:,:)
       duz1(:,:,:,1) = duz1(:,:,:,1) + sgsz1(:,:,:)
    endif

    if (ilmn) then
      !! Gravity
      if ((Fr**2).gt.zero) then
        call momentum_gravity(dux1, duy1, duz1, rho1(:,:,:,1) - one, one / Fr**2)
      endif
    endif
    if (iscalar.ne.0) then
      do is = 1, numscalar
        call momentum_gravity(dux1, duy1, duz1, phi1(:,:,:,is), ri(is))
      enddo
    endif

    !! Additional forcing
    call momentum_forcing(dux1, duy1, duz1, rho1, ux1, uy1, uz1)

    if (itrip == 1) then
       !call tripping(tb1,td1)
       call tbl_tripping(duy1(:,:,:,1),td1)
       if (nrank == 0) print *,'TRIPPING!!'
    endif

  end subroutine momentum_rhs_eq
  !************************************************************

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!
  !!  SUBROUTINE: momentum_full_viscstress_tensor
  !!      AUTHOR: Paul Bartholomew
  !! DESCRIPTION: In an incompressible flow the viscous stress
  !!              tensor reduces to
  !!                d2u^j / {dx^i}^2
  !!              however if div(u) != 0 we have
  !!                d2u^j / {dx^i}^2 + 1/3 d/dx^j div(u)
  !!              and further if \mu != const.
  !!                \mu (d2u^j / {dx^i}^2 + 1/3 d/dx^j div(u))
  !!                  + d\mu/dx^i (du^j/dx^i + du^i/dx^j
  !!                  - 2/3 div(u) \delta^{ij})
  !!              This subroutine computes the additional
  !!              contributions not accounted for in the
  !!              incompressible solver.
  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  subroutine momentum_full_viscstress_tensor(dux1, duy1, duz1, divu3, mu1)

    USE param
    USE variables
    USE decomp_2d

    USE var, only : ux1,uy1,uz1,ta1,tb1,tc1,td1,te1,tf1,tg1,th1,ti1,di1
    USE var, only : ux2,uy2,uz2,ta2,tb2,tc2,td2,te2,tf2,tg2,th2,ti2,di2
    USE var, only : ux3,uy3,uz3,ta3,tb3,tc3,td3,te3,tf3,tg3,th3,ti3,di3

    IMPLICIT NONE

    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: dux1, duy1, duz1
    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: mu1
    REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)), INTENT(IN) :: divu3

    REAL(mytype) :: one_third

    one_third = one / three

    call derz (tc3,divu3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    call transpose_z_to_y(tc3, tc2)
    call transpose_z_to_y(divu3, th2)

    call dery(tb2,th2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call transpose_y_to_x(tb2, te1)
    call transpose_y_to_x(tc2, tf1)
    call transpose_y_to_x(th2, tg1)

    call derx(td1,tg1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)

    dux1(:,:,:) = dux1(:,:,:) + mu1(:,:,:) * one_third * xnu * td1(:,:,:)
    duy1(:,:,:) = duy1(:,:,:) + mu1(:,:,:) * one_third * xnu * te1(:,:,:)
    duz1(:,:,:) = duz1(:,:,:) + mu1(:,:,:) * one_third * xnu * tf1(:,:,:)

    !! Variable viscosity part
    call derx (ta1,ux1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (tb1,uy1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (tc1,uz1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (td1,mu1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    ta1(:,:,:) = two * ta1(:,:,:) - (two * one_third) * tg1(:,:,:)

    ta1(:,:,:) = td1(:,:,:) * ta1(:,:,:)
    tb1(:,:,:) = td1(:,:,:) * tb1(:,:,:)
    tc1(:,:,:) = td1(:,:,:) * tc1(:,:,:)

    call transpose_x_to_y(ta1, ta2)
    call transpose_x_to_y(tb1, tb2)
    call transpose_x_to_y(tc1, tc2)
    call transpose_x_to_y(td1, tg2)

    call dery (td2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    call dery (te2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call dery (tf2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    te2(:,:,:) = two * te2(:,:,:) - (two * one_third) * th2(:,:,:)

    call transpose_x_to_y(mu1, ti2)
    call dery (th2,ti2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)

    ta2(:,:,:) = ta2(:,:,:) + th2(:,:,:) * td2(:,:,:)
    tb2(:,:,:) = tb2(:,:,:) + th2(:,:,:) * te2(:,:,:) + tg2(:,:,:) * td2(:,:,:)
    tc2(:,:,:) = tc2(:,:,:) + th2(:,:,:) * tf2(:,:,:)

    call transpose_y_to_z(ta2, ta3)
    call transpose_y_to_z(tb2, tb3)
    call transpose_y_to_z(tc2, tc3)
    call transpose_y_to_z(tg2, tg3) !! dmudx
    call transpose_y_to_z(th2, th3) !! dmudy
    call transpose_y_to_z(ti2, ti3) !! mu

    call derz (td3,ux3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (te3,uy3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (tf3,uz3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    tf3(:,:,:) = two * tf3(:,:,:) - (two * one_third) * divu3(:,:,:)

    tc3(:,:,:) = tc3(:,:,:) + tg3(:,:,:) * td3(:,:,:) + th3(:,:,:) * te3(:,:,:)

    call derz (th3,ti3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)

    ta3(:,:,:) = ta3(:,:,:) + th3(:,:,:) * td3(:,:,:)
    tb3(:,:,:) = tb3(:,:,:) + th3(:,:,:) * te3(:,:,:)
    tc3(:,:,:) = tc3(:,:,:) + th3(:,:,:) * tf3(:,:,:)

    call transpose_z_to_y(ta3, ta2)
    call transpose_z_to_y(tb3, tb2)
    call transpose_z_to_y(tc3, tc2)
    call transpose_z_to_y(th3, ti2) !! dmudz

    tb2(:,:,:) = tb2(:,:,:) + ti2(:,:,:) * tf2(:,:,:)

    call transpose_y_to_x(ta2, ta1)
    call transpose_y_to_x(tb2, tb1)
    call transpose_y_to_x(tc2, tc1)
    call transpose_y_to_x(th2, te1) !! dmudy
    call transpose_y_to_x(ti2, tf1) !! dmudz

    call derx (th1,uy1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (ti1,uz1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    ta1(:,:,:) = ta1(:,:,:) + te1(:,:,:) * th1(:,:,:) + tf1(:,:,:) * ti1(:,:,:)

    dux1(:,:,:) = dux1(:,:,:) + xnu * ta1(:,:,:)
    duy1(:,:,:) = duy1(:,:,:) + xnu * tb1(:,:,:)
    duz1(:,:,:) = duz1(:,:,:) + xnu * tc1(:,:,:)


  end subroutine momentum_full_viscstress_tensor

  subroutine momentum_gravity(dux1, duy1, duz1, peculiar_density1, richardson)

    use decomp_2d
    use param
    use variables

    implicit none

    !! Inputs
    real(mytype), dimension(xsize(1), xsize(2), xsize(3)), intent(in) :: peculiar_density1
    real(mytype), intent(in) :: richardson

    !! InOut
    real(mytype), dimension(xsize(1), xsize(2), xsize(3), ntime) :: dux1, duy1, duz1

    !! Locals
    integer :: istart, jstart, kstart
    integer :: iend, jend, kend
    integer :: i, j, k

    ! Return directly if richardson is zero
    if (abs(richardson) < tiny(richardson)) return

    !! X-gravity
    if ((nclx1.eq.0).and.(nclxn.eq.0)) then
       istart = 1
       iend = xsize(1)
    else
       istart = 2
       iend = xsize(1) - 1
    endif
    if ((xstart(2).eq.1).and.(ncly1.eq.2)) then
       jstart = 2
    else
       jstart = 1
    endif
    if ((xend(2).eq.ny).and.(nclyn.eq.2)) then
       jend = xsize(2) - 1
    else
       jend = xsize(2)
    endif
    if ((xstart(3).eq.1).and.(nclz1.eq.2)) then
       kstart = 2
    else
       kstart = 1
    endif
    if ((xend(3).eq.nz).and.(nclzn.eq.2)) then
       kend = xsize(3) - 1
    else
       kend = xsize(3)
    endif

    do k = kstart, kend
       do j = jstart, jend
          do i = istart, iend
             dux1(i, j, k, 1) = dux1(i, j, k, 1) + peculiar_density1(i, j, k) * richardson * gravx
          enddo
       enddo
    enddo

    !! Y-gravity
    if (nclx1.eq.2) then
       istart = 2
    else
       istart = 1
    endif
    if (nclxn.eq.2) then
       iend = xsize(1) - 1
    else
       iend = xsize(1)
    endif
    if ((xstart(2).eq.1).and.(ncly1.ne.0)) then
       jstart = 2
    else
       jstart = 1
    endif
    if ((xend(2).eq.ny).and.(nclyn.ne.0)) then
       jend = xsize(2) - 1
    else
       jend = xsize(2)
    endif
    if ((xstart(3).eq.1).and.(nclz1.eq.2)) then
       kstart = 2
    else
       kstart = 1
    endif
    if ((xend(3).eq.nz).and.(nclzn.eq.2)) then
       kend = xsize(3) - 1
    else
       kend = xsize(3)
    endif
    do k = kstart, kend
       do j = jstart, jend
          do i = istart, iend
             duy1(i, j, k, 1) = duy1(i, j, k, 1) + peculiar_density1(i, j, k) * richardson * gravy
          enddo
       enddo
    enddo

    !! Z-gravity
    if (nclx1.eq.2) then
       istart = 2
    else
       istart = 1
    endif
    if (nclxn.eq.2) then
       iend = xsize(1) - 1
    else
       iend = xsize(1)
    endif
    if ((xstart(2).eq.1).and.(ncly1.eq.2)) then
       jstart = 2
    else
       jstart = 1
    endif
    if ((xend(2).eq.ny).and.(nclyn.eq.2)) then
       jend = xsize(2) - 1
    else
       jend = xsize(2)
    endif
    if ((xstart(3).eq.1).and.(nclz1.ne.0)) then
       kstart = 2
    else
       kstart = 1
    endif
    if ((xend(3).eq.nz).and.(nclzn.ne.0)) then
       kend = xsize(3) - 1
    else
       kend = xsize(3)
    endif
    do k = kstart, kend
       do j = jstart, jend
          do i = istart, iend
             duz1(i, j, k, 1) = duz1(i, j, k, 1) + peculiar_density1(i, j, k) * richardson * gravz
          enddo
       enddo
    enddo


  end subroutine momentum_gravity

  subroutine scalar_transport_eq(dphi1, rho1, ux1, phi1, schmidt,is)

    USE param
    USE variables
    USE decomp_2d

    USE var, ONLY : ta1,tb1,tc1,td1,di1
    USE var, ONLY : rho2,uy2,ta2,tb2,tc2,td2,di2
    USE var, ONLY : rho3,uz3,ta3,tb3,td3,di3
    USE pipe

    implicit none

    !! INPUTS
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3)) :: ux1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3)) :: phi1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3),nrhotime) :: rho1
    real(mytype), INTENT(IN) :: schmidt
    integer,      INTENT(IN) :: is

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: dphi1

    !! LOCALS
    integer :: i, j, k
    real(mytype) :: xalpha

    xalpha = xnu/schmidt

    !X PENCILS
    if (itype.eq.itype_pipe.and.itbc(is).ne.1.and.iibm.eq.2) then !to avoid Dirichlet reconstruction 
        iibm=0
    endif
    call derxS (tb1,phi1(:,:,:),di1,sx,ffxpS,fsxpS,fwxpS,xsize(1),xsize(2),xsize(3),1)
    if (ilmn) then
      tb1(:,:,:) = rho1(:,:,:,1) * ux1(:,:,:) * tb1(:,:,:)
    else
      tb1(:,:,:) = ux1(:,:,:) * tb1(:,:,:)
    endif

    if (ivf.eq.0) then
        call derxxS (ta1,phi1(:,:,:),di1,sx,sfxpS,ssxpS,swxpS,xsize(1),xsize(2),xsize(3),1)
    endif

    ! Add convective (and diffusive) scalar terms of x-pencil
    if (ivf.eq.0) then
        ta1(:,:,:) = xalpha*ta1(:,:,:) - tb1(:,:,:)
    else !Only convective terms when viscous filtering
        ta1(:,:,:) = - tb1(:,:,:)
    endif

    call transpose_x_to_y(phi1(:,:,:),td2(:,:,:))

    !Y PENCILS
    if (itype.eq.itype_pipe.and.itbc(is).ne.1) then
        !Imposed Flux (IF)
        if (itbc(is).eq.2) call nbclagpoly(td2,is)
        !Conjugate Heat Transfer (CHT)
        if (itbc(is).eq.3) call chtlagpoly(td2,is)
    endif
    call deryS (tc2,td2(:,:,:),di2,sy,ffypS,fsypS,fwypS,ppy,ysize(1),ysize(2),ysize(3),1)
    if (ivf.eq.0) then
        call deryyS (ta2,td2(:,:,:),di2,sy,sfypS,ssypS,swypS,ysize(1),ysize(2),ysize(3),1)
    endif
    !!====DEBUG
    !do i=1,ysize(1)
    !    do k=1,ysize(3)
    !        if (ystart(1)+i-1.eq.nx/2+1.and.ystart(3)+k-1.eq.nz/2+1) then
    !            do j=1,ysize(2)
    !                print*,'phi_y:' ,yp(j),td2(i,j,k)
    !            enddo
    !        endif
    !    enddo
    !enddo
    !!stop
    !!====

    if (istret.ne.0) then
       !call deryS (tc2,td2(:,:,:),di2,sy,ffypS,fsypS,fwypS,ppy,ysize(1),ysize(2),ysize(3),1)
       do k = 1,ysize(3)
          do j = 1,ysize(2)
             do i = 1,ysize(1)
                ta2(i,j,k) = ta2(i,j,k)*pp2y(j)-pp4y(j)*tc2(i,j,k)
             enddo
          enddo
       enddo
    endif

    if (ilmn) then
      tb2(:,:,:) = rho2(:,:,:) * uy2(:,:,:) * tc2(:,:,:)
    else
      tb2(:,:,:) = uy2(:,:,:) * tc2(:,:,:)
    endif

    ! Add convective (and diffusive) scalar terms of y-pencil
    if (ivf.eq.0) then
        tc2(:,:,:) = xalpha*ta2(:,:,:) - tb2(:,:,:)
    else !Only convective terms when viscous filtering
        tc2(:,:,:) = - tb2(:,:,:)
    endif

    call transpose_y_to_z(td2(:,:,:),td3(:,:,:))

    !Z PENCILS
    if (itype.eq.itype_pipe.and.itbc(is).ne.1) then
        !Imposed Flux (IF)
        if (itbc(is).eq.2) call nbclagpolz(td3,is)
        !Conjugate Heat Transfer
        if (itbc(is).eq.3) call chtlagpolz(td3,is)
    endif
    call derzS (tb3,td3(:,:,:),di3,sz,ffzpS,fszpS,fwzpS,zsize(1),zsize(2),zsize(3),1)
    if (ivf.eq.0) then
        call derzzS (ta3,td3(:,:,:),di3,sz,sfzpS,sszpS,swzpS,zsize(1),zsize(2),zsize(3),1)
    endif
    if (itype.eq.itype_pipe.and.itbc(is).ne.1.and.iibm.eq.0) then
        iibm=2
    endif
    !!====DEBUG
    !do i=1,zsize(1)
    !    do j=1,zsize(2)
    !        if (zstart(1)+i-1.eq.nx/2+1.and.zstart(2)+j-1.eq.ny/2+1) then
    !            do k=1,zsize(3)
    !                print*,'phi_z:' ,(k-1)*dz,td3(i,j,k)
    !            enddo
    !        endif
    !    enddo
    !enddo
    !stop
    !!====

    ! convective terms
    if (ilmn) then
      tb3(:,:,:) = rho3(:,:,:) * uz3(:,:,:) * tb3(:,:,:)
    else
      tb3(:,:,:) = uz3(:,:,:) * tb3(:,:,:)
    endif

    ! Add convective (and diffusive) scalar terms of z-pencil
    if (ivf.eq.0) then
        ta3(:,:,:) = xalpha*ta3(:,:,:) - tb3(:,:,:)
    else !Only convective terms when viscous filtering
        ta3(:,:,:) = - tb3(:,:,:)
    endif

    call transpose_z_to_y(ta3,ta2)

    !Y PENCILS
    ! Add convective (and diffusive) scalar terms of z-pencil to y-pencil
    tc2(:,:,:) = tc2(:,:,:) + ta2(:,:,:)

    call transpose_y_to_x(tc2,tc1)

    !X PENCILS
    ! Add convective (and diffusive) scalar terms to final sum
    dphi1(:,:,:,1) = ta1(:,:,:) + tc1(:,:,:)

    !! XXX We have computed rho dphidt, want dphidt
    if (ilmn) then
      dphi1(:,:,:,1) = dphi1(:,:,:,1) / rho1(:,:,:,1)
    endif

  endsubroutine scalar_transport_eq

  !************************************************************
  subroutine scalar(dphi1, rho1, ux1, phi1)

    USE param
    USE variables
    USE decomp_2d
    USE var, ONLY : sgsphi1
    USE var, ONLY : ep1
    USE var, ONLY : phis1
    USE pipe

    implicit none

    !! INPUTS
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3)) :: ux1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3),numscalar) :: phi1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3),nrhotime) :: rho1

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime,numscalar) :: dphi1

    !! LOCALS
    integer :: icht,is

    !!=====================================================================
    !! XXX It is assumed that ux,uy,uz are already updated in all pencils!
    !!=====================================================================
    icht=0
    do is = 1, numscalar

       if (is.ne.primary_species) then
          !! For mass fractions enforce primary species Y_p = 1 - sum_s Y_s
          !! So don't solve a transport equation
          if (itype.eq.itype_pipe.and.itbc(is).eq.2) then !Treatment IF boundary condition    
              call phiw_if(phi1(:,:,:,is),ep1,is,1)
          elseif (itype.eq.itype_pipe.and.itbc(is).eq.3) then !Treatment CHT boundary condition    
              icht=icht+1
              call phiw_cht(phi1(:,:,:,is),phis1(:,:,:,icht),ep1,is,icht,1,1)
          endif
          call scalar_transport_eq(dphi1(:,:,:,:,is), rho1, ux1, phi1(:,:,:,is), sc(is),is)
          if (uset(is).ne.zero) then
             call scalar_settling(dphi1, phi1(:,:,:,is), is)
          endif
          ! If LES modelling is enabled, add the SGS stresses
          if (ilesmod.ne.0.and.jles.le.2.and.jles.gt.0) then
             dphi1(:,:,:,1,is) = dphi1(:,:,:,1,is) + sgsphi1(:,:,:,is)
          endif
       endif

    end do !loop numscalar

    if (primary_species.ge.1) then
       !! Compute rate of change of primary species
       dphi1(:,:,:,1,primary_species) = zero
       do is = 1, numscalar
          if (is.ne.primary_species) then
             dphi1(:,:,:,1,primary_species) = dphi1(:,:,:,1,primary_species) - dphi1(:,:,:,1,is)
          endif
       enddo
    endif

  end subroutine scalar

  subroutine scalar_settling(dphi1, phi1, is)

    USE param
    USE variables
    USE decomp_2d

    USE var, only : ta1, di1
    USE var, only : ta2, tb2, di2, phi2 => tc2
    USE var, only : ta3, di3, phi3 => tb3

    implicit none

    !! INPUTS
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3)) :: phi1
    integer,intent(in) :: is

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime,numscalar) :: dphi1

    call transpose_x_to_y(phi1, phi2)
    call transpose_y_to_z(phi2, phi3)

    CALL derz (ta3, phi3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    ta3(:,:,:) = uset(is) * gravz * ta3(:,:,:)

    call transpose_z_to_y(ta3, tb2)

    CALL dery (ta2, phi2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
    ta2(:,:,:) = uset(is) * gravy * ta2(:,:,:)
    ta2(:,:,:) = ta2(:,:,:) + tb2(:,:,:)

    call transpose_y_to_x(ta2, ta1)

    dphi1(:,:,:,1,is) = dphi1(:,:,:,1,is) - ta1(:,:,:)
    CALL derx (ta1, phi1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
    dphi1(:,:,:,1,is) = dphi1(:,:,:,1,is) - uset(is) * gravx * ta1(:,:,:)

  endsubroutine scalar_settling

  subroutine temperature_rhs_eq(drho1, rho1, ux1, phi1)

    USE param
    USE variables
    USE decomp_2d

    USE var, ONLY : te1, tb1

    implicit none

    !! INPUTS
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3)) :: ux1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3),nrhotime) :: rho1
    real(mytype),intent(in),dimension(xsize(1),xsize(2),xsize(3),numscalar) :: phi1

    !! OUTPUTS
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),ntime) :: drho1

    !! Get temperature
    CALL calc_temp_eos(te1, rho1(:,:,:,1), phi1, tb1, xsize(1), xsize(2), xsize(3))

    !!=====================================================================
    !! XXX It is assumed that ux,uy,uz are already updated in all pencils!
    !!=====================================================================
    call scalar_transport_eq(drho1, rho1, ux1, te1, prandtl,0)

  end subroutine temperature_rhs_eq


  SUBROUTINE continuity_rhs_eq(drho1, rho1, ux1, divu3)

    USE decomp_2d, ONLY : mytype, xsize, ysize, zsize
    USE decomp_2d, ONLY : transpose_z_to_y, transpose_y_to_x
    USE param, ONLY : ntime, nrhotime, ibirman_eos
    USE param, ONLY : xnu, prandtl
    USE variables

    USE var, ONLY : ta1, tb1, di1
    USE var, ONLY : rho2, uy2, ta2, tb2, di2
    USE var, ONLY : rho3, uz3, ta3, di3

    IMPLICIT NONE

    REAL(mytype), INTENT(IN), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ux1
    REAL(mytype), INTENT(IN), DIMENSION(xsize(1), xsize(2), xsize(3), nrhotime) :: rho1
    REAL(mytype), INTENT(IN), DIMENSION(zsize(1), zsize(2), zsize(3)) :: divu3

    REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3), ntime) :: drho1

    REAL(mytype) :: invpe

    invpe = xnu / prandtl

    !! XXX All variables up to date - no need to transpose

    CALL derz (ta3, rho3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    ta3(:,:,:) = uz3(:,:,:) * ta3(:,:,:) + rho3(:,:,:) * divu3(:,:,:)

    CALL transpose_z_to_y(ta3, tb2)
    CALL dery (ta2, rho2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
    ta2(:,:,:) = uy2(:,:,:) * ta2(:,:,:) + tb2(:,:,:)

    CALL transpose_y_to_x(ta2, ta1)
    CALL derx (drho1(:,:,:,1), rho1(:,:,:,1), &
         di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
    drho1(:,:,:,1) = -(ux1(:,:,:) * drho1(:,:,:,1) + ta1(:,:,:))

    IF (ibirman_eos) THEN !! Add a diffusion term
       CALL derzz (ta3,rho3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
       CALL transpose_z_to_y(ta3, tb2)

       CALL deryy (ta2,rho2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
       ta2(:,:,:) = ta2(:,:,:) + tb2(:,:,:)
       CALL transpose_y_to_x(ta2, ta1)

       CALL derxx (tb1,rho1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
       ta1(:,:,:) = ta1(:,:,:) + tb1(:,:,:)

       drho1(:,:,:,1) = drho1(:,:,:,1) + invpe * ta1(:,:,:)
    ENDIF

  ENDSUBROUTINE continuity_rhs_eq

END MODULE transeq
