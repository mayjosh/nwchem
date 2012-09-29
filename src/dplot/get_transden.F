c
c        construct the transition density
         logical function get_transden(iroot,ipol,filename,basis,
     &        g_movecs, g_dens)
c
         implicit none
c
#include "errquit.fh"
#include "global.fh"
#include "tcgmsg.fh"
#include "msgtypesf.h"
#include "mafdecls.fh"
#include "msgids.fh"
#include "inp.fh"
#include "util.fh"
#include "stdio.fh"
#include "bas.fh"
#include "geom.fh"
c
         integer iroot
         integer ipol
         character*80 filename
         integer basis         ! AO basis set handle
         integer g_movecs(ipol)   ! MO vectors
         integer g_dens(ipol)     ! Number of AO basis functions
c
         integer i,m,n
         logical tda
         integer nroots
         integer nocc(2)
         integer nmo(2)
         integer nfc(2)
         integer nfv(2)
         integer nov(2)
         double precision r
         integer nbf_ao
c
         logical nodezero
c
         integer g_x(2),g_y(2)
         integer g_temp(2)
c
         integer inntsize,ddblsize,logisize,ok
c
         logical bas_numbf
         external bas_numbf
c
         character*32 pname
         pname = 'get_transden: '
c
c        preliminaries
         inntsize=MA_sizeof(MT_INT,1,MT_BYTE)
         ddblsize=MA_sizeof(MT_DBL,1,MT_BYTE)
         logisize=MA_sizeof(MT_LOG,1,MT_BYTE)
         ok = 0
         nodezero=(ga_nodeid().eq.0)
         if (.not.bas_numbf(basis,nbf_ao))
     &      call errquit(pname//'bas_numbf failed',0,0)
c
         do i=1,ipol
	   call ga_zero(g_dens(i))
         end do ! ipol
c
c        Read header information from civecs file
         if (nodezero) then      
           open(unit=69,file=filename,form='formatted',
     &          status='unknown',err=1000)
            rewind(69)
            read(69,*,err=1001) tda
            read(69,*,err=1001) ipol
            read(69,*,err=1001) nroots
            read(69,*,err=1001) nocc(1),nocc(2)
            read(69,*,err=1001) nmo(1),nmo(2)
            read(69,*,err=1001) nfc(1),nfc(2)
            read(69,*,err=1001) nfv(1),nfv(2)
            read(69,*,err=1001) nov(1),nov(2)
c
            do i=1,ipol
             nov(i)=(nmo(i)-nfv(i)-nocc(i))*(nocc(i)-nfc(i))
            end do ! ipol
            if (ipol.eq.1) nov(2)=0
           close(unit=69,status='keep',err=1002) ! file
           ok = 1
         end if ! nodezero
c
c        broadcast status and variables to other nodes
         call ga_brdcst(Msg_Vec_Stat+MSGINT, ok, inntsize, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT, tda, logisize, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT,ipol, inntsize, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT,nroots, inntsize, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT, nocc, inntsize*2, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT, nmo, inntsize*2, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT, nfc, inntsize*2, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT, nfv, inntsize*2, 0)
         call ga_brdcst(Msg_Vec_NMO+MSGINT, nov, inntsize*2, 0)
         call ga_sync()
c
c        Set up X, Y vectors and transition density matrices
         do i=1,ipol
            if (.not.ga_create(mt_dbl,nov(i),nroots,'X vector',
     1        -1,-1,g_x(i))) call errquit
     2       (pname//'failed to create g_x',0, GA_ERR)
             call ga_zero(g_x(i))
             if (.not.ga_create(mt_dbl,nbf_ao,nbf_ao,'temp',
     1        -1,-1,g_temp(i))) call errquit
     2       (pname//'failed to create g_temp',0, GA_ERR)
             call ga_zero(g_temp(i))
c
             if (.not.tda) then
              if (.not.ga_create(mt_dbl,nov(i),nroots,'Y vector',
     1          -1,-1,g_y(i))) call errquit
     2          (pname//'failed to create g_y',0, GA_ERR)
              call ga_zero(g_y(i))
             end if ! .not. tda
         end do  ! ipol
c
c        Read remainder of the civecs file
         if (nodezero) then      
           open(unit=69,file=filename,form='formatted',
     &                status='unknown',err=1000)
            rewind(69)
            read(69,*,err=1001) tda
            read(69,*,err=1001) ipol
            read(69,*,err=1001) nroots
            read(69,*,err=1001) nocc(1),nocc(2)
            read(69,*,err=1001) nmo(1),nmo(2)
            read(69,*,err=1001) nfc(1),nfc(2)
            read(69,*,err=1001) nfv(1),nfv(2)
            read(69,*,err=1001) nov(1),nov(2)
c
            do n = 1,nroots
              do i=1,ipol
               if (tda) then
                 do m=1,nov(i)
                   read(69,*) r
                   call ga_put(g_x(i),m,m,n,n,r,1)
                 end do
               else
                 do m=1,nov(i)
                   read(69,*) r
                   call ga_put(g_x(i),m,m,n,n,r,1)
                 end do
                 do m=1,nov(i)
                   read(69,*) r
                   call ga_put(g_y(i),m,m,n,n,r,1)
                 end do
               end if  ! tda
              end do ! ipol
            end do ! nroots
           close(unit=69,status='keep',err=1002) ! file
           ok = 1
         end if  ! nodezero
c
 1000 call errquit(pname//'failed to open file',0,-1)
 1001 call errquit(pname//'failed to read file',0,-1)
 1002 call errquit(pname//'failed to close file',0,-1)
c
         call ga_brdcst(Msg_Vec_Stat+MSGINT, ok, inntsize, 0)
         call ga_sync()
c
c        calculate X component of the transition density matrix
         call tddft_transfm(iroot,g_x,g_movecs,nbf_ao,nocc,nmo,
     &             nfc,nfv,ipol,g_temp,1)  ! x-transition density
         do i = 1,ipol
              call ga_copy(g_temp(i),g_dens(i))
         end do
c
c        calculate Y component of the transition density matrix
         if (.not.tda) then
             call tddft_transfm(iroot,g_y,g_movecs,nbf_ao,nocc,nmo,
     &             nfc,nfv,ipol,g_temp,1)  ! y-transition density
c
c            accumulate the Y component of the transition density matrix
             do i = 1,ipol
              call ga_add(1.d0,g_dens(i),1.d0,g_temp(i),g_dens(i))
             end do
         end if  ! tda
c
c        consolidate the X and Y components
         if (ipol.gt.1)
     &        call ga_add(1.d0,g_dens(1),1.d0,g_dens(2),g_dens(1))

         do i=1,ipol
            if (.not.ga_destroy(g_x(i))) call errquit
     2       (pname//'failed to destroy g_x',0, GA_ERR)
            if (.not.ga_destroy(g_temp(i))) call errquit
     2       (pname//'failed to destroy g_temp',0, GA_ERR)
            if (.not.tda) then
              if (.not.ga_destroy(g_y(i))) call errquit
     2          (pname//'failed to destroy g_y',0, GA_ERR)
            end if ! tda
         enddo ! ipol
c
      return
      end