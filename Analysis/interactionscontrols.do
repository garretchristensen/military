cd $dir
set more off
cap log close
log using ./Logs/interactionscontrols.log, replace
cap rm ./Output/LNcontrolWR.tex
cap rm ./Output/LNcontrolW.tex

cap rm ./Output/redefinteractionselast.txt
cap rm ./Output/redefinteractionsW.txt
cap rm ./Output/redefinteractionselastW.txt
cap rm ./Output/redefinteractionsR.txt
cap rm ./Output/redefinteractionselastR.txt
cap rm ./Output/redefinteractionsRW.txt
cap rm ./Output/redefinteractionselastRW.txt
clear all


foreach file in APP CON{ /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Data/county`file'_raw.dta, clear

/*MERGE IN STATE AND NATION POPULATION DATA*/
merge m:1 statefips using ./Population/statenationyoungmalepop.dta
drop if _merge!=3 /*WHO ARE THESE 33 FUCKERS, AND WHERE DID THEY COME FROM?*/
rename _merge mergestatepop

/*CREATE POPULATION VARIABLES FOR COUNTY, STATE, AND NATION*/
bysort fips:egen countypop=mean(age1824_male)
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


/*TEST WITH RECRUITER CONTROLS AND STUFF*/
tostring qtr, replace
tostring year, replace
gen yearqtr=year+qtr
destring yearqtr, replace
gen totalrec=(arec+mrec+frec+nrec)/100 if yearqtr <=20042
gen outofcountymort=monthstatemort-monthcountymort
gen L1outofcountymort=L1monthstatemort-L1monthcountymort


foreach type in "" R { /*DO WITH BOTH ACTIVE AND TOTAL DEATHS*/
reghdfe LNactive `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp ///
	countyunemp if yearqtr<=20042&totalrec!=.&L1monthcountymort!=.&L1outofcountymort!=., ///
	absorb(fips month) vce(cluster fips)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp ///
	using ./Output/LNcontrolW`type'.tex, ct(`file'NoRec`type') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

