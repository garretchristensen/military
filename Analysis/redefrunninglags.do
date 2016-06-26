/*THIS FILE RUNS DAVID'S OBVIOUS SUGGESTION TO RUN THE REGRESSIONS WITH RUNNING LAGS OF DEATHS
 i.e., EFFECT OF DEATHS IN THE LAST 2, 4, 6 MONTHS*/

 cd $dir
clear all
set more off

cap log close
log using ./Logs/runninglags.log, replace

cap rm ./Output/redefrunninglagsP.txt
cap rm ./Output/redefrunninglagsLN.txt
cap rm ./Output/redefrunninglagsP.tex
cap rm ./Output/redefrunninglagsLN.tex

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
 gen rl2`var'=(`var'+L1`var'+L2`var')/100
 label var rl2`var' "Cumulative 2 Lag"
 gen rl4`var'=(`var'+L2`var'+L3`var'+L4`var')/100
 label var rl4`var' "Cumulative 4 Lags"
 gen rl6`var'=(`var'+L2`var'+L3`var'+L4`var'+L5`var'+L6`var')/100
 label var rl6`var' "Cumulative 6 Lags"
 gen rl12`var'=(`var'+L2`var'+L3`var'+L4`var'+L5`var'+L6`var'+L7`var'+L8`var'+L9`var'+L10`var'+L11`var'+L12`var')/100
 label var rl12`var' "Cumulative 12 Lags"
}

/* (3) RUNNING CUMULATIVE LAGS*/


/*WEIGHTED*/
reghdfe LNactive rl2outofcounty rl2monthcountydeath rl2stateunemp rl2countyunemp [aweight=avgcountypop], ///
	cluster(fips) absorb(fips month)
outreg2 using ./Output/runninglagsLN.txt, ///
	lab tex ti(Cumulative Lags WEIGHTED) ct(`header') bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on cumulative ", ///
	"lagged deaths. Fixed effects are included separately by county and month as indiciated,", ///
	"The first five columns show applicants and the last five show contracts.", Filename:runninglagsLN.tex) ///
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

	stop
