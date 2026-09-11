program treat_wind_pv_avg

!#define NOINTERP

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
  integer :: timestep_min,starttime,endtime,use_it1,use_it2
  integer :: startheight,endheight,levelstartplot,levelendplot
!  integer h0,MedAlt,startlev,startmed,IntLev
  integer, parameter :: narg=8
  real :: firstlevel,lastlevel
  real :: maxvalue,minvalue,maxvalue_wd,minvalue_wd,timestep
  integer :: colheight=3
  integer :: coldata1=1
  integer :: coldata2=2
  real, dimension(:,:), allocatable :: variable,wind,windX,windY
  real, dimension(:,:), allocatable :: corrections1,corrections2
!  real, dimension(:,:), allocatable :: wd
  real, dimension(:), allocatable :: heights,wind_mean,wind_sd,wd_mean,wd_sd
  integer, dimension(:), allocatable :: time,wind_inc,wd_inc
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile1,corrfile2
  real, parameter :: Pi=3.141592654
#ifndef NOINTERP
  integer IntLev
  real :: pas
  real, dimension(:,:), allocatable :: wind_int,windX_int,windY_int
!  real, dimension(:,:), allocatable :: wind_int
  real, dimension(:), allocatable :: heights_int
#endif

! Get initial arguments
  argnum=command_argument_count()
  if (argnum < narg-2 .OR. argnum > narg) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - vx_vy_prof_pn.dat dat file'
    print*, '!!!      2 - name of output file'
    print*, '!!!      3 - start time (min)'
    print*, '!!!      4 - end time (min)'
    print*, '!!!      5 - start height (m, I5)'
    print*, '!!!      6 - final height (m, I5)'
    print*, '!!!      7 - corrections file path for windspeed - OPTIONAL'
    print*, '!!!      8 - corrections file path for winddirection - OPTIONAL'
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
  if (argnum >= narg-1) then
    corrfile1=arg(7)
    call read_corrfile(corrfile1,corrections1,use_it1) 
  end if
  use_it2=0
  if (argnum == narg) then
    corrfile2=arg(8)
    call read_corrfile(corrfile2,corrections2,use_it2) 
  end if

! Read the .dat file and get the variable array
  call read_dat_file_pv(namefile,variable)
  call apply_corrfile(variable,corrections1,coldata1,colheight,use_it1)
  call apply_corrfile(variable,corrections2,coldata2,colheight,use_it2)

  nline=size(variable,1)
  ncol=size(variable,2)

  timestep=variable(1,ncol)
  timestep_min=int(timestep/60.0)

!Rescale start time by timestep in order to have the correct number of actual
!points
  starttime=int(starttime/timestep_min)
  endtime=int(endtime/timestep_min)

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
    print*, '!!! treat_wind_pv_avg: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
  print*, 'Columns:       ',ncol
  print*, 'Lines:         ',nline
  print*, 'Levels:        ',numlevels
  print*, 'Lowest point:  ',firstlevel
  print*, 'Highest point: ',lastlevel

  if (mod(real(nline),real(numlevels)) .ne. 0) then
    print*, '!!! treat_wind_pv_avg: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
!Move the data into the readable arrays, one for each interesting variable
  allocate(windX(numlevels,npoints))
  allocate(windY(numlevels,npoints))
  allocate(wind(numlevels,npoints))
!  allocate(wd(numlevels,npoints))
  allocate(heights(numlevels))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      windX(j,i)=variable(inttmp+j,coldata1)
      windY(j,i)=variable(inttmp+j,coldata2)
    end do
  end do
  heights(:)=variable(1:numlevels,colheight)
  deallocate(variable)

!Tipically we want to offset the heights by the ground level
  heights(:)=heights(:)-heights(1)
!Get the proper time axis
  do i=1,npoints
    do j=1,numlevels
      wind(j,i)=sqrt((windX(j,i)**2) + (windY(j,i)**2))
    end do
  end do

