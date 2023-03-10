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

subroutine corgp_IBM (ux,uy,uz,px,py,pz,nlock)
  USE param
  USE decomp_2d
  USE variables
  implicit none
  integer :: i,j,k,nlock
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ux,uy,uz,px,py,pz
  if (nlock.eq.1) then
     if (nz.gt.1) then
        do k = 1, xsize(3)
           do j = 1, xsize(2)
              do i = 1, xsize(1)
                 ux(i,j,k)=-px(i,j,k)+ux(i,j,k)
                 uy(i,j,k)=-py(i,j,k)+uy(i,j,k)
                 uz(i,j,k)=-pz(i,j,k)+uz(i,j,k)
              enddo
           enddo
        enddo
     else
        do j = 1, xsize(2)
           do i = 1, xsize(1)
              ux(i,j,k)=-px(i,j,k)+ux(i,j,k)
              uy(i,j,k)=-py(i,j,k)+uy(i,j,k)
           enddo
        enddo
     endif
  endif
  if (nlock.eq.2) then
     if (nz.gt.1) then
        do k = 1, xsize(3)
           do j = 1, xsize(2)
              do i = 1, xsize(1)
                 ux(i,j,k)=px(i,j,k)+ux(i,j,k)
                 uy(i,j,k)=py(i,j,k)+uy(i,j,k)
                 uz(i,j,k)=pz(i,j,k)+uz(i,j,k)
              enddo
           enddo
        enddo
     else
        do j = 1, xsize(2)
           do i = 1, xsize(1)
              ux(i,j,k)=px(i,j,k)+ux(i,j,k)
              uy(i,j,k)=py(i,j,k)+uy(i,j,k)
           enddo
        enddo
     endif
  endif

  return
end subroutine corgp_IBM
!*******************************************************************
subroutine body(ux1,uy1,uz1,ep1,arg)
  USE param
  USE decomp_2d
  USE decomp_2d_io
  USE variables
  implicit none
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ux1,uy1,uz1,ep1
  integer :: arg,i,j,k

#ifdef DEBG
  if (nrank .eq. 0) print *,'# body start'
#endif

  if (arg==0) then !First execution, initt epsi
     ep1(:,:,:)=zero
     !call geomcomplex(ep1,xstart(1),xend(1),ny,xstart(2),xend(2),xstart(3),xend(3),dx,yp,dz,one)
     call geomcomplex(ep1,nx,xstart(1),xend(1),ny,xstart(2),xend(2),nz,xstart(3),xend(3),xp,yp,zp,one)
  elseif (arg==1) then  !Any other iteration
     do k = 1, xsize(3)
        do j = 1, xsize(2)
           do i = 1, xsize(1)
              ux1(i,j,k)=(one-ep1(i,j,k))*ux1(i,j,k)
              uy1(i,j,k)=(one-ep1(i,j,k))*uy1(i,j,k)
              uz1(i,j,k)=(one-ep1(i,j,k))*uz1(i,j,k)
           enddo
        enddo
     enddo
  endif

  !X PENCILS

#ifdef DEBG
  if (nrank .eq. 0) print *,'# body done'
#endif

  return
end subroutine body
!*******************************************************************
!
!SUBROUTINE geomcomplex(epsi, nxi, nxf, ny, nyi, nyf, nzi, nzf, dx, yp, dz, remp)
SUBROUTINE geomcomplex(epsi, nx, nxi, nxf, ny, nyi, nyf, nz, nzi, nzf, xp, yp, zp, remp)
!
!*******************************************************************

  USE param, ONLY : itype, itype_cyl, itype_hill, itype_channel, itype_pipe
  USE decomp_2d, ONLY : mytype, nrank
  USE cyl, ONLY : geomcomplex_cyl
  USE channel, ONLY : geomcomplex_channel
  USE pipe, ONLY : geomcomplex_pipe

  IMPLICIT NONE

  !INTEGER :: nxi,nxf,ny,nyi,nyf,nzi,nzf
  INTEGER :: nx,nxi,nxf,ny,nyi,nyf,nz,nzi,nzf
  REAL(mytype),DIMENSION(nxi:nxf,nyi:nyf,nzi:nzf) :: epsi
  REAL(mytype)               :: dx,dz
  REAL(mytype),DIMENSION(ny) :: yp
  REAL(mytype)               :: remp
  REAL(mytype),DIMENSION(nx) :: xp
  REAL(mytype),DIMENSION(nz) :: zp

  IF (itype.EQ.itype_cyl) THEN

     CALL geomcomplex_cyl(epsi, nxi, nxf, ny, nyi, nyf, nzi, nzf, dx, yp, remp)

  ELSEIF (itype.EQ.itype_channel) THEN

     CALL geomcomplex_channel(epsi, nxi, nxf, ny, nyi, nyf, nzi, nzf, yp, remp)

  ELSEIF (itype.EQ.itype_pipe) THEN

     !CALL geomcomplex_pipe(epsi, nxi, nxf, ny, nyi, nyf, nzi, nzf, dx, yp, dz, remp)
     CALL geomcomplex_pipe(epsi, nx, nxi, nxf, ny, nyi, nyf, nz, nzi, nzf, xp, yp, zp, remp)

  ENDIF

END SUBROUTINE geomcomplex
!*******************************************************************
subroutine genepsi3d(ep1)

  USE var, only : epm
  USE variables, only : nx,ny,nz,nxm,nym,nzm,yp
  USE param, only : xlx,yly,zlz,dx,dy,dz,izap,npif,nclx,ncly,nclz,istret
  USE complex_geometry
  use decomp_2d
  use pipe, only : exact_ib_pipe

  implicit none

  !*****************************************************************!
  ! 0- This program will generate all the files necessary for our
  !    customize IMB based on Lagrange reconstructions
  ! 3- The object is defined in the cylinder subroutine
  ! 4- You can add your own subroutine for your own object
  ! 7- Please cite the following paper if you are using this file:
  ! Gautier R., Laizet S. & Lamballais E., 2014, A DNS study of
  ! jet control with microjets using an alterna ng direc on forcing
  ! strategy, Int. J. of Computa onal Fluid Dynamics, 28, 393--410
  !*****************************************************************!
  !
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ep1
  !
  if (nrank==0) print *,'Generating the geometry!'
  call gene_epsi_3D(ep1,nx,ny,nz,dx,dy,dz,xlx,yly,zlz ,&
       nclx,ncly,nclz,nxraf,nyraf,nzraf   ,&
       xi,xf,yi,yf,zi,zf,nobjx,nobjy,nobjz,&
       nobjmax,yp,nraf)
  call verif_epsi(ep1,npif,izap,nx,ny,nz,nobjmax,&
       nxipif,nxfpif,nyipif,nyfpif,nzipif,nzfpif)
  if (iepm.eq.1) then !One-mesh retracted epsilon matrix 
      call gene_epsim(ep1,epm,nx,ny,nz,nobjx,nobjy,nobjz,&
                      xi,xf,yi,yf,zi,zf,nobjmax,dx,dy,dz,1.d0,&
                      xlx,yly,zlz,yp) 
  endif
  !!====DEBUG
  !call exact_ib_pipe(ep1,xi,xf,yi,yf,zi,zf,nobjx,nobjy,nobjz,yp)

  call write_geomcomplex(nx,ny,nz,ep1,epm,nobjx,nobjy,nobjz,xi,xf,yi,yf,zi,zf,&
       nxipif,nxfpif,nyipif,nyfpif,nzipif,nzfpif,nobjmax,npif)
  
end subroutine genepsi3d
!
!***************************************************************************
!
  subroutine gene_epsi_3D(ep1,nx,ny,nz,dx,dy,dz,xlx,yly,zlz,&
                          nclx,ncly,nclz,nxraf,nyraf,nzraf,&
                          xi,xf,yi,yf,zi,zf,nobjx,nobjy,nobjz,&
                          nobjmax,yp,nraf)
