*2014.12.7 began testing rate of death instead of number of death

cd C:/Users/garret/Documents/Research/Military/
cap log close
log using ./Logs/redefpoisson.log, replace

/*HAVE TO KEEP THIS FILE MANAGEMENT UP HERE, OUTSIDE THE APP/CON LOOP*/
*cap rm ./Output/redefPinteractions.txt
*cap rm ./Output/redefPinteractionsR.txt
*cap rm ./Output/redefPrec.txt
*cap rm ./Output/redefPrecR.txt
*cap rm ./Output/redefPrace.txt
 cap rm ./Output/redefPbasic.txt
 cap rm ./Output/redefPbasicR.txt
 
clear all
*set maxvar 32767
set matsize 800
set maxiter 30
set more off

foreach file in county countyCON /*county90 countyCON90*/ {   /*BEGIN HUGE LOOP OVER BOTH FILES*/

/*ONLY DO ALL THIS CONSTRUCTION ONCE*/

use ./Data/`file'_raw.dta, clear
*drop *Q*
/*drop ID-McareB03*/
drop if fips==0
drop if countyfips=="999"
/*GENERATE YEAR FIXED EFFECTS*/
gen year1999=1 if year==1999
gen year2000=1 if year==2000
gen year2001=1 if year==2001
gen year2002=1 if year==2002
gen year2003=1 if year==2003
gen year2004=1 if year==2004
gen year2005=1 if year==2005
gen year2006=1 if year==2006
foreach var in 1999 2000 2001 2002 2003 2004 2005 2006{
 replace year`var'=0 if year`var'==.
}
/*GEN MONTH FE*/
cap tab month, gen(monthfe)

/* (1) CREATE LAGS*/
sort fips month
foreach var in outofstate Rmonthcountydeath Routofcounty Routofstate countyunemp stateunemp nationalunemp monthnationalmort monthstatemort monthcountymort{
 foreach X of numlist 1/12 {
  quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
  quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
  label var L`X'`var' "Value for `var' `X' months ago"
  label var F`X'`var' "Value for `var' `X' months in future"
 } 
}

