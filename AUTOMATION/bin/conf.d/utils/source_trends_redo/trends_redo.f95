program trends_redo

  implicit none
  integer, parameter :: dp = kind(1.d0)
  integer :: i,argnum
  integer, parameter :: narg=3
  character(120) :: arg(narg)
  real :: ttr,tr1,tr2,tr3,tr4
  real :: seeing_mean,seeing_sd,iso_mean,iso_sd,tau_mean,tau_sd
  real :: wind_mean,wind_sd,wd_mean,wd_sd
  real :: temp_mean,temp_sd
  real :: rh_mean,rh_sd
  real :: wv_mean,wv_sd
  logical :: ok
  integer :: fulldate

! Get initial arguments
  argnum=command_argument_count()
  if ((argnum > narg).or.(argnum < narg)) then
    print*, '!!! error: wrong number of arguments'
    print*, '!!!        you have to pass the following arguments:'
    print*, '!!!      1 - previous trend file'
    print*, '!!!      2 - wind evol stat file'
    print*, '!!!      3 - output file'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
  end do


  inquire( file=arg(1), exist=ok )
  if (.not. ok) then
    print*, '!!! trends_redo: file ',arg(1),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(1),form='formatted')
  read(30,*)
  read(30,*)
  read(30,'(I16,16(3x,f25.5))') fulldate,seeing_mean,seeing_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
                &wind_mean,wind_sd,wd_mean,wd_sd,temp_mean,temp_sd,rh_mean,rh_sd,&
                &wv_mean,wv_sd
  close(30)

  inquire( file=arg(2), exist=ok )
  if (.not. ok) then
    print*, '!!! trends_redo: file ',arg(2),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(2),form='formatted')
  read(30,*)
  read(30,*) ttr,tr1,tr2,wind_mean,wind_sd,tr3,tr4
  close(30)

  inquire( file=arg(3), exist=ok )
  if (.not. ok) then
    open(unit=30,status='new',file=arg(3),form='formatted')
    write(30,*) '## TRENDS ##'
    write(30,*) '## DATE(YYYYMMDD) SEEING_MEAN SEEING_SD ISO_MEAN ISO_SD TAU_MEAN TAU_SD &
                 &WIND_MEAN WIND_SD WD_MEAN WD_SD TEMP_MEAN TEMP_SD RH_MEAN RH_SD &
                 &VAPOR_MEAN VAPOR_SD##'
    write(30,'(I16,16(3x,f25.5))') fulldate,seeing_mean,seeing_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
                &wind_mean,wind_sd,wd_mean,wd_sd,temp_mean,temp_sd,rh_mean,rh_sd,&
                &wv_mean,wv_sd
    close(30)
  else
    open(unit=30,status='old',position='append',file=arg(3),form='formatted')
    write(30,'(I16,16(3x,f25.5))') fulldate,seeing_mean,seeing_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
                &wind_mean,wind_sd,wd_mean,wd_sd,temp_mean,temp_sd,rh_mean,rh_sd,&
                &wv_mean,wv_sd
    close(30)
  end if

end program trends_redo

