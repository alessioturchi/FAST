!******************************* READING MODULE *******************************
module mod_read_ficval
!******************************************************************************

!space for allocating variable arrays
  integer, parameter :: dp = kind(1.d0)
  private
  public  :: read_file_FICVAL,read_file_CV_FICVAL

contains

subroutine read_file_CV_FICVAL(namefile,ninf,varname,timevar,variable)
  implicit none
  integer :: i,j,nchar=0,error,flag,tmp
  logical :: ok
  character(120), intent(in) :: namefile
  character(30), intent(out) :: varname,timevar
  character(120) :: line
  character(30) :: word
  real,dimension(:,:), allocatable, intent(inout) :: variable
  integer, intent(out) :: ninf
  integer :: nx,ny,iter

  varname='NULL'
  timevar='NULL'

  if (allocated(variable)) then
    deallocate(variable)
  end if

  !Read the line containing the variable name and time, among other text
  inquire( file=namefile, exist=ok )
  if (.not. ok) then
    print*, '!!! error: file ',trim(namefile),' does not exists'
    call exit(1)
  end if
  open(unit=10,status='old',file=namefile,access='sequential')
!*******FIRST HEADER LINE*************
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    if ( error == 0 ) then
      flag=flag+1
      ! We assume that fist word is CV for a vertical cut'
      if (flag==1) then
        if (trim(word)=='CV') then
          print*, 'This is a vertical cut'
        end if
      else if (flag==2) then
!        tmp=len_trim(word)
        !If the following character is present it probably is a data extraction file
        if (word(1:2)=='G:') then
          print*, 'probably this is a data extraction file'
        end if
!        varname=word(3:tmp)
!        print *, 'VAR=',varname
      else if (flag==5) then
        tmp=len_trim(word)-1
        timevar=word(1:tmp)
        print *, 'TIME=',timevar
      else if (flag>7) then
        print*, '!!! error: error reading from file ',trim(namefile),': header line 1 malformed'
        close(10)
        call exit(1)
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  !nchar should be 5 if line is a regular header. If it is greater, then abort and check what's going on
  if (nchar > 7) then
    print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 1'
    close(10)
    call exit(1)
  end if
!*******SECOND HEADER LINE*************
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    if ( error == 0 ) then
      flag=flag+1
      if (flag==1) then
        varname=trim(word)
      else if (flag>1) then
        print*, '!!! error: error reading from file ',trim(namefile),': header line 2 malformed'
        close(10)
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  print *, 'VAR=',varname
  if (nchar > 1) then
    print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 2'
    close(10)
    call exit(1)
  end if
!*******THIRD HEADER LINE*************
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    print*, word
    if ( error == 0 ) then
      flag=flag+1
      if (flag==2) then
        read(word,'(I8)') ninf
        print*, 'NINF=',ninf
      else if (flag==7) then
        read(word,'(I8)') nx
        print*, 'NX=',nx
      else if (flag==9) then
        read(word,'(I8)') ny
!        ny=ny-2
        print*, 'NY=',ny
      else if (flag==11) then
        read(word,'(I8)') iter
        print*, 'ITER=',iter
      else if (flag>11) then
        print*, '!!! error: error reading from file ',trim(namefile),': header line 3 malformed'
        close(10)
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  print *, 'VAR=',varname
  if (nchar > 11) then
    print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 3'
    close(10)
    call exit(1)
  end if
  close(10)
!*******START READING VALUES*************

  allocate(variable(nx,ny))

  inquire( file=namefile, exist=ok )
  if (ok) then
    print*, 'reading file ',namefile
    call read_varextract(namefile,3,nx,ny,iter,1,1,variable)
  end if

end subroutine read_file_CV_FICVAL

