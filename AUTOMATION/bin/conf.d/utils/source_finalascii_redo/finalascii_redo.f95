program finalascii_redo

  use mod_read_dat

  implicit none
  integer, parameter :: dp = kind(1.d0)
  integer :: i,argnum,time,time2
  integer :: starttime,endtime,starttimemin,endtimemin,startindex,endindex
  integer, parameter :: header=3
  integer, parameter :: narg=5
  character(120) :: arg(narg)
  character(1000) :: A,B,C,D,E
  real, dimension(:,:), allocatable :: tempvar, windvar
  logical :: ok
  integer, dimension(:), allocatable :: timearray

! Get initial arguments
  argnum=command_argument_count()
  if ((argnum > narg).or.(argnum < narg-3)) then
    print*, '!!! ERROR: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - previous final output file'
    print*, '!!!      2 - start time (min, I5)'
    print*, '!!!      3 - end time (min, I5)'
    print*, '!!!      4 - wind evol stat file'
    print*, '!!!      5 - output file'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
  end do

  inquire( file=arg(1), exist=ok )
  if (.not. ok) then
    print*, '!!! ERROR: finalascii_redo: file ',arg(1),' does not exists'
    call exit(1)
  end if

  inquire( file=arg(4), exist=ok )
  if (.not. ok) then
    print*, '!!! ERROR: finalascii_redo: file ',arg(4),' does not exists'
    call exit(1)
  end if

  read(arg(2),'(I5)') starttimemin
  read(arg(3),'(I5)') endtimemin

  starttime=starttimemin*60
  endtime=endtimemin*60

  call read_file(arg(1),5,tempvar)
  time=size(tempvar,1)

  allocate(timearray(time))
  open(unit=10,status='old',file=arg(1),access='sequential')
  read(10,'(A)' ) A
  read(10,'(A)' ) B
  read(10,'(A)' ) C
  read(10,'(A)' ) D
  read(10,'(A)' ) E
  do i=1,time
    read(10,'(I16)' ) timearray(i)
  end do
  close(10)

  call read_file(arg(4),header,windvar)
  time2=size(windvar,1)
!Search for the real start end end time (one before and one after)
  startindex=1
  endindex=time2
  do i=1,time2-1
    if (windvar(i,1) .le. starttime) then
      if (windvar(i+1,1) .gt. starttime) then
        startindex=i
      end if
    end if
    if (windvar(i,1) .lt. endtime) then
      if (windvar(i+1,1) .ge. endtime) then
        endindex=i+1
      end if
    end if
  end do
  if ( (endindex-startindex+1).ne.time) then
    print*, '!!! ERROR: finalascii_redo: file ',arg(4),' has wrong number of lines'
    call exit(1)
  end if
 
  inquire( file=arg(5), exist=ok )
  if (.not. ok) then
    open(unit=30,status='new',file=arg(5),form='formatted')
    write(30,'(A)') trim(A)
    write(30,'(A)') trim(B)
    write(30,'(A)') trim(C)
    write(30,'(A)') trim(D)
    write(30,'(A)') trim(E)
    do i=1,time
    write(30,'(I16,11(3x,f25.5))') timearray(i),tempvar(i,2),tempvar(i,3),tempvar(i,4),&
      &windvar(startindex+i-1,2),windvar(startindex+i-1,3),&
      &tempvar(i,7),tempvar(i,8),tempvar(i,9),tempvar(i,10),tempvar(i,11),tempvar(i,12)
    end do
    close(30)
  else
    print*, '!!! ERROR: finalascii_redo: output file ',arg(5),' already exists'
    call exit(1)
  end if

end program finalascii_redo

