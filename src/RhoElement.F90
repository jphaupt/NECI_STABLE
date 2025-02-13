!.. Calculate RHO_IJ using a Trotter decomposition without having a stored H
!.. Calculate RHO = exp(-(BETA/P)H) matrix element <I|RHO|J> (= RHO_IJ)
!.. Trotter = RHO ~ exp(-(BETA/P)H'/2)exp(-(BETA/P)U')exp(-(BETA/P)H'/2)
!.. where H' is the diag part of H, and U' is the non-diag
!..
!.. NTAY is the order of the Taylor expansion for U'
!.. IC is the number of basis fns by which NI and NJ differ (or -1 if not known)
!..
SUBROUTINE CALCRHO2(NI, NJ, BETA, I_P, NEL, G1, NBASIS, &
                    NMAX, RH, NTAY, IC2, ECORE)
    Use Determinants, only: get_helement, nUHFDet, &
                            E0HFDet
    use constants, only: dp
    use SystemData, only: TSTOREASEXCITATIONS, BasisFN, tGUGA
    use global_utilities
    IMPLICIT NONE
    HElement_t(dp) RH
    INTEGER I_P, NTAY(2), NEL, NBASIS
    INTEGER NI(NEL), NJ(NEL), NMAX, IC, IC2
    real(dp) BETA, ECORE
    LOGICAL tSameD
    INTEGER IGETEXCITLEVEL
    type(timer), save :: proc_timer
    TYPE(BasisFN) G1(*)
    HElement_t(dp) hE, UExp, B, EDIAG
    character(*), parameter :: this_routine = 'CALCRHO2'
    IF (NTAY(1) < 0) THEN
!.. We've actually hidden a matrix of rhos in the coeffs for calcing RHOa
        call stop_all(this_routine, "GETRHOEXND has been removed.")
!         CALL GETRHOEXND(NI,NJ,NEL,BETA,NMSH,FCK,UMAT,RH)
        RETURN
    else if (NTAY(1) == 0) THEN
!.. NTAY=0 signifying we're going to calculate the RHO values when we
!.. need them from the list of eigenvalues.
!.. Hide NMSH=NEVAL
!..      FCK=W
!..      ZIA=CK
!..      UMAT=NDET
!..      ALAT=NMRKS
        call stop_all(this_routine, "Exact RHO calculation broken.")
!          CALL CALCRHOEXND(NI,NJ,NEL,BETA,NMSH,FCK,UMAT,ALAT,I_P,RH)
        RETURN
    end if
    proc_timer%timer_name = 'CALCRHO2  '
    call set_timer(proc_timer, 60)
    IC = IC2
    B = BETA / I_P
    UEXP = 0.0_dp
    IF (IC < 0) IC = IGETEXCITLEVEL(NI, NJ, NEL)
    IF (IC == 0) THEN
        tSAMED = .TRUE.
    ELSE
        tSAMED = .FALSE.
    end if

    if (tGUGA) then
        call stop_all(this_routine, "modify get_helement for GUGA!")
    end if

    IF (tStoreAsExcitations .AND. nI(1) == -1 .AND. nJ(1) == -1) THEN
!Store as excitations.
        IF (NTAY(2) /= 3) call stop_all(this_routine, "Store as Excitations only works for Fock-Partition-Lowdiag")
!Partition with Trotter with H(0) having just the Fock Operators
!Fock-Partition-Lowdiag
        IF (tSAMED) THEN
            call GetH0Element(nJ, nEl, nMax, nBasis, ECore, EDiag)
            EDiag = EDiag + (E0HFDET)
            RH = EXP(-B * EDiag)
        ELSE
            call GetH0Element(nI, nEl, nMax, nBasis, ECore, UExp)
            UExp = UExp + (E0HFDET)
            call GetH0Element(nJ, nEl, nMax, nBasis, ECore, EDiag)
            EDiag = (UExp + UExp + EDiag) / (2.0_dp)
            UExp = get_helement(nI, nJ, IC)
            UExp = -B * UExp
            RH = EXP(-B * EDiag) * UExp
        end if
        RETURN
    else if (nI(1) == -1 .or. nJ(1) == -1) THEN
        call stop_all(this_routine, "Store as Excitations used, but not allowed in CALCRHO2")
    end if
    IF (NTAY(2) == 1) THEN
!Diag-Partition
!Partition with Trotter using H(0) containing the complete diagonal
        IF (tSAMED) THEN
            UExp = UExp + (1.0_dp)
        ELSE
!.. Now do the first order term, which only exists for non-diag
            UExp = UExp - B * get_helement(nI, nJ, IC)
        end if
!.. Now the 2nd order term
!      IF(NTAY.GE.2) UExp=UExp+B*B*(RHO2ORDERND2(NI,NJ,NEL,NBASISMAX,    &
!     &            G1,NBASIS,BRR,NMSH,FCK,NMAX,ALAT,UMAT,IC,ECORE)/2.0_dp)

        hE = (get_helement(nI, nI, 0) + &
              get_helement(nJ, nJ, 0)) / (2.0_dp)
        RH = EXP((-BETA / I_P) * hE) * UExp
    else if (NTAY(2) == 2) THEN
!Partition with Trotter with H(0) having just the Fock Operators
        IF (tSAMED) THEN
            call GetH0Element(nI, nEl, nMax, nBasis, ECore, EDiag)
            UExp = 1.0_dp
!Fock-Partition
            UExp = UExp - B * (get_helement(nI, nI, 0) - EDiag)
            RH = EXP(-B * EDiag) * UExp
        ELSE
            call GetH0Element(nI, nEl, nMax, nBasis, ECore, UExp)
            call GetH0Element(nJ, nEl, nMax, nBasis, ECore, EDiag)
            EDiag = (UExp + EDiag) / (2.0_dp)
            UExp = get_helement(nI, nJ, IC)
            UExp = -B * UExp
            RH = EXP(-B * EDiag) * UExp
        end if
    else if (NTAY(2) == 3) THEN
!Partition with Trotter with H(0) having just the Fock Operators
!Fock-Partition-Lowdiag
        IF (tSAMED) THEN
            call GetH0Element(nI, nEl, nMax, nBasis, ECore, EDiag)
            RH = EXP(-B * EDiag)
        ELSE
            call GetH0Element(nI, nEl, nMax, nBasis, ECore, UExp)
            call GetH0Element(nJ, nEl, nMax, nBasis, ECore, EDiag)
            EDiag = (UExp + EDiag) / (2.0_dp)
            UExp = get_helement(nI, nJ, IC)
            UExp = -B * UExp
            RH = EXP(-B * EDiag) * UExp
        end if
    else if (NTAY(2) == 4) THEN
!         Do a simple Taylor expansion on the whole lot
        IF (tSAMED) THEN
            UEXP = 1.0_dp
        ELSE
            UEXP = 0.0_dp
        end if
        RH = UEXP - B * get_helement(nI, nJ, IC)
    else if (NTAY(2) == 5) THEN
!Fock-Partition-DCCorrect-LowDiag
!Partition with Trotter with H(0) having just the Fock Operators.  Taylor diagonal to zeroeth order, and off-diag to 1st.
! Instead of
        IF (tSAMED) THEN
            call GetH0ElementDCCorr(nUHFDet, nI, nEl, G1, ECore, EDiag)
            RH = EXP(-B * EDiag)
        ELSE
            call GetH0ElementDCCorr(nUHFDet, nI, nEl, G1, ECore, UExp)
            call GetH0ElementDCCorr(nUHFDet, nJ, nEl, G1, ECore, EDiag)
            EDiag = (UExp + EDiag) / (2.0_dp)
            UExp = get_helement(nI, nJ, IC)
            UExp = -B * UExp
            RH = EXP(-B * EDiag) * UExp
        end if
    end if

!WRDET
!      write(stdout,"(A)",advance='no') "RHO:"
!      CALL WRITEDET(6,NI,NEL,.FALSE.)
!      CALL WRITEDET(6,NJ,NEL,.FALSE.)
!      write(stdout,*) RH
    call halt_timer(proc_timer)
    RETURN
END
!.. RHO2ORDERND2(I,J,HAMIL,LAB,NROW,NDET
!.. Calculate the 2nd order term in rho for non diag elements
!.. IC2 is the number of basis fns that differ in NI and NJ (or -1 if not known)

FUNCTION Rho2OrderND2(NI, NJ, NEL, NBASISMAX, G1, NBASIS, IC2)
!.. We use a crude method and generate all possible 0th, 1st, and 2nd
!.. excitations of I and of J.  The intersection of these lists is the
!.. selection of dets we want.
    Use Determinants, only: get_helement
    use constants, only: dp
    use SystemData, only: BasisFN, tGUGA
    IMPLICIT NONE
    TYPE(BasisFN) G1(*)
    HElement_t(dp) Rho2OrderND2
    INTEGER NEL, NBASIS, nBasisMax(5, *)
    INTEGER NI(NEL), NJ(NEL), IC2
    INTEGER LSTI(NEL, NBASIS * NBASIS * NEL * NEL)
    INTEGER LSTJ(NEL, NBASIS * NBASIS * NEL * NEL)
    INTEGER NLISTI, NLISTJ, IC, I, J
    INTEGER ICI(NBASIS * NBASIS * NEL * NEL)
    INTEGER ICJ(NBASIS * NBASIS * NEL * NEL), NLISTMAX
    INTEGER CMP, IGETEXCITLEVEL, ICMPDETS
    HElement_t(dp) SUM1
    SUM1 = 0.0_dp
    NLISTMAX = NBASIS * NBASIS * NEL * NEL
    IC = IC2
    IF (IC < 0) IC = IGETEXCITLEVEL(NI, NJ, NEL)

!.. the 1 at the ends ensures K.NE. I or J, as this would make
!.. <I|U'|K> or <K|U'|J> zero (U' has a zero diag)
    CALL GENEXCIT(NI, 2, NBASIS, NEL, LSTI, ICI, NLISTI, 1, G1, .TRUE.,     &
&         NBASISMAX, .FALSE.)
    CALL GENEXCIT(NJ, 2, NBASIS, NEL, LSTJ, ICJ, NLISTJ, 1, G1, .TRUE.,     &
&         NBASISMAX, .FALSE.)
    I = 1
    J = 1
    if (tGUGA) then
        call stop_all("RHO2ORDERND2", "modify get_helement for GUGA")
    end if
!.. Now iterate over K, going along row I
    DO WHILE ((I <= NLISTI) .AND. (J <= NLISTJ))
        CMP = ICMPDETS(LSTI(1, I), LSTJ(1, J), NEL)
!.. While I>J, we increase J
        DO WHILE ((CMP > 0) .AND. (J < NLISTJ))
            J = J + 1
            CMP = ICMPDETS(LSTI(1, I), LSTJ(1, J), NEL)
        end do
        IF (CMP == 0) THEN
            SUM1 = SUM1 + get_helement(nI, lstI(:, I)) * &
                   get_helement(lstJ(:, J), nJ)
        end if
        I = I + 1

    end do
    RHO2ORDERND2 = SUM1
    RETURN
END

!  Get a matrix element of the double-counting corrected unperturbed Hamiltonian.
!  This is just the sum of the Hartree-Fock eigenvalues
!   with the double counting subtracted, Sum_i eps_i - 1/2 Sum_i,j <ij|ij>-<ij|ji>.  (i in HF det, j in excited det)
subroutine GetH0ElementDCCorr(nHFDet, nJ, nEl, G1, ECore, hEl)
    use constants, only: dp
    use Integrals_neci, only: get_umat_el
    use UMatCache
    use SystemData, only: BasisFN, Arr
    implicit none
    integer nEl
    integer nHFDet(nEl), nJ(nEl)
    type(BasisFN) G1(*)
    HElement_t(dp) hEl
    real(dp) ECore
    integer i, j
    integer IDHF(nEl), IDJ(nEl)
    hEl = (ECore)
    do i = 1, nEl
        hEl = hEl + (Arr(nJ(i), 2))
        IDHF(i) = gtID(nHFDet(i))
        IDJ(i) = gtID(nJ(i))
    end do
    do i = 1, nEl
        do j = 1, nEl
!Coulomb term
            hEl = hEl - (0.5_dp) * get_umat_el(IDHF(i), IDJ(j), IDHF(i), IDJ(j))
            if (G1(nHFDet(i))%Ms == G1(nJ(j))%Ms) then
!Exchange term
                hEl = hEl + (0.5_dp) * get_umat_el(IDHF(i), IDJ(j), IDJ(j), IDHF(i))
            end if
        end do
    end do
!         call writedet(77,nj,nel,.false.)
!         write(77,*) "H0DC",hEl
!         call neci_flush(77)
end
