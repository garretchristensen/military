/* (1) FIT THE STATE PERCENTAGE OF RECRUITS TO STATE PERCENTAGE OF DEATHS*/


clear all
set more off
cd $dir
use ./Deaths/raw/table1graph.dta, clear //Sadly, I can't find the file that builds this dataset from scratch.

drop if fips==.
/*******************************************************/
/***DEATHS AND RECRUITS. SLOPE==1, HOPEFULLY***********/
/******************************************************/
scatter percentofdeaths percentofrecruits, xtitle("Percent of Recruits") mlabel(state) || lfit percentofdeaths percentofrecruits [aweight=youngmalepop], legend(label(2 "Fitted Slope=1.01") label(3 "Slope=1")) ||lfit percentofrecruits percentofrecruits, lpattern(dash)
graph export ./Output/graph_table1_death_rec.png, replace
reg percentofdeaths percentofrecruits 
test _b[percentofrecruits]=1
estat hettest
/*HAS HETERO, RUN ROBUST*/
reg percentofdeaths percentofrecruits, robust 
test _b[percentofrecruits]=1
/*OBSERVATIONS ARE AVERAGES FROM AGG DATA, USE POP WEIGHTS*/
reg percentofdeaths percentofrecruits [aweight=youngmalepop], robust 
test _b[percentofrecruits]=1
/*LIMIT TO SMALL COUNTIES-SHACHAR*/
reg percentofdeaths percentofrecruits [aweight=youngmalepop] if percentofrecruits<3, robust 
test _b[percentofrecruits]=1


/*******************************************************/
/***DEATHS AND POPULATION. SLOPE!=1, HOPEFULLY*********/
/******************************************************/
gen percentpop=(youngmalepop/14400000)*100
label var percentpop "Percent of Young Male Population"
scatter percentofdeaths percentpop, xtitle("Percent of Population") ytitle("Percent of Deaths") title("Deaths and Population by State") mlabel(state) || lfit percentofdeaths percentpop [aweight=youngmalepop], legend(label(2 "Fitted Slope=0.85")label(3 "Slope=1"))||lfit percentofrecruits percentofrecruits, lpattern(dash)
graph export ./Output/graph_table1_death_pop.png, replace
reg percentofdeaths percentpop
test _b[percentpop]=1
estat hettest
/*HAS HETERO, RUN ROBUST*/
reg percentofdeaths percentpop, robust
test _b[percentpop]=1
/*OBSERVATIONS ARE AVERAGES FROM AGG DATA, USE POP WEIGHTS*/
reg percentofdeaths percentpop [aweight=youngmalepop], robust 
test _b[percentpop]=1


/*******************************************************/
/***RECRUITS AND POPULATION. SLOPE!=1, HOPEFULLY*********/
/******************************************************/
scatter percentofrecruits percentpop, xtitle("Percent of Population") ytitle("Percent of Recruits") title("Recruits and Population by State") mlabel(state) ||lfit percentofrecruits percentpop [aweight=youngmalepop], legend(label(2 "Fitted Slope=0.80")label(3 "Slope=1"))||lfit percentofrecruits percentofrecruits, lpattern(dash)
graph export ./Output/graph_table1_rec_pop.png, replace
reg percentofrecruits percentpop
test _b[percentpop]=1
estat hettest
/*HAS HETERO, RUN ROBUST*/
reg percentofrecruits percentpop, robust
test _b[percentpop]=1
/*OBSERVATIONS ARE AVERAGES FROM AGG DATA, USE POP WEIGHTS*/
reg percentofrecruits percentpop [aweight=youngmalepop], robust 
test _b[percentpop]=1

corr percentpop percentofdeaths percentofrecruits
corr percentpop percentofdeaths percentofrecruits [aweight=youngmalepop]

/*****************************************************/
/* PAT'S THING. JUST TEST HOW WELL THEY FIT TO A BINOMIAL DISTRIBUTION*/
/****************************************************/
/*ACTIVE DEATHS ACTIVE APPS*/
destring deaths, replace
egen sumactivedeaths=sum(activedeaths)
egen sumactiveapps=sum(stateactiveapps)
disp "Average Rate of Death "sumactivedeaths/sumactiveapps
gen WorstP=.

