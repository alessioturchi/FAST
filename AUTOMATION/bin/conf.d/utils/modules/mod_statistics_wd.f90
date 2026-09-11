MODULE MOD_STATISTICS_WD
implicit none
contains

!STATS computes the mean value of an winddir array of real and the corresponding sample standard deviation
!
!sd= sqrt(SUM(x-mean)²/(N-1))
!
!When winddir(i)=no_value, this value is rejected from the computation of the mean and the sd.
!Thus INC is always inferior or equal to SIZE_ARRAY.
!
! VX: input vector
! SIZE_ARRAY: dimension of the input vector
! MEAN: average
! SD:standard deviation
! INC:number of elements on which we calculate the mean and/or the sd
! NO_VALUE:value that we wish to reject from the calculation of the mean and/or
! the sd

SUBROUTINE STATS_WIND_DIRECTION(VX,VY,SIZE_ARRAY,MEAN,SD,INC,NO_VALUE)
 implicit none
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: VX,VY
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: MEAN,SD
 INTEGER, INTENT(OUT) :: INC

 INTEGER :: I
 REAL :: SUM_DIFF_WD
 REAL :: MEAN_VX,MEAN_VY,Pi
 REAL, DIMENSION(SIZE_ARRAY) :: WD

 Pi=3.141592654
 MEAN_VX=0
 MEAN_VY=0
 INC=0
 MEAN=NO_VALUE
 DO I=1,SIZE_ARRAY
  IF ( (VX(I).NE.NO_VALUE).AND.(VY(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   MEAN_VX = MEAN_VX + VX(I)
   MEAN_VY = MEAN_VY + VY(I)
  ENDIF
 ENDDO
 if (mean_vx.eq.0.) then
  if (mean_vy.lt.0.) mean=0.
  if (mean_vy.gt.0.) mean=180.
 else  
  IF (INC.ne.0) then 
   MEAN = 180*ATAN(MEAN_VY/MEAN_VX)/Pi !Resulting mean wind direction
   if (mean_vx.lt.0.) MEAN = 90 - MEAN
   if (mean_vx.gt.0.) MEAN = 270 - MEAN
   IF (MEAN.lt.0) MEAN = MEAN +360.
  endif
 endif
 MEAN_VX = MEAN_VX / INC
 MEAN_VY = MEAN_VY / INC


 WD=NO_VALUE
 DO I=1,SIZE_ARRAY
  IF ( (VX(I).NE.NO_VALUE).AND.(VY(I).NE.NO_VALUE) ) then 
    WD(I) = 180*ATAN(VY(I)/VX(I))/Pi
    if (vx(i).lt.0.) WD(I) = 90 - WD(I)
    if (vx(i).gt.0.) WD(I) = 270 - WD(I)
    IF (WD(I).lt.0.) WD(I)=WD(I)+360.
  endif
 ENDDO



 SUM_DIFF_WD=0
 SD=0
 INC=0
 DO I=1,SIZE_ARRAY
  IF ( (WD(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   IF ( ABS(WD(I) - MEAN).le.180 ) SUM_DIFF_WD = SUM_DIFF_WD + (WD(I) - MEAN)**2
   IF ( ABS(WD(I) - MEAN).ge.180 ) THEN 
    IF ( WD(I).gt.MEAN ) SUM_DIFF_WD = SUM_DIFF_WD + ( (WD(I)-360) - MEAN)**2
    IF ( WD(I).lt.MEAN ) SUM_DIFF_WD = SUM_DIFF_WD + ( (WD(I)+360) - MEAN)**2
   ENDIF
  ENDIF
 ENDDO
 IF(INC.NE.1) THEN
  SUM_DIFF_WD = SUM_DIFF_WD / (INC-1)
 ENDIF
 SD = SQRT(SUM_DIFF_WD)
END SUBROUTINE STATS_WIND_DIRECTION

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

!STATS computes the BIAS and the RMSE of 2 arrays of real
!
!BIAS=( sum(Yi-Xi) / N ) 
!RMSE=sqrt( sum(Yi-Xi)²/ N )
!
!When x(i) or y(i)=no_value, this value is rejected from the computation.
!Thus INC is always inferior or equal to SIZE_ARRAY.
! 

SUBROUTINE BIAS_RMSE_WIND_DIRECTION(ARRAY2,ARRAY1,SIZE_ARRAY,BIAS,RMSE,INC,NO_VALUE)
 implicit none
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: ARRAY1,ARRAY2
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: BIAS,RMSE
 INTEGER, INTENT(OUT) :: INC

 INTEGER :: I
 REAL    :: DIFF

 DIFF=0.d0
 BIAS=0
 RMSE=0
 INC=0
 DO I=1,SIZE_ARRAY
  IF ( (ARRAY1(I).NE.NO_VALUE) .AND. (ARRAY2(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   IF ( ABS(ARRAY1(I) - ARRAY2(I)).le.180 ) DIFF = ARRAY1(I) - ARRAY2(I) 
   IF ( ABS(ARRAY1(I) - ARRAY2(I)).ge.180 ) THEN
    IF ( ARRAY1(I).gt.ARRAY2(I) ) DIFF =  (ARRAY1(I)-360) - ARRAY2(I)
    IF ( ARRAY1(I).lt.ARRAY2(I) ) DIFF =  (ARRAY1(I)+360) - ARRAY2(I)
   ENDIF
   BIAS = BIAS + DIFF
   RMSE = RMSE + (DIFF)**2
  ENDIF
 ENDDO
 if (INC.ne.0.) then
  BIAS = BIAS / INC
  RMSE = sqrt (RMSE / INC)
 else
  BIAS=NO_VALUE
  RMSE=NO_VALUE
 endif
END SUBROUTINE BIAS_RMSE_WIND_DIRECTION

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

!Circular coefficient correlation by Fisher and Lee (1983).
!http://cnx.org/content/m22974/latest/
subroutine ccc(n,wd1,wd2,noval1,coeff,noval2)
implicit none
integer, intent(in)            :: n
real, intent(in)               :: noval1
real, intent(in),optional      :: noval2
real, dimension(n), intent(in) :: wd1,wd2
real, intent(out)              :: coeff

real, dimension(n) :: wd_1,wd_2
integer :: i,j
real    :: sum1,sum2,sum3,tmp
real    :: Pi

tmp=noval1
tmp=noval2

Pi=3.141592654
do i=1,n
 wd_1(i) = wd1(i) * Pi / 180.
 wd_2(i) = wd2(i) * Pi / 180.
enddo

sum1=0.
do i=1,n-1
 do j=i+1,n
  sum1 = sum1 + sin(wd_1(i)-wd_1(j)) * sin(wd_2(i)-wd_2(j))
 enddo
enddo
sum2=0.
do i=1,n-1
 do j=i+1,n
  sum2 = sum2 + ( sin(wd_1(i)-wd_1(j)) )**2
 enddo
enddo
sum3=0.
do i=1,n-1
 do j=i+1,n
  sum3 = sum3 + ( sin(wd_2(i)-wd_2(j)) )**2
 enddo
enddo

coeff = sum1 / sqrt (sum2*sum3)
end subroutine ccc

!array1=reference (obs) from which xlim1 and xlim2 and xlim3 have been extracted
subroutine hit_rate_quart(array1,array2,size_array,xlim1,xlim2,xlim3,noval,tab_hr,pod,pc,ebd,lflag)
implicit none

logical, intent(in), optional :: lflag !TRUE=with percent, FALSE=number of points
integer, intent(in) :: size_array
real,dimension(size_array), intent(in) :: array1,array2
real, intent(in) :: xlim1,xlim2,xlim3,noval
real, dimension(4,4), intent(out) :: tab_hr
real, dimension(4), intent(out) ::pod
real, intent(out) :: pc, ebd

integer :: i,icount
real :: a,b,c,d,e,f,g,h,ii,j,k,l,m,n,o,p

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
   if ( (array2(i).gt.xlim2).and.(array2(i).le.xlim3) ) tab_hr(3,1) = tab_hr(3,1) + 1
   if (array2(i).gt.xlim3)                              tab_hr(4,1) = tab_hr(4,1) + 1
  endif
  if ( (array1(i).gt.xlim1).and.(array1(i).le.xlim2) ) then
   if (array2(i).le.xlim1)                              tab_hr(1,2) = tab_hr(1,2) + 1
   if ( (array2(i).gt.xlim1).and.(array2(i).le.xlim2) ) tab_hr(2,2) = tab_hr(2,2) + 1
   if ( (array2(i).gt.xlim2).and.(array2(i).le.xlim3) ) tab_hr(3,2) = tab_hr(3,2) + 1
   if (array2(i).gt.xlim3)                              tab_hr(4,2) = tab_hr(4,2) + 1
  endif
  if ( (array1(i).gt.xlim2).and.(array1(i).le.xlim3) ) then
   if (array2(i).le.xlim1)                              tab_hr(1,3) = tab_hr(1,3) + 1
   if ( (array2(i).gt.xlim1).and.(array2(i).le.xlim2) ) tab_hr(2,3) = tab_hr(2,3) + 1
   if ( (array2(i).gt.xlim2).and.(array2(i).le.xlim3) ) tab_hr(3,3) = tab_hr(3,3) + 1
   if (array2(i).gt.xlim3)                              tab_hr(4,3) = tab_hr(4,3) + 1
  endif
   if (array1(i).gt.xlim3) then
   if (array2(i).le.xlim1)                              tab_hr(1,4) = tab_hr(1,4) + 1
   if ( (array2(i).gt.xlim1).and.(array2(i).le.xlim2) ) tab_hr(2,4) = tab_hr(2,4) + 1
   if ( (array2(i).gt.xlim2).and.(array2(i).le.xlim3) ) tab_hr(3,4) = tab_hr(3,4) + 1
   if (array2(i).gt.xlim3)                              tab_hr(4,4) = tab_hr(4,4) + 1
  endif
 endif
enddo

print *, 'Hit rate computed on',icount,'points.'

if ( (present(lflag).and.(lflag.eqv..True.)).or.(.not.present(lflag)) ) then
tab_hr = (tab_hr / icount)*100. !in %
a = tab_hr(1,1)
b = tab_hr(1,2)
c = tab_hr(1,3)
d = tab_hr(1,4)
e = tab_hr(2,1)
f = tab_hr(2,2)
g = tab_hr(2,3)
h = tab_hr(2,4)
ii = tab_hr(3,1)
j = tab_hr(3,2)
k = tab_hr(3,3)
l = tab_hr(3,4)
m = tab_hr(4,1)
n = tab_hr(4,2)
o = tab_hr(4,3)
p = tab_hr(4,4)

print *, 'X<',xlim1,'<X<',xlim2,'<X<',xlim3,'<X'
print *, tab_hr(1,1),tab_hr(1,2),tab_hr(1,3),tab_hr(1,4)
print *, tab_hr(2,1),tab_hr(2,2),tab_hr(2,3),tab_hr(2,4)
print *, tab_hr(3,1),tab_hr(3,2),tab_hr(3,3),tab_hr(3,4)
print *, tab_hr(4,1),tab_hr(4,2),tab_hr(4,3),tab_hr(4,4)
pod(1)=a/(a+e+ii+m)
print *, 'POD(event1)=', pod(1)
pod(2)=f/(b+f+j+n)
print *, 'POD(event2)=', pod(2)
pod(3)=k/(c+g+k+o)
print *, 'POD(event3)=', pod(3)
pod(4)=p/(d+h+l+p)
print *, 'POD(event4)=', pod(4)
pc=(a+f+k+p)
print*,'PC=',pc
ebd=(c+h+ii+n)
print*,'ebd=',ebd
endif

! Expressed in numbers
if ( (present(lflag).and.(lflag.eqv..false.)) ) then
tab_hr = tab_hr !in %
a = tab_hr(1,1)
b = tab_hr(1,2)
c = tab_hr(1,3)
d = tab_hr(1,4)
e = tab_hr(2,1)
f = tab_hr(2,2)
g = tab_hr(2,3)
h = tab_hr(2,4)
ii = tab_hr(3,1)
j = tab_hr(3,2)
k = tab_hr(3,3)
l = tab_hr(3,4)
m = tab_hr(4,1)
n = tab_hr(4,2)
o = tab_hr(4,3)
p = tab_hr(4,4)

print *, 'X<',xlim1,'<X<',xlim2,'<X<',xlim3,'<X'
print *, tab_hr(1,1),tab_hr(1,2),tab_hr(1,3),tab_hr(1,4)
print *, tab_hr(2,1),tab_hr(2,2),tab_hr(2,3),tab_hr(2,4)
print *, tab_hr(3,1),tab_hr(3,2),tab_hr(3,3),tab_hr(3,4)
print *, tab_hr(4,1),tab_hr(4,2),tab_hr(4,3),tab_hr(4,4)
pod(1)=(a/(a+e+ii+m))*100
print *, 'POD(event1)=', pod(1)
pod(2)=(f/(b+f+j+n))*100
print *, 'POD(event2)=', pod(2)
pod(3)=(k/(c+g+k+o))*100
print *, 'POD(event3)=', pod(3)
pod(4)=(p/(d+h+l+p))*100
print *, 'POD(event4)=', pod(4)
pc=((a+f+k+p)/icount)*100
print*,'PC=',pc
ebd=((c+h+ii+n)/icount)*100
print*,'ebd=',ebd
endif

end subroutine hit_rate_quart

SUBROUTINE BIAS_RMSE_SIGMA_WIND_DIRECTION(ARRAY2,ARRAY1,SIZE_ARRAY,BIAS,RMSE,SIGMA,INC,NO_VALUE)
 implicit none
 INTEGER, INTENT(IN) :: SIZE_ARRAY
 REAL, DIMENSION(SIZE_ARRAY), INTENT(IN) :: ARRAY1,ARRAY2
 REAL, INTENT(IN) :: NO_VALUE
 REAL, INTENT(OUT) :: BIAS,RMSE,SIGMA
 INTEGER, INTENT(OUT) :: INC

 INTEGER :: I
 REAL    :: DIFF

 DIFF=0.d0
 BIAS=0       
 RMSE=0        
 INC=0
 DO I=1,SIZE_ARRAY
  IF ( (ARRAY1(I).NE.NO_VALUE) .AND. (ARRAY2(I).NE.NO_VALUE) ) THEN
   INC = INC+1
   IF ( ABS(ARRAY1(I) - ARRAY2(I)).le.180 ) DIFF = ARRAY1(I) - ARRAY2(I)
   IF ( ABS(ARRAY1(I) - ARRAY2(I)).ge.180 ) THEN
    IF ( ARRAY1(I).gt.ARRAY2(I) ) DIFF =  (ARRAY1(I)-360) - ARRAY2(I)
    IF ( ARRAY1(I).lt.ARRAY2(I) ) DIFF =  (ARRAY1(I)+360) - ARRAY2(I)
   ENDIF
   BIAS = BIAS + DIFF
   RMSE = RMSE + (DIFF)**2
  ENDIF
 ENDDO
 if (INC.ne.0.) then 
  BIAS = BIAS / INC
  RMSE = sqrt (RMSE / INC)
  SIGMA=SQRT(RMSE**2-BIAS**2)
 else
  BIAS=NO_VALUE
  RMSE=NO_VALUE
  SIGMA=NO_VALUE
 endif
END SUBROUTINE BIAS_RMSE_SIGMA_WIND_DIRECTION

END MODULE MOD_STATISTICS_WD
