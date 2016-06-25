clear all
set more off
cd $dir

set maxvar 32767
set matsize 11000
cap log close
log using ./Logs/table1bycounty.smcl, replace

/*****************************************************/
/* JUST TEST HOW WELL THEY FIT TO A BINOMIAL DISTRIBUTION*/
/****************************************************/
/*ACTIVE DEATHS ACTIVE APPS*/
use ./Data/county_raw.dta, clear
gen WorstP=.
gen Rmonthcounty=ARmonthcounty+FRmonthcounty+NRmonthcounty+MRmonthcounty
bysort fips: egen countyactiveapps=sum(Rmonthcounty)
drop if countyactiveapps==0
bysort fips: egen activedeaths=sum(Rmonthcountydeath)
bysort fips: egen deaths=sum(monthcountydeath)
duplicates drop fips, force
forvalues X=1/3130{
quietly bitesti countyactiveapps[`X'] activedeaths[`X'] .0027603, detail
quietly replace WorstP=r(p) in `X'
}
summ WorstP
label var WorstP "County P-Value"
histogram WorstP if WorstP!=1, width(.01) frequency ti(Active Duty Deaths and Applicants) //addl
graph save ./Output/hist_binomial.gph, replace

count if WorstP<(.05/3129) //was 9 last time I checked
if r(N)!=9{
 throw a hissy fit
}
disp "this is how many counties couldn't come from the average dist"
*********************************************************/
/** ALL COUNTIES ARE CLEARLY NOT THE SAME. JUST SHOW THE DISPERSION OF THE HAZARD RATE ISN'T CRAZY*/
/* DO FOR ALL RECS & DEATHS AND ACTIVE ONLY*/
/**********************************************************/

/*ACTIVE ACTIVE APPS*/
gen hazard_aaa=activedeaths/countyactiveapps
summ hazard_aaa
disp "Active Deaths/Active Apps " r(sd)/r(mean)
*summ hazard_aaa [aweight=percentpop]
*disp "Active Deaths/Active Apps WEIGHTED " r(sd)/r(mean)
label var hazard_aaa "Active Deaths/Active Applicants"
histogram hazard_aaa, addl frequency //title("Hazard Rate by County")
graph save ./Output/hist_county_aaa.gph, replace
/*TOTAL ACTIVE APPS*/
gen hazard_taa=deaths/countyactiveapps
summ hazard_taa
disp "Total Deaths/Active Apps "r(sd)/r(mean)
*summ hazard_taa [aweight=percentpop]
*disp "Total Deaths/Active Apps WEIGHTED "r(sd)/r(mean)
label var hazard_taa "Total Deaths/Active Applicants"
histogram hazard_taa, frequency addl //title("Hazard Rate by County")
graph save ./Output/hist_county_taa.gph, replace

/*****************************************************/
/* PAT'S THING. JUST TEST HOW WELL THEY FIT TO A BINOMIAL DISTRIBUTION*/
/****************************************************/
/*ACTIVE DEATHS ACTIVE CONS*/
use ./Data/countyCON_raw.dta, clear
gen WorstP=.
gen Rmonthcounty=ARmonthcounty+FRmonthcounty+NRmonthcounty+MRmonthcounty
bysort fips: egen countyactivecons=sum(Rmonthcounty)
drop if countyactivecons==0
bysort fips: egen deaths=sum(monthcountydeath)
bysort fips: egen activedeaths=sum(Rmonthcountydeath)
duplicates drop fips, force
egen sumactivecons=sum(countyactivecons)
egen sumactivedeaths=sum(activedeaths)
forvalues X=1/3129{
quietly bitesti countyactivecons[`X'] activedeaths[`X'] sumactivedeaths/sumactivecons, detail
quietly replace WorstP=r(p) in `X'
}
summ WorstP
label var WorstP "County P-Value"
histogram WorstP if WorstP!=1, width(.01) frequency ti(Active-Duty Deaths and Contracts) //addl
graph save ./Output/hist_binomialcon.gph, replace

count if WorstP<(.05/3129) //was 0 last time I checked
if r(N)!=0{
 throw a hissy fit
}
disp "this is how many counties couldn't come from the average dist"

******************************************
*COMBINE 2 STATE and 2 COUNTY GRAPHS INTO ONE
graph combine ./Output/hist_state_binomial.gph ./Output/hist_state_binomialcon.gph ///
	./Output/hist_binomial.gph ./Output/hist_binomialcon.gph, ///
	saving(./Output/hist_binomial_combined.gph, replace) title("State and County Binomial Tests of Death Hazard Rates") ///
	note("Graph displays the p-values that the observed state and county death rate could come from the overall" ///
	"average national death rate. The majority (70+%) of county p-values are ~=1 and are excluded from the graph.")
graph export ./Output/hist_binomial_combined.png, replace

*********************************************************/
/** ALL COUNTIES ARE CLEARLY NOT THE SAME. JUST SHOW THE DISPERSION OF THE HAZARD RATE ISN'T CRAZY*/
/* DO FOR ALL RECS & DEATHS AND ACTIVE ONLY*/
/**********************************************************/
/*ACTIVE ACTIVE CON*/
gen hazard_aac=activedeaths/countyactivecons
summ hazard_aac
disp "Active Deaths/Active Cons "r(sd)/r(mean)
*summ hazard_aac [aweight=percentpop]
*disp "Active Deaths/Active Cons WEIGHTED "r(sd)/r(mean)
label var hazard_aac "Active Deaths/Active Contracts"
histogram hazard_aac, addl frequency
graph save ./Output/hist_county_aac.gph, replace
/*TOTAL ACTIVE CON*/
gen hazard_tac=deaths/countyactivecons
summ hazard_tac
disp "Total Deaths/Active Cons "r(sd)/r(mean)
*summ hazard_tac [aweight=percentpop]
disp "Total Deaths/Active Cons WEIGHTED "r(sd)/r(mean)
label var hazard_tac "Total Deaths/Active Contracts"
histogram hazard_tac, addl frequency
graph save ./Output/hist_county_tac.gph, replace

**COMBINE ALL FOUR COUNTY GRAPHS
graph combine ./Output/hist_county_aaa.gph ./Output/hist_county_taa.gph ./Output/hist_county_aac.gph ///
	./Output/hist_county_tac.gph, title("Death Hazard Rate by County") saving(./Output/hist_county_combined.gph, replace) 
graph export ./Output/hist_county_combined.png, replace
