!**************************************************************************
! This computer software was prepared by Battelle Memorial Institute, hereinafter
! the Contractor, under Contract No. DE-AC05-76RL0 1830 with the Department of 
! Energy (DOE). NEITHER THE GOVERNMENT NOR THE CONTRACTOR MAKES ANY WARRANTY,
! EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
!
! CBMZ module: see module_cbmz.F for references and terms of use
!**********************************************************************************  

MODULE module_cbmz_addemiss
!WRF:MODEL_LAYER:CHEMICS

!lm Louis Marelle 2016/5/9:  Add anthropogenic isoprene emissions to CBMZ, 
                          !  for emiss_inpt other than 1 or 102

   integer, parameter :: cbmz_addemiss_masscheck = -1
                       ! only do emissions masscheck calcs when this is positive



CONTAINS



!----------------------------------------------------------------------
   subroutine cbmz_addemiss_anthro( id, dtstep, dz8w, config_flags,       &
               rho_phy, chem,emis_ant,alt,                                &
               ids,ide, jds,jde, kds,kde,                                 &
               ims,ime, jms,jme, kms,kme,                                 &
               its,ite, jts,jte, kts,kte                                  )
!
! adds emissions for cbmz trace gas species
! (i.e., emissions tendencies over time dtstep are applied 
! to the trace gas concentrations)
!

  USE module_configure
  USE module_state_description
  USE module_data_radm2

  IMPLICIT NONE

   TYPE(grid_config_rec_type),  INTENT(IN   )    :: config_flags

   INTEGER,      INTENT(IN   ) :: id,                                      &
                                  ids,ide, jds,jde, kds,kde,               &
                                  ims,ime, jms,jme, kms,kme,               &
                                  its,ite, jts,jte, kts,kte

   REAL, INTENT(IN   ) ::    dtstep

! trace species mixing ratios (gases=ppm)
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme, num_chem ),                 &
         INTENT(INOUT ) ::   chem
!
! emissions arrays (v.1: ppm m/min; v.2: mole km^-2 hr^-1)
!
!   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                          &
   REAL, DIMENSION( ims:ime, kms:config_flags%kemit, jms:jme,num_emis_ant),&
         INTENT(IN ) ::                                                    &
                         emis_ant
! layer thickness (m)
   REAL,  DIMENSION( ims:ime , kms:kme , jms:jme )         ,               &
          INTENT(IN   ) ::   dz8w, rho_phy,alt

! local variables
   integer :: i,j,k
   real, parameter :: efact1 = 1.0/60.0
   real :: conv,conv3
   double precision :: chem_sum(num_chem)


! do mass check initial calc
      if (cbmz_addemiss_masscheck > 0) call addemiss_masscheck(               &
               id, config_flags, 1, 'cbmz_addemiss',                          &
               dtstep, efact1, dz8w, chem, chem_sum,                          &
               ids,ide, jds,jde, kds,kde,                                     &
               ims,ime, jms,jme, kms,kme,                                     &
               its,ite, jts,jte, kts,kte,                                     &
               21,                                                            &
               emis_ant(ims,kms,jms,p_e_so2),emis_ant(ims,kms,jms,p_e_no),    &
               emis_ant(ims,kms,jms,p_e_co),emis_ant(ims,kms,jms,p_e_eth),    &
               emis_ant(ims,kms,jms,p_e_hc3),emis_ant(ims,kms,jms,p_e_hc5),   &
               emis_ant(ims,kms,jms,p_e_hc8),emis_ant(ims,kms,jms,p_e_xyl),   &
               emis_ant(ims,kms,jms,p_e_ol2),emis_ant(ims,kms,jms,p_e_olt),   &
               emis_ant(ims,kms,jms,p_e_oli),emis_ant(ims,kms,jms,p_e_tol),   &
               emis_ant(ims,kms,jms,p_e_csl),emis_ant(ims,kms,jms,p_e_hcho),  &
               emis_ant(ims,kms,jms,p_e_ald),emis_ant(ims,kms,jms,p_e_ket),   &
               emis_ant(ims,kms,jms,p_e_ora2),emis_ant(ims,kms,jms,p_e_nh3),  &
               emis_ant(ims,kms,jms,p_e_no2),emis_ant(ims,kms,jms,p_e_ch3oh), &
               emis_ant(ims,kms,jms,p_e_c2h5oh))



