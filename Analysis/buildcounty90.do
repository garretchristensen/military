/*RUN REGRESSIONS BY COUNTY*/
/*RECRUITS ON TOTAL DEATHS, STATE DEATHS, COUNTY DEATHS, UNEMPLOYMENT*/
*2014.11.17 I am doing a second take on all deaths as a robustness check, but only for the 01-06 period
*If non-combat deaths have no effect, that's good for my hypothesis
*2014.11.27 We're going to keep the entire 1990-2006 data,
* and run 1990-2006 ALL DEATH regs, pluse
* 2001-2006 ALL DEATH data. Both show no effect.

clear all
set more off
cd $dir

cap log close
log using ./Logs/buildcounty90.smcl, replace

//HUGE ASS LOOP OVER BOTH APPS AND CON
foreach FILE in APP CON{

/*MERGE THE RECRUIT DATA WITH THE ZIP-CODE CROSSWALK*/
use ./Apps/`FILE'_all.dta, clear
drop if date>20060731 /*Must rebuild APPS so as to include 1990-2006 OBS*/
sort zip
count

merge m:1 zip using ./Apps/zip_crosswalk.dta /*This might be Dan's cross-walk*/
count
drop if _merge!=3 /*IS THERE A WAY TO MATCH MORE OF THE ZIPS!? LOSING 5% OF OBS*/
/*USING geocorr2kZIPCITY121212.dta only results in 368 more matched APPS*/


*Crosswalk doesn't include Puerto Rico.
*There are PR deaths, but they don't get merged in here, but all PR obs get dropped from the analysis
rename _merge ZIPmerge
tostring date, gen(month)
replace month=substr(month, 1, 6)
sort month

/*COLLAPSE RECUITS JUST BY MONTH*/
/*WHY HAVE I NEVER DONE THIS--THERE IS NEVER A MONTHTOTALRECRUIT (depvar?)*/
*
*
*
*
*
*
/*COLLAPSE RECRUITS BY MONTH & STATE*/
/*CREAT LEVELS OF RECRUITS: >50 AFQT AND GRADUATED HIGH SCHOOL*/
quietly bysort month stab: egen monthstaterecruit=count(zip)
quietly bysort month stab: egen monthstaterecruitLQ=count(zip) if afqt<50 |educ<31
quietly bysort month stab: egen monthstaterecruitHQ50=count(zip) if afqt>49 & educ>=31
quietly bysort month stab: egen monthstaterecruitHQ50alt=count(zip) if afqt>49 & (educ>=31|educ==13)
quietly bysort month stab: egen monthstaterecruitHQ75=count(zip) if afqt>74 & educ>=41
label var monthstaterecruit "Recruits in this month state"
label var monthstaterecruitLQ "Recruits-Low Quality in this month state"
label var monthstaterecruitHQ50 "Recruits-High Quality in this month state"
label var monthstaterecruitHQ50alt "Recruits-High Quality (Alt Def'n) in this month state"
label var monthstaterecruitHQ75 "Recruits-Very High Quality in this month state"



foreach var in AG AR AV CR CV FG FR FV MR MV NR NV {
  quietly gen `var'=0
  quietly gen `var'LQ=0 /*LOW QUALITY*/
  quietly gen `var'HQ50=0 /* AFQT >50, High School degree*/
  quietly gen `var'HQ50alt=0 /* AFQT 50+, Certificate*/
  quietly gen `var'HQ75=0 /*AFQT 75, some college*/
  quietly replace `var'=1 if unit=="`var'"
  quietly replace `var'LQ=1 if unit=="`var'" & (afqt<50 |educ<31)
  quietly replace `var'HQ50=1 if unit=="`var'" & afqt>49 & educ>=31
  quietly replace `var'HQ50alt=1 if unit=="`var'" & afqt>49 & (educ>=31|educ==13)
  quietly replace `var'HQ75=1 if unit=="`var'" & afqt>74 & educ>=41
  quietly bysort month stab: egen `var'monthstate=total(`var')
  quietly bysort month stab: egen `var'LQmonthstate=total(`var'LQ)
  quietly bysort month stab: egen `var'HQ50monthstate=total(`var'HQ50)
  quietly bysort month stab: egen `var'HQ50altmonthstate=total(`var'HQ50alt)
  quietly bysort month stab: egen `var'HQ75monthstate=total(`var'HQ75)
  drop `var' `var'LQ `var'HQ50 `var'HQ50alt `var'HQ75
  label var `var'monthstate "`var' Recruits in this month state"
  label var `var'LQmonthstate "`var' Recruits-Low Quality in this month state"
  label var `var'HQ50monthstate "`var' Recruits-High Quality in this month state"
  label var `var'HQ50altmonthstate "`var' Recruits-High Quality (Alt Def'n) in this month state"
  label var `var'HQ75monthstate "`var' Recruits-Very High Quality in this month state"
  compress
}
quietly gen monthstate=month+stab



