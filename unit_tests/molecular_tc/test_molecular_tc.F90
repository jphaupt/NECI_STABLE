! unit tests for molecular tc
#include "macros.h"
program test_molecular_tc
  use constants
  use SystemData, only: nBasis, tStoreSpinOrbs, nel, G1, nullBasisFn
  use bit_rep_data, only: NIfTot
  use LMat_mod
  use fruit
  use Parallel_neci, only: MPIInit, MPIEnd
  use tc_three_body_data, only: tSparseLMat, tHDF5LMat
  use tc_three_body_excitgen, only: setup_mol_tc_excitgen

  implicit none

  call MPIInit(.false.)

  call init_fruit()
  
  call molecular_tc_test_driver()
  
  call fruit_summary()
  call fruit_finalize()

  call MPIEnd(.false.)

  contains

    subroutine molecular_tc_test_driver()
      implicit none
      call setup_tests()
      ! test the three-body excitation generator
      call run_excitgen_test()

      call clear_resources()
    end subroutine molecular_tc_test_driver
    
    subroutine setup_tests()
      ! initialization of the tests: mimic the environment of a NECI calculation
      use procedure_pointers, only: get_umat_el
      use sltcnd_mod, only: initSltCndPtr
      use UMatCache, only: nullUMat
      use SystemData, only: nOccAlpha, nOccBeta, AA_elec_pairs, AB_elec_pairs, &
           BB_elec_pairs, par_elec_pairs, tNoSymGenRandExcits, t_mol_3_body
      use dSFMT_interface, only: dSFMT_init
      use FciMCData, only: pParallel, pSingles, pDoubles
      use tc_three_body_data, only: pTriples
      implicit none

      integer :: i
      
      nBasis = 14
      tStoreSpinOrbs = .false.
      nel = 6

      allocate(G1(nBasis))
      G1 = nullBasisFn

      do i = 1, nBasis
         if(is_beta(i)) then
            G1(i)%ms = -1
         else
            G1(i)%ms = 1
         end if
      end do

      t_mol_3_body = .true.
      ! the slater condon rules in the TC are routed via procedure pointers, they have to
      ! be assigned
      call initSltCndPtr()

      call init_dummy()

      nOccAlpha = 3
      nOccBeta = 3
      pParallel = 0.4
      AA_elec_pairs = nOccAlpha*(nOccAlpha-1)/2
      BB_elec_pairs = nOccBeta*(nOccBeta-1)/2
      AB_elec_pairs = nOccAlpha*nOccBeta
      par_elec_pairs = AA_elec_pairs + BB_elec_pairs

      tNoSymGenRandExcits = .true.

      NIfTot = 2
      ! random number generator initialization
      call dSFMT_init(4)
      
      pSingles = 0.0_dp
      pDoubles = 0.0_dp
      pTriples = 1.0_dp


      ! assign the the sixindex access functions
      tSparseLMat = .true.
      tHDF5LMat = .true.

      ! initialize the excitgen
      call setup_mol_tc_excitgen()
    end subroutine setup_tests

    subroutine run_excitgen_test()
      ! TODO: Scrap this crap and use the proper excitation generator unit test
      ! (as in the framework of k-space-hubbard/umat-hash)
      use tc_three_body_excitgen
      use tc_three_body_data, only: pgen3B, pgen2B, pgen1B, pgen0B, pTriples
      use DeterminantData, only: write_det
      implicit none

      integer :: nI(nel), nJ(nel), exFlag, ic, ExcitMat(2,3)
      logical :: tParity
      real(dp) :: pgen
      HElement_t(dp) :: helgen
      type(excit_gen_store_type), target :: store
      integer(n_int) :: ilut(0:NIfTot), ilutJ(0:NIfTot)
      integer :: i
      integer, parameter :: nTest = 100
     
      nI = (/1,2,4,11,13,14/)
      pTriples = 1.0

      do i = 1, nTest
         ilut = 0_n_int
         ilutJ = 0_n_int
         call gen_excit_mol_tc(nI, ilut, nJ, ilutJ, exFlag, ic, ExcitMat, &
              tParity, pgen, helgen, store)

         call assert_true(abs(pgen-calc_pgen_triple(nI,ExcitMat)) < eps)
      end do
    end subroutine run_excitgen_test

    subroutine init_dummy()
      use OneEInts, only: TMat2D, tOneElecDiag
      use UMatCache, only: UMat2D
      use SymData
      use SymExcitDataMod, only: SpinOrbSymLabel
      implicit none
      tOneElecDiag = .false.

      allocate(Symclasses(nBasis))
      Symclasses = 1
      allocate(symlabelintscum(1))
      symlabelintscum = 0
      allocate(StateSymMap(nBasis))
      StateSymMap = 1


      allocate(spinorbsymlabel(nBasis), source = 0)
      
    end subroutine init_dummy

    subroutine clear_resources()
      use OneEInts, only: TMat2D
      use UMatCache, only: UMat2D
      use SymData
      implicit none
      
      deallocate(StateSymMap)
      deallocate(symlabelintscum)
      deallocate(Symclasses)
    end subroutine clear_resources

    
end program test_molecular_tc
