program treat_wind_evollevel

! FORTRAN 2008 stuff (need updating gcc)
!  use, intrinsic :: iso_fortran_env
  use mod_statistics
  use mod_statistics_wd
  use mod_arrays
  use mod_arrays_wd
  use mod_read_dat
  implicit none
!  integer, parameter :: sp = REAL32
!  integer, parameter :: dp = REAL64
!  integer, parameter :: qp = REAL128
  integer, parameter :: dp = kind(1.d0)
  integer :: i,argnum,nline,ncol,npoints,dim_maverage,dim_resample,dim_array_res,rest_array_res
  integer :: starttime,endtime,wind_inc,wd_inc,use_it,use_it1,use_it2
  integer, parameter :: narg=7
  integer :: coldata=1,coldata1=4,coldata2=5
  integer :: coltime=6
  real, dimension(:,:), allocatable :: variable,corrections,corrections1,corrections2
  real, dimension(:), allocatable :: wind,wd,wind_x,wind_y,wind_ma,wind_x_ma,wind_y_ma
  real, dimension(:), allocatable :: time,wind_mares,wind_mares_sd,wd_mares,wd_mares_sd,time_res
  real, dimension(:), allocatable :: wind_ma_sd,wind_x_ma_sd,wind_y_ma_sd,realsd_wd_mares,wd_ma,wd_ma_sd
  real, dimension(:), allocatable :: sd_wind_mares,sd_wind_mares_sd,sd_wd_mares,sd_wd_mares_sd,realsd_wd_mares_sd
  real :: timestep,wind_mean,wind_sd,wd_mean,wd_sd,delta_t_res
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile,corrfile1,corrfile2
  character(123) :: fileout_hf  
  real, parameter :: Pi=3.141592654

! Get initial arguments
  argnum=command_argument_count()
  if (argnum < narg-3 .OR. argnum > narg) then  
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - wind_and_temp_pres_vx_vy_pn_km.dat file'
    print*, '!!!      2 - name of output file'
    print*, '!!!      3 - start time (min), int'
    print*, '!!!      4 - end time (min), int'
    print*, '!!!      5 - corrections file path for wind module - OPTIONAL'
    print*, '!!!      6 - corrections file path for wind x - OPTIONAL'
    print*, '!!!      7 - corrections file path for wind y - OPTIONAL'
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
  fileout_hf='HF_'//fileout  
  read(arg(3),'(I5)') starttime
  read(arg(4),'(I5)') endtime
  use_it=0
  if (argnum >= narg-2) then
    corrfile=arg(5)
    call read_corrfile(corrfile,corrections,use_it)
  end if
  use_it1=0
  if (argnum >= narg-1) then
    corrfile1=arg(6)
    call read_corrfile(corrfile1,corrections1,use_it1)
  end if
  use_it2=0
  if (argnum == narg) then
    corrfile2=arg(7)
    call read_corrfile(corrfile2,corrections2,use_it2)
  end if

! Read the .dat file and get the variable array
  call read_dat_file_km(namefile,variable)
  call apply_corrfile(variable,corrections,coldata,coltime,use_it)
  call apply_corrfile(variable,corrections1,coldata1,coltime,use_it1)
  call apply_corrfile(variable,corrections2,coldata2,coltime,use_it2)

  nline=size(variable,1)
  ncol=size(variable,2)

  timestep=variable(1,ncol)

!Rescale start time by timestep in order to have the correct number of actual
!points
  starttime=int(starttime*60/timestep)+1
  endtime=int(endtime*60/timestep)+1

!Get the number of points in time from the line number
  npoints=nline
  print*, 'Lines:         ',nline

!Move the data into the readable arrays, one for each interesting variable
  allocate(wind(npoints))
  allocate(wd(npoints))
  allocate(wind_x(npoints))
  allocate(wind_y(npoints))
  do i=1,npoints
    wind(i)=variable(i,coldata)
    wind_x(i)=variable(i,coldata1)
    wind_y(i)=variable(i,coldata2)
  end do
  deallocate(variable)

  do i=1,npoints
    if (wind_x(i).eq.0.) then
      if (wind_y(i).lt.0.) wd(i)=0.
      if (wind_y(i).gt.0.) wd(i)=180.
    else  
      wd(i) = 180*atan(wind_y(i)/wind_x(i))/Pi
      if (wind_x(i).lt.0.) wd(i) = 90 - wd(i)
      if (wind_x(i).gt.0.) wd(i) = 270 - wd(i)
      if (wd(i).lt.0) wd(i) = wd(i) +360.
    endif
  end do

  allocate(time(npoints))
  do i=1,npoints
    time(i)=(i-1)*timestep
  end do

  if ( starttime >= npoints) then
    print*, '!!! treat_wind_evollevel: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_wind_evollevel: end time is greater than total time'
    call exit(1)
  end if
  
  print*, 'Points:        ',npoints
  print*, 'Timestep:      ',timestep
  print*, 'Start time:    ',time(starttime)
  print*, 'Final time:    ',time(endtime)

  call stats(wind(starttime:endtime),endtime-starttime+1,wind_mean,wind_sd,wind_inc,9999.9)

  call stats_wind_direction(wind_x(starttime:endtime),wind_y(starttime:endtime),endtime-starttime+1,wd_mean,wd_sd,wd_inc,9999.9)