!
!***************************************************************************
    use param, only : zero,half, one, two
    use decomp_2d
    use decomp_2d_io
    use MPI
    USE var, only : ta2,ta3
    use variables, only : xp,zp
    implicit none
    !
    real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ep1
    !real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: ep2
    !real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: ep3
    integer                                            :: nx,ny,nz,nobjmax
    real(mytype)                                       :: dx,dy,dz
    real(mytype)                                       :: xlx,yly,zlz
    logical                                            :: nclx,ncly,nclz
    integer                                            :: nxraf,nyraf,nzraf
    integer                                            :: nraf
    integer,     dimension(xsize(2),xsize(3))          :: nobjx,nobjxraf
    integer,     dimension(ysize(1),ysize(3))          :: nobjy,nobjyraf
    integer,     dimension(zsize(1),zsize(2))          :: nobjz,nobjzraf
    real(mytype),dimension(nobjmax,xsize(2),xsize(3))  :: xi,xf
    real(mytype),dimension(nobjmax,ysize(1),ysize(3))  :: yi,yf
    real(mytype),dimension(nobjmax,zsize(1),zsize(2))  :: zi,zf
    real(mytype),allocatable,dimension(:,:,:)          :: xepsi,yepsi,zepsi
    !real(mytype),dimension(nxraf,xsize(2),xsize(3))    :: xepsi
    !real(mytype),dimension(ysize(1),nyraf,ysize(3))    :: yepsi
    !real(mytype),dimension(zsize(1),zsize(2),nzraf)    :: zepsi
    real(mytype),dimension(ny)                         :: yp
    real(mytype),dimension(nxraf)                      :: xpraf
    real(mytype),dimension(nyraf)                      :: ypraf
    real(mytype),dimension(nzraf)                      :: zpraf
    real(mytype)                     :: dxraf,dyraf,dzraf
    integer                          :: i,j,k
    integer                          :: ii,jj,kk
    real(mytype)                     :: x,y,z
    integer                          :: inum,jnum,knum
    integer                          :: ibug,jbug,kbug
    integer                          :: iobj,jobj,kobj
    integer                          :: iflu,jflu,kflu
    integer                          :: isol,jsol,ksol
    integer                          :: iraf,jraf,kraf
    integer                          :: nobjxmax ,nobjymax ,nobjzmax
    integer                          :: nobjxmaxraf,nobjymaxraf,nobjzmaxraf
    integer                          :: idebraf,jdebraf,kdebraf
    integer                          :: ifinraf,jfinraf,kfinraf
    character(len=4) suffixe
    integer                          :: numvis
    integer                          :: mpi_aux_i, code

    ep1=zero
    !call geomcomplex(ep1,xstart(1),xend(1),ny,xstart(2),xend(2),xstart(3),xend(3),dx,yp,dz,one)
    call geomcomplex(ep1,nx,xstart(1),xend(1),ny,xstart(2),xend(2),nz,xstart(3),xend(3),xp,yp,zp,one)
    !if (nrank==0) print*,'    step 1'
    xpraf=zero
    ypraf=zero
    zpraf=zero

    !-------------------------------------------------------------------------------
    !X-PENCIL
      allocate(xepsi(nxraf,xsize(2),xsize(3)))

      if(nclx)then
         dxraf =xlx/real(nxraf, mytype)
      else
         dxraf =xlx/real(nxraf-1, mytype)
      endif
      do i=1,nx-1
         do iraf=1,nraf
            xpraf(iraf+nraf*(i-1))=xp(i)+real(iraf-1, mytype)*(xp(i+1)-xp(i))/real(nraf, mytype)
         enddo
      enddo
      if(nclx)then
         do iraf=1,nraf
             xpraf(iraf+nraf*(nx-1))=xp(nx)+real(iraf-1, mytype)*(xlx+xp(1)-xp(nx))/real(nraf, mytype)
         enddo
      else
         xpraf(nxraf)=xp(nx)
      endif
      !if(.not.nclx)xpraf(nxraf)=xp(nx)
      xepsi=zero
      !call geomcomplex(xepsi,1,nxraf,ny,xstart(2),xend(2),xstart(3),xend(3),dxraf,yp,dz,one)
      call geomcomplex(xepsi,nxraf,1,nxraf,ny,xstart(2),xend(2),nz,xstart(3),xend(3),xpraf,yp,zp,one)
      !if (nrank==0) print*,'    step 2'

      nobjx(:,:)=0
      nobjxmax=0
      do k=1,xsize(3)
         do j=1,xsize(2)
            inum=0
            if(ep1(1,j,k).eq.1.)then
               inum=1
               nobjx(j,k)=1
            endif
            do i=1,nx-1
               if(ep1(i,j,k).eq.0..and.ep1(i+1,j,k).eq.1.)then
                  inum=inum+1
                  nobjx(j,k)=nobjx(j,k)+1
               endif
            enddo
            if(inum.gt.nobjxmax)then
               nobjxmax=inum
            endif
         enddo
      enddo
      call MPI_REDUCE(nobjxmax,mpi_aux_i,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,code)
      ! if (nrank==0) print*,'        nobjxmax=',mpi_aux_i

      nobjxraf(:,:)=0
      ibug=0
      nobjxmaxraf=0
      inum=0
      do k=1,xsize(3)
         do j=1,xsize(2)
            inum=0
            if(xepsi(1,j,k).eq.1.)then
               inum=1
               nobjxraf(j,k)=1
            endif
            do i=1,nxraf-1
               if(xepsi(i,j,k).eq.zero.and.xepsi(i+1,j,k).eq.one)then
                  inum=inum+1
                  nobjxraf(j,k)=nobjxraf(j,k)+1
               endif
            enddo
            if(inum.gt.nobjxmaxraf)then
               nobjxmaxraf=inum
            endif
            if(nobjx(j,k).ne.nobjxraf(j,k))then
               ibug=ibug+1
            endif
         enddo
      enddo
      call MPI_REDUCE(nobjxmaxraf,mpi_aux_i,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,code)
      ! if (nrank==0) print*,'        nobjxmaxraf=',mpi_aux_i
      call MPI_REDUCE(ibug,mpi_aux_i,1,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,code)
      ! if (nrank==0) print*,'        ibug=',mpi_aux_i
      !if (nrank==0) print*,'    step 3'

      do k=1,xsize(3)
         do j=1,xsize(2)
            inum=0
            if(xepsi(1,j,k) == one)then
               inum=inum+1
               !xi(inum,j,k)=-dx!-xlx
               xi(inum,j,k)=-(xp(2)-xp(1))!-xlx
            endif
            do i=1,nxraf-1
               if(xepsi(i,j,k) == zero .and. xepsi(i+1,j,k) == one)then
                  inum=inum+1
                  !xi(inum,j,k)=dxraf*real(i-1, mytype)+dxraf*half
                  xi(inum,j,k)=xpraf(i)+(xpraf(i+1)-xpraf(i))*half
               elseif(xepsi(i,j,k) == one .and. xepsi(i+1,j,k)== zero)then
                  !xf(inum,j,k)=dxraf*real(i-1, mytype)+dxraf*half
                  xf(inum,j,k)=xpraf(i)+(xpraf(i+1)-xpraf(i))*half
               endif
            enddo
            if(xepsi(nxraf,j,k)==1.)then
               !xf(inum,j,k)=xlx+dx!2.*xlx
               xf(inum,j,k)=xlx+(xp(nx)-xp(nx-1))*half!2.*xlx
            endif
         enddo
      enddo

      if(ibug /= 0)then
         do k=1,xsize(3)
            do j=1,xsize(2)
               if(nobjx(j,k) /= nobjxraf(j,k))then
                  iobj=0
                  if(ep1(1,j,k) == one)iobj=iobj+1
                  do i=1,nx-1
                     if(ep1(i,j,k) == zero .and. ep1(i+1,j,k) ==  one)iobj=iobj+1
                     if(ep1(i,j,k) == zero .and. ep1(i+1,j,k) == zero)iflu=1
                     if(ep1(i,j,k) ==  one .and. ep1(i+1,j,k) ==  one)isol=1
                     do iraf=1,nraf
                        if(xepsi(iraf+nraf*(i-1)  ,j,k) == zero .and.&
                           xepsi(iraf+nraf*(i-1)+1,j,k) ==  one)idebraf=iraf+nraf*(i-1)+1
                        if(xepsi(iraf+nraf*(i-1)  ,j,k) ==  one .and.&
                           xepsi(iraf+nraf*(i-1)+1,j,k) == zero)ifinraf=iraf+nraf*(i-1)+1
                     enddo
                     if(idebraf /= 0 .and. ifinraf /= 0 .and.&
                        idebraf < ifinraf .and. iflu == 1)then
                        iobj=iobj+1
                        do ii=iobj,nobjmax-1
                           xi(ii,j,k)=xi(ii+1,j,k)
                           xf(ii,j,k)=xf(ii+1,j,k)
                        enddo
                        iobj=iobj-1
                     endif
                     if(idebraf /= 0 .and. ifinraf /= 0 .and.&
                        idebraf > ifinraf .and. isol==1)then
                        iobj=iobj+1
                        do ii=iobj,nobjmax-1
                           xi(ii,j,k)=xi(ii+1,j,k)
                        enddo
                        iobj=iobj-1
                        do ii=iobj,nobjmax-1
                           xf(ii,j,k)=xf(ii+1,j,k)
                        enddo
                     endif
                     idebraf=0
                     ifinraf=0
                     iflu=0
                  enddo
               endif
            enddo
         enddo
      endif
      !if (nrank==0) write(*,*) '    step 4'
      deallocate(xepsi)

    !-------------------------------------------------------------------------------
    !Y-PENCIL
      allocate(yepsi(ysize(1),nyraf,ysize(3)))
      call transpose_x_to_y(ep1,ta2)

      if(ncly)then
         dyraf =yly/real(nyraf, mytype)
      else
         dyraf =yly/real(nyraf-1, mytype)
      endif
      do j=1,ny-1
         do jraf=1,nraf
            ypraf(jraf+nraf*(j-1))=yp(j)+real(jraf-1, mytype)*(yp(j+1)-yp(j))/real(nraf, mytype)
         enddo
      enddo
      if(ncly)then
         do jraf=1,nraf
             ypraf(jraf+nraf*(ny-1))=yp(ny)+real(jraf-1, mytype)*(yly+yp(1)-yp(ny))/real(nraf, mytype)
         enddo
      else
         ypraf(nyraf)=yp(ny)
      endif
      !if(.not.ncly)ypraf(nyraf)=yp(ny)
      yepsi=zero
      !call geomcomplex(yepsi,ystart(1),yend(1),nyraf,1,nyraf,ystart(3),yend(3),dx,ypraf,dz,one)
      call geomcomplex(yepsi,nx,ystart(1),yend(1),nyraf,1,nyraf,nz,ystart(3),yend(3),xp,ypraf,zp,one)
      !if (nrank==0) print*,'    step 5'

      nobjy(:,:)=0
      nobjymax=0
      call transpose_x_to_y(ep1,ta2)
      do k=1,ysize(3)
         do i=1,ysize(1)
            jnum=0
            if(ta2(i,1,k) == one)then
               jnum=1
               nobjy(i,k)=1
            endif
            do j=1,ny-1
               if(ta2(i,j,k) == zero .and. ta2(i,j+1,k) == one)then
                  jnum=jnum+1
                  nobjy(i,k)=nobjy(i,k)+1
               endif
            enddo
            if(jnum.gt.nobjymax)then
               nobjymax=jnum
            endif
         enddo
      enddo
      call MPI_REDUCE(nobjymax,mpi_aux_i,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,code)
      ! if (nrank==0) print*,'        nobjymax=',mpi_aux_i

      nobjyraf(:,:)=0
      jbug=0
      nobjymaxraf=0
      jnum=0
      do k=1,ysize(3)
         do i=1,ysize(1)
            jnum=0
            if(yepsi(i,1,k) == one)then
               jnum=1
               nobjyraf(i,k)=1
            endif
            do j=1,nyraf-1
               if(yepsi(i,j,k) == zero .and. yepsi(i,j+1,k) == one)then
                  jnum=jnum+1
                  nobjyraf(i,k)=nobjyraf(i,k)+1
               endif
            enddo
            if(jnum.gt.nobjymaxraf)then
               nobjymaxraf=jnum
            endif
            if(nobjy(i,k).ne.nobjyraf(i,k))then
               jbug=jbug+1
            endif
         enddo
      enddo
      call MPI_REDUCE(nobjymaxraf,mpi_aux_i,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,code)
      ! if (nrank==0) print*,'        nobjymaxraf=',mpi_aux_i
      call MPI_REDUCE(jbug,mpi_aux_i,1,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,code)
      ! if (nrank==0) print*,'        jbug=',mpi_aux_i
       !if (nrank==0) print*,'    step 6'

      do k=1,ysize(3)
         do i=1,ysize(1)
            jnum=0
            if(yepsi(i,1,k) == one)then
               jnum=jnum+1
               yi(jnum,i,k)=-(yp(2)-yp(1))!-yly
            endif
            do j=1,nyraf-1
               if(yepsi(i,j,k) == zero .and. yepsi(i,j+1,k) == one)then
                  jnum=jnum+1
                  yi(jnum,i,k)=ypraf(j)+(ypraf(j+1)-ypraf(j))*half!dyraf*(j-1)+dyraf/2.
               elseif(yepsi(i,j,k) == one .and. yepsi(i,j+1,k) == zero)then
                  yf(jnum,i,k)=ypraf(j)+(ypraf(j+1)-ypraf(j))*half!dyraf*(j-1)+dyraf/2.
               endif
            enddo
            if(yepsi(i,nyraf,k) == one)then
               yf(jnum,i,k)=yly+(yp(ny)-yp(ny-1))*half!2.*yly
            endif
         enddo
      enddo

      if(jbug /= 0)then
         do k=1,ysize(3)
            do i=1,ysize(1)
               if(nobjy(i,k) /= nobjyraf(i,k))then
                  jobj=0
                  if(ta2(i,1,k) == one)jobj=jobj+1
                  do j=1,ny-1
                     if(ta2(i,j,k) == zero .and. ta2(i,j+1,k) ==  one)jobj=jobj+1
                     if(ta2(i,j,k) == zero .and. ta2(i,j+1,k) == zero)jflu=1
                     if(ta2(i,j,k) ==  one .and. ta2(i,j+1,k) ==  one)jsol=1
                     do jraf=1,nraf
                        if(yepsi(i,jraf+nraf*(j-1)  ,k) == zero .and.&
                           yepsi(i,jraf+nraf*(j-1)+1,k) ==  one)jdebraf=jraf+nraf*(j-1)+1
                        if(yepsi(i,jraf+nraf*(j-1)  ,k) ==  one .and.&
                           yepsi(i,jraf+nraf*(j-1)+1,k) == zero)jfinraf=jraf+nraf*(j-1)+1
                     enddo
                     if(jdebraf /= 0 .and. jfinraf /= 0 .and.&
                        jdebraf < jfinraf.and.jflu == 1)then
                        jobj=jobj+1
                        do jj=jobj,nobjmax-1
                           yi(jj,i,k)=yi(jj+1,i,k)
                           yf(jj,i,k)=yf(jj+1,i,k)
                        enddo
                        jobj=jobj-1
                     endif
                     if(jdebraf /= 0 .and. jfinraf /= 0 .and.&
                        jdebraf > jfinraf .and. jsol == 1)then
                        jobj=jobj+1
                        do jj=jobj,nobjmax-1
                           yi(jj,i,k)=yi(jj+1,i,k)
                        enddo
                        jobj=jobj-1
                        do jj=jobj,nobjmax-1
                           yf(jj,i,k)=yf(jj+1,i,k)
                        enddo
                     endif
                     jdebraf=0
                     jfinraf=0
                     jflu=0
                  enddo
               endif
            enddo
         enddo
      endif
      !if (nrank==0) write(*,*) '    step 7'
      deallocate(yepsi)

    !-------------------------------------------------------------------------------
    !Z-PENCIL
    allocate(zepsi(zsize(1),zsize(2),nzraf))
    call transpose_y_to_z(ta2,ta3)

    if(nclz)then
       dzraf=zlz/real(nzraf, mytype)
    else
       dzraf=zlz/real(nzraf-1, mytype)
    endif
    do k=1,nz-1
       do kraf=1,nraf
          zpraf(kraf+nraf*(k-1))=zp(k)+real(kraf-1, mytype)*(zp(k+1)-zp(k))/real(nraf, mytype)
       enddo
    enddo
    if(nclz)then
       do kraf=1,nraf
           zpraf(kraf+nraf*(nz-1))=zp(nz)+real(kraf-1, mytype)*(zlz+zp(1)-zp(nz))/real(nraf, mytype)
       enddo
    else
       zpraf(nzraf)=zp(nz)
    endif
    !if(.not.nclz)zpraf(nzraf)=zp(nz)
    zepsi=zero
    !call geomcomplex(zepsi,zstart(1),zend(1),ny,zstart(2),zend(2),1,nzraf,dx,yp,dzraf,one)
    call geomcomplex(zepsi,nx,zstart(1),zend(1),ny,zstart(2),zend(2),nzraf,1,nzraf,xp,yp,zpraf,one)
    !if (nrank==0) print*,'    step 8'

    nobjz(:,:)=0
    nobjzmax=0
    call transpose_y_to_z(ta2,ta3)
    do j=1,zsize(2)
       do i=1,zsize(1)
          knum=0
          if(ta3(i,j,1) == one)then
             knum=1
             nobjz(i,j)=1
          endif
          do k=1,nz-1
             if(ta3(i,j,k) == zero .and. ta3(i,j,k+1) == one)then
                knum=knum+1
                nobjz(i,j)=nobjz(i,j)+1
             endif
          enddo
          if(knum.gt.nobjzmax)then
             nobjzmax=knum
          endif
       enddo
    enddo
    call MPI_REDUCE(nobjzmax,mpi_aux_i,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,code)
    ! if (nrank==0) print*,'        nobjzmax=',mpi_aux_i

    nobjzraf(:,:)=0
    kbug=0
    nobjzmaxraf=0
    knum=0
    do j=1,zsize(2)
       do i=1,zsize(1)
          knum=0
          if(zepsi(i,j,1) == one)then
             knum=1
             nobjzraf(i,j)=1
          endif
          do k=1,nzraf-1
             if(zepsi(i,j,k) == zero .and. zepsi(i,j,k+1) == one)then
                knum=knum+1
                nobjzraf(i,j)=nobjzraf(i,j)+1
             endif
          enddo
          if(knum.gt.nobjzmaxraf)then
             nobjzmaxraf=knum
          endif
          if(nobjz(i,j).ne.nobjzraf(i,j))then
             kbug=kbug+1
          endif
       enddo
    enddo
    call MPI_REDUCE(nobjzmaxraf,mpi_aux_i,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,code)
    ! if (nrank==0) print*,'        nobjzmaxraf=',mpi_aux_i
    call MPI_REDUCE(kbug,mpi_aux_i,1,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,code)
    ! if (nrank==0) print*,'        kbug=',mpi_aux_i
    !if (nrank==0) print*,'    step 9'

    do j=1,zsize(2)
       do i=1,zsize(1)
          knum=0
          if(zepsi(i,j,1) == one)then
             knum=knum+1
             !zi(knum,i,j)=-dz!zlz
             zi(knum,i,j)=-(zp(2)-zp(1))!-zlz
          endif
          do k=1,nzraf-1
             if(zepsi(i,j,k) == zero .and. zepsi(i,j,k+1) == one)then
                knum=knum+1
                !zi(knum,i,j)=dzraf*real(k-1, mytype)+dzraf*half
                zi(knum,i,j)=zpraf(k)+(zpraf(k+1)-zpraf(k))*half
             elseif(zepsi(i,j,k) == one .and. zepsi(i,j,k+1) == zero)then
                !zf(knum,i,j)=dzraf*real(k-1, mytype)+dzraf*half
                zf(knum,i,j)=zpraf(k)+(zpraf(k+1)-zpraf(k))*half
             endif
          enddo
          if(zepsi(i,j,nzraf) == one)then
             !zf(knum,i,j)=zlz+dz!2.*zlz
             zf(knum,i,j)=zlz+(zp(nz)-zp(nz-1))*half
          endif
       enddo
    enddo

    kdebraf=0
    if(kbug.ne.0)then
       do j=1,zsize(2)
          do i=1,zsize(1)
             if(nobjz(i,j) /= nobjzraf(i,j))then
                kobj=0
                if(ta3(i,j,1) == one)kobj=kobj+1
                do k=1,nz-1
                   if(ta3(i,j,k) == zero .and. ta3(i,j,k+1) ==  one)kobj=kobj+1
                   if(ta3(i,j,k) == zero .and. ta3(i,j,k+1) == zero)kflu=1
                   if(ta3(i,j,k) ==  one .and. ta3(i,j,k+1) ==  one)ksol=1
                   do kraf=1,nraf
                      if(zepsi(i,j,kraf+nraf*(k-1)  ) == zero .and.&
                         zepsi(i,j,kraf+nraf*(k-1)+1) ==  one)kdebraf=kraf+nraf*(k-1)+1
                      if(zepsi(i,j,kraf+nraf*(k-1)  ) ==  one .and.&
                         zepsi(i,j,kraf+nraf*(k-1)+1) == zero)kfinraf=kraf+nraf*(k-1)+1
                   enddo
                   if(kdebraf /= 0      .and. kfinraf /= 0 .and.&
                      kdebraf < kfinraf .and. kflu    == 1)then
                      kobj=kobj+1
                      do kk=kobj,nobjmax-1
                         zi(kk,i,j)=zi(kk+1,i,j)
                         zf(kk,i,j)=zf(kk+1,i,j)
                      enddo
                      kobj=kobj-1
                   endif
                   if(kdebraf /= 0      .and. kfinraf /= 0.and.&
                      kdebraf > kfinraf .and.    ksol == 1)then
                      kobj=kobj+1
                      do kk=kobj,nobjmax-1
                         zi(kk,i,j)=zi(kk+1,i,j)
                      enddo
                      kobj=kobj-1
                      do kk=kobj,nobjmax-1
                         zf(kk,i,j)=zf(kk+1,i,j)
                      enddo
                   endif
                   kdebraf=0
                   kfinraf=0
                   kflu=0
                enddo
             endif
          enddo
       enddo
    endif
    !if (nrank==0) print*,'    step 10'
    deallocate(zepsi)
    !
    return
  end subroutine gene_epsi_3D
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine gene_epsim(epsi,epsim,nx,ny,nz,nobjx,nobjy,nobjz,&
                      xi,xf,yi,yf,zi,zf,nobjmax,dx,dy,dz,nepm,&
                      xlx,yly,zlz,yp)
  use decomp_2d
  use MPI
  USE var, only : ta2,tb2,ta3,tb3
  implicit none
  !
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: epsi,epsim
  !real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: epsim2,epsi2
  !real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: epsim3,epsi3
  real(mytype),dimension(nobjmax,xsize(2),xsize(3))  :: xi,xf
  real(mytype),dimension(nobjmax,ysize(1),ysize(3))  :: yi,yf
  real(mytype),dimension(nobjmax,zsize(1),zsize(2))  :: zi,zf
  integer,     dimension(xsize(2),xsize(3))          :: nobjx
  integer,     dimension(ysize(1),ysize(3))          :: nobjy
  integer,     dimension(zsize(1),zsize(2))          :: nobjz
  real(mytype),dimension(ny)                         :: yp
  real(mytype)                                       :: x,y,z
  real(mytype)                                       :: dx,dy,dz
  real(mytype)                                       :: xlx,yly,zlz
  real(mytype)                                       :: xe,ye,ze
  real(mytype)                                       :: nepm !# of elements to retract
  integer                                            :: i,j,k
  integer                                            :: ix,jy,kz
  integer                                            :: nx,ny,nz,nobjmax
  !
  !if (nrank==0) print*,'    step 14'
  epsim(:,:,:)=epsi(:,:,:)
  xe=nepm*dx
  do k=1,xsize(3)
     do j=1,xsize(2)
        do i=1,nx
           if(epsi(i,j,k).eq.1..and.&
                nobjx(j,k).ne.0)then
              x=dx*(i-1)
              do ix=1,nobjx(j,k)
                 if(x  .ge.xi(ix,j,k)   .and.&
                      x  .le.xi(ix,j,k)+xe.and.&
                      0. .lt.xi(ix,j,k)   .or. &
                      x  .le.xf(ix,j,k)   .and.&
                      x  .ge.xf(ix,j,k)-xe.and.&
                      xlx.gt.xf(ix,j,k)   )then
                        epsim(i,j,k)=0.
                 endif
              enddo
           endif
        enddo
     enddo
  enddo
  !if (nrank==0) print*,'    step 15'
  call transpose_x_to_y(epsim,tb2)
  call transpose_x_to_y(epsi,ta2)
  !if (nrank==0) print*,'    step 16'
  do k=1,ysize(3)
     do i=1,ysize(1)
        do j=2,ny-1
           if(ta2(i,j,k).eq.1..and.&
                nobjy (i,k).gt.0)then
              y=yp(j)
              ye=nepm*(yp(j+1)-yp(j-1))/2.
              do jy=1,nobjy(i,k)
                 if(y  .ge.yi(jy,i,k)   .and.&
                      y  .le.yi(jy,i,k)+ye.and.&
                      0. .lt.yi(jy,i,k)   .or. &
                      y  .le.yf(jy,i,k)   .and.&
                      y  .ge.yf(jy,i,k)-ye.and.&
                      yly.gt.yf(jy,i,k)   )then
                        tb2(i,j,k)=0.
                 endif
              enddo
           endif
        enddo
     enddo
  enddo
  !if (nrank==0) print*,'    step 17'
  call transpose_y_to_z(tb2,tb3)
  call transpose_y_to_z(ta2,ta3)
  ze=nepm*dz
  !if (nrank==0) print*,'    step 18'
  do j=1,zsize(2)
     do i=1,zsize(1)
        do k=1,nz
           if(ta3(i,j,k).eq.1..and.&
                nobjz (i,j).gt.0)then
              z=dz*(k-1)
              do kz=1,nobjz(i,j)
                 if(z  .ge.zi(kz,i,j)   .and.&
                      z  .le.zi(kz,i,j)+ze.and.&
                      0. .lt.zi(kz,i,j)   .or. &
                      z  .le.zf(kz,i,j)   .and.&
                      z  .ge.zf(kz,i,j)-ze.and.&
                      zlz.gt.zf(kz,i,j)   )then
                        tb3(i,j,k)=0.
                 endif
              enddo
           endif
        enddo
     enddo
  enddo
  !if (nrank==0) print*,'    step 19'
  call transpose_z_to_y(tb3,tb2)
  call transpose_y_to_x(tb2,epsim)
  !if (nrank==0) print*,'    step 20'
  !
  return