!       
! add emissions
!
      do 100 j=jts,jte  
      do 100 i=its,ite  

      DO k=kts,min(config_flags%kemit,kte)
!v1 units:        conv = dtstep/(dz8w(i,k,j)*60.)
!v2 units:
        conv = 4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
        conv3 = (dtstep/dz8w(i,k,j))*alt(i,k,j)*28/250*1e-3

#if (defined(CHEM_DBG_I) && defined(CHEM_DBG_J) && defined(CHEM_DBG_K))
       if( (i <= CHEM_DBG_I .and. i >= CHEM_DBG_I) .and. &
           (j <= CHEM_DBG_J .and. j >= CHEM_DBG_J) .and. &
           (k <= CHEM_DBG_K .and. k >= CHEM_DBG_K)  ) then
          print*
          print*,"Converted emissions for CBMZ:"
          print*,"e_csl=",emis_ant(i,k,j,p_e_csl)*conv
          print*,"e_so2=",emis_ant(i,k,j,p_e_so2)*conv
          print*,"e_no=",emis_ant(i,k,j,p_e_no)*conv
          print*,"e_ald=",emis_ant(i,k,j,p_e_ald)*conv
          print*,"e_hcho=",emis_ant(i,k,j,p_e_hcho)*conv
          print*,"e_ora2=",emis_ant(i,k,j,p_e_ora2)*conv
          print*,"e_nh3=",emis_ant(i,k,j,p_e_nh3)*conv
          print*,"e_hc3=",emis_ant(i,k,j,p_e_hc3)*conv
          print*,"e_hc5=",emis_ant(i,k,j,p_e_hc5)*conv
          print*,"e_hc8=",emis_ant(i,k,j,p_e_hc8)*conv
          print*,"e_eth=",emis_ant(i,k,j,p_e_eth)*conv
          print*,"e_co=",emis_ant(i,k,j,p_e_co)*conv
          print*,"e_ol2=",emis_ant(i,k,j,p_e_ol2)*conv
          print*,"e_olt=",emis_ant(i,k,j,p_e_olt)*conv
          print*,"e_oli=",emis_ant(i,k,j,p_e_oli)*conv
          print*,"e_tol=",emis_ant(i,k,j,p_e_tol)*conv
          print*,"e_xyl=",emis_ant(i,k,j,p_e_xyl)*conv
          print*,"e_ket=",emis_ant(i,k,j,p_e_ket)*conv
!jcr
          print*,"e_no2=",emis_ant(i,k,j,p_e_no2)*conv
          print*,"e_ch3oh=",emis_ant(i,k,j,p_e_ch3oh)*conv
          print*,"e_c2h5oh=",emis_ant(i,k,j,p_e_c2h5oh)*conv
          print*,"e_iso=",emis_ant(i,k,j,p_e_iso)*conv
!jcr
       end if