!  do i=1,npoints
!    do j=1,numlevels
!      if (windX(j,i).eq.0.) then
!        if (windY(j,i).lt.0.) wd(j,i)=0.
!        if (windY(j,i).gt.0.) wd(j,i)=180.
!      else  
!        wd(j,i) = 180*atan(windY(j,i)/windX(j,i))/Pi
!        if (windX(j,i).lt.0.) wd(j,i) = 90 - wd(j,i)
!        if (windX(j,i).gt.0.) wd(j,i) = 270 - wd(j,i)
!        if (wd(j,i).lt.0) wd(j,i) = wd(j,i) +360.
!      endif
!    end do
!  end do

  allocate(time(npoints))
  do i=1,npoints
    time(i)=i*timestep_min
  end do

  if ( starttime >= npoints) then
    print*, '!!! treat_wind_pv_avg: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_wind_pv_avg: end time is greater than total time'
    call exit(1)
  end if
  
  print*, 'Points:        ',npoints
  print*, 'Timestep:      ',timestep_min
  print*, 'Start time:    ',time(starttime)
  print*, 'Final time:    ',time(endtime)

#ifdef NOINTERP
!The folllowing is if we don't want to interpolate the levels produced by
!MESO-NH on its nonlinearly distributed level heights
  allocate(wind_mean(numlevels))
  allocate(wind_sd(numlevels))
  allocate(wind_inc(numlevels))
  allocate(wd_mean(numlevels))
  allocate(wd_sd(numlevels))
  allocate(wd_inc(numlevels))
!Get the heights were we want our plot to start and end
  levelstartplot=1
  levelendplot=1
  do i=1,numlevels
    if ( heights_int(i) .le. startheight) levelstartplot=i
    if ( heights_int(i) .le. endheight) levelendplot=i
  end do
 
  print*, 'Final time:    ',time(endtime)
  print*, 'Start height:  ',heights(levelstartplot)
  print*, 'Final height:  ',heights(levelendplot)
  print*, 'Start level:   ',levelstartplot
  print*, 'Final level:   ',levelendplot

!Perform statistics
  do i=1,numlevels
    call stats(wind(i,starttime:endtime),endtime-starttime+1,wind_mean(i),wind_sd(i),wind_inc(i),9999.9)
    call stats_wind_direction(windX(i,starttime:endtime),windY(i,starttime:endtime),endtime-starttime+1,wd_mean(i),wd_sd(i),wd_inc(i),9999.9)
  end do
 
  maxvalue=maxval(wind)+maxval(wind_sd)
  minvalue=max(minval(wind)-maxval(wind_sd),0.)
  maxvalue_wd=maxval(wd_mean)+maxval(wd_sd)
  minvalue_wd=max(minval(wd_mean)-maxval(wd_sd),0.)

!Write out the file to pass to the plotting routine
  open(unit=20,status='new',file=fileout,form='formatted')
  write(20,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), min, max,  points_used_for_statistics, min wd, max wd ###'
  write(20,*) timestep_min,time(starttime),time(endtime),heights(levelstartplot),heights(levelendplot),&
              &minvalue,maxvalue,wind_inc(1),minvalue_wd,maxvalue_wd
  write(20,*) '### HEIGHT (m), WIND_MEAN (m/s), WIND_SD (m/s), &
              &WINDIR_MEAN (angle), WINDIR_SD (angle) ###'
  do i=1,numlevels
    write(20,*) heights(i),wind_mean(i),wind_sd(i),wd_mean(i),wd_sd(i)
  end do
  close(20)

#else
!If we want to perform interpolation, follow here

!Get the height step from the first MESO-NH step
!  pas=heights(2)-heights(1)
  pas=20.
  print*, 'DELTA(Z): ',pas
!The number of levels
  IntLev=int((lastlevel-firstlevel)/pas)
  print*, 'Number of levels after interpolation: ',IntLev
  allocate(wind_int(IntLev,npoints))
  allocate(windX_int(IntLev,npoints))
  allocate(windY_int(IntLev,npoints))
!  allocate(wd_int(IntLev,npoints))
  allocate(heights_int(IntLev))
!Perform interpolation
  do i=1,npoints
    call ITP(numlevels,IntLev,wind(:,i),heights,wind_int(:,i),heights_int,pas,9999.9)
    call ITP(numlevels,IntLev,windX(:,i),heights,windX_int(:,i),heights_int,pas,9999.9)
    call ITP(numlevels,IntLev,windY(:,i),heights,windY_int(:,i),heights_int,pas,9999.9)
!    call ITP_CIRCULAR(numlevels,IntLev,wd(:,i),heights,wd_int(:,i),heights_int,pas,360,9999.9)
  end do

