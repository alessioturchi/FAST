program read_latlonCV

  use mod_statistics
  use mod_cumdist
  use mod_read_ficval
  implicit none
  integer :: i,j,argnum,nx_xalt,ny_xalt,nx_cv,ny_cv
  integer, parameter :: narg=7
  integer, dimension(:), allocatable :: exitarray
  character(120) :: arg(narg)
  character(120) :: startexit,endexit,filename,firstname,startavg,endavg
  character(3) :: charnum
  integer :: startexitINT, endexitINT,sizeexit,ne,namelen,pos,cv_inc
  integer :: startavgINT, endavgINT,sizeavg,startavg_rel
  real,dimension(:,:),allocatable :: xalt,cv,cvall_mean,cvall_med
  real :: cv_mean,cv_sd,cv_med,cvmin,cvmax
  real, dimension(:), allocatable :: cv_cdx,cv_cdy
  real, dimension(:,:,:), allocatable :: cvall
  logical :: ok
  real,dimension(:,:), allocatable :: variable
  integer :: nx,ny,ninf,ninf_alt,ninf_cv
  character(30) :: varname,timevar

  allocate(cvall(1,1,1))
  deallocate(cvall)
!******************************* INPUT ARGUMENTS *******************************
  argnum=command_argument_count()
  if (argnum /= narg) then
    if (argnum <narg) then
      print*, '!!! error: wrong number of arguments'
      print*, '!!!        you have to pass the following arguments:'
      print*, '!!!      1 - ALT ficval file'
      print*, '!!!      2 - cv ficval file - First exit file'
      print*, '!!!      3 - output file - base name, will be numbered'
      print*, '!!!      4 - Starting exit file (number from 001 to xxx)'
      print*, '!!!      5 - Ending exit file (number from 001 to xxx)'
      print*, '!!!      6 - Starting exit file for average (number, 3 characters, from 001 to xxx)'
      print*, '!!!      7 - Ending exit file for average (number, 3 characters, from 001 to xxx)'
      call exit(1)
    else
      print*, '!!! error: too many input arguments'
      print*, '!!!        you have to pass the following arguments:'
      print*, '!!!      1 - ALT ficval file'
      print*, '!!!      2 - cv ficval file - First exit file'
      print*, '!!!      3 - output file - base name, will be numbered'
      print*, '!!!      4 - Starting exit file (number, 3 characters, from 001 to xxx)'
      print*, '!!!      5 - Ending exit file (number, 3 characters, from 001 to xxx)'
      print*, '!!!      6 - Starting exit file for average (number, 3 characters, from 001 to xxx)'
      print*, '!!!      7 - Ending exit file for average (number, 3 characters, from 001 to xxx)'
      call exit(1)
    end if
  end if
  nx_cv=0
  ny_cv=0
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
  startexit=trim(arg(4))
  endexit=trim(arg(5))
  startavg=trim(arg(6))
  endavg=trim(arg(7))
  read(startexit,'(I3)') startexitINT
  read(endexit,'(I3)') endexitINT
  read(startavg,'(I3)') startavgINT
  read(endavg,'(I3)') endavgINT
  if (endexitINT <= startexitINT) then
    print*, '!!! error: start exit file number is greater than exit file number'
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
  call read_file_CV_FICVAL(arg(1),ninf,varname,timevar,variable)
  ninf_alt=ninf
  nx=size(variable,1)
  ny=size(variable,2)
  allocate(xalt(nx,ny))
  nx_xalt=nx
  ny_xalt=ny
  xalt=variable
!manipulate the input names in order to have all the names for each exit file
  firstname=arg(2)
  namelen=len_trim(firstname)
