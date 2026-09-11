program test

  use mod_read_ficval
  implicit none
  integer :: i,j,argnum,Dist,tmpj,tmpi,nx_lat,ny_lat,nx_xzs,ny_xzs
  integer, parameter :: narg=5
  real :: PTlat=32.700863, PTlon=-109.889595
  character(120) :: arg(narg)
  real,dimension(:,:),allocatable :: xlatm,xlonm,xzs
  real,dimension(:),allocatable :: tmplat
  real,dimension(:),allocatable :: tmplon
  logical :: ok
  real :: minZS,maxZS,nearLAT,nearLON,DeltaMax,TMPDelta
  integer,dimension(2) :: minIJ,maxIJ,nearIJ
  real,dimension(:,:), allocatable :: variable
  integer :: nx,ny
  integer :: klevel
  logical :: isextraction,isconversion,islevelK
  character(30) :: varname,timevar

!******************************* INPUT ARGUMENTS *******************************
  argnum=command_argument_count()
  if (argnum /= narg-2) then
    if (argnum <narg) then
      print*, '!!! error: wrong number of arguments'
      print*, '!!!        you have to pass the following arguments:'
      print*, '!!!      1 - LatLon file'
      print*, '!!!      2 - ZS file'
      print*, '!!!      3 - output file'
      print*, '!!!      4 - latitude of point (real) - optional'
      print*, '!!!      5 - longitude of point (real) - optional'
      print*, '!!!        if you chose to pass argument 4 and 5 then both must be present'
      call exit(1)
    else if  (argnum > narg) then
      print*, '!!! error: too many input arguments'
      print*, '!!!        you have to pass the following arguments:'
      print*, '!!!      1 - LatLon file'
      print*, '!!!      2 - ZS file'
      print*, '!!!      3 - output file'
      print*, '!!!      4 - latitude of point (real) - optional'
      print*, '!!!      5 - longitude of point (real) - optional'
      print*, '!!!        if you chose to pass argument 4 and 5 then both must be present'
      call exit(1)
    end if
  end if
  do i=1,narg
    if (i > narg) exit
      call get_command_argument(i, arg(i))
    if (len_trim(arg(i)) == 0) exit
!    print*, '*',trim(arg(i)),'*'
  end do
  if (argnum == 5) then
    read(arg(4),'(f20.13)') PTlat
    read(arg(5),'(f20.13)') PTlon
  end if
  call read_file_FICVAL(arg(1),klevel,isextraction,isconversion,islevelK,varname,timevar,variable)
  if (isconversion) then
    nx=int(size(variable,1)/2)
    ny=size(variable,2)
    allocate(xlatm(nx,ny))
    allocate(xlonm(nx,ny))
    allocate(tmplat(ny))
    allocate(tmplon(nx))
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
    nx_xzs=nx
    ny_xzs=ny
  else
    print*, '!!! error: you did not select a valid ZS file'
    call exit(1)
  end if
  inquire( file=arg(3), exist=ok )
  if (ok) then
    print*, '!!! error: file ',arg(3),' is already present'
    call exit(1)
  end if