end subroutine gene_epsim
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine verif_epsi(ep1,npif,izap,nx,ny,nz,nobjmax,&
     nxipif,nxfpif,nyipif,nyfpif,nzipif,nzfpif)
  use decomp_2d
  use MPI
  USE var, only : ta2,ta3

  implicit none
  !
  integer                            :: nx,ny,nz,nobjmax
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ep1
  !real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: ep2
  !real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: ep3
  integer,dimension(0:nobjmax,xsize(2),xsize(3)) :: nxipif,nxfpif
  integer,dimension(0:nobjmax,ysize(1),ysize(3)) :: nyipif,nyfpif
  integer,dimension(0:nobjmax,zsize(1),zsize(2)) :: nzipif,nzfpif
  integer                            :: npif,izap
  integer                            :: i,j,k
  integer                            :: inum ,jnum ,knum
  integer                            :: iflu ,jflu ,kflu
  integer                            :: ising,jsing,ksing,itest
  integer                            :: mpi_aux_i, code

  !x-pencil
  nxipif(:,:,:)=npif
  nxfpif(:,:,:)=npif
  ising=0
  do k=1,xsize(3)
     do j=1,xsize(2)
        inum=0
        iflu=0
        if(ep1(1,j,k).eq.1.)inum=inum+1
        if(ep1(1,j,k).eq.0.)iflu=iflu+1
        do i=2,nx
           if(ep1(i  ,j,k).eq.0.)iflu=iflu+1
           if(ep1(i-1,j,k).eq.0..and.&
                ep1(i  ,j,k).eq.1.)then
              inum=inum+1
              if(inum.eq.1)then
                 nxipif(inum  ,j,k)=iflu-izap
                 if(iflu-izap.lt.npif)ising=ising+1
                 if(iflu-izap.ge.npif)nxipif(inum  ,j,k)=npif
                 iflu=0
              else
                 nxipif(inum  ,j,k)=iflu-izap
                 nxfpif(inum-1,j,k)=iflu-izap
                 if(iflu-izap.lt.npif)ising=ising+1
                 if(iflu-izap.ge.npif)nxipif(inum  ,j,k)=npif
                 if(iflu-izap.ge.npif)nxfpif(inum-1,j,k)=npif
                 iflu=0
              endif
           endif
           if(ep1(i,j,k).eq.1.)iflu=0
        enddo
        if(ep1(nx,j,k).eq.0.)then
           nxfpif(inum,j,k)=iflu-izap
           if(iflu-izap.lt.npif)ising=ising+1
           if(iflu-izap.lt.npif)nxfpif(inum,j,k)=npif
        endif
     enddo
  enddo
  call MPI_REDUCE(ising,mpi_aux_i,1,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,code)
  if (nrank==0) print*,'        number of points with potential problem in X :',mpi_aux_i
  !if (nrank==0) print*,'    step 11'

  !y-pencil
  call transpose_x_to_y(ep1,ta2)
  nyipif(:,:,:)=npif
  nyfpif(:,:,:)=npif
  jsing=0
  do k=1,ysize(3)
     do i=1,ysize(1)
        jnum=0
        jflu=0
        if(ta2(i,1,k).eq.1.)jnum=jnum+1
        if(ta2(i,1,k).eq.0.)jflu=jflu+1
        do j=2,ny
           if(ta2(i,j  ,k).eq.0.)jflu=jflu+1
           if(ta2(i,j-1,k).eq.0..and.&
                ta2(i,j  ,k).eq.1.)then
              jnum=jnum+1
              if(jnum.eq.1)then
                 nyipif(jnum  ,i,k)=jflu-izap
                 if(jflu-izap.lt.npif)jsing=jsing+1
                 if(jflu-izap.ge.npif)nyipif(jnum  ,i,k)=npif
                 jflu=0
              else
                 nyipif(jnum  ,i,k)=jflu-izap
                 nyfpif(jnum-1,i,k)=jflu-izap
                 if(jflu-izap.lt.npif)jsing=jsing+1
                 if(jflu-izap.ge.npif)nyipif(jnum  ,i,k)=npif
                 if(jflu-izap.ge.npif)nyfpif(jnum-1,i,k)=npif
                 jflu=0
              endif
           endif
           if(ta2(i,j,k).eq.1.)jflu=0
        enddo
        if(ta2(i,ny,k).eq.0.)then
           nyfpif(jnum,i,k)=jflu-izap
           if(jflu-izap.lt.npif)jsing=jsing+1
           if(jflu-izap.lt.npif)nyfpif(jnum,i,k)=npif
        endif
     enddo
  enddo
  call MPI_REDUCE(jsing,mpi_aux_i,1,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,code)
  if (nrank==0) print*,'        number of points with potential problem in Y :',mpi_aux_i
  !if (nrank==0) print*,'    step 12'

  !z-pencil
  if(nz.gt.1)then
     call transpose_y_to_z(ta2,ta3)
     nzipif(:,:,:)=npif
     nzfpif(:,:,:)=npif
     ksing=0
     do j=1,zsize(2)
        do i=1,zsize(1)
           knum=0
           kflu=0
           if(ta3(i,j,1).eq.1.)knum=knum+1
           if(ta3(i,j,1).eq.0.)kflu=kflu+1
           do k=2,nz
              if(ta3(i,j,k  ).eq.0.)kflu=kflu+1
              if(ta3(i,j,k-1).eq.0..and.&
                   ta3(i,j,k  ).eq.1.)then
                 knum=knum+1
                 if(knum.eq.1)then
                    nzipif(knum  ,i,j)=kflu-izap
                    if(kflu-izap.lt.npif)ksing=ksing+1
                    if(kflu-izap.ge.npif)nzipif(knum  ,i,j)=npif
                    kflu=0
                 else
                    nzipif(knum  ,i,j)=kflu-izap
                    nzfpif(knum-1,i,j)=kflu-izap
                    if(kflu-izap.lt.npif)ksing=ksing+1
                    if(kflu-izap.ge.npif)nzipif(knum  ,i,j)=npif
                    if(kflu-izap.ge.npif)nzfpif(knum-1,i,j)=npif
                    kflu=0
                 endif
              endif
              if(ta3(i,j,k).eq.1.)kflu=0
           enddo
           if(ta3(i,j,nz).eq.0.)then
              nzfpif(knum,i,j)=kflu-izap
              if(kflu-izap.lt.npif)ksing=ksing+1
              if(kflu-izap.lt.npif)nzfpif(knum,i,j)=npif
           endif
        enddo
     enddo
     call MPI_REDUCE(ksing,mpi_aux_i,1,MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,code)
     if (nrank==0) print*,'        number of points with potential problem in Z :',mpi_aux_i
  endif
  !if (nrank==0) print*,'    step 13'
  !
  return