subroutine read_file_FICVAL(namefile,klevel,isextraction,isconversion,islevelK,varname,timevar,variable)
  implicit none
  integer :: i,j,nchar=0,error,flag,tmp
  character(120), intent(in) :: namefile
  logical :: ok
  character(30) :: word
  character(120) :: line
  integer, intent(out) :: klevel
  logical, intent(out) :: isextraction,isconversion,islevelK
  logical :: islevelP,islevelZ
  character(30), intent(out) :: varname,timevar
  real,dimension(:,:), allocatable, intent(inout) :: variable
  integer :: niinf,nisup,njinf,njsup,nx,ny,iter

  isextraction=.FALSE.
  isconversion=.FALSE.
  islevelK=.FALSE.
  islevelP=.FALSE.
  islevelZ=.FALSE.
  niinf=0
  njinf=0
  nisup=0
  njsup=0
  klevel=-10
  iter=0
  nx=0
  ny=0
  varname='NULL'
  timevar='NULL'

  if (allocated(variable)) then
    deallocate(variable)
  end if

  !Read the line containing the variable name and time, among other text
  inquire( file=namefile, exist=ok )
  if (.not. ok) then
    print*, '!!! error: file ',trim(namefile),' does not exists'
    call exit(1)
  end if
  open(unit=10,status='old',file=namefile,access='sequential')
!*******FIRST HEADER LINE*************
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    if ( error == 0 ) then
    ! We assume that second character is G:varname and fifth character is time.s'
      flag=flag+1
      !If the above asumption is wrong, it may be a data conversion file
      if (flag==1) then
        if (trim(word)=='FICHIER:') then
          print*, 'probably this is a conversion file, not a data extraction'
          isconversion=.TRUE.
        end if
      else if (flag==2) then
!        tmp=len_trim(word)
        !If the following character is present it probably is a data extraction file
        if (word(1:2)=='G:') then
          print*, 'probably this is a data extraction file'
          isextraction=.TRUE.
        end if
!        varname=word(3:tmp)
!        print *, 'VAR=',varname
      else if (flag==5) then
        tmp=len_trim(word)-1
        timevar=word(1:tmp)
        print *, 'TIME=',timevar
      else if (flag>5) then
        print*, '!!! error: error reading from file ',trim(namefile),': header line 1 malformed'
        close(10)
        call exit(1)
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  !nchar should be 5 if line is a regular header. If it is greater, then abort and check what's going on
  if (nchar > 5) then
    print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 1'
    close(10)
    call exit(1)
  end if
!*******SECOND HEADER LINE*************
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    if ( error == 0 ) then
    ! We check that word 8 is 'CONVERSION' or we read the variable name
      flag=flag+1
      !If the above asumption is wrong, it may be a data conversion file
      if (flag==1) then
        varname=trim(word)
      else if (flag==6) then
        if (trim(word)=='ITER') then
          print*, 'just guessing, maybe it is a conversion file?'
          isconversion=.TRUE.
        end if
      else if (flag==7) then
        if (is_numeric(word)) then
          if (isconversion) read(word,'(I8)') iter
        end if
      else if (flag==8) then
        if (trim(word)=='CONVERSION') then
          print*, 'definitely this is a conversion file'
          isconversion=.TRUE.
          varname='CONVERSION'
        end if
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  print *, 'VAR=',varname
  if (isextraction) print *, 'TIME=',timevar
