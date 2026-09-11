MODULE MOD_ARRAYS_WD
implicit none
contains


!Compute a moving average of data.
!How to call it:
!call moving_average(input_array,size_of_input_array,N,output_array,discarded_value)
!Average at i€[1,size_of_input_array] is computed over the [i-N,i+N] interval (2N+1 points); 
!'output_array' has the same dimension as input_array;
!'discarded_value' is the value used to discard points from the average computation. A test is perform to see 
!wether it exists at least one point different from discarded_value in the interval [i-N,...,i,...,i+N]. If not, 
!then output_array(i)=discarded_value.

SUBROUTINE MOVING_AVERAGE_WIND_DIRECTION(VX,VY,SIZE_ARRAY,NP_M_A,M_A_WD,NO_VALUE)
 use mod_statistics_wd
 implicit none
 integer,                     intent(in)  :: size_array  ! size of the input array
 integer,                     intent(in)  :: np_m_a      ! number of points used in the computation of the moving average = 2*np_m_a + 1
                                                         ! [i-np_m_a,.....,i,......,i+np_m_a] ----> i
 real,                        intent(in)  :: no_value    ! discarded value in the computation of the moving average
 real, dimension(size_array), intent(in)  :: vx,vy       ! input array
 
 real, dimension(size_array), intent(out) :: m_a_wd   ! output array


 integer                                  :: i,j,itot,inc
 real, dimension(size_array)              :: sd_m_a
 integer, dimension(size_array)           :: inc_m_a

 m_a_wd = no_value
 sd_m_a    = 0.        
 
 do i=1,np_m_a
 inc=0
  do j=1,i+np_m_a
   if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
  enddo
  if (inc.ne.0.) call stats_wind_direction(vx(1:i+np_m_a),vy(1:i+np_m_a),i+np_m_a,m_a_wd(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 itot=2*np_m_a+1
 do i=np_m_a+1,size_array-np_m_a-1
  inc=0
  do j=i-np_m_a,i+np_m_a
   if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
  enddo
  if (inc.ne.0.) call stats_wind_direction(vx(i-np_m_a:i+np_m_a),vy(i-np_m_a:i+np_m_a),itot,m_a_wd(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 do i=size_array-np_m_a,size_array
  inc=0
  do j=i-np_m_a,size_array
   if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
  enddo
  if (inc.ne.0.) call stats_wind_direction(vx(i-np_m_a:size_array),vy(i-np_m_a:size_array),size_array-i+np_m_a+1,&
                                           m_a_wd(i),sd_m_a(i),inc_m_a(i),no_value)
  if (inc.eq.0.) m_a_wd(i)=no_value
 enddo
END SUBROUTINE MOVING_AVERAGE_WIND_DIRECTION

!Identical to the preceding routine, except for the extra output variable SD_M_A

SUBROUTINE MOVING_AVERAGE_WIND_DIRECTION_SD(VX,VY,SIZE_ARRAY,NP_M_A,M_A_WD,sd_m_a,NO_VALUE)
 use mod_statistics_wd
 implicit none
 integer,                     intent(in)  :: size_array  ! size of the input array
 integer,                     intent(in)  :: np_m_a      ! number of points used in the computation of the moving average = 2*np_m_a + 1
                                                         ! [i-np_m_a,.....,i,......,i+np_m_a] ----> i
 real,                        intent(in)  :: no_value    ! discarded value in the computation of the moving average
 real, dimension(size_array), intent(in)  :: vx,vy       ! input array
 
 real, dimension(size_array), intent(out) :: m_a_wd   ! output array


 integer                                  :: i,j,itot,inc
 real, dimension(size_array), intent(out) :: sd_m_a
 integer, dimension(size_array)           :: inc_m_a

 m_a_wd = no_value
 sd_m_a    = 0.        
 
 do i=1,np_m_a
 inc=0
  do j=1,i+np_m_a
   if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
  enddo
  if (inc.ne.0.) call stats_wind_direction(vx(1:i+np_m_a),vy(1:i+np_m_a),i+np_m_a,m_a_wd(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 itot=2*np_m_a+1
 do i=np_m_a+1,size_array-np_m_a-1
  inc=0
  do j=i-np_m_a,i+np_m_a
   if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
  enddo
  if (inc.ne.0.) call stats_wind_direction(vx(i-np_m_a:i+np_m_a),vy(i-np_m_a:i+np_m_a),itot,m_a_wd(i),sd_m_a(i),inc_m_a(i),no_value)
 enddo

 do i=size_array-np_m_a,size_array
  inc=0
  do j=i-np_m_a,size_array
   if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
  enddo
  if (inc.ne.0.) call stats_wind_direction(vx(i-np_m_a:size_array),vy(i-np_m_a:size_array),size_array-i+np_m_a+1,&
                                           m_a_wd(i),sd_m_a(i),inc_m_a(i),no_value)
  if (inc.eq.0.) m_a_wd(i)=no_value
 enddo
END SUBROUTINE MOVING_AVERAGE_WIND_DIRECTION_SD

!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!
!!!!!


!Resampling of a data set by computing the average every NP points by NP points.
!New dimension is equal to SIZE_ARRAY/NP or INT(SIZE_ARRAY/NP) + 1.
!ATTENTION: the input parameters must verify SIZE_RS_ARRAY * NP = SIZE_ARRAY
!call resampling_average(input_array,size_input_array,number_of_points_for_the_average,output_array,size_output_array,sigma_array,
!value_to_be_discarded_from_average_computation)

SUBROUTINE RESAMPLING_AVERAGE_WIND_DIRECTION(VX,VY,SIZE_ARRAY,NP,RS_WD,SIZE_RS_WD,SD_WD,NO_VALUE)
 use mod_statistics_wd
 implicit none
 integer,                     intent(in)  :: size_array     ! size of the input array
 integer,                     intent(in)  :: size_rs_wd     ! size of the output array < size of the input array
 integer,                     intent(in)  :: np             ! number of points used in the computation of the average
 real,                        intent(in)  :: no_value       ! discarded value in the computation of the moving average
 real, dimension(size_array), intent(in)  :: vx,vy          ! input array

 real, dimension(size_rs_wd),    intent(out)  :: rs_wd          ! output array
 real, dimension(size_rs_wd),    intent(out)  :: sd_wd          ! standard deviation of the output values
 


 integer                                  :: i,j,inc
 integer                                  :: ibeg,iend
 integer, dimension(size_rs_wd)        :: inc_a


if ( (size_rs_wd*np).ne.size_array ) then
  print *, 'ALARM! ALARM! ALARM! Wrong size for output array. Please check.'
  print *, 'It should be', int(size_array / np),'.'
  print *, 'Input array dimension  = ',size_array
  print *, 'Output array dimension = ',size_rs_wd  
  print *, 'Number of points used in the computation of the average = ', np
  print *, 'Input array dimension / number of points used for the average = ',size_array/np
  stop
 endif

 rs_wd=no_value
 sd_wd=0

 do i=1,size_rs_wd
  ibeg = i*np - np + 1
  iend = i*np
 inc=0
 do j=ibeg,iend
  if ( (vx(j).ne.no_value).and.(vy(j).ne.no_value) ) inc=inc+1
 enddo
  if (inc.ne.0.) call stats_wind_direction(vx(ibeg:iend),vy(ibeg:iend),np,rs_wd(i),sd_wd(i),inc_a(i),no_value)
 enddo
END SUBROUTINE RESAMPLING_AVERAGE_WIND_DIRECTION

SUBROUTINE ITP_CIRCULAR(LevIni,LevInt,ARRIni,ALTIni,ARRInt,ALTInt,delta,xmodulo,noval)
!Interpolation of a circular variable
!Input vector ARRIni of dimension LevIni; interpolated on LevInt levels, ouptut vector: ARRInt
!-noval: if values at z or z+1 (of ARRIni) is equal noval, no interpolation is done between the 2 points and all resulted 
!interpolated levels between z and z+1 (so for ARRInt) are put equal to noval
!-xmodulo: for the wind direction, please put xmodulo=360 (in degrees)
!-delta: the resolution of the interpolated grid  
implicit none
INTEGER, INTENT(IN)  :: LevIni,LevInt
REAL, INTENT(IN) :: delta,xmodulo,noval

REAL, DIMENSION(:), INTENT(IN)  :: ARRIni,ALTIni
REAL, DIMENSION(:), INTENT(OUT) :: ARRInt,ALTInt

INTEGER :: ICOUNT, JCOUNT, LevInf
REAL :: lmin,lmax,d1,d2

lmin=0.
lmax=0.
LevInf=0

DO ICOUNT=1,LevInt !construction of the interpolated grid with a resolution of delta
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
  if(abs(lmax-lmin).gt.(xmodulo/2.)) then 
!   print *, 'Routine ITP_CIRCULAR activated, |lmin-lmax|>',xmodulo/2,'between levels',LevInf,'and',LevInf+1
!   print *, 'lmin at level',LevInf,'=',lmin,'and lmax at level',LevInf+1,'=',lmax
   if(lmin.lt.(xmodulo/2.)) then 
    lmin = lmin + xmodulo
   else
    lmax = lmax + xmodulo
   endif
   ARRInt(ICOUNT) = (lmin/d1 + lmax/d2) / (1/d1 + 1/d2)
   if (ARRInt(ICOUNT).gt.xmodulo) ARRInt(ICOUNT) = ARRInt(ICOUNT) - xmodulo
!   print *, 'Interpolated value=',ARRInt(ICOUNT),'between lmin(mod)=',lmin,'and lmax(mod)=',lmax
  else
   ARRInt(ICOUNT)=(lmin/d1 + lmax/d2) / (1/d1 + 1/d2)
  endif

  else !else loop test noval

  ARRInt(ICOUNT)=noval

  endif !loop test noval   

 ENDIF
ENDDO
END SUBROUTINE ITP_CIRCULAR

END MODULE MOD_ARRAYS_WD
