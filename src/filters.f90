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

subroutine filter(af)
  USE param
  USE parfiX
  USE parfiY
  USE parfiZ
  USE variables
  USE var
  !=================================================
  ! Discrete low-pass filter according to 
  !=================================================	
  implicit none
  real(mytype),intent(in) :: af 

#ifdef DEBG
  if (nrank .eq. 0) print *,'# filter calculation start'
#endif

  ! Filter functions
  if (nclx1.eq.0.and.nclxn.eq.0) filx => filx_00
  if (nclx1.eq.1.and.nclxn.eq.1) filx => filx_11
  if (nclx1.eq.1.and.nclxn.eq.2) filx => filx_12
  if (nclx1.eq.2.and.nclxn.eq.1) filx => filx_21
  if (nclx1.eq.2.and.nclxn.eq.2) filx => filx_22
  !
  if (ncly1.eq.0.and.nclyn.eq.0) fily => fily_00
  if (ncly1.eq.1.and.nclyn.eq.1) fily => fily_11
  if (ncly1.eq.1.and.nclyn.eq.2) fily => fily_12
  if (ncly1.eq.2.and.nclyn.eq.1) fily => fily_21
  if (ncly1.eq.2.and.nclyn.eq.2) fily => fily_22
  !
  if (nclz1.eq.0.and.nclzn.eq.0) filz => filz_00
  if (nclz1.eq.1.and.nclzn.eq.1) filz => filz_11
  if (nclz1.eq.1.and.nclzn.eq.2) filz => filz_12
  if (nclz1.eq.2.and.nclzn.eq.1) filz => filz_21
  if (nclz1.eq.2.and.nclzn.eq.2) filz => filz_22

  ! Set coefficients for x-direction filter
  call set_filter_coefficients(af,fial1x,fia1x,fib1x,fic1x,fid1x,fial2x,fia2x,fib2x,fic2x,fid2x,fial3x,fia3x,fib3x,fic3x,fid3x,fie3x,fif3x,&
       fialnx,fianx,fibnx,ficnx,fidnx,fialmx,fiamx,fibmx,ficmx,fidmx,fialpx,fiapx,fibpx,ficpx,fidpx,fiepx,fifpx,&
       fialix,fiaix,fibix,ficix,fidix,fiffx,fifsx,fifwx,fiffxp,fifsxp,fifwxp,nx,nclx1,nclxn)
  ! Set coefficients for y-direction filter
  call set_filter_coefficients(af,fial1y,fia1y,fib1y,fic1y,fid1y,fial2y,fia2y,fib2y,fic2y,fid2y,fial3y,fia3y,fib3y,fic3y,fid3y,fie3y,fif3y,&
       fialny,fiany,fibny,ficny,fidny,fialmy,fiamy,fibmy,ficmy,fidmy,fialpy,fiapy,fibpy,ficpy,fidpy,fiepy,fifpy,&
       fialjy,fiajy,fibjy,ficjy,fidjy,fiffy,fifsy,fifwy,fiffyp,fifsyp,fifwyp,ny,ncly1,nclyn)
  ! Set coefficients for z-direction filter
  call set_filter_coefficients(af,fial1z,fia1z,fib1z,fic1z,fid1z,fial2z,fia2z,fib2z,fic2z,fid2z,fial3z,fia3z,fib3z,fic3z,fid3z,fie3z,fif3z,&
       fialnz,fianz,fibnz,ficnz,fidnz,fialmz,fiamz,fibmz,ficmz,fidmz,fialpz,fiapz,fibpz,ficpz,fidpz,fiepz,fifpz,&
       fialkz,fiakz,fibkz,fickz,fidkz,fiffz,fifsz,fifwz,fiffzp,fifszp,fifwzp,nz,nclz1,nclzn)
#ifdef DEBG 
  if (nrank .eq. 0) print *,'# filter calculation end'
#endif

  return 

end subroutine filter


subroutine set_filter_coefficients(af,alfa1,a1,b1,c1,d1,alfa2,a2,b2,c2,d2,alfa3,a3,b3,c3,d3,e3,f3,&
     alfan,an,bn,cn,dn,alfam,am,bm,cm,dm,alfap,ap,bp,cp,dp,ep,fp,&
     alfai,ai,bi,ci,di,ff,fs,fw,ffp,fsp,fwp,n,ncl1,ncln)

  use decomp_2d, only : mytype, nrank
  use param

  implicit none

  real(mytype),intent(in) :: af
  integer,intent(in) :: n,ncl1,ncln
  real(mytype),dimension(n),intent(out) :: ff,fs,fw,ffp,fsp,fwp
  real(mytype),intent(out) :: alfa1,a1,b1,c1,d1,alfa2,a2,b2,c2,d2,alfa3,a3,b3,c3,d3,e3,f3,&
       alfan,an,bn,cn,dn,alfam,am,bm,cm,dm,alfap,ap,bp,cp,dp,ep,fp,&
       alfai,ai,bi,ci,di
  integer :: i
  real(mytype),dimension(n) :: fb,fc

  ! Set the coefficient for the discrete filter following 
  ! the tridiagonal filtering of Motheau and Abraham, JCP 2016 
  ! Filter should be -0.5<filax<0.5

  ! General Case (entire points)
  ! alpha*fhat(i-1)+fhat(i)+alpha*fhat(i+1)=af(i)+b/2*[f(i+1)+f(i-1)] + ...

  ! Coefficients are calculated according to the report of Gaitonde & Visbal, 1998,
  ! "High-order schemes for Navier-Stokes equations: Algorithm and implementation into FDL3DI"


  alfai=af                                       ! alpha_f
  !Interior points
  ai=(eleven + ten*af)/sixteen                   ! a
  bi=half*(fifteen +thirtyfour*af)/thirtytwo     ! b/2 
  ci=half*(-three + six*af)/sixteen              ! c/2
  di=half*(one - two*af)/thirtytwo               ! d/2
  ! Explicit third/fifth-order filters near the boundaries!
  !Boundary point 1 (no-filtering)
  alfa1=zero
  a1=one                           ! a1=7./8.+af/8.! a1/2
  b1=zero                          ! b1=3./8.+5.*af/8.  
  c1=zero                          ! c1=-3./8.+3./8.*af 
  d1=zero                          ! d1=1./8.-1./8.*af 
  !Boundary point 2 (Third order)
  alfa2=af
  a2=one/eight+three/four*af            ! a2
  b2=five/eight+three/four*af           ! b2
  c2=three/eight+af/four                ! c2
  d2=-one/eight+af/four                 ! d2
  !Boundary point 3 (Fifth order)
  alfa3=af
  a3= -one/thirtytwo+af/sixteen         ! a3
  b3= five/thirtytwo+eleven/sixteen*af  ! b3
  c3= eleven/sixteen+five*af/eight      ! c3
  d3= five/sixteen+three*af/eight       ! d3
  e3=-five/thirtytwo+five*af/sixteen    ! e3
  f3= one/thirtytwo-af/sixteen          ! f3
  !Boundary point n (no-filtering)
  alfan=zero
  an=one                                !an = 7./8.+af/8.! a1/2
  bn=zero                               !bn = 3./8.+5.*af/8.
  cn=zero                               !cn =-3./8.+3./8.*af    
  dn=zero                               !dn = 1./8.-1./8.*af    
  !Boundary point 2 (Third order)
  alfam=af
  am=one/eight+three/four*af            ! am
  bm=five/eight+three/four*af           ! bm
  cm=three/eight+af/four                ! cm
  dm=-one/eight+af/four                 ! dm
  !Boundary point 3 (Fifth order)
  alfap=af
  ap=-one/thirtytwo+af/sixteen          ! ap
  bp= five/thirtytwo+eleven/sixteen*af  ! bp
  cp= eleven/sixteen+five*af/eight      ! cp
  dp= five/sixteen+three*af/eight       ! dp
  ep=-five/thirtytwo+five*af/sixteen    ! ep
  fp= one/thirtytwo-af/sixteen          ! fp

  ff=zero;fs=zero;fw=zero;ffp=zero;fsp=zero;fwp=zero
  fb=zero;fc=zero

  if     (ncl1.eq.0) then !Periodic
     ff(1)   =alfai
     ff(2)   =alfai
     fc(1)   =two
     fc(2)   =one
     fb(1)   =alfai
     fb(2)   =alfai
  elseif (ncl1.eq.1) then !Free-slip
     ff(1)   =alfai+alfai
     ff(2)   =alfai
     fc(1)   =one
     fc(2)   =one
     fb(1)   =alfai 
     fb(2)   =alfai
  elseif (ncl1.eq.2) then !Dirichlet
     ff(1)   =alfa1
     ff(2)   =alfa2
     fc(1)   =one
     fc(2)   =one
     fb(1)   =alfa2 
     fb(2)   =alfai
  endif
  if (ncln.eq.0) then !Periodic
     ff(n-2)=alfai
     ff(n-1)=alfai
     ff(n)  =zero
     fc(n-2)=one
     fc(n-1)=one
     fc(n  )=one+alfai*alfai
     fb(n-2)=alfai
     fb(n-1)=alfai
     fb(n  )=zero
  elseif (ncln.eq.1) then !Free-slip
     ff(n-2)=alfai
     ff(n-1)=alfai
     ff(n)  =zero
     fc(n-2)=one
     fc(n-1)=one
     fc(n  )=one
     fb(n-2)=alfai
     fb(n-1)=alfai+alfai
     fb(n  )=zero
  elseif (ncln.eq.2) then !Dirichlet
     ff(n-2)=alfai
     ff(n-1)=alfam
     ff(n)  =zero
     fc(n-2)=one
     fc(n-1)=one
     fc(n  )=one
     fb(n-2)=alfam
     fb(n-1)=alfan
     fb(n  )=zero
  endif
  do i=3,n-3
     ff(i)=alfai
     fc(i)=one
     fb(i)=alfai
  enddo

  do i=1,n
     ffp(i)=ff(i)
  enddo

  call prepare (fb,fc,ffp ,fsp ,fwp ,n)

  if (ncl1.eq.1) then
     ff(1)=zero
  endif
  if (ncln.eq.1) then
     fb(n-1)=zero
  endif

  call prepare (fb,fc,ff,fs,fw,n)

  return

end subroutine set_filter_coefficients

