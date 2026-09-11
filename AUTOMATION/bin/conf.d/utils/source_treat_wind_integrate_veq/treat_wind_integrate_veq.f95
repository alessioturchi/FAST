program treat_wind_integrate_veq

! FORTRAN 2008 stuff (need updating gcc)
!  use, intrinsic :: iso_fortran_env
  use mod_statistics
  use mod_statistics_wd
  use mod_arrays
  use mod_read_dat
  implicit none
!  integer, parameter :: sp = REAL32
!  integer, parameter :: dp = REAL64
!  integer, parameter :: qp = REAL128
  integer, parameter :: dp = kind(1.d0)
  integer :: i,j,argnum,inttmp,numlevels,nline,ncol,npoints
  integer :: starttime,endtime,use_it1,doweight
  integer :: startheight,endheight,levelstartplot,levelendplot
!  integer h0,MedAlt,startlev,startmed,IntLev
  integer, parameter :: narg=8
  real :: firstlevel,lastlevel,tmpsum
  integer :: colheight=2
  integer :: coldata=1
  integer :: coldatacn2=1
  real, dimension(:,:), allocatable :: variable,wind,variablecn2,cn2
  real, dimension(:,:), allocatable :: corrections1
!  real, dimension(:,:), allocatable :: wd
  real, dimension(:), allocatable :: heights,wind_linc,wind_linc_sd
  real, dimension(:), allocatable :: wind_linc_eq
  real :: wind_mean,wind_sd
  integer, dimension(:), allocatable :: wind_linc_inc
  integer :: wind_inc
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile1,cn2file
  real, parameter :: Pi=3.141592654
  integer IntLev,dim_resample,dim_array_res,rest_array_res,dim_maverage
  real :: pas,timestep,delta_t_res
  real, dimension(:,:), allocatable :: wind_int,cn2_int
  real, dimension(:), allocatable :: heights_int,time_res
  real, dimension(:), allocatable :: wind_mares,wind_mares_sd,time,wind_ma
  real, dimension(:), allocatable :: wind_eq_mares,wind_mares_eq_sd,wind_eq_ma
  real, dimension(:), allocatable :: wind_ma_sd,wind_eq_ma_sd,sd_wind_mares
  real, dimension(:), allocatable :: sd_wind_mares_sd,sd_wind_eq_mares,sd_wind_mares_eq_sd

! Get initial arguments
  argnum=command_argument_count()
  if (argnum < narg-2 .OR. argnum > narg) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - wind_prof_pn.dat dat file'
    print*, '!!!      2 - name of output file'
    print*, '!!!      3 - start time (min)'
    print*, '!!!      4 - end time (min)'
    print*, '!!!      5 - start height (m, I5)'
    print*, '!!!      6 - final height (m, I5)'
    print*, '!!!      7 - cn2_pn.dat file for weighting - OPTIONAL'
    print*, '!!!      8 - corrections file path for windspeed - OPTIONAL'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
!    print*, '*',trim(arg(i)),'*'
  end do
  namefile=arg(1)
  fileout=arg(2)
  read(arg(3),'(I5)') starttime
  read(arg(4),'(I5)') endtime
  read(arg(5),'(I5)') startheight
  read(arg(6),'(I5)') endheight
  use_it1=0
  doweight=0
  if (argnum >= narg-1) then
    cn2file=arg(7)
    doweight=1
  end if
  if (argnum == narg) then
    corrfile1=arg(8)
    call read_corrfile(corrfile1,corrections1,use_it1)
  end if

! Read the .dat file and get the variable array
  call read_dat_file_pv(namefile,variable)
  call apply_corrfile(variable,corrections1,coldata,colheight,use_it1)

  if (doweight .eq. 1) then
    call read_dat_file_pv(cn2file,variablecn2)
  end if

  nline=size(variable,1)
  ncol=size(variable,2)

  if (doweight .eq. 1) then
    if (size(variablecn2,1) .ne. nline) then
      print*,'!!! treat_wind_integrate_veq: number of lines in '//trim(cn2file)//' are different from '//trim(namefile)
      call exit(1)
    end if
  end if

  timestep=variable(1,ncol)
 
  if (doweight .eq. 1) then
    if (variablecn2(1,ncol) .ne. timestep) then
      print*,'!!! treat_wind_integrate_veq: timestep in '//trim(cn2file)//' is different from '//trim(namefile)
      call exit(1)
    end if
  end if

