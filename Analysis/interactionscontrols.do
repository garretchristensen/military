cd $dir
set more off
cap log close
log using ./Logs/interactionscontrols.log, replace
cap rm ./Output/LNcontrolWR.tex
cap rm ./Output/LNcontrolW.tex
cap rm ./Output/LNcontrolWR.txt
cap rm ./Output/LNcontrolW.txt
cap rm ./Output/LNinteractALL.txt
cap rm ./Output/LNinteractCOMBINE.txt
cap rm ./Output/LNinteractALL.tex
cap rm ./Output/LNinteractCOMBINE.tex

clear all

foreach file in APP CON{ /*BEGIN HUGE LOOP OVER BOTH FILES*/
if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}

use ./Data/county`file'_raw.dta, clear

/*MERGE IN STATE AND NATION POPULATION DATA*/
merge m:1 statefips using ./Population/statenationyoungmalepop.dta
drop if _merge!=3 /*WHO ARE THESE 33 FUCKERS, AND WHERE DID THEY COME FROM?*/
rename _merge mergestatepop

/*CREATE POP VARIABLES FOR STATE, AND NATION*/
rename age1824_male countypopmonth
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


**********
*Do all generating *before* resizing
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

/*RUN REGRESSIONS WITH INTERACTIONS. MONTHLY FE. CALC ELASTICITIES, THEN REDO WITH WEIGHTS*/
/*DO POP FIRST SINCE INVERSE*/
 summ countypopmonth /*calc average of county populations*/
	/*doesn't matter whether you use this or avgcountypop, which is avg'd by fips already*/
 local avgcountypop=r(mean)
 gen countypopZ=countypop-`avgcountypop' //subtract off mean
 gen deathcountypop=L1monthcountydeath/countypopZ //create interaction

/*ALL THE REST OF THE INTERACTIONS INDIVIDUALLLY*/
foreach var in countyunemp PctBlack05 PctH05 PctAsian05 RaceFracH RaceFrac Farming FarmMine Manufacturing Government ///
	Services HouseStrs04 LowEduc04 LowEmp04 PerstPov04 PopLoss04 NonmetRec04 Retirement04 UrbanInf03 UrbanInfluence ///
	RuralUrban03 Rural Rural2 CA05N0035_05 CA05N0030_05 PctBush04 PctKerry04{
 summ `var' [aweight=avgcountypop]
 gen avg`var'=r(mean)
 gen `var'Z=`var'-avg`var'
 summ `var'Z
 gen death`var'=L1monthcountydeath*`var'Z
}
label var deathcountyunemp "Lag County Death*County Unemployment"
label var deathcountypop "Lag County Death/County Population"
label var deathPctBlack05 "Lag County Death*%Black Population"
label var deathPctBush04 "Lag County Death*%George Bush Vote"
label var deathRural2 "Lag County Death*Rural"

*RESIZE DEATHS
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


/*TEST WITH RECRUITER CONTROLS AND STUFF*/
tostring qtr, replace
tostring year, replace
gen yearqtr=year+qtr
destring yearqtr, replace
gen totalrec=(arec+mrec+frec+nrec)/100 if yearqtr <=20042
label var totalrec "Military Recruiter by State"
gen outofcountymort=monthstatemort-monthcountymort
label var outofcountymort "Out-of-County Mortality Rate"
gen L1outofcountymort=L1monthstatemort-L1monthcountymort
label var L1outofcountymort "Lag Out-of-County Mortality Rate"
label var L1monthcountymort "Lag County Mortality Rate"

foreach type in "" R { /*DO WITH BOTH ACTIVE AND TOTAL DEATHS*/
reghdfe LNactive `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp ///
	countyunemp [aweight=avgcountypop] if yearqtr<=20042&totalrec!=.&L1monthcountymort!=.&L1outofcountymort!=., ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNcontrolW`type'.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append  ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first four columns show applicants and the last three show contracts.", Filename:LNcontrolW`type'.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

reghdfe LNactive `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp ///
	countyunemp totalrec L1monthcountymort L1outofcountymort [aweight=avgcountypop] ///
	if yearqtr<=20042&totalrec!=.&L1monthcountymort!=.&L1outofcountymort!=., ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNcontrolW`type'.txt, lab tex ct(`header') bdec(3) tdec(3) ///
	bracket se append addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
} 

