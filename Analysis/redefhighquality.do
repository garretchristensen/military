/*THIS FILE DOES SOME OF MY BASIC REGRESSIONS, BUT WITH DIFFERENT DATA SETS*/
clear all
set more off
cd $dir

cap log close
log using ./Logs/highquality.txt, replace

/*HAVE TO KEEP FILE MANAGEMENT STUFF UP HERE, OUTSIDE APP/CON LOOP*/
*cap rm ./Output/highqualitybyserviceP.txt
*cap rm ./Output/highqualitybyserviceLN.txt
cap rm ./Output/highqualitybytypeLN.txt
cap rm ./Output/highqualitybytypeP.txt
cap rm ./Output/highqualitybytypeLN.tex
cap rm ./Output/highqualitybytypeP.tex
*cap rm ./Output/highqualitybytypePX.txt
*cap rm ./Output/redefbyservicedeath.txt
*cap rm ./Output/redefPrace.txt
*cap rm ./Output/redefPhostile.txt
*cap rm ./Output/redefPgender.txt
*cap rm ./Output/redefPwar.txt

foreach file in APP CON {
/******************************************************************************/
use county`file'_raw.dta, clear /*LOOPS OVER BOTH FILES!*/
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}


/*(2)RECRUITS OF DIFFERENT QUALITY--OLS*/
foreach TYPE in LQ HQ50 HQ50alt HQ75 {
 gen LN`TYPE'monthcounty=ln(R`TYPE'monthcounty+1)
 reghdfe LN`TYPE'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp ///
	[aweight=avgcountypop], cluster(fips) absorb(fips month)
 outreg2 using ./Output/highqualitybytypeLN.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on cumulative ", ///
	"lagged deaths. Fixed effects are included separately by county and month as indiciated,", ///
	"The first five columns show applicants and the last five show contracts.", Filename:highqualitybytypeLN.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
}

/*RECRUITS OF DIFFERENT QUALITY--POISSON*/
foreach TYPE in LQ HQ50 HQ50alt HQ75 {
 xtpoisson R`TYPE'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp ///
	monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(countypop) vce(robust)
 outreg2  using ./Output/highqualitybytypeP.txt, ct(`header') bdec(3) tdec(3) bracket se append 
 /*ADDED 1/3/11-JUSTIN GALLAGHER ASKED WHY SMARTER KIDS RESPOND _MORE_ TO LOCAL DEATHS. IF THEY'RE SMARTER
  SHOULDN'T THEY BE RESPONDING LESS TO LOCAL INFO BECAUSE THEY READ THE NYT? MAYBE THEY JUST RESPOND MORE TO TOTAL DEATHS*/
 *xtpoisson R`TYPE'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty outofstate L1outofstate stateunemp countyunemp, fe exposure(avgcountypop) vce(robust)
 *outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty outofstate L1outofstate stateunemp countyunemp  using ./Output/highqualitybytypePX.txt, ct(`file'`TYPE') bdec(3) tdec(3) bracket se append
}


STOP
/****************************************************************************************/
/*(7) DEATHS OF DIFFERENT WARS*/

/*CURRENT*/
xtpoisson active IRAQmonthcountydeath AFGHANmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test IRAQmonthcountydeath=AFGHANmonthcountydeath
outreg2  IRAQmonthcountydeath AFGHANmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPwar.txt, ct(`file'Race current only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), " Test", r(p))

/*LAGGED*/
xtpoisson active monthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1IRAQmonthcountydeath=L1AFGHANmonthcountydeath
outreg2  monthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/redefPwar.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p))

/*BOTH*/
xtpoisson active IRAQmonthcountydeath AFGHANmonthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test IRAQmonthcountydeath=AFGHANmonthcountydeath
local current=r(p)
test L1IRAQmonthcountydeath=L1AFGHANmonthcountydeath
outreg2  IRAQmonthcountydeath AFGHANmonthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPwar.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p), "Current", `current')

/*IN AND OUT OF COUNTY*/
xtpoisson active monthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty L1IRAQoutofcounty L1AFGHANoutofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1IRAQmonthcountydeath=L1AFGHANmonthcountydeath
local county=r(p)
test L1IRAQoutofcounty=L1AFGHANoutofcounty
outreg2  monthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty L1IRAQoutofcounty L1AFGHANoutofcounty stateunemp countyunemp using ./Output/redefPwar.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "State", r(p), "County", `county')


*ADDED 2015/2/18--TEST INTERACTIONS WITH AFGHAN AND IRAQ, SINCE THAT'S INTERESTING TO A LOT OF PEOPLE
/*REGS WITH INTERACTIONS*/
/*REWORK INTERACTION VARIABLES*/

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
 gen `type'deathcountypopIRAQ=L1IRAQ`type'monthcountydeath/countypopZ
 gen `type'deathcountypopAFGHAN=L1AFGHAN`type'monthcountydeath/countypopZ
 gen `type'deathOOCcountypopIRAQ=L1IRAQ`type'outofcounty/countypopZ
 gen `type'deathOOCcountypopAFGHAN=L1AFGHAN`type'outofcounty/countypopZ 
 //*1000 here would make the coefficient less ridiculous, but it makes sense either way.
  
 *bysort fips: egen avgcountyunemp=mean(countyunemp) //Don't use. Calculate the county unemployment interaction using the unemployment in the month
 //of each death, not just the average unemployment in the county across time.
 
 foreach var in /*avg*/countyunemp PctBlack05 PctBush04 /*avgcov*/{
  quietly summ `var' [aweight=countypop] //calculate the weighted average of the interaction characteristics
  quietly cap gen avg`var'=r(mean) //make that weighted average a variable
  quietly cap gen `var'Z=`var'-avg`var' //calculate the above-averageness of the characteristic
  foreach type in IRAQ AFGHAN{
   quietly gen death`var'`type'=L1`type'monthcountydeath*`var'Z //Interact the death/100 with the above-averageness of the characteristic
   quietly gen deathOOC`var'`type'=L1`type'outofcounty*`var'Z 
  } 
 } /*END MULTIPLE INTERACTION VARS*/ 

 *interact deaths separately by ware an characteristic. Only in-county deaths
 xtpoisson active monthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty L1outofcounty /*took out avg*/deathcountyunempIRAQ deathcountyunempAFGHAN deathcountypopIRAQ deathcountypopAFGHAN deathPctBlack05IRAQ deathPctBlack05AFGHAN deathPctBush04IRAQ deathPctBush04AFGHAN /*no rural*/ stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust)
 *outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathavgcountyunemp deathcountypop deathPctBlack05 deathPctBush04 deathRural2 stateunemp countyunemp  using ./Output/redefPinteractions.txt, ct(black) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

 *in and out of county deaths interacted
 xtpoisson active monthcountydeath L1IRAQmonthcountydeath L1AFGHANmonthcountydeath outofcounty L1IRAQoutofcounty L1AFGHANoutofcounty deathcountyunempIRAQ deathcountyunempAFGHAN deathcountypopIRAQ deathcountypopAFGHAN deathPctBlack05IRAQ deathPctBlack05AFGHAN deathPctBush04IRAQ deathPctBush04AFGHAN deathOOCcountyunempIRAQ deathOOCcountyunempAFGHAN deathOOCcountypopIRAQ deathOOCcountypopAFGHAN deathOOCPctBlack05IRAQ deathOOCPctBlack05AFGHAN deathOOCPctBush04IRAQ deathOOCPctBush04AFGHAN /*no rural*/ stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust)

 *test only afghan deaths and interactions
 xtpoisson active AFGHANmonthcountydeath L1AFGHANmonthcountydeath AFGHANoutofcounty L1AFGHANoutofcounty /*took out avg*/deathcountyunempAFGHAN deathcountypopAFGHAN deathPctBlack05AFGHAN deathPctBush04AFGHAN /*no rural*/ stateunemp countyunemp monthfe3-monthfe58, fe exposure(countypop) vce(robust)

} /*END OF HUGE LOOP OVER BOTH APP AND CON FILES*/

