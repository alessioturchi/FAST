MODULE MOD_STATISTICS
implicit none
contains

!STATS computes the mean value of an array of real and the corresponding sample standard deviation
!
!sd= sqrt(SUM(x-mean)²/(N-1))
!
!When array(i)=no_value, this value is rejected from the computation of the mean and the sd.
!Thus INC is always inferior or equal to SIZE_ARRAY.
!
! ARRAY: input vector
! SIZE_ARRAY: dimension of the input vector
! MEAN: average
! SD:standard deviation
! INC:number of elements on which we calculate the mean and/or the sd
! NO_VALUE:value that we wish to reject from the calculation of the mean and/or
! the sd

SUBROUTINE STATS(ARRAY,SIZE_ARRAY,MEAN,SD,INC,NO_VALUE)
 implicit none
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: ARRAY
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: MEAN,SD
 INTEGER, INTENT(OUT) :: INC

 INTEGER :: I
 REAL :: SUM_DIFF

 MEAN=0
 INC=0
 DO I=1,SIZE_ARRAY
  IF (ARRAY(I).NE.NO_VALUE) THEN
   INC = INC+1
   MEAN = MEAN + ARRAY(I)
  ENDIF
 ENDDO
 IF (INC.ne.0.) MEAN = MEAN / INC
 IF (INC.eq.0.) MEAN=NO_VALUE

IF (INC.ne.0.) THEN
 SUM_DIFF=0
 SD=0
 DO I=1,SIZE_ARRAY
  IF (ARRAY(I).NE.NO_VALUE) THEN
   SUM_DIFF = SUM_DIFF + (ARRAY(I) - MEAN)**2
  ENDIF
 ENDDO
 IF(INC.NE.1)THEN
 SUM_DIFF = SUM_DIFF / (INC-1)
 ELSE
 SUM_DIFF = SUM_DIFF
 ENDIF
 SD = SQRT(SUM_DIFF)
ELSE
 SD = NO_VALUE
ENDIF
END SUBROUTINE STATS

!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!

