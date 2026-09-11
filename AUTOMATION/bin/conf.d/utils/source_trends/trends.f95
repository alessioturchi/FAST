program trends

  implicit none
  integer, parameter :: dp = kind(1.d0)
  integer :: i,argnum
  integer, parameter :: narg=8
  character(120) :: arg(narg)
  integer :: tt,t1,t2,hh1,hh2,statpoints
  real :: ttr,tr1,tr2,tr3,tr4
  real :: h1,h2,seeing_mean,seeing_sd,Jcn2_mean,Jcn2_sd,iso_mean,iso_sd,tau_mean,tau_sd
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
    print*, '!!!      1 - yyyymmdd'
    print*, '!!!      2 - seeisotau stat file'
    print*, '!!!      3 - wind evol stat file'
    print*, '!!!      4 - wd evol stat file'    
    print*, '!!!      5 - temp evol stat file'
    print*, '!!!      6 - rh evol stat file'
    print*, '!!!      7 - wv evol stat file'
    print*, '!!!      8 - output file'
    call exit(1)
  end if

  do i=1,command_argument_count()
    if (i > narg) exit
    call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
  end do


  if (len_trim(arg(1)).ne.8) then
    print*, '!!! trends: error reading date string - incorrect lenght'
    call exit(1)
  end if
  read(arg(1),'(I8)') fulldate

  inquire( file=arg(2), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(2),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(2),form='formatted')
  read(30,*)
  read(30,*) tt,t1,t2,h1,h2,hh1,hh2,seeing_mean,seeing_sd,Jcn2_mean,Jcn2_sd,iso_mean,iso_sd,tau_mean,tau_sd,statpoints
  close(30)

  inquire( file=arg(3), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(3),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(3),form='formatted')
  read(30,*)
  read(30,*) ttr,tr1,tr2,wind_mean,wind_sd,tr3,tr4
  close(30)

  inquire( file=arg(4), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(4),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(4),form='formatted')
  read(30,*)
  read(30,*) ttr,tr1,tr2,tr3,tr4,wd_mean,wd_sd
  close(30)

  inquire( file=arg(5), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(5),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(5),form='formatted')
  read(30,*)
  read(30,*) ttr,tr1,tr2,temp_mean,temp_sd
  close(30)

  inquire( file=arg(6), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(6),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(6),form='formatted')
  read(30,*)
  read(30,*) ttr,tr1,tr2,rh_mean,rh_sd
  close(30)

  inquire( file=arg(7), exist=ok )
  if (.not. ok) then
    print*, '!!! trends: file ',arg(7),' does not exists'
    call exit(1)
  end if
  open(unit=30,status='old',file=arg(7),form='formatted')
  read(30,*)
  read(30,*) tt,t1,t2,h1,h2,hh1,hh2,wv_mean,wv_sd,statpoints
  close(30)

  inquire( file=arg(8), exist=ok )
  if (.not. ok) then
    open(unit=30,status='new',file=arg(8),form='formatted')
    write(30,*) '## TRENDS ##'
    write(30,*) '## DATE(YYYYMMDD) SEEING_MEAN SEEING_SD ISO_MEAN ISO_SD TAU_MEAN TAU_SD &
                 &WIND_MEAN WIND_SD WD_MEAN WD_SD TEMP_MEAN TEMP_SD RH_MEAN RH_SD &
                 &VAPOR_MEAN VAPOR_SD##'
    write(30,'(I16,16(3x,f25.5))') fulldate,seeing_mean,seeing_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
                &wind_mean,wind_sd,wd_mean,wd_sd,temp_mean,temp_sd,rh_mean,rh_sd,&
                &wv_mean,wv_sd
    close(30)
  else
    open(unit=30,status='old',position='append',file=arg(8),form='formatted')
    write(30,'(I16,16(3x,f25.5))') fulldate,seeing_mean,seeing_sd,iso_mean,iso_sd,tau_mean,tau_sd,&
                &wind_mean,wind_sd,wd_mean,wd_sd,temp_mean,temp_sd,rh_mean,rh_sd,&
                &wv_mean,wv_sd
    close(30)
  end if

end program trends

