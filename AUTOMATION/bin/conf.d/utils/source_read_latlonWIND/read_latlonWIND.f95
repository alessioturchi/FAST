program read_latlonWIND

  use mod_statistics
  use mod_cumdist
  use mod_statistics_wd
  use mod_read_ficval
  implicit none
  integer :: i,j,argnum,nx_lat,ny_lat,nx_xzs,ny_xzs,nx_see,ny_see
  integer, parameter :: narg=9
  integer, dimension(:), allocatable :: exitarray
  character(120) :: arg(narg)
  character(120) :: startexit,endexit,filename,firstname,secondname,startavg,endavg
  character(3) :: charnum
  integer :: startexitINT, endexitINT,sizeexit,ne,namelen,namelen2,pos,pos2,see_inc
  integer :: startavgINT, endavgINT,sizeavg,startavg_rel
  real,dimension(:,:),allocatable :: xlatm,xlonm,xzs,see
  real :: see_mean_dir,see_mean_mod,see_mean_X,see_mean_Y,see_sd_dir,see_sd_mod,see_sd_X,see_sd_Y,seemin,seemax,see_med
  real, dimension(:,:,:), allocatable :: seeallX,seeallY,seeall_mod,seeall_dir
  real, dimension(:,:), allocatable :: seeall_mean_mod,seeall_mean_dir,seeall_mean_X,seeall_mean_Y
  real, dimension(:,:), allocatable :: seeall_med,seeall_medX,seeall_medY
  real, dimension(:), allocatable :: see_cdx,see_cdy
  logical :: ok
  real,dimension(:,:), allocatable :: variable
  integer :: nx,ny
  integer :: klevel
  logical :: isextraction,isconversion,islevelK
  character(30) :: varname,timevar
  real, parameter :: Pi=3.141592654

  allocate(seeallX(1,1,1))
  allocate(seeallY(1,1,1))
  deallocate(seeallX)
  deallocate(seeallY)

!******************************* INPUT ARGUMENTS *******************************
  argnum=command_argument_count()
  if (argnum /= narg) then
    if (argnum <narg) then
      print*, '!!! error: wrong number of arguments'
      print*, '!!!        you have to pass the following arguments:'
      print*, '!!!      1 - LatLon file'
      print*, '!!!      2 - ZS ficval file'
      print*, '!!!      3 - wind X (UT) file - First exit file'
      print*, '!!!      4 - wind Y (VT) file - First exit file'
      print*, '!!!      5 - output file - base name, will be numbered'
      print*, '!!!      6 - Starting exit file (number, 3 characters, from 001 to xxx)'
      print*, '!!!      7 - Ending exit file (number, 3 characters, from 001 to xxx)'
      print*, '!!!      8 - Starting exit file for average (number, 3 characters, from 001 to xxx)'
      print*, '!!!      9 - Ending exit file for average (number, 3 characters, from 001 to xxx)'
      call exit(1)
    else
      print*, '!!! error: too many input arguments'
      print*, '!!!        you have to pass the following arguments:'
      print*, '!!!      1 - LatLon file'
      print*, '!!!      2 - ZS ficval file'
      print*, '!!!      3 - wind X (UT) file - First exit file'
      print*, '!!!      4 - wind Y (VT) file - First exit file'
      print*, '!!!      5 - output file - base name, will be numbered'
      print*, '!!!      6 - Starting exit file (number, 3 characters, from 001 to xxx)'
      print*, '!!!      7 - Ending exit file (number, 3 characters, from 001 to xxx)'
      print*, '!!!      8 - Starting exit file for average (number, 3 characters, from 001 to xxx)'
      print*, '!!!      9 - Ending exit file for average (number, 3 characters, from 001 to xxx)'
      call exit(1)
    end if
  end if
  nx_see=0
  ny_see=0
!Get all input arguments
  do i=1,narg
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
!    print*, '*',trim(arg(i)),'*'
  end do
