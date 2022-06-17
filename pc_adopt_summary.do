


/*********************************************************/
/*     Computer usage by industry at aggregate level     */
/*********************************************************/

use comp_usage_data, clear

do "G:\Automation_SE\Program\subfile_ind1990dd.do" // aggregate industrial categories //

/* clean the data */
drop if age<16 | age>64 // age between 16 and 64 //
drop if statefip == 2 | statefip == 15
* keep if ahrsworkt >= 35 & ahrsworkt != 999 // full time worker //
keep if wkstat <= 15 // full time worker //
keep if ciwrkcmp == 1 | ciwrkcmp == 2 // whether use computer at work, exclude answer NA //

tab year
keep if classwkr != 29 // exclude unpaid family worker //

replace ciwrkcmp = ciwrkcmp - 1 /* convert to 0/1 dummy */
bys year ind7: egen tot_emp = total(cisuppwt)
bys year ind7: egen comp_emp = total(cisuppwt * ciwrkcmp)

gen pc_usage = comp_emp/tot_emp
tab year

gen agri_pcshare = pc_usage if ind7 == 1
gen cons_pcshare = pc_usage if ind7 == 2
gen manu_pcshare = pc_usage if ind7 == 3
gen whosale_pcshare = pc_usage if ind7 == 4
gen retsale_pcshare = pc_usage if ind7 == 5
gen fin_pcshare = pc_usage if ind7 == 6
gen serv_pcshare = pc_usage if ind7 == 7

* collapse (mean) pc_usage agri_pcshare cons_pcshare manu_pcshare whosale_pcshare retsale_pcshare fin_pcshare serv_pcshare, by(year)
collapse (mean) pc_usage, by(year ind7)

recode year (1989 = 1990) (2001 = 2000) 
keep if year == 1990 | year == 2000

gen agri_pcadopt = pc_usage if ind7 == 1 
gen cons_pcadopt = pc_usage if ind7 == 2 
gen manu_pcadopt = pc_usage if ind7 == 3 
gen whosale_pcadopt = pc_usage if ind7 == 4 
gen retail_pcadopt = pc_usage if ind7 == 5 
gen finance_pcadopt = pc_usage if ind7 == 6 
gen serve_pcadopt = pc_usage if ind7 == 7 

foreach i of varlist serve_pcadopt cons_pcadopt retail_pcadopt manu_pcadopt whosale_pcadopt finance_pcadopt {
replace `i' = `i' * 100
}

global i serve_pcadopt cons_pcadopt retail_pcadopt manu_pcadopt whosale_pcadopt finance_pcadopt
eststo: estpost tabstat $i if year == 1990, statistics(mean count) columns(statistics)
eststo: estpost tabstat $i if year == 2000, statistics(mean count) columns(statistics)
esttab using summary_table.csv, main(mean) b(3) nostar unstack nomtitle nonumber replace
est clear