/*COLLAPSE RECRUITS BY MONTH & COUNTY*/
quietly bysort month countyfp: egen monthcountyrecruit=count(zip)
quietly bysort month countyfp: egen monthcountyrecruitLQ=count(zip) if afqt<50 |educ<31
quietly bysort month countyfp: egen monthcountyrecruitHQ50=count(zip) if afqt>49 & educ>=31
quietly bysort month countyfp: egen monthcountyrecruitHQ50alt=count(zip) if afqt>49 & (educ>=31|educ==13)
quietly bysort month countyfp: egen monthcountyrecruitHQ75=count(zip) if afqt>74 & educ>=41
label var monthcountyrecruit "Recruits in this month county"
label var monthcountyrecruitLQ "Recruits-Low Quality in this month county"
label var monthcountyrecruitHQ50 "Recruits-High Quality in this month county"
label var monthcountyrecruitHQ50alt "Recruits-High Quality (Alt Def'n) in this month county"
label var monthcountyrecruitHQ75 "Recruits-Very High Quality in this month county"


foreach var in AG AR AV CR CV FG FR FV MR MV NR NV {
  quietly gen `var'=0
  quietly gen `var'LQ=0 /*LOW QUALITY*/
  quietly gen `var'HQ50=0 /* AFQT >50, High School degree*/
  quietly gen `var'HQ50alt=0 /* AFQT 50+, Certificate*/
  quietly gen `var'HQ75=0 /*AFQT 75, some college*/
  quietly replace `var'=1 if unit=="`var'" 
  quietly replace `var'LQ=1 if unit=="`var'" & (afqt<50|educ<31)
  quietly replace `var'HQ50=1 if unit=="`var'" & afqt>49 & educ>=31
  quietly replace `var'HQ50alt=1 if unit=="`var'" & afqt>49 & (educ>=31|educ==13)
  quietly replace `var'HQ75=1 if unit=="`var'" & afqt>74 & educ>=41
  quietly bysort month countyfp: egen `var'monthcounty=total(`var')
  quietly bysort month countyfp: egen `var'LQmonthcounty=total(`var'LQ)
  quietly bysort month countyfp: egen `var'HQ50monthcounty=total(`var'HQ50)
  quietly bysort month countyfp: egen `var'HQ50altmonthcounty=total(`var'HQ50alt)
  quietly bysort month countyfp: egen `var'HQ75monthcounty=total(`var'HQ75)
  drop `var' `var'LQ `var'HQ50 `var'HQ50alt `var'HQ75
  label var `var'monthcounty "`var' Recruits in this month county"
  label var `var'LQmonthcounty "`var' Recruits-Low Quality in this month county"
  label var `var'HQ50monthcounty "`var' Recruits-High Quality in this month county"
  label var `var'HQ50altmonthcounty "`var' Recruits-High Quality (Alt Def'n) in this month county"
  label var `var'HQ75monthcounty "`var' Recruits-Very High Quality in this month county"
  compress
}
quietly gen monthcounty=month+countyfp
count
duplicates drop monthcounty, force
count
compress
save ./Apps/`FILE'bymonthcounty90.dta, replace


/*BUILD DEATHS*/
use ./Deaths/post90deaths.dta, clear
compress
/*DROP THE DEATHS AFTER THE RECRUIT DATA ENDS*/

drop if date>20060731
tostring date, gen(month)
replace month=substr(month, 1, 6)
/*CHANGE VAR NAMES TO MATCH BETWEEN OEF/OIF AND POST-1990 SETS*/
rename homeofrecordstate homestate
rename homeofrecordcounty homecounty
rename homeofrecordcity homecity

/************************************************* TOTAL **************************************/
/*BUILD TOTAL DEATHS AND TOTAL BY SERVICE*/
quietly bysort month: egen monthtotaldeath=count(age)
quietly gen servicebranch=service+component
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV{
  quietly bysort month: egen `servicebranch'monthtotaldeath=total(servicebranch=="`servicebranch'")
 }