#endif

        chem(i,k,j,p_csl)  =  chem(i,k,j,p_csl)                        &
                         +emis_ant(i,k,j,p_e_csl)*conv 
        chem(i,k,j,p_so2)  = chem(i,k,j,p_so2)                         &
                         +emis_ant(i,k,j,p_e_so2)*conv
        chem(i,k,j,p_no)   = chem(i,k,j,p_no)                          &
                         +emis_ant(i,k,j,p_e_no)*conv
        chem(i,k,j,p_ald)  = chem(i,k,j,p_ald)                         &
                         +emis_ant(i,k,j,p_e_ald)*conv
        chem(i,k,j,p_hcho) = chem(i,k,j,p_hcho)                        &
                         +emis_ant(i,k,j,p_e_hcho)*conv
        chem(i,k,j,p_ora2)  = chem(i,k,j,p_ora2)                       &
                         +emis_ant(i,k,j,p_e_ora2)*conv 
        chem(i,k,j,p_nh3)  = chem(i,k,j,p_nh3)                         &
                         +emis_ant(i,k,j,p_e_nh3)*conv
        chem(i,k,j,p_eth)  = chem(i,k,j,p_eth)                         &
                         +emis_ant(i,k,j,p_e_eth)*conv
        chem(i,k,j,p_co)  = chem(i,k,j,p_co)                           &
                         +emis_ant(i,k,j,p_e_co)*conv
        chem(i,k,j,p_ol2)  = chem(i,k,j,p_ol2)                         &
                         +emis_ant(i,k,j,p_e_ol2)*conv
        chem(i,k,j,p_olt)  = chem(i,k,j,p_olt)                         &
                         +emis_ant(i,k,j,p_e_olt)*conv
        chem(i,k,j,p_oli)  = chem(i,k,j,p_oli)                         &
                         +emis_ant(i,k,j,p_e_oli)*conv
        chem(i,k,j,p_tol)  = chem(i,k,j,p_tol)                         &
                         +emis_ant(i,k,j,p_e_tol)*conv
        chem(i,k,j,p_xyl)  = chem(i,k,j,p_xyl)                         &
                         +emis_ant(i,k,j,p_e_xyl)*conv       
        chem(i,k,j,p_ket)  =  chem(i,k,j,p_ket)                        &
                         +emis_ant(i,k,j,p_e_ket)*conv      
!jcr
        chem(i,k,j,p_no2)  =  chem(i,k,j,p_no2)                        &
                         +emis_ant(i,k,j,p_e_no2)*conv
        chem(i,k,j,p_ch3oh)  =  chem(i,k,j,p_ch3oh)                    &
                         +emis_ant(i,k,j,p_e_ch3oh)*conv
        chem(i,k,j,p_c2h5oh)  =  chem(i,k,j,p_c2h5oh)                  &
                         +emis_ant(i,k,j,p_e_c2h5oh)*conv
        chem(i,k,j,p_iso)  =  chem(i,k,j,p_iso)                        &
                         +emis_ant(i,k,j,p_e_iso)*conv
!jcr

         chem_select_2 : SELECT CASE( config_flags%chem_opt )

         END SELECT  chem_select_2


 

! when emissions input file is "radm2sorg" variety, calc par emissions as a 
!   combination of the anthropogenic emissions for radm2 primary voc species
        if ( (config_flags%emiss_inpt_opt == EMISS_INPT_DEFAULT) .or.   &
             (config_flags%emiss_inpt_opt == EMISS_INPT_PNNL_RS) ) then
            chem(i,k,j,p_par) = chem(i,k,j,p_par)             &
                + conv*                                       &
                  ( 0.4*emis_ant(i,k,j,p_e_ald) + 2.9*emis_ant(i,k,j,p_e_hc3)       &
                  + 4.8*emis_ant(i,k,j,p_e_hc5) + 7.9*emis_ant(i,k,j,p_e_hc8)       &
                  + 0.9*emis_ant(i,k,j,p_e_ket) + 2.8*emis_ant(i,k,j,p_e_oli)       &
                  + 1.8*emis_ant(i,k,j,p_e_olt) + 1.0*emis_ant(i,k,j,p_e_ora2) )

! when emissions input file is "cbmzmosaic" variety, 
!   the par emissions are read into e_hc5
!   and there are emissions for other species
        else
            chem(i,k,j,p_par) = chem(i,k,j,p_par)             &
                + conv*emis_ant(i,k,j,p_e_hc5)

            chem(i,k,j,p_no2) = chem(i,k,j,p_no2)             &
                + conv*emis_ant(i,k,j,p_e_no2)
            chem(i,k,j,p_ch3oh)  = chem(i,k,j,p_ch3oh)        &
                + conv*emis_ant(i,k,j,p_e_ch3oh)
            chem(i,k,j,p_c2h5oh) = chem(i,k,j,p_c2h5oh)       &
                + conv*emis_ant(i,k,j,p_e_c2h5oh)