SUBROUTINE BIAS_RMSE(ARRAY1,ARRAY2,SIZE_ARRAY,BIAS,RMSE,INC,NO_VALUE)
 implicit none
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: ARRAY1,ARRAY2
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: BIAS,RMSE
 INTEGER, INTENT(OUT) :: INC

 INTEGER :: I

 BIAS=0.
 RMSE=0.
 INC=0
 DO I=1,SIZE_ARRAY
  IF ( (ARRAY1(I).NE.NO_VALUE) .AND. (ARRAY2(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   BIAS = BIAS + (ARRAY2(I)-ARRAY1(I))
!   BIAS = BIAS + ABS(ARRAY2(I)-ARRAY1(I))
   RMSE = RMSE + (ARRAY2(I)-ARRAY1(I))**2
  ENDIF
 ENDDO
 if (INC.ne.0.) BIAS = BIAS / INC
 if (INC.ne.0.) RMSE = sqrt (RMSE / INC)
END SUBROUTINE BIAS_RMSE

!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!

SUBROUTINE CORR(N,X,Y,NO_VALUE_X,CORR_COEF,NO_VALUE_Y)
 implicit none
 INTEGER, INTENT(IN) :: N
 REAL, INTENT(IN)  :: NO_VALUE_X
 REAL, OPTIONAL, INTENT(IN)  :: NO_VALUE_Y
 REAL, DIMENSION(N),INTENT(IN)  :: X
 REAL, DIMENSION(N),INTENT(IN)  :: Y
 REAL,INTENT(OUT)   :: CORR_COEF 

 INTEGER  :: I,INC
 REAL     :: MEAN_X,MEAN_Y,VAR_X,VAR_Y,SOM_XY
 REAL,DIMENSION(N) :: DIF,DIFX2,DIFY2

DIF(:)=0.
DIFX2(:)=0.
DIFY2(:)=0.
CORR_COEF=0.

MEAN_X=0
MEAN_Y=0
INC=0
print *, 'Subroutine CORR is called.'
IF (PRESENT(NO_VALUE_Y)) THEN
 print *, 'NO_VALUE_X=',NO_VALUE_X,' and NO_VALUE_Y=',NO_VALUE_Y
 DO I=1,N
  IF ( (X(I).NE.NO_VALUE_X).AND.(Y(I).NE.NO_VALUE_Y) ) THEN
   INC = INC+1
   MEAN_X = MEAN_X + X(I)
   MEAN_Y = MEAN_Y + Y(I)
  ENDIF
 ENDDO
ELSE
 print *, 'NO_VALUE_X=',NO_VALUE_X, '; NO_VALUE_Y absent, set to NO_VALUE_X.'
 DO I=1,N
  IF ( (X(I).NE.NO_VALUE_X).AND.(Y(I).NE.NO_VALUE_X) ) THEN
   INC = INC+1
   MEAN_X = MEAN_X + X(I)
   MEAN_Y = MEAN_Y + Y(I)
  ENDIF
 ENDDO
ENDIF
MEAN_X = MEAN_X / INC
print *, 'INC CC = ', INC
MEAN_Y = MEAN_Y / INC

VAR_X=0
VAR_Y=0
IF (PRESENT(NO_VALUE_Y)) THEN
 DO I=1,N
  IF ( (X(I).NE.NO_VALUE_X).AND.(Y(I).NE.NO_VALUE_Y) ) THEN
   DIFX2(I)=(X(I)-MEAN_X)*(X(I)-MEAN_X) 
   VAR_X=VAR_X+DIFX2(I)
   DIFY2(I)=(Y(I)-MEAN_Y)*(Y(I)-MEAN_Y)
   VAR_Y=VAR_Y+DIFY2(I)
  ENDIF
 ENDDO
ELSE
 DO I=1,N
  IF ( (X(I).NE.NO_VALUE_X).AND.(Y(I).NE.NO_VALUE_X) ) THEN
   DIFX2(I)=(X(I)-MEAN_X)*(X(I)-MEAN_X)
   VAR_X=VAR_X+DIFX2(I)
   DIFY2(I)=(Y(I)-MEAN_Y)*(Y(I)-MEAN_Y)
   VAR_Y=VAR_Y+DIFY2(I)
  ENDIF
 ENDDO
ENDIF
VAR_Y=SQRT(VAR_Y)
VAR_X=SQRT(VAR_X)

SOM_XY=0
IF (PRESENT(NO_VALUE_Y)) THEN
 DO I=1,N
  IF ( (X(I).NE.NO_VALUE_X).AND.(Y(I).NE.NO_VALUE_Y) ) THEN
   DIF(I)=(X(I)-MEAN_X)*(Y(I)-MEAN_Y)
   SOM_XY=SOM_XY+DIF(I)
  ENDIF
 ENDDO
ELSE
 DO I=1,N
  IF ( (X(I).NE.NO_VALUE_X).AND.(Y(I).NE.NO_VALUE_X) ) THEN
   DIF(I)=(X(I)-MEAN_X)*(Y(I)-MEAN_Y)
   SOM_XY=SOM_XY+DIF(I)
  ENDIF
 ENDDO
ENDIF
CORR_COEF=SOM_XY/(VAR_X*VAR_Y)
END SUBROUTINE CORR


!array1=reference (obs) from which xlim1 and xlim2 have been extracted
! To be used for 3x3 tables
subroutine hit_rate(array1,array2,size_array,xlim1,xlim2,noval,tab_hr,pod,pc,ebd,lflag)
implicit none

logical, intent(in), optional :: lflag !TRUE=with percent, FALSE=number of points
integer, intent(in) :: size_array
real,dimension(size_array), intent(in) :: array1,array2
real, intent(in) :: xlim1,xlim2,noval
real, dimension(3,3), intent(out) :: tab_hr
real, dimension(3), intent(out) ::pod
real, intent(out) :: pc, ebd

integer :: i,icount
real :: a,b,c,d,e,f,g,h,ii

if (present(lflag)) then
 if (lflag.eqv..true.) print *, 'Contingency table filled with percent.'
 if (lflag.eqv..false.) print *, 'Contingency table filled with numbers.'
else
 print *, 'Contingency table filled with percent.'
endif

tab_hr=0
icount=0
do i=1,size_array
 if ( (array1(i).ne.noval).and.(array2(i).ne.noval) ) then
  icount = icount + 1
  if (array1(i).le.xlim1) then
   if (array2(i).le.xlim1)                              tab_hr(1,1) = tab_hr(1,1) + 1
   if ( (array2(i).gt.xlim1).and.(array2(i).le.xlim2) ) tab_hr(2,1) = tab_hr(2,1) + 1 
   if (array2(i).gt.xlim2)                              tab_hr(3,1) = tab_hr(3,1) + 1
  endif
  if ( (array1(i).gt.xlim1).and.(array1(i).le.xlim2) ) then 
   if (array2(i).le.xlim1)                              tab_hr(1,2) = tab_hr(1,2) + 1
   if ( (array2(i).gt.xlim1).and.(array2(i).le.xlim2) ) tab_hr(2,2) = tab_hr(2,2) + 1
   if (array2(i).gt.xlim2)                              tab_hr(3,2) = tab_hr(3,2) + 1
  endif
  if (array1(i).gt.xlim2) then
   if (array2(i).le.xlim1)                              tab_hr(1,3) = tab_hr(1,3) + 1
   if ( (array2(i).gt.xlim1).and.(array2(i).le.xlim2) ) tab_hr(2,3) = tab_hr(2,3) + 1
   if (array2(i).gt.xlim2)                              tab_hr(3,3) = tab_hr(3,3) + 1  
  endif
 endif
enddo

print *, 'Hit rate computed on',icount,'points.'


!  Expressed in percent
if ( (present(lflag).and.(lflag.eqv..True.)).or.(.not.present(lflag)) ) then 
tab_hr = (tab_hr / icount)*100. !in %

a = tab_hr(1,1)
b = tab_hr(1,2)
c = tab_hr(1,3)
d = tab_hr(2,1)
e = tab_hr(2,2)
f = tab_hr(2,3)
g = tab_hr(3,1)
h = tab_hr(3,2)
ii = tab_hr(3,3)
print *, 'X<',xlim1,xlim1,'<X<',xlim2,'X>',xlim2
print *, tab_hr(1,1),tab_hr(1,2),tab_hr(1,3) 
print *, tab_hr(2,1),tab_hr(2,2),tab_hr(2,3) 
print *, tab_hr(3,1),tab_hr(3,2),tab_hr(3,3) 
pod(1)=a/(a+d+g)*100
print *, 'POD(event1)=', pod(1)
pod(2)=e/(b+e+h)*100
print *, 'POD(event2)=', pod(2)
pod(3)=ii/(c+f+ii)*100
print *, 'POD(event3)=', pod(3)
pc=(a+e+ii)
print*,'PC=',pc
ebd=(c+g)
print*,'ebd=',ebd
endif

! Expressed in numbers
if ( (present(lflag).and.(lflag.eqv..false.)) ) then
tab_hr = tab_hr !in %

a = tab_hr(1,1)
b = tab_hr(1,2)
c = tab_hr(1,3)
d = tab_hr(2,1)
e = tab_hr(2,2)
f = tab_hr(2,3)
g = tab_hr(3,1)
h = tab_hr(3,2)
ii = tab_hr(3,3)
print *, 'X<',xlim1,xlim1,'<X<',xlim2,'X>',xlim2
print *, tab_hr(1,1),tab_hr(1,2),tab_hr(1,3)
print *, tab_hr(2,1),tab_hr(2,2),tab_hr(2,3)
print *, tab_hr(3,1),tab_hr(3,2),tab_hr(3,3)
pod(1)=a/(a+d+g)*100
print *, 'POD(event1)=', pod(1)
pod(2)=e/(b+e+h)*100
print *, 'POD(event2)=', pod(2)
pod(3)=ii/(c+f+ii)*100
print *, 'POD(event3)=', pod(3)
pc=((a+e+ii)/icount)*100
print*,'PC=',pc
ebd=((c+g)/icount)*100
print*,'ebd=',ebd
endif

end subroutine hit_rate

!array1=reference (obs) from which xlim has been extracted
subroutine contingency(array1,array2,size_array,xlim,noval,tab_hr,statnum,lflag)
implicit none

logical, intent(in), optional :: lflag !TRUE=with percent, FALSE=number of points
integer, intent(in) :: size_array
real,dimension(size_array), intent(in) :: array1,array2
real, intent(in) :: xlim,noval
real, dimension(2,2), intent(out) :: tab_hr
real, dimension(11), intent(out)   :: statnum
!statnum(1) = accuracy ACC
!statnum(2) = hit rate (probability of detection) POD
!statnum(3) = false alarm ratio (Fraction of forecasted events that were false alarms) FAR
!statnum(4) = false alarm rate (probability of false detection) POFD
!statnum(5) = frequency (bias) FBIAS
!statnum(6) = threat score (critical success index) CSI
!statnum(7) = Heidke Skill Score HSC
!statnum(8) = Hanssen-Kuipers Discriminant HKD
!statnum(9) = Odds Ratio
!statnum(10)= OR Skill Score
!statnum(11)= Gilber SS or ETS

!Local variables
integer :: i,icount
real :: a,b,c,d,N,ar

if (present(lflag)) then
 if (lflag.eqv..true.) print *, 'Contingency table filled with percent.'
 if (lflag.eqv..false.) print *, 'Contingency table filled with numbers.'
else
 print *, 'Contingency table filled with percent.'
endif

tab_hr=0
icount=0
do i=1,size_array
 if ( (array1(i).ne.noval).and.(array2(i).ne.noval) ) then
  icount = icount + 1
  if (array1(i).le.xlim) then
   if (array2(i).le.xlim)                              tab_hr(1,1) = tab_hr(1,1) + 1
   if (array2(i).gt.xlim)                              tab_hr(2,1) = tab_hr(2,1) + 1
  endif
  if (array1(i).gt.xlim) then
   if (array2(i).le.xlim)                              tab_hr(1,2) = tab_hr(1,2) + 1
   if (array2(i).gt.xlim)                              tab_hr(2,2) = tab_hr(2,2) + 1
  endif
 endif
enddo

print *, 'Hit rate computed on',icount,'points.'

a = tab_hr(1,1)
b = tab_hr(1,2)
c = tab_hr(2,1)
d = tab_hr(2,2)
N = icount
ar = (a+b)*(a+c) / N !number of hits expected by forecasts independent of observations (pure chance)

statnum(1) = (a + d) / N      !ACC, or PC (Percent Correct)  
statnum(2) = a / (a + c)      !POD
statnum(3) = b / (a + b)      !FAR
statnum(4) = b / (b + d)      !POFD
statnum(5) = (a + b) / (a + c) !FBIAS
statnum(6) = a / (a + b + c)    !CSI
statnum(7) = ( (a*d) - (b*c) ) / ( (((a+c)*(c+d)) + ((a+b)*(b+d))) / 2 )  !HSC
statnum(8) = ( (a*d) - (b*c) ) / ( (a+c)*(b+d) ) !HKD = POD-POFD, or Peirce's Skill Score
statnum(9) = (a*d) / (b*c) ! OR (Odds Ratio)
statnum(10)= ( (a*d) - (b*c) ) / ( (a*d) + (b*c) ) ! OR Skill Score
statnum(11)= (a - ar) / (a -ar + b + c) ! GSS (Gilbert Skill Score) or ETS (Equitable Threat Score)

!tab_hr = (tab_hr / icount)*100. !in %
if ( (present(lflag).and.(lflag.eqv..True.)).or.(.not.present(lflag)) ) tab_hr = (tab_hr / icount)*100. !in %

print *, '------------'
print *, 'X<',xlim,xlim,'<X<'
print *, tab_hr(1,1),tab_hr(1,2)
print *, tab_hr(2,1),tab_hr(2,2)
print *, '------------'
print *, 'PC (Percent Correct) =', statnum(1)
print *, 'POD (or Hit Rate) =',statnum(2)
print *, 'M (Miss Rate) = 1 - POD =', 1-statnum(2)
print *, 'FAR (False Alarm Ratio) =', statnum(3)
print *, 'F (False Alarm Rate, or POFD) =', statnum(4)
print *, 'Bias =', statnum(5)
print *, '------------'
print *, 'CSI (Critical success index) =', statnum(6)
print *, 'HSS (Heidke Skill Score) = (PC-PCrandom)/(1-PCrandom) =', statnum(7)
print *, 'Peirce Skill Score = 1 - M - F =', statnum(8)
print *, 'Odds Ratio (OR) =', statnum(9)
print *, 'OR Skill Score (ORSS) =', statnum(10)
print *, 'Number of hits expected by forecasts independent of observations (pure chance), ar =', ar
print *, 'ETS ( or GSS = HSS / (2 - HSS) ) =', statnum(11)


end subroutine contingency


!STATS computes the BIAS and the RMSE of 2 arrays of real
!
!BIAS=( sum(Yi-Xi) / N ) 
!RMSE=sqrt( sum(Yi-Xi)²/ N )
!
!When x(i) or y(i)=no_value, this value is rejected from the computation.
!Thus INC is always inferior or equal to SIZE_ARRAY.
! 

SUBROUTINE BIAS_RMSE_SIGMA(ARRAY1,ARRAY2,SIZE_ARRAY,BIAS,RMSE,SIGMA,INC,NO_VALUE)
 IMPLICIT NONE
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: ARRAY1,ARRAY2
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: BIAS,RMSE,SIGMA
 INTEGER, INTENT(OUT) :: INC

 INTEGER :: I

 BIAS=0.
 RMSE=0.
 SIGMA=0.
 INC=0
 DO I=1,SIZE_ARRAY
  IF ( (ARRAY1(I).NE.NO_VALUE) .AND. (ARRAY2(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   BIAS = BIAS + (ARRAY2(I)-ARRAY1(I))
!   BIAS = BIAS + ABS(ARRAY2(I)-ARRAY1(I))
   RMSE = RMSE + (ARRAY2(I)-ARRAY1(I))**2
  ENDIF
 ENDDO
 if (INC.ne.0.) BIAS = BIAS / INC
 if (INC.ne.0.) RMSE = sqrt (RMSE / INC)
 if (INC.ne.0.) SIGMA=SQRT(RMSE**2-BIAS**2)

END SUBROUTINE BIAS_RMSE_SIGMA

! SLOPE=slope of the regression line
! SD=standard deviation with respect to the regression line
! SIZE_ARRAY has to be the same for XARRAY and YARRAY

SUBROUTINE SD_REG_LIN(SIZE_ARRAY,XARRAY,YARRAY,SLOPE,NO_VALUE,SD)
 IMPLICIT NONE
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: XARRAY,YARRAY
 REAL, INTENT(IN) :: SLOPE
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: SD

 INTEGER :: I,INC

 SD=0.
 INC=0
 DO I=1,SIZE_ARRAY
  IF ( (XARRAY(I).NE.NO_VALUE).AND.(YARRAY(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   SD = SD + (YARRAY(I) - ABS(SLOPE)*XARRAY(I))**2
  ENDIF
 ENDDO
 IF (INC.NE.0.) SD = SQRT(SD / INC)
 IF (INC.EQ.0.) SD = NO_VALUE

END SUBROUTINE

!******************************************************************************
! SUBROUTINES FOR MEDIAN
!******************************************************************************

! --------------------------------------------------------------------
! REAL FUNCTION  Median() :
!    This function receives an array X of N entries, copies its value
! to a local array Temp(), sorts Temp() and computes the median.
!    The returned value is of REAL type.
! --------------------------------------------------------------------

REAL FUNCTION  Median(X, N, NO_VALUE)
 IMPLICIT  NONE
 real, DIMENSION(:), INTENT(IN)  :: X
 INTEGER, INTENT(IN)             :: N
 REAL, INTENT(IN)                :: NO_VALUE 
 real, DIMENSION(N)              :: Temp
 real                            :: Tmp,MMAX
 INTEGER                         :: i, Location, count_mmax, Ndim

 Ndim=N
 MMAX=maxval(X,1)+1
 count_mmax=0
 DO i = 1, N                       ! make a copy
  if (X(i) == NO_VALUE) then
   Temp(i)=MMAX
   count_mmax=count_mmax+1
  else
   Temp(i) = X(i)
  end if
 END DO
 !Subtract count_mmax values
 if (count_mmax > 0) then
  Ndim=N-count_mmax
 end if
 !Sort the array
 DO i = 1, Ndim-1                      ! except for the last
  Location = minloc(Temp(i:Ndim),1)+i-1
  ! swap this and the minimum
  Tmp = Temp(i)
  Temp(i)    = Temp(Location)
  Temp(Location)    = Tmp
 END DO
 IF (MOD(Ndim,2) == 0) THEN           ! compute the median
  Median = (Temp(Ndim/2) + Temp(Ndim/2+1)) / 2.0
 ELSE
  Median = Temp(Ndim/2+1)
 END IF
END FUNCTION  Median


!******************************************************************************

END MODULE MOD_STATISTICS