/*BUILD TOTAL DEATHS BY RACE*/
quietly bysort month: egen BLACKmonthtotaldeath=total(raceethnic=="BLACK OR AFRICAN AMERICAN")
quietly bysort month: egen WHITEmonthtotaldeath=total(raceethnic=="WHITE")
quietly bysort month: egen HISPmonthtotaldeath=total(raceethnic=="HISPANIC")
quietly bysort month: egen OTHmonthtotaldeath=total(raceethnic!="HISPANIC" & raceethnic!="WHITE" & raceethnic!="BLACK OR AFRICAN AMERICAN" & raceethnic!="")
/*BUILD TOTAL DEATHS BY HOSTILE STATUS*/
quietly bysort month: egen Hmonthtotaldeath=total(hostile=="H")
quietly bysort month: egen notHmonthtotaldeath=total(hostile=="")
/*BUILD TOTAL DEATHS BY GENDER*/
quietly bysort month: egen FEMALEmonthtotaldeath=total(gender=="F")
quietly bysort month: egen MALEmonthtotaldeath=total(gender=="M")
/*BUILD TOTAL DEATHS BY WAR*/
quietly bysort month: egen IRAQmonthtotaldeath=total(war=="Iraq")
quietly bysort month: egen AFGHANmonthtotaldeath=total(war=="Afghanistan")
quietly bysort month: egen OTHERmonthtotaldeath=total(war=="")

/******************************************************STATE*************************************/
/*BUILD STATE DEATHS AND STATE BY SERVICE*/
quietly gen monthstate=month+homestate
quietly bysort monthstate: egen monthstatedeath=count(age)
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV{
   quietly bysort monthstate: egen `servicebranch'monthstatedeath=total(servicebranch=="`servicebranch'")
}

/*BUILD STATE DEATHS BY RACE*/
quietly bysort monthstate: egen BLACKmonthstatedeath=total(raceethnic=="BLACK OR AFRICAN AMERICAN")
quietly bysort monthstate: egen WHITEmonthstatedeath=total(raceethnic=="WHITE")
quietly bysort monthstate: egen HISPmonthstatedeath=total(raceethnic=="HISPANIC")
quietly bysort monthstate: egen OTHmonthstatedeath=total(raceethnic!="HISPANIC" & raceethnic!="WHITE" & raceethnic!="BLACK OR AFRICAN AMERICAN" & raceethnic!="")
/*BUILD STATE DEATHS BY HOSTILE STATUS*/
quietly bysort monthstate: egen Hmonthstatedeath=total(hostile=="H")
quietly bysort monthstate: egen notHmonthstatedeath=total(hostile=="")
/*BUILD STATE DEATHS BY GENDER*/
quietly bysort monthstate: egen FEMALEmonthstatedeath=total(gender=="F")
quietly bysort monthstate: egen MALEmonthstatedeath=total(gender=="M")
/*BUILD STATE DEATHS BY WAR*/
quietly bysort monthstate: egen IRAQmonthstatedeath=total(war=="Iraq")
quietly bysort monthstate: egen AFGHANmonthstatedeath=total(war=="Afghanistan")
quietly bysort monthstate: egen OTHERmonthstatedeath=total(war=="")


