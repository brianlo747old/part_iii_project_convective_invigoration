module microphysics_common
   use microphysics_constants, only: kreal

   implicit none

   public thermal_conductivity

   contains

      pure function thermal_conductivity(temp)
         use microphysics_constants, only: temp0 => T0, a_K, b_K

         real(kreal) :: thermal_conductivity
         real(kreal), intent(in) :: temp

         thermal_conductivity=a_K*(temp-temp0) + b_K
      end function thermal_conductivity

      pure function water_vapour_diffusivity(temp, pressure)
         use microphysics_constants, only: temp0 => T0, ps0, a_D, b_D

         real(kreal) :: water_vapour_diffusivity
         real(kreal), intent(in) :: temp, pressure

         ! The tabulated values are in reference to P=100kPa=100000Pa
         water_vapour_diffusivity=a_D*(temp/temp0)**b_D*100000./(pressure)
      end function water_vapour_diffusivity

      pure function saturation_vapour_pressure_water(temp)
         use microphysics_constants, only: epsmach, temp0 => T0, p0vs, a0_lq, a1_lq, a0_ice, a1_ice

         real(kreal) :: saturation_vapour_pressure_water
         real(kreal), intent(in) :: temp

         real(kreal) :: expon2, satpw

         expon2=a0_lq*(temp-temp0)/max(temp+a1_lq,epsmach)

         saturation_vapour_pressure_water=p0vs*exp(expon2)
      end function saturation_vapour_pressure_water

      pure function saturation_vapour_concentration_water(temp, p)
         use microphysics_constants, only: epsmach, temp0 => T0, R_v, R_d

         real(kreal), intent(in) :: temp, p
         real(kreal) :: saturation_vapour_concentration_water

         real(kreal) :: pv_sat, eps

         pv_sat = saturation_vapour_pressure_water(temp)
         eps = R_d/R_v
         saturation_vapour_concentration_water = (eps*pv_sat)/(p-(1.-eps)*pv_sat)
      end function saturation_vapour_concentration_water

      pure function saturation_vapour_pressure_ice(temp)
         use microphysics_constants, only: epsmach, temp0 => T0, p0vs, a0_lq, a1_lq, a0_ice, a1_ice

         real(kreal) :: saturation_vapour_pressure_ice
         real(kreal), intent(in) :: temp

         real(kreal) :: expon2, satpw

         expon2=a0_ice*(temp-temp0)/max(temp+a1_ice,epsmach)

         saturation_vapour_pressure_ice=p0vs*exp(expon2)
      end function saturation_vapour_pressure_ice

      pure function saturation_vapour_concentration_ice(temp, p)
         use microphysics_constants, only: epsmach, temp0 => T0, R_v, R_d

         real(kreal), intent(in) :: temp, p
         real(kreal) :: saturation_vapour_concentration_ice

         real(kreal) :: pv_sat, eps

         pv_sat = saturation_vapour_pressure_ice(temp)
         eps = R_d/R_v
         saturation_vapour_concentration_ice = (eps*pv_sat)/(p-(1.-eps)*pv_sat)
      end function saturation_vapour_concentration_ice

      !> Calculate dynamic viscosity using parameterisation from Rogers & Yau
      !> 1989
      pure function dynamic_viscosity(T)
         use microphysics_constants, only: temp0 => T0

         real(kreal), intent(in) :: T
         real(kreal) :: dynamic_viscosity

         real(kreal), parameter :: r3_2 = 3./2._kreal

         dynamic_viscosity = 1.72e-5_kreal*(393._kreal/(T + 120._kreal))*(T/temp0)**r3_2
      end function dynamic_viscosity

      !pure function cp_gas(y)
      !   use microphysics_register, only: n_variables, cp_species, q_species_flag, idx_water_vapour
      !   use microphysics_constants, only: cp_d, cp_v
      !   real(kreal), dimension(n_variables), intent(in) :: y
      !   real(kreal) :: cp_gas, q_d

      !   q_d = 1.0_kreal - sum(y*q_species_flag)

      !   cp_gas = cp_d*q_d + cp_v*y(idx_water_vapour)/(q_d + y(idx_water_vapour))
      !end function

      !pure function cv_gas(y)
      !   use microphysics_register, only: n_variables, cv_species, q_species_flag, idx_water_vapour
      !   use microphysics_constants, only: cv_d, cv_v
      !   real(kreal), dimension(n_variables), intent(in) :: y
      !   real(kreal) :: cv_gas, q_d

      !   q_d = 1.0_kreal - sum(y*q_species_flag)

      !   cv_gas = (cv_d*q_d + cv_v*y(idx_water_vapour))/(q_d + y(idx_water_vapour))
      !end function

      pure function cv_mixture(y)
         !use microphysics_register, only: n_variables, cv_species, q_species_flag
         !use microphysics_constants, only: cv_d
         use microphysics_constants, only: cv_d, cv_v, cv_l, cv_i
         integer, parameter :: n_variables = 7
         real(kreal), dimension (1 : n_variables) :: cv_species, q_species_flag

         real(kreal), dimension(n_variables), intent(in) :: y
         real(kreal) :: cv_mixture, q_d, test_sum

         ! Allocate and define cv_species array
         cv_species(1) = 0.0
         cv_species(2) = 0.0
         cv_species(3) = cv_l
         cv_species(4) = cv_l
         cv_species(5) = cv_v
         cv_species(6) = cv_i
         cv_species(7) = cv_i

         q_species_flag(1) = 0.0_kreal
         q_species_flag(2) = 0.0_kreal
         q_species_flag(3) = 1.0_kreal
         q_species_flag(4) = 1.0_kreal
         q_species_flag(5) = 1.0_kreal
         q_species_flag(6) = 1.0_kreal
         q_species_flag(7) = 1.0_kreal

         q_d = 1.0_kreal - sum(y*q_species_flag)

         cv_mixture = cv_d*q_d + sum(y*cv_species)
      end function cv_mixture

      pure function cp_mixture(y)
         !use microphysics_register, only: n_variables, cp_species, q_species_flag
         !use microphysics_constants, only: cp_d
         use microphysics_constants, only: cp_d, cp_v, cp_l, cp_i
         integer, parameter :: n_variables = 7
         real(kreal), dimension (1 : n_variables) :: cp_species, q_species_flag

         real(kreal), dimension(n_variables), intent(in) :: y
         real(kreal) :: cp_mixture, q_d

         ! Allocate and define cv_species array
         cp_species(1) = 0.0
         cp_species(2) = 0.0
         cp_species(3) = cp_l
         cp_species(4) = cp_l
         cp_species(5) = cp_v
         cp_species(6) = cp_i
         cp_species(7) = cp_i

         q_species_flag(1) = 0.0_kreal
         q_species_flag(2) = 0.0_kreal
         q_species_flag(3) = 1.0_kreal
         q_species_flag(4) = 1.0_kreal
         q_species_flag(5) = 1.0_kreal
         q_species_flag(6) = 1.0_kreal
         q_species_flag(7) = 1.0_kreal

         q_d = 1.0_kreal - sum(y*q_species_flag)

         cp_mixture = cp_d*q_d + sum(y*cp_species)
      end function cp_mixture

end module microphysics_common