!Rescale start time by timestep in order to have the correct number of actual
!points
  starttime=int(starttime*60/timestep)+1
  endtime=int(endtime*60/timestep)+1

!Get the level numbers
  firstlevel=variable(1,colheight)
  do i=2,nline
    if ( variable(i,colheight) == firstlevel ) then
      lastlevel=variable(i-1,colheight)
      numlevels=i-1
      exit
    end if
  end do
!Get the number of points in time from the line number
  npoints=int(nline/numlevels)
  if (mod(real(nline),real(numlevels)) .ne. 0) then
    print*, '!!! treat_wind_integrate_veq: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
  print*, 'Columns:       ',ncol
  print*, 'Lines:         ',nline
  print*, 'Levels:        ',numlevels
  print*, 'Lowest point:  ',firstlevel
  print*, 'Highest point: ',lastlevel

  if (mod(real(nline),real(numlevels)) .ne. 0) then
    print*, '!!! treat_wind_integrate_veq: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
!Move the data into the readable arrays, one for each interesting variable
  allocate(wind(numlevels,npoints))
  if (doweight .eq. 1) then
    allocate(cn2(numlevels,npoints))
  end if
!  allocate(wd(numlevels,npoints))
  allocate(heights(numlevels))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      wind(j,i)=variable(inttmp+j,coldata)
      if (doweight .eq. 1) then
        cn2(j,i)=variablecn2(inttmp+j,coldatacn2)
      end if
    end do
  end do
  heights(:)=variable(1:numlevels,colheight)
  deallocate(variable)

!Tipically we want to offset the heights by the ground level
  heights(:)=heights(:)-heights(1)
!Get the proper time axis

  allocate(time(npoints))
  do i=1,npoints
    time(i)=i*timestep
  end do

  if ( starttime >= npoints) then
    print*, '!!! treat_wind_integrate_veq: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_wind_integrate_veq: end time is greater than total time'
    call exit(1)
  end if

  print*, 'Points:        ',npoints
  print*, 'Timestep:      ',timestep

!Get the height step from the first MESO-NH step
!  pas=heights(2)-heights(1)
  pas=20.
  print*, 'DELTA(Z): ',pas
!The number of levels
  IntLev=int((lastlevel-firstlevel)/pas)
  print*, 'Number of levels after interpolation: ',IntLev
  allocate(wind_int(IntLev,npoints))
  if (doweight .eq. 1) then
    allocate(cn2_int(IntLev,npoints))
  end if
!  allocate(wd_int(IntLev,npoints))
  allocate(heights_int(IntLev))
!Perform interpolation
  do i=1,npoints
    call ITP(numlevels,IntLev,wind(:,i),heights,wind_int(:,i),heights_int,pas,9999.9)
    if (doweight .eq. 1) then
      call ITP(numlevels,IntLev,cn2(:,i),heights,cn2_int(:,i),heights_int,pas,9999.9)
    end if
  end do


!Get the heights were we want our average to start and end  
  levelstartplot=1
  levelendplot=1
  do i=1,IntLev
    if ( heights_int(i) .le. startheight) levelstartplot=i
    if ( heights_int(i) .le. endheight) levelendplot=i+1
  end do

  print*, 'Start height:  ',heights_int(levelstartplot)
  print*, 'Final height:  ',heights_int(levelendplot)
  print*, 'Start level:   ',levelstartplot
  print*, 'Final level:   ',levelendplot

  allocate(wind_linc(npoints))
  allocate(wind_linc_sd(npoints))
  allocate(wind_linc_inc(npoints))
  allocate(wind_linc_eq(npoints))

    if (doweight .eq. 1) then
    end if
!Perform statistics
  do i=1,npoints
! Compute V_eq
    if (doweight .eq. 1) then
      tmpsum=sum(cn2_int(levelstartplot:levelendplot,i))
      wind_linc_eq(i)=0.
      do j=levelstartplot,levelendplot
        wind_linc_eq(i)=wind_linc_eq(i)+cn2_int(j,i)*(abs(wind_int(j,i))**(5./3.))
      end do
      wind_linc_eq(i)=wind_linc_eq(i)/tmpsum
      wind_linc_eq(i)=wind_linc_eq(i)**(0.600)
    end if