/*********************************************COUNTY***************************************/
/*BUILD DEATHS BY MONTH AND COUNTY*/
rename homestate stab
rename homecounty county
sort stab county
save temp_deaths90, replace
use ./Apps/zip_crosswalk.dta /*THIS HAS COUNTY NAME AND FIPS CODE. DEATHS FILE JUST HAS COUNTY NAME*/
/*Oct 30, 11--where did this zip_crosswalk come from? Acland? It has ~31,000 ZIPS, which isn't complete. That's not important here since it's just using county, but earlier it is.*/
duplicates drop countyfp, force
/*MAKE UPPER-CASE*/
quietly replace county=upper(county)
/*GET RID OF PERIODS*/
quietly replace county=subinstr(county,".","",.)
sort stab county
save ./Apps/temp_crosswalk.dta, replace

/***************************************CHANGE ALL CITY NAMES IN DEATH DATA TO COUNTIES USING USGS-CROSSWALK*/

use ./Crosswalk/USGSCrosswalk.dta, clear
sort stab county
save ./Data/temp_geocorr.dta, replace

use temp_deaths90.dta, clear
merge m:m stab county using ./Data/temp_geocorr.dta 
/*OCT 30, 11--18,000 of 20,500 matched*/
 

drop if _merge!=3 /*MASTER IS DEATHS FILE. USING IS CROSSWALK*/
/*IDEALLY THERE SHOULD BE NO _merge==1. THAT'S USING EVERY DEATH*/
rename _merge mergedeathcounty

gen CRAP=string(state_numeric)
drop state_numeric
rename CRAP state_numeric
replace state_numeric="0"+state_numeric if length(state_numeric)==1

quietly gen CRAP=string(county_numeric)
drop county_numeric
rename CRAP county_numeric
quietly replace county_numeric="00"+county_numeric if length(county_numeric)==1
quietly replace county_numeric="0"+county_numeric if length(county_numeric)==2

quietly gen countyfp=state_numeric+county_numeric
quietly gen monthcounty=month+countyfp
/*BUILD MONTHLY COUNTY DEATHS BY SERVICE*/
quietly bysort monthcounty: egen monthcountydeath=count(age)
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV{
  quietly bysort monthcounty: egen `servicebranch'monthcountydeath=total(servicebranch=="`servicebranch'")
 }

/*ADDED 122910--RACE*/
quietly bysort monthcounty: egen BLACKmonthcountydeath=total(raceethnic=="BLACK OR AFRICAN AMERICAN")
quietly bysort monthcounty: egen WHITEmonthcountydeath=total(raceethnic=="WHITE")
quietly bysort monthcounty: egen HISPmonthcountydeath=total(raceethnic=="HISPANIC")
quietly bysort monthcounty: egen OTHmonthcountydeath=total(raceethnic!="HISPANIC" & raceethnic!="WHITE" & raceethnic!="BLACK OR AFRICAN AMERICAN" & raceethnic!="")

/*BUILD COUNTY DEATHS BY HOSTILE STATUS*/
quietly bysort monthcounty: egen Hmonthcountydeath=total(hostile=="H")
quietly bysort monthcounty: egen notHmonthcountydeath=total(hostile=="")
/*BUILD COUNTY DEATHS BY GENDER*/
quietly bysort monthcounty: egen FEMALEmonthcountydeath=total(gender=="F")
quietly bysort monthcounty: egen MALEmonthcountydeath=total(gender=="M")
/*BUILD COUNTY DEATHS BY WAR*/
quietly bysort monthcounty: egen IRAQmonthcountydeath=total(war=="Iraq")
quietly bysort monthcounty: egen AFGHANmonthcountydeath=total(war=="Afghanistan")
quietly bysort monthcounty: egen OTHERmonthcountydeath=total(war=="")

