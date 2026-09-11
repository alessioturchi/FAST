MODULE MOD_ARRAYS
implicit none
contains


SUBROUTINE CONVOL(X,Y,NDIM,XC,DX,YC,NB,NOVAL)
implicit none
!****************************************************
!* LEGENDE
!*    x: variable indépendante
!*    y: variable à convoluer
!*    ndim: nombre de points de départ
!*    xc: point de départ
!*    dx: base du triangle sur lequel on fait la convolution (mètres) (input)
!*    yc: valeur ponctuelle de la variable convoluée
!*    nb: nombre de points sur lesquels on fait la convolution (output)
!****************************************************

INTEGER, INTENT(IN)                ::  NDIM
INTEGER, INTENT(OUT)               ::  NB
REAL, DIMENSION(:), INTENT(IN)     ::  X(NDIM),Y(NDIM)
REAL, INTENT(IN)                   ::  DX
REAL, INTENT(IN)                   ::  XC
REAL, INTENT(IN) :: NOVAL
REAL, INTENT(OUT)                  ::  YC

REAL                               ::  XDEB,XFIN,DXS2,XSUM,YR
REAL :: YI,XI,YI1,XI1
INTEGER :: I
REAL :: TR,TR1

DXS2=DX/2.
YR=0.
NB=0
XSUM=0.

XDEB=XC-DXS2
XFIN=XC+DXS2


DO I=1,NDIM-1
   YI=Y(I)
   XI=X(I)
   YI1=Y(I+1)
   XI1=X(I+1)

   IF(XFIN.LT.X(1))EXIT
   IF(XDEB.GT.X(NDIM))EXIT
   IF(XI1.GT.XFIN)EXIT

   IF(XI.GE.XDEB.AND.XI1.LE.XFIN)THEN
      TR=(1.-(ABS(XI-XC)/DXS2))
      TR1=(1.-(ABS(XI1-XC)/DXS2))
      NB=NB+1
      IF((YI.ne.NOVAL).and.(YI1.ne.NOVAL)) THEN 
       YR=YR+0.5*(YI*TR+YI1*TR1)*(XI1-XI)
       XSUM=XSUM+0.5*(TR+TR1)*(XI1-XI)
      ENDIF
   ENDIF
ENDDO

YC=NOVAL
IF(YR.ne.0.) THEN 
 IF(NB.EQ.0)THEN
  YC=0.
 ELSE
  YC=YR/XSUM
 ENDIF
ENDIF
END SUBROUTINE CONVOL

!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!
!!!!!!


SUBROUTINE ITP(LevIni,LevInt,ARRIni,ALTIni,ARRInt,ALTInt,delta,NOVAL)
!Input vector ARRIni of dimension LevIni; interpolated on LevInt levels, ouptut vector: ARRInt
!-noval: if values at z or z+1 (of ARRIni) is equal noval, no interpolation is done between the 2 points and all resulted 
!interpolated levels between z and z+1 (so for ARRInt) are put equal to noval
!-delta: the resolution of the interpolated grid  
!!!! ALTInt first grid point has to be equal to the first grid point of AltIni !!!!
! Routine created to reinterpolate the Meso-Nh grid with a regular grid having the grid equal to the 
! smallest grid point of the Meso-Nh grid i..e the first grid point above the ground.
implicit none
INTEGER, INTENT(IN)  :: LevIni,LevInt
REAL, INTENT(IN) :: delta,NOVAL

REAL, DIMENSION(:), INTENT(IN)  :: ARRIni,ALTIni
REAL, DIMENSION(:), INTENT(OUT) :: ARRInt,ALTInt

INTEGER :: ICOUNT, JCOUNT, LevInf
REAL :: lmin,lmax,d1,d2

lmin=0.
lmax=0.
LevInf=0

DO ICOUNT=1,LevInt
 ALTInt(ICOUNT)=ALTIni(1) - delta + (ICOUNT*delta)
 ARRInt(ICOUNT)=0.
ENDDO

ARRInt(1)=ARRIni(1)

DO ICOUNT=1, LevInt
 DO JCOUNT=1, LevIni-1
  IF (ALTIni(JCOUNT)<=ALTInt(ICOUNT)) THEN
   lmin=ARRIni(JCOUNT)
   LevInf=JCOUNT
  ENDIF
  lmax=ARRIni(LevInf+1)
 ENDDO
 IF (ALTInt(ICOUNT)==ALTIni(LevInf)) THEN
  ARRInt(ICOUNT)=ARRIni(LevInf)
 ELSE

  if ( (lmin.ne.noval).and.(lmax.ne.noval) ) then  !loop test noval

   d1=ALTInt(ICOUNT)-ALTIni(LevInf)
   d2=ALTIni(LevInf+1)-ALTInt(ICOUNT)
   ARRInt(ICOUNT)=(lmin/d1 + lmax/d2) / (1/d1 + 1/d2)

  else !else loop test noval

   ARRInt(ICOUNT)=noval

  endif !loop test noval 

 ENDIF
