/**********************
This do-file does logs on logs (in levels) regressions.

LAST EDITED: ADF 1/18/2016
***********************/

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 
set maxvar 32000
set matsize 11000



use "/home/research/masslayoff/rawdata/cw_cty_czone", clear

rename cty_fips fips 
sort fips 
tempfile czone
save `czone', replace


use $datdir/CTY_ED_LAYOFF, clear
do $prodir/preamble_cty.do
 
 drop _merge
merge m:1 fips using `czone'
	tab _merge

*Basic Regressions
#delimit;

local clustervar czone  ;
local type cty  ;
local weightvar total_pop ;

local rhscovar log_`type'layoff;


global mainoutcomes tef_tot ffe_tot aw_tot aw_aa aw_1t4 aw_lt1y ;


qui tab fips, gen(fipsfe);




	
drop if year==1995;
xtset fips year;

gen l1_log_ctylayoff=l.log_ctylayoff;
gen l2_log_ctylayoff=l2.log_ctylayoff;
gen l3_log_ctylayoff=l3.log_ctylayoff;
	label var l1_log_ctylayoff "Layoffs, t-1";
	label var l2_log_ctylayoff "Layoffs, t-2";
	label var l3_log_ctylayoff "Layoffs, t-3";
*********************************************;
*Pre and Post Recession (2007) variables;
**********************************************;

gen post_rece=year>=2007;

gen layoff_postrece_t1=L.log_ctylayoff*post_rece;
gen layoff_postrece_t2=L2.log_ctylayoff*post_rece;
gen layoff_postrece_t3=L3.log_ctylayoff*post_rece; 

				
local rhs_postvars "layoff_postrece_t1 layoff_postrece_t2 layoff_postrece_t3";
	label var layoff_postrece_t1 "Layoffs, t-1xPost-2007";
	label var layoff_postrece_t2 "Layoffs, t-2xPost-2007";
	label var layoff_postrece_t3 "Layoffs, t-3xPost-2007";
	
	local rhscovar log_`type'layoff;
local adjrhscovar log_adjctylayoff;

*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
eststo clear;
eststo clear;
foreach sec in 47 69{;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		eststo spec`sec'`outcome': areg ln_`outcome'_`sec' l1_log_ctylayoff l2_log_ctylayoff l3_log_ctylayoff `rhs_postvars' ctytre*  yearfe*  [weight=`weightvar'],   absorb(fips) cluster(`clustervar');
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				
				esttab * using "${tabdir}/lev/reg_regprepost_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_ctylayoff l2_log_ctylayoff l3_log_ctylayoff  `rhs_postvars'  )
				stat(ysu N ar2, labels("Y-Mean" "Observations" "Adj. R-sq") );
				eststo clear;
				};


******************************************************************;
*Table with Main Spec, College-Program Variables;
***************************************************************;

eststo clear;
local rhscovar log_`type'layoff;
			foreach sec in 47 69{;
			foreach outcome in ln_aw_tot ln_aw_aa ln_aw_lt1y ln_aw_1t4{ ;
			eststo clear;
			foreach field in  CTE IT CON  HEA { ;

				eststo spec`sec'`outcome'`field': areg `outcome'_`field'_`sec' l1_log_ctylayoff l2_log_ctylayoff l3_log_ctylayoff  `rhs_postvars'     yearfe* ctytrend* [weight=`weightvar'],   absorb(fips) cluster(`clustervar');
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					};

				esttab  using "${tabdir}/lev/reg_prepost_f`outcome'_`type'.tex", replace se  star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_ctylayoff l2_log_ctylayoff l3_log_ctylayoff  `rhs_postvars'  );
				eststo clear;
		};		
		};

