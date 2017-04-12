*2015.02.17 Just do negative binomial regression even though it allows constant variables to get coefficients.

cd C:/Users/garret/Documents/Research/Military/
cap log close
log using ./Logs/redefpoisson.log, replace

/*HAVE TO KEEP THIS FILE MANAGEMENT UP HERE, OUTSIDE THE APP/CON LOOP*/
 cap rm ./Output/negbinom.txt
 cap rm ./Output/negbinom.tex
 
clear all
set more off

foreach file in APP CON {   /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Data/county`file'_raw.dta, clear

if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}

foreach lag in  "" L1 {
	replace `lag'monthcountydeath=`lag'monthcountydeath/100
	replace `lag'outofcounty=`lag'outofcounty/100
}

label var monthcountydeath "Current In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Current Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"

summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}

/*MAIN NBREG TABLE*/
disp "BASIC%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtnbreg active monthcountydeath L1monthcountydeath monthfe3-monthfe58, fe exposure(avgcountypop)
outreg2 using ./Output/negbinom.txt, lab tex keep(monthcountydeath L1monthcountydeath) ///
	ct(`header') addnote("Notes: Table shows Negative Binomial regression of national active duty recruits on deaths.", ///
	"Fixed effects are included separately by county and month, and linear state trends, as indicated,", ///
	"The first four columns show applicants and the last three show contracts.", Filename:negbinom.tex) ///
	ti(Negative Binomial Regressions of Recruits vs Deaths and Unemployment) ///
	addtext(County FE, YES, Month FE, YES, State Trends, NO) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtnbreg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp ///
	countyunemp monthfe3-monthfe58, fe exposure(avgcountypop) 
outreg2 using ./Output/negbinom.txt, ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trends, NO) lab tex

/*STATE TRENDS*/
xtnbreg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp ///
	countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(avgcountypop) 
outreg2 using ./Output/negbinom.txt, ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trends, YES) lab tex


}/*END HUGE LOOP OVER BOTH FILES*/
