



cd "G:\Automation_SE\Data\IPUMS"


// Plot the computer usage at work for incorporate and unincorporate s.e //

use comp_usage_data, clear
keep if year == 1989 | year == 2001

/* clean the data */
drop if age<16 | age>64 // age between 16 and 64 //
drop if statefip == 2 | statefip == 15
keep if ahrsworkt >= 35 & ahrsworkt != 999 // full time worker //

keep if ciwrkcmp == 1 | ciwrkcmp == 2 // whether use computer at work, exclude answer NA //

tab year
keep if classwkr != 29 // class of worker not available //

gen unise = classwkr == 13
gen incse = classwkr == 14

replace ciwrkcmp = ciwrkcmp - 1
bys year statefip: egen tot_unise = total(wtfinl * unise)
bys year statefip: egen tot_salemp = total(wtfinl * incse)

bys year statefip: egen comp_unise = total(wtfinl * unise * ciwrkcmp)
bys year statefip: egen comp_salemp = total(wtfinl * incse * ciwrkcmp)

gen unise_compshare = comp_unise/tot_unise
gen salemp_compshare = comp_salemp/tot_salemp


preserve
collapse (mean) unise_compshare salemp_compshare, by(year statefip)
gen d_pc_se = salemp_compshare - unise_compshare 

reshape wide unise_compshare salemp_compshare d_pc_se, i(statefip) j(year)

graph twoway (scatter d_pc_se1989 d_pc_se2001, mlabel(state) msize(small) mlabsize(vsmall) ) ///
|| line d_pc_se1989 d_pc_se1989, sort legend(label(1 "Incorp v.s Unincorp Computer Usage Difference") ///
label(2 "45 Degree Line") bmargin(small) rows(2) position(6)) ytitle("Computer Usage Difference in 1990", size(small)) ///
xtitle("Computer Usage Difference in 2000", size(small))  xsc(r(-0.2 0.6)) xlabel(-.2(.1).6) scheme(538w) name(g1, replace)

restore



collapse (mean) unise_compshare salemp_compshare, by(statefip)
statastates, fips(state) nogen

graph twoway (scatter salemp_compshare unise_compshare, mlabel(state) msize(small) mlabsize(vsmall) ) ///
|| line unise_compshare unise_compshare, sort legend(label(1 "Computer Usage at Work in 1990 and 2000") ///
label(2 "45 Degree Line") bmargin(small) rows(2) position(6)) ytitle("Computer Usage at Work by Incorporate Self-employed", size(small)) ///
xtitle("Computer Usage at Work of Unincorporate Self-employed", size(small))  xsc(r(0.1 0.6)) xlabel(.1(.1).6) scheme(538w) name(g2, replace)

graph combine g1 g2, col(2) scheme(538w)