*****************************************************************************
*****************************************************************************
/*OLD STUFF I'VE TESTED THAT'S TOO MUCH
/*(1)RECRUITS OF DIFFERENT SERVICES--OLS*/
foreach service in AR FR MR NR{
 gen LN`service'monthcounty=ln(`service'monthcounty)
 reghdfe LN`service'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51 [aweight=avgcountypop], robust cluster(fips) absorb(fips)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/highqualitybyserviceLN.txt, ct(`file'`service'recs) bdec(3) tdec(3) bracket se append
}
/*RECRUITS OF DIFFERENT SERVICES--POISSON*/
foreach service in AR FR MR NR{
 xtpoisson `service'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 estimates store `service'
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/highqualitybyserviceP.txt, ct(`file'`service'recs) bdec(3) tdec(3) bracket se append
}
*/
/*(3)DEATHS OF DIFFERENT SERVICES--POISSON*/
/*FIRST RESIZE AND GEN LAGS FOR ALL TYPES OF DIFFERENT DEATHS*/
/*sort fips month
foreach type in AR FR MR NR WHITE BLACK HISP OTH H notH FEMALE MALE IRAQ AFGHAN {
 foreach var in monthcountydeath outofcounty{
  quietly gen L1`type'`var'=`type'`var'[_n-1]/100 if fips[_n]==fips[_n-1]
  quietly replace `type'`var'=`type'`var'/100
 } 
}
*/

/*
/*ONLY LOCAL SPLIT OUT*/
xtpoisson active monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1outofcounty stateunemp countyunemp  using ./Output/redefbyservicedeath.txt, ct(`file'servicedeath) bdec(3) tdec(3) bracket se adds("Test Lag County Deaths", r(p)) append

/*LOCAL AND STATE SPLIT OUT*/
xtpoisson active monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1ARoutofcounty L1FRoutofcounty L1MRoutofcounty L1NRoutofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1ARoutofcounty=L1FRoutofcounty=L1MRoutofcounty=L1NRoutofcounty
local LagState=r(p)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1ARoutofcounty L1FRoutofcounty L1MRoutofcounty L1NRoutofcounty stateunemp countyunemp  using ./Output/redefbyservicedeath.txt, ct(`file'wstate) bdec(3) tdec(3) bracket se adds("Test Lag County Deaths", r(p), "Test Lag State", `LagState') append

/****************************************************************************/
/*(4) DEATHS OF DIFFERENT RACES*/

/*CURRENT*/
xtpoisson active WHITEmonthcountydeath BLACKmonthcountydeath HISPmonthcountydeath OTHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test WHITEmonthcountydeath=BLACKmonthcountydeath=HISPmonthcountydeath=OTHmonthcountydeath
outreg2  WHITEmonthcountydeath BLACKmonthcountydeath HISPmonthcountydeath OTHmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPrace.txt, ct(`file'Race current only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), " Test", r(p))

/*LAGGED*/
xtpoisson active L1WHITEmonthcountydeath L1BLACKmonthcountydeath L1HISPmonthcountydeath L1OTHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1WHITEmonthcountydeath=L1BLACKmonthcountydeath=L1HISPmonthcountydeath=L1OTHmonthcountydeath
*outreg2  L1WHITEmonthcountydeath L1BLACKmonthcountydeath L1HISPmonthcountydeath L1OTHmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPrace.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p))

/*BOTH*/
xtpoisson active WHITEmonthcountydeath BLACKmonthcountydeath HISPmonthcountydeath OTHmonthcountydeath L1WHITEmonthcountydeath L1BLACKmonthcountydeath L1HISPmonthcountydeath L1OTHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test WHITEmonthcountydeath=BLACKmonthcountydeath=HISPmonthcountydeath=OTHmonthcountydeath
local current=r(p)
test L1WHITEmonthcountydeath=L1BLACKmonthcountydeath=L1HISPmonthcountydeath=L1OTHmonthcountydeath
outreg2  WHITEmonthcountydeath BLACKmonthcountydeath HISPmonthcountydeath OTHmonthcountydeath L1WHITEmonthcountydeath L1BLACKmonthcountydeath L1HISPmonthcountydeath L1OTHmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPrace.txt, ct(`file'Race both) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p), "Current", `current')

/**************************************************************************************/
/*4(A). INTERACT RACE OF DEATH WITH COUNTY FRACTION BLACK*/
/*REWORK INTERACTION VARIABLES*/
replace PctWhite05=PctWhite05/100
replace PctBlack05=PctBlack05/100
/*GEN INTERACTIONS*/
 gen countypop=age1824_male/1000
 summ countypop [aweight=countypop]
 cap gen avgcountypop=r(mean)
 foreach var in PctBlack05 PctBush04 PctKerry04{
  quietly summ `var' [aweight=countypop]
  quietly gen avg`var'=r(mean)
  quietly gen `var'Z=`var'-avg`var'
  quietly gen WHITEdeath`var'=L1WHITEmonthcountydeath*`var'Z
  quietly gen BLACKdeath`var'=L1BLACKmonthcountydeath*`var'Z
 } /*END MULTIPLE INTERACTION VARS*/ 
 
/*DO BLACKS REACT DIFFERENTLY TO BLACK DEATHS?*/ 
xtpoisson active L1WHITEmonthcountydeath L1BLACKmonthcountydeath WHITEdeathPctBlack05 BLACKdeathPctBlack05 L1HISPmonthcountydeath L1OTHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)