!*******THIRD HEADER LINE*************
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    if ( error == 0 ) then
      flag=flag+1
      if (is_numeric(word)) then
        if (flag==2) then
          read(word,'(I8)') niinf
        else if (flag==4) then
          read(word,'(I8)') njinf
        else if (flag==6) then
          read(word,'(I8)') nisup
        else if (flag==8) then
          read(word,'(I8)') njsup
        end if
      end if
      if (flag==9) then
        if (trim(word)=='K') then
          print*, 'this is an extraction on a K level'
          islevelK=.TRUE.
        else if (trim(word)=='P') then
          print*, 'this is an extraction on a P level'
          islevelP=.TRUE.
        else if (trim(word)=='Z') then
          print*, 'this is an extraction on a Z level'
          islevelZ=.TRUE.
        end if
      else if (flag==10) then
         if ((islevelK).and.(is_numeric(word))) then
           read(word,'(I8)') klevel
           print*, 'K=',klevel
         else if ((islevelP).and.(is_numeric(word))) then
           read(word,'(I8)') klevel
           print*, 'P=',klevel
         else if ((islevelZ).and.(is_numeric(word))) then
           klevel=1
           print*, 'Z=',klevel
         end if
      else if (flag>10) then
        print*, '!!! error: error reading from file ',trim(namefile),': header line 1 malformed'
        close(10)
        call exit(1)
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  print*, 'niinf=',niinf,'njinf=',njinf,'nisup=',nisup,'njsup=',njsup
  if (islevelK) print*, 'K=',klevel
  if (islevelP) print*, 'P=',klevel
  if (islevelZ) print*, 'Z=',klevel
  !nchar should be 8 if it is a conversion and 10 if it is an extraction on a level K. If it is greater, then abort and check what's going on
  if (nchar > 8) then
    if ((islevelK .or. islevelP .or. islevelZ) .and. (nchar > 10)) then
      print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 3'
      close(10)
      call exit(1)
    else if (nchar > 11) then
      print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 3'
      close(10)    
      call exit(1)
    end if
  end if
!*******FOURTH HEADER LINE*************
  !Read the line containing the number of grid points, among other text
  read(10,'(A)' ) line
  flag=0
  do i =1,40   ! The very maximum that the string can contain
    read(line,*, iostat=error) ( word, j=1,i )
    if ( error == 0 ) then
      if (is_numeric(word)) then
        flag=flag+1
        if (flag==1) then
          read(word,'(I8)') nx
        else if (flag==2) then
          read(word,'(I8)') ny
        else if (flag==3) then
          if (.not. isconversion) then
            read(word,'(I8)') iter
          end if
        else
          print*, '!!! error: error reading from file ',trim(namefile),': header line 4 malformed'
          close(10)
          call exit(1)
        end if
      end if
    else if ( error /= 0 ) then
      nchar = i - 1
      exit
    end if
  end do
  !nchar should be 8 if it is a conversion and 10 if it is an extraction. If it is greater, then abort and check what's going on
  if (nchar > 8) then
    if (isextraction .and. (nchar > 10)) then
      print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 4'
      close(10)    
      call exit(1)
    else if (nchar > 11) then
      print*, '!!! error: error reading from file ',trim(namefile),': too many characters in header line 4'
      close(10)    
      call exit(1)
    end if
  end if
  close(10)
  print*, 'I=',nx,'J=',ny,'ITER=',iter

!*******FINAL CHECKS ON PARAMETERS*************
  if (isextraction .and. ((niinf/=2).or.(njinf/=2).or.(nisup/=(nx+1)).or.(njsup/=(ny+1)))) then
    print*, '!!! error: extrema data array are non-standard for an extraction'
    call exit(1)
  end if
  if (isconversion .and. ((niinf/=1).or.(njinf/=1).or.(nisup/=(nx)).or.(njsup/=(ny)))) then
    print*, '!!! error: extrema data array are non-standard for an conversion'
    call exit(1)
  end if
  if ((.not.isextraction).and.(.not. isconversion)) then
    print*, '!!! error: unrecognized data format'
    call exit(1)
  end if
  if ((isextraction).and.((.not. (islevelK .or. islevelP .or. islevelZ)).or.(klevel==-10))) then
    print*, '!!! error: it seems a data extraction but the level K or P is unspecified'
    call exit(1)
  end if
  !I don't want to export a dummy variable again, so we export just one.
  islevelK=islevelP

!*******START READING VALUES*************

  if (isextraction) then
    allocate(variable(nx,ny))
  else if (isconversion) then
    allocate(variable(2*nx,ny))
  end if

  inquire( file=namefile, exist=ok )
  if (ok) then
    print*, 'reading file ',namefile
    if (isextraction) call read_varextract(namefile,1,nx,ny,iter,niinf,njinf,variable)
    if (isconversion) call read_varextract(namefile,2,nx,ny,iter,niinf,njinf,variable)
  end if

