
gfortran -c -g -O0 microphysics_constants.F90
gfortran -c -g -O0 microphysics_common.F90
gfortran -c -g -O0 integrator_config.F90
gfortran -c -g -O0 mphys_with_ice.F90
gfortran -c -g -O0 integrator_species_rate.F90
gfortran -c -g -O0 integrator_rkf.F90
gfortran -c -g -O0 integrator_main.F90
gfortran -c -g -O0 integrator_tests_precip.F90

gfortran -o integrator_tests -g -O0 integrator_tests.F90 *.o

./integrator_tests
