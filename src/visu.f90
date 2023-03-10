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

module visu

  implicit none

  private
  public :: postprocessing

contains

  subroutine postprocessing(rho1, ux1, uy1, uz1, pp3, phi1, ep1)

    use decomp_2d, only : mytype, xsize, ph1
    use case, only : postprocess_case

    use stats, only : overall_statistic

    use var, only : nzmsize
    use var, only : itime
    use var, only : numscalar, nrhotime, npress

    real(mytype),dimension(xsize(1),xsize(2),xsize(3)), intent(in) :: ux1, uy1, uz1
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),numscalar), intent(in) :: phi1
    real(mytype),dimension(xsize(1),xsize(2),xsize(3),nrhotime), intent(in) :: rho1
    real(mytype),dimension(xsize(1),xsize(2),xsize(3)), intent(in) :: ep1
    real(mytype), dimension(ph1%zst(1):ph1%zen(1), ph1%zst(2):ph1%zen(2), nzmsize, npress), intent(in) :: pp3

    call write_snapshot(rho1, ux1, uy1, uz1, pp3, phi1, ep1, itime)
    call postprocess_case(rho1, ux1, uy1, uz1, pp3, phi1, ep1)
    call overall_statistic(ux1, uy1, uz1, phi1, pp3, ep1)

  end subroutine postprocessing

  subroutine write_snapshot(rho1, ux1, uy1, uz1, pp3, phi1, ep1, itime)

    use decomp_2d, only : transpose_x_to_y, transpose_y_to_z, transpose_z_to_y, transpose_y_to_x
    use decomp_2d, only : mytype, xsize, ysize, zsize
    use decomp_2d, only : fine_to_coarsev
    use decomp_2d_io, only : decomp_2d_write_one

    use param, only : ivisu, ioutput, nrhotime, ilmn, iscalar, iibm

    use variables, only : derx, dery, derz 
    use variables, only : ffx, ffxp, fsx, fsxp, fwx, fwxp
    use variables, only : ffy, ffyp, fsy, fsyp, fwy, fwyp, ppy
    use variables, only : ffz, ffzp, fsz, fszp, fwz, fwzp
    use variables, only : sx, cifip6, cisip6, ciwip6, cifx6, cisx6, ciwx6
    use variables, only : sy, cifip6y, cisip6y, ciwip6y, cify6, cisy6, ciwy6
    use variables, only : sz, cifip6z, cisip6z, ciwip6z, cifz6, cisz6, ciwz6
    use variables, only : numscalar

    use var, only : one
    use var, only : uvisu
    use var, only : pp1, ta1, tb1, tc1, td1, te1, tf1, tg1, th1, ti1, di1, nxmsize
    use var, only : pp2, ta2, tb2, tc2, td2, te2, tf2, ppi2, di2, dip2, ph2, nymsize
    use var, only : ppi3, ta3, tb3, tc3, td3, te3, tf3, di3, dip3, ph3, nzmsize
    use var, only : npress
    use var, only : phis1
    use variables, only : itbc

    implicit none

    character(len=30) :: filename

    !! inputs
    real(mytype), dimension(xsize(1), xsize(2), xsize(3)), intent(in) :: ux1, uy1, uz1
    real(mytype), dimension(xsize(1), xsize(2), xsize(3)), intent(in) :: ep1
    real(mytype), dimension(xsize(1), xsize(2), xsize(3), nrhotime), intent(in) :: rho1
    real(mytype), dimension(ph3%zst(1):ph3%zen(1),ph3%zst(2):ph3%zen(2),nzmsize,npress), intent(in) :: pp3
    real(mytype), dimension(xsize(1), xsize(2), xsize(3), numscalar), intent(in) :: phi1
    integer, intent(in) :: itime

    integer :: icht,is

    if ((ivisu.ne.0).and.(mod(itime, ioutput).eq.0)) then
       !! Write velocity
       !uvisu=0.
       if (iibm==2) then
          ta1(:,:,:) = (one - ep1(:,:,:)) * ux1(:,:,:)
       else
          ta1(:,:,:) = ux1(:,:,:)
       endif
       !call fine_to_coarseV(1,ta1,uvisu)
