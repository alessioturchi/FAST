program treat_seeisotau_evol

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
  integer :: timestep_min,starttime,endtime,ncol2,nline2,dim_maverage,dim_array_res,use_it,use_it1
  integer :: use_it2,use_it3,use_it4
  integer :: startheight,endheight,levelstartplot,levelendplot,dim_resample,rest_array_res
  integer, parameter :: narg=12
  integer :: colheight=2
  integer :: coldata=1
  real :: firstlevel,lastlevel
  real, dimension(:,:), allocatable :: variable,cn2,wind,corrections,corrections1
  real, dimension(:,:), allocatable :: corrections2,corrections3,corrections4
  real, dimension(:), allocatable :: heights,seeing,Jcn2,iso,tau
  real, dimension(:), allocatable :: Jcn2_ma,Jcn2_mares,Jcn2_mares_sd,Jcn2_ma_sd,sd_Jcn2_mares,sd_Jcn2_mares_sd
  real, dimension(:), allocatable :: seeing_ma,seeing_mares,seeing_mares_sd,seeing_ma_sd,sd_seeing_mares,sd_seeing_mares_sd
  real, dimension(:), allocatable :: iso_ma,iso_mares,iso_mares_sd,iso_ma_sd,sd_iso_mares,sd_iso_mares_sd
  real, dimension(:), allocatable :: tau_ma,tau_mares,tau_mares_sd,tau_ma_sd,sd_tau_mares,sd_tau_mares_sd
  real :: seeing_mean,seeing_sd,Jcn2_mean,Jcn2_sd
  real :: iso_mean,iso_sd,tau_mean,tau_sd,delta_t_res
  integer, dimension(:), allocatable :: time
  real, dimension(:), allocatable :: time_res
  integer :: statpoints
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,namefilewind,corrfile,corrfile1
  character(120) :: corrfile2,corrfile3,corrfile4
  character(123) :: fileout_hf
  REAL,PARAMETER :: LAMBDA=0.5E-6
  logical :: FLAGTAU
  integer IntLev
  real :: pas,timestep
  real, dimension(:,:), allocatable :: cn2_int,wind_int
  real, dimension(:), allocatable :: heights_int

! Get initial arguments
  argnum=command_argument_count()
  if ((argnum > narg).or.(argnum < narg-6)) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!      you have to pass the following arguments:'
    print*, '!!!      1  - cn2_p1.dat file'
    print*, '!!!      2  - name of output file'
    print*, '!!!      3  - start time (min, I5)'
    print*, '!!!      4  - end time (min, I5)'
    print*, '!!!      5  - start height (m, I5)'
    print*, '!!!      6  - final height (m, I5)'
    print*, '!!!      7  - OPTIONAL - wind_prof_pn.dat to compute tau0'
    print*, '!!!      8 - OPTIONAL - corrections file path for seeing'
    print*, '!!!      9 - OPTIONAL - corrections file path for iso'
    print*, '!!!      10 - OPTIONAL - corrections file path for tau'
    print*, '!!!      11 - OPTIONAL - corrections file path for cn2 profile'
    print*, '!!!      12 - OPTIONAL - corrections file path for wind profile'
    call exit(1)
  end if

  FLAGTAU=.FALSE.

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
!    print*, '*',trim(arg(i)),'*'
    if (i >= 7) FLAGTAU=.TRUE.
  end do
  namefile=arg(1)
  fileout=arg(2)
  fileout_hf='HF_'//fileout
  read(arg(3),'(I5)') starttime
  read(arg(4),'(I5)') endtime
  read(arg(5),'(I5)') startheight
  read(arg(6),'(I5)') endheight
  if (FLAGTAU) namefilewind=arg(7)
  use_it=0
  if (argnum >= narg-4) then
    corrfile2=arg(8)
    call read_corrfile(corrfile2,corrections2,use_it2)
  end if
  if (argnum >= narg-3) then
    corrfile3=arg(9)
    call read_corrfile(corrfile3,corrections3,use_it3)
  end if
  if (argnum >= narg-2) then
    corrfile4=arg(10)
    call read_corrfile(corrfile4,corrections4,use_it4)
  end if
  if (argnum >= narg-1) then
    corrfile=arg(11)
    call read_corrfile(corrfile,corrections,use_it)
  end if
  use_it1=0
  if (argnum == narg) then
    corrfile1=arg(12)
    call read_corrfile(corrfile1,corrections1,use_it1)
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
    print*, '!!! treat_seeisotau_evol: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
  print*, 'Columns:       ',ncol
  print*, 'Lines:         ',nline
  print*, 'Levels:        ',numlevels
  print*, 'Lowest point:  ',firstlevel
  print*, 'Highest point: ',lastlevel

  if (mod(real(nline),real(numlevels)) .ne. 0) then
    print*, '!!! treat_seeisotau_evol: number of lines is not a multiple of number of leveles'
    call exit(1)
  end if