end subroutine verif_epsi
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine write_geomcomplex(nx,ny,nz,ep1,epm,nobjx,nobjy,nobjz,xi,xf,yi,yf,zi,zf,&
     nxipif,nxfpif,nyipif,nyfpif,nzipif,nzfpif,nobjmax,npif)
  use decomp_2d
  USE decomp_2d_io
  USE complex_geometry, ONLY: iepm
  implicit none
  !
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ep1,epm
  integer                            :: nx,ny,nz,nobjmax
  integer,dimension(xstart(2):xend(2),xstart(3):xend(3)) :: nobjx
  integer,dimension(ystart(1):yend(1),ystart(3):yend(3)) :: nobjy
  integer,dimension(zstart(1):zend(1),zstart(2):zend(2)) :: nobjz
  real(mytype),dimension(nobjmax,xstart(2):xend(2),xstart(3):xend(3)) :: xi,xf
  real(mytype),dimension(nobjmax,ystart(1):yend(1),ystart(3):yend(3)) :: yi,yf
  real(mytype),dimension(nobjmax,zstart(1):zend(1),zstart(2):zend(2)) :: zi,zf
  integer,dimension(0:nobjmax,xstart(2):xend(2),xstart(3):xend(3)) :: nxipif,nxfpif
  integer,dimension(0:nobjmax,ystart(1):yend(1),ystart(3):yend(3)) :: nyipif,nyfpif
  integer,dimension(0:nobjmax,zstart(1):zend(1),zstart(2):zend(2)) :: nzipif,nzfpif
  integer                            :: npif
  integer                            :: i,j,k,count
  !
  if (nrank==0) print *,'Writing geometry'
  call decomp_2d_write_one(1,ep1,'epsilon.dat')
  if (iepm.eq.1) call decomp_2d_write_one(1,epm,'epsilonm.dat')
  !x-pencil
  open(67,file='nobjx.dat',form='formatted',access='direct',recl=13)
  do k=xstart(3),xend(3)
     do j=xstart(2),xend(2)
        count = (k-1)*ny+j
        write(67,'(1I12,A)',rec=count) nobjx(j,k),char(10)
     enddo
  enddo
  close(67)
  !y-pencil
  open(67,file='nobjy.dat',form='formatted',access='direct',recl=13)
  do k=ystart(3),yend(3)
     do i=ystart(1),yend(1)
        count = (k-1)*nx+i
        write(67,'(1I12,A)',rec=count) nobjy(i,k),char(10)
     enddo
  enddo
  close(67)
  !z-pencil
  open(67,file='nobjz.dat',form='formatted',access='direct',recl=13)
  do j=zstart(2),zend(2)
     do i=zstart(1),zend(1)
        count = (j-1)*nx+i
        write(67,'(1I12,A)',rec=count) nobjz(i,j),char(10)
     enddo
  enddo
  close(67)
  !x-pencil
  open(67,file='nxifpif.dat',form='formatted',access='direct',recl=25)
  do k=xstart(3),xend(3)
     do j=xstart(2),xend(2)
        do i=0,nobjmax
           count = (k-1)*ny*(1+nobjmax)+(j-1)*(1+nobjmax)+i+1
           write(67,'(2I12,A)',rec=count) nxipif(i,j,k),nxfpif(i,j,k),char(10)
        enddo
     enddo
  enddo
  close(67)
  !y-pencil
  open(67,file='nyifpif.dat',form='formatted',access='direct',recl=25)
  do k=ystart(3),yend(3)
     do i=ystart(1),yend(1)
        do j=0,nobjmax
           count = (k-1)*nx*(1+nobjmax)+(i-1)*(1+nobjmax)+j+1
           write(67,'(2I12,A)',rec=count) nyipif(j,i,k),nyfpif(j,i,k),char(10)
        enddo
     enddo
  enddo
  close(67)
  !z-pencil
  open(67,file='nzifpif.dat',form='formatted',access='direct',recl=25)
  do j=zstart(2),zend(2)
     do i=zstart(1),zend(1)
        do k=0,nobjmax
           count = (j-1)*nx*(1+nobjmax)+(i-1)*(1+nobjmax)+k+1
           write(67,'(2I12,A)',rec=count) nzipif(k,i,j),nzfpif(k,i,j),char(10)
        enddo
     enddo
  enddo
  close(67)
  !x-pencil
  open(67,file='xixf.dat',form='formatted',access='direct',recl=29)
  do k=xstart(3),xend(3)
     do j=xstart(2),xend(2)
        do i=1,nobjmax
           count = (k-1)*ny*nobjmax+(j-1)*nobjmax+i
           write(67,'(2E14.6,A)',rec=count) xi(i,j,k),xf(i,j,k),char(10)
        enddo
     enddo
  enddo
  close(67)
  !y-pencil
  open(67,file='yiyf.dat',form='formatted',access='direct',recl=29)
  do k=ystart(3),yend(3)
     do i=ystart(1),yend(1)
        do j=1,nobjmax
           count = (k-1)*nx*nobjmax+(i-1)*nobjmax+j
           write(67,'(2E14.6,A)',rec=count) yi(j,i,k),yf(j,i,k),char(10)
        enddo
     enddo
  enddo
  close(67)
  !z-pencil
  open(67,file='zizf.dat',form='formatted',access='direct',recl=29)
  do j=zstart(2),zend(2)
     do i=zstart(1),zend(1)
        do k=1,nobjmax
           count = (j-1)*nx*nobjmax+(i-1)*nobjmax+k
           write(67,'(2E14.6,A)',rec=count) zi(k,i,j),zf(k,i,j),char(10)
        enddo
     enddo
  enddo
  close(67)
  !
  return