! Compute <V>
    call stats(wind_int(levelstartplot:levelendplot,i),levelendplot-levelstartplot+1,&
         &wind_linc(i),wind_linc_sd(i),wind_linc_inc(i),9999.9)
  end do

  call stats(wind_linc(starttime:endtime),endtime-starttime+1,wind_mean,wind_sd,wind_inc,9999.9)

!Perform moving avaerage over an hour worth of samples
  dim_maverage=floor(1800.0/timestep)
  allocate(wind_ma(npoints))
  allocate(wind_ma_sd(npoints))
  call MOVING_AVERAGE_SD(wind_linc,npoints,dim_maverage,wind_ma,wind_ma_sd,9999999.0)
  allocate(wind_eq_ma(npoints))
  allocate(wind_eq_ma_sd(npoints))
  call MOVING_AVERAGE_SD(wind_linc_eq,npoints,dim_maverage,wind_eq_ma,wind_eq_ma_sd,9999999.0)

!!Perform resampling average
  dim_resample=floor(1200.0/timestep)
  dim_array_res=floor(real(npoints)/real(dim_resample))
  !remove from output the remainder of the above division, startin from the first point of the array.
  rest_array_res=int(mod(npoints,dim_resample))
  allocate(wind_mares(dim_array_res))
  allocate(wind_mares_sd(dim_array_res))
  allocate(sd_wind_mares(dim_array_res))
  allocate(sd_wind_mares_sd(dim_array_res))
  call RESAMPLING_AVERAGE(wind_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,wind_mares,&
       &dim_array_res,wind_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(wind_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_wind_mares,&
       &dim_array_res,sd_wind_mares_sd,9999999.0)
  allocate(wind_eq_mares(dim_array_res))
  allocate(wind_mares_eq_sd(dim_array_res))
  allocate(sd_wind_eq_mares(dim_array_res))
  allocate(sd_wind_mares_eq_sd(dim_array_res))
  call RESAMPLING_AVERAGE(wind_eq_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,wind_eq_mares,&
       &dim_array_res,wind_mares_eq_sd,9999999.0)
  call RESAMPLING_AVERAGE(wind_eq_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_wind_eq_mares,&
       &dim_array_res,sd_wind_mares_eq_sd,9999999.0)

  delta_t_res=time(rest_array_res+dim_resample+1)-time(rest_array_res+1)

  allocate(time_res(dim_array_res))
  do i=1,dim_array_res
    time_res(i)=time(rest_array_res+((i-1)*dim_resample)+1)+(delta_t_res/2)
  end do


!Write out the file to pass to the plotting routine
  open(unit=20,status='new',file=fileout,form='formatted')
!  write(20,*) '### timestep (s), start height(m), end height(m), start time (s), endtime (s), <V>_MEAN, <V>_SD ,&
!              & MAX WIND, MIN WIND ###'
  write(20,*) '### timestep (s), start height(m), end height(m), start time (s), endtime (s), <V>_MEAN, <V>_SD ,&
              & MAX WIND EQ, MIN WIND EQ, MAX <V>, MIN <V> ###'
!  write(20,*) timestep,heights_int(levelstartplot),heights_int(levelendplot),time(starttime),time(endtime), wind_mean, wind_sd&
!              &,maxval([wind_mares+sd_wind_mares,wind_eq_mares+sd_wind_eq_mares])&
!              &,minval([wind_mares-sd_wind_mares,wind_eq_mares-sd_wind_eq_mares]
  write(20,*) timestep,heights_int(levelstartplot),heights_int(levelendplot),time(starttime),time(endtime), wind_mean, wind_sd&
              &,maxval(wind_eq_mares+sd_wind_eq_mares)&
              &,minval(wind_eq_mares-sd_wind_eq_mares)&
              &,maxval(wind_mares+sd_wind_mares)&
              &,minval(wind_mares-sd_wind_mares)
  if (doweight .eq. 1) then
    write(20,*) '### TIME (s), <V> (m/s), <V> SD, V_eq (m/s), V_eq SD, ###'
    do i=1,dim_array_res
      write(20,*) time_res(i),wind_mares(i),sd_wind_mares(i),wind_eq_mares(i),sd_wind_eq_mares(i)
    end do
  else
    write(20,*) '### TIME (s), <V> (m/s), <V> SD ###'
    do i=1,dim_array_res
      write(20,*) time_res(i),wind_mares(i),wind_mares_sd(i)
    end do
  end if
  close(20)

end program treat_wind_integrate_veq