!Move the data into the readable arrays, one for each interesting variable
  allocate(cn2(numlevels,npoints))
  allocate(heights(numlevels))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      cn2(j,i)=variable(inttmp+j,coldata)
    end do
  end do
  heights(:)=variable(1:numlevels,colheight)
  deallocate(variable)

!If reading wind
  if (FLAGTAU) then
    call read_dat_file_pv(namefilewind,variable)
    call apply_corrfile(variable,corrections1,coldata,colheight,use_it1)

    nline2=size(variable,1)
    ncol2=size(variable,2)
    if ((nline2 /= nline).or.(ncol2 /= ncol)) then
      print*, '!!! treat_seeisotau_evol: wind file size not compatible with cn2 file size'
      call exit(1)
    end if
    allocate(wind(numlevels,npoints))
    do i=1,npoints
      do j=1,numlevels
        inttmp=(i-1)*numlevels
        wind(j,i)=variable(inttmp+j,coldata)
      end do
    end do
    deallocate(variable)
  end if

!Tipically we want to offset the heights by the ground level
  heights(:)=heights(:)-heights(1)
!Get the proper time axis
  allocate(time(npoints))
  do i=1,npoints
    time(i)=i*timestep_min
  end do

  if ( starttime >= npoints) then
    print*, '!!! treat_seeisotau_evol: start time is >= than total time'
    call exit(1)
  end if
  if ( endtime > npoints) then
    print*, '!!! treat_seeisotau_evol: end time is greater than total time'
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
  allocate(cn2_int(IntLev,npoints))
  allocate(wind_int(IntLev,npoints))
  allocate(heights_int(IntLev))
!Perform interpolation
  do i=1,npoints
    call ITP(numlevels,IntLev,cn2(:,i),heights,cn2_int(:,i),heights_int,pas,9999.9)
  end do
  if (FLAGTAU) then
!Perform interpolation
    do i=1,npoints
      call ITP(numlevels,IntLev,wind(:,i),heights,wind_int(:,i),heights_int,pas,9999.9)
    end do
  end if

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
  allocate(seeing(npoints))
  allocate(Jcn2(npoints))
  allocate(iso(npoints))
  allocate(tau(npoints))
  seeing(:)=0.d0
  Jcn2(:)=0.d0
  iso(:)=0.d0
  tau(:)=0.d0
  if ( levelendplot >= IntLev ) then
    print*, '!!! treat_seeisotau_evol: final height is equal to total height. Please &
            &reduce at lest by one level for integration purposes'
    call exit(1)
  end if
!Compute J  
  do i=1,npoints
    do j=levelstartplot,levelendplot
      Jcn2(i)=Jcn2(i)+(cn2_int(j,i)*(heights_int(j+1)-heights_int(j)))
    end do
  end do
!Compute integral for isoplanatic angle
  do i=1,npoints
    do j=levelstartplot,levelendplot
      iso(i)=iso(i)+(cn2_int(j,i)*(heights_int(j+1)-heights_int(j))*abs(heights_int(j))**(5./3.))
!      iso(i)=iso(i)+(cn2_int(j,i)*(heights_int(j+1)-heights_int(j))*&
!          (0.5*(heights_int(j)+heights_int(j+1))-heights_int(levelstartplot))**(5./3.))
    end do
  end do
!Compute seeing
  do i=1,npoints
    seeing(i)=19.96e6*Jcn2(i)**(3./5.)
  end do
!Compute isoplanatic angle
  do i=1,npoints
!    iso(i)=1.175E4*(0.27E-7)*iso(i)**(-0.6)
    iso(i)=1.175E4*(LAMBDA**(6./5.))*iso(i)**(-0.6)
  end do
  if (FLAGTAU) then
!Compute integral for tau0
    do i=1,npoints
      do j=levelstartplot,levelendplot
        tau(i)=tau(i)+(cn2_int(j,i)*(heights_int(j+1)-heights_int(j))*wind_int(j,i)**(5./3.))
      end do
    end do
!Compute tau0
    do i=1,npoints
      tau(i)=0.057*(LAMBDA**(6./5.))*tau(i)**(-3./5.)
!      tau(i)=0.057*(0.27E-7)*tau(i)**(-0.6)
    end do
  end if

  if (use_it2 .eq. 1) then
    do i=1,npoints
      seeing(i)=(seeing(i)*corrections2(1,1))+corrections2(1,2)
    end do
  end if
  if (use_it3 .eq. 1) then
    do i=1,npoints
      iso(i)=(iso(i)*corrections3(1,1))+corrections3(1,2)
    end do
  end if
  if (use_it4 .eq. 1) then
    do i=1,npoints
      tau(i)=(tau(i)*corrections4(1,1))+corrections4(1,2)
    end do
  end if