ENDDO
END SUBROUTINE ITP

SUBROUTINE ITP_dp(LevIni,LevInt,ARRIni,ALTIni,ARRInt,ALTInt,delta)
! Routine equal to ITP but for inputs in double precision
implicit none
INTEGER, INTENT(IN)  :: LevIni,LevInt
REAL, INTENT(IN) :: delta

DOUBLE PRECISION, DIMENSION(:), INTENT(IN)  :: ARRIni,ALTIni
DOUBLE PRECISION, DIMENSION(:), INTENT(OUT) :: ARRInt,ALTInt

INTEGER :: ICOUNT, JCOUNT, LevInf
DOUBLE PRECISION :: lmin,lmax,d1,d2

lmin=0.
lmax=0.
LevInf=0

DO ICOUNT=1,LevInt
 ALTInt(ICOUNT)=ALTIni(1) - delta + (ICOUNT*delta)
 ARRInt(ICOUNT)=0.
ENDDO

ARRInt(1)=ARRIni(1)

DO ICOUNT=1, LevInt
 DO JCOUNT=1, LevIni-1
  IF (ALTIni(JCOUNT)<=ALTInt(ICOUNT)) THEN
   lmin=ARRIni(JCOUNT)
   LevInf=JCOUNT
  ENDIF
  lmax=ARRIni(LevInf+1)
 ENDDO
 IF (ALTInt(ICOUNT)==ALTIni(LevInf)) THEN
  ARRInt(ICOUNT)=ARRIni(LevInf)
 ELSE
  d1=ALTInt(ICOUNT)-ALTIni(LevInf)
  d2=ALTIni(LevInf+1)-ALTInt(ICOUNT)
  ARRInt(ICOUNT)=(lmin/d1 + lmax/d2) / (1/d1 + 1/d2)
 ENDIF
ENDDO
END SUBROUTINE ITP_dp

!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!

!Interpolates a vertical profile of LevIni points (Altitude=ALTIni and Value=ARRIni) on a new vertical grid which levels 
!are defined in ALTInt. ALTInt is an input parameter. The output is a vector of reinterpolated values (ARRInt).
subroutine irregular_itp(LevIni,LevInt,ARRIni,ALTIni,ALTInt,ARRInt,NOVAL)
implicit none

integer, intent(in)  :: LevIni,LevInt

real, dimension(LevIni), intent(in)  :: ARRIni,ALTIni
real, dimension(LevInt), intent(in)  :: ALTInt
real, dimension(LevInt), intent(out) :: ARRInt
real, intent(in) :: NOVAL

integer :: icount, jcount, LevInf, LevMax
real :: lmin,lmax,d1,d2

lmin=0.
lmax=0.
LevInf=0
LevMax=0

print *, 'Number of level for output matrice:', LevInt
do icount=1, LevInt
 do jcount=1, LevIni
  if (ALTIni(jcount).gt.ALTInt(icount)) then
!   print *, 'WARNING!!'
!   print *, 'The value of the first altitude of the interpolated field is inferior'
!   print *, 'to the value of the first altitude of the initial field.'
!   print *, 'ALTIni(jcount)=',ALTIni(jcount),'and ALTInt(icount)=',ALTInt(icount),'with jcount / LevIni=',jcount, &
!            'and icount / LevInt=',icount
!   print *, 'PROGRAM ENDS NOW.'
   exit
  endif
  if (ALTIni(jcount)<=ALTInt(icount)) then
   LevInf=jcount
   lmin=ARRIni(LevInf)
  endif
  if (LevInf.lt.LevIni) then 
   LevMax=LevInf+1
  else 
   LevMax=LevInf
  endif
  lmax=ARRIni(LevMax)
 enddo
 if (LevMax.gt.LevInf) then !Check of array bounds
  if (ALTInt(icount)==ALTIni(LevInf)) then
   ARRInt(icount)=ARRIni(LevInf)
  else

   if ( (lmin.ne.noval).and.(lmax.ne.noval) ) then  !loop test noval
 
    d1=ALTInt(icount)-ALTIni(LevInf)
    d2=ALTIni(LevMax)-ALTInt(icount)
    ARRInt(icount)=(lmin/d1 + lmax/d2) / (1/d1 + 1/d2)
  
   else !else loop test noval
 
    ARRInt(ICOUNT)=noval 

   endif !loop test noval 

  endif
 else
  ARRInt(icount)=noval
 endif
 if ( (LevMax.eq.LevInf).and.(ALTInt(icount).eq.ALTIni(LevInf)) ) ARRInt(icount)=ARRIni(LevInf) !Very rare case when the last level of the input field has the same altitude than the last level of the output field.
