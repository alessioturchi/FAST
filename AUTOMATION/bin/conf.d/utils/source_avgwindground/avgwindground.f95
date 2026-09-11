program avgwindground

  implicit none
  integer, parameter :: dp = kind(1.d0)
  integer :: i,argnum
  integer, parameter :: narg=1
  character(120) :: arg(narg)
  real :: ttr,tr1,tr2
  real :: wind_mean,wind_sd,wd_mean,wd_sd
  logical :: ok

! Get initial arguments
  argnum=command_argument_count()
  if ((argnum > narg).or.(argnum < narg)) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - wind evol stat file'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
  end do

  inquire( file=arg(1), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(1),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(1),form='formatted')
  read(30,*)
  read(30,*) ttr,tr1,tr2,wind_mean,wind_sd,wd_mean,wd_sd
  close(30)

  write(*,'(f25.5)') wind_mean

end program avgwindground