!TAU is in seconds, we convert it to milliseconds
  tau=tau*1000

!Perform statistics
  call stats(Jcn2(starttime:endtime),endtime-starttime+1,&
       &Jcn2_mean,Jcn2_sd,statpoints,9999.9)
  call stats(seeing(starttime:endtime),endtime-starttime+1,&
       &seeing_mean,seeing_sd,statpoints,9999.9)
  call stats(iso(starttime:endtime),endtime-starttime+1,&
       &iso_mean,iso_sd,statpoints,9999.9)
  if (FLAGTAU) then
    call stats(tau(starttime:endtime),endtime-starttime+1,&
         &tau_mean,tau_sd,statpoints,9999.9)
  end if

!Apply correction to seeing
  if (use_it2 .eq. 1) then
    seeing_mean=((19.96e6*Jcn2_mean**(3./5.))*corrections2(1,1))+corrections2(1,2)
  else
    seeing_mean=(19.96e6*Jcn2_mean**(3./5.))
  end if

!Perform moving avaerage over an hour worth of samples
  dim_maverage=floor(30.0/timestep_min)
  allocate(Jcn2_ma(npoints))
  allocate(seeing_ma(npoints))
  allocate(iso_ma(npoints))
  allocate(Jcn2_ma_sd(npoints))
  allocate(seeing_ma_sd(npoints))
  allocate(iso_ma_sd(npoints))
  call MOVING_AVERAGE_SD(Jcn2,npoints,dim_maverage,Jcn2_ma,Jcn2_ma_sd,9999999.0)
  call MOVING_AVERAGE_SD(seeing,npoints,dim_maverage,seeing_ma,seeing_ma_sd,9999999.0)
  call MOVING_AVERAGE_SD(iso,npoints,dim_maverage,iso_ma,iso_ma_sd,9999999.0)
  if (FLAGTAU) then
    allocate(tau_ma(npoints))
    allocate(tau_ma_sd(npoints))    
    call MOVING_AVERAGE_SD(tau,npoints,dim_maverage,tau_ma,tau_ma_sd,9999999.0)
  end if

