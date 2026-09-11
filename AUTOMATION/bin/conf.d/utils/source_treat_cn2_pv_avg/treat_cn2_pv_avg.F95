program treat_cn2_pv_avg

!#define NOINTERP

! FORTRAN 2008 stuff (need updating gcc)
!  use, intrinsic :: iso_fortran_env
  use mod_statistics
  use mod_arrays
  use mod_read_dat
  implicit none
!  integer, parameter :: sp = REAL32
!  integer, parameter :: dp = REAL64
!  integer, parameter :: qp = REAL128
  integer, parameter :: dp = kind(1.d0)
  integer :: i,j,argnum,inttmp,numlevels,nline,ncol,npoints
  integer :: timestep_min,starttime,endtime,use_it
  integer :: startheight,endheight,levelstartplot,levelendplot
  integer, parameter :: narg=7
  integer :: colheight=2
  integer :: coldata=1
  real :: firstlevel,lastlevel
  real :: minvalue,maxvalue,timestep
  real, dimension(:,:), allocatable :: variable,cn2,cn2_log,corrections
  real, dimension(:), allocatable :: heights,cn2_mean,cn2_sd,cn2_log_mean,cn2_log_sd
  integer, dimension(:), allocatable :: time,cn2_inc,cn2_log_inc
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile
#ifndef NOINTERP
  integer IntLev
  real :: pas
  real, dimension(:,:), allocatable :: cn2_int,cn2_log_int
  real, dimension(:), allocatable :: heights_int
#endif

! Get initial arguments
  argnum=command_argument_count()
  if (argnum < narg-1 .OR. argnum > narg) then  
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - cn2 dat file'
    print*, '!!!      2 - name of output file'
    print*, '!!!      3 - start time (min, I5)'
    print*, '!!!      4 - end time (min, I5)'
    print*, '!!!      5 - start height (m, I5)'
    print*, '!!!      6 - final height (m, I5)'
    print*, '!!!      7 - corrections file path - OPTIONAL'
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
  use_it=0
  if (argnum == narg) then
    corrfile=arg(7)
    call read_corrfile(corrfile,corrections,use_it) 
  end if

! Read the .dat file and get the variable array
  call read_dat_file_pv(namefile,variable)
  call apply_corrfile(variable,corrections,coldata,colheight,use_it)

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
    print*, '!!! treat_cn2_pv_avg: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
  print*, 'Columns:       ',ncol
  print*, 'Lines:         ',nline
  print*, 'Levels:        ',numlevels
  print*, 'Lowest point:  ',firstlevel
  print*, 'Highest point: ',lastlevel

  if (mod(real(nline),real(numlevels)) .ne. 0) then
    print*, '!!! treat_cn2_pv_avg: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
!Move the data into the readable arrays, one for each interesting variable
  allocate(cn2(numlevels,npoints))
  allocate(cn2_log(numlevels,npoints))
  allocate(heights(numlevels))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      cn2(j,i)=variable(inttmp+j,coldata)
      cn2_log(j,i)=log10(cn2(j,i))
    end do
  end do
  heights(:)=variable(1:numlevels,colheight)
  deallocate(variable)

!Tipically we want to offset the heights by the ground level
  heights(:)=heights(:)-heights(1)
!Get the proper time axis
  allocate(time(npoints))
  do i=1,npoints
    time(i)=i*timestep_min
  end do

  if ( starttime >= npoints) then
    print*, '!!! treat_cn2_pv_avg: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_cn2_pv_avg: end time is greater than total time'
    call exit(1)
  end if
  
  print*, 'Points:        ',npoints
  print*, 'Timestep:      ',timestep_min
  print*, 'Start time:    ',time(starttime)
  print*, 'Final time:    ',time(endtime)

#ifdef NOINTERP
!The folllowing is if we don't want to interpolate the levels produced by
!MESO-NH on its nonlinearly distributed level heights
  allocate(cn2_mean(numlevels))
  allocate(cn2_sd(numlevels))
  allocate(cn2_inc(numlevels))
  allocate(cn2_log_mean(numlevels))
  allocate(cn2_log_sd(numlevels))
  allocate(cn2_log_inc(numlevels))
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
    call stats(cn2(i,starttime:endtime),endtime-starttime+1,&
         &cn2_mean(i),cn2_sd(i),cn2_inc(i),9999.9)
  end do

  do i=1,numlevels
    call stats(cn2_log(i,starttime:endtime),endtime-starttime+1,&
         &cn2_log_mean(i),cn2_log_sd(i),cn2_log_inc(i),9999.9)
  end do

  minvalue=max(minval(cn2)-maxval(cn2_sd),0.)
  maxvalue=maxval(cn2)+maxval(cn2_sd)

!Write out the file to pass to the plottind routine
  open(unit=20,status='new',file=fileout,form='formatted')
  write(20,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), min, max  points_used_for_statistics ###'
  write(30,*) timestep_min,time(starttime),time(endtime),heights(levelstartplot),heights(levelendplot),minvalue,maxvalue,cn2_inc(1)
  write(20,*) '### HEIGHT (m), CN2_MEAN (m-2/3), CN2_SD (m-2/3) ###'
  do i=levelstartplot,levelendplot
    write(20,*) heights(i),cn2_mean(i),cn2_sd(i)
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
  allocate(cn2_log_int(IntLev,npoints))
  allocate(cn2_int(IntLev,npoints))
  allocate(heights_int(IntLev))
!Perform interpolation
  do i=1,npoints
    call ITP(numlevels,IntLev,cn2(:,i),heights,cn2_int(:,i),heights_int,pas,9999.9)
  end do

  allocate(cn2_mean(IntLev))
  allocate(cn2_sd(IntLev))
  allocate(cn2_inc(IntLev))
  allocate(cn2_log_mean(IntLev))
  allocate(cn2_log_sd(IntLev))
  allocate(cn2_log_inc(IntLev))
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

  do i=1,IntLev
    do j=1,npoints
      cn2_log_int(i,j)=log10(cn2_int(i,j))
    end do
  end do
!Perform statistics
  do i=1,IntLev
    call stats(cn2_int(i,starttime:endtime),endtime-starttime+1,&
         &cn2_mean(i),cn2_sd(i),cn2_inc(i),9999.9)
  end do

  do i=1,IntLev
    call stats(cn2_log_int(i,starttime:endtime),endtime-starttime+1,&
         &cn2_log_mean(i),cn2_log_sd(i),cn2_log_inc(i),9999.9)
  end do

  minvalue=max(minval(cn2_int)-maxval(cn2_sd),0.)
  maxvalue=maxval(cn2_int)+maxval(cn2_sd)

!Write out the file to pass to the plottind routine
  open(unit=30,status='new',file=fileout,form='formatted')
  write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), min, max  points_used_for_statistics ###'
  write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),heights_int(levelendplot),&
              &minvalue,maxvalue,cn2_inc(1)
  write(30,*) '### HEIGHT (m), CN2_MEAN (m-2/3), CN2_SD (m-2/3) ###'
  do i=levelstartplot,levelendplot
    write(30,*) heights_int(i),cn2_mean(i),cn2_sd(i)
  end do
  close(30)

#endif

end program treat_cn2_pv_avg