foreach var in monthcountydeath{
gen `var'bin=(`var'>0 & `var'<.) /*binary*/
foreach X of numlist 1/12 {
  quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X'] /*lags*/
  quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X'] /*leads*/
  quietly gen L`X'`var'bin=(`var'[_n-`X']>0 &`var'[_n-`X']<.) if fips[_n]==fips[_n-`X'] /*binary lag*/
  quietly gen F`X'`var'bin=(`var'[_n+`X']>0 &`var'[_n-`X']<.) if fips[_n]==fips[_n+`X'] /*binary leads*/
  label var L`X'`var' "County deaths `X' months ago"
  label var F`X'`var' "County deaths `X' months hence"
 } 
}
foreach var in outofcounty{
gen `var'bin=(`var'>0 & `var'<.) /*binary*/
foreach X of numlist 1/12 {
  quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
  quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
  quietly gen L`X'`var'bin=(`var'[_n-`X']>0 &`var'[_n-`X']<.) if fips[_n]==fips[_n-`X'] /*binary lag*/
  quietly gen F`X'`var'bin=(`var'[_n+`X']>0 &`var'[_n-`X']<.) if fips[_n]==fips[_n+`X'] /*binary leads*/
  label var L`X'`var' "State deaths `X' months ago"
  label var F`X'`var' "State deaths `X' months hence"
 } 
 }
 label var monthcountydeath "In-county deaths this month"
 label var outofcounty "In-State deaths this month"
 
/*CREATE TIME SERIES, STATE TREND*/
gen mo=substr(month,5,2)
destring year, replace
destring mo, replace
gen fancymonth=ym(year,mo)
destring fips, replace
tsset fips fancymonth
gen t=fancymonth-501
tab statefips, gen(statetrend)
forvalues X=1/51 {
 replace statetrend`X'=statetrend`X'*t
}

/*CREATE INTERACTED FE*/
gen stateyear=string(year)+string(statefips)
tab stateyear, gen(stateyearfe)

gen active=ARmonthcounty+MRmonthcounty+NRmonthcounty+FRmonthcounty
label var active "Active duty recruits this month"

/*MERGE IN THE POPULATION DATA*/
/*drop ID-McareB03*/
destring statefips, replace
destring countyfips, replace
destring year, replace
drop if statefips==72
sort statefips countyfips
merge m:1 statefips countyfips year using ./Population/countyyoungmalepop.dta
drop if _merge==2 /*ALASKA DIVISIONS ARE INCONSISTENT. DROP IT*/
rename _merge mergecountypop
merge m:1 statefips using ./Population/statenationyoungmalepop.dta
drop if _merge!=3 /*WHO ARE THESE 33 FUCKERS, AND WHERE DID THEY COME FROM?*/
rename _merge mergestatepop

/*MERGE IN THE BUSH '00 DATA*/
sort statefips countyfips
merge m:1 statefips countyfips using ./Political/pctbush2000.dta
drop if _merge==2
rename _merge mergeBush00

/*CREATE POPULATION VARIABLES FOR COUNTY, STATE, AND NATION*/
bysort fips:egen countypop=mean(age1824_male)
rename age1824_male countypopmonth
drop if countypop==0 /*CAN'T USE THESE FOR EXPOSURE*/
gen statepop=.
gen nationpop=.
destring month, replace
replace statepop=totalpop2001 if year==2001
replace statepop=totalpop2002 if year==2002
replace statepop=totalpop2003 if year==2003
replace statepop=totalpop2004 if year==2004
replace statepop=totalpop2005 if year==2005
replace statepop=totalpop2006 if year==2006
gen avgstatepop=(totalpop2001+totalpop2002+totalpop2003+totalpop2004+totalpop2005+totalpop2006)/6
replace nationpop=14358348 if year==2001
replace nationpop=14626517 if year==2002
replace nationpop=14834115 if year==2003
replace nationpop=15055210 if year==2004
replace nationpop=15139739 if year==2005
replace nationpop=15233351 if year==2006

/*TEST FOR ANY DEATHS BY MONTH*/
bysort month: egen anydeaththismonth=max(monthcountydeath)
replace anydeaththismonth=1 if anydeaththismonth>1
drop if fips==8014|fips==30069|fips==31091|fips==51515|fips==51580|fips==51595|fips==51600|fips==51678|fips==51685|fips==51690
drop if month==200608
/*DROP THESE COUNTIES AND MONTHS BECAUSE THEY HAVE NO DEATHS (recruits?) OR ALL ZEROES, PREVENTING CONVERGENCE*/

/*GENERATE POLYNOMIALS OF DEATHS*/
foreach var in monthcountydeath Rmonthcountydeath outofcounty Routofcounty outofstate Routofstate monthstatemort monthcountymort{
 foreach lag in F12 F11 F10 F9 F8 F7 F6 F5 F4 F3 F2 F1 "" L1 L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12{
  quietly gen `lag'`var'SQ=`lag'`var'*`lag'`var'
  label var `lag'`var'SQ "`lag'`var' Squared"
 }
}

/*REPLACE DEATHS BY /100 SO THAT ESTIMATES ARE EASY TO READ/INTERPRET*/
foreach var in monthcountydeath Rmonthcountydeath outofcounty Routofcounty outofstate Routofstate monthstatemort monthcountymort{
 foreach lag in F12 F11 F10 F9 F8 F7 F6 F5 F4 F3 F2 F1 "" L1 L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12 {
  foreach poly in "" SQ{
   quietly replace `lag'`var'`poly'=`lag'`var'`poly'/100
  }
 }
} 


save temp_`file'_P.dta, replace
/**/


/*END ALL CONSTRUCTION GARBAGE*/
use temp_`file'_P.dta, clear



/*MAIN POISSON TABLE*/
foreach type in "" R {/*DO WITH BOTH ACTIVE AND TOTAL DEATHS*/

disp "HORSE RACE BTW DEATH TYPES%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate using ./Output/redefPbasic`type'.txt, ct(`file'`type'HORSERACE) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "BASIC%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath monthfe3-monthfe58, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath using ./Output/redefPbasic`type'.txt, ct(`file'`type'Basic) addnote(redefPbasic`type'.txt on EML) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/redefPbasic`type'.txt, ct(w/State) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

*disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
*xtpoisson active F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp monthfe10-monthfe52, fe exposure(countypop) vce(robust)
*outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp using ./Output/forwardPbasic`type'.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
*coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title(County Recruits)
*graph export ./Output/forwardPcounty`file'.png, replace

*xtpoisson active F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp monthfe10-monthfe52, fe exposure(countypop) vce(robust)
*outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp using ./Output/forwardPbasic`type'.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
*coefplot, drop(monthfe* stateunemp countyunemp _cons) xline(0) title (County and State Recruits)
*graph export ./Output/forwardPcountystate`file'.png, replace

/*STATE TRENDS*/
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/redefPbasic`type'.txt, ct(w/StateTrend) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

/*SHOULD I HAVE ONLY ONE UNEMP?*/
*xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(countypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty countyunemp using ./Output/redefPbasic`type'.txt, ct(No State Unemp) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

/*DEATH POLYNOMIAL*/
*xtpoisson active `type'monthcountydeath L1`type'monthcountydeath L1`type'monthcountydeathSQ `type'outofcounty L1`type'outofcounty L1`type'outofcountySQ stateunemp countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(countypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath L1`type'monthcountydeathSQ `type'outofcounty L1`type'outofcounty L1`type'outofcountySQ stateunemp countyunemp using ./Output/redefPbasic`type'.txt, ct(w/Poly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

/*GET INTERACTED TO WORK?
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp stateyearfe52-stateyearfe101 stateyearfe103-stateyearfe153 stateyearfe155-stateyearfe205 stateyearfe207-stateyearfe257 stateyearfe259-stateyearfe309 stateyearfe311-stateyearfe312, fe exposure(countypop) difficult vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/redefPbasic.txt, ct(w/State*Year) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
*/

}/*END BOTH ACTIVE AND TOTAL DEATHS*/
}/*END HUGE LOOP OVER BOTH FILES*/


****************************************************************************************************************
/*MAIN POISSON TABLE, EXCEPT WITH ALL RECRUITS, BECAUSE SOME REFERREE DOESN'T UNDERSTAND MEASUREMENT ERROR*/
*That means use "monthcountyrecruit" instead of "active"
*Still doing both active and all recruits

*disp "FOR THE TABLE 1, JUST DO AN F-TEST%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
*areg monthcountyrecruit monthfe2-monthfe58, absorb(fips) vce(robust)
*predict resid, res
*drop resid

/*
disp "HORSE RACE BTW DEATH TYPES%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson monthcountyrecruit `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate using ./Output/allrecPbasic`type'.txt, addnote(allrecPbasic`type'.txt on EML) ct(`file'`type'HORSERACE) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "BASIC%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson monthcountyrecruit `type'monthcountydeath L1`type'monthcountydeath monthfe3-monthfe58, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath using ./Output/allrecPbasic`type'.txt, ct(`file'`type'Basic) addnote(allrecPbasic`type'.txt on EML) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson monthcountyrecruit `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/allrecPbasic`type'.txt, ct(w/State) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
*/

*disp "PLACEBO TEST-FUTURE LAGS--LOOKS LIKE I WIN"
*xtpoisson active F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp monthfe10-monthfe52, fe exposure(countypop) vce(robust)
*outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath stateunemp countyunemp using ./Output/allrec_forwardPbasic`type'.txt, ct(`file'countyonly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
*xtpoisson active F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp monthfe10-monthfe52, fe exposure(countypop) vce(robust)
*outreg2 F6monthcountydeath F5monthcountydeath F4monthcountydeath F3monthcountydeath F2monthcountydeath F1monthcountydeath monthcountydeath L1monthcountydeath L2monthcountydeath L3monthcountydeath L4monthcountydeath L5monthcountydeath L6monthcountydeath L7monthcountydeath L8monthcountydeath L9monthcountydeath L10monthcountydeath L11monthcountydeath L12monthcountydeath F6outofcounty F5outofcounty F4outofcounty F3outofcounty F2outofcounty F1outofcounty outofcounty L1outofcounty L2outofcounty L3outofcounty L4outofcounty L5outofcounty L6outofcounty stateunemp countyunemp using ./Output/allrec_forwardPbasic`type'.txt, ct(`file'countyandstate) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

/*STATE TRENDS*/
*xtpoisson monthcountyrecruit `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(countypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/allrecPbasic`type'.txt, ct(w/StateTrend) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

/*SHOULD I HAVE ONLY ONE UNEMP?*/
*xtpoisson monthcountyrecruit `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(countypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty countyunemp using ./Output/allrecPbasic`type'.txt, ct(No State Unemp) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

/*DEATH POLYNOMIAL*/
*xtpoisson monthcountyrecruit `type'monthcountydeath L1`type'monthcountydeath L1`type'monthcountydeathSQ `type'outofcounty L1`type'outofcounty L1`type'outofcountySQ stateunemp countyunemp monthfe3-monthfe58 statetrend1-statetrend51, fe exposure(countypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath L1`type'monthcountydeathSQ `type'outofcounty L1`type'outofcounty L1`type'outofcountySQ stateunemp countyunemp using ./Output/allrecPbasic`type'.txt, ct(w/Poly) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

} /*END OF BOTH ACTIVE AND TOTAL DEATHS*/




/********************************************************************************/
/*
/*TEST WITH RECRUITER CONTROLS AND STUFF*/
tostring qtr, replace
tostring year, replace
gen yearqtr=year+qtr
destring yearqtr, replace
gen totalrec=(arec+mrec+frec+nrec)/100 if yearqtr <=20042
gen outofcountymort=monthstatemort-monthcountymort
gen L1outofcountymort=L1monthstatemort-L1monthcountymort


foreach type in "" R { /*DO WITH BOTH ACTIVE AND TOTAL DEATHS*/
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51 if yearqtr<=20042&totalrec!=.&L1monthcountymort!=.&L1outofcountymort!=., fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/redefPrec`type'.txt, ct(`file'NoRec`type') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp totalrec L1monthcountymort L1outofcountymort monthfe3-monthfe33 statetrend1-statetrend51 if yearqtr<=20042, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp totalrec L1monthcountymort L1outofcountymort using ./Output/redefPrec`type'.txt, ct(`file'RecMort`type') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
} 

*/


/*************************************************************************************/
/*************************************************************************************/
/* IGNORE JAN16 FOR BASIC ONLY*/

/*REGS WITH INTERACTIONS*/
/*REWORK INTERACTION VARIABLES*/
replace PctWhite05=PctWhite05/100
replace PctBlack05=PctBlack05/100
replace PctAIAN05=PctAIAN05/100
replace PctAsian05=PctAsian05/100
replace PctNHOPI05=PctNHOPI05/100
replace PctH05=PctH05/100
replace CA05N0035_05=CA05N0035_05/1000
replace CA05N0030_05=CA05N0030_05/1000
replace PctBush04=PctBush04/100
replace PctKerry04=PctKerry04/100
/*RACIAL FRACTIONALIZATION*/
gen RaceFracH=1-PctWhite05*PctWhite05-PctBlack05*PctBlack05-PctAIAN05*PctAIAN05-PctAsian05*PctAsian05-PctNHOPI*PctNHOPI05-PctH05*PctH05
gen RaceFrac=1-PctWhite05*PctWhite05-PctBlack05*PctBlack05-PctAIAN05*PctAIAN05-PctAsian05*PctAsian05-PctNHOPI*PctNHOPI05
replace PctWhite05=PctWhite05*100
replace PctBlack05=PctBlack05*100
replace PctAIAN05=PctAIAN05*100
replace PctAsian05=PctAsian05*100
replace PctNHOPI05=PctNHOPI05*100
replace PctH05=PctH05*100
replace CA05N0035_05=CA05N0035_05*1000
replace CA05N0030_05=CA05N0030_05*1000
replace PctBush04=PctBush04*100
replace PctKerry04=PctKerry04*100
replace pctbush_2000=pctbush_2000*100
/*ECONOMY TYPE*/
gen Farming=1 if EconType04==1
replace Farming=0 if Farming==.
gen FarmMine=1 if EconType04==1|EconType==2
replace FarmMine=0 if FarmMine==.
gen Manufacturing=1 if EconType04==1
replace Manufacturing=0 if Manufacturing==.
gen Government=1 if EconType04==1
replace Government=0 if Government==.
gen Services=1 if EconType04==1
replace Services=0 if Services==.
gen UrbanInfluence=1 if UrbanInf03<=7
replace UrbanInfluence=0 if UrbanInfluence==.
gen Rural=1 if RuralUrban03>3
replace Rural=0 if Rural==.
gen Rural2=1 if RuralUrban03>5
replace Rural2=0 if Rural2==.

/*ADD NEWSPAPERS*/
*rename StateName statename
*rename CountyName countyname
*replace countyname=upper(countyname)
*replace statename=upper(statename)
*sort statename countyname
*merge m:1 statename countyname using ./Newspaper/Newspapers.dta


 /*GEN INTERACTIONS*/ //*RESTORE DEATHS TO FULL SIZE for INTERACTION *replace L1monthcountydeath=L1monthcountydeath*100 *replace countypop=countypop/1000
 summ countypop [aweight=countypop]
 cap gen avgcountypop=r(mean)
 cap gen countypopZ=countypop-avgcountypop
 gen `type'deathcountypop=L1`type'monthcountydeath/countypopZ
  //*1000 here would make the coefficient less ridiculous, but it makes sense either way.
  

 *bysort fips: egen avgcountyunemp=mean(countyunemp) //Don't use. Calculate the county unemployment interaction using the unemployment in the month
 //of each death, not just the average unemployment in the county across time.
 
 foreach var in /*avg*/countyunemp PctBlack05 RaceFrac Rural2 PctBush04 PctKerry04 pctbush_2000 /*avgcov*/{
  quietly summ `var' [aweight=countypop] //calculate the weighted average of the interaction characteristics
  quietly cap gen avg`var'=r(mean) //make that weighted average a variable
  quietly cap gen `var'Z=`var'-avg`var' //calculate the above-averageness of the characteristic
  quietly gen death`var'=L1`type'monthcountydeath*`var'Z //Interact the death/100 with the above-averageness of the characteristic
 } /*END MULTIPLE INTERACTION VARS*/ 

/*TEST DISTRIBUTION OF EFFECT WITH INTERACTIONS*/

*Black
 xtpoisson active monthcountydeath L1monthcountydeath outofcounty L1outofcounty /*took out avg*/deathcountyunemp deathcountypop deathPctBlack05 deathPctBush04 /*deathavgcov*/ deathRural2 stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathavgcountyunemp deathcountypop deathPctBlack05 deathPctBush04 deathRural2 stateunemp countyunemp  using ./Output/redefPinteractions.txt, ct(black) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
 gen effect=_b[L1monthcountydeath]+_b[deathcountyunemp]*countyunempZ+_b[deathcountypop]*countypopZ + PctBlack05Z*_b[deathPctBlack05] +PctBush04Z*_b[deathPctBush04] +Rural2Z*_b[deathRural2]
 //No need to add fixed effects here because those affect level, not the effect size
 sort effect

 summ effect
 label var effect "Percentage Point Deterrent Effect of County Death by Interacted County Characteristics"
 histogram effect if effect>-50 &effect<50, title(Distribution of Deterrent Effects)
 graph export ./Output/interactionhisto.tif, replace

 *Race Frac
 xtpoisson active monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathavgcountyunemp deathcountypop deathRaceFrac deathPctBush04 deathRural2 stateunemp countyunemp monthfe3-monthfe58 if effect>0 & effect<., fe exposure(countypop) vce(robust)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathavgcountyunemp deathcountypop deathRaceFrac deathPctBush04 deathRural2 stateunemp countyunemp  using ./Output/redefPinteractions.txt, ct(racefrac) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

 *xtpoisson active monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 if effect>0 & effect<., fe exposure(countypop) vce(robust)
 *br fips avgcountyunemp PctBlack05 PctBush04 countypop effect if (fips==6001|fips==6037|fips==53033|fips==41051|fips==8013|fips==48329|fips==19061|fips==40003|fips==30031|fips==49049) & month==200410


 
 /*UGH! TRY A WHOLE SHIT-TON OF INTERACTIONS*/
 #delimit;
 xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty 
  `type'deathcountyunemp `type'NLdeathcountyunemp `type'Sdeathcountyunemp `type'SNLdeathcountyunemp
  `type'deathcountypop `type'NLdeathcountypop `type'Sdeathcountypop `type'SNLdeathcountypop
  `type'deathPctBlack05 `type'NLdeathPctBlack05 `type'SdeathPctBlack05 `type'SNLdeathPctBlack05
  `type'deathPctBush04 `type'NLdeathPctBush04 `type'SdeathPctBush04 `type'SNLdeathPctBush04
  `type'deathRural2 `type'NLdeathRural2 `type'SdeathRural2 `type'SNLdeathRural2
   stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust);
 #delimit cr
 outreg2 using ./Output/redefPinteractions`type'.txt, ct(TooMany!) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
  
 /*TEST BUSH '00*/
 xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'deathcountyunemp `type'deathcountypop `type'deathPctBlack05 `type'deathpctbush_2000 `type'deathRural2 stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust) 

 */
 
}/*END BOTH ACTIVE AND TOTAL DEATHS*/


}/*END HUGE LOOP OVER BOTH FILES*/
