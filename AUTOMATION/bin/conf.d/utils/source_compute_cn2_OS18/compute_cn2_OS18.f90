program compute_cn2_OS18
    implicit none
    !CN2 CONSTANT FORM OSBORN and SARAZIN 2018
    real, parameter :: K=6.0
    character(300) :: temp_pres_file,theta_file,windfile,outfile
    real, dimension(:,:), allocatable :: temp,pres,theta,vx,vy,alt,timescales
    real, dimension(:), allocatable :: heights,time
    real, dimension(:,:), allocatable :: CN2,DVX,DVY,DTHETA,TKE,L
    integer :: i,j,numlevels,npoints,timestep,timestep_min,ierr,tmpint
    integer :: nline,ncol,nlinew,ncolw,proc
    real :: firsttime,firstlevel,lastlevel,timevar,altvar,tmpreal
    integer, parameter :: narg=4
    character(300) :: arg(narg)
    integer :: argnum

! Get initial arguments
    argnum=command_argument_count()
    if (argnum .ne. narg) then
        print*, '!!! error: wrong number of arguments'
        print*, '!!!        you have to pass the following arguments:'
        print*, '!!!      1 - temp_pres_p1.dat'
        print*, '!!!      2 - theta_prof_p1.dat'
        print*, '!!!      3 - vx_vy_pn.dat file'
        print*, '!!!      4 - name of output file'
        call exit(1)
    end if

    do i=1,command_argument_count()
        if (i > narg) exit
        call get_command_argument(i, arg(i))
        if (len_trim(arg(i)) == 0) exit
!           print*, '*',trim(arg(i)),'*'
    end do
    temp_pres_file=arg(1)
    theta_file=arg(2)
    windfile=arg(3)
    outfile=arg(4)

    call count_file_size(temp_pres_file,0,nline,ncol)
    call count_file_size(theta_file,0,nlinew,ncolw)
    if (nlinew .ne. nline) then
        print*, '!!! compute_cn2_OS18: rh file and temp file have different number of lines'
        call exit(1)
    end if
    call count_file_size(windfile,0,nlinew,ncolw)
    if (nlinew .ne. nline) then
        print*, '!!! compute_cn2_OS18: wind file and temp file have different number of lines'
        call exit(1)
    end if

    !Get the level numbers
    open(unit=90,file=temp_pres_file,form='formatted',iostat=ierr,status='old',access='sequential')
    do i=1,nline
        read(90,*) tmpint,tmpreal,tmpreal,altvar,timevar
        if (i==1) then
            firsttime=timevar
            firstlevel=altvar
        else
            if (timevar .ne. firsttime) exit
        end if
        lastlevel=altvar
        numlevels=i
    end do
    close(90)
    proc=tmpint
!Get the number of points in time from the line number
    npoints=int(nline/numlevels)
    if (mod(real(nline),real(numlevels)) .ne. 0) then
        print*, "nline=",nline
        print*, "numlevels=",numlevels
        print*, "npoints=",real(nline)/real(numlevels)
        print*, '!!! compute_cn2_OS18: number of lines is not a multiple of number of leveles'
        call exit(1)
    end if
    print*, 'Columns:       ',ncol
    print*, 'Lines:         ',nline
    print*, 'Levels:        ',numlevels
    print*, 'Lowest point:  ',firstlevel
    print*, 'Highest point: ',lastlevel

    allocate(temp(numlevels,npoints))
    allocate(pres(numlevels,npoints))
    allocate(theta(numlevels,npoints))
    allocate(vx(numlevels,npoints))
    allocate(vy(numlevels,npoints))
    allocate(alt(numlevels,npoints))
    allocate(timescales(numlevels,npoints))   
    allocate(heights(numlevels))
    allocate(time(npoints))
    !READ TEMP AND PRES
    open(unit=90,file=temp_pres_file,form='formatted',iostat=ierr,status='old',access='sequential')
    do j=1,npoints
      do i=1,numlevels
        read(90,*) tmpint,temp(i,j),pres(i,j),alt(i,j),timescales(i,j)
      end do
    end do
    close(90)
    heights(:)=alt(:,1)
    time(:)=timescales(1,:)
    timestep=int(timescales(1,1))
    timestep_min=int(timescales(1,1)/60.)
    !READ THETA
    open(unit=90,file=theta_file,form='formatted',iostat=ierr,status='old',access='sequential')
    do j=1,npoints
      do i=1,numlevels
        read(90,*) tmpint,theta(i,j),tmpreal,tmpreal
      end do
    end do
    close(90)
    !READ WIND
    open(unit=90,file=windfile,form='formatted',iostat=ierr,status='old',access='sequential')
    do j=1,npoints
      do i=1,numlevels
        read(90,*) tmpint,vx(i,j),vy(i,j),tmpreal,tmpreal
      end do
    end do
    close(90)

    do j=1,npoints
        do i=1,numlevels
