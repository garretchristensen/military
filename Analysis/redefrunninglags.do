/*THIS FILE RUNS DAVID'S OBVIOUS SUGGESTION TO RUN THE REGRESSIONS WITH RUNNING LAGS OF DEATHS
 i.e., EFFECT OF DEATHS IN THE LAST 2, 4, 6 MONTHS*/

 cd $dir
clear all
set more off

cap log close
log using ./Logs/runninglags.log, replace

cap rm ./Output/runninglagsP.txt
cap rm ./Output/runninglagsLN.txt
cap rm ./Output/runninglagsP.tex
cap rm ./Output/runninglagsLN.tex

foreach file in APP CON { /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Data/county`file'_raw.dta, clear
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}
/* (1) REDO+EXTEND LAGS
drop L*monthcountydeath L*outofcounty L*countyunemp L*stateunemp L*monthstatemort L*monthcountymort L*outofstate
drop F1monthcountydeath F2monthcountydeath F1Rmonthcountydeath F2Rmonthcountydeath F*outofcounty F*outofstate F*countyunemp F*stateunemp F*monthstatemort F*monthcountymort
sort fips month
foreach var in monthcountydeath outofcounty countyunemp stateunemp monthstatemort monthcountymort Rmonthcountydeath Routofcounty Routofstate {
 forvalues X=1/12 {
   quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
 }
 forvalues X=1/12 {
   quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
 } 
}
*/

/* (2) CREATE RUNNING LAGS */
foreach var in monthcountydeath outofcounty countyunemp stateunemp {
 local LABELPART : variable label `var'
 gen rl2`var'=(`var'+L1`var'+L2`var')/100
 label var rl2`var' "Cum. 2 Lags `LABELPART'"
 gen rl4`var'=(`var'+L2`var'+L3`var'+L4`var')/100
 label var rl4`var' "Cum. 4 Lags  `LABELPART'"
 gen rl6`var'=(`var'+L2`var'+L3`var'+L4`var'+L5`var'+L6`var')/100
 label var rl6`var' "Cum. 6 Lags  `LABELPART'"
 gen rl12`var'=(`var'+L2`var'+L3`var'+L4`var'+L5`var'+L6`var'+L7`var'+L8`var'+L9`var'+L10`var'+L11`var'+L12`var')/100
 label var rl12`var' "Cum. 12 Lags `LABELPART'"
}

/* (3) RUNNING CUMULATIVE LAGS*/


/*WEIGHTED*/
reghdfe LNactive rl2outofcounty rl2monthcountydeath rl2stateunemp rl2countyunemp [aweight=avgcountypop], ///
	cluster(fips) absorb(fips month)
outreg2 using ./Output/runninglagsLN.txt, ///
	lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on cumulative ", ///
	"lagged deaths. Fixed effects are included separately by county and month as indiciated,", ///
	"The first four columns show applicants and the last four show contracts.", Filename:runninglagsLN.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
reghdfe LNactive rl4outofcounty rl4monthcountydeath rl4stateunemp rl4countyunemp [aweight=avgcountypop], ///
	cluster(fips) absorb(fips month)
outreg2 using ./Output/runninglagsLN.txt, ///
	lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
reghdfe LNactive rl6outofcounty rl6monthcountydeath rl6stateunemp rl6countyunemp [aweight=avgcountypop], ///
	cluster(fips) absorb(fips month)
outreg2 using ./Output/runninglagsLN.txt, ///
	lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
reghdfe LNactive rl12outofcounty rl12monthcountydeath rl12stateunemp rl12countyunemp [aweight=avgcountypop], ///
	cluster(fips) absorb(fips month)
outreg2 using ./Output/runninglagsLN.txt, ///
	lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

/*POISSON*/
xtpoisson active rl2outofcounty rl2monthcountydeath rl2stateunemp rl2countyunemp monthfe4-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl2outofcounty rl2monthcountydeath rl2stateunemp rl2countyunemp using ./Output/runninglagsP.txt, ti(Cumulative Lags POISSON) addnote(runninglagsP.txt EML) ct(`header') bdec(3) tdec(3) bracket se append
xtpoisson active rl4outofcounty rl4monthcountydeath rl4stateunemp rl4countyunemp monthfe6-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl4outofcounty rl4monthcountydeath rl4stateunemp rl4countyunemp using ./Output/runninglagsP.txt, ct(`header') bdec(3) tdec(3) bracket se append
xtpoisson active rl6outofcounty rl6monthcountydeath rl6stateunemp rl6countyunemp monthfe8-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl6outofcounty rl6monthcountydeath rl6stateunemp rl6countyunemp using ./Output/runninglagsP.txt, ct(`header') bdec(3) tdec(3) bracket se append
xtpoisson active rl12outofcounty rl12monthcountydeath rl12stateunemp rl12countyunemp monthfe14-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl12outofcounty rl12monthcountydeath rl12stateunemp rl12countyunemp using ./Output/runninglagsP.txt, ct(`header') bdec(3) tdec(3) bracket se append

} /*END THE HUGE LOOP OVER BOTH FILES*/


