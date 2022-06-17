




/*======================================================== */

//         ----------- PART 1 -----------------            //

/*======================================================== */

cd "G:\Automation_SE\Data\IPUMS"

use crime_estimation, clear

keep year czone  crime_report pc_indocc_25  violent_report  crime_report tot_off d_mean_crime_report *_crime_report 
merge 1:1 year czone using master_set, nogen 

tempfile d_mean_saln_hrwage  reg_saln_hrwage

qui ivregress 2sls d_mean_saln_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone)
qui parmest,fast ids(d_mean_saln_hrwage) saving(`d_mean_saln_hrwage')

//Appending
use `d_mean_saln_hrwage', clear
keep if parm=="pc_usshare"
save ADH_regression_results, replace


/*======================================================== */

//         ----------- PART 2 -----------------            //

/*======================================================== */

cd "G:\Automation_SE\Data\IPUMS"

use crime_estimation, clear

keep year czone  crime_report pc_indocc_25  violent_report  crime_report tot_off d_mean_crime_report *_crime_report 
merge 1:1 year czone using master_set, nogen 

**Loop over the suffixes (sample specifications)**
	preserve
	qui ivregress 2sls d_p5_saln_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone)
	qui parmest,fast idn(5) saving(`reg_saln_hrwage')
	restore


//Then all other quantiles, loop through and append regression results
forvalues q=10 15 to 95 {

	tempfile tfall
	
	**All workers first**
	preserve
	qui ivregress 2sls d_p`q'_saln_hrwage (pc_usshare = pc_indocc_25) i.statefip i.year [aw=reg_wgt] if year >= 1990, cluster(czone)
	qui parmest,fast idn(`q') saving(`tfall', replace)
	restore
	preserve
	drop _all
	append using `reg_saln_hrwage' `tfall'
	qui save `reg_saln_hrwage', replace
	restore
	
	}


/*======================================================== */

//         ----------- PART 3 -----------------            //

/*======================================================== */
  
	use `reg_saln_hrwage', clear
	qui keep if parm=="pc_usshare"
	qui keep idnum estimate min95 max95 stderr
	qui save `reg_saln_hrwage', replace

	use ADH_regression_results, clear
	keep parm idstr estimate max95 min95
	keep if idstr=="d_mean_saln_hrwage"
	reshape wide estimate max95 min95, i(parm) j(idstr) string
	drop parm
	rename estimated_mean_saln_hrwage original_estimate
	rename max95d_mean_saln_hrwage max95_original
	rename min95d_mean_saln_hrwage min95_original

	expand 19

	merge using `reg_saln_hrwage'
	assert _merge==3
	
	drop _merge
	
	replace idnum=idnum/100 // Quantiles
	
	//Plotting
	twoway (line original_estimate idnum, pstyle(p3) lw(medthick)) (rline max95_original min95_original idnum,pstyle(p4) lpattern(shortdash) lw(medthick)) (connected estimate idnum, pstyle(p1) lw(medthick)) (rline max95 min95 idnum, lpattern(dash) pstyle(p2) lw(medthick)), xtitle("Quantile") xlabel(0.1(0.1)0.90, format(%9.1f)) ylabel(-1(.25)1,gmax gmin) yscale(range(-1 1.25)) name(`class',replace) saving(quantileplot_`class', replace) legend(label(3 "Point Estimate") label(4 "95% Confidence Interval") label(1 "Avg Estimate") label(2 "Avg 95% Confidence Interval") order(3 4 1 2) pos(6) col(2)) scheme(538w) 
	
	graph export color_fig.png, replace width(2400)
	graph export color_fig.eps, replace
	graph export color_fig.pdf, replace

	* black and white versions
	twoway (line original_estimate idnum, pstyle(p3)) (rline max95_original min95_original idnum,pstyle(p2) lpattern(shortdash)) ///
		(connected estimate idnum, pstyle(p1)) (rline max95 min95 idnum, lpattern(dash) pstyle(p4)) ///
		, graphregion(fcolor(white)) scheme(s2mono) xtitle("Quantile") xlabel(0.1(0.1)0.90, format(%9.1f)) ylabel(-1(.25)1.25, gmin gmax)  yscale(range(-1 1)) name(`class',replace) ///
		legend(label(3 "Point Estimate") label(4 "95% Confidence Interval") label(1 "Avg Estimate") label(2 "Avg 95% Confidence Interval") order(3 4 1 2) pos(6) ) scheme(538w)
	graph export blackwhite_fig.png, replace width(2400)
	graph export blackwhite_fig.eps, replace
	graph export blackwhite_fig.pdf, replace
	
	save CLP_regresults, replace	
