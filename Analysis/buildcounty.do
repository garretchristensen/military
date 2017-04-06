/*THIS FILE RUNS THE INTERMEDIATE STEPS OF DATASET CONSTRUCTION*/
/*YOU MUST ALREADY HAVE TURNED THE FOIA .TXT APPLICATION DATA INTO COMPILED APPS
(done in buildfromFOIA.do)
AND YOU MUST ALSO TURN THE RAW DEATH DATA INTO A MASTER LIST OF US DEATHS*/
/*This file take the apps and deaths, puts those together by county, then also merges in
unemployment, recruiters, and mortality data.*/

clear all
set more off
cd $dir

cap log close
log using ./Logs/buildcounty.smcl, replace

*HUGE ASS LOOP OVER BOTH APP AND CON!
foreach FILE in APP CON{

/*MERGE THE RECRUIT DATA WITH THE ZIP-CODE CROSSWALK*/
use ./Apps/`FILE'_all.dta, clear
drop if date<20011000|date>20060731
sort zip
count

merge m:1 zip using ./Apps/zip_crosswalk.dta /*This ZIP->county cross-walk is from MABLE*/
//Unfortunately I don't have the exact details of its creation
//Testing with a newer crosswalk yields no significant differences.

count
drop if _merge!=3 /*5% OF OBS do not match, unfortunately*/

/*USING geocorr2kZIPCITY121212.dta only results in 368 more matched APPS*/
/* TEST A FRESH MABLE GEOCORR CROSSWALK
/*attempt clean the zip crosswalk, temporarily*/
use ./Crosswalk/geocorr2kZIPCITY121212.dta, clear
duplicates drop zip, force
replace zip=subinstr(zip, "X","0",.)
destring zip, replace
sort zip
save ./Crosswalk/temp_crosswalk, replace
/*merge them together*/
use temp, clear
merge m:m zip using ./Crosswalk/temp_crosswalk.dta
count
drop if _merge!=3
count
*/

*Crosswalks do not include Puerto Rico, so they have been dropped here.
*There are PR deaths, but as they are not merged here from ZIP to county, all PR obs get dropped from the analysis
rename _merge ZIPmerge
tostring date, gen(month)
replace month=substr(month, 1, 6)
sort month

/*COLLAPSE RECUITS JUST BY MONTH*/
/*I HAVE NEVER DONE THIS--THERE IS NEVER A MONTHTOTALRECRUIT (depvar?)*/
/*IT WOULDN'T BE THAT INTERESTING, IT's JUST 58 MONTHLY OBSERVATIONS*/
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
gen monthstate=month+stab



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
gen monthcounty=month+countyfp
count
duplicates drop monthcounty, force
count
compress
save ./Apps/`FILE'bymonthcounty.dta, replace

/*BUILD DEATHS*/
************************************************************************************
*MUST BE DONE LIKE RECRUITS-WITH TOTAL NOT COUNT-IF
**********************************************************************************
use ./Deaths/allUS, clear
compress
drop if date<20010000|date>20060731
tostring date, gen(month)
replace month=substr(month, 1, 6)

/************************************************* TOTAL **************************************/
/*BUILD TOTAL DEATHS AND TOTAL BY SERVICE*/
bysort month: egen monthtotaldeath=count(age)
label var monthtotaldeath "Total deaths this month"

gen servicebranch=service+component
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV {
  bysort month: egen `servicebranch'monthtotaldeath=total(servicebranch=="`servicebranch'")
  label var `servicebranch'monthtotaldeath "Total `servicebranch' deaths this month" 
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
/*BUILD TOTAL DEATHS BY PAYGRADE*/
quietly bysort month: egen E3monthtotaldeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03")
quietly bysort month: egen E4monthtotaldeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03"|paygrade=="E04")
quietly bysort month: egen E3Pmonthtotaldeath=total(paygrade!="E01"& paygrade!="E02"& paygrade!="E03" & paygrade!="")
quietly bysort month: egen E4Pmonthtotaldeath=total(paygrade!="E01"& paygrade!="E02"& paygrade!="E03" & paygrade!="E04" & paygrade!="")
quietly bysort month: egen E5monthtotaldeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03"|paygrade=="E04"|paygrade=="E05")
quietly bysort month: egen E5Pmonthtotaldeath=total(paygrade!="E01"& paygrade!="E02"& paygrade!="E03" & paygrade!="E04" ///
	& paygrade!="E05" & paygrade!="")
quietly bysort month: egen OFFICERmonthtotaldeath=total(substr(paygrade,1,1)=="W"|substr(paygrade,1,1)=="O")
quietly bysort month: egen ENLISTEDmonthtotaldeath=total(substr(paygrade,1,1)=="E")
	

label var BLACKmonthtotaldeath "Total BLACK deaths this month"
label var WHITEmonthtotaldeath "Total WHITE deaths this month"
label var HISPmonthtotaldeath "Total HISP deaths this month"
label var OTHmonthtotaldeath "Total OTHER RACE deaths this month"
label var Hmonthtotaldeath "Total HOSTILE deaths this month"
label var notHmonthtotaldeath "Total non-HOSTILE deaths this month"
label var FEMALEmonthtotaldeath "Total FEMALE deaths this month"
label var MALEmonthtotaldeath "Total MALE deaths this month"
label var IRAQmonthtotaldeath "Total IRAQ deaths this month"
label var AFGHANmonthtotaldeath "Total AFGHAN deaths this month"
label var E3monthtotaldeath "Total E3 or less paygrade deaths this month"
label var E4monthtotaldeath "Total E4 or less paygrade deaths this month"
label var E5monthtotaldeath "Total E5 or less paygrade deaths this month"
label var E3Pmonthtotaldeath "Total more than E3 paygrade deaths this month"
label var E4Pmonthtotaldeath "Total more than E4 paygrade deaths this month"
label var E5Pmonthtotaldeath "Total more than E5 paygrade deaths this month"
label var OFFICERmonthtotaldeath "Total officer deaths this month"
label var ENLISTEDmonthtotaldeath "Total enlisted deaths this month"

/******************************************************STATE*************************************/
/*BUILD STATE DEATHS AND STATE BY SERVICE*/
gen monthstate=month+homestate
bysort monthstate: egen monthstatedeath=count(age)
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV {
  bysort monthstate: egen `servicebranch'monthstatedeath=total(servicebranch=="`servicebranch'")
  label var `servicebranch'monthstatedeath "`servicebranch' deaths this month state"
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
/*BUILD STATE DEATHS BY PAYGRADE*/
quietly bysort monthstate: egen E3monthstatedeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03")
quietly bysort monthstate: egen E4monthstatedeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03"|paygrade=="E04")
quietly bysort monthstate: egen E3Pmonthstatedeath=total(paygrade!="E01"&paygrade!="E02"&paygrade!="E03"&paygrade!="")
quietly bysort monthstate: egen E4Pmonthstatedeath=total(paygrade!="E01"&paygrade!="E02"&paygrade!="E03"&paygrade!="E04"&paygrade!="")
quietly bysort monthstate: egen E5monthstatedeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03"|paygrade=="E04"|paygrade=="E05")
quietly bysort monthstate: egen E5Pmonthstatedeath=total(paygrade!="E01"& paygrade!="E02"& paygrade!="E03" & paygrade!="E04" ///
	& paygrade!="E05" & paygrade!="")
quietly bysort monthstate: egen OFFICERmonthstatedeath=total(substr(paygrade,1,1)=="W"|substr(paygrade,1,1)=="O")
quietly bysort monthstate: egen ENLISTEDmonthstatedeath=total(substr(paygrade,1,1)=="E")

label var BLACKmonthstatedeath "Total BLACK deaths this month-state"
label var WHITEmonthstatedeath "Total WHITE deaths this month-state"
label var HISPmonthstatedeath "Total HISP deaths this month-state"
label var OTHmonthstatedeath "Total OTHER RACE deaths this month-state"
label var Hmonthstatedeath "Total HOSTILE deaths this month-state"
label var notHmonthstatedeath "Total non-HOSTILE deaths this month-state"
label var FEMALEmonthstatedeath "Total FEMALE deaths this month-state"
label var MALEmonthstatedeath "Total MALE deaths this month-state"
label var IRAQmonthstatedeath "Total IRAQ deaths this month-state"
label var AFGHANmonthstatedeath "Total AFGHAN deaths this month-state"
label var E3monthstatedeath "Total E3 or less paygrade deaths this month-state"
label var E4monthstatedeath "Total E4 or less paygrade deaths this month-state"
label var E5monthstatedeath "Total E5 or less paygrade deaths this month-state"
label var E3Pmonthstatedeath "Total more than E3 paygrade deaths this month-state"
label var E4Pmonthstatedeath "Total more than E4 paygrade deaths this month-state"
label var E5Pmonthstatedeath "Total more than E5 paygrade deaths this month-state"
label var OFFICERmonthstatedeath "Total officer deaths this month-state"
label var ENLISTEDmonthstatedeath "Total enlisted deaths this month-state"

/*********************************************COUNTY***************************************/
/*BUILD DEATHS BY MONTH AND COUNTY*/
rename homestate stab
rename homecounty county
sort stab county
save temp, replace
use ./Apps/zip_crosswalk.dta /*THIS HAS COUNTY NAME AND FIPS CODE. DEATHS FILE JUST HAS COUNTY NAME*/
duplicates drop countyfp, force
/*MAKE UPPER-CASE*/
replace county=upper(county)
/*GET RID OF PERIODS*/
replace county=subinstr(county,".","",.)
sort stab county
save ./Apps/temp_crosswalk.dta, replace
use temp, clear
replace county="ANCHORAGE BOROUGH" if county=="ANCHORAGE" & stab=="AK"
replace county="FAIRBANKS NORTH STAR BOROUGH" if county=="FAIRBANKS NORTH STAR" & stab=="AK"
replace county="YAVAPAI" if county=="YAVAPOI" & stab=="AZ"
replace county="OTERO" if county=="OTERA" & stab=="CO"
replace county="MIAMI-DADE" if county=="DADE" & stab=="FL"
replace county="FREMONT" if county=="FREEMONT" & stab=="IA"
replace county="DUPAGE" if county=="DU PAGE" & stab=="IL"
replace county=county+" PARISH" if stab=="LA"
replace county="BALTIMORE CITY" if county=="BALTIMORE (CITY)" & stab=="MD"
replace county="PRINCE GEORGES" if county=="PRINCE GEORGE'S" & stab=="MD"
replace county="ST MARYS" if county=="ST MARY'S" & stab=="MD"
replace county="DEKALB" if county=="DE KALB" & stab=="MO"
replace county="ST LOUIS" if county=="ST LOUIS (CITY)" & stab=="MO"
replace county="BELMONT" if county=="BEDFORD" & stab=="OH"
replace county="MC KEAN" if county=="MCKEAN" & stab=="PA"
replace county=subinstr(county," (CITY)"," CITY",.) if stab=="VA"
replace county="EAU CLAIRE" if county=="EAU CLEAIRE" & stab=="WI"
replace  county = "COFFEE" if county=="" & stab=="AL"
replace  county = "DALE" if homecity=="FT RUCKER" & stab=="AL"
replace  county = "PULASKI" if homecity=="MABLEVALE" & stab=="AR"
replace  county = "BOONE" if homecity=="EVERTON" & stab=="AR"
replace  county = "WHITE" if homecity=="MCRAE" & stab=="AR"
replace  county = "FULTON" if homecity=="CAMP FULTON" & stab=="AR"
replace  homecity = "CAMP" if homecity=="CAMP FULTON" & stab=="AR"
replace  homecity = "SURPRISE" if homecity=="SUPRISE" & stab=="AZ"
replace  county = "MARICOPA" if homecity=="SURPRISE" & stab=="AZ"
replace  county = "YUMA" if homecity=="SAN LUIS" & stab=="AZ"
replace  county = "SACRAMENTO" if homecity=="SACRAMENTO" & stab=="CA"
replace  county = "ORANGE" if homecity=="FOOTHILL RANCH" & stab=="CA"
replace  county = "KERN" if homecity=="CALIENTE" & stab=="CA"
replace  county = "SISKIYOU" if homecity=="MOUNT SHASTA" & stab=="CA"
replace  county = "CONTRA COSTA" if homecity=="DISCOVERY BAY" & stab=="CA"
replace  county = "YUBA" if homecity=="SMARTSVILLE" & stab=="CA"
replace  county = "LOS ANGELES" if homecity=="ARACADIA" & stab=="CA"
replace  county = "SACRAMENTO" if homecity=="FAIR OAKS" & stab=="CA"
replace  county = "SANTA CLARA" if homecity=="MOUNTAIN VIEW" & stab=="CA"
replace  county = "LARIMER" if homecity=="TIMNATH" & stab=="CO"
replace  county = "DOUGLAS" if homecity=="HIGHLANDS RANCH" & stab=="CO"
replace  county = "EAGLE" if homecity=="EDWARDS" & stab=="CO"
replace  homecity = "ST. GEORGES" if homecity=="ST. GEORGE" & stab=="DE"
replace  county = "NEW CASTLE" if homecity=="ST. GEORGES" & stab=="DE"
replace  county = "OKALOOSA" if homecity=="FORT WALTON BEACH" & stab=="FL"
replace  county = "OSCEOLA" if homecity=="ST. CLOUD" & stab=="FL"
replace  county = "FRANKLIN" if homecity=="ST GEORGE'S ISLAND" & stab=="FL"
replace  county = "PINELLAS" if homecity=="SAINT PETERSBURG" & stab=="FL"
replace  county = "BROWARD" if homecity=="POMPANO" & stab=="FL"
replace  homecity = "POMPANO BEACH" if homecity=="POMPANO" & stab=="FL"
replace  homecity = "DONALSONVILLE" if homecity=="DONALDSONVILLE" & stab=="GA"
replace  county = "SEMINOLE" if homecity=="DONALSONVILLE" & stab=="GA"
replace  county = "WHITFIELD" if homecity=="TUNNEL HILL" & stab=="GA"
replace  county = "BRYAN" if homecity=="ELLABELL" & stab=="GA"
replace  county = "HARDIN" if homecity=="ALDEN" & stab=="IA"
replace  county = "SIOUX" if homecity=="MAURICE" & stab=="IA"
replace  county = "DUBUQUE" if homecity=="PEOSTA" & stab=="IA"
replace  county = "POCAHONTAS" if homecity=="POCAHONTAS" & stab=="IA"
replace  county = "LEWIS" if homecity=="CRAIGMONT" & stab=="ID"
replace  county = "FREMONT" if homecity=="SAINT ANTHONY" & stab=="ID"
replace  homecity = "DU QUOIN" if homecity=="DUQUOIN" & stab=="IL"
replace  county = "PERRY" if homecity=="DU QUOIN" & stab=="IL"
replace  county = "HANCOCK" if homecity=="LAHARPE" & stab=="IL"
replace  county = "COOK" if homecity=="BURBANK" & stab=="IL"
replace  county = "JOHNSON" if homecity=="SIMPSON" & stab=="IL"
replace  county = "ALLEN" if homecity=="FORT WAYNE" & stab=="IN"
replace  county = "POSEY" if homecity=="MT. VERNON" & stab=="IN"
replace  county = "DEARBORN" if homecity=="MANCHESTER" & stab=="IN"
replace  county = "SULLIVAN" if homecity=="PAXTON" & stab=="IN"
replace  county = "DUBOIS" if homecity=="DUBOIS" & stab=="IN"
replace  county = "RIPLEY" if homecity=="BATESVILLE" & stab=="IN"
replace  county = "LEAVENWORTH" if homecity=="TONGANOXIE" & stab=="KS"
replace  county = "COWLEY" if homecity=="ARKANSAS" & stab=="KS"
replace  county = "HARDIN" if homecity=="RADCLIFF" & stab=="KY"
replace  county = "CADDO PARISH" if homecity=="SHREVEPORT" & stab=="LA"
replace  county = "VERMILION PARISH" if homecity=="ERATH" & stab=="LA"
replace  county = "WASHINGTON PARISH" if homecity=="MT. HERMON" & stab=="LA"
replace  county = "ANNE ARUNDEL" if homecity=="ROSE HAVEN" & stab=="MD"
replace  county = "BALTIMORE" if homecity=="COCKESVILLE" & stab=="MD"
replace  county = "CARROLL" if homecity=="FINKSBURG" & stab=="MD"
replace  county = "HARFORD" if homecity=="ABERDEEN PROVING GROUND" & stab=="MD"
replace  county = "KNOX" if homecity=="APPLETON" & stab=="ME"
replace  county = "ST JOSEPH" if homecity=="CENTREVILLE" & stab=="MI"
replace  homecity = "FOWLERVILLE" if homecity=="FOWERVILLE" & stab=="MI"
replace  county = "LIVINGSTON" if homecity=="FOWLERVILLE" & stab=="MI"
replace  county = "OAKLAND" if homecity=="WHITE LAKE" & stab=="MI"
replace  homecity = "SHIAWASSEE" if homecity=="SHIAWASSE" & stab=="MI"
replace  county = "SHIAWASSEE" if homecity=="SHIAWASSEE" & stab=="MI"
replace  county = "BARRY" if homecity=="FREEPORT" & stab=="MI"
replace  county = "INGHAM" if homecity=="LANSING" & stab=="MI"
replace  county = "RAMSEY" if homecity=="SAINT PAUL" & stab=="MN"
replace  county = "RAMSEY" if homecity=="VADNAIS HEIGHTS" & stab=="MN"
replace  county = "ANOKA" if homecity=="ANDOVER" & stab=="MN"
replace  county = "RAMSEY" if homecity=="ST. PAUL" & stab=="MN"
replace  county = "LACLEDE" if homecity=="CONWAY" & stab=="MO"
replace  county = "BUCHANAN" if homecity=="SAINT JOSEPH" & stab=="MO"
replace  county = "ST LOUIS" if homecity=="SAINT LOUIS" & stab=="MO"
replace  county = "ST LOUIS" if homecity=="ST. LOUIS" & stab=="MO"
replace  county = "COLE" if homecity=="HENLEY" & stab=="MO"
replace  county = "MCDONALD" if homecity=="PINEVILLE" & stab=="MO"
replace  county = "DOUGLAS" if homecity=="DRURY" & stab=="MO"
replace  county = "DALLAS" if homecity=="LOUISBURG" & stab=="MO"
replace  county = "MONITEAU" if homecity=="JAMESTOWN" & stab=="MO"
replace  county = "BUCHANAN" if homecity=="SAINT JOSEPH" & stab=="MO"
replace county = "HANCOCK" if homecity=="BAY ST. LOUIS" & stab=="MS"
replace county = "PRENTISS" if homecity=="NEWSITE" & stab=="MS"
replace county = "LEWIS AND CLARK" if homecity=="WOLF CREEK" & stab=="MT"
replace county = "FORSYTH" if homecity=="WINSTON SALEM" & stab=="NC"
replace county = "ROWAN" if homecity=="LANDIS" & stab=="NC"
replace county = "WILKES" if homecity=="N. WILKESBORO" & stab=="NC"
replace homecity = "HAMPSTEAD" if homecity=="HAMESTEAD" & stab=="NC"
replace county = "PENDER" if homecity=="HAMPSTEAD" & stab=="NC"
replace county = "YADKIN" if homecity=="YADKINVILLE" & stab=="NC"
replace county = "WAKE" if homecity=="MORRISVILLE" & stab=="NC"
replace county = "BRUNSWICK" if homecity=="OAK ISLAND" & stab=="NC"
replace county = "MERRICK" if homecity=="CLARKS" & stab=="NE"
replace county = "WAYNE" if homecity=="WAYNE" & stab=="NE"
replace county = "JEFFERSON" if homecity=="PLYMOUTH" & stab=="NE"
replace county = "SARPY" if homecity=="LAVISTA" & stab=="NE"
replace county = "MERRIMACK" if homecity=="HENNIKER" & stab=="NH"
replace county = "ROCKINGHAM" if homecity=="HAMPSTEAD" & stab=="NH"
replace county = "BELKNAP" if homecity=="GILMANTON" & stab=="NH"
replace county = "BURLINGTON" if homecity=="WESTAMPTON" & stab=="NJ"
replace homecity = "KEARNY" if homecity=="POWDER SPRINGS" & stab=="NJ"
replace county = "HUDSON" if homecity=="KEARNY" & stab=="NJ"
replace county = "BURLINGTON" if homecity=="FORT DIX" & stab=="NJ"
replace county = "GLOUCESTER" if homecity=="WEST DEPTFORD" & stab=="NJ"
replace county = "MONMOUTH" if homecity=="SPRING LAKE HEIGHTS" & stab=="NJ"
replace homecity = "HADDON HEIGHTS" if homecity=="HADDEN HEIGHTS" & stab=="NJ"
replace county = "CAMDEN" if homecity=="HADDON HEIGHTS" & stab=="NJ"
replace county = "ALLEGANY" if homecity=="SCIO" & stab=="NY"
replace county = "KINGS" if homecity=="BROOKLYN" & stab=="NY"
replace county = "WOOD" if homecity=="ROSSFORD" & stab=="OH"
replace county = "LICKING" if homecity=="ST. LOUISVILLE" & stab=="OH"
replace county = "LOGAN" if homecity=="RIDGEWAY" & stab=="OH"
replace county = "CUYAHOGA" if homecity=="BROADVIEW HEIGHTS" & stab=="OH"
replace county = "UNION" if homecity=="ELGIN" & stab=="OR"
replace county = "WESTMORELAND" if homecity=="AVONMORE" & stab=="PA"
replace county = "PIKE" if homecity=="LACKAWAXEN" & stab=="PA"
replace county = "SULLIVAN" if homecity=="LOPEZ" & stab=="PA"
replace county = "BERKS" if homecity=="NEW BERLINVILLE" & stab=="PA"
replace county = "LACKAWANNA" if homecity=="GREENFIELD" & stab=="PA"
replace county = "CUMBERLAND" if homecity=="NEW KINGSTOWN" & stab=="PA"
replace county = "ALLEGHANY" if homecity=="WEST VIEW" & stab=="PA"
replace county = "CHESTER" if homecity=="COCHRANVILLE" & stab=="PA"
replace county = "BONHOMME" if homecity=="TABOR" & stab=="SD"
replace county = "PENNINGTON" if homecity=="KEYSTONE" & stab=="SD"
replace county = "BRAZORIA" if homecity=="LIVERPOOL" & stab=="TX"
replace county = "FORT BEND" if homecity=="SUGARLAND" & stab=="TX"
replace county = "WEBB" if homecity=="EL CENIZO" & stab=="TX"
replace county = "CHEROKEE" if homecity=="JACKONSVILLE" & stab=="TX"
replace county = "GRAYSON" if homecity=="BELLS" & stab=="TX"
replace county = "FAIRFAX" if homecity=="FAIRFAX STATION" & stab=="VA"
replace homecity = "ALEXANDRIA" if homecity=="ALEXANDERIA" & stab=="VA"
replace county = "ALEXANDRIA" if homecity=="ALEXANDRIA" & stab=="VA"
replace county = "WINDSOR" if homecity=="WHITE RIVER JUNCTION" & stab=="VT"
replace county = "LAMOILLE" if homecity=="STOWE" & stab=="VT"
replace county = "FRANKLIN" if homecity=="ENOSBURG" & stab=="VT"
replace county = "WHITMAN" if homecity=="PARSONS" & stab=="WA"
replace county = "DANE" if homecity=="DEFOREST" & stab=="WI"
replace county = "DODGE" if homecity=="MAYVILLE" & stab=="WI"
replace county = "PIERCE" if homecity=="BAY CITY" & stab=="WI"
replace county = "RACINE" if homecity=="CALENDONIA" & stab=="WI"
replace county = "PUTNAM" if homecity=="MIDWAY" & stab=="WV"
replace county = "OHIO" if homecity=="VALLEY GROVE" & stab=="WV"
replace county = "SUMMERS" if homecity=="TALCOTT" & stab=="WV"

merge m:1 stab county using ./Apps/temp_crosswalk.dta
drop if _merge!=3 /*MASTER IS DEATHS FILE. USING IS CROSSWALK*/
/*IDEALLY THERE SHOULD BE NO _merge==1. THAT'S USING EVERY DEATH*/
*Currently looks like (2725)/(2725+161)=94% matching

rename _merge mergedeathcounty
gen monthcounty=month+countyfp
/*BUILD MONTHLY COUNTY DEATHS BY SERVICE*/
quietly bysort monthcounty: egen monthcountydeath=count(age)
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV {
  quietly bysort monthcounty: egen `servicebranch'monthcountydeath=total(servicebranch=="`servicebranch'")
  label var `servicebranch'monthcountydeath "`servicebranch' deaths this month-county"
}

/*ADDED 122910--RACE*/
quietly bysort monthcounty: egen BLACKmonthcountydeath=total(raceethnic=="BLACK OR AFRICAN AMERICAN")
quietly bysort monthcounty: egen WHITEmonthcountydeath=total(raceethnic=="WHITE")
quietly bysort monthcounty: egen HISPmonthcountydeath=total(raceethnic=="HISPANIC")
quietly bysort monthcounty: egen OTHmonthcountydeath=total(raceethnic!="HISPANIC" & raceethnic!="WHITE" & raceethnic!="BLACK OR AFRICAN AMERICAN"&raceethnic!="")

/*BUILD COUNTY DEATHS BY HOSTILE STATUS*/
quietly bysort monthcounty: egen Hmonthcountydeath=total(hostile=="H")
quietly bysort monthcounty: egen notHmonthcountydeath=total(hostile=="")
/*BUILD COUNTY DEATHS BY GENDER*/
quietly bysort monthcounty: egen FEMALEmonthcountydeath=total(gender=="F")
quietly bysort monthcounty: egen MALEmonthcountydeath=total(gender=="M")
/*BUILD COUNTY DEATHS BY WAR*/
quietly bysort monthcounty: egen IRAQmonthcountydeath=total(war=="Iraq")
quietly bysort monthcounty: egen AFGHANmonthcountydeath=total(war=="Afghanistan")
/*BUILD COUNTY DEATHS BY PAYGRADE*/
quietly bysort monthcounty: egen E3monthcountydeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03")
quietly bysort monthcounty: egen E4monthcountydeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03"|paygrade=="E04")
quietly bysort monthcounty: egen E3Pmonthcountydeath=total(paygrade!="E01" & paygrade!="E02" & paygrade!="E03"&paygrade!="")
quietly bysort monthcounty: egen E4Pmonthcountydeath=total(paygrade!="E01" & paygrade!="E02" & paygrade!="E03" & paygrade!="E04"&paygrade!="")
quietly bysort monthcounty: egen E5monthcountydeath=total(paygrade=="E01"|paygrade=="E02"|paygrade=="E03"|paygrade=="E04"|paygrade=="E05")
quietly bysort monthcounty: egen E5Pmonthcountydeath=total(paygrade!="E01"& paygrade!="E02"& paygrade!="E03" & paygrade!="E04" ///
	& paygrade!="E05" & paygrade!="")

quietly bysort monthcounty: egen OFFICERmonthcountydeath=total(substr(paygrade,1,1)=="W"|substr(paygrade,1,1)=="O")
quietly bysort monthcounty: egen ENLISTEDmonthcountydeath=total(substr(paygrade,1,1)=="E")


label var BLACKmonthcountydeath "Total BLACK deaths this month-county"
label var WHITEmonthcountydeath "Total WHITE deaths this month-county"
label var HISPmonthcountydeath "Total HISP deaths this month-county"
label var OTHmonthcountydeath "Total OTHER RACE deaths this month-county"
label var Hmonthcountydeath "Total HOSTILE deaths this month-county"
label var notHmonthcountydeath "Total non-HOSTILE deaths this month-county"
label var FEMALEmonthcountydeath "Total FEMALE deaths this month-county"
label var MALEmonthcountydeath "Total MALE deaths this month-county"
label var IRAQmonthcountydeath "Total IRAQ deaths this month-county"
label var AFGHANmonthcountydeath "Total AFGHAN deaths this month-county"
label var E3monthcountydeath "Total E3 or less paygrade deaths this month-county"
label var E4monthcountydeath "Total E4 or less paygrade deaths this month-county"
label var E5monthcountydeath "Total E5 or less paygrade deaths this month-county"
label var E3Pmonthcountydeath "Total more than E3 paygrade deaths this month-county"
label var E4Pmonthcountydeath "Total more than E4 paygrade deaths this month-county"
label var E5Pmonthcountydeath "Total more than E5 paygrade deaths this month-county"
label var OFFICERmonthtotaldeath "Total officer deaths this month-county"
label var ENLISTEDmonthtotaldeath "Total enlisted deaths this month-county"

count
duplicates drop monthcounty, force

count
keep monthstate monthstatedeath monthtotaldeath monthcounty *monthcountydeath *monthstatedeath *monthtotaldeath 
compress
sa ./Deaths/deathsbymonthcounty.dta, replace

/*HAVE TO START WITH ALL COUNTY-MONTHS SO I HAVE COUNTY 
MONTHS WITH NO DEATHS AND NO RECRUITS*/
use ./Unemployment/countyunemployment.dta, clear
keep if month>200109 & month<200608
tostring month, replace
gen monthcounty=month+fips
gen monthstate=month+substr(name,-2,.) 
replace monthstate=month+"DC" if name=="District of Columbia"
move monthcounty fips
sort monthcounty
/*MERGE IN DEATHS*/
merge 1:1 monthcounty using ./Deaths/deathsbymonthcounty.dta
replace monthcountydeath=0 if _merge==1 & monthcountydeath==. /*IF THERE WERE NO DEATHS IN THE COUNTY, SET=0*/
foreach servicebranch in AG AR AV CR CV FG FR FV MR MV NR NV WHITE BLACK HISP OTH H notH FEMALE MALE IRAQ AFGHAN ///
	E3 E4 E5 E3P E4P E5P OFFICER ENLISTED{
  quietly replace `servicebranch'monthcountydeath=0 if _merge==1 & `servicebranch'monthcountydeath==.
 }
rename _merge mergedeathtounemp

/*CAN'T JUST SET ALL DEATHS=0 BECAUSE TOTAL & STATE ARE >0. CALC VIA EGEN*/
/*THIS IS 'SPREADING' THE TOTAL DEATHS TO OTHER STATES WITHOUT ANY, SO THEIR MONTH-TOTAL IS CORRECTED*/
/*THIS IS NECESSARY BECAUSE I START WITH THE UNEMPLOYMENT DATA TO GET A FULL LIST OF MONTH-COUNTIES
BUT THEN WHEN I MERGE, NOT EVERYONE HAS A GIVEN TYPE OF DEATH, SO YOU HAVE TO APPLY THE VALUE TO ALL
THE STATE (AND TOTAL) VALUES TO EVERY COUNTY IN A GIVEN STATE*/

/*BY SERVICE*/
foreach servicebranch in "" AG AR AV CR CV FG FR FV MR MV NR NV WHITE BLACK HISP OTH H notH FEMALE MALE IRAQ AFGHAN ///
	E3 E4 E5 E3P E4P E5P OFFICER ENLISTED{
  quietly bysort month: egen `servicebranch'NEWmonthtotaldeath=max(`servicebranch'monthtotaldeath)
  quietly replace `servicebranch'monthtotaldeath=`servicebranch'NEWmonthtotaldeath
  drop `servicebranch'NEWmonthtotaldeath
  quietly replace `servicebranch'monthtotaldeath=0 if `servicebranch'monthtotaldeath==.
 }

/*SPREAD STATE DEATHS TO IN-STATE COUNTIES WITHOUT ANY DEATHS*/
/*BY SERVICE*/
foreach servicebranch in "" AG AR AV CR CV FG FR FV MR MV NR NV BLACK WHITE HISP OTH H notH FEMALE MALE IRAQ AFGHAN ///
	E3 E4 E5 E3P E4P E5P OFFICER ENLISTED{
  quietly bysort monthstate: egen `servicebranch'NEWmonthstatedeath=max(`servicebranch'monthstatedeath)
  quietly replace `servicebranch'monthstatedeath=`servicebranch'NEWmonthstatedeath
  drop `servicebranch'NEWmonthstatedeath
  quietly replace `servicebranch'monthstatedeath=0 if `servicebranch'monthstatedeath==.
}

sort monthcounty

************************************************************************
****** MERGE IN SEVERAL OUTSIDE DATA SETS**************
*RECRUITS
*ICPSR COUNTY CHAR
*MORTALITY
*UNEMPLOYMENT
*POPULATION
************************************************************************

/*MERGE IN RECRUITS*/
/*STARTED WITH LIST OF EVERY COUNTY MONTH, THEN MERGED IN DEATHS, NOW MERGE IN RECRUITS.*/
/*NOT ALL COUNTY-MONTHS HAVE A RECRUIT, SO THEY DON'T ALL GET THE TOTALS FOR STATE AND COUNTRY THEY DESERVE*/
/*(THOUGH THE COUNTY IS ZERO IF IT'S ZERO)*/
merge 1:1 monthcounty using ./Apps/`FILE'bymonthcounty.dta
rename _merge merge_apps
drop original-type countyfp-county
foreach var of varlist monthstaterecruit-NVHQ75monthstate {
 quietly bysort monthstate: egen new`var'=max(`var')
 quietly replace `var'=new`var'
 drop new`var'
}
foreach var of varlist monthstaterecruit-NVHQ75monthcounty{
 quietly replace `var'=0 if `var'==.
}


/*MERGE IN ICPSR COUNTY BACKGROUND DATA*/
destring fips, replace
sort fips
compress
drop if month<"200110"|month>"200607"
*Here I just use a renamed version of the ICPSR county data.
*A fresh downloaded version (July 25 2015) appears identical
merge m:1 fips using ./Data/icpsrcounties.dta
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
use "./Recruiters/Military Recruiting Data 1988-2005 New Version.dta"
keep state state_name yr qtr *rec*
rename yr year
rename state statefips
sort statefips year qtr
drop if year<2001
drop if year==2001 & qtr<4
compress
save ./Recruiters/Warner.dta, replace


use temp_county.dta
gen qtr=1
replace qtr=2 if apr==1|may==1|jun==1
replace qtr=3 if jul==1|aug==1|sep==1
replace qtr=4 if oct==1|nov==1|dec==1
destring statefips, replace
sort statefips year qtr
merge m:1 statefips year qtr using ./Recruiters/Warner.dta
/*RECRUITER DATA MISSING FOR DC, PR, ENDS IN 2004/2005*/
rename _merge mergerecruiters
drop if statefips==. /*WHO ARE THESE 28?*/

/** BUILD IN BETTER MORTALITY RATES*/
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

label var monthcountymort "County Mortality Rate"
label var monthstatemort "State Mortality Rate"
label var monthnationalmort "National Mortality Rate"


/**BUILD IN NATIONAL AND STATE UNEMPLOYMENT LEVELS*/
sort month
merge m:1 month using ./Unemployment/nationalunemp.dta
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
gen outofstate=monthtotaldeath-monthstatedeath
gen outofcounty=monthstatedeath-monthcountydeath
label var outofstate "Out of state deaths this month"
label var outofcounty "Out of county but in-state deaths this month"
gen Rmonthcountydeath=ARmonthcountydeath+MRmonthcountydeath+FRmonthcountydeath+NRmonthcountydeath
gen Rmonthstatedeath=ARmonthstatedeath+MRmonthstatedeath+FRmonthstatedeath+NRmonthstatedeath
gen Rmonthtotaldeath=ARmonthtotaldeath+MRmonthtotaldeath+FRmonthtotaldeath+NRmonthtotaldeath
label var Rmonthcountydeath "Active duty deaths this month-county"
label var Rmonthstatedeath "Active duty deaths this month-state"
foreach type in R AR FR MR NR WHITE BLACK HISP OTH H notH MALE FEMALE IRAQ AFGHAN E3 E4 E5 E3P E4P E5P OFFICER ENLISTED{
 gen `type'outofstate=`type'monthtotaldeath-`type'monthstatedeath
 gen `type'outofcounty=`type'monthstatedeath-`type'monthcountydeath
 label var `type'outofstate "`type' out of state deaths this month"
 label var `type'outofcounty "`type' out of county but in-state deaths this month"
}
/*CON IS MISSING RESERVE--ACTIVE DUTY ONLY*/
gen active=ARmonthcounty+MRmonthcounty+NRmonthcounty+FRmonthcounty
gen LNactive=ln(active+1)
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
gen yearcounty=string(year)+string(fips)

/*STATE TREND*/
tab statefips, gen(statefe)
gen mo=substr(month,5,2)
destring mo, replace
gen fancymonth=ym(year,mo)
tsset fips fancymonth
gen t=fancymonth-500 /*changed from 501 2/1/2016--1 to 58 not 0 to 57*/
tab statefips, gen(statetrend)
forvalues X=1/51 {
 replace statetrend`X'=statetrend`X'*t
}


/*STATE YEAR INTERACTED FE*/
gen stateyear=string(year)+string(statefips)
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
	E3monthcountydeath E3outofcounty E4monthcountydeath E4outofcounty E5monthcountydeath E5outofcounty///
	E3Pmonthcountydeath E3Poutofcounty E4Pmonthcountydeath E4Poutofcounty E5Pmonthcountydeath E5Poutofcounty///
	OFFICERmonthcountydeath OFFICERoutofcounty ENLISTEDmonthcountydeath ENLISTEDoutofcounty
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
forvalues X=3/5{
label var L1E`X'monthcounty "Lag E`X' paygrade In-County Deaths"
label var L1E`X'outofcounty "Lag E`X' paygrade Out-of-County Deaths"
label var L1E`X'Pmonthcounty "Lag E`X'-plus paygrade In-County Deaths"
label var L1E`X'Poutofcounty "Lag E`X'-plus paygrade Out-of-County Deaths"
}
compress
sa ./Data/county`FILE'_raw.dta, replace

} //END HUGE LOOP OVER BOTH TYPES OF APPLICANTS
