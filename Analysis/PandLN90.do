cd $dir
cap log close
log using ./Logs/redef90PandLN.log, replace

/*HAVE TO KEEP THIS FILE MANAGEMENT UP HERE, OUTSIDE THE APP/CON LOOP*/
*cap rm ./Output/redefPinteractions.txt
*cap rm ./Output/redefPinteractionsR.txt
*cap rm ./Output/redefPrec.txt
*cap rm ./Output/redefPrecR.txt
*cap rm ./Output/redefPrace.txt
 cap rm ./Output/redefPbasic90`type'.txt
*cap rm ./Output/allrecPbasic`type'.txt
*cap rm ./Output/forwardPbasic.txt
*cap rm ./Output/allrec_forwardPbasic.txt
 
clear all
*set maxvar 32767
set matsize 800
set maxiter 30
set more off

foreach file in county90 countyCON90 {   /*BEGIN HUGE LOOP OVER BOTH FILES*/


/*REPLACE DEATHS BY /100 SO THAT ESTIMATES ARE EASY TO READ/INTERPRET*/
foreach var in monthcountydeath Rmonthcountydeath outofcounty Routofcounty outofstate Routofstate monthstatemort monthcountymort{
 foreach lag in F12 F11 F10 F9 F8 F7 F6 F5 F4 F3 F2 F1 "" L1 L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12 {
  foreach poly in "" SQ{
   quietly replace `lag'`var'`poly'=`lag'`var'`poly'/100
  }
 }
} 





/*MAIN POISSON TABLE*/


*disp "HORSE RACE BTW DEATH TYPES%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
*xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate, fe exposure(countypop) vce(robust)
*outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty `type'outofstate L1`type'outofstate using ./Output/redefPbasic`type'.txt, ct(`file'`type'HORSERACE) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "BASIC%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath monthfe3-monthfe199, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath using ./Output/redefPbasic90`type'.txt, ct(`file'`type'Basic) addnote(redefPbasic90`type'.txt) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe3-monthfe199 , fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/redefPbasic90`type'.txt, ct(w/State) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))

disp "BASIC if month>=200110%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath monthfe143-monthfe199 if month>=200110, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath using ./Output/redefPbasic90`type'.txt, ct(`file'`type'Basic01-06) append bdec(3) tdec(3) bracket se addstat(Likelihood, e(ll))

disp "OUT OF COUNTY if month>=200110%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
xtpoisson active `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp monthfe143-monthfe199 if month>=200110, fe exposure(countypop) vce(robust)
outreg2 `type'monthcountydeath L1`type'monthcountydeath `type'outofcounty L1`type'outofcounty stateunemp countyunemp using ./Output/redefPbasic90`type'.txt, ct(w/State01-06) bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll))


} /*END OF APP AND CON*/


