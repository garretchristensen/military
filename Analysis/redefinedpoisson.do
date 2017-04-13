*Main Poisson
*Forward Leads of Poisson

*BUNCH OF OTHER POISSONS TURNED OFF: RECRUITER CONTROLS, INTERACTIONS, ALL RECRUITS INCLUDING THE BAD DATA

cd $dir
cap log close
log using ./Logs/redefpoisson.log, replace

/*HAVE TO KEEP THIS FILE MANAGEMENT UP HERE, OUTSIDE THE APP/CON LOOP*/
*cap rm ./Output/redefPinteractions.txt
*cap rm ./Output/redefPinteractionsR.txt
*cap rm ./Output/redefPrec.txt
*cap rm ./Output/redefPrecR.txt
*cap rm ./Output/redefPrace.txt
 cap rm ./Output/redefPbasic.txt
 cap rm ./Output/redefPbasic.tex
 cap rm ./Output/redefPbasicR.txt
 cap rm ./Output/redefPbasicR.tex
 cap rm ./Output/forwardPbasic.tex
 cap rm ./Output/forwardPbasic.txt
 cap rm ./Output/forwardPbasicR.tex
 cap rm ./Output/forwardPbasicR.txt
 
 
clear all

set more off

foreach file in APP CON {   /*BEGIN HUGE LOOP OVER BOTH FILES*/

/*ONLY DO ALL THIS CONSTRUCTION ONCE*/

use ./Data/county`file'_raw.dta, clear

if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}

/*REPLACE DEATHS BY /100 SO THAT ESTIMATES ARE EASY TO READ/INTERPRET*/
replace F2monthcountydeath=F2monthcountydeath/100
replace F1monthcountydeath=F1monthcountydeath/100
foreach type in "" R{
	replace `type'monthcountydeath=`type'monthcountydeath/100
	replace L1`type'monthcountydeath=L1`type'monthcountydeath/100
	replace `type'outofcounty=`type'outofcounty/100
	replace L1`type'outofcounty=L1`type'outofcounty/100
}
replace F2outofcounty=F2outofcounty/100
replace F1outofcounty=F1outofcounty/100
*Label Vars
label var F2monthcountydeath "2-Lead In-County Deaths/100"
label var F1monthcountydeath "Lead In-County Deaths/100"
label var monthcountydeath "Current In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var F2outofcounty "2-Lead Out-of-County Deaths/100"
label var F1outofcounty "Lead Out-of-County Deaths/100"
label var outofcounty "Current Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
label var Rmonthcountydeath "Active Duty In-County Deaths/100"
label var L1Rmonthcountydeath "Lag Active Duty In-County Deaths/100"
label var Routofcounty "Active Duty Out-of-County Deaths/100"
label var L1Routofcounty "Lag Active Duty Out-of-County Deaths/100"

summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}


/*MAIN POISSON TABLE*/
foreach type in "" R { //DO WITH BOTH ACTIVE AND TOTAL DEATHS

*disp "HORSE RACE BTW DEATH TYPES%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
*xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate, fe exposure(avgcountypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate using ./Output/redefPbasic`type'.txt, ct(`file'`type'HORSERACE) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "BASIC%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath monthfe3-monthfe58, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/redefPbasic`type'.txt, lab tex keep(`type'monthcountydeath L1`type'monthcountydeath) ///
	ct(`header') addnote("Notes: Table shows Poisson regression of national active duty recruits on deaths.", ///
	"Fixed effects are included separately by county and month, and linear state trends, as indiciated,", ///
	Filename:redefPbasic`type'.tex) ///
	addtext(County FE, YES, Month FE, YES, State Trends, NO) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp ///
	countyunemp monthfe3-monthfe58, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/redefPbasic`type'.txt, ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(`type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trends, NO) lab tex

/*STATE TRENDS*/
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp ///
	countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/redefPbasic`type'.txt, ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(`type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trends, YES) lab tex

****************
	
disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
xtpoisson active F1monthcountydeath monthcountydeath L1monthcountydeath ///
	stateunemp countyunemp monthfe4-monthfe58, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/forwardPbasic`type'.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(F1monthcountydeath monthcountydeath L1monthcountydeath stateunemp countyunemp) ///
	addnote("Notes: Table shows Poisson regression of national active duty recruits on deaths", ///
	"As well as future 'lead' periods. Fixed effects are included separately by county and month", ///
	"and for each state-year, as indiciated, as well as a state-specific linear trend.", ///
	"The first columns show applicants and the last show contracts.", ///
	Filename:forwardPbasic`type'.txt) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

xtpoisson active F1monthcountydeath monthcountydeath L1monthcountydeath ///
	F1outofcounty outofcounty L1outofcounty ///
	stateunemp countyunemp monthfe4-monthfe58, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/forwardPbasic`type'.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(F1monthcountydeath monthcountydeath L1monthcountydeath ///
	F1outofcounty outofcounty L1outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

xtpoisson active F1monthcountydeath monthcountydeath L1monthcountydeath ///
	F1outofcounty outofcounty L1outofcounty ///
	stateunemp countyunemp monthfe5-monthfe58 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
outreg2 using ./Output/forwardPbasic`type'.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
	keep(F1monthcountydeath monthcountydeath L1monthcountydeath ///
	F1outofcounty outofcounty L1outofcounty stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
}/*END BOTH ACTIVE AND TOTAL DEATHS*/
}/*END HUGE LOOP OVER BOTH FILES*/