! esprimo la pressione in mb invece che in Pascal (formato MNH)
            pres(i,j)=pres(i,j)/100.
        end do
    end do

    allocate(CN2(numlevels,npoints))   
    allocate(DVX(numlevels,npoints))
    allocate(DVY(numlevels,npoints))
    allocate(DTHETA(numlevels,npoints))
    allocate(TKE(numlevels,npoints))
    allocate(L(numlevels,npoints))

    do j=1,npoints
!    do i=1,2
        do i=1,numlevels-1
            DVX(i,j)=(vx(i+1,j) - vx(i,j))/(heights(i+1) - heights(i))
            DVY(i,j)=(vy(i+1,j) - vy(i,j))/(heights(i+1) - heights(i))
            DTHETA(i,j)=abs((theta(i+1,j)-theta(i,j))/(heights(i+1) - heights(i)))
            TKE(i,j)=(DVX(i,j)**2.) + (DVY(i,j)**2.)
            L(i,j)=sqrt((2.0*TKE(i,j))/(DTHETA(i,j)*9.81/theta(i,j)))
            CN2(i,j)= ((80.0*1.0E-6*pres(i,j))/(temp(i,j)*theta(i,j)))**2
            CN2(i,j)= CN2(i,j)*(L(i,j)**(4./3.))*(DTHETA(i,j)**2.)
            CN2(i,j)= CN2(i,j)*K          
        end do
        CN2(numlevels,j)=CN2(numlevels-1,j)        
        do i=2,numlevels-1
            if (isnan(CN2(i,j))) CN2(i,j)=(CN2(i+1,j)+CN2(i-1,j))/2.
            if (isnan(CN2(i,j))) then
                print*, "ERRORE NAN",i,j, CN2(i,j)
                call exit(1)
            end if
        end do
        if (isnan(CN2(1,j))) CN2(1,j)=CN2(2,j)
        if (isnan(CN2(numlevels,j))) CN2(numlevels,j)=CN2(numlevels-1,j)
     end do

    open(UNIT=80,FILE=outfile,FORM='FORMATTED',STATUS='UNKNOWN',ACCESS='APPEND')
    do j=1,npoints
        do i=1,numlevels
            WRITE(80,'(I10,3x,E25.18,3x,f25.18,3x,f25.5)') proc,CN2(i,j),heights(i),time(j)
        end do
    end do
    close(80)

    print*, "OK, file ",trim(outfile)," was written"


end program compute_cn2_OS18
!******************************************************************************

!******************************************************************************
subroutine count_file_size(namefile,headerlines,nline,ncol)
!Generically read a file and outputs an array with data
!******************************************************************************
  implicit none
  integer, parameter :: maxcol=30                                 !Maximum column number
  integer, parameter :: maxlinelenght=2000                        !Maximum line lenght
  character(120), intent(in) :: namefile
  integer, intent(in) :: headerlines
  integer, intent(out) :: nline,ncol
  integer :: i,j,error
  real :: tmp
  logical :: ok
  character(maxlinelenght) :: line
  character(32) :: word

  inquire( file=namefile, exist=ok )
  if (.not. ok) then
    print*, '!!! read_file: file ',trim(namefile),' does not exists'
    call exit(1)
  end if
  open(unit=10,status='old',file=namefile,access='sequential')
  do i=1,headerlines
    read(10,'(A)') line
  end do
  nline=0
  ncol=0
  error=0
  i=1
  read(10,'(A)' ) line
  do while ( error == 0 )
    read(line,*, iostat=error) ( word, j=1,i )
    i=i+1
    if (i>maxcol) then
       print*, '!!! read_file: too many columns in file ',trim(namefile)
       call exit(1)
    end if
    if ( error == 0 ) then
      ncol=ncol+1
    else if ( error /= 0 ) then
      if ( error > 0 ) then
        print*, '!!! read_file: error while determining columns number from file ',trim(namefile),' at line 1, column',ncol
        call exit(1)
      end if
      exit
    end if
  end do
  rewind(10)
  do i=1,headerlines
    read(10,'(A)') line
  end do
  error=0
  do while ( error == 0 )
    read(10,*,iostat=error) tmp
    if ( error == 0 ) then
      nline=nline+1
    else if ( error /= 0 ) then
      if ( error > 0 ) then
        print*, '!!! read_file: error while determining line number from file',trim(namefile),' at line',nline
        call exit(1)
      end if
      exit
    end if
  end do
  close(10)
end subroutine count_file_size
!******************************************************************************
