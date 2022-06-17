









/* ------------------------ ESTIMATION --------------------------- */

// The motivation would be explain the non-cyclical decreasing trend of unincorproate se. To explain this, we
// look at the pc usage growth, which is also monotonically increasing since 1980 as well. //
// A notable change from the previous version is now we estimate the impact of pc_usage as a level rather than the change in pc_usage !!! //
// Another notable change is hypothesis, we propose 3 hypothesis: two positive and one negative.
// two positive ones: income effect and replacement effect 
// one negative hypothesis: labor in the high pc usage industries become more efficient (reflected on the wage) becasue of the augmenting effect. 
// The incorporate se would benefit more due to have larger establishment size (economy of scale), so it is more difficult for unincorp se to compete in the high pc usage industry. //


// Background: IPUMS USA data is used to generate the unse_share, the IPUMS USA covers 1980, 1990, 2000 and 2010. However, pc usage data (from IPUMS CPS) is only available for year:
// 1984, 1989, 2001, and 2003. We typically treat pc usage in 1980 as Zero. Thus, we focus on 1990, 2000 and 2010. Key dependent variable ``diff_unse_share" measures the growth of unincorporate se share
// between 1990-2000 and 2000-2010 //

// There are 722 commuting zones for each decades, for two decades: 1990-2000 and 2000-2010 we have 1444 observations in total. //
// All regressions includes state and year fixed effects and weighted by the beginning periods commuzting zone share of national population //

// pc_usshare: the pc usage at the beginning period. //
// the commutzing zone pc usage rate is calculated as the product of pc usage at national industrial level multiply by the local (CZ) industrial composition //

// RSH_1990 ASH_1990 RSH_2000 ASH_2000: the IV, the interaction term of predicted RSH and ASH using the 1950 data and time dummy, the exact same IV as Autor and Dorn paper. //

/* diff_unse_share: the percentage change of unincorporate SE between current decade and the following decade. For detail, see the code below:

sort czone year
bys czone: gen diff_`i' = `i'[_n+1] - `i'[_n]
replace diff_`i' = diff90_`i' / `i'

*/

// pc_fake: simulated pc usage rate. Recall the commutzing zone pc suage rate is calculated as the product of pc usage at national industrial level multiply by the local (CZ) industrial composition //
// the simulated pc usage rate fixing the local (CZ) industrial composition at 1980. This means we fix the industrial compositional change, variation comes from within industry pc adoption rate. //





cd "G:\Automation_SE\Data\IPUMS"

use crime_estimation, clear

keep year czone  crime_report pc_indocc_25  violent_report  crime_report tot_off d_mean_crime_report *_crime_report 
merge 1:1 year czone using master_set, nogen 


// check pc adoption percentile //
_pctile pc_usshare [aw=reg_wgt] if year >= 1990, nq(10)
return list

_pctile ASH_t [aw=reg_wgt] if year >= 1990, nq(10)
return list

/*======================================================== *//*======================================================== *//*======================================================== */
// Motivation Figures //
/*======================================================== *//*======================================================== *//*======================================================== */

do "G:\Automation_SE\Program\cps_trend_unse.do"
do "G:\Automation_SE\Program\pc usage by industry figure.do"
do "G:\Automation_SE\Program\pc_adopt_inc_uninc_figure.do"








/*======================================================== *//*======================================================== *//*======================================================== */
// Table 1: summary stats //
/*======================================================== *//*======================================================== *//*======================================================== */
// PC adoption by industry and share of unincorporate se by industry //

do "C:\Users\Zexuan Liu\Dropbox\Paper with Yao-yu\Program\New\pc_adopt_summary.do "

foreach i of varlist unse_serve unse_cons unse_retail unse_manu unse_whosale unse_finance {
replace `i' = `i' * 100 
}

global m unse_serve unse_cons unse_retail unse_manu unse_whosale unse_finance unsetot_serve unsetot_cons unsetot_retail unsetot_manu unsetot_whosale unsetot_finance 
eststo: estpost tabstat $m [aw = reg_wgt] if year == 1990, statistics(mean sd count) columns(statistics)
eststo: estpost tabstat $m [aw = reg_wgt] if year == 2000, statistics(mean sd count) columns(statistics)
eststo: estpost tabstat $m [aw = reg_wgt] if year == 2010, statistics(mean sd count) columns(statistics)
esttab using summary_table.tex, main(mean) aux(sd) b(3) nostar unstack nomtitle nonumber replace
est clear











/*======================================================== *//*======================================================== *//*======================================================== */
// Table 2: first stage result //
/*======================================================== *//*======================================================== *//*======================================================== */
// RSH_1990 ASH_1990 RSH_2000 ASH_2000 are predicted RSH and ASH using 1950 industrial mix, then interacted with time dummies of 1990 and 2000 //