!*********************************************************************
!
subroutine viscous_filter(var1,ifilt,ilag)
!
!*********************************************************************
USE decomp_2d
USE param
USE variables
USE viscfiX 
USE viscfiY 
USE viscfiZ 
USE var, ONLY : ta1,tb1,ta2,tb2,ta3,tb3,di1,di2,di3
USE var, ONLY : phi1,phis1,ep1
USE pipe

    implicit none
    real(mytype),dimension(xsize(1),xsize(2),xsize(3))  :: var1
    integer                                             :: ifilt
    integer                                             :: ilag !0: with lagpol
                                                                !1: with nbclagpol/chtlagpol
    integer                                             :: icht,is
    integer                                             :: i,j,k

    tb1(:,:,:) = var1(:,:,:)

    if (ifilt.eq.0) then   ! Velocity filtering

        !X PENCIL
        call filxx(ta1,tb1,di1,fvalx,fvaix,fvbix,fvcix,fvdix,fveix,&
                   sx,vfx,vsx,vwx,xsize(1),xsize(2),xsize(3),0)
        call transpose_x_to_y(ta1,tb2)
        !Y PENCIL
        call filyy(ta2,tb2,di2,fvaly,fvajy,fvbjy,fvcjy,fvdjy,fvejy,&
                   sy,vfy,vsy,vwy,ysize(1),ysize(2),ysize(3),0)
        call transpose_y_to_z(ta2,tb3)
        !Z PENCIL
        call filzz(ta3,tb3,di3,fvalz,fvakz,fvbkz,fvckz,fvdkz,fvekz,&
                   sz,vfz,vsz,vwz,zsize(1),zsize(2),zsize(3),0)
        !BACK TO X Pencil
        call transpose_z_to_y(ta3,ta2)
        call transpose_y_to_x(ta2,var1)

    !elseif (ifilt.ne.0) then  ! Scalar filtering
    elseif (ifilt.gt.0) then  ! Scalar filtering

        !To avoid Dirichlet reconstruction
        if (itype.eq.itype_pipe.and.itbc(ifilt).ne.1.and.ilag.eq.1) then 
            iibm=0
            !
            !Predict phiw^(n+1) (fluid)
            if (itbc(ifilt).eq.2) then !Treatment IF boundary condition
                call phiw_if(tb1,ep1,ifilt,0)
            elseif (itbc(ifilt).eq.3) then !Treatment CHT boundary condition (fluid)
                icht=icht+1
                call phiw_cht(tb1,phis1(:,:,:,icht),ep1,ifilt,icht,1,0)
            endif
        endif

        !X PENCIL
        call filxxS(ta1,tb1,di1,fscalx(ifilt),fscaix(ifilt),fscbix(ifilt),fsccix(ifilt),&
                   fscdix(ifilt),fsceix(ifilt),sx,vscfx(:,ifilt),vscsx(:,ifilt),vscwx(:,ifilt),&
                   xsize(1),xsize(2),xsize(3),0)
        call transpose_x_to_y(ta1,tb2)
        !Y PENCIL
        if (itype.eq.itype_pipe.and.itbc(ifilt).ne.1.and.ilag.eq.1) then !Reconstruction IF/CHT 
            !Imposed Flux (IF)
            if (itbc(ifilt).eq.2) call nbclagpoly(tb2,ifilt)
            !Conjugate Heat Tansfer (CHT)
            if (itbc(ifilt).eq.3) call chtlagpoly(tb2,ifilt)
        endif
        call filyyS(ta2,tb2,di2,fscaly(ifilt),fscajy(ifilt),fscbjy(ifilt),fsccjy(ifilt),&
                   fscdjy(ifilt),fscejy(ifilt),sy,vscfy(:,ifilt),vscsy(:,ifilt),vscwy(:,ifilt),&
                   ysize(1),ysize(2),ysize(3),0)
        call transpose_y_to_z(ta2,tb3)
        !Z PENCIL
        if (itype.eq.itype_pipe.and.itbc(ifilt).ne.1.and.ilag.eq.1) then 
            !Imposed Flux (IF)
            if (itbc(ifilt).eq.2) call nbclagpolz(tb3,ifilt)
            !Conjugate Heat Tansfer (CHT)
            if (itbc(ifilt).eq.3) call chtlagpolz(tb3,ifilt)
        endif
        call filzzS(ta3,tb3,di3,fscalz(ifilt),fscakz(ifilt),fscbkz(ifilt),fscckz(ifilt),&
                   fscdkz(ifilt),fscekz(ifilt),sz,vscfz(:,ifilt),vscsz(:,ifilt),vscwz(:,ifilt),&
                   zsize(1),zsize(2),zsize(3),0)
        !To restore iibm value
        if (itype.eq.itype_pipe.and.itbc(ifilt).ne.1.and.ilag.eq.1) then 
            iibm=2
        endif
        !BACK TO X Pencil
        call transpose_z_to_y(ta3,ta2)
        call transpose_y_to_x(ta2,var1)

    elseif (ifilt.lt.0) then  ! Scalar solid filtering

        icht=0
        do is=1,numscalar
            if (itbc(is).eq.3) then
                icht=icht+1
                if (is.eq.-ifilt) exit
            endif
        enddo

        iibm=0
        !Predict phiws^(n+1)
        call phiw_cht(phi1(:,:,:,-ifilt),tb1,ep1,-ifilt,icht,2,0)

        !X PENCIL
        call filxxS(ta1,tb1,di1,fscalx_s(-ifilt),fscaix_s(-ifilt),fscbix_s(-ifilt),fsccix_s(-ifilt),&
                   fscdix_s(-ifilt),fsceix_s(-ifilt),sx,vscfx_s(:,-ifilt),vscsx_s(:,-ifilt),vscwx_s(:,-ifilt),&
                   xsize(1),xsize(2),xsize(3),0)
        call transpose_x_to_y(ta1,tb2)
        !Y PENCIL
        call chtlagpoly_s(tb2,icht)
        call filyyS(ta2,tb2,di2,fscaly_s(-ifilt),fscajy_s(-ifilt),fscbjy_s(-ifilt),fsccjy_s(-ifilt),&
                   fscdjy_s(-ifilt),fscejy_s(-ifilt),sy,vscfy_s(:,-ifilt),vscsy_s(:,-ifilt),vscwy_s(:,-ifilt),&
                   ysize(1),ysize(2),ysize(3),0)
        call transpose_y_to_z(ta2,tb3)
        !Z PENCIL
        call chtlagpolz_s(tb3,icht)
        call filzzS(ta3,tb3,di3,fscalz_s(-ifilt),fscakz_s(-ifilt),fscbkz_s(-ifilt),fscckz_s(-ifilt),&
                   fscdkz_s(-ifilt),fscekz_s(-ifilt),sz,vscfz_s(:,-ifilt),vscsz_s(:,-ifilt),vscwz_s(:,-ifilt),&
                   zsize(1),zsize(2),zsize(3),0)
        iibm=2
        !BACK TO X Pencil
        call transpose_z_to_y(ta3,ta2)
        call transpose_y_to_x(ta2,var1)

    endif

end subroutine viscous_filter
!*********************************************************************

subroutine filx_00(tx,ux,rx,fisx,fiffx,fifsx,fifwx,nx,ny,nz,npaire) 

  USE param  
  USE parfiX 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tx,ux,rx 
  real(mytype), dimension(ny,nz) :: fisx
  real(mytype), dimension(nx) :: fiffx,fifsx,fifwx

  if(iibm.eq.2) call lagpolx(ux)

  do k=1,nz 
     do j=1,ny 
        tx(1,j,k)=fiaix*ux(1,j,k)+fibix*(ux(2,j,k)+ux(nx,j,k))& 
             +ficix*(ux(3,j,k)+ux(nx-1,j,k))&
             +fidix*(ux(4,j,k)+ux(nx-2,j,k)) 
        rx(1,j,k)=-1.
        tx(2,j,k)=fiaix*ux(2,j,k)+fibix*(ux(3,j,k)+ux(1,j,k))&
             +ficix*(ux(4,j,k)+ux(nx,j,k))& 
             +fidix*(ux(5,j,k)+ux(nx-1,j,k)) 
        rx(2,j,k)=0. 
        tx(3,j,k)=fiaix*ux(3,j,k)+fibix*(ux(4,j,k)+ux(2,j,k))& 
             +ficix*(ux(5,j,k)+ux(1,j,k))& 
             +fidix*(ux(6,j,k)+ux(nx,j,k)) 
        rx(3,j,k)=0. 
        do i=4,nx-3
           tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           rx(i,j,k)=0. 
        enddo
        tx(nx-2,j,k)=fiaix*ux(nx-2,j,k)+fibix*(ux(nx-3,j,k)+ux(nx-1,j,k))&
             +ficix*(ux(nx-4,j,k)+ux(nx,j,k))& 
             +fidix*(ux(nx-5,j,k)+ux(1,j,k)) 
        rx(nx-2,j,k)=0. 
        tx(nx-1,j,k)=fiaix*ux(nx-1,j,k)+fibix*(ux(nx-2,j,k)+ux(nx,j,k))&
             +ficix*(ux(nx-3,j,k)+ux(1,j,k))& 
             +fidix*(ux(nx-4,j,k)+ux(2,j,k)) 
        rx(nx-1,j,k)=0. 
        tx(nx,j,k)=fiaix*ux(nx,j,k)+fibix*(ux(nx-1,j,k)+ux(1,j,k))&
             +ficix*(ux(nx-2,j,k)+ux(2,j,k))& 
             +fidix*(ux(nx-3,j,k)+ux(3,j,k)) 
        rx(nx,j,k)=fialix           
        do i=2, nx
           tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           rx(i,j,k)=rx(i,j,k)-rx(i-1,j,k)*fifsx(i) 
        enddo
        tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
        rx(nx,j,k)=rx(nx,j,k)*fifwx(nx) 
        do i=nx-1,1,-1
           tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           rx(i,j,k)=(rx(i,j,k)-fiffx(i)*rx(i+1,j,k))*fifwx(i) 
        enddo
        fisx(j,k)=(tx(1,j,k)-fialix*tx(nx,j,k))&
             /(1.+rx(1,j,k)-fialix*rx(nx,j,k)) 
        do i=1,nx 
           tx(i,j,k)=tx(i,j,k)-fisx(j,k)*rx(i,j,k) 
        enddo
     enddo
  enddo

  return  

end subroutine filx_00