!I search for an extended string in order to avoid collisions (like with the
!year... we are fine even beyond year 2100!!! Well, I suppose I'll be dead and
!buried by that date, but let me be optimistic)
!We search for a default first number
  pos=index(firstname,'_001_')
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
    !If you didn't pass the first 001 file, we search to cv if you passed at
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
!Read the file
    call read_file_CV_FICVAL(filename,ninf,varname,timevar,variable)
    ninf_cv=ninf
    if (ninf_alt.ne.ninf_cv) then
      print*, '!!! error: the input files initial grid points do not agree'
      call exit(1)
    end if
    nx=size(variable,1)
    ny=size(variable,2)
    allocate(cv(nx,ny))
    !Allocate the global cving matrix only the first time the loop is called
    if (.not. allocated(cvall)) allocate(cvall(nx,ny,sizeexit))
    !Store the cving
    cv=variable
    cvall(:,:,ne)=cv
    if (ne > 1) then
      if ((nx /= nx_cv) .or. (ny /= ny_cv)) then
        print*, '!!! error: the input file dimensions do not agree'
        call exit(1)
      end if
    else
      if ((nx /= nx_xalt) .or. (ny /= ny_xalt)) then
        print*, '!!! error: the input file and ZS file dimensions do not agree'
        call exit(1)
      end if
    end if
    nx_cv=nx
    ny_cv=ny
    deallocate(cv)
  end do

  cvmin=minval(cvall(:,2:ny-1,:))
  cvmax=maxval(cvall(:,2:ny-1,:))

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

    inquire( file=trim(arg(3))//'.'//trim(charnum)//'.stat', exist=ok )
    if (ok) then
      print*, '!!! error: file ',trim(arg(3))//'.'//trim(charnum)//'.stat',' is already present'
      call exit(1)
    end if

    open(unit=40,status='new',file=trim(arg(3))//'.'//trim(charnum)//'.stat',access='sequential')
    write(40,*) '### GRID SIZE X, GRID SIZE Y, START EXIT, END EXIT, EXIT NUM,&
        & MIN CV, MAX CV ###'
    write(40,*) nx,ny,startexitINT,endexitINT,sizeexit,cvmin,cvmax
    write(40,*) '###  I   J           ALT        CN2'
    do i=1,nx_cv
      do j=2,ny_cv-1
        write(40,*) i+ninf_alt-1,j,xalt(i,j),cvall(i,j,ne)
      end do
    end do
    close(40)
    print *, 'Write in ',trim(arg(3))//'.'//trim(charnum)//'.stat',' ok.'
  end do

!Compute mean over all cving files
  allocate(cvall_mean(nx_cv,ny_cv))
  do i=1,nx_cv
    do j=1,ny_cv
      call stats(cvall(i,j,startavg_rel+1:startavg_rel+sizeavg),sizeavg,cv_mean,cv_sd,cv_inc,9999.9)
      cvall_mean(i,j)=cv_mean
    end do
  end do

  inquire( file=trim(arg(3))//'.avg.stat', exist=ok )
  if (ok) then
    print*, '!!! error: file ',trim(arg(3))//'.avg.stat',' is already present'
    call exit(1)
  end if

  open(unit=40,status='new',file=trim(arg(3))//'.avg.stat',access='sequential')
  write(40,*) '### GRID SIZE X, GRID SIZE Y, START EXIT, END EXIT, EXIT NUM, &
        &MIN CV, MAX CV ###'
  write(40,*) nx,ny,startavgINT,endavgINT,sizeavg,cvmin,cvmax 
  write(40,*) '###  I   J           ALT        CN2_AVERAGE'
  do i=1,nx_cv
    do j=2,ny_cv-1
      write(40,*) i+ninf_alt-1,j,xalt(i,j),cvall_mean(i,j)
    end do
  end do
  close(40)
  print *, 'Write in ',trim(arg(3))//'.avg.stat',' ok.'

!compute median over all cving files
  allocate(cvall_med(nx_cv,ny_cv))
  allocate(cv_cdx(sizeexit))
  allocate(cv_cdy(sizeexit))
  do i=1,nx_cv
    do j=1,ny_cv
      call cumdist(sizeavg,cvall(i,j,startavg_rel+1:startavg_rel+sizeavg),cv_cdx,cv_cdy,cv_med)
      cvall_med(i,j)=cv_med
    end do
  end do

  inquire( file=trim(arg(3))//'.med.stat', exist=ok )
  if (ok) then
    print*, '!!! error: file ',trim(arg(3))//'.med.stat',' is already present'
    call exit(1)
  end if

  open(unit=40,status='new',file=trim(arg(3))//'.med.stat',access='sequential')
  write(40,*) '### GRID SIZE X, GRID SIZE Y, START EXIT, END EXIT, EXIT NUM, &
        &MIN CV, MAX CV ###'
  write(40,*) nx,ny,startavgINT,endavgINT,sizeavg,cvmin,cvmax 
  write(40,*) '###  I   J           ALT        CN2_MEDIAN'
  do i=1,nx_cv
    do j=2,ny_cv-1
      write(40,*) i+ninf_alt-1,j,xalt(i,j),cvall_med(i,j)
    end do
  end do
  close(40)
  print *, 'Write in ',trim(arg(3))//'.med.stat',' ok.'

  deallocate(xalt)
  deallocate(cvall)
  deallocate(cvall_mean)
  deallocate(cvall_med)
  deallocate(cv_cdx)
  deallocate(cv_cdy)
  deallocate(variable)

end program read_latlonCV