*INTERACTIONS ONE AT A TIME**********************************
/*WEIGHTED*/
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathcountypop stateunemp ///
	countyunemp [aweight=avgcountypop], absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNinteractALL.txt, lab ct(`header', pop) ti(OLS Weighted Interactions) ///
	tex bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first three columns show applicants and the last three show contracts.", Filename:LNinteractALL.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)

 /*WEIGHTED*/
 /*INTERACTION REGRESSION*/
foreach var in countyunemp PctBlack05 PctH05 PctAsian05 RaceFracH RaceFrac Farming FarmMine Manufacturing Government ///
	Services HouseStrs04 LowEduc04 LowEmp04 PerstPov04 PopLoss04 NonmetRec04 Retirement04 UrbanInf03 UrbanInfluence ///
	RuralUrban03 Rural Rural2 CA05N0035_05 CA05N0030_05 PctBush04 PctKerry04{
 reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty death`var' stateunemp countyunemp ///
	[aweight=avgcountypop], absorb(fips month) vce(cluster fips)
 outreg2 using	./Output/LNinteractALL.txt, tex lab ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
}


*INTERACTIONS COMBINED**********************************
reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty /*took out avg*/deathcountyunemp ///
	deathcountypop deathPctBlack05 deathPctBush04 /*deathavgcov*/ deathRural2 stateunemp countyunemp [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips)
outreg2 using ./Output/LNinteractCOMBINE.txt, ct(`header') bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO) tex lab ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first three columns show applicants and the last three show contracts.", Filename:LNinteractCOMBINE.tex) ///


/**************************************/
/*DO THE ABOVE BUT WITH ONLY ACTIVE DEATHS--JUNE 2016--LEAVE OUT
/*RUN REGRESSIONS WITH INTERACTIONS. MONTHLY FE. CALC ELASTICITIES, THEN REDO WITH WEIGHTS*/
/*DO POP FIRST SINCE INVERSE*/
/*DO POP FIRST SINCE INVERSE*/
 summ countypopmonth /*calc average of county populations*/
	/*doesn't matter whether you use this or avgcountypop, which is avg'd by fips already*/
 local avgcountypop=r(mean)
 gen countypopZ=countypop-`avgcountypop' //subtract off mean
 gen Rdeathcountypop=L1Rmonthcountydeath/countypopZ //create interaction

/*WEIGHTED*/
reghdfe LNactive Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeathcountypop ///
	stateunemp countyunemp monthfe1-monthfe56 [aweight=avgcountypop], absorb(fips month) vce(cluster fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeathpop using ./Output/redefinteractionsRW.txt, ///
	ct(`file'pop) ti(OLS Weighted Interactions ACTIVE Deaths) addnote(redefinteractionsRW.txt EML) ///
	bdec(3) tdec(3) bracket se append 

/*ALL THE REST OF THE INTERACTIONS 4 WAYS*/
foreach var in countyunemp PctBlack05 PctH05 PctAsian05 RaceFracH RaceFrac Farming FarmMine Manufacturing ///
	Government Services HouseStrs04 LowEduc04 LowEmp04 PerstPov04 PopLoss04 NonmetRec04 Retirement04 UrbanInf03 ///
	UrbanInfluence RuralUrban03 Rural Rural2 CA05N0035_05 CA05N0030_05 PctBush04 PctKerry04{
 gen Rdeath`var'=L1Rmonthcountydeath*`var'Z
 /*WEIGHTED*/
 /*INTERACTION REGRESSION*/
 reghdfe LNactive Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeath`var' stateunemp ///
	countyunemp [aweight=avgcountypop], absorb(fips month) vce(cluster fips)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeath`var' using ///
	./Output/redefinteractionsRW.txt, ct(`var') bdec(3) tdec(3) bracket se append 
}
END OF "R" SECTION */ 
} /*END HUGE LOOP OVER APP & CON*/