!  do i=1,npoints
!    do j=1,IntLev
!      if (windX_int(j,i).eq.0.) then
!        if (windY_int(j,i).lt.0.) wd_int(j,i)=0.
!        if (windY_int(j,i).gt.0.) wd_int(j,i)=180.
!      else
!        wd_int(j,i) = 180*atan(windY_int(j,i)/windX_int(j,i))/Pi
!        if (windX_int(j,i).lt.0.) wd_int(j,i) = 90 - wd_int(j,i)
!        if (windX_int(j,i).gt.0.) wd_int(j,i) = 270 - wd_int(j,i)
!        if (wd_int(j,i).lt.0) wd_int(j,i) = wd_int(j,i) +360.
!      endif
!    end do
!  end do

  allocate(wind_mean(IntLev))
  allocate(wind_sd(IntLev))
  allocate(wind_inc(IntLev))
  allocate(wd_mean(IntLev))
  allocate(wd_sd(IntLev))
  allocate(wd_inc(IntLev))

!Get the heights were we want our plot to start and end  
  levelstartplot=1
  levelendplot=1
  do i=1,IntLev
    if ( heights_int(i) .le. startheight) levelstartplot=i
    if ( heights_int(i) .le. endheight) levelendplot=i
  end do

  print*, 'Final time:    ',time(endtime)
  print*, 'Start height:  ',heights_int(levelstartplot)
  print*, 'Final height:  ',heights_int(levelendplot)
  print*, 'Start level:   ',levelstartplot
  print*, 'Final level:   ',levelendplot

!Perform statistics
  do i=1,IntLev
    call stats(wind_int(i,starttime:endtime),endtime-starttime+1,&
         &wind_mean(i),wind_sd(i),wind_inc(i),9999.9)
    call stats_wind_direction(windX_int(i,starttime:endtime),windY_int(i,starttime:endtime),endtime-starttime+1,&
         &wd_mean(i),wd_sd(i),wd_inc(i),9999.9)
  end do

  maxvalue=maxval(wind_int)+maxval(wind_sd)
  minvalue=max(minval(wind_int)-maxval(wind_sd),0.)
  maxvalue_wd=maxval(wd_mean)+maxval(wd_sd)
  minvalue_wd=max(minval(wd_mean)-maxval(wd_sd),0.)

!Write out the file to pass to the plottind routine
  open(unit=30,status='new',file=fileout,form='formatted')
  write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), min, max, points_used_for_statistics, min wd, max wd ###'
  write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),heights_int(levelendplot),&
              &minvalue,maxvalue,wind_inc(1),minvalue_wd,maxvalue_wd
  write(30,*) '### HEIGHT (m), WIND_MEAN (m/s), WIND_SD (m/s) &
               &WINDIR_MEAN (angle), WINDIR_SD (angle) ###'
  do i=levelstartplot,levelendplot
    write(30,*) heights_int(i),wind_mean(i),wind_sd(i),wd_mean(i),wd_sd(i)
  end do
  close(30)

#endif

!  pas=heights(2)-heights(1)
!  print*, 'DELTA(Z): ',pas
!  IntLev=int((lastlevel-firstlevel)/pas)
!  print*, 'Number of levels after interpolation: ',IntLev
!  allocate(cn2_int(IntLev,npoints))
!  allocate(heights_int(IntLev))
!  do i=1,npoints
!    cn2(:,i)=log10(cn2(:,i))
!    call ITP(numlevels,IntLev,cn2(:,i),heights,cn2_int(:,i),heights_int,pas)
!    cn2_int(:,i)=exp(log(10.)*cn2_int(:,i))
!  end do
!
!  do i=1,npoints
!    do j=1,IntLev
!      int_cn2(i,j)=log10(cn2_int(j,i))
!    end do
!  end do
!
!  startlev=1
!  do while (heights_int(startlev) .lt. h0)
!    startlev=startlev+1
!  end do
!
!  print*, 'Starting level:  ',startlev
!  print*, 'Starting height: ',heights_int(startlev)
!
!  startmed=1
!  do while (heights_int(startmed) .lt. MedAlt)
!    startmed=startmed+1
!  end do
!
!  print*, 'Level at which to divide the troposphere:  ',startmed
!  print*, 'Height at which to divide the troposphere: ',heights(startmed)

end program treat_wind_pv_avg