count
duplicates drop monthcounty, force
count
keep monthstate monthstatedeath monthtotaldeath monthcounty *monthcountydeath *monthstatedeath *monthtotaldeath 
sa ./Deaths/deathsbymonthcounty90.dta, replace

/*HAVE TO START WITH ALL COUNTY-MONTHS SO I HAVE COUNTY 
MONTHS WITH NO DEATHS AND NO RECRUITS*/
use ./Unemployment/countyunemployment.dta, clear /*This starts in 1990, so should be good for post90 deaths*/
/*DROP UNEMPLOYMENT AFTER THE RECRUITING DATA ENDS*/
keep if month<200608
drop if statefips=="72" /*Use only the 50 states, not Puerto Rico*/
tostring month, replace
quietly gen monthcounty=month+fips
quietly gen monthstate=month+substr(name,-2,.) 
quietly replace monthstate=month+"DC" if name=="District of Columbia"
move monthcounty fips
sort monthcounty
/*MERGE IN DEATHS*/
merge 1:1 monthcounty using ./Deaths/deathsbymonthcounty90.dta
replace monthcountydeath=0 if _merge==1 & monthcountydeath==. /*IF THERE WERE NO DEATHS IN THE COUNTY, SET=0*/
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV{
  quietly replace `servicebranch'monthcountydeath=0 if _merge==1 & `servicebranch'monthcountydeath==.
 }

/*BY RACE, HOSTILITY, GENDER, WAR*/
foreach race in WHITE BLACK HISP OTH H notH FEMALE MALE IRAQ AFGHAN OTHER{
 quietly replace `race'monthcountydeath=0 if _merge==1 & `race'monthcountydeath==.
}

rename _merge mergedeathtounemp

/*CAN'T JUST SET ALL DEATHS=0 BECAUSE TOTAL & STATE ARE >0. CALC VIA EGEN*/
/*THIS IS 'SPREADING' THE TOTAL DEATHS TO OTHER STATES WITHOUT ANY, SO THEIR MONTH-TOTAL IS CORRECTED*/
quietly bysort month: egen NEWmonthtotaldeath=max(monthtotaldeath)
drop monthtotaldeath
rename NEWmonthtotaldeath monthtotaldeath
quietly replace monthtotaldeath=0 if monthtotaldeath==.
/*BY SERVICE*/
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV{
  quietly bysort month: egen `servicebranch'NEWmonthtotaldeath=max(`servicebranch'monthtotaldeath)
  drop `servicebranch'monthtotaldeath
  rename `servicebranch'NEWmonthtotaldeath `servicebranch'monthtotaldeath
  quietly replace `servicebranch'monthtotaldeath=0 if `servicebranch'monthtotaldeath==.
 }

/*BY RACE, HOSTILE, GENDER, WAR*/
foreach race in WHITE BLACK HISP OTH H notH FEMALE MALE IRAQ AFGHAN OTHER{
 quietly bysort month: egen `race'NEWmonthtotaldeath=max(`race'monthtotaldeath)
 drop `race'monthtotaldeath
 rename `race'NEWmonthtotaldeath `race'monthtotaldeath
 quietly replace `race'monthtotaldeath=0 if `race'monthtotaldeath==.
}