subroutine filx_11(tx,ux,rx,fisx,fiffx,fifsx,fifwx,nx,ny,nz,npaire) 

  USE param  
  USE parfiX 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tx,ux,rx 
  real(mytype), dimension(ny,nz) :: fisx
  real(mytype), dimension(nx) :: fiffx,fifsx,fifwx

  if(iibm.eq.2) call lagpolx(ux)

  if (npaire==1) then 
     do k=1,nz 
        do j=1,ny 
           tx(1,j,k)=fiaix*ux(1,j,k)+fibix*(ux(2,j,k)+ux(2,j,k))&
                +ficix*(ux(3,j,k)+ux(3,j,k))&
                +fidix*(ux(4,j,k)+ux(4,j,k))
           tx(2,j,k)=fiaix*ux(2,j,k)+fibix*(ux(3,j,k)+ux(1,j,k))& 
                +ficix*(ux(4,j,k)+ux(2,j,k))&
                +fidix*(ux(5,j,k)+ux(3,j,k)) 
           tx(3,j,k)=fiaix*ux(3,j,k)+fibix*(ux(4,j,k)+ux(2,j,k))& 
                +ficix*(ux(5,j,k)+ux(1,j,k))&
                +fidix*(ux(6,j,k)+ux(2,j,k)) 
           do i=4,nx-3 
              tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                   +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                   +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           enddo
           tx(nx,j,k)  =fiaix*ux(nx,j,k)  +fibix*(ux(nx-1,j,k)+ux(nx-1,j,k))&
                +ficix*(ux(nx-2,j,k)+ux(nx-2,j,k))&
                +fidix*(ux(nx-3,j,k)+ux(nx-3,j,k))
           tx(nx-1,j,k)=fiaix*ux(nx-1,j,k)+fibix*(ux(  nx,j,k)+ux(nx-2,j,k))& 
                +ficix*(ux(nx-1,j,k)+ux(nx-3,j,k))&
                +fidix*(ux(nx-2,j,k)+ux(nx-4,j,k)) 
           tx(nx-2,j,k)=fiaix*ux(nx-2,j,k)+fibix*(ux(nx-1,j,k)+ux(nx-3,j,k))& 
                +ficix*(ux(  nx,j,k)+ux(nx-4,j,k))&
                +fidix*(ux(nx-1,j,k)+ux(nx-5,j,k)) 
           do i=2,nx 
              tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           enddo
           tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
           do i=nx-1,1,-1  
              tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           enddo
        enddo
     enddo
  endif

  if (npaire==0) then 
     do k=1,nz 
        do j=1,ny 
           tx(1,j,k)=zero
           tx(2,j,k)=fiaix*ux(2,j,k)+fibix*(ux(3,j,k)+ux(1,j,k))& 
                +ficix*(ux(4,j,k)-ux(2,j,k))&
                +fidix*(ux(5,j,k)-ux(3,j,k)) 
           tx(3,j,k)=fiaix*ux(3,j,k)+fibix*(ux(4,j,k)+ux(2,j,k))& 
                +ficix*(ux(5,j,k)+ux(1,j,k))&
                +fidix*(ux(6,j,k)-ux(2,j,k)) 
           do i=4,nx-3 
              tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                   +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                   +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           enddo
           tx(nx  ,j,k)=zero
           tx(nx-1,j,k)=fiaix*ux(nx-1,j,k)+fibix*( ux(nx  ,j,k)+ux(nx-2,j,k))& 
                +ficix*(-ux(nx-1,j,k)+ux(nx-3,j,k))&
                +fidix*(-ux(nx-2,j,k)+ux(nx-4,j,k)) 
           tx(nx-2,j,k)=fiaix*ux(nx-2,j,k)+fibix*( ux(nx-1,j,k)+ux(nx-3,j,k))& 
                +ficix*( ux(nx  ,j,k)+ux(nx-4,j,k))&
                +fidix*(-ux(nx-1,j,k)+ux(nx-5,j,k)) 
           do i=2,nx 
              tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           enddo
           tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
           do i=nx-1,1,-1  
              tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           enddo

        enddo
     enddo
  endif

  return

end subroutine filx_11

subroutine filx_12(tx,ux,rx,fisx,fiffx,fifsx,fifwx,nx,ny,nz,npaire) 

  USE param  
  USE parfiX 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tx,ux,rx 
  real(mytype), dimension(ny,nz) :: fisx
  real(mytype), dimension(nx) :: fiffx,fifsx,fifwx

  if(iibm.eq.2) call lagpolx(ux)

  if (npaire==1) then 
     do k=1,nz 
        do j=1,ny 
           tx(1,j,k)=fiaix*ux(1,j,k)+fibix*(ux(2,j,k)+ux(2,j,k))&
                +ficix*(ux(3,j,k)+ux(3,j,k))&
                +fidix*(ux(4,j,k)+ux(4,j,k))
           tx(2,j,k)=fiaix*ux(2,j,k)+fibix*(ux(3,j,k)+ux(1,j,k))& 
                +ficix*(ux(4,j,k)+ux(2,j,k))&
                +fidix*(ux(5,j,k)+ux(3,j,k)) 
           tx(3,j,k)=fiaix*ux(3,j,k)+fibix*(ux(4,j,k)+ux(2,j,k))& 
                +ficix*(ux(5,j,k)+ux(1,j,k))&
                +fidix*(ux(6,j,k)+ux(2,j,k)) 
           do i=4,nx-3 
              tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                   +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                   +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           enddo
           tx(nx,j,k)=ux(nx,j,k)
           tx(nx-1,j,k)=fiamx*ux(nx,j,k)+fibmx*ux(nx-1,j,k)+ficmx*ux(nx-2,j,k)+&
                fidmx*ux(nx-3,j,k)
           tx(nx-2,j,k)=fiapx*ux(nx,j,k)+fibpx*ux(nx-1,j,k)+ficpx*ux(nx-2,j,k)+&
                fidpx*ux(nx-3,j,k)+fiepx*ux(nx-4,j,k)+fifpx*ux(nx-5,j,k)
           do i=2,nx 
              tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           enddo
           tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
           do i=nx-1,1,-1  
              tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           enddo
        enddo
     enddo
  endif

  if (npaire==0) then 
     do k=1,nz 
        do j=1,ny 
           tx(1,j,k)=zero
           tx(2,j,k)=fiaix*ux(2,j,k)+fibix*(ux(3,j,k)+ux(1,j,k))& 
                +ficix*(ux(4,j,k)-ux(2,j,k))&
                +fidix*(ux(5,j,k)-ux(3,j,k)) 
           tx(3,j,k)=fiaix*ux(3,j,k)+fibix*(ux(4,j,k)+ux(2,j,k))& 
                +ficix*(ux(5,j,k)+ux(1,j,k))&
                +fidix*(ux(6,j,k)-ux(2,j,k)) 
           do i=4,nx-3 
              tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                   +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                   +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           enddo
           tx(nx,j,k)=ux(nx,j,k)
           tx(nx-1,j,k)=fiamx*ux(nx,j,k)+fibmx*ux(nx-1,j,k)+ficmx*ux(nx-2,j,k)+&
                fidmx*ux(nx-3,j,k)
           tx(nx-2,j,k)=fiapx*ux(nx,j,k)+fibpx*ux(nx-1,j,k)+ficpx*ux(nx-2,j,k)+&
                fidpx*ux(nx-3,j,k)+fiepx*ux(nx-4,j,k)+fifpx*ux(nx-5,j,k)
           do i=2,nx 
              tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           enddo
           tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
           do i=nx-1,1,-1  
              tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           enddo

        enddo
     enddo
  endif

  return

end subroutine filx_12

subroutine filx_21(tx,ux,rx,fisx,fiffx,fifsx,fifwx,nx,ny,nz,npaire) 

  USE param  
  USE parfiX 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tx,ux,rx 
  real(mytype), dimension(ny,nz) :: fisx
  real(mytype), dimension(nx) :: fiffx,fifsx,fifwx

  if(iibm.eq.2) call lagpolx(ux)

  if (npaire==1) then 
     do k=1,nz 
        do j=1,ny 
           tx(1,j,k)=ux(1,j,k)
           tx(2,j,k)=fia2x*ux(1,j,k)+fib2x*ux(2,j,k)+fic2x*ux(3,j,k)+&
                fid2x*ux(4,j,k)
           tx(3,j,k)=fia3x*ux(1,j,k)+fib3x*ux(2,j,k)+fic3x*ux(3,j,k)+&
                fid3x*ux(4,j,k)+fie3x*ux(5,j,k)+fif3x*ux(6,j,k)
           do i=4,nx-3 
              tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                   +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                   +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           enddo
           tx(nx,j,k)  =fiaix*ux(nx,j,k)  +fibix*(ux(nx-1,j,k)+ux(nx-1,j,k))&
                +ficix*(ux(nx-2,j,k)+ux(nx-2,j,k))&
                +fidix*(ux(nx-3,j,k)+ux(nx-3,j,k))
           tx(nx-1,j,k)=fiaix*ux(nx-1,j,k)+fibix*(ux(  nx,j,k)+ux(nx-2,j,k))& 
                +ficix*(ux(nx-1,j,k)+ux(nx-3,j,k))&
                +fidix*(ux(nx-2,j,k)+ux(nx-4,j,k)) 
           tx(nx-2,j,k)=fiaix*ux(nx-2,j,k)+fibix*(ux(nx-1,j,k)+ux(nx-3,j,k))& 
                +ficix*(ux(  nx,j,k)+ux(nx-4,j,k))&
                +fidix*(ux(nx-1,j,k)+ux(nx-5,j,k)) 
           do i=2,nx 
              tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           enddo
           tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
           do i=nx-1,1,-1  
              tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           enddo
        enddo
     enddo
  endif

  if (npaire==0) then 
     do k=1,nz 
        do j=1,ny 
           tx(1,j,k)=ux(1,j,k)
           tx(2,j,k)=fia2x*ux(1,j,k)+fib2x*ux(2,j,k)+fic2x*ux(3,j,k)+&
                fid2x*ux(4,j,k)
           tx(3,j,k)=fia3x*ux(1,j,k)+fib3x*ux(2,j,k)+fic3x*ux(3,j,k)+&
                fid3x*ux(4,j,k)+fie3x*ux(5,j,k)+fif3x*ux(6,j,k)

           do i=4,nx-3 
              tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                   +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                   +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
           enddo
           tx(nx  ,j,k)=zero
           tx(nx-1,j,k)=fiaix*ux(nx-1,j,k)+fibix*( ux(nx  ,j,k)+ux(nx-2,j,k))& 
                +ficix*(-ux(nx-1,j,k)+ux(nx-3,j,k))&
                +fidix*(-ux(nx-2,j,k)+ux(nx-4,j,k)) 
           tx(nx-2,j,k)=fiaix*ux(nx-2,j,k)+fibix*( ux(nx-1,j,k)+ux(nx-3,j,k))& 
                +ficix*( ux(nx  ,j,k)+ux(nx-4,j,k))&
                +fidix*(-ux(nx-1,j,k)+ux(nx-5,j,k)) 
           do i=2,nx 
              tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
           enddo
           tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
           do i=nx-1,1,-1  
              tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
           enddo

        enddo
     enddo
  endif

  return

end subroutine filx_21


