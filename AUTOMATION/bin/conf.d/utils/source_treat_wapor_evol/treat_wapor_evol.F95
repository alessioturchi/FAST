program treat_wapor_evol

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
  integer :: timestep_min,starttime,endtime,dim_maverage,dim_array_res,use_it,use_it1
  integer :: startheight,endheight,levelstartplot,levelendplot,dim_resample,rest_array_res
  integer, parameter :: narg=9
  integer, parameter :: colheight=3
  integer, parameter :: coldata=1
  integer, parameter :: coldata2=2
  real :: firstlevel,lastlevel
  real, dimension(:,:), allocatable :: variable,mr,corrections,variable2,pres,corrections1
  real, dimension(:), allocatable :: heights,mmh20
  real, dimension(:), allocatable :: mmh20_ma,mmh20_mares,mmh20_mares_sd,mmh20_ma_sd,sd_mmh20_mares,sd_mmh20_mares_sd
  real :: mmh20_mean,mmh20_sd
  real :: delta_t_res
  integer, dimension(:), allocatable :: time
  real, dimension(:), allocatable :: time_res
  integer :: statpoints
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile,namefile2,corrfile1
  character(123) :: fileout_hf
  integer IntLev
  real :: pas,timestep
  real, dimension(:,:), allocatable :: mr_int,pres_int
  real, dimension(:), allocatable :: heights_int

! Get initial arguments
  argnum=command_argument_count()
  if ((argnum > narg).or.(argnum < narg-3)) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - mr_prof_p1_kn.dat file'
    print*, '!!!      2 - temp_pres_p1.dat file'
    print*, '!!!      3 - name of output file'
    print*, '!!!      4 - start time (min, I5)'
    print*, '!!!      5 - end time (min, I5)'
    print*, '!!!      6 - start height (m, I5)'
    print*, '!!!      7 - final height (m, I5)'
    print*, '!!!      8 - OPTIONAL - corrections file path for pwv'
    print*, '!!!      9 - OPTIONAL - corrections file path for mr profile'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
!    print*, '*',trim(arg(i)),'*'
  end do
  namefile=arg(1)
  namefile2=arg(2)
  fileout=arg(3)
  fileout_hf='HF_'//fileout  
  read(arg(4),'(I5)') starttime
  read(arg(5),'(I5)') endtime
  read(arg(6),'(I5)') startheight
  read(arg(7),'(I5)') endheight
  use_it=0
  if (argnum >= narg-1) then
    corrfile1=arg(8)
    call read_corrfile(corrfile1,corrections1,use_it1)
  end if
  if (argnum == narg) then
    corrfile=arg(9)
    call read_corrfile(corrfile,corrections,use_it)
  end if

! Read the .dat file and get the variable array
  call read_dat_file_pv(namefile,variable)
  call read_dat_file_pv(namefile2,variable2)
  call apply_corrfile(variable,corrections,coldata,colheight,use_it)

  nline=size(variable,1)
  ncol=size(variable,2)

  if (nline.ne.size(variable2,1)) then
    print*, '!!! treat_wapor_evol: number of lines is not the same in file1 and file2'
    call exit(1)
  end if

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
    print*, '!!! treat_wapor_evol: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
  print*, 'Columns:       ',ncol
  print*, 'Lines:         ',nline
  print*, 'Levels:        ',numlevels
  print*, 'Lowest point:  ',firstlevel
  print*, 'Highest point: ',lastlevel

  if (mod(real(nline),real(numlevels)) .ne. 0) then
    print*, '!!! treat_wapor_evol: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
!Move the data into the readable arrays, one for each interesting variable
  allocate(mr(numlevels,npoints))
  allocate(pres(numlevels,npoints))
  allocate(heights(numlevels))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      mr(j,i)=variable(inttmp+j,coldata)
      pres(j,i)=variable2(inttmp+j,coldata2)
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
    print*, '!!! treat_wapor_evol: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_wapor_evol: end time is greater than total time'
    call exit(1)
  end if
  
  print*, 'Points:        ',npoints
  print*, 'Timestep:      ',timestep_min
  print*, 'Start time:    ',time(starttime)
  print*, 'Final time:    ',time(endtime)

!Get the height step from the first MESO-NH step
!  pas=heights(2)-heights(1)
  pas=20.
  print*, 'DELTA(Z): ',pas
!The number of levels
  IntLev=int((lastlevel-firstlevel)/pas)
  print*, 'Number of levels after interpolation: ',IntLev
  allocate(mr_int(IntLev,npoints))
  allocate(pres_int(IntLev,npoints))
  allocate(heights_int(IntLev))
