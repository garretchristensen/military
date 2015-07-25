/*RUN REGRESSIONS BY COUNTY*/
/*RECRUITS ON TOTAL DEATHS, STATE DEATHS, COUNTY DEATHS, UNEMPLOYMENT*/
*2014.11.17 I am doing a second take on all deaths as a robustness check, but only for the 01-06 period
*If non-combat deaths have no effect, that's good for my hypothesis

*2014.11.27 Change this back to keeping all 90-2006 deaths,
*so we can run 1900-2006 ALL DEATH regs, plus 2001-2006 ALL DEATH regs.

clear all
set more off
cd C:/Users/garret/Documents/Research/Military

cap log close
log using ./Logs/buildCONcounty90.smcl, replace

/*MERGE THE RECRUIT DATA WITH THE ZIP-CODE CROSSWALK*/
use ./Apps/CON_all.dta, clear
drop if date>20060731 /*Must rebuild CONS so as to include 1990-2006 OBS*/
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
bysort month stab: egen monthstaterecruit=count(zip)
bysort month stab: egen monthstaterecruitLQ=count(zip) if afqt<50 |educ<31
bysort month stab: egen monthstaterecruitHQ50=count(zip) if afqt>49 & educ>=31
bysort month stab: egen monthstaterecruitHQ50alt=count(zip) if afqt>49 & (educ>=31|educ==13)
bysort month stab: egen monthstaterecruitHQ75=count(zip) if afqt>74 & educ>=41
label var monthstaterecruit "Recruits in this month state"
label var monthstaterecruitLQ "Recruits-Low Quality in this month state"
label var monthstaterecruitHQ50 "Recruits-High Quality in this month state"
label var monthstaterecruitHQ50alt "Recruits-High Quality (Alt Def'n) in this month state"
label var monthstaterecruitHQ75 "Recruits-Very High Quality in this month state"



foreach var in AG AR AV CR CV FG FR FV MR MV NR NV {
  gen `var'=0
  gen `var'LQ=0 /*LOW QUALITY*/
  gen `var'HQ50=0 /* AFQT >50, High School degree*/
  gen `var'HQ50alt=0 /* AFQT 50+, Certificate*/
  gen `var'HQ75=0 /*AFQT 75, some college*/
  replace `var'=1 if unit=="`var'"
  replace `var'LQ=1 if unit=="`var'" & (afqt<50 |educ<31)
  replace `var'HQ50=1 if unit=="`var'" & afqt>49 & educ>=31
  replace `var'HQ50alt=1 if unit=="`var'" & afqt>49 & (educ>=31|educ==13)
  replace `var'HQ75=1 if unit=="`var'" & afqt>74 & educ>=41
  bysort month stab: egen `var'monthstate=total(`var')
  bysort month stab: egen `var'LQmonthstate=total(`var'LQ)
  bysort month stab: egen `var'HQ50monthstate=total(`var'HQ50)
  bysort month stab: egen `var'HQ50altmonthstate=total(`var'HQ50alt)
  bysort month stab: egen `var'HQ75monthstate=total(`var'HQ75)
  drop `var' `var'LQ `var'HQ50 `var'HQ50alt `var'HQ75
  label var `var'monthstate "`var' Recruits in this month state"
  label var `var'LQmonthstate "`var' Recruits-Low Quality in this month state"
  label var `var'HQ50monthstate "`var' Recruits-High Quality in this month state"
  label var `var'HQ50altmonthstate "`var' Recruits-High Quality (Alt Def'n) in this month state"
  label var `var'HQ75monthstate "`var' Recruits-Very High Quality in this month state"
  compress
}
gen monthstate=month+stab



/*COLLAPSE RECRUITS BY MONTH & COUNTY*/
bysort month countyfp: egen monthcountyrecruit=count(zip)
bysort month countyfp: egen monthcountyrecruitLQ=count(zip) if afqt<50 |educ<31
bysort month countyfp: egen monthcountyrecruitHQ50=count(zip) if afqt>49 & educ>=31
bysort month countyfp: egen monthcountyrecruitHQ50alt=count(zip) if afqt>49 & (educ>=31|educ==13)
bysort month countyfp: egen monthcountyrecruitHQ75=count(zip) if afqt>74 & educ>=41
label var monthcountyrecruit "Recruits in this month county"
label var monthcountyrecruitLQ "Recruits-Low Quality in this month county"
label var monthcountyrecruitHQ50 "Recruits-High Quality in this month county"
label var monthcountyrecruitHQ50alt "Recruits-High Quality (Alt Def'n) in this month county"
label var monthcountyrecruitHQ75 "Recruits-Very High Quality in this month county"