enddo
end subroutine irregular_itp

subroutine irregular_itp_dp(LevIni,LevInt,ARRIni,ALTIni,ALTInt,ARRInt)
implicit none

integer, intent(in)  :: LevIni,LevInt

double precision, dimension(LevIni), intent(in)  :: ARRIni,ALTIni
double precision, dimension(LevInt), intent(in)  :: ALTInt
double precision, dimension(LevInt), intent(out) :: ARRInt

integer :: icount, jcount, LevInf, LevMax
double precision :: lmin,lmax,d1,d2

lmin=0.
lmax=0.
LevInf=0
LevMax=0

print *, 'Number of level for output matrice:', LevInt
do icount=1, LevInt
 do jcount=1, LevIni
  if (ALTIni(jcount).gt.ALTInt(icount)) then
!   print *, 'WARNING!!'
!   print *, 'The value of the first altitude of the interpolated field is inferior'
!   print *, 'to the value of the first altitude of the initial field.'
!   print *, 'ALTIni(jcount)=',ALTIni(jcount),'and ALTInt(icount)=',ALTInt(icount),'with jcount / LevIni=',jcount, &
!            'and icount / LevInt=',icount
!   print *, 'PROGRAM ENDS NOW.'
   exit
  endif
  if (ALTIni(jcount)<=ALTInt(icount)) then
   LevInf=jcount
   lmin=ARRIni(LevInf)
  endif
  if (LevInf.lt.LevIni) then
   LevMax=LevInf+1
  else
   LevMax=LevInf
  endif
  lmax=ARRIni(LevMax)
 enddo
 if (LevMax.gt.LevInf) then !Check of array bounds
  if (ALTInt(icount)==ALTIni(LevInf)) then
   ARRInt(icount)=ARRIni(LevInf)
  else
   d1=ALTInt(icount)-ALTIni(LevInf)
   d2=ALTIni(LevMax)-ALTInt(icount)
   ARRInt(icount)=(lmin/d1 + lmax/d2) / (1/d1 + 1/d2)
  endif
 else
  ARRInt(icount)=-9999.
 endif
 if ( (LevMax.eq.LevInf).and.(ALTInt(icount).eq.ALTIni(LevInf)) ) ARRInt(icount)=ARRIni(LevInf) !Very rare case when the last level of the input field has the same altitude than the last level of the output field.
enddo
end subroutine irregular_itp_dp

!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!
!!!!!!!

!Resampling of a data set by computing the average every NP points by NP points.
!New dimension is equal to SIZE_ARRAY/NP or INT(SIZE_ARRAY/NP) + 1.
!ATTENTION: the input parameters must verify SIZE_RS_ARRAY * NP = SIZE_ARRAY
!call resampling_average(input_array,size_input_array,number_of_points_for_the_average,output_array,size_output_array,sigma_array,
!value_to_be_discarded_from_average_computation)

SUBROUTINE RESAMPLING_AVERAGE(ARRAY,SIZE_ARRAY,NP,RS_ARRAY,SIZE_RS_ARRAY,SD_ARRAY,NO_VALUE)
 use mod_statistics
 implicit none

 integer,                     intent(in)  :: size_array     ! size of the input array
 integer,                     intent(in)  :: size_rs_array  ! size of the output array < size of the input array
 integer,                     intent(in)  :: np             ! number of points used in the computation of the average
 real,                        intent(in)  :: no_value       ! discarded value in the computation of the moving average
 real, dimension(size_array), intent(in)  :: array          ! input array

 real, dimension(size_rs_array),    intent(out)  :: rs_array       ! output array
 real, dimension(size_rs_array),    intent(out)  :: sd_array       ! standard deviation of the output values


 integer                                  :: i,j,inc
 integer                                  :: ibeg,iend
 integer, dimension(size_rs_array)        :: inc_a

if ( (size_rs_array*np).ne.size_array ) then
  print *, 'ALARM! ALARM! ALARM! Wrong size for output array. Please check.'
  print *, 'It should be', int(size_array / np),'.'
  print *, 'Input array dimension  = ',size_array
  print *, 'Output array dimension = ',size_rs_array
  print *, 'Number of points used in the computation of the average = ', np
  print *, 'Input array dimension / number of points used for the average = ',size_array/np
  stop
 endif

 rs_array=no_value
 sd_array=0

 do i=1,size_rs_array
  ibeg = i*np - np + 1
  iend = i*np
 inc=0
 do j=ibeg,iend
  if (array(j).ne.no_value) inc=inc+1
 enddo
  if (inc.ne.0.) call stats(array(ibeg:iend),np,rs_array(i),sd_array(i),inc_a(i),no_value)
 enddo
END SUBROUTINE RESAMPLING_AVERAGE

!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!
!!!!!!!!