subroutine filx_22(tx,ux,rx,fisx,fiffx,fifsx,fifwx,nx,ny,nz,npaire) 

  USE param  
  USE parfiX 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tx,ux,rx 
  real(mytype), dimension(ny,nz) :: fisx
  real(mytype), dimension(nx) :: fiffx,fifsx,fifwx

  if(iibm.eq.2) call lagpolx(ux)

  do k=1,nz
     do j=1,ny 
        tx(1,j,k)=ux(1,j,k)
        tx(2,j,k)=fia2x*ux(1,j,k)+fib2x*ux(2,j,k)+fic2x*ux(3,j,k)+&
             fid2x*ux(4,j,k)
        tx(3,j,k)=fia3x*ux(1,j,k)+fib3x*ux(2,j,k)+fic3x*ux(3,j,k)+&
             fid3x*ux(4,j,k)+fie3x*ux(5,j,k)+fif3x*ux(6,j,k)
        do i=4,nx-3
           tx(i,j,k)=fiaix*ux(i,j,k)+fibix*(ux(i+1,j,k)+ux(i-1,j,k))& 
                +ficix*(ux(i+2,j,k)+ux(i-2,j,k))&
                +fidix*(ux(i+3,j,k)+ux(i-3,j,k)) 
        enddo
        tx(nx,j,k)=ux(nx,j,k)
        tx(nx-1,j,k)=fiamx*ux(nx,j,k)+fibmx*ux(nx-1,j,k)+ficmx*ux(nx-2,j,k)+&
             fidmx*ux(nx-3,j,k)
        tx(nx-2,j,k)=fiapx*ux(nx,j,k)+fibpx*ux(nx-1,j,k)+ficpx*ux(nx-2,j,k)+&
             fidpx*ux(nx-3,j,k)+fiepx*ux(nx-4,j,k)+fifpx*ux(nx-5,j,k)
        do i=2,nx 
           tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*fifsx(i) 
        enddo
        tx(nx,j,k)=tx(nx,j,k)*fifwx(nx) 
        do i=nx-1,1,-1
           tx(i,j,k)=(tx(i,j,k)-fiffx(i)*tx(i+1,j,k))*fifwx(i) 
        enddo
     enddo
  enddo

  return  
end subroutine filx_22

subroutine fily_00(ty,uy,ry,fisy,fiffy,fifsy,fifwy,nx,ny,nz,npaire) 

  USE param  
  USE parfiY 

  implicit none

  integer :: nx,ny,nz,i,j,k,npaire
  real(mytype), dimension(nx,ny,nz) :: ty,uy 
  real(mytype), dimension(nx,ny,nz) :: ry
  real(mytype), dimension(nx,nz)  :: fisy
  real(mytype), dimension(ny) :: fiffy,fifsy,fifwy

  if(iibm.eq.2) call lagpoly(uy)

  do k=1,nz 
     do i=1,nx 
        ty(i,1,k)=fiajy*uy(i,1,k)+fibjy*(uy(i,2,k)+uy(i,ny,k))& 
             +ficjy*(uy(i,3,k)+uy(i,ny-1,k))&
             +fidjy*(uy(i,4,k)+uy(i,ny-2,k)) 
        ry(i,1,k)=-1.
        ty(i,2,k)=fiajy*uy(i,2,k)+fibjy*(uy(i,3,k)+uy(i,1,k))&
             +ficjy*(uy(i,4,k)+uy(i,ny,k))& 
             +fidjy*(uy(i,5,k)+uy(i,ny-1,k)) 
        ry(i,2,k)=0. 
        ty(i,3,k)=fiajy*uy(i,3,k)+fibjy*(uy(i,4,k)+uy(i,2,k))&
             +ficjy*(uy(i,5,k)+uy(i,1,k))& 
             +fidjy*(uy(i,6,k)+uy(i,ny,k)) 
        ry(i,3,k)=0. 
        do j=4,ny-3
           ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           ry(i,j,k)=0. 
        enddo
        ty(i,ny-2,k)=fiajy*uy(i,ny-2,k)+fibjy*(uy(i,ny-3,k)+uy(i,ny-1,k))&
             +ficjy*(uy(i,ny-4,k)+uy(i,ny,k))& 
             +fidjy*(uy(i,ny-5,k)+uy(i,1,k)) 
        ry(i,ny-2,k)=0. 
        ty(i,ny-1,k)=fiajy*uy(i,ny-1,k)+fibjy*(uy(i,ny-2,k)+uy(i,ny,k))&
             +ficjy*(uy(i,ny-3,k)+uy(i,1,k))& 
             +fidjy*(uy(i,ny-4,k)+uy(i,2,k)) 
        ry(i,ny-1,k)=0. 
        ty(i,ny,k)=fiajy*uy(i,ny,k)+fibjy*(uy(i,ny-1,k)+uy(i,1,k))&
             +ficjy*(uy(i,ny-2,k)+uy(i,2,k))& 
             +fidjy*(uy(i,ny-3,k)+uy(i,3,k)) 
        ry(i,ny,k)=fialjy           
        do j=2, ny
           ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           ry(i,j,k)=ry(i,j,k)-ry(i,j-1,k)*fifsy(j) 
        enddo
        ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 
        ry(i,ny,k)=ry(i,ny,k)*fifwy(ny) 
        do j=ny-1,1,-1
           ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           ry(i,j,k)=(ry(i,j,k)-fiffy(j)*ry(i,j+1,k))*fifwy(j) 
        enddo
        fisy(i,k)=(ty(i,1,k)-fialjy*ty(i,ny,k))&
             /(1.+ry(i,1,k)-fialjy*ry(i,ny,k)) 
        do j=1,ny 
           ty(i,j,k)=ty(i,j,k)-fisy(i,k)*ry(i,j,k) 
        enddo
     enddo
  enddo

  return

end subroutine fily_00

!********************************************************************
!
subroutine fily_11(ty,uy,ry,fisy,fiffy,fifsy,fifwy,nx,ny,nz,npaire) 
  !
  !********************************************************************

  USE param  
  USE parfiY 

  implicit none

  integer :: nx,ny,nz,i,j,k,npaire
  real(mytype), dimension(nx,ny,nz) :: ty,uy 
  real(mytype), dimension(nx,ny,nz) :: ry
  real(mytype), dimension(nx,nz)  :: fisy
  real(mytype), dimension(ny) :: fiffy,fifsy,fifwy

  if(iibm.eq.2) call lagpoly(uy)

  if (npaire==1) then 
     do k=1,nz 
        do i=1,nx 
           ty(i,1,k)=fiajy*uy(i,1,k)+fibjy*(uy(i,2,k)+uy(i,2,k))&
                +ficjy*(uy(i,3,k)+uy(i,3,k))&
                +fidjy*(uy(i,4,k)+uy(i,4,k))
           ty(i,2,k)=fiajy*uy(i,2,k)+fibjy*(uy(i,3,k)+uy(i,1,k))& 
                +ficjy*(uy(i,4,k)+uy(i,2,k))&
                +fidjy*(uy(i,5,k)+uy(i,3,k)) 
           ty(i,3,k)=fiajy*uy(i,3,k)+fibjy*(uy(i,4,k)+uy(i,2,k))& 
                +ficjy*(uy(i,5,k)+uy(i,1,k))&
                +fidjy*(uy(i,6,k)+uy(i,2,k)) 
           do j=4,ny-3 
              ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                   +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                   +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           enddo
           ty(i,ny,k)=fiajy*uy(i,ny,k)    +fibjy*(uy(i,ny-1,k)+uy(i,ny-1,k))&
                +ficjy*(uy(i,ny-2,k)+uy(i,ny-2,k))&
                +fidjy*(uy(i,ny-3,k)+uy(i,ny-3,k))
           ty(i,ny-1,k)=fiajy*uy(i,ny-1,k)+fibjy*(uy(i,ny,k)  +uy(i,ny-2,k))& 
                +ficjy*(uy(i,ny-1,k)+uy(i,ny-3,k))&
                +fidjy*(uy(i,ny-2,k)+uy(i,ny-4,k)) 
           ty(i,ny-2,k)=fiajy*uy(i,ny-2,k)+fibjy*(uy(i,ny-1,k)+uy(i,ny-3,k))& 
                +ficjy*(uy(i,ny,k)+uy(i,ny-4,k))&
                +fidjy*(uy(i,ny-1,k)+uy(i,ny-5,k)) 
           do j=2,ny  
              ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           enddo
           ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 
           do j=ny-1,1,-1  
              ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           enddo
        enddo
     enddo
  endif
  if (npaire==0) then 
     do k=1,nz 
        do i=1,nx 
           ty(i,1,k)=zero !fiajy*uy(i,1,k)
           ty(i,2,k)=fiajy*uy(i,2,k)+fibjy*(uy(i,3,k)+uy(i,1,k))& 
                +ficjy*(uy(i,4,k)-uy(i,2,k))&
                +fidjy*(uy(i,5,k)-uy(i,3,k)) 
           ty(i,3,k)=fiajy*uy(i,3,k)+fibjy*(uy(i,4,k)+uy(i,2,k))& 
                +ficjy*(uy(i,5,k)+uy(i,1,k))&
                +fidjy*(uy(i,6,k)-uy(i,2,k)) 
           do j=4,ny-3 
              ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                   +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                   +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           enddo
           ty(i,ny,k)=zero !fiajy*uy(i,ny,k)
           ty(i,ny-1,k)=fiajy*uy(i,ny-1,k) +fibjy*(uy(i,ny,k)+uy(i,ny-2,k))& 
                +ficjy*(-uy(i,ny-1,k)+uy(i,ny-3,k))&
                +fidjy*(-uy(i,ny-2,k)+uy(i,ny-4,k)) 
           ty(i,ny-2,k)=fiajy*uy(i,ny-2,k) +fibjy*(uy(i,ny-1,k)+uy(i,ny-3,k))& 
                +ficjy*(uy(i,ny,k)+uy(i,ny-4,k))&
                +fidjy*(-uy(i,ny-1,k)+uy(i,ny-5,k)) 
           do j=2,ny  
              ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           enddo
           ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 

           do j=ny-1,1,-1  
              ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           enddo
        enddo
     enddo
  endif

  return

end subroutine fily_11