!Perform moving avaerage over an hour worth of samples
  dim_maverage=floor(1800.0/timestep)
  allocate(wind_ma(npoints))
  allocate(wind_ma_sd(npoints))
  call MOVING_AVERAGE_SD(wind,npoints,dim_maverage,wind_ma,wind_ma_sd,9999999.0)
  allocate(wind_x_ma(npoints))
  allocate(wind_y_ma(npoints))
  allocate(wind_x_ma_sd(npoints))
  allocate(wind_y_ma_sd(npoints))
  allocate(wd_ma(npoints))
  allocate(wd_ma_sd(npoints))
  call MOVING_AVERAGE_SD(wind_x,npoints,dim_maverage,wind_x_ma,wind_x_ma_sd,9999999.0)
  call MOVING_AVERAGE_SD(wind_y,npoints,dim_maverage,wind_y_ma,wind_y_ma_sd,9999999.0)
  call MOVING_AVERAGE_WIND_DIRECTION_SD(wind_x,wind_y,npoints,dim_maverage,wd_ma,wd_ma_sd,9999999.0)

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

  allocate(wd_mares(dim_array_res))
  allocate(wd_mares_sd(dim_array_res))
  allocate(sd_wd_mares(dim_array_res))
  allocate(sd_wd_mares_sd(dim_array_res))
  allocate(realsd_wd_mares(dim_array_res))
  allocate(realsd_wd_mares_sd(dim_array_res))
  call RESAMPLING_AVERAGE_WIND_DIRECTION(wind_x_ma(rest_array_res+1:),wind_y_ma(rest_array_res+1:),&
       &npoints-rest_array_res,dim_resample,wd_mares,&
       &dim_array_res,wd_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE_WIND_DIRECTION(wind_x_ma_sd(rest_array_res+1:),wind_y_ma_sd(rest_array_res+1:),&
       &npoints-rest_array_res,dim_resample,sd_wd_mares,&
       &dim_array_res,sd_wd_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(wd_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,realsd_wd_mares,&
       &dim_array_res,realsd_wd_mares_sd,9999999.0)


  delta_t_res=time(rest_array_res+dim_resample+1)-time(rest_array_res+1)

  allocate(time_res(dim_array_res))
  do i=1,dim_array_res
    time_res(i)=time(rest_array_res+((i-1)*dim_resample)+1)+(delta_t_res/2)
  end do

!Write out the file to pass to the plotting routine
  open(unit=20,status='new',file=fileout,form='formatted')
  write(20,*) '### timestep (s), start time (s), endtime (s), WIND_MEAN, WIND_SD, WIND_DIRECTION_MEAN, WIND_DIRECTION_SD ###'
  write(20,*) timestep,time(starttime),time(endtime), wind_mean, wind_sd ,wd_mean, wd_sd
  write(20,*) '### TIME (s), WIND MODULE (m/s), WIND MODULE SD, WIND DIRECTION (angle), WIND DIRECTION SD ###'
  do i=1,dim_array_res
!    write(20,*) time_res(i),wind_mares(i),wind_mares_sd(i),wd_mares(i),wd_mares_sd(i)
    write(20,*) time_res(i),wind_mares(i),sd_wind_mares(i),wd_mares(i),realsd_wd_mares(i)
  end do
  close(20)

  open(unit=20,status='new',file=fileout_hf,form='formatted')
  write(20,*) '### timestep (s), start time (s), endtime (s), WIND_MEAN, WIND_SD, WIND_DIRECTION_MEAN, WIND_DIRECTION_SD ###'
  write(20,*) timestep,time(starttime),time(endtime), wind_mean, wind_sd ,wd_mean, wd_sd
  write(20,*) '### TIME (s), WIND MODULE (m/s), WIND DIRECTION (angle), WIND component X (m/s), WIND component Y (m/s) ###'
  do i=1,npoints
    write(20,*) time(i),wind(i),wd(i),wind_x(i),wind_y(i)
  end do
  close(20)

end program treat_wind_evollevel
