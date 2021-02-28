!##############################################################################
! MODULE globals
!
! This code is published under the GNU General Public License v3
!                         (https://www.gnu.org/licenses/gpl-3.0.en.html)
!
! Authors: Hans Fehr, Maurice Hofmann and Fabian Kindermann
!          contact@ce-fortran.com
!
! #VC# VERSION: 1.0  (16 December 2019)
!
!##############################################################################
module globals

    use toolbox

    implicit none

    ! number of transition periods
    integer, parameter :: TT = 40

    ! number of years the household lives
    integer, parameter :: JJ = 12

    ! number of years the household retires
    integer, parameter :: JR = 10

    ! number of persistent shock process values
    integer, parameter :: NP = 2

    ! number of transitory shock process values
    integer, parameter :: NS = 5

    ! number of points on the asset grid
    integer, parameter :: NA = 100

    ! number of points on the earnings points grid for retirement
    integer, parameter :: NR = 10

    ! household preference parameters
    real*8, parameter :: gamma = 0.50d0
    real*8, parameter :: egam = 1d0 - 1d0/gamma
    real*8, parameter :: nu    = 0.335d0
    real*8, parameter :: beta  = 0.998**5

    ! household risk process
    real*8, parameter :: sigma_theta = 0.23d0
    real*8, parameter :: sigma_eps   = 0.05d0
    real*8, parameter :: rho         = 0.98d0

    ! production parameters
    real*8, parameter :: alpha = 0.36d0
    real*8, parameter :: delta = 1d0-(1d0-0.0823d0)**5
    real*8, parameter :: Omega = 1.60d0

    ! size of the asset grid
    real*8, parameter :: a_l    = 0.0d0
    real*8, parameter :: a_u    = 35d0
    real*8, parameter :: a_grow = 0.05d0

    ! size of the earnings point grid
    real*8, parameter :: ep_l    = 0d0
    real*8, parameter :: ep_u    = 7d0
    real*8, parameter :: ep_grow = 0.02d0

    ! demographic parameters
    real*8, parameter :: n_p   = (1d0+0.01d0)**5-1d0

    ! simulation parameters
    real*8, parameter :: damp    = 0.30d0
    real*8, parameter :: sig     = 1d-4
    integer, parameter :: itermax = 50

    ! counter variables
    integer :: iter

    ! macroeconomic variables
    real*8 :: r(0:TT), rn(0:TT), w(0:TT), wn(0:TT), p(0:TT)
    real*8 :: KK(0:TT), AA(0:TT), BB(0:TT), LL(0:TT), HH(0:TT)
    real*8 :: YY(0:TT), CC(0:TT), II(0:TT), GG(0:TT)

    ! government variables
    real*8 :: gy, by, tauc(0:TT), tauw(0:TT), taur(0:TT), taxrev(4,0:TT)
    real*8 :: taup(0:TT), kappa(0:TT), lambda(0:TT), PP(0:TT), tau_impl(JJ, 0:TT)
    integer :: tax(0:TT)

    ! LSRA variables
    real*8 :: BA(0:TT) = 0d0, SV(0:TT) = 0d0, lsra_comp, lsra_all, Lstar
    logical :: lsra_on

    ! cohort aggregate variables
    real*8 :: c_coh(JJ, 0:TT), l_coh(JJ, 0:TT), y_coh(JJ, 0:TT), a_coh(JJ+1, 0:TT), pen(JJ, 0:TT)
    real*8 :: v_coh(JJ, 0:TT) = 0d0, VV_coh(JJ, 0:TT) = 0d0

    ! the shock process
    real*8 :: dist_theta(NP), theta(NP)
    real*8 :: pi(NS, NS), eta(NS)
    integer :: is_initial = 3

    ! demographic and other model parameters
    real*8 :: m(JJ, 0:TT), pop(JJ, 0:TT), eff(JJ), workpop(0:TT), INC(0:TT)

    ! individual variables
    real*8 :: a(0:NA), ep(0:NR), aplus(JJ, 0:NA, 0:NR, NP, NS, 0:TT), epplus(JJ, 0:NA, 0:NR, NP, NS, 0:TT)
    real*8 :: penp(JJ, 0:TT, 0:NR)
    real*8 :: c(JJ, 0:NA, 0:NR, NP, NS, 0:TT), l(JJ, 0:NA, 0:NR, NP, NS, 0:TT)
    real*8 :: phi(JJ, 0:NA, 0:NR, NP, NS, 0:TT), VV(JJ, 0:NA, 0:NR, NP, NS, 0:TT) = 0d0
    real*8 :: v(JJ, 0:NA, 0:NR, NP, NS, 0:TT) = 0d0, FLC(JJ,0:TT)

    ! numerical variables
    real*8 :: RHS(JJ, 0:NA, 0:NR, NP, NS, 0:TT), EV(JJ, 0:NA, 0:NR, NP, NS, 0:TT)
    integer :: ij_com, ia_com, ir_com, ip_com, is_com, it_com
    real*8 :: cons_com, lab_com, epplus_com, DIFF(0:TT)

contains


    function foc(x_in)

        implicit none
        real*8, intent(in) :: x_in
        real*8 :: foc, a_plus, varphi_a, varphi_r, tomorrow, wagen, wage, v_ind, available
        integer :: ial, iar, irl, irr, itp

        ! calculate tomorrows assets
        a_plus  = x_in

        ! get tomorrows year
        itp = year(it_com, ij_com, ij_com+1)

        ! get lsra transfer payment
        v_ind = v(ij_com, ia_com, ir_com, ip_com, is_com, it_com)

        ! calculate the marginal wage rate
        wage = w(it_com)*eff(ij_com)*theta(ip_com)*eta(is_com)
        wagen = wn(it_com)*eff(ij_com)*theta(ip_com)*eta(is_com)

        ! calculate available resources
        available = (1d0+rn(it_com))*a(ia_com) + penp(ij_com, it_com, ir_com) + v_ind

        ! determine labor
        if(ij_com < JR)then
            lab_com = min( max(nu +(1d0-nu)*(a_plus-available)/ &
                (wage*(1d0-tauw(it_com)-tau_impl(ij_com,it_com))), 0d0) , 1d0-1d-10)
        else
            lab_com = 0d0
        endif

        ! calculate consumption
        cons_com = max( (available + wagen*lab_com - a_plus)/p(it_com) , 1d-10)

        ! pension system
        if(ij_com >= JR)then
            epplus_com = ep(ir_com)
        else
            epplus_com = (ep(ir_com)*dble(ij_com-1) + lambda(it_com) + &
                         (1d0-lambda(it_com))*wage*lab_com/INC(it_com))/dble(ij_com)
        endif


        ! calculate linear interpolation for future part of first order condition
        call linint_Grow(a_plus, a_l, a_u, a_grow, NA, ial, iar, varphi_a)
        call linint_Grow(epplus_com, ep_l, ep_u, ep_grow, NR, irl, irr, varphi_r)


        tomorrow = max(varphi_a*varphi_r*RHS(ij_com+1, ial, irl, ip_com, is_com, itp) + &
                       varphi_a*(1d0-varphi_r)*RHS(ij_com+1, ial, irr, ip_com, is_com, itp) + &
                       (1d0-varphi_a)*varphi_r*RHS(ij_com+1, iar, irl, ip_com, is_com, itp) + &
                       (1d0-varphi_a)*(1d0-varphi_r)*RHS(ij_com+1, iar, irr, ip_com, is_com, itp), 0d0)

        ! calculate first order condition for consumption
        foc = margu(cons_com, lab_com, it_com)**(-gamma) - tomorrow

    end function


    ! calculates marginal utility of consumption
    function margu(cons, lab, it)

        implicit none
        real*8, intent(in) :: cons, lab
        integer, intent(in) :: it
        real*8 :: margu, c_help, l_help

        ! check whether consumption or leisure are too small
        c_help = max(cons, 1d-10)
        l_help = min(max(lab, 0d0),1d0-1d-10)

        margu = nu*(c_help**nu*(1d0-l_help)**(1d0-nu))**egam/(p(it)*c_help)

    end function

    ! calculates the value function
    function valuefunc(a_plus, ep_plus, cons, lab, ij, ip, is, it)

        implicit none
        integer, intent(in) :: ij, ip, is, it
        real*8, intent(in) :: a_plus, ep_plus, cons, lab
        real*8 :: valuefunc, varphi_a, varphi_r, c_help, l_help
        integer :: ial, iar, irl, irr, itp

        ! check whether consumption or leisure are too small
        c_help = max(cons, 1d-10)
        l_help = min(max(lab, 0d0),1d0-1d-10)

        ! get tomorrows year
        itp = year(it, ij, ij+1)

        ! get tomorrows utility
        call linint_Grow(a_plus, a_l, a_u, a_grow, NA, ial, iar, varphi_a)
        call linint_Grow(ep_plus, ep_l, ep_u, ep_grow, NR, irl, irr, varphi_r)


        ! calculate tomorrow's part of the value function
        valuefunc = 0d0
        if(ij < JJ)then
            valuefunc = max(varphi_a*varphi_r*EV(ij+1, ial, irl, ip, is, itp) + &
                            varphi_a*(1d0-varphi_r)*EV(ij+1, ial, irr, ip, is, itp) + &
                            (1d0-varphi_a)*varphi_r*EV(ij+1, iar, irl, ip, is, itp) + &
                            (1d0-varphi_a)*(1d0-varphi_r)*EV(ij+1, iar, irr, ip, is, itp), 1d-10) &
                             **egam/egam
        endif

        ! add todays part and discount
        valuefunc = (c_help**nu*(1d0-l_help)**(1d0-nu))**egam/egam + beta*valuefunc

    end function


    ! calculates year at which age ij agent is ijp
    function year(it, ij, ijp)

        implicit none
        integer, intent(in) :: it, ij, ijp
        integer :: year

        year = it + ijp - ij

        if(it == 0 .or. year <= 0)year = 0
        if(it == TT .or. year >= TT)year = TT

    end function

end module