/*POISSON*/
xtpoisson active rl2outofcounty rl2monthcountydeath rl2stateunemp rl2countyunemp monthfe4-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl2outofcounty rl2monthcountydeath rl2stateunemp rl2countyunemp using ./Output/redefrunninglagsP.txt, ti(Cumulative Lags POISSON) addnote(redefrunninglagsP.txt EML) ct(`header') bdec(3) tdec(3) bracket se append
xtpoisson active rl4outofcounty rl4monthcountydeath rl4stateunemp rl4countyunemp monthfe6-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl4outofcounty rl4monthcountydeath rl4stateunemp rl4countyunemp using ./Output/redefrunninglagsP.txt, ct(`header') bdec(3) tdec(3) bracket se append
xtpoisson active rl6outofcounty rl6monthcountydeath rl6stateunemp rl6countyunemp monthfe8-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl6outofcounty rl6monthcountydeath rl6stateunemp rl6countyunemp using ./Output/redefrunninglagsP.txt, ct(`header') bdec(3) tdec(3) bracket se append
xtpoisson active rl12outofcounty rl12monthcountydeath rl12stateunemp rl12countyunemp monthfe14-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 outreg2 rl12outofcounty rl12monthcountydeath rl12stateunemp rl12countyunemp using ./Output/redefrunninglagsP.txt, ct(`header') bdec(3) tdec(3) bracket se append

} /*END THE HUGE LOOP OVER BOTH FILES*/

/* OLD GARBAGE
/*EVENT STUDY*/
bysort fips:egen deathevermax=max(monthcountydeath)
bysort fips:egen deathevertotal=sum(monthcountydeath)
tab deathevermax
gen deatheverdummy=1 if deathevermax>=1
replace deatheverdummy=0 if deatheverdummy==.
tab deatheverdummy
bysort fips: egen deathoutside45=sum(monthcountydeath) if year!=2004&year!=2005
bysort fips: egen deathoutside=max(deathoutside45)
tab deathoutside

sort fips month
gen death6after=0
gen death6before=0
forvalues Y=7/58 {
 quietly replace death6after=death6after+monthcountydeath[_n+`Y'] if fips[_n]==fips[_n+`Y']
 quietly replace death6before=death6before+monthcountydeath[_n-`Y'] if fips[_n]==fips[_n-`Y']
}
gen death12after=0
gen death12before=0
forvalues Y=13/58 {
 quietly replace death12after=death12after+monthcountydeath[_n+`Y'] if fips[_n]==fips[_n+`Y']
 quietly replace death12before=death12before+monthcountydeath[_n-`Y'] if fips[_n]==fips[_n-`Y']
}

/*ABOVE FOR R DEATH*/
gen Rdeath6after=0
gen Rdeath6before=0
forvalues Y=7/58 {
 quietly replace Rdeath6after=Rdeath6after+Rmonthcountydeath[_n+`Y'] if fips[_n]==fips[_n+`Y']
 quietly replace Rdeath6before=Rdeath6before+Rmonthcountydeath[_n-`Y'] if fips[_n]==fips[_n-`Y']
}
gen Rdeath12after=0
gen Rdeath12before=0
forvalues Y=13/58 {
 quietly replace Rdeath12after=Rdeath12after+Rmonthcountydeath[_n+`Y'] if fips[_n]==fips[_n+`Y']
 quietly replace Rdeath12before=Rdeath12before+Rmonthcountydeath[_n-`Y'] if fips[_n]==fips[_n-`Y']
}

reghdfe active monthcountydeath L1monthcountydeath , absorb(fips month)
 outreg2 monthcountydeath L1monthcountydeath using ./Output/eventstudy.txt, ct(Basic) bdec(3) tdec(3) bracket se replace
reghdfe active Rmonthcountydeath L1Rmonthcountydeath , absorb(fips month)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath using ./Output/eventstudy.txt, ct(BasicR) bdec(3) tdec(3) bracket se append
 
reghdfe active monthcountydeath L1monthcountydeath-L6monthcountydeath F1monthcountydeath-F6monthcountydeath monthfe8-monthfe52 death6before death6after, absorb(fips month)
 outreg2 monthcountydeath L1monthcountydeath-L6monthcountydeath F1monthcountydeath-F6monthcountydeath death6before death6after using ./Output/eventstudy.txt, ct(6LFBins) bdec(3) tdec(3) bracket se append
reghdfe active monthcountydeath L1monthcountydeath-L12monthcountydeath F1monthcountydeath-F12monthcountydeath monthfe14-monthfe44 death12before death12after, absorb(fips month)
 outreg2 monthcountydeath L1monthcountydeath-L12monthcountydeath F1monthcountydeath-F12monthcountydeath death12before death12after using ./Output/eventstudy.txt, ct(12LFBins) bdec(3) tdec(3) bracket se append
reghdfe active Rmonthcountydeath L1Rmonthcountydeath-L6Rmonthcountydeath F1Rmonthcountydeath-F6Rmonthcountydeath monthfe8-monthfe52 Rdeath6before Rdeath6after, absorb(fips month)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath-L6Rmonthcountydeath F1Rmonthcountydeath-F6Rmonthcountydeath Rdeath6before Rdeath6after using ./Output/eventstudy.txt, ct(6RLFBins) bdec(3) tdec(3) bracket se append
reghdfe active Rmonthcountydeath L1Rmonthcountydeath-L12Rmonthcountydeath F1Rmonthcountydeath-F12Rmonthcountydeath monthfe14-monthfe44 Rdeath12before Rdeath12after, absorb(fips month)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath-L12Rmonthcountydeath F1Rmonthcountydeath-F12Rmonthcountydeath Rdeath12before Rdeath12after using ./Output/eventstudy.txt, ct(12RLFBins) bdec(3) tdec(3) bracket se append
/*WEIGHTED*/
reghdfe active monthcountydeath L1monthcountydeath-L6monthcountydeath F1monthcountydeath-F6monthcountydeath monthfe8-monthfe52 death6before death6after [aweight=avgcountypop], absorb(fips month)
 outreg2 monthcountydeath L1monthcountydeath-L6monthcountydeath F1monthcountydeath-F6monthcountydeath death6before death6after using ./Output/eventstudy.txt, ct(6LFBinsW) bdec(3) tdec(3) bracket se append
reghdfe active monthcountydeath L1monthcountydeath-L12monthcountydeath F1monthcountydeath-F12monthcountydeath monthfe14-monthfe44 death12before death12after [aweight=avgcountypop], absorb(fips month)
 outreg2 monthcountydeath L1monthcountydeath-L12monthcountydeath F1monthcountydeath-F12monthcountydeath death12before death12after using ./Output/eventstudy.txt, ct(12LFBinsW) bdec(3) tdec(3) bracket se append
reghdfe active Rmonthcountydeath L1Rmonthcountydeath-L6Rmonthcountydeath F1Rmonthcountydeath-F6Rmonthcountydeath monthfe8-monthfe52 Rdeath6before Rdeath6after [aweight=avgcountypop], absorb(fips month)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath-L6Rmonthcountydeath F1Rmonthcountydeath-F6Rmonthcountydeath Rdeath6before Rdeath6after using ./Output/eventstudy.txt, ct(6RLFBinsW) bdec(3) tdec(3) bracket se append
reghdfe active Rmonthcountydeath L1Rmonthcountydeath-L12Rmonthcountydeath F1Rmonthcountydeath-F12Rmonthcountydeath monthfe14-monthfe44 Rdeath12before Rdeath12after [aweight=avgcountypop], absorb(fips month)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath-L12Rmonthcountydeath F1Rmonthcountydeath-F12Rmonthcountydeath Rdeath12before Rdeath12after using ./Output/eventstudy.txt, ct(12RLFBinsW) bdec(3) tdec(3) bracket se append

/*DO WITH TREND AND INTERACTED*/
reghdfe active monthcountydeath L1monthcountydeath-L6monthcountydeath F1monthcountydeath-F6monthcountydeath statetrend2-statetrend51 monthfe28-monthfe52 death6before death6after if year==2004|year==2005 [aweight=avgcountypop], absorb(fips month)
/*PANEL OF DUMMIES*/
forvalues x=1/57 {
 replace L`x'monthcountydeath=1 if L`x'monthcountydeath>1
 replace F`x'monthcountydeath=1 if F`x'monthcountydeath>1
}
reghdfe active monthcountydeath L1monthcountydeath-L6monthcountydeath F1monthcountydeath-F6monthcountydeath statetrend2-statetrend51 monthfe28-monthfe52 death6before death6after if year==2004|year==2005 [aweight=avgcountypop], absorb(fips month)

/*BALANCED PANEL OF DUMMIES--ASSUME MISSING LAGS=0, NOT MISSING.*/
foreach x of numlist 1/57{
 replace L`x'monthcountydeath=0 if L`x'monthcountydeath==.
 replace F`x'monthcountydeath=0 if F`x'monthcountydeath==. 
} 
*/