!lm Add anthropogenic isoprene emissions to CBMZ, for emiss_inpt other than 1 or 102
            chem(i,k,j,p_iso)  =  chem(i,k,j,p_iso)           &
                +emis_ant(i,k,j,p_e_iso)*conv
!lm
        end if

        !BSINGH(01/24/2013): Added for DMS emissions
        !PMA DMS emission [added by BSINGH - 01/20/2014]        
        if ( (config_flags%emiss_inpt_opt == EMISS_INPT_PNNL_MAM)) then
           chem(i,k,j,p_dms) = chem(i,k,j,p_dms)             &
                + conv*emis_ant(i,k,j,p_e_dms)
        end if

      END DO                                                          
 100  continue


! do mass check final calc
      if (cbmz_addemiss_masscheck > 0) call addemiss_masscheck(               &
               id, config_flags, 2, 'cbmz_addemiss',                          &
               dtstep, efact1, dz8w, chem, chem_sum,                          &
               ids,ide, jds,jde, kds,kde,                                     &
               ims,ime, jms,jme, kms,kme,                                     &
               its,ite, jts,jte, kts,kte,                                     &
               21,                                                            &
               emis_ant(ims,kms,jms,p_e_so2),emis_ant(ims,kms,jms,p_e_no),    &
               emis_ant(ims,kms,jms,p_e_co),emis_ant(ims,kms,jms,p_e_eth),    &
               emis_ant(ims,kms,jms,p_e_hc3),emis_ant(ims,kms,jms,p_e_hc5),   &
               emis_ant(ims,kms,jms,p_e_hc8),emis_ant(ims,kms,jms,p_e_xyl),   &
               emis_ant(ims,kms,jms,p_e_ol2),emis_ant(ims,kms,jms,p_e_olt),   &
               emis_ant(ims,kms,jms,p_e_oli),emis_ant(ims,kms,jms,p_e_tol),   &
               emis_ant(ims,kms,jms,p_e_csl),emis_ant(ims,kms,jms,p_e_hcho),  &
               emis_ant(ims,kms,jms,p_e_ald),emis_ant(ims,kms,jms,p_e_ket),   &
               emis_ant(ims,kms,jms,p_e_ora2),emis_ant(ims,kms,jms,p_e_nh3),  &
               emis_ant(ims,kms,jms,p_e_no2),emis_ant(ims,kms,jms,p_e_ch3oh), &
               emis_ant(ims,kms,jms,p_e_c2h5oh))


   END subroutine cbmz_addemiss_anthro



!----------------------------------------------------------------------
  subroutine cbmz_addemiss_bio( id, dtstep, dz8w, config_flags,       &
        rho_phy, chem, e_bio, ne_area, e_iso,                         &
        ids,ide, jds,jde, kds,kde,                                    &
        ims,ime, jms,jme, kms,kme,                                    &
        its,ite, jts,jte, kts,kte                                     )

  USE module_configure
  USE module_state_description
  USE module_data_radm2
  USE module_aerosols_sorgam

  IMPLICIT NONE

! subr arguments
   TYPE(grid_config_rec_type),  INTENT(IN   )    :: config_flags

   INTEGER,      INTENT(IN   ) :: id, ne_area,                             &
                                  ids,ide, jds,jde, kds,kde,               &
                                  ims,ime, jms,jme, kms,kme,               &
                                  its,ite, jts,jte, kts,kte

   REAL,      INTENT(IN   ) ::    dtstep

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme, num_chem ),                 &
         INTENT(INOUT ) ::        chem

   REAL, DIMENSION( ims:ime, jms:jme,ne_area ),                            &
         INTENT(IN ) ::           e_bio
         
   REAL, DIMENSION( ims:ime, kms:config_flags%kemit, jms:jme ),            &
         INTENT(IN ) ::           e_iso

   REAL,  DIMENSION( ims:ime , kms:kme , jms:jme )         ,               &
          INTENT(IN   ) ::        dz8w, rho_phy            


! local variables
   integer i,j,k,n
   real, parameter :: efact1 = 1.0/60.0
   double precision :: chem_sum(num_chem)