/*SPREAD STATE DEATHS TO IN-STATE COUNTIES WITHOUT ANY DEATHS*/
quietly bysort monthstate: egen NEWmonthstatedeath=max(monthstatedeath)
drop monthstatedeath
rename NEWmonthstatedeath monthstatedeath
quietly replace monthstatedeath=0 if monthstatedeath==.
/*BY SERVICE*/
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV{
  quietly bysort monthstate: egen `servicebranch'NEWmonthstatedeath=max(`servicebranch'monthstatedeath)
  drop `servicebranch'monthstatedeath
  rename `servicebranch'NEWmonthstatedeath `servicebranch'monthstatedeath
  quietly replace `servicebranch'monthstatedeath=0 if `servicebranch'monthstatedeath==.
 }


/*BY RACE, HOSTILE, GENDER, WAR*/
foreach race in BLACK WHITE HISP OTH H notH FEMALE MALE IRAQ AFGHAN OTHER{ 
 quietly bysort monthstate: egen `race'NEWmonthstatedeath=max(`race'monthstatedeath)
 drop `race'monthstatedeath
 rename `race'NEWmonthstatedeath `race'monthstatedeath
 quietly replace `race'monthstatedeath=0 if `race'monthstatedeath==.
}

sort monthcounty
save temp_90deathsjustbeforeappmerge.dta, replace
/*MERGE IN RECRUITS*/

merge 1:1 monthcounty using ./Apps/`FILE'bymonthcounty90.dta 
/*Use same set of apps and main, the only thing that's different to compare the non-combat deaths
is the death data*/
rename _merge merge_apps
drop original-type countyfp-county
foreach var of varlist monthstaterecruit-NRmonthstate {
 quietly bysort monthstate: egen new`var'=max(`var')
 drop `var'
 rename new`var' `var'
}
foreach var of varlist monthcountyrecruit-NRmonthstate{
 quietly replace `var'=0 if `var'==.
}


/*MERGE IN ICPSR COUNTY BACKGROUND DATA*/
destring fips, replace
sort fips
compress
/*DROP DATA AFTER RECRUITING DATA ENDS*/
drop if month>"200607"
merge m:1 fips using ./Data/icpsrcountiesSM.dta /*this has just the 50 states*/
drop if _merge==2 /*Hawaii county from ICPSR combined with other county*/
	/* TWO PERCENT OF OBSERVATIONS _merge==3. ICPSR HAS NO PUERTO RICO DATA*/
rename _merge mergeicpsr

/*MAKE THE CALENDAR MONTHS*/
gen year=substr(monthcounty,1,4)
destring year, replace
tostring month, replace
gen calendar=substr(month,5,2)
destring calendar, replace
quietly gen jan=1 if calendar==1
quietly gen feb=1 if calendar==2
quietly gen mar=1 if calendar==3
quietly gen apr=1 if calendar==4
quietly quietly gen may=1 if calendar==5
quietly gen jun=1 if calendar==6
quietly gen jul=1 if calendar==7
quietly gen aug=1 if calendar==8
quietly gen sep=1 if calendar==9
quietly gen oct=1 if calendar==10
quietly gen nov=1 if calendar==11
quietly gen dec=1 if calendar==12
foreach var in jan feb mar apr may jun jul aug sep oct nov dec{
 quietly replace `var'=0 if `var'==.
}
compress
save temp_county, replace

/*MERGE IN RECRUITER DATA FROM JOHN WARNER*/
*Only need to do this once
*use "./Recruiters/Military Recruiting Data 1988-2005 New Version.dta" /*this has only the 50 states*/
*keep state state_name yr qtr *rec*
*rename yr year
*rename state statefips
*sort statefips year qtr
*drop if year<1990
*save ./Recruiters/Warner.dta, replace

/* INCLUDE GELBER'S WAGE/SALARY DATA ONCE I CAN IDENTIFY STATES
use ./Recruiters/garret_christensen_082410.dta
keep if yr>2000
*/