subroutine fily_12(ty,uy,ry,fisy,fiffy,fifsy,fifwy,nx,ny,nz,npaire) 

  USE param  
  USE parfiY 

  implicit none

  integer :: nx,ny,nz,i,j,k,npaire
  real(mytype), dimension(nx,ny,nz) :: ty,uy 
  real(mytype), dimension(nx,ny,nz) :: ry
  real(mytype), dimension(nx,nz)  :: fisy
  real(mytype), dimension(ny) :: fiffy,fifsy,fifwy

  if(iibm.eq.2) call lagpoly(uy)
  if (npaire==1) then 
     do k=1,nz 
        do i=1,nx 
           ty(i,1,k)=fiajy*uy(i,1,k)+fibjy*(uy(i,2,k)+uy(i,2,k))&
                +ficjy*(uy(i,3,k)+uy(i,3,k))&
                +fidjy*(uy(i,4,k)+uy(i,4,k))
           ty(i,2,k)=fiajy*uy(i,2,k)+fibjy*(uy(i,3,k)+uy(i,1,k))& 
                +ficjy*(uy(i,4,k)+uy(i,2,k))&
                +fidjy*(uy(i,5,k)+uy(i,3,k)) 
           ty(i,3,k)=fiajy*uy(i,3,k)+fibjy*(uy(i,4,k)+uy(i,2,k))& 
                +ficjy*(uy(i,5,k)+uy(i,1,k))&
                +fidjy*(uy(i,6,k)+uy(i,2,k)) 
           do j=4,ny-3 
              ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                   +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                   +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           enddo
           ty(i,ny,k)  =      uy(i,ny,k)
           ty(i,ny-1,k)=fiamy*uy(i,ny  ,k)+fibmy*uy(i,ny-1,k)+ficmy*uy(i,ny-2,k)+&
                fidmy*uy(i,ny-3,k)
           ty(i,ny-2,k)=fiapy*uy(i,ny  ,k)+fibpy*uy(i,ny-1,k)+ficpy*uy(i,ny-2,k)+&
                fidpy*uy(i,ny-3,k)+fiepy*uy(i,ny-4,k)+fifpy*uy(i,ny-5,k)
           do j=2,ny  
              ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           enddo
           ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 
           do j=ny-1,1,-1  
              ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           enddo
        enddo
     enddo
  endif
  if (npaire==0) then 
     do k=1,nz 
        do i=1,nx 
           ty(i,1,k)=zero !fiajy*uy(i,1,k)
           ty(i,2,k)=fiajy*uy(i,2,k)+fibjy*(uy(i,3,k)+uy(i,1,k))& 
                +ficjy*(uy(i,4,k)-uy(i,2,k))&
                +fidjy*(uy(i,5,k)-uy(i,3,k)) 
           ty(i,3,k)=fiajy*uy(i,3,k)+fibjy*(uy(i,4,k)+uy(i,2,k))& 
                +ficjy*(uy(i,5,k)+uy(i,1,k))&
                +fidjy*(uy(i,6,k)-uy(i,2,k)) 
           do j=4,ny-3 
              ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                   +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                   +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           enddo
           ty(i,ny,k)  =      uy(i,ny,k)
           ty(i,ny-1,k)=fiamy*uy(i,ny  ,k)+fibmy*uy(i,ny-1,k)+ficmy*uy(i,ny-2,k)+&
                fidmy*uy(i,ny-3,k)
           ty(i,ny-2,k)=fiapy*uy(i,ny  ,k)+fibpy*uy(i,ny-1,k)+ficpy*uy(i,ny-2,k)+&
                fidpy*uy(i,ny-3,k)+fiepy*uy(i,ny-4,k)+fifpy*uy(i,ny-5,k)
           do j=2,ny  
              ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           enddo
           ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 

           do j=ny-1,1,-1  
              ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           enddo
        enddo
     enddo
  endif

end subroutine fily_12


subroutine fily_21(ty,uy,ry,fisy,fiffy,fifsy,fifwy,nx,ny,nz,npaire) 

  USE param  
  USE parfiY 

  implicit none

  integer :: nx,ny,nz,i,j,k,npaire
  real(mytype), dimension(nx,ny,nz) :: ty,uy 
  real(mytype), dimension(nx,ny,nz) :: ry
  real(mytype), dimension(nx,nz)  :: fisy
  real(mytype), dimension(ny) :: fiffy,fifsy,fifwy

  if(iibm.eq.2) call lagpoly(uy)

  if (npaire==1) then 
     do k=1,nz 
        do i=1,nx 
           ty(i,1,k)=      uy(i,1,k)
           ty(i,2,k)=fia2y*uy(i,1,k)+fib2y*uy(i,2,k)+fic2y*uy(i,3,k)+&
                fid2y*uy(i,4,k)
           ty(i,3,k)=fia3y*uy(i,1,k)+fib3y*uy(i,2,k)+fic3y*uy(i,3,k)+&
                fid3y*uy(i,4,k)+fie3y*uy(i,5,k)+fif3y*uy(i,6,k)
           do j=4,ny-3 
              ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                   +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                   +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           enddo
           ty(i,ny,k)=fiajy*uy(i,ny,k)    +fibjy*(uy(i,ny-1,k)+uy(i,ny-1,k))&
                +ficjy*(uy(i,ny-2,k)+uy(i,ny-2,k))&
                +fidjy*(uy(i,ny-3,k)+uy(i,ny-3,k))
           ty(i,ny-1,k)=fiajy*uy(i,ny-1,k)+fibjy*(uy(i,ny,k)  +uy(i,ny-2,k))& 
                +ficjy*(uy(i,ny-1,k)+uy(i,ny-3,k))&
                +fidjy*(uy(i,ny-2,k)+uy(i,ny-4,k)) 
           ty(i,ny-2,k)=fiajy*uy(i,ny-2,k)+fibjy*(uy(i,ny-1,k)+uy(i,ny-3,k))& 
                +ficjy*(uy(i,ny,k)+uy(i,ny-4,k))&
                +fidjy*(uy(i,ny-1,k)+uy(i,ny-5,k)) 
           do j=2,ny  
              ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           enddo
           ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 
           do j=ny-1,1,-1  
              ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           enddo
        enddo
     enddo
  endif
  if (npaire==0) then 
     do k=1,nz 
        do i=1,nx 
           ty(i,1,k)=      uy(i,1,k)
           ty(i,2,k)=fia2y*uy(i,1,k)+fib2y*uy(i,2,k)+fic2y*uy(i,3,k)+&
                fid2y*uy(i,4,k)
           ty(i,3,k)=fia3y*uy(i,1,k)+fib3y*uy(i,2,k)+fic3y*uy(i,3,k)+&
                fid3y*uy(i,4,k)+fie3y*uy(i,5,k)+fif3y*uy(i,6,k)
           do j=4,ny-3 
              ty(i,j,k)=fiajy*uy(i,j,k)+fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                   +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                   +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
           enddo
           ty(i,ny,k)=zero !fiajy*uy(i,ny,k)
           ty(i,ny-1,k)=fiajy*uy(i,ny-1,k) +fibjy*(uy(i,ny,k)+uy(i,ny-2,k))& 
                +ficjy*(-uy(i,ny-1,k)+uy(i,ny-3,k))&
                +fidjy*(-uy(i,ny-2,k)+uy(i,ny-4,k)) 
           ty(i,ny-2,k)=fiajy*uy(i,ny-2,k) +fibjy*(uy(i,ny-1,k)+uy(i,ny-3,k))& 
                +ficjy*(uy(i,ny,k)+uy(i,ny-4,k))&
                +fidjy*(-uy(i,ny-1,k)+uy(i,ny-5,k)) 
           do j=2,ny  
              ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
           enddo
           ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 

           do j=ny-1,1,-1  
              ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
           enddo
        enddo
     enddo
  endif

  return

end subroutine fily_21

subroutine fily_22(ty,uy,ry,fisy,fiffy,fifsy,fifwy,nx,ny,nz,npaire) 

  USE param  
  USE parfiY 

  implicit none

  integer :: nx,ny,nz,i,j,k,npaire
  real(mytype), dimension(nx,ny,nz) :: ty,uy 
  real(mytype), dimension(nx,ny,nz) :: ry
  real(mytype), dimension(nx,nz)  :: fisy
  real(mytype), dimension(ny) :: fiffy,fifsy,fifwy

  if(iibm.eq.2) call lagpoly(uy)

  do k=1,nz
     do i=1,nx 
        ty(i,1,k)=      uy(i,1,k)
        ty(i,2,k)=fia2y*uy(i,1,k)+fib2y*uy(i,2,k)+fic2y*uy(i,3,k)+&
             fid2y*uy(i,4,k)
        ty(i,3,k)=fia3y*uy(i,1,k)+fib3y*uy(i,2,k)+fic3y*uy(i,3,k)+&
             fid3y*uy(i,4,k)+fie3y*uy(i,5,k)+fif3y*uy(i,6,k)
        do j=4,ny-3
           ty(i,j,k)=fiajy*uy(i,j,k) +fibjy*(uy(i,j+1,k)+uy(i,j-1,k))& 
                +ficjy*(uy(i,j+2,k)+uy(i,j-2,k))&
                +fidjy*(uy(i,j+3,k)+uy(i,j-3,k)) 
        enddo
        ty(i,ny,k)  =      uy(i,ny  ,k)
        ty(i,ny-1,k)=fiamy*uy(i,ny  ,k)+fibmy*uy(i,ny-1,k)+ficmy*uy(i,ny-2,k)+&
             fidmy*uy(i,ny-3,k)
        ty(i,ny-2,k)=fiapy*uy(i,ny  ,k)+fibpy*uy(i,ny-1,k)+ficpy*uy(i,ny-2,k)+&
             fidpy*uy(i,ny-3,k)+fiepy*uy(i,ny-4,k)+fifpy*uy(i,ny-5,k)
        do j=2,ny 
           ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*fifsy(j) 
        enddo
        ty(i,ny,k)=ty(i,ny,k)*fifwy(ny) 
        do j=ny-1,1,-1
           ty(i,j,k)=(ty(i,j,k)-fiffy(j)*ty(i,j+1,k))*fifwy(j) 
        enddo
     enddo
  enddo

  return

end subroutine fily_22

subroutine filz_00(tz,uz,rz,fisz,fiffz,fifsz,fifwz,nx,ny,nz,npaire) 

  USE param  
  USE parfiZ 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tz,uz,rz
  real(mytype), dimension(nx,ny) :: fisz
  real(mytype), dimension(nz) :: fiffz,fifsz,fifwz

  if(iibm.eq.2) call lagpolz(uz)

  do j=1,ny 
     do i=1,nx 
        tz(i,j,1)=fiakz*uz(i,j,1)+fibkz*(uz(i,j,2)+uz(i,j,nz))& 
             +fickz*(uz(i,j,3)+uz(i,j,nz-1))&
             +fidkz*(uz(i,j,4)+uz(i,j,nz-2)) 
        rz(i,j,1)=-1.
        tz(i,j,2)=fiakz*uz(i,j,2)+fibkz*(uz(i,j,3)+uz(i,j,1))&
             +fickz*(uz(i,j,4)+uz(i,j,nz))& 
             +fidkz*(uz(i,j,5)+uz(i,j,nz-1)) 
        rz(i,j,2)=0. 
        tz(i,j,3)=fiakz*uz(i,j,3)+fibkz*(uz(i,j,4)+uz(i,j,2))&
             +fickz*(uz(i,j,5)+uz(i,j,1))& 
             +fidkz*(uz(i,j,6)+uz(i,j,nz)) 
        rz(i,j,3)=0.
        do k=4,nz-3
           tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           rz(i,j,k)=0. 
        enddo
        tz(i,j,nz-2)=fiakz*uz(i,j,nz-2)+fibkz*(uz(i,j,nz-3)+uz(i,j,nz-1))&
             +fickz*(uz(i,j,nz-4)+uz(i,j,nz))& 
             +fidkz*(uz(i,j,nz-5)+uz(i,j,1)) 
        rz(i,j,nz-2)=0. 
        tz(i,j,nz-1)=fiakz*uz(i,j,nz-1)+fibkz*(uz(i,j,nz-2)+uz(i,j,nz))&
             +fickz*(uz(i,j,nz-3)+uz(i,j,1))& 
             +fidkz*(uz(i,j,nz-4)+uz(i,j,2)) 
        rz(i,j,nz-1)=0. 
        tz(i,j,nz)=fiakz*uz(i,j,nz)+fibkz*(uz(i,j,nz-1)+uz(i,j,1))&
             +fickz*(uz(i,j,nz-2)+uz(i,j,2))& 
             +fidkz*(uz(i,j,nz-3)+uz(i,j,3)) 
        rz(i,j,nz)=fialkz           
        do k=2,nz
           tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           rz(i,j,k)=rz(i,j,k)-rz(i,j,k-1)*fifsz(k) 
        enddo
        tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 
        rz(i,j,nz)=rz(i,j,nz)*fifwz(nz) 
        do k=nz-1,1,-1
           tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           rz(i,j,k)=(rz(i,j,k)-fiffz(k)*rz(i,j,k+1))*fifwz(k) 
        enddo
        fisz(i,j)=(tz(i,j,1)-fialkz*tz(i,j,nz))&
             /(1.+rz(i,j,1)-fialkz*rz(i,j,nz)) 
        do k=1,nz 
           tz(i,j,k)=tz(i,j,k)-fisz(i,j)*rz(i,j,k) 
        enddo

     enddo
  enddo

  return  