foreach X of numlist 1/51{
bitesti stateactiveapps[`X'] activedeaths[`X'] .0027603, detail
replace WorstP=r(p) in `X'
}
summ WorstP
label var WorstP "State P-Value"
histogram WorstP, addl width(.01) frequency ti(Active-Duty Deaths and Applicants)
graph save ./Output/hist_state_binomial.gph, replace

/*ACTIVE DEATHS ACTIVE CONS*/
egen sumactivecons=sum(stateactivecons)
foreach X of numlist 1/51{
bitesti stateactivecons[`X'] activedeaths[`X'] sumactivedeaths/sumactivecons, detail
replace WorstP=r(p) in `X'
}
summ WorstP
label var WorstP "State P-Value"
histogram WorstP, addl width(.01) frequency ti(Active-Duty Deaths and Contracts)
graph save ./Output/hist_state_binomialcon.gph, replace


/*********************************************************/
/** ALL STATES ARE CLEARLY NOT THE SAME. JUST SHOW THE DISPERSION OF THE HAZARD RATE ISN'T CRAZY*/
/* DO FOR ALL RECS & DEATHS AND ACTIVE ONLY*/
/**********************************************************/


/*ACTIVE ACTIVE APPS*/
gen hazard_aaa=activedeaths/stateactiveapps
summ hazard_aaa
disp "Active Deaths/Active Apps " r(sd)/r(mean)
summ hazard_aaa [aweight=percentpop]
disp "Active Deaths/Active Apps WEIGHTED " r(sd)/r(mean)
label var hazard_aaa "Active Deaths/Active Applicants"
histogram hazard_aaa, addl frequency //title("Hazard Rate by State")
graph save ./Output/hist_state_aaa.gph, replace
/*TOTAL ACTIVE APPS*/
gen hazard_taa=deaths/stateactiveapps
summ hazard_taa
disp "Total Deaths/Active Apps "r(sd)/r(mean)
summ hazard_taa [aweight=percentpop]
disp "Total Deaths/Active Apps WEIGHTED "r(sd)/r(mean)
label var hazard_taa "Total Deaths/Active Applicants"
histogram hazard_taa, addl frequency //title("Hazard Rate by State")
graph save ./Output/hist_state_taa.gph, replace
/*ACTIVE ACTIVE CON*/
gen hazard_aac=activedeaths/stateactivecons
summ hazard_aac
disp "Active Deaths/Active Cons "r(sd)/r(mean)
summ hazard_aac [aweight=percentpop]
disp "Active Deaths/Active Cons WEIGHTED "r(sd)/r(mean)
label var hazard_aac "Active Deaths/Active Contracts"
histogram hazard_aac, addl frequency //title("Hazard Rate by State")
graph save ./Output/hist_state_aac.gph, replace
/*TOTAL ACTIVE CON*/
gen hazard_tac=deaths/stateactivecons
summ hazard_tac
disp "Total Deaths/Active Cons "r(sd)/r(mean)
summ hazard_tac [aweight=percentpop]
disp "Total Deaths/Active Cons WEIGHTED "r(sd)/r(mean)
label var hazard_tac "Total Deaths/Active Contracts"
histogram hazard_tac, addl frequency //title("Hazard Rate by State")
graph save ./Output/hist_state_tac.gph, replace

***COMBINE ALL 4 GRAPHS***
graph combine ./Output/hist_state_aaa.gph ./Output/hist_state_taa.gph ./Output/hist_state_aac.gph ///
	./Output/hist_state_tac.gph, title("Death Hazard Rate by State") saving(./Output/hist_state_combined.gph, replace) 
graph export ./Output/hist_state_combined.png, replace

/* (2) SIMPLE GRAPH OF DEATHS AGAINST RECRUITS OVER TIME*/
use ./Apps/APP_bydate2000.dta, clear
sort date
merge 1:1 date using ./Deaths/deathsbydate

/*KEEP ONLY THE DATES FOR WHICH I HAVE RECRUIT NUMBERS*/
drop if date<20011000|date>20060800
tostring date, gen(month)
replace month=substr(month,1,6)
gen mo=substr(month,5,2)
destring mo, replace
tostring date, gen(year)
replace year=substr(year,1,4)
destring year, replace
/*COLLAPSE DEATHS BY MONTH*/
bysort month: egen monthdeathUS=total(totalUS)
bysort month: egen monthdeathtotal=total(totaldeaths)
bysort month: egen monthapptotal=total(totapp)
bysort month: egen monthARtotal=total(AR)
count
duplicates drop month, force
count
/*GRAPH RECRUITS AND DEATHS BY MONTH*/
keep month year mo type month*
save ./Deaths/deathsbymonth, replace
generate fancymonth=ym(year,mo)
destring fancymonth, replace
format fancymonth %tm
sort fancymonth
label var fancymonth "Year and Month"
label var monthdeathtotal "US Deaths in Iraq/Afghanistan"
label var monthapptotal "Applicants to Military"
graph twoway (line monthdeathtotal fancymonth, yaxis(1) lpattern(dash))(line monthapptotal fancymonth, yaxis(2))
graph export ./Output/graph_deathsvsrecruits_basic.png, replace
