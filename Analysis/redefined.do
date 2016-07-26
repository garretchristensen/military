/*******************************************RUN LINEAR COUNTY REGRESSIONS!***********************************************/
*2015/8/12 This file runs the main set of log-linear regressions, which are presented as the main set of results
*2015/10/15 remaking this as the main set of linear regs. level linear appear in appx, log linear are main set.

clear all
set more off
cd $dir
cap log close
log using ./Logs/redefined.smcl, replace

//since outreg is inside loop, they're all append and must be rm'd manually
cap rm ./Output/LinearW.tex //level regs
cap rm ./Output/LinearW.txt
cap rm ./Output/LNLinearW.tex //log linear
cap rm ./Output/LNLinearW.txt
cap rm ./Output/LNLinearWR.tex //log linear, active deaths only
cap rm ./Output/LNLinearWR.txt
cap rm ./Output/forwardbasicWLN.txt //log linear, 2 leads
cap rm ./Output/forwardbasicWLN.tex
cap rm ./Output/allrecLNLinearW.txt //log linear, ALL recruits
cap rm ./Output/allrecLNLinearW.tex


foreach file in APP CON{ /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Data/county`file'_raw.dta, clear
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
*drop ID-McareB03
*drop *Q*

/******WEIGHTED LINEAR (LEVEL!!) REGRESSIONS*******/
/* Level regressions. Appear in Appendix*/

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
*reghdfe active monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
*	stateunemp [aweight=avgcountypop], vce (cluster fips) ///
*	absorb(fips month statetrend)
*outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp ///
*	countyunemp using ./Output/LinearW.tex, tex ct(w/Statetrend) bdec(3) tdec(3) ///
*	bracket se append keep(*month* *county* stateunemp)

/*STATE YEAR INTERACTED FE*/
reghdfe active monthcountydeath L1monthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/LinearW.tex, tex ti(County Applicants vs Deaths and Unemployment) ///
	ct(w/Stateyear) bdec(3) tdec(3) bracket se append

 
/*WEIGHTED FUTURE LEADS*/
*10/20/15 This doesn't appear in the paper, I don't think.
*2/1/16 AND not even in appendix because it's level regressions.

*disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
*areg active F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath  stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips) vce(robust)
*outreg2  F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath  stateunemp countyunemp using ./Output/forwardbasicW.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote(forwardbasicW.txt)

*areg active  F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath  F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty  stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips)  vce(robust)
*outreg2  F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath ///
*	L2monthcountydeath  F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty ///
*	stateunemp countyunemp using ./Output/forwardbasicW.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))


/*******************************************************************/
*2/1/16 IGNORE--NOBODY GIVES A SHIT ABOUT LEVEL-LEVEL REGRESSIONS
/*REPEAT ABOVE WITH ACTIVE DEATHS ONLY*/
*Do the same as above (level-level weighted linear regressions) 
*But only with active deaths: Rmonthcountydeath L1Rmonthcountydeath

/*******************************************************************************************/
/*REPEAT ABOVE WITH LN RECRUITS and all deaths TO DO SEMI-ELAST LINEARLY*/
*My paper had Poisson Regressions as the main functional form, but to be honest
*I think economists are biased against non-linear estimation. So I'm making the OLS estimates
*the main estimates.


/* If I resize deaths here I need to resize all of them*/
replace monthcountydeath=monthcountydeath/100
replace L1monthcountydeath=L1monthcountydeath/100
replace outofcounty=outofcounty/100
replace L1outofcounty=L1outofcounty/100
label var monthcountydeath "Current In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Current Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}

/******WEIGHTED REGRESSIONS*******/
*THIS IS THE MAIN SPECIFICATION!

if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}
/*NO STATE*/
reghdfe LNactive monthcountydeath L1monthcountydeath [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNLinearW.tex, tex label ///
	ti(Log County Applicants vs Deaths and Unemployment) ///
	ct(`header') bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first three columns show applicants and the last three show contracts.", Filename:LNLinearW.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 

/*STATE AND UNEMP*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp [aweight=avgcountypop], vce(cluster fips) absorb(fips month)
outreg2 using ./Output/LNLinearW.tex, tex label ct(`header') bdec(3) tdec(3) bracket ///
	se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
	

/*STATE TREND*/
*reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
*	stateunemp statetrend1-statetrend51[aweight=avgcountypop], ///
*	vce (cluster fips) absorb(fips month )
*outreg2 using ./Output/LNLinearW.tex, tex label ct(State Trend) bdec(3) tdec(3) ///
*	bracket se append keep(*month* *county* stateunemp) ///
*	addtext(County FE, YES, Month FE, YES, State Trend, YES, Stateyear FE, NO)

/*STATE YEAR INTERACTED FE*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/LNLinearW.tex, tex label ///
	ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)

/*WEIGHTED FUTURE LEADS--WITH LN(Active)*/
disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
reghdfe LNactive F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath ///
	stateunemp countyunemp [aweight=avgcountypop], absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/forwardbasicWLN.txt, lab tex ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) ///
addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on active duty deaths", ///
	"As well as future 'lead' periods. Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"as well as a state-specific linear trend. The first four columns show applicants and the last four show contracts.", ///
	Filename:forwardbasicWLN.txt) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)

reghdfe LNactive F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath ///
	F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop], absorb(fips month stateyear)  vce(cluster fips)
outreg2 using ./Output/forwardbasicWLN.txt, lab tex ct(`file'countyandstate) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)


************************************************************************
/*ACTIVE DEATHS ONLY*/
************************************************************************
replace Rmonthcountydeath=Rmonthcountydeath/100
label var Rmonthcountydeath "In-County Active Duty Deaths/100"
replace L1Rmonthcountydeath=L1Rmonthcountydeath/100
label var L1Rmonthcountydeath "Lag In-County Active Duty Deaths/100"
replace Routofcounty=Routofcounty/100
label var Routofcounty "Out-of-County Active Duty Deaths"
replace L1Routofcounty=L1Routofcounty/100
label var L1Routofcounty "Lag Out-of-County Active Duty Deaths"

summ Rmonthcountydeath
if r(max)>1|r(max)<.01 {
	display "divided R deaths by 100 too much"
	hissy fit
}
/*NO STATE*/
reghdfe LNactive Rmonthcountydeath L1Rmonthcountydeath [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNLinearWR.tex, tex label ///
	ti(Log County Applicants vs Active Duty Deaths and Unemployment) ///
	ct(Basic) bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on \textit{only} active duty deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first three columns show applicants and the last three show contracts.", Filename:LNLinearWR.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 

/*STATE AND UNEMP*/
reghdfe LNactive Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp ///
	stateunemp [aweight=avgcountypop], vce(cluster fips) absorb(fips month)
outreg2 using ./Output/LNLinearWR.tex, tex label ct(State) bdec(3) tdec(3) bracket ///
	se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
	
/*STATE TREND*/
*reghdfe LNactive Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp ///
*	stateunemp statetrend1-statetrend51[aweight=avgcountypop], ///
*	vce (cluster fips) absorb(fips month)
*outreg2 using ./Output/LNLinearWR.tex, tex label ct(State Trend) bdec(3) tdec(3) ///
*	bracket se append keep(*month* *county* stateunemp) ///
*	addtext(County FE, YES, Month FE, YES, State Trend, YES, Stateyear FE, NO)

/*STATE YEAR INTERACTED FE*/
reghdfe LNactive Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/LNLinearWR.tex, tex label ///
	ct(w/Stateyear) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)

	
************************************************************************
/*ALL RECRUITS, EVEN THE JACKED RESERVES DATA*/
************************************************************************
gen LNmcr=ln(monthcountyrecruit+1)

/*NO STATE*/
reghdfe LNmcr monthcountydeath L1monthcountydeath [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/allrecLNLinearW.tex, tex label ///
	ti(Log County ALL Applicants vs Deaths and Unemployment) ///
	ct(Basic) bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national recruits +1) on military deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first three columns show applicants and the last three show contracts.", Filename:allrecLNLinearW.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 

/*STATE AND UNEMP*/
reghdfe LNmcr monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp ///
	stateunemp [aweight=avgcountypop], vce(cluster fips) absorb(fips month)
outreg2 using ./Output/allrecLNLinearW.tex, tex label ct(State) bdec(3) tdec(3) bracket ///
	se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
	
/*STATE TREND*/
*reghdfe LNmcr Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp ///
*	stateunemp statetrend1-statetrend51[aweight=avgcountypop], ///
*	vce (cluster fips) absorb(fips month)
*outreg2 using ./Output/allrecLNLinearW.tex, tex label ct(State Trend) bdec(3) tdec(3) ///
*	bracket se append keep(*month* *county* stateunemp) ///
*	addtext(County FE, YES, Month FE, YES, State Trend, YES, Stateyear FE, NO)

/*STATE YEAR INTERACTED FE*/
reghdfe LNmcr monthcountydeath L1monthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp [aweight=avgcountypop],  absorb(fips month stateyear) vce(cluster fips)
outreg2 using ./Output/allrecLNLinearW.tex, tex label ///
	ct(w/Stateyear) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
	
	
	
	
} /*END HUGE LOOP OVER BOTH FILES*/