end subroutine write_geomcomplex
subroutine read_geomcomplex()
  !
  USE complex_geometry
  USE decomp_2d
  USE MPI
  !
  implicit none
  !
  integer :: i,j,k
  integer :: code
  !
  if(nrank.eq.0)then
     open(11,file='nobjx.dat'  ,form='formatted', status='old')
     do k=1,nz
        do j=1,ny
           read(11,*)nobjx(j,k)
        enddo
     enddo
     close(11)
  endif
  call MPI_BCAST(nobjx,ny*nz,MPI_INTEGER,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(12,file='nobjy.dat'  ,form='formatted', status='old')
     do k=1,nz
        do i=1,nx
           read(12,*)nobjy(i,k)
        enddo
     enddo
     close(12)
  endif
  call MPI_BCAST(nobjy,nx*nz,MPI_INTEGER,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(13,file='nobjz.dat'  ,form='formatted', status='old')
     do j=1,ny
        do i=1,nx
           read(13,*)nobjz(i,j)
        enddo
     enddo
     close(13)
  endif
  call MPI_BCAST(nobjz,nx*ny,MPI_INTEGER,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(21,file='nxifpif.dat',form='formatted', status='old')
     do k=1,nz
        do j=1,ny
           do i=0,nobjmax
              read(21,*)nxipif(i,j,k),nxfpif(i,j,k)
           enddo
        enddo
     enddo
     close(21)
  endif
  call MPI_BCAST(nxipif,ny*nz*(nobjmax+1),MPI_INTEGER,0,MPI_COMM_WORLD,code)
  call MPI_BCAST(nxfpif,ny*nz*(nobjmax+1),MPI_INTEGER,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(22,file='nyifpif.dat',form='formatted', status='old')
     do k=1,nz
        do i=1,nx
           do j=0,nobjmax
              read(22,*)nyipif(j,i,k),nyfpif(j,i,k)
           enddo
        enddo
     enddo
     close(22)
  endif
  call MPI_BCAST(nyipif,nx*nz*(nobjmax+1),MPI_INTEGER,0,MPI_COMM_WORLD,code)
  call MPI_BCAST(nyfpif,nx*nz*(nobjmax+1),MPI_INTEGER,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(23,file='nzifpif.dat',form='formatted', status='old')
     do j=1,ny
        do i=1,nx
           do k=0,nobjmax
              read(23,*)nzipif(k,i,j),nzfpif(k,i,j)
           enddo
        enddo
     enddo
     close(23)
  endif
  call MPI_BCAST(nzipif,nx*ny*(nobjmax+1),MPI_INTEGER,0,MPI_COMM_WORLD,code)
  call MPI_BCAST(nzfpif,nx*ny*(nobjmax+1),MPI_INTEGER,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(31,file='xixf.dat'   ,form='formatted', status='old')
     do k=1,nz
        do j=1,ny
           do i=1,nobjmax
              read(31,*)xi(i,j,k),xf(i,j,k)
           enddo
        enddo
     enddo
     close(31)
  endif
  call MPI_BCAST(xi,ny*nz*nobjmax,MPI_REAL,0,MPI_COMM_WORLD,code)
  call MPI_BCAST(xf,ny*nz*nobjmax,MPI_REAL,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(32,file='yiyf.dat'   ,form='formatted', status='old')
     do k=1,nz
        do i=1,nx
           do j=1,nobjmax
              read(32,*)yi(j,i,k),yf(j,i,k)
           enddo
        enddo
     enddo
     close(32)
  endif
  call MPI_BCAST(yi,nx*nz*nobjmax,MPI_REAL,0,MPI_COMM_WORLD,code)
  call MPI_BCAST(yf,nx*nz*nobjmax,MPI_REAL,0,MPI_COMM_WORLD,code)
  if(nrank.eq.0)then
     open(33,file='zizf.dat'   ,form='formatted', status='old')
     do j=1,ny
        do i=1,nx
           do k=1,nobjmax
              read(33,*)zi(k,i,j),zf(k,i,j)
           enddo
        enddo
     enddo
     close(33)
  endif
  call MPI_BCAST(zi,nx*ny*nobjmax,MPI_REAL,0,MPI_COMM_WORLD,code)
  call MPI_BCAST(zf,nx*ny*nobjmax,MPI_REAL,0,MPI_COMM_WORLD,code)
  !
  return
end subroutine read_geomcomplex
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine lagpolx(u)
  !
  USE param
  USE complex_geometry
  USE decomp_2d
  USE variables
  !
  implicit none
  !
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: u
  integer                                            :: i,j,k
  real(mytype)                                       :: x,y,z
  integer                                            :: ix              != position du point "zappé"
  integer                                            :: ipif,ipol,nxpif
  integer                                            :: ipoli,ipolf     != positions Initiales et Finales du POLynôme considéré
  real(mytype)                                       :: xpol,ypol,dypol !|variables concernant les polynômes
  real(mytype),dimension(10)                         :: xa,ya           !|de Lagrange. A mettre impérativement en 
  integer                                            :: ia,na           !|double précision
  !
  !====DEBUG
  if (new_rec.eq.1) return
  !
  do k=1,xsize(3)
     do j=1,xsize(2)
        if(nobjx(j,k).ne.0)then
           ia=0
           do i=1,nobjx(j,k)          !boucle sur le nombre d'objets par (j,k)
              !1ère frontière
              nxpif=npif
              ia=ia+1
              xa(ia)=xi(i,j,k)
              ya(ia)=0.
              if(xi(i,j,k).gt.0.)then!objet immergé
                 ix=xi(i,j,k)/dx+1
                 ipoli=ix+1
                 if(nxipif(i,j,k).lt.npif)nxpif=nxipif(i,j,k)
                 do ipif=1,nxpif
                    ia=ia+1
                    if(izap.eq.1)then!zapping
                       xa(ia)=(ix-1)*dx-ipif*dx
                       ya(ia)=u(ix-ipif,j,k)
                    else             !no zapping
                       xa(ia)=(ix-1)*dx-(ipif-1)*dx
                       ya(ia)=u(ix-ipif+1,j,k)
                    endif
                 enddo
              else                   !objet semi-immergé
                 ipoli=1
              endif
              !2ème frontière
              nxpif=npif
              ia=ia+1
              xa(ia)=xf(i,j,k)
              ya(ia)=0.
              if(xf(i,j,k).lt.xlx)then!objet immergé
                 ix=(xf(i,j,k)+dx)/dx+1
                 ipolf=ix-1
                 if(nxfpif(i,j,k).lt.npif)nxpif=nxfpif(i,j,k)
                 do ipif=1,nxpif
                    ia=ia+1
                    if(izap.eq.1)then!zapping
                       xa(ia)=(ix-1)*dx+ipif*dx
                       ya(ia)=u(ix+ipif,j,k)
                    else             !no zapping
                       xa(ia)=(ix-1)*dx+(ipif-1)*dx
                       ya(ia)=u(ix+ipif-1,j,k)
                    endif
                 enddo
              else                   !objet semi-immergé
                 ipolf=nx
              endif
              !calcul du polynôme
              na=ia
              do ipol=ipoli,ipolf
                 xpol=dx*(ipol-1)
                 call polint(xa,ya,na,xpol,ypol,dypol)
                 u(ipol,j,k)=ypol
              enddo
              ia=0
           enddo
        endif
     enddo
  enddo
  !
  return
end subroutine lagpolx
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine lagpoly(u)
  !
  USE param
  USE complex_geometry
  USE decomp_2d
  USE variables
  USE pipe, only: lagpoly2
  !
  implicit none
  !
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: u
  integer                                            :: i,j,k
  real(mytype)                                       :: x,y,z
  integer                                            :: jy              != position du point "zappé"
  integer                                            :: jpif,jpol,nypif
  integer                                            :: jpoli,jpolf     != positions Initiales et Finales du POLynôme considéré
  real(mytype)                                       :: xpol,ypol,dypol !|variables concernant les polynômes
  real(mytype),dimension(10)                         :: xa,ya           !|de Lagrange. A mettre impérativement en 
  integer                                            :: ia,na           !|double précision
  !
  !====DEBUG
  if (new_rec.eq.1)then !New reconstruction through periodicity 
      call lagpoly2(u)
      return
  endif
  !
  do k=1,ysize(3)
     do i=1,ysize(1)
        if(nobjy(i,k).ne.0)then
           ia=0
           do j=1,nobjy(i,k)          !boucle sur le nombre d'objets par (j,k)
              !1ère frontière
              nypif=npif
              ia=ia+1
              xa(ia)=yi(j,i,k)
              ya(ia)=0.
              if(yi(j,i,k).gt.0.)then!objet immergé
                 jy=1!jy=yi(j,i,k)/dy+1
                 do while(yp(jy).lt.yi(j,i,k))
                    jy=jy+1
                 enddo
                 jy=jy-1
                 jpoli=jy+1
                 if(nyipif(j,i,k).lt.npif)nypif=nyipif(j,i,k)
                 do jpif=1,nypif
                    ia=ia+1
                    if(izap.eq.1)then!zapping
                       xa(ia)=yp(jy-jpif)!(jy-1)*dy-jpif*dy
                       ya(ia)=u(i,jy-jpif,k)
                    else             !no zapping
                       xa(ia)=yp(jy-jpif+1)!(jy-1)*dy-(jpif-1)*dy
                       ya(ia)=u(i,jy-jpif+1,k)
                    endif
                 enddo
              else                   !objet semi-immergé
                 jpoli=1
              endif
              !2ème frontière
              nypif=npif
              ia=ia+1
              xa(ia)=yf(j,i,k)
              ya(ia)=0.
              if(yf(j,i,k).lt.yly)then!objet immergé
                 jy=1!jy=(yf(j,i,k)+dy)/dy+1
                 do while(yp(jy).lt.yf(j,i,k))  !there was a bug here yi<-->yf
                    jy=jy+1
                 enddo
                 jpolf=jy-1
                 if(nyfpif(j,i,k).lt.npif)nypif=nyfpif(j,i,k)
                 do jpif=1,nypif
                    ia=ia+1
                    if(izap.eq.1)then!zapping
                       xa(ia)=yp(jy+jpif)!(jy-1)*dy+jpif*dy
                       ya(ia)=u(i,jy+jpif,k)
                    else             !no zapping
                       xa(ia)=yp(jy+jpif-1)!(jy-1)*dy+(jpif-1)*dy
                       ya(ia)=u(i,jy+jpif-1,k)
                    endif
                 enddo
              else                   !objet semi-immergé
                 jpolf=ny
              endif
              !calcul du polynôme
              na=ia
              do jpol=jpoli,jpolf
                 xpol=yp(jpol)!dy*(jpol-1)
                 call polint(xa,ya,na,xpol,ypol,dypol)
                 u(i,jpol,k)=ypol
              enddo
              ia=0
           enddo
        endif
     enddo
  enddo
  !
  return
end subroutine lagpoly
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine lagpolz(u)
  !
  USE param
  USE complex_geometry
  USE decomp_2d
  USE variables
  USE pipe, only: lagpolz2
  !
  implicit none
  !
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: u
  integer                                            :: i,j,k
  real(mytype)                                       :: x,y,z
  integer                                            :: kz              != position du point "zappé"
  integer                                            :: kpif,kpol,nzpif
  integer                                            :: kpoli,kpolf     != positions Initiales et Finales du POLynôme considéré
  real(mytype)                                       :: xpol,ypol,dypol !|variables concernant les polynômes
  real(mytype),dimension(10)                         :: xa,ya           !|de Lagrange. A mettre imérativement en 
  integer                                            :: ia,na           !|double précision
  !
  !====DEBUG
  if (new_rec.eq.1)then !New reconstruction through periodicity 
      call lagpolz2(u)
      return
  endif
  !
  do j=1,zsize(2)
     do i=1,zsize(1)
        if(nobjz(i,j).ne.0)then
           ia=0
           do k=1,nobjz(i,j)          !boucle sur le nombre d'objets par couple (i,j)
              !1ère frontière
              nzpif=npif
              ia=ia+1
              xa(ia)=zi(k,i,j)
              ya(ia)=0.
              if(zi(k,i,j).gt.0.)then!objet immergé
                 kz=zi(k,i,j)/dz+1
                 kpoli=kz+1
                 if(nzipif(k,i,j).lt.npif)nzpif=nzipif(k,i,j)
                 do kpif=1,nzpif
                    ia=ia+1
                    if(izap.eq.1)then!zapping
                       xa(ia)=(kz-1)*dz-kpif*dz
                       ya(ia)=u(i,j,kz-kpif)
                    else             !no zapping
                       xa(ia)=(kz-1)*dz-(kpif-1)*dz
                       ya(ia)=u(i,j,kz-kpif+1)
                    endif
                 enddo
              else                   !objet semi-immergé
                 kpoli=1
              endif
              !2ème frontière
              nzpif=npif
              ia=ia+1
              xa(ia)=zf(k,i,j)
              ya(ia)=0.
              if(zf(k,i,j).lt.zlz)then!objet immergé
                 kz=(zf(k,i,j)+dz)/dz+1
                 kpolf=kz-1
                 if(nzfpif(k,i,j).lt.npif)nzpif=nzfpif(k,i,j)
                 do kpif=1,nzpif
                    ia=ia+1
                    if(izap.eq.1)then!zapping
                       xa(ia)=(kz-1)*dz+kpif*dz
                       ya(ia)=u(i,j,kz+kpif)
                    else             !no zapping
                       xa(ia)=(kz-1)*dz+(kpif-1)*dz
                       ya(ia)=u(i,j,kz+kpif-1)
                    endif
                 enddo
              else                   !objet semi-immergé
                 kpolf=nz
              endif
              !calcul du polynôme
              na=ia
              do kpol=kpoli,kpolf
                 xpol=dz*(kpol-1)
                 call polint(xa,ya,na,xpol,ypol,dypol)
                 u(i,j,kpol)=ypol
              enddo
              ia=0
           enddo
        endif
     enddo
  enddo
  !
  return
end subroutine lagpolz
!
!
!***************************************************************************
!***************************************************************************
!***************************************************************************
!
subroutine polint(xa,ya,n,x,y,dy)
  !
  USE decomp_2d
  !
  implicit none
  !
  integer,parameter            :: nmax=30
  integer                      :: n,i,m,ns
  real(mytype)                 :: dy,x,y,den,dif,dift,ho,hp,w
  real(mytype),dimension(nmax) :: c,d
  real(mytype),dimension(n)    :: xa,ya
  ns=1
  dif=abs(x-xa(1))
  do i=1,n
     dift=abs(x-xa(i))
     if(dift.lt.dif)then
        ns=i
        dif=dift
     endif
     c(i)=ya(i)
     d(i)=ya(i)
  enddo
  y=ya(ns)
  ns=ns-1
  do m=1,n-1
     do i=1,n-m
        ho=xa(i)-x
        hp=xa(i+m)-x
        w=c(i+1)-d(i)
        den=ho-hp
        !         if(den.eq.0)read(*,*)
        den=w/den
        d(i)=hp*den
        c(i)=ho*den
     enddo
     if (2*ns.lt.n-m)then
        dy=c(ns+1)
     else
        dy=d(ns)
        ns=ns-1
     endif
     y=y+dy
  enddo
  return
end subroutine polint