end subroutine filz_00

subroutine filz_11(tz,uz,rz,fisz,fiffz,fifsz,fifwz,nx,ny,nz,npaire) 

  USE param  
  USE parfiZ 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tz,uz,rz
  real(mytype), dimension(nx,ny) :: fisz
  real(mytype), dimension(nz) :: fiffz,fifsz,fifwz

  if(iibm.eq.2) call lagpolz(uz)

  if (npaire==1) then 
     do j=1,ny 
        do i=1,nx 
           tz(i,j,1)=fiakz*uz(i,j,1)+fibkz*(uz(i,j,2)+uz(i,j,2))&
                +fickz*(uz(i,j,3)+uz(i,j,3))&
                +fidkz*(uz(i,j,4)+uz(i,j,4))
           tz(i,j,2)=fiakz*uz(i,j,2)+fibkz*(uz(i,j,3)+uz(i,j,1))& 
                +fickz*(uz(i,j,4)+uz(i,j,2))&
                +fidkz*(uz(i,j,5)+uz(i,j,3)) 
           tz(i,j,3)=fiakz*uz(i,j,3)+fibkz*(uz(i,j,4)+uz(i,j,2))& 
                +fickz*(uz(i,j,5)+uz(i,j,1))&
                +fidkz*(uz(i,j,6)+uz(i,j,2)) 
           do k=4,nz-3 
              tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                   +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                   +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           enddo
           tz(i,j,nz)=fiakz*uz(i,j,nz)    +fibkz*(uz(i,j,nz-1)+uz(i,j,nz-1))&
                +fickz*(uz(i,j,nz-2)+uz(i,j,nz-2))&
                +fidkz*(uz(i,j,nz-3)+uz(i,j,nz-3))
           tz(i,j,nz-1)=fiakz*uz(i,j,nz-1)+fibkz*(uz(i,j,nz  )+uz(i,j,nz-2))& 
                +fickz*(uz(i,j,nz-1)+uz(i,j,nz-3))&
                +fidkz*(uz(i,j,nz-2)+uz(i,j,nz-4)) 
           tz(i,j,nz-2)=fiakz*uz(i,j,nz-2)+fibkz*(uz(i,j,nz-1)+uz(i,j,nz-3))& 
                +fickz*(uz(i,j,nz  )+uz(i,j,nz-4))&
                +fidkz*(uz(i,j,nz-1)+uz(i,j,nz-5)) 
           do k=2,nz  
              tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           enddo
           tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 
           do k=nz-1,1,-1  
              tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           enddo
        enddo
     enddo
  endif
  if (npaire==0) then 
     do j=1,ny 
        do i=1,nx 
           tz(i,j,1)=zero 
           tz(i,j,2)=fiakz*uz(i,j,2)+fibkz*(uz(i,j,3)+uz(i,j,1))& 
                +fickz*(uz(i,j,4)-uz(i,j,2))&
                +fidkz*(uz(i,j,5)-uz(i,j,3)) 
           tz(i,j,3)=fiakz*uz(i,j,3)+fibkz*(uz(i,j,4)+uz(i,j,2))& 
                +fickz*(uz(i,j,5)+uz(i,j,1))&
                +fidkz*(uz(i,j,6)-uz(i,j,2)) 
           do k=4,nz-3 
              tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                   +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                   +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           enddo
           tz(i,j,nz)=zero 
           tz(i,j,nz-1)=fiakz*uz(i,j,nz-1) +fibkz*( uz(i,j,nz  )+uz(i,j,nz-2))& 
                +fickz*(-uz(i,j,nz-1)+uz(i,j,nz-3))&
                +fidkz*(-uz(i,j,nz-2)+uz(i,j,nz-4)) 
           tz(i,j,nz-2)=fiakz*uz(i,j,nz-2) +fibkz*( uz(i,j,nz-1)+uz(i,j,nz-3))& 
                +fickz*( uz(i,j,nz  )+uz(i,j,nz-4))&
                +fidkz*(-uz(i,j,nz-1)+uz(i,j,nz-5)) 
           do k=2,nz  
              tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           enddo
           tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 

           do k=nz-1,1,-1  
              tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           enddo
        enddo
     enddo
  endif

  return
end subroutine filz_11

subroutine filz_12(tz,uz,rz,fisz,fiffz,fifsz,fifwz,nx,ny,nz,npaire) 

  USE param  
  USE parfiZ 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tz,uz,rz
  real(mytype), dimension(nx,ny) :: fisz
  real(mytype), dimension(nz) :: fiffz,fifsz,fifwz

  if(iibm.eq.2) call lagpolz(uz)

  if (npaire==1) then 
     do j=1,ny 
        do i=1,nx 
           tz(i,j,1)=fiakz*uz(i,j,1)+fibkz*(uz(i,j,2)+uz(i,j,2))&
                +fickz*(uz(i,j,3)+uz(i,j,3))&
                +fidkz*(uz(i,j,4)+uz(i,j,4))
           tz(i,j,2)=fiakz*uz(i,j,2)+fibkz*(uz(i,j,3)+uz(i,j,1))& 
                +fickz*(uz(i,j,4)+uz(i,j,2))&
                +fidkz*(uz(i,j,5)+uz(i,j,3)) 
           tz(i,j,3)=fiakz*uz(i,j,3)+fibkz*(uz(i,j,4)+uz(i,j,2))& 
                +fickz*(uz(i,j,5)+uz(i,j,1))&
                +fidkz*(uz(i,j,6)+uz(i,j,2)) 
           do k=4,nz-3 
              tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                   +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                   +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           enddo
           tz(i,j,nz)   =      uz(i,j,nz  )
           tz(i,j,nz-1 )=fiamz*uz(i,j,nz  )+fibmz*uz(i,j,nz-1)+ficmz*uz(i,j,nz-2)+&
                fidmz*uz(i,j,nz-3)
           tz(i,j,nz-2 )=fiapz*uz(i,j,nz  )+fibpz*uz(i,j,nz-1)+ficpz*uz(i,j,nz-2)+&
                fidpz*uz(i,j,nz-3)+fiepz*uz(i,j,nz-4)+fifpz*uz(i,j,nz-5)
           do k=2,nz  
              tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           enddo
           tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 
           do k=nz-1,1,-1  
              tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           enddo
        enddo
     enddo
  endif
  if (npaire==0) then 
     do j=1,ny 
        do i=1,nx 
           tz(i,j,1)=zero 
           tz(i,j,2)=fiakz*uz(i,j,2)+fibkz*(uz(i,j,3)+uz(i,j,1))& 
                +fickz*(uz(i,j,4)-uz(i,j,2))&
                +fidkz*(uz(i,j,5)-uz(i,j,3)) 
           tz(i,j,3)=fiakz*uz(i,j,3)+fibkz*(uz(i,j,4)+uz(i,j,2))& 
                +fickz*(uz(i,j,5)+uz(i,j,1))&
                +fidkz*(uz(i,j,6)-uz(i,j,2)) 
           do k=4,nz-3 
              tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                   +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                   +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           enddo
           tz(i,j,nz)   =      uz(i,j,nz  )
           tz(i,j,nz-1 )=fiamz*uz(i,j,nz  )+fibmz*uz(i,j,nz-1)+ficmz*uz(i,j,nz-2)+&
                fidmz*uz(i,j,nz-3)
           tz(i,j,nz-2 )=fiapz*uz(i,j,nz  )+fibpz*uz(i,j,nz-1)+ficpz*uz(i,j,nz-2)+&
                fidpz*uz(i,j,nz-3)+fiepz*uz(i,j,nz-4)+fifpz*uz(i,j,nz-5)
           do k=2,nz  
              tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           enddo
           tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 

           do k=nz-1,1,-1  
              tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           enddo
        enddo
     enddo
  endif

  return

end subroutine filz_12

subroutine filz_21(tz,uz,rz,fisz,fiffz,fifsz,fifwz,nx,ny,nz,npaire) 

  USE param  
  USE parfiZ 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tz,uz,rz
  real(mytype), dimension(nx,ny) :: fisz
  real(mytype), dimension(nz) :: fiffz,fifsz,fifwz

  if(iibm.eq.2) call lagpolz(uz)

  if (npaire==1) then 
     do j=1,ny 
        do i=1,nx 
           tz(i,j,1)=      uz(i,j,1)
           tz(i,j,2)=fia2z*uz(i,j,1)+fib2z*uz(i,j,2)+fic2z*uz(i,j,3)+&
                fid2z*uz(i,j,4)
           tz(i,j,3)=fia3z*uz(i,j,1)+fib3z*uz(i,j,2)+fic3z*uz(i,j,3)+&
                fid3z*uz(i,j,4)+fie3z*uz(i,j,5)+fif3z*uz(i,j,6)
           do k=4,nz-3 
              tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                   +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                   +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           enddo
           tz(i,j,nz)=fiakz*uz(i,j,nz)    +fibkz*(uz(i,j,nz-1)+uz(i,j,nz-1))&
                +fickz*(uz(i,j,nz-2)+uz(i,j,nz-2))&
                +fidkz*(uz(i,j,nz-3)+uz(i,j,nz-3))
           tz(i,j,nz-1)=fiakz*uz(i,j,nz-1)+fibkz*(uz(i,j,nz  )+uz(i,j,nz-2))& 
                +fickz*(uz(i,j,nz-1)+uz(i,j,nz-3))&
                +fidkz*(uz(i,j,nz-2)+uz(i,j,nz-4)) 
           tz(i,j,nz-2)=fiakz*uz(i,j,nz-2)+fibkz*(uz(i,j,nz-1)+uz(i,j,nz-3))& 
                +fickz*(uz(i,j,nz  )+uz(i,j,nz-4))&
                +fidkz*(uz(i,j,nz-1)+uz(i,j,nz-5)) 
           do k=2,nz  
              tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           enddo
           tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 
           do k=nz-1,1,-1  
              tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           enddo
        enddo
     enddo
  endif
  if (npaire==0) then 
     do j=1,ny 
        do i=1,nx 
           tz(i,j,1)=      uz(i,j,1)
           tz(i,j,2)=fia2z*uz(i,j,1)+fib2z*uz(i,j,2)+fic2z*uz(i,j,3)+&
                fid2z*uz(i,j,4)
           tz(i,j,3)=fia3z*uz(i,j,1)+fib3z*uz(i,j,2)+fic3z*uz(i,j,3)+&
                fid3z*uz(i,j,4)+fie3z*uz(i,j,5)+fif3z*uz(i,j,6)
           do k=4,nz-3 
              tz(i,j,k)=fiakz*uz(i,j,k)+fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                   +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                   +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
           enddo
           tz(i,j,nz)=zero 
           tz(i,j,nz-1)=fiakz*uz(i,j,nz-1) +fibkz*( uz(i,j,nz  )+uz(i,j,nz-2))& 
                +fickz*(-uz(i,j,nz-1)+uz(i,j,nz-3))&
                +fidkz*(-uz(i,j,nz-2)+uz(i,j,nz-4)) 
           tz(i,j,nz-2)=fiakz*uz(i,j,nz-2) +fibkz*( uz(i,j,nz-1)+uz(i,j,nz-3))& 
                +fickz*( uz(i,j,nz  )+uz(i,j,nz-4))&
                +fidkz*(-uz(i,j,nz-1)+uz(i,j,nz-5)) 
           do k=2,nz  
              tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
           enddo
           tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 

           do k=nz-1,1,-1  
              tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
           enddo
        enddo
     enddo
  endif

  return

