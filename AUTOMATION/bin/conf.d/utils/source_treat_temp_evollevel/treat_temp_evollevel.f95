program treat_temp_evollevel

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
  integer :: i,argnum,nline,ncol,npoints,dim_maverage,dim_array_res
  integer :: starttime,endtime,temp_inc,dim_resample,rest_array_res,use_it
  integer, parameter :: narg=5
  integer :: coldata=2
  integer :: coltime=6
  real, dimension(:,:), allocatable :: variable,corrections
  real, dimension(:), allocatable :: temperature,temperature_ma,time_res,temperature_ma_sd
  real, dimension(:), allocatable :: time,temperature_mares,temperature_mares_sd
  real, dimension(:), allocatable :: sd_temperature_mares,sd_temperature_mares_sd
  real :: timestep,temp_mean,temp_sd,delta_t_res
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile
  character(123) :: fileout_hf

! Get initial arguments
  argnum=command_argument_count()
  if (argnum < narg-1 .OR. argnum > narg) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - wind_and_temp_pres_vx_vy_pn_km.dat dat file'
    print*, '!!!      2 - name of output file'
    print*, '!!!      3 - start time (min), int'
    print*, '!!!      4 - end time (min), int'
    print*, '!!!      5 - corrections file path - OPTIONAL'
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
  if (argnum == narg) then
    corrfile=arg(5)
    call read_corrfile(corrfile,corrections,use_it) 
  end if

! Read the .dat file and get the variable array
  call read_dat_file_km(namefile,variable)
!  call apply_corrfile(variable,corrections,coldata,coltime,use_it)

  nline=size(variable,1)
  ncol=size(variable,2)

  !Apply manually the correction
  if (use_it == 1) then
    print*,"Applying correction to TEMP, mult:",corrections(1,1)," sum:",corrections(1,2)
    do i=1,nline
      variable(i,coldata)=variable(i,coldata)-273.15
      variable(i,coldata)=variable(i,coldata)*corrections(1,1) + corrections(1,2)
      variable(i,coldata)=variable(i,coldata)+273.15
    end do
  end if

  timestep=variable(1,ncol)

!Rescale start time by timestep in order to have the correct number of actual
!points
  starttime=int(starttime*60/timestep)+1
  endtime=int(endtime*60/timestep)+1

!Get the number of points in time from the line number
  npoints=nline
  print*, 'Lines:         ',nline
!Move the data into the readable arrays, one for each interesting variable
  allocate(temperature(npoints))
  do i=1,npoints
    temperature(i)=variable(i,coldata)
  end do
  deallocate(variable)
!Get the proper time axis
  allocate(time(npoints))
  do i=1,npoints
    time(i)=(i-1)*timestep
  end do

!Perform moving avaerage over an hour worth of samples
  dim_maverage=floor(1800.0/timestep)
  allocate(temperature_ma(npoints))
  allocate(temperature_ma_sd(npoints))
  call MOVING_AVERAGE_SD(temperature,npoints,dim_maverage,temperature_ma,temperature_ma_sd,9999999.0)
  
!!Perform resampling average
  dim_resample=floor(1200.0/timestep)
  dim_array_res=floor(real(npoints)/real(dim_resample))
  !remove from output the remainder of the above division, startin from the first point of the array.
  rest_array_res=int(mod(npoints,dim_resample))
  allocate(temperature_mares(dim_array_res))
  allocate(temperature_mares_sd(dim_array_res))
  allocate(sd_temperature_mares(dim_array_res))
  allocate(sd_temperature_mares_sd(dim_array_res))
  call RESAMPLING_AVERAGE(temperature_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,temperature_mares,&
       &dim_array_res,temperature_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(temperature_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_temperature_mares,&
       &dim_array_res,sd_temperature_mares_sd,9999999.0)

  delta_t_res=time(rest_array_res+dim_resample+1)-time(rest_array_res+1)

  allocate(time_res(dim_array_res))
  do i=1,dim_array_res
    time_res(i)=time(rest_array_res+((i-1)*dim_resample)+1)+(delta_t_res/2)
  end do

  if ( starttime >= npoints) then
    print*, '!!! treat_temp_evollevel: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_temp_evollevel: end time is greater than total time'
    call exit(1)
  end if
  
  print*, 'Points:        ',npoints
  print*, 'Timestep:      ',timestep
  print*, 'Start time:    ',time(starttime)
  print*, 'Final time:    ',time(endtime)

call stats(temperature(starttime:endtime),endtime-starttime+1,temp_mean,temp_sd,temp_inc,9999.9)

!Write out the file to pass to the plotting routine
  open(unit=20,status='new',file=fileout,form='formatted')
  write(20,*) '### timestep (s), start time (s), endtime (s), TEMP_MEAN, TEMP_SD ###'
  write(20,*) 1200,time(starttime),time(endtime), temp_mean, temp_sd
  write(20,*) '### TIME (s), ABSOLUTE TEMPERATURE (K) , ABS_TEMP_SD ###'
  do i=1,dim_array_res
    write(20,*) time_res(i),temperature_mares(i),sd_temperature_mares(i)
  end do
  close(20)

  open(unit=20,status='new',file=fileout_hf,form='formatted')
  write(20,*) '### timestep (s), start time (s), endtime (s), TEMP_MEAN, TEMP_SD ###'
  write(20,*) 1200,time(starttime),time(endtime), temp_mean, temp_sd
  write(20,*) '### TIME (s), ABSOLUTE TEMPERATURE (K)  ###'
  do i=1,npoints
    write(20,*) time(i),temperature(i)
  end do
  close(20)

end program treat_temp_evollevel
