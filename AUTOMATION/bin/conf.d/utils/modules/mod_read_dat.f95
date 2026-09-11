!******************************************************************************
module mod_read_dat  ! subrotines for reading .dat files                      !
!******************************************************************************

! FORTRAN 2008 stuff (need updating gcc)
!  use, intrinsic :: iso_fortran_env
  implicit none
!  integer, parameter :: sp = REAL32
!  integer, parameter :: dp = REAL64
!  integer, parameter :: qp = REAL128
  integer, parameter :: dp = kind(1.d0)
  private
  public :: read_dat_file_pv,read_dat_file_km,read_corrfile,apply_corrfile,read_file

contains
!******************************************************************************
subroutine read_dat_file_pv(namefile,variable)
!Read a.dat file and outputs an array with data
!Assume first colon is the processor number
!******************************************************************************
  implicit none
  integer :: i,j,error,nline,ncol,inttmp
  real :: tmp
  real, dimension(:,:), allocatable, intent(inout) :: variable
  logical :: ok
  character(120), intent(in) :: namefile
  integer, parameter :: maxlinelenght=1000
  character(maxlinelenght) :: line
  character(32) :: word

  if (allocated(variable)) then
    print*, '!!! read_dat_file_pv: input variable is already allocated when &
            &calling the subroutine'
    call exit(1)
  end if

  inquire( file=namefile, exist=ok )
  if (.not. ok) then
    print*, '!!! read_dat_file_pv: file ',trim(namefile),' does not exists'
    call exit(1)
  end if
  open(unit=10,status='old',file=namefile,access='sequential')
  nline=0
  ncol=0
  error=0
  i=1
  read(10,'(A)' ) line
  do while ( error == 0 )
    read(line,*, iostat=error) ( word, j=1,i )
!    read(10,'(I5,E20.10)',advance='NO',iostat=error) inttmp,(tmp,j=1,i)
!    read(10,*,iostat=error) (tmp,j=1,i)
!    read(10,*,iostat=error) (tmp,j=1,i)
    i=i+1
    if (i>20) then
       print*, '!!! read_dat_file_pv: too many columns in file ',trim(namefile)
       call exit(1)
    end if
    if ( error == 0 ) then
      ncol=ncol+1
    else if ( error /= 0 ) then
      if ( error > 0 ) then
        print*, '!!! read_dat_file_pv: error while determining columns number from file ',trim(namefile),' at line 1, column',ncol
        call exit(1)
      end if
      exit
    end if
  end do
  rewind(10)
  error=0
  do while ( error == 0 )
    read(10,*,iostat=error) tmp
    if ( error == 0 ) then
      nline=nline+1
    else if ( error /= 0 ) then
      if ( error > 0 ) then
        print*, '!!! read_dat_file_pv: error while determining line number from file',trim(namefile),' at line',nline
        call exit(1)
      end if
      exit
    end if
  end do

  rewind(10)
  allocate(variable(nline,ncol-1))

  do i=1,nline
    read(10,*,IOSTAT=error) inttmp,(variable(i,j),j=1,ncol-1)
    if (error < 0) exit
    if (error > 0) then
      print*, '!!! read_dat_file_pv: error reading from file ',trim(namefile),' at line',i
      call exit(1)
    end if
  end do

  close(10)

end subroutine read_dat_file_pv

!******************************************************************************
subroutine read_dat_file_km(namefile,variable)
!Read a.dat file and outputs an array with data
!******************************************************************************
  implicit none
  integer :: i,j,error,nline,ncol
  real :: tmp
  real, dimension(:,:), allocatable, intent(inout) :: variable
  logical :: ok
  character(120), intent(in) :: namefile
  integer, parameter :: maxlinelenght=1000
  character(maxlinelenght) :: line
  character(32) :: word

  if (allocated(variable)) then
    print*, '!!! read_dat_file_km: input variable is already allocated when &
            &calling the subroutine'
    call exit(1)
  end if

  inquire( file=namefile, exist=ok )
  if (.not. ok) then
    print*, '!!! read_dat_file_km: file ',trim(namefile),' does not exists'
    call exit(1)
  end if
  open(unit=10,status='old',file=namefile,access='sequential')
  nline=0
  ncol=0
  error=0
  i=1
  read(10,'(A)' ) line
  do while ( error == 0 )
    read(line,*, iostat=error) ( word, j=1,i )
!    read(10,'(I5,E20.10)',advance='NO',iostat=error) inttmp,(tmp,j=1,i)
!    read(10,*,iostat=error) (tmp,j=1,i)
!    read(10,*,iostat=error) (tmp,j=1,i)
    i=i+1
    if (i>20) then
       print*, '!!! read_dat_file_km: too many columns in file ',trim(namefile)
       call exit(1)
    end if
    if ( error == 0 ) then
      ncol=ncol+1
    else if ( error /= 0 ) then
      if ( error > 0 ) then
        print*, '!!! read_dat_file_km: error while determining columns number from file ',trim(namefile),' at line 1, column',ncol
        call exit(1)
      end if
      exit
    end if
  end do
  rewind(10)
  error=0
  do while ( error == 0 )
    read(10,*,iostat=error) tmp
    if ( error == 0 ) then
      nline=nline+1
    else if ( error /= 0 ) then
      if ( error > 0 ) then
        print*, '!!! read_dat_file_km: error while determining line number from file',trim(namefile),' at line',nline
        call exit(1)
      end if
      exit
    end if
  end do
  
  rewind(10)
  allocate(variable(nline,ncol))

  do i=1,nline
    read(10,*,IOSTAT=error) (variable(i,j),j=1,ncol)
    if (error < 0) exit
    if (error > 0) then
      print*, '!!! read_dat_file_km: error reading from file ',trim(namefile),' at line',i
      call exit(1)
    end if
  end do

  close(10)

