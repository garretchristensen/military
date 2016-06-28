*This file does the main regressions, linear and Poisson, with 1990-2006 data.
*6/26/2016
cd $dir
cap log close
log using ./Logs/PandLN90.smcl, replace

/*HAVE TO KEEP THIS FILE MANAGEMENT UP HERE, OUTSIDE THE APP/CON LOOP*/

*cap rm ./Output/redefPbasic90.txt
*cap rm ./Output/redefPbasic90.tex
cap rm ./Output/LNLinear90.tex
cap rm ./Output/LNLinear90.txt
 
clear all
set more off

foreach file in APP90 CON90 {   /*BEGIN HUGE LOOP OVER BOTH FILES*/
*NOTE THAT YOU SHOULD JUST BE ABLE TO CHANGE THE ABOVE FOR ALMOST *ANY* FILE
*WITH THE EXCEPTION OF THE MONTHFE199 IN POISSON REGRESSIONS
*TO GET THE 1990-2006 RESULTS.
*YOU DON'T EVEN HAVE TO CHANGE TABLE NAMES (THOUGH IT WOULD MAKE EXISTING TABLES TWICE AS WIDE)
use ./Data/county`file'_raw.dta, clear
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command

//*REPLACE DEATHS BY /100 SO THAT ESTIMATES ARE EASY TO READ/INTERPRET*/
replace monthcountydeath=monthcountydeath/100
replace L1monthcountydeath=L1monthcountydeath/100
replace outofcounty=outofcounty/100
replace L1outofcounty=L1outofcounty/100
label var monthcountydeath "In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}

if "`file'"=="APP90"{
	local header="Applicants"
}
else{
	local header="Contracts"
}


*MAIN LINEAR REGRESSIONS*
/*NO STATE*/
reghdfe LNactive monthcountydeath L1monthcountydeath [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips)
display "`file'"
if "`file'"=="APP90"{
display "it worked"
}

outreg2 using ./Output/LNLinear90.tex, tex label ///
	ti(1990-2006 Log County Applicants vs Deaths and Unemployment) ///
	ct(`header') bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first three columns show applicants and the last three show contracts.", Filename:LNLinear90.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

/*STATE AND UNEMP*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp [aweight=avgcountypop], vce(cluster fips) absorb(fips month)
outreg2 using ./Output/LNLinear90.tex, tex label ct(`header') bdec(3) tdec(3) bracket ///
	se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

/*STATE YEAR INTERACTED FE*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/LNLinear90.tex, tex label ///
	ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)

	

*WARNING: THE 199 MONTHLY FIXED EFFECTS TAKE FOREVER TO ESTIMATE	
/*MAIN POISSON TABLE*/
disp "BASIC%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active monthcountydeath L1monthcountydeath monthfe3-monthfe199, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/redefPbasic90.txt, lab tex keep(monthcountydeath L1monthcountydeath) ///
	ct(`header') addnote("Notes: Table shows Poisson regression estimates of national active duty recruits on deaths.", ///
	"Fixed effects are included separately by county and month, and linear state trends, as indiciated,", ///
	"The first four columns show applicants and the last three show contracts.", Filename:redefPbasic.tex) ///
	addtext(County FE, YES, Month FE, YES, State Trends, NO) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp ///
	countyunemp monthfe3-monthfe199, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/redefPbasic90.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trends, NO)

/*STATE TRENDS*/
xtpoisson active monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp ///
	countyunemp monthfe3-monthfe199 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/redefPbasic90.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trends, YES)


} /*END OF APP AND CON*/