!Start exit and end exit correspond to the first numbered exit from meso-nh (ex.
!001), while end exit correspond to the last numbered exit that I want to
!analyze (ex. 15)
!I have to pass from string to integer and again to string to do some manipulation.
  startexit=trim(arg(6))
  endexit=trim(arg(7))
  startavg=trim(arg(8))
  endavg=trim(arg(9))
  read(startexit,'(I3)') startexitINT
  read(endexit,'(I3)') endexitINT
  read(startavg,'(I3)') startavgINT
  read(endavg,'(I3)') endavgINT
  if (endexitINT <= startexitINT) then
    print*, '!!! error: start exit file number is greater than end exit file number'
    call exit(1)
  end if
  if (endavgINT > endexitINT) then
    print*, '!!! error: end average file number is greater than end exit file number'
    call exit(1)
  end if
  if (startavgINT < startexitINT) then
    print*, '!!! error: start average file number is less than start exit file number'
    call exit(1)
  end if
  if (startavgINT >= endavgINT) then
    print*, '!!! error: start average file number is greater than end exit file number'
    call exit(1)
  end if
!The size of the input name
  sizeexit=endexitINT-startexitINT+1
  sizeavg=endavgINT-startavgINT+1
  startavg_rel=startavgINT-startexitINT
!The array containing all the integers representing the numbered exits (like 1, 2, 3 ...)
  allocate(exitarray(sizeexit))
  do i=startexitINT,endexitINT
     exitarray(i-startexitINT+1)=i
  end do
!First read the latlon and ZS file since they are common for all
  call read_file_FICVAL(arg(1),klevel,isextraction,isconversion,islevelK,varname,timevar,variable)
  if (isconversion) then
    nx=int(size(variable,1)/2)
    ny=size(variable,2)
    allocate(xlatm(nx,ny))
    allocate(xlonm(nx,ny))
    do i=1,nx
      xlatm(i,:)=variable(2*i-1,:)
      xlonm(i,:)=variable(2*i,:)
    end do
    nx_lat=nx
    ny_lat=ny
  else
    print*, '!!! error: you did not select a valid LatLon file'
    call exit(1)
  end if
  call read_file_FICVAL(arg(2),klevel,isextraction,isconversion,islevelK,varname,timevar,variable)
  if (isextraction) then
    nx=size(variable,1)
    ny=size(variable,2)
    allocate(xzs(nx,ny))
    xzs=variable
!Latlon dimensions include border, so we subtract 2
    if ((nx /= nx_lat-2) .or. (ny /= ny_lat-2)) then
      print*, '!!! error: the latlon and ZS file dimensions do not agree'
      call exit(1)
    end if
    nx_xzs=nx
    ny_xzs=ny
  else
    print*, '!!! error: you did not select a valid ZS ficval file'
    call exit(1)
  end if
!manipulate the input names in order to have all the names for each exit file
  firstname=arg(3)
  namelen=len_trim(firstname)
!I search for an extended string in order to avoid collisions (like with the
!year... we are fine even beyond year 2100!!! Well, I suppose I'll be dead and
!buried by that date, but let me be optimistic)
!We search for a default first number
  pos=index(firstname,'_001_')
!manipulate the input names in order to have all the names for each exit file
  secondname=arg(4)
  namelen2=len_trim(secondname)
!I search for an extended string in order to avoid collisions (like with the
!year... we are fine even beyond year 2100!!! Well, I suppose I'll be dead and
!buried by that date, but let me be optimistic)
!We search for a default first number
  pos2=index(firstname,'_001_')
!The big loop that searches for each exit and outputs what it has to output,
!clear, is it?
  do ne=1,sizeexit