990    format('ux',I3.3)
       write(filename, 990) itime/ioutput
       call decomp_2d_write_one(1,ta1,filename,2)
       !!===DEBUG
       !call decomp_2d_write_one(1,uvisu,filename,2)

       !uvisu=0.
       if (iibm==2) then
          ta1(:,:,:) = (one - ep1(:,:,:)) * uy1(:,:,:)
       else
          ta1(:,:,:) = uy1(:,:,:)
       endif
       !call fine_to_coarseV(1,ta1,uvisu)
991    format('uy',I3.3)
       write(filename, 991) itime/ioutput
       call decomp_2d_write_one(1,ta1,filename,2)
       !===DEBUG
       !call decomp_2d_write_one(1,uvisu,filename,2)

       !uvisu=0.
       if (iibm==2) then
          ta1(:,:,:) = (one - ep1(:,:,:)) * uz1(:,:,:)
       else
          ta1(:,:,:) = uz1(:,:,:)
       endif
       !call fine_to_coarseV(1,ta1,uvisu)
992    format('uz',I3.3)
       write(filename, 992) itime/ioutput
       call decomp_2d_write_one(1,ta1,filename,2)
       !===DEBUG
       !call decomp_2d_write_one(1,uvisu,filename,2)

       !! Write pressure
       !WORK Z-PENCILS
       call interzpv(ppi3,pp3(:,:,:,1),dip3,sz,cifip6z,cisip6z,ciwip6z,cifz6,cisz6,ciwz6,&
            (ph3%zen(1)-ph3%zst(1)+1),(ph3%zen(2)-ph3%zst(2)+1),nzmsize,zsize(3),1)
       !WORK Y-PENCILS
       call transpose_z_to_y(ppi3,pp2,ph3) !nxm nym nz
       call interypv(ppi2,pp2,dip2,sy,cifip6y,cisip6y,ciwip6y,cify6,cisy6,ciwy6,&
            (ph3%yen(1)-ph3%yst(1)+1),nymsize,ysize(2),ysize(3),1)
       !WORK X-PENCILS
       call transpose_y_to_x(ppi2,pp1,ph2) !nxm ny nz
       call interxpv(ta1,pp1,di1,sx,cifip6,cisip6,ciwip6,cifx6,cisx6,ciwx6,&
            nxmsize,xsize(1),xsize(2),xsize(3),1)

       !uvisu=0._mytype
       if (iibm==2) then
          ta1(:,:,:) = (one - ep1(:,:,:)) * ta1(:,:,:)
       endif
       !call fine_to_coarseV(1,ta1,uvisu)
993    format('pp',I3.3)
       write(filename, 993) itime/ioutput
       call decomp_2d_write_one(1,ta1,filename,2)
       !===DEBUG
       !call decomp_2d_write_one(1,uvisu,filename,2)

       !! LMN - write out density
       if (ilmn) then
          uvisu=0.
          call fine_to_coarsev(1,rho1(:,:,:,1),uvisu)
995       format('rho',i3.3)
          write(filename, 995) itime/ioutput
          call decomp_2d_write_one(1,uvisu,filename,2)
       endif

       !! Scalars
       if (iscalar.ne.0) then
!996       format('phi',i1.1,i3.3)
!596       format('phis',i1.1,i3.3)
996       format('phi',i2.2,i3.3)
596       format('phis',i2.2,i3.3)
          icht=0
          do is = 1, numscalar
             if (iibm==2) then
                ta1(:,:,:) = (one - ep1(:,:,:)) * phi1(:,:,:,is)
             endif
             !uvisu=0.
             !call fine_to_coarsev(1,phi1(:,:,:,is),uvisu)
             write(filename, 996) is, itime/ioutput
             call decomp_2d_write_one(1,ta1,filename,2)
             !===DEBUG
             !call decomp_2d_write_one(1,uvisu,filename,2)

             !If Conjugate Heat Transfer, save solid temperature
             if (itbc(is).eq.3) then
                icht=icht+1
                ta1(:,:,:) = ep1(:,:,:) * phis1(:,:,:,icht)
                write(filename, 596) is, itime/ioutput
                call decomp_2d_write_one(1,ta1,filename,2)
             endif
          enddo
       endif
    endif
  end subroutine write_snapshot