end subroutine filz_21


subroutine filz_22(tz,uz,rz,fisz,fiffz,fifsz,fifwz,nx,ny,nz,npaire) 

  USE param  
  USE parfiZ 

  implicit none

  integer :: nx,ny,nz,npaire,i,j,k
  real(mytype), dimension(nx,ny,nz) :: tz,uz,rz
  real(mytype), dimension(nx,ny) :: fisz
  real(mytype), dimension(nz) :: fiffz,fifsz,fifwz

  if(iibm.eq.2) call lagpolz(uz)

  do j=1,ny
     do i=1,nx 
        tz(i,j,1)=      uz(i,j,1)
        tz(i,j,2)=fia2z*uz(i,j,1)+fib2z*uz(i,j,2)+fic2z*uz(i,j,3)+&
             fid2z*uz(i,j,4)
        tz(i,j,3)=fia3z*uz(i,j,1)+fib3z*uz(i,j,2)+fic3z*uz(i,j,3)+&
             fid3z*uz(i,j,4)+fie3z*uz(i,j,5)+fif3z*uz(i,j,6)
        do k=4,nz-3
           tz(i,j,k)=fiakz*uz(i,j,k) +fibkz*(uz(i,j,k+1)+uz(i,j,k-1))& 
                +fickz*(uz(i,j,k+2)+uz(i,j,k-2))&
                +fidkz*(uz(i,j,k+3)+uz(i,j,k-3)) 
        enddo
        tz(i,j,nz)   =      uz(i,j,nz  )
        tz(i,j,nz-1 )=fiamz*uz(i,j,nz  )+fibmz*uz(i,j,nz-1)+ficmz*uz(i,j,nz-2)+&
             fidmz*uz(i,j,nz-3)
        tz(i,j,nz-2 )=fiapz*uz(i,j,nz  )+fibpz*uz(i,j,nz-1)+ficpz*uz(i,j,nz-2)+&
             fidpz*uz(i,j,nz-3)+fiepz*uz(i,j,nz-4)+fifpz*uz(i,j,nz-5)
        do k=2,nz 
           tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*fifsz(k) 
        enddo
        tz(i,j,nz)=tz(i,j,nz)*fifwz(nz) 
        do k=nz-1,1,-1
           tz(i,j,k)=(tz(i,j,k)-fiffz(k)*tz(i,j,k+1))*fifwz(k) 
        enddo
     enddo
  enddo

  return

end subroutine filz_22

!*********************************************************************
!
subroutine filxx_00(tx,ux,rx,fvalx,fvaix,fvbix,fvcix,fvdix,fveix,&
                    sx,vfx,vsx,vwx,nx,ny,nz,npaire) 
!
!********************************************************************

USE decomp_2d, ONLY: nrank
USE param 

implicit none

integer :: nx,ny,nz,npaire,i,j,k 
real(mytype), dimension(nx,ny,nz) :: tx,ux,rx
real(mytype), dimension(ny,nz)    :: sx
real(mytype),  dimension(nx)      :: vfx,vsx,vwx 
real(mytype)                      :: fvalx,fvaix,fvbix,fvcix,fvdix,fveix

    if(iibm.eq.2) call lagpolx(ux)

    do k=1,nz
    do j=1,ny
       tx(1,j,k)=fvaix*ux(1,j,k)+&
                 fvbix*(ux(2,j,k)+ux(nx,j,k))+&
                 fvcix*(ux(3,j,k)+ux(nx-1,j,k))+&
                 fvdix*(ux(4,j,k)+ux(nx-2,j,k))+&
                 fveix*(ux(5,j,k)+ux(nx-3,j,k))
       rx(1,j,k)=-1.
       tx(2,j,k)=fvaix*ux(2,j,k)+&
                 fvbix*(ux(3,j,k)+ux(1,j,k))+&
                 fvcix*(ux(4,j,k)+ux(nx,j,k))+&
                 fvdix*(ux(5,j,k)+ux(nx-1,j,k))+&
                 fveix*(ux(6,j,k)+ux(nx-2,j,k))
       rx(2,j,k)=0.
       tx(3,j,k)=fvaix*ux(3,j,k)+&
                 fvbix*(ux(4,j,k)+ux(2,j,k))+&
                 fvcix*(ux(5,j,k)+ux(1,j,k))+&
                 fvdix*(ux(6,j,k)+ux(nx,j,k))+&
                 fveix*(ux(7,j,k)+ux(nx-1,j,k))
       rx(3,j,k)=0.
       tx(4,j,k)=fvaix*ux(4,j,k)+&
                 fvbix*(ux(5,j,k)+ux(3,j,k))+&
                 fvcix*(ux(6,j,k)+ux(2,j,k))+&
                 fvdix*(ux(7,j,k)+ux(1,j,k))+&
                 fveix*(ux(8,j,k)+ux(nx,j,k))
       rx(4,j,k)=0.
       do i=5,nx-4
          tx(i,j,k)=fvaix*ux(i,j,k)+&
                    fvbix*(ux(i+1,j,k)+ux(i-1,j,k))+&
                    fvcix*(ux(i+2,j,k)+ux(i-2,j,k))+&
                    fvdix*(ux(i+3,j,k)+ux(i-3,j,k))+&
                    fveix*(ux(i+4,j,k)+ux(i-4,j,k))
          rx(i,j,k)=0.
       enddo
       tx(nx-3,j,k)=fvaix*ux(nx-3,j,k)+&
                    fvbix*(ux(nx-2,j,k)+ux(nx-4,j,k))+&
                    fvcix*(ux(nx-1,j,k)+ux(nx-5,j,k))+&
                    fvdix*(ux(nx,j,k)+ux(nx-6,j,k))+&
                    fveix*(ux(1,j,k)+ux(nx-7,j,k))
       rx(nx-3,j,k)=0.
       tx(nx-2,j,k)=fvaix*ux(nx-2,j,k)+&
                    fvbix*(ux(nx-1,j,k)+ux(nx-3,j,k))+&
                    fvcix*(ux(nx,j,k)+ux(nx-4,j,k))+&
                    fvdix*(ux(1,j,k)+ux(nx-5,j,k))+&
                    fveix*(ux(2,j,k)+ux(nx-6,j,k))
       rx(nx-2,j,k)=0.
       tx(nx-1,j,k)=fvaix*ux(nx-1,j,k)+&
                    fvbix*(ux(nx,j,k)+ux(nx-2,j,k))+&
                    fvcix*(ux(1,j,k)+ux(nx-3,j,k))+&
                    fvdix*(ux(2,j,k)+ux(nx-4,j,k))+&
                    fveix*(ux(3,j,k)+ux(nx-5,j,k))
       rx(nx-1,j,k)=0.
       tx(nx  ,j,k)=fvaix*ux(nx,j,k)+&
                    fvbix*(ux(1,j,k)+ux(nx-1,j,k))+&
                    fvcix*(ux(2,j,k)+ux(nx-2,j,k))+&
                    fvdix*(ux(3,j,k)+ux(nx-3,j,k))+&
                    fveix*(ux(4,j,k)+ux(nx-4,j,k))
       rx(nx  ,j,k)=fvalx
       do i=2,nx
          tx(i,j,k)=tx(i,j,k)-tx(i-1,j,k)*vsx(i)
          rx(i,j,k)=rx(i,j,k)-rx(i-1,j,k)*vsx(i)
       enddo
          tx(nx,j,k)=tx(nx,j,k)*vwx(nx)
          rx(nx,j,k)=rx(nx,j,k)*vwx(nx)
       do i=nx-1,1,-1
          tx(i,j,k)=(tx(i,j,k)-vfx(i)*tx(i+1,j,k))*vwx(i)
          rx(i,j,k)=(rx(i,j,k)-vfx(i)*rx(i+1,j,k))*vwx(i)
       enddo
       sx(j,k)=(   tx(1,j,k)-fvalx*tx(nx,j,k))/&
            (1.+rx(1,j,k)-fvalx*rx(nx,j,k))
       do i=1,nx
          tx(i,j,k)=tx(i,j,k)-sx(j,k)*rx(i,j,k)
       enddo
    enddo
    enddo

    return  
end subroutine filxx_00
!*********************************************************************
!
subroutine filyy_00(ty,uy,ry,fvaly,fvajy,fvbjy,fvcjy,fvdjy,fvejy,&
                    sy,vfy,vsy,vwy,nx,ny,nz,npaire) 
!
!********************************************************************

USE param 

implicit none

integer :: nx,ny,nz,npaire,i,j,k 
real(mytype), dimension(nx,ny,nz) :: ty,uy,ry
real(mytype), dimension(nx,nz)    :: sy
real(mytype), dimension(ny)       :: vfy,vsy,vwy
real(mytype)                      :: fvaly,fvajy,fvbjy,fvcjy,fvdjy,fvejy

