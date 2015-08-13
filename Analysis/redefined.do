/*******************************************RUN LINEAR COUNTY REGRESSIONS!***********************************************/
*2015/8/12 This file runs the main set of log-linear regressions, which are presented as the main set of results

clear all
set more off
*set mem 5g
*set maxvar 32767
*set matsize 11000
cd $dir
cap log close
log using ./Logs/redefined.txt, replace

cap rm ./Output/redefW.txt
cap rm ./Output/redefelastW.txt
cap rm ./Output/redefRW.txt
cap rm ./Output/redefelastRW.txt
cap rm ./Output/redefWLN.txt

foreach file in APP CON{ /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Data/county`file'_raw.dta, clear
*drop ID-McareB03
*drop *Q*


*************************************************************************************************
/*Simple Regression, Get Residuals and Plot. Quite Noisy.*/
/*Not clear this works, since counties have multiple deaths*/
*disp "EVENT STUDY/F TEST%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
*disp "FILE NAME IS `file'"
*disp "look at obs numbers to not drop zeros--log"

*gen lnactive=active+1
*replace lnactive=ln(lnactive)
*foreach var in active lnactive {
*xi: areg `var' i.month [aweight=countypop], absorb(fips) vce(robust) 
*predict resid, res
*foreach X of numlist 1/12{
* disp "F`X'"
* summ resid if F`X'monthcountydeathbin==1
*}
*foreach X of numlist 1/12{
* disp "L`X'"
* summ resid if L`X'monthcountydeathbin==1
*}
*quietly gen residF12=resid if F12monthcountydeathbin==1
*quietly gen residF11=resid if F11monthcountydeathbin==1
*quietly gen residF10=resid if F10monthcountydeathbin==1
*quietly gen residF9=resid if F9monthcountydeathbin==1
*quietly gen residF8=resid if F8monthcountydeathbin==1
*quietly gen residF7=resid if F7monthcountydeathbin==1
*quietly gen residF6=resid if F6monthcountydeathbin==1
*quietly gen residF5=resid if F5monthcountydeathbin==1
*quietly gen residF4=resid if F4monthcountydeathbin==1
*quietly gen residF3=resid if F3monthcountydeathbin==1
*quietly gen residF2=resid if F2monthcountydeathbin==1
*quietly gen residF1=resid if F1monthcountydeathbin==1
*quietly gen resid0=resid if monthcountydeathbin==1
*quietly gen residL1=resid if L1monthcountydeathbin==1
*quietly gen residL2=resid if L2monthcountydeathbin==1
*quietly gen residL3=resid if L3monthcountydeathbin==1
*quietly gen residL4=resid if L4monthcountydeathbin==1
*quietly gen residL5=resid if L5monthcountydeathbin==1
*quietly gen residL6=resid if L6monthcountydeathbin==1
*quietly gen residL7=resid if L7monthcountydeathbin==1
*quietly gen residL8=resid if L8monthcountydeathbin==1
*quietly gen residL9=resid if L9monthcountydeathbin==1
*quietly gen residL10=resid if L10monthcountydeathbin==1
*quietly gen residL11=resid if L11monthcountydeathbin==1
*quietly gen residL12=resid if L12monthcountydeathbin==1
*graph box residF12 residF11 residF10 residF9 residF8 residF7 residF6 residF5 residF4 residF3 residF2 residF1 resid0 residL1 residL2 residL3 residL4 residL5 residL6 residL7 residL8 residL9 residL10 residL11 residL12, legend(off) nooutsides title("`var' `file'")
*drop resid*
*} /*End active lnactive loop*/
*******************************************************************************

/******WEIGHTED REGRESSIONS*******/



/*NO STATE*/
*areg active monthcountydeath L1monthcountydeath monthfe3-monthfe58 [aweight=avgcountypop], absorb(fips) robust cluster(fips)
*outreg2 monthcountydeath L1monthcountydeath using ./Output/redefW.txt, ti(County Applicants vs Deaths and Unemployment) addnote(redefW.txt) ct(Basic) bdec(3) tdec(3) bracket se append
/*ELAST*/
*margins, eydx(monthcountydeath L1monthcountydeath) atmeans post
*outreg2 monthcountydeath L1monthcountydeath using ./Output/redefelastW.txt, ti(Margins-Calculated SEMI-Elasticities) addnote(redefelastW.txt) ct(Basic) bdec(3) tdec(3) bracket se append  
/*STATE AND UNEMP*/
areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp stateunemp monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefW.txt, ct(w/State) bdec(3) tdec(3) bracket se append
/*ELAST*/
*margins, eydx(monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp stateunemp) atmeans post
*outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefelastW.txt, ct(w/State) bdec(3) tdec(3) bracket se append  
/*STATE TREND*/
*areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp stateunemp statetrend2-statetrend51 monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
*outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefW.txt, ct(w/Statetrend) bdec(3) tdec(3) bracket se append
/*ELAST*/
*margins, eydx(monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp stateunemp) atmeans post
*outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefelastW.txt, ct(w/Statetrend) bdec(3) tdec(3) bracket se append  
/*STATE YEAR INTERACTED FE*/
*areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty  stateunemp countyunemp monthfe3-monthfe58 stateyearfe59-stateyearfe312 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
*outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefW.txt, ct(w/Stateyear) bdec(3) tdec(3) bracket se append
/*ELAST*/
*margins, eydx(monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp) atmeans post
*outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefelastW.txt, ct(w/Stateyear) bdec(3) tdec(3) bracket se append  

*2014.11.10 BASED ON JHR COMMENTS, TRY LOG, WITH DUMMY
foreach var in monthcountydeath L1monthcountydeath outofcounty L1outofcounty{
*make a dummy equal to 1 if deaths==0
replace `var'=`var'*100
gen Z`var'=(`var'==0)
*take log of deaths, set to zero if zero deaths
gen temp`var'=ln(`var')
replace temp`var'=0 if `var'==0
drop `var'
rename temp`var' `var'
}

areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty Zmonthcountydeath ZL1monthcountydeath Zoutofcounty ZL1outofcounty countyunemp stateunemp monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
 /*
/*WEIGHTED FUTURE LEADS*/
disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
areg active F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips) vce(robust)
outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp using ./Output/forwardbasicW.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote(forwardbasicW.txt)
coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title(County Recruits)
graph export ./Output/forwardcounty`file'.png, replace
margins, eydx(F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp) atmeans post
outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp using ./Output/forwardbasicelastW.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote (forwardbasicelastW.txt)

areg active F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips)  vce(robust)
outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp using ./Output/forwardbasicW.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title (County and State Recruits)
graph export ./Output/forwardcountystate`file'.png, replace
margins, eydx(F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp) atmeans post
outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp using ./Output/forwardbasicelastW.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