end subroutine read_file_FICVAL

subroutine read_varextract(namefile,vartype,nx,ny,iter,startx,starty,variable)
  implicit none
  character(120), intent(in) :: namefile
  integer, intent(in) :: nx,ny,iter,vartype,startx,starty
  integer :: i,j,niter,nj,IOstatus,tmp,k,itercolumns,columns,starti,startj
  real,dimension(:,:), allocatable, intent(inout) :: variable

!VARTYPE=1 is data extraction file
!VARTYPE=2 is data conversion file
!VARTYPE=3 is CV file

  if ((vartype==1).or.(vartype==3)) then
    itercolumns=ceiling(real(nx)/real(iter))
    columns=itercolumns
  else if (vartype==2) then
    itercolumns=ceiling(real(nx)/real(iter))
    columns=itercolumns*2
  else
    print*, '!!! error: vartype not recognized'
    call exit(1)
  end if

  starti=startx-1
  startj=starty-1

  open(unit=20,status='old',file=namefile,access='sequential')
  !skip header
  if (vartype==3) then
    do i=1,3
      read(20,*,IOSTAT=IOstatus)
    enddo
  else
    do i=1,4
      read(20,*,IOSTAT=IOstatus)
    enddo
  end if
  niter=1
  i=1
  do while (niter <= iter)
    !skip separators
    read(20,*,IOSTAT=IOstatus)
    call check_readerr(IOstatus,namefile,niter)
    if (IOstatus < 0) exit
    read(20,*,IOSTAT=IOstatus)
    call check_readerr(IOstatus,namefile,niter)
    if (IOstatus < 0) exit
    read(20,*,IOSTAT=IOstatus)
    call check_readerr(IOstatus,namefile,niter)
    if (IOstatus < 0) exit
    !start reading something useful
    if (niter<iter) then
      do nj=1,ny
        read(20,*,IOSTAT=IOstatus) j,(variable(i+k,j-startj),k=0,columns-1)
        call check_readerr(IOstatus,namefile,niter)
        if (IOstatus < 0) exit
      end do
    else
      tmp=nx-(iter-1)*itercolumns
      if (vartype==2) tmp=tmp*2
      if (tmp>columns) then
        print*, '!!! error: remaining number of columns is wrong'
        call exit(1)
      end if
      do nj=1,ny
        read(20,*,IOSTAT=IOstatus) j,(variable(i+k,j-startj),k=0,tmp-1)
        call check_readerr(IOstatus,namefile,niter)
        if (IOstatus < 0) exit
      end do
    end if
    if ((vartype==1).or.(vartype==3)) then
      !skip another separator
      read(20,*,IOSTAT=IOstatus)
      call check_readerr(IOstatus,namefile,niter)
      if (IOstatus < 0) exit
    end if
    niter=niter+1
    i=i+columns
    if (niter>1000) then
      print*, '!!! error: too many lines in FICVAL file'
      exit
    end if
  enddo
  close(20)
end subroutine read_varextract

logical function is_numeric(string)
  implicit none
  character(len=*), intent(in) :: string
  real :: x
  integer :: e,n
  character(12) :: fmt

!  is_numeric = .false.
!  x = FOR_S_NAN
!  READ(string,*,IOSTAT=e) x
!  is_numeric = ((e == 0) .and. (.NOT. ISNAN(X))

!  READ(string,*,IOSTAT=e, ADVANCE='NO', EOR=999) x
!  is_numeric = e == 0
!  999 CONTINUE

  n=len_trim(string)
  write(fmt,'("(F",I0,".0)")') n
  read(string,fmt,IOSTAT=e) x
  is_numeric = e == 0

end function is_numeric

subroutine check_readerr(IOstatus,namefile,niter)
  implicit none
  integer, intent(in) :: IOstatus,niter
  character(32), intent(in) :: namefile

  if (IOstatus > 0) then
    print*, '!!! error: error reading from file ',trim(namefile),' at iteration ',niter
  end if
end subroutine check_readerr

end module mod_read_ficval