use temp_county.dta
quietly gen qtr=1
quietly replace qtr=2 if apr==1|may==1|jun==1
quietly replace qtr=3 if jul==1|aug==1|sep==1
quietly replace qtr=4 if oct==1|nov==1|dec==1
destring statefips, replace
sort statefips year qtr
merge m:1 statefips year qtr using ./Recruiters/Warner.dta
drop if _merge==2
/*RECRUITER DATA MISSING FOR DC, PR, ENDS IN 2004/2005*/
rename _merge mergerecruiters
drop if statefips==. /*WHO ARE THESE 28?*/

/** BUILD IN BETTER MORTALITY RATES*/
/*APRIL 2011 I NEED TO GET OLDER MORTALITY DATA IN HERE FOR SURE. HOPEFULLY PUBLICLY AVAILABLE*/
sort monthcounty
merge 1:1 monthcounty using ./Mortality/youngmaledeaths0104.dta 
rename _merge mergegoodmortality
/*MERGE RATE IS FAIRLY LOW HERE, BECAUSE NOT EVERY COUNTY HAS A YOUNG MALE DEATH
EVERY MONTH. THAT'S OK.
_merge==1 is the counties without deaths, _merge==2 is the 999 counties that can't be identified, 
JUST LIKE WITH THE MILITARY DEATHS, I MUST 'SPREAD' THESE DEATHS TO THE COUNTIES WITHOUT*/
quietly replace monthcountymort=0 if monthcountymort==.
bysort statefips month: egen newmonthstatemort=max(monthstatemort)
drop monthstatemort
rename newmonthstatemort monthstatemort
move monthstatemort monthcountymort
bysort month: egen monthnationalmort=sum(monthstatemort)
move monthnationalmort monthstatemort

label var monthcountymort "County Mortality Rate"
label var monthstatemort "State Mortality Rate"
label var monthnationalmort "National Mortality Rate"

/**BUILD IN NATIONAL AND STATE UNEMPLOYMENT LEVELS*/
sort month
merge m:1 month using ./Unemployment/nationalunemp.dta /*This has post-90, so should be cool*/
drop if _merge==2 /*OUT OF RELEVANT TIME PERIOD*/
rename _merge mergenationalunemp
rename unemployment nationalunemp
move nationalunemp countyunemp
merge m:1 statefips month using ./Unemployment/stateunemp.dta
drop if _merge==2 /* OUT OF RELEVANT TIME PERIOD. MERGE==1 PUERTO RICO MISSING DATA*/
rename _merge mergestateunemp
move stateunemp nationalunemp

/*ADD COUNTY POPULATION IN ORDER TO WEIGHT*/
destring countyfips, replace
merge m:1 statefips countyfips year using ./Population/countyyoungmalepop.dta
drop if _merge==2
rename _merge merge_countypop
bysort fips: egen avgcountypop=mean(age1824_male)
label var avgcountypop "Young Male 18-24 Population, Average for County"
rename age1824_male countypopmonth
label var countypopmonth "Young Male 18-24 Population By Month"

/*ADD SLIGHTLY ALTERED/EXCLUSIVE DEATH DEFINITIONS*/
quietly gen outofstate=monthtotaldeath-monthstatedeath
quietly gen outofcounty=monthstatedeath-monthcountydeath
label var outofstate "Out of state deaths this month"
label var outofcounty "Out of county but in-state deaths this month"
quietly gen Rmonthcountydeath=ARmonthcountydeath+MRmonthcountydeath+FRmonthcountydeath+NRmonthcountydeath
quietly gen Rmonthstatedeath=ARmonthstatedeath+MRmonthstatedeath+FRmonthstatedeath+NRmonthstatedeath
quietly gen Rmonthtotaldeath=ARmonthtotaldeath+MRmonthtotaldeath+FRmonthtotaldeath+NRmonthtotaldeath
label var Rmonthcountydeath "Active duty deaths this month-county"
label var Rmonthstatedeath "Active duty deaths this month-state"
foreach type in R AR FR MR NR WHITE BLACK HISP OTH H notH MALE FEMALE IRAQ AFGHAN{
 quietly gen `type'outofstate=`type'monthtotaldeath-`type'monthstatedeath
 quietly gen `type'outofcounty=`type'monthstatedeath-`type'monthcountydeath
 label var `type'outofstate "`type' out of state deaths this month"
 label var `type'outofcounty "`type' out of county but in-state deaths this month"
}
/*CON IS MISSING RESERVE--ACTIVE DUTY ONLY*/
quietly gen active=ARmonthcounty+MRmonthcounty+NRmonthcounty+FRmonthcounty
quietly gen LNactive=ln(active+1)
label var active "Active Duty Recruits"
label var LNactive "Log Active Duty Recruits"