*/


/*******************************************************************/
/*REPEAT ABOVE WITH ACTIVE DEATHS ONLY*/

/******WEIGHTED REGRESSIONS--ACTIVE DEATHS ONLY*******/
/*
/*NO STATE*/
areg active Rmonthcountydeath L1Rmonthcountydeath monthfe3-monthfe58 [aweight=avgcountypop], absorb(fips) robust cluster(fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath using ./Output/redefRW.txt, ti(County Applicants vs ACTIVE Deaths and Unemployment) addnote(redefRW.txt EML) ct(`file'Basic) bdec(3) tdec(3) bracket se append
/*ELAST*/
margins, eydx(Rmonthcountydeath L1Rmonthcountydeath) atmeans post
outreg2 Rmonthcountydeath L1Rmonthcountydeath using ./Output/redefelastRW.txt, ti(Margins-Calculated SEMI-Elasticities ACTIVE deaths) addnote(redefelastRW.txt EML) ct(`file'Basic) bdec(3) tdec(3) bracket se append  
/*STATE AND UNEMP*/
areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp stateunemp monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp using ./Output/redefRW.txt, ct(w/State) bdec(3) tdec(3) bracket se append
/*ELAST*/
margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp stateunemp) atmeans post
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp using ./Output/redefelastRW.txt, ct(w/State) bdec(3) tdec(3) bracket se append  
/*STATE TREND*/
areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp stateunemp statetrend2-statetrend51 monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp using ./Output/redefRW.txt, ct(w/Statetrend) bdec(3) tdec(3) bracket se append
/*ELAST*/
margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty countyunemp stateunemp) atmeans post
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp using ./Output/redefelastRW.txt, ct(w/Statetrend) bdec(3) tdec(3) bracket se append  
/*STATE YEAR INTERACTED FE*/
areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty  stateunemp countyunemp monthfe3-monthfe58 stateyearfe59-stateyearfe312 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp using ./Output/redefRW.txt, ct(w/Stateyear) bdec(3) tdec(3) bracket se append
/*ELAST*/
margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp) atmeans post
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty stateunemp countyunemp using ./Output/redefelastRW.txt, ct(w/Stateyear) bdec(3) tdec(3) bracket se append  
*/
/*
/*WEIGHTED FUTURE LEADS--ACTIVE DEATHS ONLY*/
disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
areg active F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips) vce(robust)
outreg2 F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath stateunemp countyunemp using ./Output/forwardbasicRW.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote(forwardbasicRW.txt)
coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title(County Recruits)
graph export ./Output/forwardcountyR`file'.png, replace
margins, eydx(F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath stateunemp countyunemp) atmeans post
outreg2 F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath stateunemp countyunemp using ./Output/forwardbasicelastRW.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) addnote (forwardbasicelastRW.txt)

areg active F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath F6Routofcounty F5Routofcounty F4Routofcounty F3Routofcounty F2Routofcounty F1Routofcounty Routofcounty L1Routofcounty L2Routofcounty L3Routofcounty L4Routofcounty L5Routofcounty L6Routofcounty stateunemp countyunemp monthfe12-monthfe52 [aweight=avgcountypop], absorb(fips) vce(robust)
outreg2 F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath F6Routofcounty F5Routofcounty F4Routofcounty F3Routofcounty F2Routofcounty F1Routofcounty Routofcounty L1Routofcounty L2Routofcounty L3Routofcounty L4Routofcounty L5Routofcounty L6Routofcounty stateunemp countyunemp using ./Output/forwardbasicRW.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title (County and State Recruits)
graph export ./Output/forwardcountystateR`file'.png, replace
margins, eydx(F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath F6Routofcounty F5Routofcounty F4Routofcounty F3Routofcounty F2Routofcounty F1Routofcounty Routofcounty L1Routofcounty L2Routofcounty L3Routofcounty L4Routofcounty L5Routofcounty L6Routofcounty stateunemp countyunemp) atmeans post
outreg2 F6Rmonthcountydeath F5Rmonthcountydeath F4Rmonthcountydeath F3Rmonthcountydeath F2Rmonthcountydeath F1Rmonthcountydeath Rmonthcountydeath L1Rmonthcountydeath L2Rmonthcountydeath L3Rmonthcountydeath L4Rmonthcountydeath L5Rmonthcountydeath L6Rmonthcountydeath L7Rmonthcountydeath L8Rmonthcountydeath L9Rmonthcountydeath L10Rmonthcountydeath L11Rmonthcountydeath L12Rmonthcountydeath F6Routofcounty F5Routofcounty F4Routofcounty F3Routofcounty F2Routofcounty F1Routofcounty Routofcounty L1Routofcounty L2Routofcounty L3Routofcounty L4Routofcounty L5Routofcounty L6Routofcounty stateunemp countyunemp using ./Output/forwardbasicelastRW.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