endmodule visu
!############################################################################
subroutine VISU_PRE (pp3,ta1,tb1,di1,ta2,tb2,di2,ta3,di3,nxmsize,nymsize,nzmsize,uvisu,pre1)

  USE param
  USE variables
  USE decomp_2d
  USE decomp_2d_io

  implicit none

  integer :: nxmsize,nymsize,nzmsize

  real(mytype),dimension(xszV(1),xszV(2),xszV(3)) :: uvisu
  real(mytype),dimension(ph3%zst(1):ph3%zen(1),ph3%zst(2):ph3%zen(2),nzmsize) :: pp3
  !Z PENCILS NXM NYM NZM-->NXM NYM NZ
  real(mytype),dimension(ph3%zst(1):ph3%zen(1),ph3%zst(2):ph3%zen(2),zsize(3)) :: ta3,di3
  !Y PENCILS NXM NYM NZ -->NXM NY NZ
  real(mytype),dimension(ph3%yst(1):ph3%yen(1),nymsize,ysize(3)) :: ta2
  real(mytype),dimension(ph3%yst(1):ph3%yen(1),ysize(2),ysize(3)) :: tb2,di2
  !X PENCILS NXM NY NZ  -->NX NY NZ
  real(mytype),dimension(nxmsize,xsize(2),xsize(3)) :: ta1
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: tb1,di1,pre1

  character(len=30) filename

  !WORK Z-PENCILS
  call interzpv(ta3,pp3,di3,sz,cifip6z,cisip6z,ciwip6z,cifz6,cisz6,ciwz6,&
       (ph3%zen(1)-ph3%zst(1)+1),(ph3%zen(2)-ph3%zst(2)+1),nzmsize,zsize(3),1)
  !WORK Y-PENCILS
  call transpose_z_to_y(ta3,ta2,ph3) !nxm nym nz
  call interypv(tb2,ta2,di2,sy,cifip6y,cisip6y,ciwip6y,cify6,cisy6,ciwy6,&
       (ph3%yen(1)-ph3%yst(1)+1),nymsize,ysize(2),ysize(3),1)
  !WORK X-PENCILS
  call transpose_y_to_x(tb2,ta1,ph2) !nxm ny nz
  call interxpv(tb1,ta1,di1,sx,cifip6,cisip6,ciwip6,cifx6,cisx6,ciwx6,&
       nxmsize,xsize(1),xsize(2),xsize(3),1)

  pre1=tb1

  if (save_pre.eq.1) then
     uvisu=0._mytype
     call fine_to_coarseV(1,pre1,uvisu)
     write(filename,"('./data/pre',I4.4)") itime/ioutput
     call decomp_2d_write_one(1,uvisu,filename,2)
  endif

  if (save_prem.eq.1) then
     tb1=0._mytype
     call mean_plane_z(pre1,xsize(1),xsize(2),xsize(3),tb1(:,:,1))
     write(filename,"('./data/prem',I4.4)") itime/ioutput
     call decomp_2d_write_plane(1,tb1,3,1,filename)
  endif

  return

end subroutine VISU_PRE

!######################################################################################
subroutine mean_plane_x (f1,nx,ny,nz,fm1)

  use param, only : mytype, zero

  implicit none

  integer,intent(in) :: nx, ny, nz
  real(mytype),intent(in),dimension(nx,ny,nz) :: f1
  real(mytype),intent(out),dimension(ny,nz) :: fm1
  integer :: i,j,k

  fm1 = sum(f1,DIM=1)/real(nx,mytype)
  return

end subroutine mean_plane_x
!!######################################################################################
subroutine mean_plane_y (f2,nx,ny,nz,fm2)

  use param, only : mytype, zero

  implicit none

  integer,intent(in) :: nx, ny, nz
  real(mytype),intent(in),dimension(nx,ny,nz) :: f2
  real(mytype),intent(out),dimension(nx,nz) :: fm2
  integer :: i,j,k

  fm2 = sum(f2,DIM=2)/real(ny,mytype)
  return

end subroutine mean_plane_y
!######################################################################################
subroutine mean_plane_z (f3,nx,ny,nz,fm3)

  use param, only : mytype, zero

  implicit none

  integer,intent(in) :: nx, ny, nz
  real(mytype),intent(in),dimension(nx,ny,nz) :: f3
  real(mytype),intent(out),dimension(nx,ny) :: fm3
  integer :: i,j,k

  fm3 = sum(f3,DIM=3)/real(nz,mytype)
  return

end subroutine mean_plane_z