!!Perform resampling average
  dim_resample=floor(20.0/timestep_min)
  dim_array_res=floor(real(npoints)/real(dim_resample))

  !remove from output the remainder of the above division, startin from the first point of the array.
  rest_array_res=int(mod(npoints,dim_resample))
  allocate(Jcn2_mares(dim_array_res))
  allocate(Jcn2_mares_sd(dim_array_res))
  allocate(seeing_mares(dim_array_res))
  allocate(seeing_mares_sd(dim_array_res))
  allocate(iso_mares(dim_array_res))
  allocate(iso_mares_sd(dim_array_res))
  allocate(sd_Jcn2_mares(dim_array_res))
  allocate(sd_Jcn2_mares_sd(dim_array_res))
  allocate(sd_seeing_mares(dim_array_res))
  allocate(sd_seeing_mares_sd(dim_array_res))
  allocate(sd_iso_mares(dim_array_res))
  allocate(sd_iso_mares_sd(dim_array_res))
  call RESAMPLING_AVERAGE(Jcn2_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,Jcn2_mares,&
       &dim_array_res,Jcn2_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(seeing_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,seeing_mares,&
       &dim_array_res,seeing_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(iso_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,iso_mares,&
       &dim_array_res,iso_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(Jcn2_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_Jcn2_mares,&
       &dim_array_res,sd_Jcn2_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(seeing_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_seeing_mares,&
       &dim_array_res,sd_seeing_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(iso_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_iso_mares,&
       &dim_array_res,sd_iso_mares_sd,9999999.0)
  if (FLAGTAU) then
    allocate(tau_mares(dim_array_res))
    allocate(tau_mares_sd(dim_array_res))
    allocate(sd_tau_mares(dim_array_res))
    allocate(sd_tau_mares_sd(dim_array_res))
  call RESAMPLING_AVERAGE(tau_ma(rest_array_res+1:),npoints-rest_array_res,dim_resample,tau_mares,&
       &dim_array_res,tau_mares_sd,9999999.0)
  call RESAMPLING_AVERAGE(tau_ma_sd(rest_array_res+1:),npoints-rest_array_res,dim_resample,sd_tau_mares,&
       &dim_array_res,sd_tau_mares_sd,9999999.0)
  end if

  delta_t_res=time(rest_array_res+dim_resample+1)-time(rest_array_res+1)

  allocate(time_res(dim_array_res))
  do i=1,dim_array_res
    time_res(i)=real(time(rest_array_res+((i-1)*dim_resample)+1))+real((delta_t_res/2.0))
  end do

!Apply corrections to the seeing
!  if (use_it2 .eq. 1) then
!    do i=1,dim_array_res
!!      seeing_mares(i)=((19.96e6*Jcn2_mares(i)**(3./5.))*corrections2(1,1))+corrections2(1,2)
!      seeing_mares(i)=(seeing_mares(i)*corrections2(1,1))+corrections2(1,2)
!    end do
!    do i=1,npoints
!      seeing(i)=(seeing(i)*corrections2(1,1))+corrections2(1,2)
!    end do
!  end if

!Write out the file to pass to the plottind routine
  if (FLAGTAU) then
    open(unit=30,status='new',file=fileout,form='formatted')
    write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), start formal height (m), &
              &end formal height (m), SEEING_MEAN (arcsec), &
              &SEEING_SD (arcsec), J_MEAN, J_SD,&
              &THETA0_MEAN (arcsec), THETA0_SD (arcsec),&
              &TAU_MEAN (ms), TAU_SD (ms),&
              & points_used_for_statistics ###'
    write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),&
              &heights_int(levelendplot),startheight,endheight,seeing_mean,&
              &seeing_sd,Jcn2_mean,Jcn2_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
              &statpoints
    write(30,*) '### TIME (min), SEEING (arcsec), SEEING_SD, J (m^1/3), J_SD, THETA0 (arcsec), THETA0_SD, &
              &TAU (ms), TAU_SD ###'
    do i=1,dim_array_res
      write(30,*) time_res(i),seeing_mares(i),sd_seeing_mares(i),Jcn2_mares(i),sd_Jcn2_mares(i),&
                  &iso_mares(i),sd_iso_mares(i),tau_mares(i),sd_tau_mares(i)
    end do
    close(30)
  else
    open(unit=30,status='new',file=fileout,form='formatted')
    write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), start formal height (m), &
              &end formal height (m), SEEING_MEAN (arcsec), &
              &SEEING_SD (arcsec), J_MEAN, J_SD,&
              &THETA0_MEAN (arcsec), THETA0_SD (arcsec),&
              &TAU_MEAN (ms), TAU_SD (ms),&
              & points_used_for_statistics ###'
    write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),&
              &heights_int(levelendplot),startheight,endheight,seeing_mean,&
              &seeing_sd,Jcn2_mean,Jcn2_sd,iso_mean,iso_sd,statpoints
    write(30,*) '### TIME (min), SEEING (arcsec), SEEING_SD, J (m^1/3), J_SD, THETA0 (arcsec), THETA0_SD ###'
    do i=1,dim_array_res
      write(30,*) time_res(i),seeing_mares(i),sd_seeing_mares(i),Jcn2_mares(i),sd_Jcn2_mares(i),&
                  &iso_mares(i),sd_iso_mares(i)
    end do
    close(30)
  end if

!Write out the high frequency data
  if (FLAGTAU) then
    open(unit=30,status='new',file=fileout_hf,form='formatted')
    write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), start formal height (m), &
              &end formal height (m), SEEING_MEAN (arcsec), &
              &SEEING_SD (arcsec), J_MEAN, J_SD,&
              &THETA0_MEAN (arcsec), THETA0_SD (arcsec),&
              &TAU_MEAN (ms), TAU_SD (ms),&
              & points_used_for_statistics ###'
    write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),&
              &heights_int(levelendplot),startheight,endheight,seeing_mean,&
              &seeing_sd,Jcn2_mean,Jcn2_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
              &statpoints
    write(30,*) '### TIME (min), SEEING (arcsec), J (m^1/3), THETA0 (arcsec), TAU (ms) ###'
    do i=1,npoints
      write(30,*) time(i),seeing(i),Jcn2(i),iso(i),tau(i)
    end do
    close(30)
  else
    open(unit=30,status='new',file=fileout_hf,form='formatted')
    write(30,*) '### timestep (min), start time (min), endtime (min), &
              &start height (m), end height (m), start formal height (m), &
              &end formal height (m), SEEING_MEAN (arcsec), &
              &SEEING_SD (arcsec), J_MEAN, J_SD,&
              &THETA0_MEAN (arcsec), THETA0_SD (arcsec),&
              &TAU_MEAN (ms), TAU_SD (ms),&
              & points_used_for_statistics ###'
    write(30,*) timestep_min,time(starttime),time(endtime),heights_int(levelstartplot),&
              &heights_int(levelendplot),startheight,endheight,seeing_mean,&
              &seeing_sd,Jcn2_mean,Jcn2_sd,iso_mean,iso_sd,statpoints
    write(30,*) '### TIME (min), SEEING (arcsec), J (m^1/3), THETA0 (arcsec) ###'
    do i=1,npoints
      write(30,*) time(i),seeing(i),Jcn2(i),iso(i)
    end do
    close(30)
  end if

end program treat_seeisotau_evol