if(iibm.eq.2) call lagpoly(uy)

    do k=1,nz
    do i=1,nx
       ty(i,1,k)=fvajy*uy(i,1,k)+&
            fvbjy*(uy(i,2,k)+uy(i,ny,k))+&
            fvcjy*(uy(i,3,k)+uy(i,ny-1,k))+&
            fvdjy*(uy(i,4,k)+uy(i,ny-2,k))+&
            fvejy*(uy(i,5,k)+uy(i,ny-3,k))
       ry(i,1,k)=-1.
       ty(i,2,k)=fvajy*uy(i,2,k)+&
            fvbjy*(uy(i,3,k)+uy(i,1,k))+&
            fvcjy*(uy(i,4,k)+uy(i,ny,k))+ &
            fvdjy*(uy(i,5,k)+uy(i,ny-1,k))+&
            fvejy*(uy(i,6,k)+uy(i,ny-2,k))
       ry(i,2,k)=0.
       ty(i,3,k)=fvajy*uy(i,3,k)+&
            fvbjy*(uy(i,4,k)+uy(i,2,k))+&
            fvcjy*(uy(i,5,k)+uy(i,1,k))+&
            fvdjy*(uy(i,6,k)+uy(i,ny,k))+&
            fvejy*(uy(i,7,k)+uy(i,ny-1,k))
       ry(i,3,k)=0.
       ty(i,4,k)=fvajy*uy(i,4,k)+&
            fvbjy*(uy(i,5,k)+uy(i,3,k))+&
            fvcjy*(uy(i,6,k)+uy(i,2,k))+&
            fvdjy*(uy(i,7,k)+uy(i,1,k))+&
            fvejy*(uy(i,8,k)+uy(i,ny,k))
       ry(i,4,k)=0.
    enddo
    enddo
    do k=1,nz
    do j=5,ny-4
    do i=1,nx
       ty(i,j,k)=fvajy*uy(i,j,k)+&
            fvbjy*(uy(i,j+1,k)+uy(i,j-1,k))+&
            fvcjy*(uy(i,j+2,k)+uy(i,j-2,k))+&
            fvdjy*(uy(i,j+3,k)+uy(i,j-3,k))+&
            fvejy*(uy(i,j+4,k)+uy(i,j-4,k))
       ry(i,j,k)=0.
    enddo
    enddo
    enddo
    do k=1,nz
    do i=1,nx
       ty(i,ny-3,k)=fvajy*uy(i,ny-3,k)+&
            fvbjy*(uy(i,ny-2,k)+uy(i,ny-4,k))+&
            fvcjy*(uy(i,ny-1,k)+uy(i,ny-5,k))+&
            fvdjy*(uy(i,ny,k)+uy(i,ny-6,k))+&
            fvejy*(uy(i,1,k)+uy(i,ny-7,k))
       ry(i,ny-3,k)=0.
       ty(i,ny-2,k)=fvajy*uy(i,ny-2,k)+&
            fvbjy*(uy(i,ny-1,k)+uy(i,ny-3,k))+&
            fvcjy*(uy(i,ny,k)+uy(i,ny-4,k))+&
            fvdjy*(uy(i,1,k)+uy(i,ny-5,k))+&
            fvejy*(uy(i,2,k)+uy(i,ny-6,k))
       ry(i,ny-2,k)=0.
       ty(i,ny-1,k)=fvajy*uy(i,ny-1,k)+&
            fvbjy*(uy(i,ny,k)+uy(i,ny-2,k))+&
            fvcjy*(uy(i,1,k)+uy(i,ny-3,k))+&
            fvdjy*(uy(i,2,k)+uy(i,ny-4,k))+&
            fvejy*(uy(i,3,k)+uy(i,ny-5,k))
       ry(i,ny-1,k)=0.
       ty(i,ny  ,k)=fvajy*uy(i,ny,k)+&
            fvbjy*(uy(i,1,k)+uy(i,ny-1,k))+&
            fvcjy*(uy(i,2,k)+uy(i,ny-2,k))+&
            fvdjy*(uy(i,3,k)+uy(i,ny-3,k))+&
            fvejy*(uy(i,4,k)+uy(i,ny-4,k))
       ry(i,ny  ,k)=fvaly
    enddo
    enddo
    do k=1,nz
    do j=2,ny
    do i=1,nx
       ty(i,j,k)=ty(i,j,k)-ty(i,j-1,k)*vsy(j)
       ry(i,j,k)=ry(i,j,k)-ry(i,j-1,k)*vsy(j)
    enddo
    enddo
    enddo
    do k=1,nz
    do i=1,nx
       ty(i,ny,k)=ty(i,ny,k)*vwy(ny)
       ry(i,ny,k)=ry(i,ny,k)*vwy(ny)
    enddo
    enddo
    do k=1,nz
    do j=ny-1,1,-1
    do i=1,nx
       ty(i,j,k)=(ty(i,j,k)-vfy(j)*ty(i,j+1,k))*vwy(j)
       ry(i,j,k)=(ry(i,j,k)-vfy(j)*ry(i,j+1,k))*vwy(j)
    enddo
    enddo
    enddo
    do k=1,nz
    do i=1,nx
       sy(i,k)=(   ty(i,1,k)-fvaly*ty(i,ny,k))/&
            (1.+ry(i,1,k)-fvaly*ry(i,ny,k))
    enddo
    enddo   
    do k=1,nz
    do j=1,ny     
    do i=1,nx
       ty(i,j,k)=ty(i,j,k)-sy(i,k)*ry(i,j,k)
    enddo
    enddo
    enddo

    return  
end subroutine filyy_00
!*********************************************************************
!*********************************************************************
!
subroutine filzz_00(tz,uz,rz,fvalz,fvaiz,fvbiz,fvciz,fvdiz,fveiz,&
                    sz,vfz,vsz,vwz,nx,ny,nz,npaire) 
!
!********************************************************************

USE param 

implicit none

integer :: nx,ny,nz,npaire,i,j,k
real(mytype), dimension(nx,ny,nz) :: tz,uz,rz
real(mytype), dimension(nx,ny)    :: sz 
real(mytype), dimension(nz)       :: vfz,vsz,vwz
real(mytype)                      :: fvalz,fvaiz,fvbiz,fvciz,fvdiz,fveiz

if(iibm.eq.2) call lagpolz(uz)

    do j=1,ny
    do i=1,nx
       tz(i,j,1)=fvaiz*uz(i,j,1)+&
            fvbiz*(uz(i,j,2)+uz(i,j,nz))+&
            fvciz*(uz(i,j,3)+uz(i,j,nz-1))+&
            fvdiz*(uz(i,j,4)+uz(i,j,nz-2))+&
            fveiz*(uz(i,j,5)+uz(i,j,nz-3))
       rz(i,j,1)=-1.
       tz(i,j,2)=fvaiz*uz(i,j,2)+&
            fvbiz*(uz(i,j,3)+uz(i,j,1))+ &
            fvciz*(uz(i,j,4)+uz(i,j,nz))+&
            fvdiz*(uz(i,j,5)+uz(i,j,nz-1))+&
            fveiz*(uz(i,j,6)+uz(i,j,nz-2))
       rz(i,j,2)=0.
       tz(i,j,3)=fvaiz*uz(i,j,3)+&
            fvbiz*(uz(i,j,4)+uz(i,j,2))+&
            fvciz*(uz(i,j,5)+uz(i,j,1))+&
            fvdiz*(uz(i,j,6)+uz(i,j,nz))+&
            fveiz*(uz(i,j,7)+uz(i,j,nz-1))
       rz(i,j,3)=0.
       tz(i,j,4)=fvaiz*uz(i,j,4)+&
            fvbiz*(uz(i,j,5)+uz(i,j,3))+&
            fvciz*(uz(i,j,6)+uz(i,j,2))+&
            fvdiz*(uz(i,j,7)+uz(i,j,1))+&
            fveiz*(uz(i,j,8)+uz(i,j,nz))
       rz(i,j,4)=0.
    enddo
    enddo
    do k=5,nz-4
    do j=1,ny
    do i=1,nx
       tz(i,j,k)=fvaiz*uz(i,j,k)+&
            fvbiz*(uz(i,j,k+1)+uz(i,j,k-1))+&
            fvciz*(uz(i,j,k+2)+uz(i,j,k-2))+&
            fvdiz*(uz(i,j,k+3)+uz(i,j,k-3))+&
            fveiz*(uz(i,j,k+4)+uz(i,j,k-4))
       rz(i,j,k)=0.
    enddo
    enddo
    enddo
    do j=1,ny
    do i=1,nx
       tz(i,j,nz-3)=fvaiz*uz(i,j,nz-3)+&
            fvbiz*(uz(i,j,nz-2)+uz(i,j,nz-4))+&
            fvciz*(uz(i,j,nz-1)+uz(i,j,nz-5))+&
            fvdiz*(uz(i,j,nz)+uz(i,j,nz-6))+&
            fveiz*(uz(i,j,1)+uz(i,j,nz-7))
       rz(i,j,nz-3)=0.
       tz(i,j,nz-2)=fvaiz*uz(i,j,nz-2)+&
            fvbiz*(uz(i,j,nz-1)+uz(i,j,nz-3))+&
            fvciz*(uz(i,j,nz)+uz(i,j,nz-4))+&
            fvdiz*(uz(i,j,1)+uz(i,j,nz-5))+&
            fveiz*(uz(i,j,2)+uz(i,j,nz-6))
       rz(i,j,nz-2)=0.
       tz(i,j,nz-1)=fvaiz*uz(i,j,nz-1)+&
            fvbiz*(uz(i,j,nz)+uz(i,j,nz-2))+&
            fvciz*(uz(i,j,1)+uz(i,j,nz-3))+&
            fvdiz*(uz(i,j,2)+uz(i,j,nz-4))+&
            fveiz*(uz(i,j,3)+uz(i,j,nz-5))
       rz(i,j,nz-1)=0.
       tz(i,j,nz  )=fvaiz*uz(i,j,nz)+&
            fvbiz*(uz(i,j,1)+uz(i,j,nz-1))+&
            fvciz*(uz(i,j,2)+uz(i,j,nz-2))+&
            fvdiz*(uz(i,j,3)+uz(i,j,nz-3))+&
            fveiz*(uz(i,j,4)+uz(i,j,nz-4))
       rz(i,j,nz  )=fvalz
    enddo
    enddo
    do k=2,nz
    do j=1,ny
    do i=1,nx
       tz(i,j,k)=tz(i,j,k)-tz(i,j,k-1)*vsz(k)
       rz(i,j,k)=rz(i,j,k)-rz(i,j,k-1)*vsz(k)
    enddo
    enddo
    enddo
    do j=1,ny
    do i=1,nx
       tz(i,j,nz)=tz(i,j,nz)*vwz(nz)
       rz(i,j,nz)=rz(i,j,nz)*vwz(nz)
    enddo
    enddo
    do k=nz-1,1,-1
    do j=1,ny
    do i=1,nx
       tz(i,j,k)=(tz(i,j,k)-vfz(k)*tz(i,j,k+1))*vwz(k)
       rz(i,j,k)=(rz(i,j,k)-vfz(k)*rz(i,j,k+1))*vwz(k)
    enddo
    enddo
    enddo
    do j=1,ny
    do i=1,nx
       sz(i,j)=(   tz(i,j,1)-fvalz*tz(i,j,nz))/&
            (1.+rz(i,j,1)-fvalz*rz(i,j,nz))
    enddo
    enddo
    do k=1,nz
    do j=1,ny
    do i=1,nx
       tz(i,j,k)=tz(i,j,k)-sz(i,j)*rz(i,j,k)
    enddo
    enddo
    enddo

    return  
end subroutine filzz_00
!*********************************************************************