!
! apply gunther online biogenic gas emissions when bio_emiss_opt == GUNTHER1
!
   if (config_flags%bio_emiss_opt == GUNTHER1) then

      if (cbmz_addemiss_masscheck > 0) call addemiss_masscheck(         &
               id, config_flags, 1, 'cbmz_addemiss_bioaa',              &
               dtstep, efact1, dz8w, chem, chem_sum,                    &
               ids,ide, jds,jde, kds,kde,                               &
               ims,ime, jms,jme, kms,kme,                               &
               its,ite, jts,jte, kts,kte,                               &
               13,                                                      &
               e_bio(ims,jms,lald),  e_bio(ims,jms,lhc3),               &
               e_bio(ims,jms,lhc5),  e_bio(ims,jms,lhc8),               &
               e_bio(ims,jms,lhcho), e_bio(ims,jms,liso),               &
               e_bio(ims,jms,lket),  e_bio(ims,jms,lno),                &
               e_bio(ims,jms,loli),  e_bio(ims,jms,lolt),               &
               e_bio(ims,jms,lora1), e_bio(ims,jms,lora2),              &
               e_bio(ims,jms,lxyl),                                     &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl),               &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl),               &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl),               &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl)                )

      do j=jts,jte  
      do i=its,ite  
        chem(i,kts,j,p_so2) = chem(i,kts,j,p_so2)    &
                          + e_bio(i,j,lso2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_sulf) = chem(i,kts,j,p_sulf)    &
                          + e_bio(i,j,lsulf)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_no2) = chem(i,kts,j,p_no2)    &
                          + e_bio(i,j,lno2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_no) = chem(i,kts,j,p_no)    &
                          + e_bio(i,j,lno)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_o3) = chem(i,kts,j,p_o3)    &
                          + e_bio(i,j,lo3)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_hno3) = chem(i,kts,j,p_hno3)    &
                          + e_bio(i,j,lhno3)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_h2o2) = chem(i,kts,j,p_h2o2)    &
                          + e_bio(i,j,lh2o2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_ald) = chem(i,kts,j,p_ald)    &
                          + e_bio(i,j,lald)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_hcho) = chem(i,kts,j,p_hcho)    &
                          + e_bio(i,j,lhcho)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_op1) = chem(i,kts,j,p_op1)    &
                          + e_bio(i,j,lop1)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_op2) = chem(i,kts,j,p_op2)    &
                          + e_bio(i,j,lop2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_ora1) = chem(i,kts,j,p_ora1)    &
                          + e_bio(i,j,lora1)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_ora2) = chem(i,kts,j,p_ora2)    &
                          + e_bio(i,j,lora2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_nh3) = chem(i,kts,j,p_nh3)    &
                          + e_bio(i,j,lnh3)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_n2o5) = chem(i,kts,j,p_n2o5)    &
                          + e_bio(i,j,ln2o5)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_no2) = chem(i,kts,j,p_no2)    &
                          + e_bio(i,j,lno2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_pan) = chem(i,kts,j,p_pan)    &
                          + e_bio(i,j,lpan)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_eth) = chem(i,kts,j,p_eth)    &
                          + e_bio(i,j,leth)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_co) = chem(i,kts,j,p_co)    &
                          + e_bio(i,j,lco)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_ol2) = chem(i,kts,j,p_ol2)    &
                          + e_bio(i,j,lol2)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_olt) = chem(i,kts,j,p_olt)    &
                          + e_bio(i,j,lolt)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_oli) = chem(i,kts,j,p_oli)    &
                          + e_bio(i,j,loli)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_tol) = chem(i,kts,j,p_tol)    &
                          + e_bio(i,j,ltol)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_xyl) = chem(i,kts,j,p_xyl)    &
                          + e_bio(i,j,lxyl)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_hono) = chem(i,kts,j,p_hono)    &
                          + e_bio(i,j,lhono)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_hno4) = chem(i,kts,j,p_hno4)    &
                          + e_bio(i,j,lhno4)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_ket) = chem(i,kts,j,p_ket)    &
                          + e_bio(i,j,lket)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_mgly) = chem(i,kts,j,p_mgly)    &
                          + e_bio(i,j,lmgly)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_onit) = chem(i,kts,j,p_onit)    &
                          + e_bio(i,j,lonit)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_csl) = chem(i,kts,j,p_csl)    &
                          + e_bio(i,j,lcsl)/(dz8w(i,kts,j)*60.)*dtstep
        chem(i,kts,j,p_iso) = chem(i,kts,j,p_iso)    &
                          + e_bio(i,j,liso)/(dz8w(i,kts,j)*60.)*dtstep
      end do
      end do