eststo: areg diff90_pc_usshare RSH_nopc ASH_nopc [aw=reg_wgt], absorb(statefip) cluster(czone) // pooled first stage regression //
eststo: areg diff00_pc_usshare RSH_nopc ASH_nopc [aw=reg_wgt], absorb(statefip) cluster(czone) // pooled first stage regression //

eststo: areg RSH_nopc RSH_1990 RSH_2000 i.year [aw=reg_wgt] if year == 1990 | year == 2000, absorb(statefip) cluster(czone) // pooled first stage regression //
eststo: areg ASH_nopc ASH_1990 ASH_2000 i.year [aw=reg_wgt] if year == 1990 | year == 2000, absorb(statefip) cluster(czone) // pooled first stage regression //

eststo: areg pc_usshare RSH_1990 ASH_1990 RSH_2000 ASH_2000 i.year [aw=reg_wgt] if year >= 1990, absorb(statefip) cluster(czone) // pooled first stage regression //
eststo: areg pc_usshare RSH_1990 ASH_1990 [aw=reg_wgt] if year == 1990, absorb(statefip) cluster(czone) // single decade regression //
eststo: areg pc_usshare RSH_2000 ASH_2000 [aw=reg_wgt] if year == 2000, absorb(statefip) cluster(czone) // single decade regression //

esttab using Table_2.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(RSH_nopc ASH_nopc RSH_1990 RSH_2000 ASH_1990 ASH_2000 _cons) title(Table_1\label{tab1})  replace
eststo clear

// conclusion: the predicted RSH and ASH are logically good IV for pc usage,
// high RSH means large amount of occupations will be done by automation/ computerization, which increases the pc usage.
// the ASH occupations will be augmented by the computer, and high skill required occupations are likely to agglomerate to reach the economy of scale //



// simple scatter plot //

// relationship plot between pc adoption and 1980's RSH and ASH to justify the IV's validity //
scatter diff90_pc_usshare RSH_nopc ASH_nopc
scatter diff00_pc_usshare RSH_nopc ASH_nopc








/*======================================================== *//*======================================================== *//*======================================================== */
// Table 3: baseline results //
/*======================================================== *//*======================================================== *//*======================================================== */

set more off
// pc share on delta unincorp entrep share //

eststo: ivregress 2sls diff_unse_share pc_usshare i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // OLS state and year fixed effects //
eststo: ivregress 2sls diff_unse_share pc_usshare RSH_t i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share pc_usshare ASH_t i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share pc_usshare RSH_t ASH_t i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share pc_usshare diff_inse_share i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share pc_usshare d_tradeusch_pw i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share pc_usshare i.statefip##i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // OLS state and year fixed effects, and state-specific time trend //

