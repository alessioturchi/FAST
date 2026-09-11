program treat_cn2_pv_avg

! FORTRAN 2008 stuff (need updating gcc)
!  use, intrinsic :: iso_fortran_env
  use mod_statistics
  use mod_read_dat
  implicit none
!  integer, parameter :: sp = REAL32
!  integer, parameter :: dp = REAL64
!  integer, parameter :: qp = REAL128
  integer, parameter :: dp = kind(1.d0)
  real :: alpha,beta
  integer :: i,j,argnum,inttmp,numlevels,nline,ncol,npoints,nlinew,ncolw
  integer :: timestep_min,use_it,intmed
  integer :: medalt
  integer, parameter :: narg=7
  integer :: colheight=2
  integer :: coldata=1
  integer :: coldata1=1
  integer :: coldata2=2
  real :: firstlevel,lastlevel
  integer, dimension(:,:), allocatable :: procnum
  real :: timestep,timestepw
  real, dimension(:,:), allocatable :: variable,cn2,cn2_log,corrections,variablewind,timescale
  real, dimension(:), allocatable :: heights
  integer, dimension(:), allocatable :: time
  real, dimension(:,:), allocatable :: windX,windY,wf_wind2
  real, dimension(:), allocatable :: mean_wf_wind2,sd_wf_wind2
  real, dimension(:,:), allocatable :: cn2_wf2,cn2_log_wf2
  real, dimension(:,:), allocatable :: grad_modu,grad_modv
  character(120) :: arg(narg)
  character(120) :: namefile,fileout,corrfile,windfile

! Get initial arguments
  argnum=command_argument_count()
  if (argnum < narg-1 .OR. argnum > narg) then  
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - cn2_pn dat file'
    print*, '!!!      2 - vx_vy_pn.dat file'
    print*, '!!!      3 - name of output file'
    print*, '!!!      4 - height for correction (m, I5)'
    print*, '!!!      5 - alpha (F5.2)'
    print*, '!!!      6 - beta (F5.2)'
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
  windfile=arg(2)
  fileout=arg(3)
  read(arg(4),'(I5)') medalt
  read(arg(5),'(F5.2)') alpha
  read(arg(6),'(F5.2)') beta

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

! Read the wind .dat file and get the variable array
  call read_dat_file_pv(windfile,variablewind)

  nlinew=size(variablewind,1)
  ncolw=size(variablewind,2)

  if (nlinew .ne. nline) then
    print*, '!!! rescale_cn2_wind: wind file and cn2 file have different number of lines'
    call exit(1)
  end if

  timestep=variable(1,ncol)
  timestep_min=int(timestep/60.0)

  timestepw=variablewind(1,ncolw)

  if (timestepw .ne. timestep) then
    print*, '!!! rescale_cn2_wind: wind file and cn2 file have different timestep'
    call exit(1)
  end if

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
  allocate(procnum(numlevels,npoints))
  allocate(timescale(numlevels,npoints))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      procnum(j,i)=int(variable(inttmp+j,1))
      cn2(j,i)=variable(inttmp+j,coldata)
      cn2_log(j,i)=log10(cn2(j,i))
      timescale(j,i)=variable(inttmp+j,ncol)
    end do
  end do
  heights(:)=variable(1:numlevels,colheight)
  deallocate(variable)

!Now medalt is from the ground
  medalt=medalt+int(heights(1))

!Move the wind data into the readable arrays, one for each interesting variable
  allocate(windX(numlevels,npoints))
  allocate(windY(numlevels,npoints))
  do i=1,npoints
    do j=1,numlevels
      inttmp=(i-1)*numlevels
      windX(j,i)=variablewind(inttmp+j,coldata1)
      windY(j,i)=variablewind(inttmp+j,coldata2)
    end do
  end do
  deallocate(variablewind)

!Get the proper time axis
  allocate(time(npoints))
  do i=1,npoints
    time(i)=i*timestep_min
  end do

!Compute Wind gradients
  allocate(grad_modu(numlevels,npoints))
  allocate(grad_modv(numlevels,npoints))
  do i=1,npoints
    do j=1,numlevels-1
      grad_modu(j,i) = ( windX(j+1,i) - windX(j,i) ) / ( heights(j+1) - heights(j) )
      grad_modv(j,i) = ( windY(j+1,i) - windY(j,i) ) / ( heights(j+1) - heights(j) )
    end do
  end do
  grad_modu(numlevels,:) = grad_modu(numlevels-1,:) 
  grad_modv(numlevels,:) = grad_modv(numlevels-1,:) 
  allocate(wf_wind2(numlevels,npoints))
  wf_wind2(:,:) = alpha * ( (grad_modu*grad_modu + grad_modv*grad_modv)**beta )

  allocate(mean_wf_wind2(numlevels))
  allocate(sd_wf_wind2(numlevels))
  do i=1,numlevels
    call stats(wf_wind2(i,:),npoints,mean_wf_wind2(i),sd_wf_wind2(i),inttmp,-9999.)
  enddo
  do i=1,npoints
    do j=1,numlevels
      wf_wind2(j,i) = wf_wind2(j,i) / mean_wf_wind2(j)
    end do
  end do
!get altitude from which to apply correction
  intmed=1
  do while (heights(intmed).le.medalt)
    intmed=intmed+1
  end do
  intmed=intmed-1
!Multiply cn2 by wind correction only if h>medalt
  do j=1,numlevels
    if(j.ge.intmed)then
      wf_wind2(j,:) = wf_wind2(j,:) 
    else
      wf_wind2(j,:) = 1.
    endif
  enddo
  allocate(cn2_wf2(numlevels,npoints))
  allocate(cn2_log_wf2(numlevels,npoints))
  do j=1,numlevels
    cn2_wf2(j,:) = cn2(j,:) * wf_wind2(j,:)
    cn2_log_wf2(j,:)=log10(cn2_wf2(j,:))
  end do

!Write out the file to pass to the plotting routine
!Write it as if it is a regular .dat from MNH, so that the idl routine doesn't complain
!This means we don't have an header
  open(unit=30,status='new',file=fileout,form='formatted')
  do i=1,npoints
    do j=1,numlevels
      write(30,'(I10,3x,E25.18,3x,f25.18,3x,f25.5)') procnum(j,i),cn2_wf2(j,i),heights(j),timescale(j,i)
    end do
  end do
  close(30)


end program treat_cn2_pv_avg

