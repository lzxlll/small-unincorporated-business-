






cd "G:\Automation_SE\Data\IPUMS"



// append 1980 and 2000 data to plot delta entrep share and pc usage //


clear
use 1990_pcusage_percentile
append using 2010_pcusage_percentile

sort percent year
bys percent: gen d_unseind_share =  (unseind_share[_n] - unseind_share[_n-1])

keep if year == 2010
keep percent pc_usage d_unseind_share 

* Get plotting points

lowess d_unseind_share percent, gen(pdsh0) bwidth(`bw') nograph
label var pdsh0 "Unincorp Entrep change"
replace pdsh0 = pdsh0 * 100

local subtit = ""
* Plot observed change and counterfactual change at 1980 service occupation employment
local bw = .75 // set in Autor: .75 //
local y1 = 1990
local y2 = 2010
local span1= -0.03
local span2= 0.05
local int = 0.01
local tick=0.05
local rewtyr=1980


sort perc
tw scatter pdsh0 percent, connect(l) msymbol(o d) msize(small) ylabel(`span1'(`int')`span2') ymtick(`span1'(`tick')`span2') ytitle("100 x Change in Unincorp Self-employment Share", size(medsmall)) xtitle("Skill Percentile (Ranked by Industrial PC Adoption)", size(medsmall)) subtitle("`subtit'", size(medsmall)) title("Smoothed Changes in Unincorp Entrep by PC Usage Percentile `y1'-`y2'", size(medium)) scheme(538w)