!Genereate the numbered string
    if (exitarray(ne) <= 9) then
      write(charnum,'(A2,I1)') '00',exitarray(ne)
    else if (exitarray(ne) <= 99) then
      write(charnum,'(A1,I2)') '0',exitarray(ne)
    else if (exitarray(ne) <= 999) then
      write(charnum,'(I3)') exitarray(ne)
    else
      print*, '!!! error: end exit file number is greater than 999'
      call exit(1)
    end if
    !If you didn't pass the first 001 file, we search to see if you passed at
    !least the first exit startexit that you passed as an argument
    if (pos == 0) then
      pos=index(firstname,'_'//trim(charnum)//'_')
    end if
    if (pos == 0) then
      print*, '!!! error: input file does not correspond to starting exit file'
      call exit(1)
    end if
!Generate the exit file name
    filename=firstname(1:pos)//trim(charnum)//firstname(pos+4:namelen)
!Read the WIND X direction
    call read_file_FICVAL(filename,klevel,isextraction,isconversion,islevelK,varname,timevar,variable)
    if (isextraction) then
      nx=size(variable,1)
      ny=size(variable,2)
      allocate(see(nx,ny))
      !Allocate the global seeing matrix only the first time the loop is called
      if (.not. allocated(seeallX)) allocate(seeallX(nx,ny,sizeexit))
      !Store the seeing
      see=variable
      seeallX(:,:,ne)=see
      if (ne > 1) then
        if ((nx /= nx_see) .or. (ny /= ny_see)) then
          print*, '!!! error: the input file dimensions do not agree'
          call exit(1)
        end if
      else
        if ((nx /= nx_xzs) .or. (ny /= ny_xzs)) then
          print*, '!!! error: the input file and ZS file dimensions do not agree'
          call exit(1)
        end if
      end if
      nx_see=nx
      ny_see=ny
    else
      print*, '!!! error:'//trim(filename)//' - you did not select a valid seeing ficval file'
      call exit(1)
    end if
    deallocate(see)
    !If you didn't pass the first 001 file, we search to see if you passed at
    !least the first exit startexit that you passed as an argument
    if (pos2 == 0) then
      pos2=index(secondname,'_'//trim(charnum)//'_')
    end if
    if (pos2 == 0) then
      print*, '!!! error: input file does not correspond to starting exit file'
      call exit(1)
    end if
!Generate the exit file name
    filename=secondname(1:pos2)//trim(charnum)//secondname(pos2+4:namelen)
!Read the WIND Y direction
    call read_file_FICVAL(filename,klevel,isextraction,isconversion,islevelK,varname,timevar,variable)
    if (isextraction) then
      nx=size(variable,1)
      ny=size(variable,2)
      allocate(see(nx,ny))
      !Allocate the global seeing matrix only the first time the loop is called
      if (.not. allocated(seeallY)) allocate(seeallY(nx,ny,sizeexit))
      !Store the seeing
      see=variable
      seeallY(:,:,ne)=see
      if (ne > 1) then
        if ((nx /= nx_see) .or. (ny /= ny_see)) then
          print*, '!!! error: the input file dimensions do not agree'
          call exit(1)
        end if
      else
        if ((nx /= nx_xzs) .or. (ny /= ny_xzs)) then
          print*, '!!! error: the input file and ZS file dimensions do not agree'
          call exit(1)
        end if
      end if
      nx_see=nx
      ny_see=ny
    else
      print*, '!!! error:'//trim(filename)//' - you did not select a valid seeing ficval file'
      call exit(1)
    end if
    deallocate(see)
  end do

  allocate(seeall_mod(nx,ny,sizeexit))
  allocate(seeall_dir(nx,ny,sizeexit))
  do ne=1,sizeexit
    do i=1,nx
      do j=1,ny
        seeall_mod(i,j,ne)=sqrt((seeallX(i,j,ne)**2) + (seeallY(i,j,ne)**2))
        if (seeallX(i,j,ne).eq.0.) then
          if (seeallY(i,j,ne).lt.0.) seeall_dir(i,j,ne)=0.
          if (seeallY(i,j,ne).gt.0.) seeall_dir(i,j,ne)=180.
        else  
          seeall_dir(i,j,ne) = 180*atan(seeallY(i,j,ne)/seeallX(i,j,ne))/Pi
          if (seeallX(i,j,ne).lt.0.) seeall_dir(i,j,ne) = 90 - seeall_dir(i,j,ne)
          if (seeallX(i,j,ne).gt.0.) seeall_dir(i,j,ne) = 270 - seeall_dir(i,j,ne)
          if (seeall_dir(i,j,ne).lt.0) seeall_dir(i,j,ne) = seeall_dir(i,j,ne) +360.
        endif
      end do
    end do
  end do

  seemin=minval(seeall_mod)
  seemax=maxval(seeall_mod)

! WRITE OUT THE FILES
  do ne=1,sizeexit
!Genereate the numbered string
    if (exitarray(ne) <= 9) then
      write(charnum,'(A2,I1)') '00',exitarray(ne)
    else if (exitarray(ne) <= 99) then
      write(charnum,'(A1,I2)') '0',exitarray(ne)
    else if (exitarray(ne) <= 999) then
      write(charnum,'(I3)') exitarray(ne)
    end if

    inquire( file=trim(arg(5))//'.'//trim(charnum)//'.stat', exist=ok )
    if (ok) then
      print*, '!!! error: file ',trim(arg(5))//'.'//trim(charnum)//'.stat',' is already present'
      call exit(1)
    end if

    open(unit=40,status='new',file=trim(arg(5))//'.'//trim(charnum)//'.stat',access='sequential')
    write(40,*) '### GRID SIZE X, GRID SIZE Y, START EXIT, END EXIT, EXIT NUM,&
        & MIN WIND, MAX WIND ###'
    write(40,*) nx,ny,startexitINT,endexitINT,sizeexit,seemin,seemax
    write(40,*) '###  I   J           XLAT                XLON          ZS        &
        &WIND MODULE        WIND ANGLE        WIND X (UT)        WINDY(VT)'
    do i=2,nx_lat-1
      do j=2,ny_lat-1
        write(40,*) i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1),seeall_mod(i-1,j-1,ne),seeall_dir(i-1,j-1,ne),&
        &seeallX(i-1,j-1,ne),seeallY(i-1,j-1,ne)
!        write(40,'(i4,i4,f20.6,f20.6,f20.7,e20.7e2)') i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1),see(i-1,j-1)
      end do
    end do
    close(40)
    print *, 'Write in ',trim(arg(5))//'.'//trim(charnum)//'.stat',' ok.'
  end do

!Compute mean over all seeing files
  allocate(seeall_mean_mod(nx_see,ny_see))
  allocate(seeall_mean_dir(nx_see,ny_see))
  allocate(seeall_mean_X(nx_see,ny_see))
  allocate(seeall_mean_Y(nx_see,ny_see))
  do i=1,nx_see
    do j=1,ny_see
      call stats(seeall_mod(i,j,startavg_rel+1:startavg_rel+sizeavg),sizeavg,see_mean_mod,see_sd_mod,see_inc,9999.9)
      seeall_mean_mod(i,j)=see_mean_mod
      call stats(seeallX(i,j,startavg_rel+1:startavg_rel+sizeavg),sizeavg,see_mean_X,see_sd_X,see_inc,9999.9)
      seeall_mean_X(i,j)=see_mean_X
      call stats(seeallY(i,j,startavg_rel+1:startavg_rel+sizeavg),sizeavg,see_mean_Y,see_sd_Y,see_inc,9999.9)
      seeall_mean_Y(i,j)=see_mean_Y
      call stats_wind_direction(seeallX(i,j,startavg_rel+1:startavg_rel+sizeavg),seeallY(i,j,startavg_rel+1:startavg_rel+sizeavg),&
        sizeavg,see_mean_dir,see_sd_dir,see_inc,9999.9)
      seeall_mean_dir(i,j)=see_mean_dir
    end do
  end do

  inquire( file=trim(arg(5))//'.avg.stat', exist=ok )
  if (ok) then
    print*, '!!! error: file ',trim(arg(5))//'.avg.stat',' is already present'
    call exit(1)
  end if

  open(unit=40,status='new',file=trim(arg(5))//'.avg.stat',access='sequential')
  write(40,*) '### GRID SIZE X, GRID SIZE Y, START EXIT, END EXIT, EXIT NUM, &
        &MIN WIND, MAX WIND ###'
  write(40,*) nx,ny,startavgINT,endavgINT,sizeavg,seemin,seemax 
  write(40,*) '###  I   J           XLAT                XLON          ZS        &
        &WIND MODULE AVERAGE    WIND ANGLE AVERAGE    WIND X AVERAGE    WIND Y AVERAGE'
  do i=2,nx_lat-1
    do j=2,ny_lat-1
      write(40,*) i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1),seeall_mean_mod(i-1,j-1),seeall_mean_dir(i-1,j-1),&
        &seeall_mean_X(i-1,j-1),seeall_mean_Y(i-1,j-1)
!      write(40,'(i4,i4,f20.6,f20.6,f20.7,e20.7e2)') i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1),see(i-1,j-1)
    end do
  end do
  close(40)
  print *, 'Write in ',trim(arg(5))//'.avg.stat',' ok.'

!compute median over all seeing files
  allocate(seeall_med(nx_see,ny_see))
  allocate(seeall_medX(nx_see,ny_see))
  allocate(seeall_medY(nx_see,ny_see))
  allocate(see_cdx(sizeavg))
  allocate(see_cdy(sizeavg))
  do i=1,nx_see
    do j=1,ny_see
      call cumdist(sizeavg,seeall_mod(i,j,startavg_rel+1:startavg_rel+sizeavg),see_cdx,see_cdy,see_med)
      seeall_med(i,j)=see_med
      call cumdist(sizeavg,seeallX(i,j,startavg_rel+1:startavg_rel+sizeavg),see_cdx,see_cdy,see_med)
      seeall_medX(i,j)=see_med
      call cumdist(sizeavg,seeallY(i,j,startavg_rel+1:startavg_rel+sizeavg),see_cdx,see_cdy,see_med)
      seeall_medY(i,j)=see_med
    end do
  end do

  inquire( file=trim(arg(5))//'.med.stat', exist=ok )
  if (ok) then
    print*, '!!! error: file ',trim(arg(5))//'.med.stat',' is already present'
    call exit(1)
  end if

  open(unit=40,status='new',file=trim(arg(5))//'.med.stat',access='sequential')
  write(40,*) '### GRID SIZE X, GRID SIZE Y, START EXIT, END EXIT, EXIT NUM, &
        &MIN WIND, MAX WIND ###'
  write(40,*) nx,ny,startavgINT,endavgINT,sizeavg,seemin,seemax 
  write(40,*) '###  I   J           XLAT                XLON          ZS        &
       &WIND_MEDIAN        NULL_VALUE    WIND_Y_MEDIAN        WIND_X_MEDIAN'
  do i=2,nx_lat-1
    do j=2,ny_lat-1
      write(40,*) i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1),seeall_med(i-1,j-1),0.0,seeall_medX(i-1,j-1),seeall_medY(i-1,j-1)
!      write(40,'(i4,i4,f20.6,f20.6,f20.7,e20.7e2)') i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1),see(i-1,j-1)
    end do
  end do
  close(40)
  print *, 'Write in ',trim(arg(5))//'.med.stat',' ok.'

  deallocate(xlatm)
  deallocate(xlonm)
  deallocate(xzs)
  deallocate(seeallX)
  deallocate(seeallY)
  deallocate(seeall_mod)
  deallocate(seeall_dir)
  deallocate(seeall_mean_mod)
  deallocate(seeall_mean_dir)
  deallocate(seeall_mean_X)
  deallocate(seeall_mean_Y)
  deallocate(seeall_med)
  deallocate(see_cdx)
  deallocate(see_cdy)
  deallocate(variable)

end program read_latlonWIND
