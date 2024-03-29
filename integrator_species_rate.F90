module integrator_species_rate
  use mphys_with_ice
  use microphysics_common, only: cv_mixture, cp_mixture
  use integrator_config, only: ice_graupel_processes

  implicit none

  logical, parameter :: debug_1 = .true.

  contains
    function dydt_mphys_with_ice(t, y) result(dydt)
       !use microphysics_register, only: idx_temp, idx_pressure
       !use microphysics_register, only: idx_cwater, idx_water_vapour, idx_rain, idx_cice, idx_graupel
       use microphysics_constants, only: temp0 => T0, L_v => L_cond, L_s => L_subl , L_f => L_fusi
       use mphys_with_ice

       real(kreal), dimension(:), intent(in) :: y
       real(kreal), intent(in) :: t
       real(kreal) :: dydt(size(y))

       real(kreal) :: ql, qv, qg, qr, qd, qi, qh
       real(kreal) :: rho, rho_g, c_m, c_p
       real(kreal) :: dqldt_condevap, dqrdt_condevap, dqhdt_condevap
       real(kreal) :: dqidt_sublidep, dqhdt_sublidep
       real(kreal) :: dqrdt_autoconv, dqhdt_autoconv
       real(kreal) :: dqrdt_accre_rc, dqhdt_accre_hi, dqldt_accre_chr
       real(kreal) :: dqhdt_accre_hiri, dqhdt_accre_hirr, dqhdt_accre_hr
       real(kreal) :: dqrdt_melt_rh, dqldt_melt_ci
       real(kreal) :: dqidt_freeze , dqhdt_freeze
       real(kreal) :: temp, p

       real(kreal) :: dydt_sum_check

       ! OBS: it's important to make sure that return variable is initiated to
       ! zero
       dydt(:) = 0.0_kreal

       temp = y(1)
       p = y(2)

       ! pick out specific concentrations from state vectors
       ql = y(3)           !idx_cwater
       qr = y(4)             !idx_rain
       qv = y(5)     !idx_water_vapour
       qi = y(6)             !idx_cice
       qh = y(7)          !idx_graupel
       qd = 1.0_kreal - ql - qr - qv - qi - qh
       qg = qv + qd

       ! compute gas and mixture density using equation of state
       rho = rho_f(qd, qv, ql, qr, qi, qh, p, temp)
       rho_g = rho_f(qd, qv, 0.0_kreal, 0.0_kreal, 0.0_kreal, 0.0_kreal, p, temp)

       ! compute heat capacity of mixture
       c_m = cv_mixture(y)

       ! compute time derivatives for each process TODO: Functions for each function

       if (ice_graupel_processes) then
         dqldt_condevap = dql_dt__condensation_evaporation(rho=rho, rho_g=rho_g, qv=qv, ql=ql, T=temp, p=p)
         dqrdt_condevap = dqr_dt__condensation_evaporation(qv=qv, qr=qr, rho=rho, T=temp, p=p)
         dqhdt_condevap = dqh_dt__condensation_evaporation(qv=qv, qh=qh, rho=rho, T=temp, p=p)
         dqidt_sublidep = dqi_dt__sublimation_deposition(qi=qi, qv=qv, rho=rho, T=temp, p=p)
         dqhdt_sublidep = dqh_dt__sublimation_evaporation(qg=qg, qv=qv, qh=qh, rho=rho, T=temp, p=p)
         dqrdt_autoconv = dqr_dt__autoconversion(ql=ql, qg=qg, rho_g=rho_g, T=temp, qv=qv, rho=rho)
         dqhdt_autoconv = dqh_dt__autoconversion_ice_graupel(qi=qi, qg=qg, rho_g=rho_g, T=temp)
         dqrdt_accre_rc = dqr_dt__accretion_cloud_rain(ql=ql, rho_g=rho_g, rho=rho, qr=qr)
         dqhdt_accre_hi = dqh_dt__accretion_ice_graupel(qi=qi, rho_g=rho_g, qh=qh, T=temp)
         dqldt_accre_chr= dqh_dt__accretion_cloud_graupel_rain(ql=ql, rho_g=rho_g, rho=rho, qh=qh, T=temp, qr=qr)
         dqhdt_accre_hiri= dqr_dt__accretion_ice_rain_graupel_i(qi=qi, rho_g=rho_g, rho=rho, qr=qr)
         dqhdt_accre_hirr= dqr_dt__accretion_ice_rain_graupel_r(qi=qi, ql=ql, rho=rho, rho_g=rho_g, qr=qr, T=temp)
         dqhdt_accre_hr = dqr_dt__accretion_graupel(qg=qg, rho_g=rho_g, qv=qv, qh=qh, rho=rho, T=temp, p=p, qr=qr, ql=ql)
         dqrdt_melt_rh  = dqr_dt__melting_graupel(qg=qg, rho_g=rho_g, qv=qv, qh=qh, rho=rho, T=temp, p=p, qr=qr, ql=ql)
         dqldt_melt_ci  = dqr_dt__melting_ice(qg=qg, rho_g=rho_g, qv=qv, qh=qh, rho=rho, T=temp, p=p, qr=qr, ql=ql, qi=qi)
         dqhdt_freeze   = dqh_dt__freezing_graupel(qh=qh, rho=rho, T=temp, qr=qr)
         dqidt_freeze   = dqi_dt__freezing_ice(ql=ql, rho=rho, T=temp, qv=qv, p=p)
       else
         dqldt_condevap = dql_dt__condensation_evaporation(rho=rho, rho_g=rho_g, qv=qv, ql=ql, T=temp, p=p)
         dqrdt_condevap = dqr_dt__condensation_evaporation(qv=qv, qr=qr, rho=rho, T=temp, p=p)
         dqhdt_condevap = 0.0_kreal
         dqidt_sublidep = 0.0_kreal
         dqhdt_sublidep = 0.0_kreal
         dqrdt_autoconv = dqr_dt__autoconversion(ql=ql, qg=qg, rho_g=rho_g, T=temp, qv=qv, rho=rho)
         dqhdt_autoconv = 0.0_kreal
         dqrdt_accre_rc = dqr_dt__accretion_cloud_rain(ql=ql, rho_g=rho_g, rho=rho, qr=qr)
         dqhdt_accre_hi = 0.0_kreal
         dqldt_accre_chr= 0.0_kreal
         dqhdt_accre_hiri= 0.0_kreal
         dqhdt_accre_hirr= 0.0_kreal
         dqhdt_accre_hr = 0.0_kreal
         dqrdt_melt_rh  = 0.0_kreal
         dqldt_melt_ci  = 0.0_kreal
         dqhdt_freeze   = 0.0_kreal
         dqidt_freeze   = 0.0_kreal
       endif

       ! combine to create time derivatives for species

       if (temp > temp0) then

         dydt(3) =  dqldt_condevap - dqrdt_autoconv &
                  - dqrdt_accre_rc &
                  - dqldt_accre_chr &
                  + dqldt_melt_ci
         dydt(4) =  dqrdt_condevap + dqrdt_autoconv &
                  + dqrdt_accre_rc &
                  + dqldt_accre_chr - dqhdt_accre_hirr &
                  + dqrdt_melt_rh
         dydt(5) = -dqldt_condevap - dqrdt_condevap - dqhdt_condevap &
                  - dqidt_sublidep - dqhdt_sublidep
         dydt(6) = dqidt_sublidep - dqhdt_autoconv &
                  - dqhdt_accre_hi - dqhdt_accre_hiri &
                  - dqldt_melt_ci
         dydt(7) = dqhdt_condevap + dqhdt_sublidep + dqhdt_autoconv &
                  + dqhdt_accre_hi + dqhdt_accre_hiri + dqhdt_accre_hirr &
                  - dqrdt_melt_rh

         dydt(1) = & !(y(2)/100000._kreal)**(0.28591_kreal) * &
                   (L_v/c_m*(dqldt_condevap + dqrdt_condevap + dqhdt_condevap) &
                 + L_s/c_m*(dqidt_sublidep + dqhdt_sublidep) &
                 + L_f/c_m*(dqldt_accre_chr + dqhdt_accre_hirr - dqrdt_melt_rh &
                 - dqldt_melt_ci))

       else

         dydt(3) =  dqldt_condevap - dqrdt_autoconv &
                  - dqrdt_accre_rc - dqldt_accre_chr &
                  + dqldt_melt_ci &

                  - dqidt_freeze

         dydt(4) =  dqrdt_condevap + dqrdt_autoconv &
                  + dqrdt_accre_rc - dqhdt_accre_hirr &
                  + dqrdt_melt_rh &

                  - dqhdt_freeze &
                  - dqhdt_accre_hr

         dydt(5) = -dqldt_condevap - dqrdt_condevap - dqhdt_condevap &
                  - dqidt_sublidep - dqhdt_sublidep
         dydt(6) = dqidt_sublidep - dqhdt_autoconv &
                  - dqhdt_accre_hi - dqhdt_accre_hiri &
                  - dqldt_melt_ci &

                  + dqidt_freeze
         dydt(7) = dqhdt_condevap + dqhdt_sublidep + dqhdt_autoconv &
                  + dqhdt_accre_hi + dqhdt_accre_hiri + dqhdt_accre_hirr &
                  - dqrdt_melt_rh &

                  + dqhdt_freeze &
                  + dqldt_accre_chr + dqhdt_accre_hr
         !print *,  dqhdt_accre_hirr

         dydt(1) = & !(y(2)/100000._kreal)**(0.28591_kreal) * &
                  (L_v/c_m*(dqldt_condevap + dqrdt_condevap + dqhdt_condevap) &
                + L_s/c_m*(dqidt_sublidep + dqhdt_sublidep) &
                + L_f/c_m*(dqldt_accre_chr + dqhdt_accre_hirr + dqhdt_accre_hr &
                - dqrdt_melt_rh - dqldt_melt_ci + dqidt_freeze + dqhdt_freeze))


       endif

    end function

end module integrator_species_rate
