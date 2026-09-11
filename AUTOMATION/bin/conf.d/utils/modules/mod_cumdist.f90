!******************************************************************************
module mod_cumdist ! integrates cumdist.f cumdist_tertiles.f cumdist_quartiles.f and indexx.f !
!******************************************************************************

!space for parallel computation
  private
  public :: cumdist_quartiles,cumdist_tertiles,cumdist,indexx

contains

!******************************************************************************
  subroutine cumdist_quartiles(N,F,CDX,CDY,XMED,X25,X75)
!  Subroutine de calcul de la distribution cumulee des valeurs de F
!  ENTREE:F:tableau de dimension N
!         N: dimension de F
!  SORTIE: CDX: abscissa de la distribution cumulee
!          CDY: ordonnees de la distribution cumulee
!          xmed: mediane
!  F et CDX peuvent etre le meme tableau lors de l'appel
!******************************************************************************
    implicit none
    integer, intent(in) :: N
    real, dimension(N), intent(in) :: F
    real, dimension(N), intent(out) :: CDX,CDY
    real, dimension(N) :: AUX
    real, intent(out) :: XMED,X25,X75
    integer :: i,N2,N3,N4
    integer, dimension(N) :: indx

    call indexx (N,F,indx)
    AUX=F
    CDX=AUX(indx)
    N2=N/2
    N3=N/4
    N4=3*N/4
    do i=1,N
       CDY(i)=(real(i-1)/real(N-1))
    enddo
    if(2*N2.eq.N)then
       XMED=0.5*(CDX(N2)+CDX(N2+1))
    else
       XMED=CDX(N2+1)  
    endif
    if(4*N3.eq.N)then
       X25=0.5*(CDX(N3)+CDX(N3+1))
    else
       X25=CDX(N3+1)
    endif
    if((4./3.)*N4.eq.N)then
       X75=0.5*(CDX(N4)+CDX(N4+1))
    else
       X75=CDX(N4+1)
    endif

!  equivalemment, au lieu du XMED construit comme ca
!  on peut le definir aussi
!            XMED=CDX(N2)+((0.5-CDY(N2))*(CDX(N2+1)-CDX(N2))
!     1   /(CDY(N2+1)-CDY(N2)))
    return
  end subroutine cumdist_quartiles

!******************************************************************************
  subroutine cumdist_tertiles(N,F,CDX,CDY,XMED,X33,X66)
!  Subroutine de calcul de la distribution cumulee des valeurs de F
!  ENTREE:F:tableau de dimension N
!         N: dimension de F
!  SORTIE: CDX: abscissa de la distribution cumulee
!          CDY: ordonnees de la distribution cumulee
!          xmed: mediane
!  F et CDX peuvent etre le meme tableau lors de l'appel
!******************************************************************************
    implicit none
    integer, intent(in) :: N
    real, dimension(N), intent(in) :: F
    real, dimension(N), intent(out) :: CDX,CDY
    real, dimension(N) :: AUX
    real, intent(out) :: XMED,X33,X66
    integer :: i,N2,N3,N4
    integer, dimension(N) :: indx

    call indexx (N,F,indx)
    AUX=F
    CDX=AUX(indx)
    N2=N/2
    N3=N/3
    N4=2*N/3
    do i=1,N
       CDY(i)=(real(i-1)/real(N-1))
    enddo
    if(2*N2.eq.N)then
       XMED=0.5*(CDX(N2)+CDX(N2+1))
    else
       XMED=CDX(N2+1)  
    endif
    if(3*N3.eq.N)then
       X33=0.5*(CDX(N3)+CDX(N3+1))
    else
       X33=CDX(N3+1)
    endif
    if((3./2)*N4.eq.N)then
       X66=0.5*(CDX(N4)+CDX(N4+1))
    else
       X66=CDX(N4+1)
    endif

!  equivalemment, au lieu du XMED construit comme ca
!  on peut le definir aussi
!            XMED=CDX(N2)+((0.5-CDY(N2))*(CDX(N2+1)-CDX(N2))
!     1   /(CDY(N2+1)-CDY(N2)))
    return
  end subroutine cumdist_tertiles

!******************************************************************************
  subroutine cumdist(N,F,CDX,CDY,XMED)
!  Subroutine de calcul de la distribution cumulee des valeurs de F
!  ENTREE:F:tableau de dimension N
!         N: dimension de F
!  SORTIE: CDX: abscissa de la distribution cumulee
!          CDY: ordonnees de la distribution cumulee
!          xmed: mediane
!  F et CDX peuvent etre le meme tableau lors de l'appel
!******************************************************************************
    implicit none
    integer, intent(in) :: N
    real, dimension(N), intent(in) :: F
    real, dimension(N), intent(out) :: CDX,CDY
    real, dimension(N) :: AUX
    real, intent(out) :: XMED
    integer :: i,N2
    integer, dimension(N) :: indx

    call indexx (N,F,indx)
    AUX=F
    CDX=AUX(indx)
    N2=N/2
    do i=1,N
       CDY(i)=(real(i-1)/real(N-1))
    enddo
    if(2*N2.eq.N)then
       XMED=0.5*(CDX(N2)+CDX(N2+1))
    else
       XMED=CDX(N2+1)  
    endif
!  equivalemment, au lieu du XMED construit comme ca
!  on peut le definir aussi
!            XMED=CDX(N2)+((0.5-CDY(N2))*(CDX(N2+1)-CDX(N2))
!     1   /(CDY(N2+1)-CDY(N2)))
    return
    end subroutine cumdist

!******************************************************************************
 subroutine indexx (input_size, input_array, output_index)
!Output an ascending index vector output_index from an input array input_array
!of size input_size
!******************************************************************************
   integer, intent(in):: input_size
   real, dimension(input_size), intent(in):: input_array
   integer, dimension(input_size), intent(out):: output_index
   integer :: i,j,ix,iix,jix
      
   do i = 1, input_size
     output_index(i) = i
   end do
      
   ! Selection sort
   do i = 1, input_size - 1
     iix = output_index(i)
     ix = i
     do j = i + 1, input_size
       jix = output_index(j)
       ! Do your comparison here
       if (input_array(iix) .gt. input_array(jix)) then
         ! Record the smallest
         ix = j
         iix = jix
       end if
     end do
     ! Swap
     output_index(ix) = output_index(i)
     output_index(i) = iix
   end do
   return
 end subroutine indexx

!******************************************************************************
end module mod_cumdist
!******************************************************************************