/*************************************************************************************/
/*(5) DEATHS OF DIFFERENT HOSTILITY STATUS*/

/*CURRENT*/
xtpoisson active Hmonthcountydeath notHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test Hmonthcountydeath=notHmonthcountydeath
outreg2  Hmonthcountydeath notHmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPhostile.txt, ct(`file'Race current only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), " Test", r(p))

/*LAGGED*/
xtpoisson active L1Hmonthcountydeath L1notHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1Hmonthcountydeath=L1notHmonthcountydeath
outreg2  L1Hmonthcountydeath L1notHmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPhostile.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p))

/*BOTH*/
xtpoisson active Hmonthcountydeath notHmonthcountydeath L1Hmonthcountydeath L1notHmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test Hmonthcountydeath=notHmonthcountydeath
local current=r(p)
test L1Hmonthcountydeath=L1notHmonthcountydeath
outreg2  Hmonthcountydeath notHmonthcountydeath L1Hmonthcountydeath L1notHmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPhostile.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p), "Current", `current')

/*************************************************************************************/
/*(6) DEATHS OF DIFFERENT GENDER*/

/*CURRENT*/
xtpoisson active FEMALEmonthcountydeath MALEmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test FEMALEmonthcountydeath=MALEmonthcountydeath
outreg2  FEMALEmonthcountydeath MALEmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPgender.txt, ct(`file'Race current only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), " Test", r(p))

/*LAGGED*/
xtpoisson active L1FEMALEmonthcountydeath L1MALEmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1FEMALEmonthcountydeath=L1MALEmonthcountydeath
outreg2  L1FEMALEmonthcountydeath L1MALEmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPgender.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p))

/*BOTH*/
xtpoisson active FEMALEmonthcountydeath MALEmonthcountydeath L1FEMALEmonthcountydeath L1MALEmonthcountydeath outofcounty stateunemp countyunemp monthfe3-monthfe33 statetrend1-statetrend51, fe exposure(avgcountypop) vce(robust)
test FEMALEmonthcountydeath=MALEmonthcountydeath
local current=r(p)
test L1FEMALEmonthcountydeath=L1MALEmonthcountydeath
outreg2  FEMALEmonthcountydeath MALEmonthcountydeath L1FEMALEmonthcountydeath L1MALEmonthcountydeath outofcounty stateunemp countyunemp using ./Output/redefPgender.txt, ct(`file'Race lag only) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "Test", r(p), "Current", `current')


/*GENERATE ACTIVE DUTY ONLY VARIABLES*/
gen Rmonthcounty=ARmonthcounty+FRmonthcounty+MRmonthcounty+NRmonthcounty
gen RLQmonthcounty=ARLQmonthcounty+FRLQmonthcounty+MRLQmonthcounty+NRLQmonthcounty
gen RHQ50monthcounty=ARHQ50monthcounty+FRHQ50monthcounty+MRHQ50monthcounty+NRHQ50monthcounty
gen RHQ50altmonthcounty=ARHQ50altmonthcounty+FRHQ50altmonthcounty+MRHQ50altmonthcounty+NRHQ50altmonthcounty
gen RHQ75monthcounty=ARHQ75monthcounty+FRHQ75monthcounty+MRHQ75monthcounty+NRHQ75monthcounty
*/