!Compute a moving average of data.
!How to call it:
!call moving_average(input_array,size_of_input_array,N,output_array,discarded_value)
!Average at i€[1,size_of_input_array] is computed over the [i-N,i+N] interval (2N+1 points); 
!'output_array' has the same dimension as input_array;
!'discarded_value' is the value used to discard points from the average computation. A test is perform to see 
!wether it exists at least one point different from discarded_value in the interval [i-N,...,i,...,i+N]. If not, 
!then output_array(i)=discarded_value.

SUBROUTINE MOVING_AVERAGE(ARRAY,SIZE_ARRAY,NP_M_A,M_A_ARRAY,NO_VALUE)
 use mod_statistics
 implicit none

 integer,                     intent(in)  :: size_array  ! size of the input array
 integer,                     intent(in)  :: np_m_a      ! number of points used in the computation of the moving average = 2*np_m_a + 1
                                                         ! [i-np_m_a,.....,i,......,i+np_m_a] ----> i
 real,                        intent(in)  :: no_value    ! discarded value in the computation of the moving average
 real, dimension(size_array), intent(in)  :: array       ! input array
 
 real, dimension(size_array), intent(out) :: m_a_array   ! output array

 integer                                  :: i,j,itot,inc
 real, dimension(size_array)              :: sd_m_a
 real, dimension(2*np_m_a + 1)            :: zero   
 integer, dimension(size_array)           :: inc_m_a


 m_a_array = no_value
 sd_m_a    = 0.        
 inc_m_a   = 0
 zero = no_value
 
 do i=1,np_m_a
 inc=0
  do j=1,i+np_m_a
   if (array(j).ne.no_value) inc=inc+1
  enddo
  if (inc.ne.0.) call stats(array(1:i+np_m_a),i+np_m_a,m_a_array(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 itot=2*np_m_a+1
 do i=np_m_a+1,size_array-np_m_a-1
  inc=0
  do j=i-np_m_a,i+np_m_a
   if (array(j).ne.no_value) inc=inc+1
  enddo
  if (inc.ne.0) call stats(array(i-np_m_a:i+np_m_a),itot,m_a_array(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 do i=size_array-np_m_a,size_array
  inc=0
  do j=i-np_m_a,size_array
   if (array(j).ne.no_value) inc=inc+1
  enddo
  if (inc.ne.0.) call stats(array(i-np_m_a:size_array),size_array-i+np_m_a+1,m_a_array(i),sd_m_a(i),inc_m_a(i),no_value)
  if (inc.eq.0.) m_a_array(i)=no_value
 enddo
END SUBROUTINE MOVING_AVERAGE

!Identical to the preceding routine, except for the extra output variable SD_M_A

SUBROUTINE MOVING_AVERAGE_SD(ARRAY,SIZE_ARRAY,NP_M_A,M_A_ARRAY,sd_m_a,NO_VALUE)
 use mod_statistics
 implicit none

 integer,                     intent(in)  :: size_array  ! size of the input array
 integer,                     intent(in)  :: np_m_a      ! number of points used in the computation of the moving average = 2*np_m_a + 1
                                                         ! [i-np_m_a,.....,i,......,i+np_m_a] ----> i
 real,                        intent(in)  :: no_value    ! discarded value in the computation of the moving average
 real, dimension(size_array), intent(in)  :: array       ! input array
 
 real, dimension(size_array), intent(out) :: m_a_array   ! output array

 integer                                  :: i,j,itot,inc
 real, dimension(size_array), intent(out) :: sd_m_a
 real, dimension(2*np_m_a + 1)            :: zero   
 integer, dimension(size_array)           :: inc_m_a


 m_a_array = no_value
 sd_m_a    = 0.        
 inc_m_a   = 0
 zero = no_value
 
 do i=1,np_m_a
 inc=0
  do j=1,i+np_m_a
   if (array(j).ne.no_value) inc=inc+1
  enddo
  if (inc.ne.0.) call stats(array(1:i+np_m_a),i+np_m_a,m_a_array(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 itot=2*np_m_a+1
 do i=np_m_a+1,size_array-np_m_a-1
  inc=0
  do j=i-np_m_a,i+np_m_a
   if (array(j).ne.no_value) inc=inc+1
  enddo
  if (inc.ne.0) call stats(array(i-np_m_a:i+np_m_a),itot,m_a_array(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 do i=size_array-np_m_a,size_array
  inc=0
  do j=i-np_m_a,size_array
   if (array(j).ne.no_value) inc=inc+1
  enddo
  if (inc.ne.0.) call stats(array(i-np_m_a:size_array),size_array-i+np_m_a+1,m_a_array(i),sd_m_a(i),inc_m_a(i),no_value)
  if (inc.eq.0.) m_a_array(i)=no_value
 enddo
END SUBROUTINE MOVING_AVERAGE_SD


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

END MODULE MOD_ARRAYS