!Perform interpolation
  do i=1,npoints
    call ITP(numlevels,IntLev,mr(:,i),heights,mr_int(:,i),heights_int,pas,9999.9)
    call ITP(numlevels,IntLev,pres(:,i),heights,pres_int(:,i),heights_int,pas,9999.9)
  end do

!Get the heights were we want our plot to start and end  
  levelstartplot=1
  levelendplot=1
  do i=1,IntLev
    if ( heights_int(i) .le. startheight) levelstartplot=i
    if ( heights_int(i) .le. endheight) levelendplot=i
  end do

  print*, 'Final time:    ',time(endtime)
  print*, 'Start height:  ',heights_int(levelstartplot)
  print*, 'Final height:  ',heights_int(levelendplot+1)
  print*, 'Start level:   ',levelstartplot
  print*, 'Final level:   ',levelendplot

!Integrate between levelstartplot and levelendplot
  allocate(mmh20(npoints))
  mmh20(:)=0.d0
  if ( levelendplot >= IntLev ) then
    print*, '!!! treat_wapor_evol: final height is equal to total height. Please &
            &reduce at lest by one level for integration purposes'
    call exit(1)
  end if
!Compute water column
  do i=1,npoints
    do j=levelstartplot,levelendplot
      mmh20(i)=mmh20(i)+(mr_int(j,i)*(pres_int(j+1,i)-pres_int(j,i)))
    end do
  end do
  mmh20=-1.0*mmh20/9.81

!Apply correction
  if (use_it1 .eq. 1) then
    do i=1,npoints
      mmh20(i)=(mmh20(i)*corrections1(1,1))+corrections1(1,2)
    end do
  end if

!Perform statistics
  call stats(mmh20(starttime:endtime),endtime-starttime+1,&
       &mmh20_mean,mmh20_sd,statpoints,9999.9)

!Perform moving avaerage over an hour worth of samples
  dim_maverage=floor(30.0/timestep_min)
  allocate(mmh20_ma(npoints))
  allocate(mmh20_ma_sd(npoints))
  call MOVING_AVERAGE_SD(mmh20,npoints,dim_maverage,mmh20_ma,mmh20_ma_sd,9999999.0)

!!Perform resampling average
  dim_resample=floor(20.0/timestep_min)
  dim_array_res=floor(real(npoints)/real(dim_resample))
  print*,"***",dim_array_res
  !remove from output the remainder of the above division, startin from the first point of the array.
  rest_array_res=int(mod(npoints,dim_resample))
  allocate(mmh20_mares(dim_array_res))
  allocate(mmh20_mares_sd(dim_array_res))
  allocate(sd_mmh20_mares(dim_array_res))
  allocate(sd_mmh20_mares_sd(dim_array_res))
  call RESAMPLING_AVERAGE(mmh20_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,mmh20_mares,&
       &dim_array_res,mmh20_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(mmh20_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_mmh20_mares,&
       &dim_array_res,sd_mmh20_mares_sd,9999999.0)

  delta_t_res=time(rest_array_res+dim_resample+1)-time(rest_array_res+1)

  allocate(time_res(dim_array_res))
  do i=1,dim_array_res
    time_res(i)=real(time(rest_array_res+((i-1)*dim_resample)+1))+real((delta_t_res/2.0))
  end do

!Write out the file to pass to the plottind routine
  open(unit=30,status='new',file=fileout,form='formatted')
  write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), start formal height (m), &
              &end formal height (m), PWV_MEAN (mm), &
              &PWV_SD (mm), points_used_for_statistics ###'
  write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),&
              &heights_int(levelendplot),startheight,endheight,&
              &mmh20_mean,mmh20_sd,statpoints
  write(30,*) '### TIME (min), PWV (mm), PWV_SD (mm) ###'
  do i=1,dim_array_res
    write(30,*) time_res(i),mmh20_mares(i),sd_mmh20_mares(i)
  end do
  close(30)

  open(unit=20,status='new',file=fileout_hf,form='formatted')
  write(20,*) '### TIME (min), start time (min), endtime (min), &
              &start height (m), end height (m), start formal height (m), &
              &end formal height (m), PWV_MEAN (mm), &
              &PWV_SD (mm), points_used_for_statistics ###'
  write(20,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),&
              &heights_int(levelendplot),startheight,endheight,&
              &mmh20_mean,mmh20_sd,statpoints
  write(20,*) '### TIME (min), PWV (mm) ###'
  do i=1,npoints
    write(20,*) time(i),mmh20(i)
  end do
  close(20)

end program treat_wapor_evol