end subroutine read_dat_file_km

!******************************************************************************
subroutine read_corrfile(namefile,corrections,use_it)
!Read corrections file with multiplicative and additive factors
!******************************************************************************
  implicit none
  integer, intent(out) :: use_it
  integer :: i,j,error,nline,ncol
  real :: tmp
  real, dimension(:,:), allocatable, intent(inout) :: corrections
  logical :: ok
  character(120), intent(in) :: namefile
  integer, parameter :: maxlinelenght=1000
  character(maxlinelenght) :: line
  character(32) :: word

  if (allocated(corrections)) then
    print*, '!!! read_corrfile: input variable is already allocated when &
            &calling the subroutine'
    call exit(1)
  end if

  inquire( file=namefile, exist=ok )
  if (ok) then
    open(unit=10,status='old',file=namefile,access='sequential')
    nline=0
    ncol=0
    error=0
    i=1
!Jump header
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
!First usable line
    read(10,'(A)' ) line
    do while ( error == 0 )
      read(line,*, iostat=error) ( word, j=1,i )
      i=i+1
      if (i>20) then
         print*, '!!! read_corrfile: too many columns in file ',trim(namefile)
         call exit(1)
      end if
      if ( error == 0 ) then
        ncol=ncol+1
      else if ( error /= 0 ) then
        if ( error > 0 ) then
          print*, '!!! read_corrfile: error while determining columns number from file ',trim(namefile),' at line 1, column',ncol
          call exit(1)
        end if
        exit
      end if
    end do
    rewind(10)
    error=0
!Jump header
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
!First usable line
    read(10,'(A)' ) line
    do while ( error == 0 )
      read(10,*,iostat=error) tmp
      if ( error <= 0 ) then
        nline=nline+1
      else if ( error /= 0 ) then
        if ( error > 0 ) then
          print*, '!!! read_corrfile: error while determining line number from file',trim(namefile),' at line',nline
          call exit(1)
        end if
        exit
      end if
    end do
    rewind(10)
!Jump header
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    read(10,'(A)' ) line
    print*, nline,ncol
    allocate(corrections(nline,ncol))
    do i=1,nline
      read(10,*,IOSTAT=error) (corrections(i,j),j=1,ncol)
      print*, corrections(i,:)
      if (error < 0) exit
      if (error > 0) then
        print*, '!!! read_corrfile: error reading from file ',trim(namefile),' at line',i
        call exit(1)
      end if
    end do
    close(10)
    use_it=1
  else
    use_it=0
  end if

end subroutine read_corrfile

!******************************************************************************
subroutine apply_corrfile(variable,corrections,coldata,colheight,use_it)
!Read corrections file with multiplicative and additive factors
!******************************************************************************
  implicit none
  integer, intent(in) :: coldata,colheight,use_it
  integer :: i,j,doit,linecorr,nline,ncol,nlinecorr,ncolcorr
  real, dimension(:,:), intent(in) :: corrections
  real, dimension(:,:), intent(inout) :: variable

  if (use_it == 1) then
    nline=size(variable,1)
    ncol=size(variable,2)
    nlinecorr=size(corrections,1)
    ncolcorr=size(corrections,2)
    linecorr=1
    do i=1,nline
      doit=0
      do j=1,nlinecorr
        if (variable(i,colheight) >= corrections(j,3) .AND. variable(i,colheight) <= corrections(j,4)) then
          doit=1
          linecorr=j
          exit
        end if
      end do
      if (doit == 1) then
        variable(i,coldata)=variable(i,coldata)*corrections(linecorr,1) + corrections(linecorr,2)
      end if
    end do
  end if

end subroutine apply_corrfile

!******************************************************************************
subroutine read_file(namefile,headerlines,variable)
!Generically read a file and outputs an array with data
!******************************************************************************
  implicit none
  integer, parameter :: maxcol=30                                 !Maximum column number
  integer, parameter :: maxlinelenght=2000                        !Maximum line lenght
  integer, intent(in) :: headerlines
  integer :: i,j,error,nline,ncol
  real :: tmp
  real, dimension(:,:), allocatable, intent(inout) :: variable
  logical :: ok
  character(120), intent(in) :: namefile
  character(maxlinelenght) :: line
  character(32) :: word

  if (allocated(variable)) then
    print*, '!!! read_dat_file_pv: input variable is already allocated when &
            &calling the subroutine'
    call exit(1)
  end if
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
  rewind(10)
  do i=1,headerlines
    read(10,'(A)') line
  end do
  allocate(variable(nline,ncol))
  do i=1,nline
    read(10,*,IOSTAT=error) (variable(i,j),j=1,ncol)
    if (error < 0) exit
    if (error > 0) then
      print*, '!!! read_file: error reading from file ',trim(namefile),' at line',i
      call exit(1)
    end if
  end do
  close(10)

end subroutine read_file

end module mod_read_dat