reghdfe LNactive `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp ///
	countyunemp totalrec L1monthcountymort L1outofcountymort if yearqtr<=20042, ///
	absorb(fips month) vce(cluster fips)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp ///
	totalrec L1monthcountymort L1outofcountymort using ./Output/LNcontrolW`type'.tex, ct(`file'RecMort`type') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))
} 


stop

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
/*UNWEIGHTED*/
gen deathpop=L1monthcountydeath/countypop
areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathpop stateunemp countyunemp monthfe1-monthfe56, absorb(fips) robust cluster(fips)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathpop using ./Output/redefinteractions.txt, ct(`file'pop) ti(OLS with interacations) addnote(redefinteractions.txt EML) bdec(3) tdec(3) bracket se append
margins, eydx(L1monthcountydeath deathpop) atmeans post
outreg2 L1monthcountydeath death`var' using ./Output/redefinteractionselast.txt, ct(`file'pop) ti(Partial-Elasticity interacations) addnote(redefinteractionselast.txt EML) bdec(3) tdec(3) bracket se append  
/*WEIGHTED*/
areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathpop stateunemp countyunemp monthfe1-monthfe56 [aweight=countypop], absorb(fips) robust cluster(fips)
outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty deathpop using ./Output/redefinteractionsW.txt, ct(`file'pop) ti(OLS Weighted Interactions) addnote(redefinteractionsW.txt EML) bdec(3) tdec(3) bracket se append 
margins, eydx(L1monthcountydeath deathpop) atmeans post
outreg2 L1monthcountydeath deathpop using ./Output/redefinteractionselastW.txt, ct(`file'pop) ti(Partial-Elasticity Weighted Interactions) addnote(redefinteractionselastW.txt EML) bdec(3) tdec(3) bracket se append  

/*ALL THE REST OF THE INTERACTIONS 4 WAYS*/
foreach var in countyunemp PctBlack05 PctH05 PctAsian05 RaceFracH RaceFrac Farming FarmMine Manufacturing Government Services HouseStrs04 LowEduc04 LowEmp04 PerstPov04 PopLoss04 NonmetRec04 Retirement04 UrbanInf03 UrbanInfluence RuralUrban03 Rural Rural2 CA05N0035_05 CA05N0030_05 PctBush04 PctKerry04{
 summ `var' [aweight=countypop]
 gen avg`var'=r(mean)
 gen `var'Z=`var'-avg`var'
 summ `var'Z
 gen death`var'=L1monthcountydeath*`var'Z
 /*UNWEIGHTED*/
 /*INTERACTION REGRESSION*/
 areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty death`var' stateunemp countyunemp monthfe1-monthfe56, absorb(fips) robust cluster(fips)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty death`var' using ./Output/redefinteractions.txt, ct(`var') bdec(3) tdec(3) bracket se append 
 /*ELAST*/
 margins, eydx(monthcountydeath L1monthcountydeath death`var') atmeans post
 outreg2 monthcountydeath L1monthcountydeath death`var' using ./Output/redefinteractionselast.txt, ct(`file'`var') bdec(3) tdec(3) bracket se append  
 /*WEIGHTED*/
 /*INTERACTION REGRESSION*/
 areg active monthcountydeath L1monthcountydeath outofcounty L1outofcounty death`var' stateunemp countyunemp monthfe1-monthfe56 [aweight=countypop], absorb(fips) robust cluster(fips)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty death`var' using ./Output/redefinteractionsW.txt, ct(`var') bdec(3) tdec(3) bracket se append 
 /*ELAST*/
 margins, eydx(monthcountydeath L1monthcountydeath death`var') atmeans post
 outreg2 monthcountydeath L1monthcountydeath death`var' using ./Output/redefinteractionselastW.txt, ct(`file'`var') bdec(3) tdec(3) bracket se append  
}


/**************************************/
/*DO THE ABOVE BUT WITH ONLY ACTIVE DEATHS*/
/*RUN REGRESSIONS WITH INTERACTIONS. MONTHLY FE. CALC ELASTICITIES, THEN REDO WITH WEIGHTS*/
/*DO POP FIRST SINCE INVERSE*/
/*UNWEIGHTED*/
gen Rdeathpop=L1Rmonthcountydeath/countypop
areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeathpop stateunemp countyunemp monthfe1-monthfe56, absorb(fips) robust cluster(fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeathpop using ./Output/redefinteractions.txt, ct(`file'pop) ti(OLS with interacations ACTIVE DEATHS) addnote(redefinteractionsR.txt EML) bdec(3) tdec(3) bracket se append
margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Rdeathpop) atmeans post
outreg2 Rmonthcountydeath L1Rmonthcountydeath Rdeathpop using ./Output/redefinteractionselast.txt, ct(`file'pop) ti(Partial-Elasticity interacations ACTIVEDEATHS) addnote(redefinteractionselastR.txt EML) bdec(3) tdec(3) bracket se append  
/*WEIGHTED*/
areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeathpop stateunemp countyunemp monthfe1-monthfe56 [aweight=countypop], absorb(fips) robust cluster(fips)
outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeathpop using ./Output/redefinteractionsRW.txt, ct(`file'pop) ti(OLS Weighted Interactions ACTIVE Deaths) addnote(redefinteractionsRW.txt EML) bdec(3) tdec(3) bracket se append 
margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Rdeathpop) atmeans post
outreg2 Rmonthcountydeath L1Rmonthcountydeath Rdeathpop using ./Output/redefinteractionselastRW.txt, ct(`file'pop) ti(Partial-Elasticity Weighted Interactions ACTIVE deaths) addnote(redefinteractionselastRW.txt EML) bdec(3) tdec(3) bracket se append  

/*ALL THE REST OF THE INTERACTIONS 4 WAYS*/
foreach var in countyunemp PctBlack05 PctH05 PctAsian05 RaceFracH RaceFrac Farming FarmMine Manufacturing Government Services HouseStrs04 LowEduc04 LowEmp04 PerstPov04 PopLoss04 NonmetRec04 Retirement04 UrbanInf03 UrbanInfluence RuralUrban03 Rural Rural2 CA05N0035_05 CA05N0030_05 PctBush04 PctKerry04{
 gen Rdeath`var'=L1Rmonthcountydeath*`var'Z
 /*UNWEIGHTED*/
 /*INTERACTION REGRESSION*/
 areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeath`var' stateunemp countyunemp monthfe1-monthfe56, absorb(fips) robust cluster(fips)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeath`var' using ./Output/redefinteractionsR.txt, ct(`var') bdec(3) tdec(3) bracket se append 
 /*ELAST*/
 margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Rdeath`var') atmeans post
 outreg2 Rmonthcountydeath L1Rmonthcountydeath Rdeath`var' using ./Output/redefinteractionselastR.txt, ct(`file'`var') bdec(3) tdec(3) bracket se append  
 /*WEIGHTED*/
 /*INTERACTION REGRESSION*/
 areg active Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeath`var' stateunemp countyunemp monthfe1-monthfe56 [aweight=countypop], absorb(fips) robust cluster(fips)
 outreg2 Rmonthcountydeath L1Rmonthcountydeath Routofcounty L1Routofcounty Rdeath`var' using ./Output/redefinteractionsRW.txt, ct(`var') bdec(3) tdec(3) bracket se append 
 /*ELAST*/
 margins, eydx(Rmonthcountydeath L1Rmonthcountydeath Rdeath`var') atmeans post
 outreg2 Rmonthcountydeath L1Rmonthcountydeath Rdeath`var' using ./Output/redefinteractionselastRW.txt, ct(`file'`var') bdec(3) tdec(3) bracket se append  
}

} /*END HUGE LOOP OVER APP & CON*/
