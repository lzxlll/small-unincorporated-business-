

// ------------------------ IPUMS CPS data ------------------- //
// Figure start from line 131 !!!//

// the first year IPUMS CPS data report the incorporate and unincorporate se (separately!!!) is 1988,
// this figure depcits the long-run trend of unincorporate se. 
// it is interesting for several reasons: 1. not affected by cyclical recessions. 2. monotonically decreasing since 1990 till 2020 

cd "G:\Automation_SE\Data\IPUMS"



use if year >= 1980 & year <= 1982 using 80-2010_cps, clear
merge m:1 occ using "G:\Automation_SE\Data\IPUMS\occ1970_occ1990dd.dta", nogen keep(match master)
save f1, replace

use if year >= 1983 & year <= 1991 using 80-2010_cps, clear
merge m:1 occ using "G:\Automation_SE\Data\IPUMS\occ1980_occ1990dd.dta", nogen keep(match master)
save f2, replace

use if year >= 1992 & year <= 2002 using 80-2010_cps, clear
merge m:1 occ using "G:\Automation_SE\Data\IPUMS\occ1990_occ1990dd.dta", nogen keep(match master)
save f3, replace

use if year >= 2003 & year <= 2010 using 80-2010_cps, clear
replace occ = occ/10
merge m:1 occ using "G:\Automation_SE\Data\IPUMS\occ2000_occ1990dd.dta", nogen keep(match master)
save f4, replace

use if year >= 2011 & year <= 2015 using 2010-2020_cps, clear
merge m:1 occ using "G:\Automation_SE\Data\IPUMS\occ2010_occ1990dd.dta", nogen keep(match master)
save f5, replace


clear
append using f1 f2 f3 f4 f5

/*
forvalues i = 1/5 {
erase f`i'.dta
}
*/

do "G:\Automation_SE\Program\subfile_ind1990dd.do" // aggregate industrial categories //
do "G:\Automation_SE\Program\subfile_occ1990dd_occgroups.do"
merge m:1 occ1990dd using "C:\Users\Zexuan Liu\Dropbox\Papers_with_Zexuan\Labor\Inequality_crime_and_Incarceration\Data\Crime_Data\Raw_Data\occ1990dd_RI.dta"

gen lopc_ind = ind7 == 7 | ind7 == 2 | ind7 == 5
gen hipc_ind = ind7 == 3 | ind7 == 4 | ind7 == 6

// check for labor force //
drop if labforce == 1
drop if labforce == 0
tab empstat
keep if year >= 1988 & year <= 2015

/*
sort cpsidp 
drop if cpsidp == 0

bys cpsidp: gen grsize = _N
*keep if grsize == 4
*/

tab classwkr
drop if classwkr == 0
drop if classwkr == 29
drop if classwkr == 26
drop if classwkr == 99
keep if age >= 16 & age <= 60

tab empstat
gen emped = empstat == 10 | empstat == 12
gen unemped = empstat == 20 | empstat == 21 | empstat == 22
gen in_se = classwkr == 14 & unemped == 0
gen unin_se = classwkr == 13 & unemped == 0
gen sa_worker = classwkr >= 20 & classwkr <= 28 & unemped == 0
gen service_worker = occ1_service == 1
gen trans_worker = occ1_transmechcraft == 1
tab classwkr

*assert unemped+ in_se + unin_se + sa_worker == 1
summ unemped in_se unin_se sa_worker


bys year: egen labfor = total(asecwt)
bys year: egen emptot = total(asecwt * emped)
bys year: egen sa_emptot = total(asecwt * emped * sa_worker)
bys year: egen insetot = total(asecwt * in_se)
bys year: egen unsetot = total(asecwt * unin_se)
bys year: egen lo_unsetot = total(asecwt * unin_se * lopc_ind)
bys year: egen hi_unsetot = total(asecwt * unin_se * hipc_ind)
bys year: egen umemptot = total(asecwt * unemped)
bys year: egen msh_occ = total(asecwt * MI * emped)
bys year: egen service_occ = total(asecwt * service_worker * emped)
bys year: egen trans_occ = total(asecwt * trans_worker * emped)


gen inse_share = insetot/emptot
gen unse_share = unsetot/emptot
gen lo_unse_share = lo_unsetot/emptot
gen hi_unse_share = hi_unsetot/emptot
gen umemp_share = umemptot/labfor
gen msh_share = msh_occ/emptot
gen service_share = service_occ/emptot
gen trans_share = trans_occ/emptot

collapse (mean) inse_share unse_share umemp_share lo_unse_share hi_unse_share msh_share service_share trans_share, by(year)

save ipums_cps_year, replace 





// ---------------------------- Figure ------------------- //


use ipums_cps_year, clear

keep if year >= 1990 & year <= 2010

sort year 
// time series of unincorporate se share in total labor force and unemployment rate //
*twoway (connected unse_share year, lpattern(solid) yaxis(1) msymbol(oh) msize(medium)) (connected service_share year, msize(medium) msymbol(o) lpattern(longdash) yaxis(2)) (connected umemp_share year, msize(medium) msymbol(T) lpattern(dash) ), legend(label(1 "Unincorporated SE Share") label(3 "Low Skill Service Share") label(2 "Unemployment Rate") bmargin(small) rows(1) position(6)) xlabel(1990(5)2010) ylabel(0.02(.01)0.1, gmin gmax)  scheme(538w) ytitle("Unincorporated SE and unemployment rate")  ytitle("Low skill service share", axis(2)) xtitle("Year")

twoway (connected unse_share year, lpattern(solid) yaxis(1) msymbol(oh) msize(medium)) (connected inse_share year, msize(medium) msymbol(o) lpattern(longdash)) (connected umemp_share year, msize(medium) msymbol(T) lpattern(dash) ), legend(label(1 "Unincorporated SE Share") label(2 "Incorporated SE Share") label(3 "Unemployment Rate") bmargin(small) rows(1) position(6)) xlabel(1990(5)2010) ylabel(0.02(.01)0.1, gmin gmax)  scheme(538w) xtitle("Year")