!******************************* ANALYSIS ROUTINE *******************************

  open(unit=40,status='new',file=arg(3),access='sequential')
  write(40,*) 'I  J   XLAT      XLON     XZS   '
  do i=2,nx_lat-1
    do j=2,ny_lat-1
      write(40,'(2i4,2f20.13,f9.2)') i,j,xlatm(i,j),xlonm(i,j),xzs(i-1,j-1)
    end do
  end do
  close(40)
  print *, 'Write in ',trim(arg(3)),' ok.'

  print *, '-------------------------------'
  print *, 'Latitude / Longitude of domain'
  print '("(1,",i4,") , (",f20.13,",",f20.13,")")', ny_lat,xlatm(1,ny_lat),xlonm(1,ny_lat)
  print '("(",i4,",",i4,") , (",f20.13,",",f20.13,")")', nx_lat,ny_lat,xlatm(nx_lat,ny_lat),xlonm(ny_lat,ny_lat)
  print '("(1,1)",f20.13,",",f20.13,")")', xlatm(1,1),xlonm(1,1)
  print '("("i4,",1,",") , (",f20.13,",",f20.13,")")', nx_lat,xlatm(nx_lat,1),xlonm(nx_lat,1)
  print *, '-------------------------------'

  print *, 'Latitude / Longitude of real space'
  print '("(2,",i4,") , (",f20.13,",",f20.13,")")', (ny_lat-1),xlatm(2,ny_lat-1),xlonm(2,ny_lat-1)
  print '("(",i4,",",i4,") , (",f20.13,",",f20.13,")")',(nx_lat-1),(ny_lat-1),xlatm(nx_lat-1,ny_lat-1),xlonm(nx_lat-1,ny_lat-1)
  print '("(2,2)",f20.13,",",f20.13,")")', xlatm(2,2),xlonm(2,2)
  print '("("i4,",2,",") , (",f20.13,",",f20.13,")")',(nx_lat-1),xlatm(nx_lat-1,2),xlonm(nx_lat-1,2)
  print *, '-------------------------------'

  minZS=minval(xzs(1:nx_xzs,1:ny_xzs))
  maxZS=maxval(xzs(1:nx_xzs,1:ny_xzs))

  minIJ=minloc(xzs(1:nx_xzs,1:ny_xzs))
  minIJ=minIJ+1
  maxIJ=maxloc(xzs(1:nx_xzs,1:ny_xzs))
  maxIJ=maxIJ+1

  print *, '-------------------------------'
  print '("MIN altitude = ",f9.2,"  --  coord = (",i4,",",i4,")")', minZS,minIJ(1),minIJ(2)
  print '("MAX altitude = ",f9.2,"  --  coord = (",i4,",",i4,")")', maxZS,maxIJ(1),maxIJ(2)
  print *, '-------------------------------'

  if (argnum == 5) then
    tmplat=xlatm(1,:)-PTlat
    tmplon=xlonm(:,1)-PTlon
  
    nearLAT=minval(abs(tmplat))
    nearLON=minval(abs(tmplon))
    nearIJ(2)=minloc(abs(tmplat),dim=1)
    nearIJ(1)=minloc(abs(tmplon),dim=1)
    print *, '-------------------------------'
    print '("LatLon Point = (",f20.13,",",f20.13,")")', PTlat,PTlon
    print '("NEAR grid point = (",i4,",",i4,")  --  ZS = ",f9.2)', nearIJ(1),nearIJ(2),xzs(nearIJ(1)-1,nearIJ(2)-1)

    if (tmplat(nearIJ(1)) > 0) nearIJ(1)=nearIJ(1)-1
    if (tmplon(nearIJ(2)) > 0) nearIJ(2)=nearIJ(2)-1
    print '("conventional NEAR grid point = (",i4,",",i4,")  --  ZS = ",f9.2)', nearIJ(1),nearIJ(2),xzs(nearIJ(1)-1,nearIJ(2)-1)
    print *, '-------------------------------'

    print *, '-------------------------------'
    print*, 'nearby points (2 grid points): '
    do i=max(1,nearIJ(1)-2),min(nx_lat,nearIJ(1)+2)
      do j=max(1,nearIJ(2)-2),min(ny_lat,nearIJ(2)+2)
        print '("(",i4,",",i4,")  --  ZS = ",f9.2)', i,j,xzs(i-1,j-1)
      end do
    end do
    print *, '-------------------------------'
    
    Dist=1
    DeltaMax=maxval(abs(xzs(nearIJ(1)-1-Dist:nearIJ(1)-1+Dist,nearIJ(2)-1-Dist:nearIJ(2)-1+Dist)-xzs(nearIJ(1)-1,nearIJ(2)-1)))
    print '("DeltaMAX (1grid) = ",f9.2," m")', DeltaMAX

    Dist=2
    DeltaMax=maxval(abs(xzs(nearIJ(1)-1-Dist:nearIJ(1)-1+Dist,nearIJ(2)-1-Dist:nearIJ(2)-1+Dist)-xzs(nearIJ(1)-1,nearIJ(2)-1)))
    print '("DeltaMAX (2grid) = ",f9.2," m")', DeltaMAX

    Dist=3
    DeltaMax=maxval(abs(xzs(nearIJ(1)-1-Dist:nearIJ(1)-1+Dist,nearIJ(2)-1-Dist:nearIJ(2)-1+Dist)-xzs(nearIJ(1)-1,nearIJ(2)-1)))
    print '("DeltaMAX (3grid) = ",f9.2," m")', DeltaMAX

    Dist=4
    DeltaMax=maxval(abs(xzs(nearIJ(1)-1-Dist:nearIJ(1)-1+Dist,nearIJ(2)-1-Dist:nearIJ(2)-1+Dist)-xzs(nearIJ(1)-1,nearIJ(2)-1)))
    print '("DeltaMAX (4grid) = ",f9.2," m")', DeltaMAX

    Dist=5
    DeltaMax=maxval(abs(xzs(nearIJ(1)-1-Dist:nearIJ(1)-1+Dist,nearIJ(2)-1-Dist:nearIJ(2)-1+Dist)-xzs(nearIJ(1)-1,nearIJ(2)-1)))
    print '("DeltaMAX (5grid) = ",f9.2," m")', DeltaMAX

    print *, '-------------------------------'
    DeltaMax=0
    tmpi=0
    tmpj=0
    do i=2,nx_xzs-1,2
      do j=2,ny_xzs-1,2
        TMPDelta=maxval(abs(xzs(i-1:i+1,j-1:j+1)-xzs(i,j)))
        if (TMPDelta > DeltaMax) then
          DeltaMax=TMPDelta
          tmpi=i
          tmpj=j
        end if
      end do
    end do
    print '("DeltaMAX over the whole domain = ",f9.2,"  --  (",i4,",",i4,")")', DeltaMax,tmpi+1,tmpj+1
    print *, '-------------------------------'

end if
deallocate(xlatm)
deallocate(xlonm)
deallocate(xzs)
deallocate(tmplat)
deallocate(tmplon)

end program test