*************FINAL CLEANING************
*This used to be at the beginning of each and every regression file.
*Much better to have it here so we're sure I'm using the same data every time.

drop if fips==0 
drop if countyfips==999 /*This means they don't know. Right?*/

*********FIXED EFFECTS AND TRENDS***********
/*MONTHLY FE*/
tab month, generate(monthfe)

/*GENERATE YEAR FIXED EFFECTS*/ //Why don't I make these somewhere everyone can reach them?
quietly gen year1999=1 if year==1999
quietly gen year2000=1 if year==2000
quietly gen year2001=1 if year==2001
quietly gen year2002=1 if year==2002
quietly gen year2003=1 if year==2003
quietly gen year2004=1 if year==2004
quietly gen year2005=1 if year==2005
quietly gen year2006=1 if year==2006
foreach var in 1999 2000 2001 2002 2003 2004 2005 2006{
 quietly replace year`var'=0 if year`var'==.
}
quietly gen yearcounty=string(year)+string(fips)

/*STATE TREND*/
tab statefips, gen(statefe)
quietly gen mo=substr(month,5,2)
destring mo, replace
quietly gen fancymonth=ym(year,mo)
tsset fips fancymonth
quietly gen t=fancymonth-500 /*changed from 501 2/1/2016--1 to 58 not 0 to 57*/
tab statefips, gen(statetrend)
forvalues X=1/51 {
 quietly replace statetrend`X'=statetrend`X'*t
}


/*STATE YEAR INTERACTED FE*/
quietly gen stateyear=string(year)+string(statefips)
tab stateyear, gen(stateyearfe)

/* (1) CREATE LAGS*/
sort fips month
foreach var in monthcountydeath outofcounty outofstate countyunemp stateunemp nationalunemp ///
	monthnationalmort monthstatemort monthcountymort Rmonthcountydeath Routofcounty Routofstate{
 foreach X of numlist 1/12 {
  quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
  label var L`X'`var' "`X' monthly lags of `var'"
  quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
  label var F`X'`var' "`X' monthly leads of `var'"
 } 
}

foreach var in IRAQmonthcountydeath AFGHANmonthcountydeath IRAQoutofcounty AFGHANoutofcounty ///
	ARmonthcountydeath FRmonthcountydeath MRmonthcountydeath NRmonthcountydeath ///
	ARoutofcounty FRoutofcounty MRoutofcounty NRoutofcounty{
 foreach X of numlist 1/2 {
  quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
  label var L`X'`var' "`X' monthly lags of `var'"
  quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
  label var F`X'`var' "`X' monthly leads of `var'"
 } 
}

label var monthcountydeath "In-County Deaths"
label var L1monthcountydeath "Lag In-County Deaths"
label var outofcounty "Out-of-County Deaths"
label var L1outofcounty "Lag Out-of-County Deaths"
label var L1ARoutofcounty "Army Lag Out-of-County Deaths"
label var L1FRoutofcounty "Air Force Lag Out-of-County Deaths"
label var L1MRoutofcounty "Marines Lag Out-of-County Deaths"
label var L1NRoutofcounty "Navy Lag Out-of-County Deaths"

compress
sa ./Data/county`FILE'90_raw.dta, replace

} //END HUGE ASS LOOP OF BOTH APPS AND CONS