! calc par emissions as a combination of the biogenic emissions
! for radm2 primary voc species
      do j = jts, jte
      do i = its, ite
         chem(i,kts,j,p_par)  =  chem(i,kts,j,p_par)               &
             + (dtstep/(dz8w(i,kts,j)*60.))*                       &
               ( 0.4*e_bio(i,j,lald) + 2.9*e_bio(i,j,lhc3)         &
               + 4.8*e_bio(i,j,lhc5) + 7.9*e_bio(i,j,lhc8)         &
               + 0.9*e_bio(i,j,lket) + 2.8*e_bio(i,j,loli)         &
               + 1.8*e_bio(i,j,lolt) + 1.0*e_bio(i,j,lora2)        )
      end do
      end do

      if (cbmz_addemiss_masscheck > 0) call addemiss_masscheck(         &
               id, config_flags, 2, 'cbmz_addemiss_bioaa',              &
               dtstep, efact1, dz8w, chem, chem_sum,                    &
               ids,ide, jds,jde, kds,kde,                               &
               ims,ime, jms,jme, kms,kme,                               &
               its,ite, jts,jte, kts,kte,                               &
               13,                                                      &
               e_bio(ims,jms,lald),  e_bio(ims,jms,lhc3),               &
               e_bio(ims,jms,lhc5),  e_bio(ims,jms,lhc8),               &
               e_bio(ims,jms,lhcho), e_bio(ims,jms,liso),               &
               e_bio(ims,jms,lket),  e_bio(ims,jms,lno),                &
               e_bio(ims,jms,loli),  e_bio(ims,jms,lolt),               &
               e_bio(ims,jms,lora1), e_bio(ims,jms,lora2),              &
               e_bio(ims,jms,lxyl),                                     &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl),               &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl),               &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl),               &
               e_bio(ims,jms,lxyl),  e_bio(ims,jms,lxyl)                )

   end if


!
! apply offline isoprene emissions when bio_emiss_opt /= GUNTHER1
!
   if (config_flags%bio_emiss_opt /= GUNTHER1) then

      if (cbmz_addemiss_masscheck > 0) call addemiss_masscheck(            &
               id, config_flags, 1, 'cbmz_addemiss_biobb',                 &
               dtstep, efact1, dz8w, chem, chem_sum,                       &
               ids,ide, jds,jde, kds,kde,                                  &
               ims,ime, jms,jme, kms,kme,                                  &
               its,ite, jts,jte, kts,kte,                                  &
               1,                                                          &
               e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,                  &
               e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,                  &
               e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,e_iso                   )

      do j = jts, jte
      do k = kts, min(config_flags%kemit,kte)
      do i = its, ite
         chem(i,k,j,p_iso) = chem(i,k,j,p_iso) + e_iso(i,k,j)              &
              *4.828e-4/rho_phy(i,k,j)*(dtstep/(dz8w(i,k,j)*60.))
      end do
      end do
      end do

      if (cbmz_addemiss_masscheck > 0) call addemiss_masscheck(            &
               id, config_flags, 2, 'cbmz_addemiss_biobb',                 &
               dtstep, efact1, dz8w, chem, chem_sum,                       &
               ids,ide, jds,jde, kds,kde,                                  &
               ims,ime, jms,jme, kms,kme,                                  &
               its,ite, jts,jte, kts,kte,                                  &
               1,                                                          &
               e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,                  &
               e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,                  &
               e_iso,e_iso,e_iso,e_iso,e_iso,e_iso,e_iso                   )

   end if


   END subroutine cbmz_addemiss_bio


END MODULE module_cbmz_addemiss