*/


/*******************************************************************************************/
/*REPEAT ABOVE WITH LNACTIVE DEATHS TO DO SEMI-ELAST AUTOMATICALLY*/

gen LNactive=ln(active+1)
/* If I resize deaths here I need to resize all of them*/
*replace monthcountydeath=monthcountydeath/100
*replace L1monthcountydeath=L1monthcountydeath/100
*replace outofcounty=outofcounty/100
*replace L1outofcounty=L1outofcounty/100


/******WEIGHTED REGRESSIONS*******/
/*
/*NO STATE*/
areg LNactive monthcountydeath L1monthcountydeath monthfe3-monthfe58 [aweight=avgcountypop], absorb(fips) robust cluster(fips)
outreg2 monthcountydeath L1monthcountydeath using ./Output/redefWLN.txt, ti(LNCounty Applicants vs Deaths and Unemployment) addnote(redefWLN.txt EML) ct(`file'Basic) bdec(3) tdec(3) bracket se append
/*STATE AND UNEMP*/
areg LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp stateunemp monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefWLN.txt, ct(w/State) bdec(3) tdec(3) bracket se append
/*STATE TREND*/
areg LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty countyunemp stateunemp statetrend2-statetrend51 monthfe3-monthfe58 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefWLN.txt, ct(w/Statetrend) bdec(3) tdec(3) bracket se append
/*STATE YEAR INTERACTED FE*/
areg LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty  stateunemp countyunemp monthfe3-monthfe58 stateyearfe59-stateyearfe312 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefWLN.txt, ct(w/Stateyear) bdec(3) tdec(3) bracket se append
*/
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
