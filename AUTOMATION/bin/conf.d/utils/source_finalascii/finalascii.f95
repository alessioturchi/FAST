program finalascii

  use mod_read_dat

  implicit none
  integer, parameter :: dp = kind(1.d0)
  integer :: i,argnum,time,tstamp,dusk,dawn
  integer :: starttime,endtime,starttimemin,endtimemin,startindex,endindex
  integer, parameter :: header=3
  integer, parameter :: narg=11
  character(120) :: arg(narg)
  real, dimension(:,:), allocatable :: tempvar, windvar, rhvar, seevar
  logical :: ok
  character(8) :: fulldate

! Get initial arguments
  argnum=command_argument_count()
  if ((argnum > narg).or.(argnum < narg-3)) then
    print*, '!!! ERROR: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - yyyymmdd'
    print*, '!!!      2 - UNIX timestamp of the starting date'
    print*, '!!!      3 - start time (min, I5)'
    print*, '!!!      4 - end time (min, I5)'
    print*, '!!!      5 - temp evol stat file'
    print*, '!!!      6 - wind evol stat file'
    print*, '!!!      7 - rh evol stat file'
    print*, '!!!      8 - see evol stat file'
    print*, '!!!      9 - DUSK timestamp'
    print*, '!!!      10 - DAWN timestamp'
    print*, '!!!      11 - output file'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
  end do

  if (len_trim(arg(1)).ne.8) then
    print*, '!!! ERROR: finalascii: error reading date string - incorrect lenght'
    call exit(1)
  end if
  fulldate=trim(arg(1))

  read(arg(2),*) tstamp
  read(arg(3),'(I5)') starttimemin
  read(arg(4),'(I5)') endtimemin
  read(arg(9),*) dusk
  read(arg(10),*) dawn

  starttime=starttimemin*60
  endtime=endtimemin*60

  inquire( file=arg(5), exist=ok )
  if (.not. ok) then
    print*, '!!! ERROR: finalascii: file ',arg(5),' does not exists'
    call exit(1)
  end if
  call read_file(arg(5),header,tempvar)
  time=size(tempvar,1)
!Search for the real start end end time (one before and one after)
  startindex=1
  endindex=time
  do i=1,time-1
    if (tempvar(i,1) .le. starttime) then
      if (tempvar(i+1,1) .gt. starttime) then
        startindex=i
      end if
    end if
    if (tempvar(i,1) .lt. endtime) then
      if (tempvar(i+1,1) .ge. endtime) then
        endindex=i+1
      end if
    end if
  end do

  inquire( file=arg(6), exist=ok )
  if (.not. ok) then
    print*, '!!! ERROR: finalascii: file ',arg(6),' does not exists'
    call exit(1)
  end if
  call read_file(arg(6),header,windvar)
  if (size(windvar,1) .ne. time) then
    print*, '!!! ERROR: finalascii: file ',arg(6),' has wrong lines number'
    call exit(1)
  end if

  inquire( file=arg(7), exist=ok )
  if (.not. ok) then
    print*, '!!! ERROR: finalascii: file ',arg(7),' does not exists'
    call exit(1)
  end if
  call read_file(arg(7),header,rhvar)
  if (size(rhvar,1) .ne. time) then
    print*, '!!! ERROR: finalascii: file ',arg(7),' has wrong lines number'
    call exit(1)
  end if

  inquire( file=arg(8), exist=ok )
  if (.not. ok) then
    print*, '!!! ERROR: finalascii: file ',arg(8),' does not exists'
    call exit(1)
  end if
  call read_file(arg(8),header,seevar)
  if (size(rhvar,1) .ne. time) then
    print*, '!!! ERROR: finalascii: file ',arg(8),' has wrong lines number'
    call exit(1)
  end if


  inquire( file=arg(11), exist=ok )
  if (.not. ok) then
    open(unit=30,status='new',file=arg(11),form='formatted')
    write(30,'(A)') '## OUTPUTS ##'
    write(30,'(A,A)') '## DATE_MST(YYYYMMDD)=',fulldate
    write(30,'(A,I10.10)') '## DUSK (EPOCH)=',dusk
    write(30,'(A,I10.10)') '## DAWN (EPOCH)=',dawn
    write(30,'(A)') '## TIME (EPOCH), TIME FROM SIMULATION START(min, UT), TEMPERATURE (K), TEMPERATURE SD (K),&
                & WIND SPEED (m/s), WIND SPEED SD (m/s),&
                & WIND DIRECTION (deg), WIND DIRECTION SD (deg),&
                & RELATIVE HUMIDITY (%), RELATIVE HUMIDITY SD (%) &
                & TOTAL SEEING (arcsec), TOTAL SEEING SD (arcsec) ##'
    do i=startindex,endindex
      write(30,'(I16,11(3x,f25.5))') tstamp+int(tempvar(i,1)),tempvar(i,1)/60.,tempvar(i,2),tempvar(i,3),windvar(i,2),windvar(i,3),&
                &windvar(i,4),windvar(i,5),rhvar(i,2),rhvar(i,3),seevar(i,2),seevar(i,3)
    end do
    close(30)
  else
    print*, '!!! ERROR: finalascii: output file ',arg(8),' already exists'
    call exit(1)
  end if

end program finalascii

