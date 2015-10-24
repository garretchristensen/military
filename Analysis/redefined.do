/*******************************************RUN LINEAR COUNTY REGRESSIONS!***********************************************/
*2015/8/12 This file runs the main set of log-linear regressions, which are presented as the main set of results
*2015/10/15 remaking this as the main set of linear regs. level linear appear in appx, log linear are main set.

clear all
set more off
*set mem 5g
*set maxvar 32767
*set matsize 11000
cd $dir
cap log close
log using ./Logs/redefined.txt, replace

//since outreg is inside loop, they're all append and must be rm'd manually
cap rm ./Output/LinearW.tex
cap rm ./Output/LinearW.txt
cap rm ./Output/LNLinearW.tex
cap rm ./Output/LNLinearW.txt

cap rm ./Output/redefelastW.txt
cap rm ./Output/redefRW.txt
cap rm ./Output/redefelastRW.txt


foreach file in APP /*CON*/{ /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Data/county`file'_raw.dta, clear
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
*drop ID-McareB03
*drop *Q*

/******WEIGHTED LINEAR REGRESSIONS*******/
/* Level regressions. Appear in Appendix*/
/*
/*NO STATE*/
reghdfe active monthcountydeath L1monthcountydeath [aweight=avgcountypop], absorb(fips month) ///
	vce(cluster fips)
outreg2 monthcountydeath L1monthcountydeath using ./Output/LinearW.tex, tex ///
	ti(County Applicants vs Deaths and Unemployment) addnote(LinearW.tex) ///
	ct(Basic) bdec(3) tdec(3) bracket se append

/*STATE AND UNEMP*/
reghdfe active monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp [aweight=avgcountypop], vce(cluster fips) absorb(fips month)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp ///
	using ./Output/LinearW.tex, tex ct(w/State) bdec(3) tdec(3) bracket se append

/*STATE TREND*/
reghdfe active monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp statetrend1-statetrend51[aweight=avgcountypop], vce (cluster fips) ///
	absorb(fips month)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp ///
	countyunemp using ./Output/LinearW.tex, tex ct(w/Statetrend) bdec(3) tdec(3) ///
	bracket se append keep(*month* *county* stateunemp)

/*STATE YEAR INTERACTED FE*/
reghdfe active monthcountydeath L1monthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/LinearW.tex, tex ti(County Applicants vs Deaths and Unemployment) ///
	ct(w/Stateyear) bdec(3) tdec(3) bracket se append
*/
 
/*WEIGHTED FUTURE LEADS*/
*10/20/15 This doesn't appear in the paper, I don't think.
*disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
*areg active F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath  stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips) vce(robust)
*outreg2  F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath  stateunemp countyunemp using ./Output/forwardbasicW.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote(forwardbasicW.txt)

*areg active  F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath  F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty  stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips)  vce(robust)
*outreg2  F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath ///
*	L2monthcountydeath  F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty ///
*	stateunemp countyunemp using ./Output/forwardbasicW.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))


/*******************************************************************/
/*REPEAT ABOVE WITH ACTIVE DEATHS ONLY*/
*Do the same as above (level-level weighted linear regressions) 
*But only with active deaths: Rmonthcountydeath L1Rmonthcountydeath

/*******************************************************************************************/
/*REPEAT ABOVE WITH LN RECRUITS and all deaths TO DO SEMI-ELAST LINEARLY*/
*My paper had Poisson Regressions as the main functional form, but to be honest
*I think economists are biased against non-linear estimation. So I'm making the OLS estimates
*the main estimates.

gen LNactive=ln(active+1)
/* If I resize deaths here I need to resize all of them*/
replace monthcountydeath=monthcountydeath/100
replace L1monthcountydeath=L1monthcountydeath/100
replace outofcounty=outofcounty/100
replace L1outofcounty=L1outofcounty/100
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.

/******WEIGHTED REGRESSIONS*******/

/*NO STATE*/
reghdfe LNactive monthcountydeath L1monthcountydeath [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNLinearW.tex, tex ti(Log County Applicants vs Deaths and Unemployment) ///
 ct(Basic) bdec(3) tdec(3) bracket se append ///
 addnote("Notes: Table shows linear regression estimates of log national recruits on deaths.", ///
 "The first four columns show applicants and the last four show contracts.", Filename:LNLinearW.tex) ///
 addtext(County FE, YES, Month FE, YES, State Trend, NO, Stateyear FE, NO)
 

/*STATE AND UNEMP*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp [aweight=avgcountypop], vce(cluster fips) absorb(fips month)
outreg2 using ./Output/LNLinearW.tex, tex ct(w/State) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO, Stateyear FE, NO)
	
/*STATE TREND*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp statetrend1-statetrend51[aweight=avgcountypop], ///
	vce (cluster fips) absorb(fips month)
outreg2 using ./Output/LNLinearW.tex, tex ct(w/Statetrend) bdec(3) tdec(3) ///
	bracket se append keep(*month* *county* stateunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trend, YES, Stateyear FE, NO)

/*STATE YEAR INTERACTED FE*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/LNLinearW.tex, tex ti(County Applicants vs Deaths and Unemployment) ///
	ct(w/Stateyear) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO, Stateyear FE, YES)
/*
/*WEIGHTED FUTURE LEADS--WITH LN(Active)*/
disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
areg LNactive F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips) vce(robust)
outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp using ./Output/forwardbasicWLN.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote(forwardbasicWLN.txt)
coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title(County Recruits)
graph export ./Output/forwardcountyLN`file'.png, replace

areg LNactive F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips)  vce(robust)
outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp using ./Output/forwardbasicWLN.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title (County and State Recruits)
graph export ./Output/forwardcountystateLN`file'.png, replace
*/


} /*END HUGE LOOP OVER BOTH FILES*/