eststo: ivreg2 diff_unse_share (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivreg2 diff_unse_share (pc_usshare d_tradeusch_pw= d_tradeotch_pw_lag pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
// conclsion: pc usage has a negative impact on the unincorporate share //
// models include state and year fixed effects, sd clustered at czone level. Results are robust to include state-specific time trend //

// pc share on delta unincorp entrep share --subsample by metropolitan area dummies //
eststo: ivreg2 diff_unse_share (pc_usshare c.pc_usshare#c.metro_city = pc_indocc_25 c.pc_indocc_25#c.metro_city) metro_city i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
// conclusion: impact on metro area is slightly less than non-metro areas //
// Both replacement and income effects are (suppose to be) stronger in the metro area, this result means the low-skill worker drops more siginificantly in the metro area //

esttab using Table_3.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01) keep(pc_usshare RSH_t ASH_t diff_inse_share d_tradeusch_pw c.pc_usshare#c.metro_city metro_city _cons) title(Table_1\label{tab1})  replace
eststo clear








/*======================================================== *//*======================================================== *//*======================================================== */
// Table 4: pc share on delta unincorp entrep share --subsample by decades: 1990- 2000, 2000- 2010 //
/*======================================================== *//*======================================================== *//*======================================================== */

eststo: ivregress 2sls diff_unse_share pc_usshare i.statefip [aw=reg_wgt] if year == 1990, cluster(czone) // 10 years different sample //
eststo: ivregress 2sls diff_unse_share pc_usshare i.statefip [aw=reg_wgt] if year == 2000, cluster(czone) // 10 years different sample //


eststo: ivregress 2sls diff_unse_share (pc_usshare = pc_indocc_25) i.statefip [aw=reg_wgt] if year == 1990, cluster(czone) // 20 years different sample //
eststo: ivregress 2sls diff_unse_share (pc_usshare = pc_indocc_25) i.statefip [aw=reg_wgt] if year == 2000, cluster(czone) // 20 years different sample //

// conclusion: the impact from 2000-2010 is stronger than 1990-2000 //
// although the growth of pc usage slowed down in 1990-2000 comparing to 1980-1990, however, the impact of pc usage is persistent //

esttab using Table_4.csv, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(pc_usshare _cons) title(Table_1\label{tab1})  replace
eststo clear



// Robustness checks //
// 3 year average to generate the 2010's unse share rather than signle year 2010 //

preserve
use crime_estimation, clear

keep year czone  crime_report pc_indocc_25  violent_report  crime_report tot_off d_mean_crime_report *_crime_report 
merge 1:1 year czone using master_set_robust, nogen 

eststo: ivregress 2sls diff_unse_share (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year == 1990, cluster(czone) // state and year fixed effects //
restore
eststo: ivregress 2sls diff_unse_share (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year == 2000, cluster(czone) // state and year fixed effects //

esttab using Table_4.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(pc_usshare _cons) title(Table_1\label{tab1})  replace
eststo clear





















/*======================================================== *//*======================================================== *//*======================================================== */
// Table 5: The negative relationship between pc and unse growth is driven by the high pc usage industries //
/*======================================================== *//*======================================================== *//*======================================================== */
// hypothesis: high pc usage industries are more capital intensive //
// exclude the AGRICULTURE industry //

// industries with low pc usage  //
eststo: ivregress 2sls diff_unse_serve (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_cons (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_retail (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// industries with high pc usage  //
eststo: ivregress 2sls diff_unse_manu (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_whosale (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_finance (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// conclusion: the negative relationship between pc usage and ununcorporate se is mainly in high pc usage industries //

esttab using Table_5.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(pc_usshare _cons) title(Table_1\label{tab1})  replace
eststo clear



// show the hourly wage increase significantly more for labor in high pc usage industries //
// reflecting an efficiency gain caused by computerization, the unincorp se have a disadvantage edge as their establishment size are smaller than incorporate se //

// industries with low pc usage  //
eststo: ivregress 2sls diff_serve_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_cons_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_retail_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// industries with high pc usage  //
eststo: ivregress 2sls diff_manu_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_whosale_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_finance_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
// maybe, could add disaggregated individual level regressions as Autor and Dorn Table 7 Panel B //


esttab using Table_5.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(pc_usshare _cons) title(Table_1\label{tab1})  replace
eststo clear












/*======================================================== *//*======================================================== *//*======================================================== */
// Table 6: hypothesis: the pc usage's replacement effect, this is, with the pc penetration low-skill labors in routine intensive occupation will be replaced to low-skill unincorporated self-employed job // 
/*======================================================== *//*======================================================== *//*======================================================== */

// to check on this, we: //
// 1. regress diff_unse_share = RSH //
// 2. limit the sample to low-skill labor to compare the coefficient from the previous case //



// multinominal logit model to 
use unincorp_mlogit, clear

gen t = year == 1990
*femlogit ind7 nonc t, group(statefip)
mlogit ind7 nonc t sex age marst race citizen i.statefip [aw = lswt] if ind7 >= 2, base(2) // keep non-agriculture idnustry //

eststo mlogit

foreach o in 2 3 4 5 6 7{
       quietly margins, atmeans dydx(nonc) predict(outcome(`o')) post
       eststo, title(Outcome `o')
       estimates restore mlogit
   }

eststo drop mlogit  

esttab using Table_6.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(nonc) title(Table_1\label{tab1})  replace
eststo clear




cd "G:\Automation_SE\Data\IPUMS"

clear
use master_set

// summary statistics of non-college share in unincorporate se by industry //
global i unse_nonc_serve unse_nonc_cons unse_nonc_retail unse_nonc_manu unse_nonc_whosale unse_nonc_finance
eststo: estpost tabstat $i [aw = reg_wgt] if year == 1990 | year == 2000, statistics(mean sd count) columns(statistics)

esttab using Table_6.tex, main(mean) aux(sd) b(3) nostar nomtitle nonumber replace
est clear

// 2SLS //

// industries with low pc usage  //

eststo: ivregress 2sls diff_unse_serve (RSH_t = RSH_1990 RSH_2000) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_cons (RSH_t = RSH_1990 RSH_2000) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_retail (RSH_t = RSH_1990 RSH_2000) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// industries with high pc usage  //
eststo: ivregress 2sls diff_unse_manu (RSH_t = RSH_1990 RSH_2000) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_whosale (RSH_t = RSH_1990 RSH_2000) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_finance (RSH_t = RSH_1990 RSH_2000) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// conclusion: the replacement does not have a postive impact on unincop se overall, however, replacement effect can explain the strong increase in the in-person service industry //

esttab using Table_6.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(RSH_t _cons) title(Table_1\label{tab1})  replace
eststo clear














/*======================================================== *//*======================================================== *//*======================================================== */
// Table 7: Alternative hypothesis: positive relationship between unincorporated SE and pc usage is driven by the income effect //
// income effect: rising income at the top of the wage distribution, which stimulates demand for in-person services among wealthy households //
/*======================================================== *//*======================================================== *//*======================================================== */

// to check on this hypothesis, we: //


/*======================================================== *//*======================================================== *//*======================================================== */
// 1. use IV quantile method developed by CLP (2013, Economertica) to show the pc usage drastically increase the top quntile's wage, denoted as ln(delta P90) or ln(delta P80) //
/*======================================================== *//*======================================================== *//*======================================================== */

do "G:\Automation_SE\Program\CLP_quantile_wage.do"
// add a table cover each 10 percentile's result //
// conclusion: pc usage do have a significantly positive impact on the top quantile's wage //	
	
	
	
/*======================================================== *//*======================================================== *//*======================================================== */
// 2. regress ivregress diff_unse_share = pc_usshare + ln(delta P90), or regress diff_unse_share = ln(delta P90), to check whether a significant relationship can be identified //
/*======================================================== *//*======================================================== *//*======================================================== */


cd "G:\Automation_SE\Data\IPUMS"

clear
use master_set

set more off


// 95 percentile //
eststo: ivregress 2sls diff_unse_share d_p95_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share (pc_usshare = pc_indocc_25) d_p95_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// 90 percentile as robustness check //
eststo: ivregress 2sls diff_unse_share d_p90_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_share (pc_usshare = pc_indocc_25) d_p90_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

/*======================================================== *//*======================================================== *//*======================================================== */
// 3. regress diff_unse_share (limit sample to in-person service industry) = pc_usshare + ln(delta P90), to see whether the reltionship is stronger //
/*======================================================== *//*======================================================== *//*======================================================== */

// 95 percentile //
eststo: ivregress 2sls diff_unse_serve d_p95_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_serve (pc_usshare = pc_indocc_25) d_p95_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// 90 percentile as robustness check //
eststo: ivregress 2sls diff_unse_serve d_p90_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //
eststo: ivregress 2sls diff_unse_serve (pc_usshare = pc_indocc_25) d_p90_saln_hrwage i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // state and year fixed effects //

// conclusion: however, an increase in the top quantile's wage increase does not transfer to unincorporate se increase, not even in the in-person service industry //

esttab using Table_7.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(pc_usshare d_p95_saln_hrwage d_p90_saln_hrwage) title(Table_1\label{tab1})  replace
eststo clear












/*======================================================== *//*======================================================== *//*======================================================== */
// Table 8: Alternative hypothesis: fake pc share on delta unincorp entrep share -- subsample by decades: 1990- 2000, 2000- 2010 //
/*======================================================== *//*======================================================== *//*======================================================== */

// Table 8: fake pc adoption based on the 1980 industrial mix //


 // simple scatter plot to check the correlation between simulated pc usage and actual pc usage //

gr twoway (scatter diff00_pc_00sharefake diff00_pc_usshare) (lfit diff00_pc_00sharefake diff00_pc_00sharefake), xtitle("Simulated PC adoption, based on 1980 industrial mix") ytitle("PC adoption") legend(label(1 "PC adoption rate in CZ") label(2 "45 degree line") bmargin(small) rows(1) position(6)) scheme(538w)



// pc usage cause industrial mix change, towards more unincorporated SE favored industry //
// fake pc share fix the industrial compositional change, variation comes from within industry pc adoption rate //
// need to discuss why fake pc usage overestimate or underestimate the unincorporate se //


eststo: ivregress 2sls diff_unse_share pc_fake i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // 10 years different sample //
eststo: ivregress 2sls diff_unse_share pc_fake i.statefip [aw=reg_wgt] if year == 1990, cluster(czone) // 10 years different sample //
eststo: ivregress 2sls diff_unse_share pc_fake i.statefip [aw=reg_wgt] if year == 2000, cluster(czone) // 10 years different sample //

eststo: ivregress 2sls diff_unse_share (pc_fake = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone) // 20 years different sample //
eststo: ivregress 2sls diff_unse_share (pc_fake = pc_indocc_25) i.statefip [aw=reg_wgt] if year == 1990, cluster(czone) // 20 years different sample //
eststo: ivregress 2sls diff_unse_share (pc_fake = pc_indocc_25) i.statefip [aw=reg_wgt] if year == 2000, cluster(czone) // 20 years different sample //
// conclusion: the computerization-induced industrial compositional mix change is not the main driving force //
// the fake pc usage appears to be underestimate the growth of unse_share. Discuss why? //

esttab using Table_8.tex, r2 se(3) b(3)  label star(* 0.1 ** 0.05 *** 0.01)  ///
keep(pc_fake _cons) title(Table_1\label{tab1})  replace
eststo clear