foreach var in AG AR AV CR CV FG FR FV MR MV NR NV {
  gen `var'=0
  gen `var'LQ=0 /*LOW QUALITY*/
  gen `var'HQ50=0 /* AFQT >50, High School degree*/
  gen `var'HQ50alt=0 /* AFQT 50+, Certificate*/
  gen `var'HQ75=0 /*AFQT 75, some college*/
  replace `var'=1 if unit=="`var'" 
  replace `var'LQ=1 if unit=="`var'" & (afqt<50|educ<31)
  replace `var'HQ50=1 if unit=="`var'" & afqt>49 & educ>=31
  replace `var'HQ50alt=1 if unit=="`var'" & afqt>49 & (educ>=31|educ==13)
  replace `var'HQ75=1 if unit=="`var'" & afqt>74 & educ>=41
  bysort month countyfp: egen `var'monthcounty=total(`var')
  bysort month countyfp: egen `var'LQmonthcounty=total(`var'LQ)
  bysort month countyfp: egen `var'HQ50monthcounty=total(`var'HQ50)
  bysort month countyfp: egen `var'HQ50altmonthcounty=total(`var'HQ50alt)
  bysort month countyfp: egen `var'HQ75monthcounty=total(`var'HQ75)
  drop `var' `var'LQ `var'HQ50 `var'HQ50alt `var'HQ75
  label var `var'monthcounty "`var' Recruits in this month county"
  label var `var'LQmonthcounty "`var' Recruits-Low Quality in this month county"
  label var `var'HQ50monthcounty "`var' Recruits-High Quality in this month county"
  label var `var'HQ50altmonthcounty "`var' Recruits-High Quality (Alt Def'n) in this month county"
  label var `var'HQ75monthcounty "`var' Recruits-Very High Quality in this month county"
  compress
}
gen monthcounty=month+countyfp
count
duplicates drop monthcounty, force
count
compress
save ./Apps/CONbymonthcounty90.dta, replace


/*BUILD DEATHS*/
*for all CON data, use deaths from the APPs construction file.

use temp_90deathsjustbeforeappmerge.dta, replace

/*MERGE IN RECRUITS*/
merge 1:1 monthcounty using ./Apps/CONbymonthcounty90.dta /*Make sure to use full set of Apps!*/
rename _merge merge_apps
drop original-type countyfp-county
foreach var of varlist monthstaterecruit-NRmonthstate {
 bysort monthstate: egen new`var'=max(`var')
 drop `var'
 rename new`var' `var'
}
foreach var of varlist monthcountyrecruit-NRmonthstate{
 replace `var'=0 if `var'==.
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
gen jan=1 if calendar==1
gen feb=1 if calendar==2
gen mar=1 if calendar==3
gen apr=1 if calendar==4
gen may=1 if calendar==5
gen jun=1 if calendar==6
gen jul=1 if calendar==7
gen aug=1 if calendar==8
gen sep=1 if calendar==9
gen oct=1 if calendar==10
gen nov=1 if calendar==11
gen dec=1 if calendar==12
foreach var in jan feb mar apr may jun jul aug sep oct nov dec{
 replace `var'=0 if `var'==.
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
gen qtr=1
replace qtr=2 if apr==1|may==1|jun==1
replace qtr=3 if jul==1|aug==1|sep==1
replace qtr=4 if oct==1|nov==1|dec==1
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
replace monthcountymort=0 if monthcountymort==.
bysort statefips month: egen newmonthstatemort=max(monthstatemort)
drop monthstatemort
rename newmonthstatemort monthstatemort
move monthstatemort monthcountymort
bysort month: egen monthnationalmort=sum(monthstatemort)
move monthnationalmort monthstatemort

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

/*ADD SLIGHTLY ALTERED/EXCLUSIVE DEATH DEFINITIONS*/
gen outofstate=monthtotaldeath-monthstatedeath
gen outofcounty=monthstatedeath-monthcountydeath
gen Rmonthcountydeath=ARmonthcountydeath+MRmonthcountydeath+FRmonthcountydeath+NRmonthcountydeath
gen Rmonthstatedeath=ARmonthstatedeath+MRmonthstatedeath+FRmonthstatedeath+NRmonthstatedeath
gen Rmonthtotaldeath=ARmonthtotaldeath+MRmonthtotaldeath+FRmonthtotaldeath+NRmonthtotaldeath
foreach type in R AR FR MR NR WHITE BLACK HISP OTH H notH MALE FEMALE IRAQ AFGHAN OTHER{
 gen `type'outofstate=`type'monthtotaldeath-`type'monthstatedeath
 gen `type'outofcounty=`type'monthstatedeath-`type'monthcountydeath
}

compress
sa ./Data/countyCON90_raw.dta, replace
