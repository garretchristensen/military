/*This file builds the necessary death dataset*/
/*The data came from a no longer functional US DOD website.
The original data files are oef_coalition, oef_list_of_names, oif_coalition, and oif_list_of_names.*/
//Annoyingly, the DOD data in Excel has several rows of non-useful information, 
//so I manually exported them to text, and this file uses those text files. Bad form, I know.

/*This script builds oef_coalition, oef_all, oif_coalition, oif_all, and allUS*/
/*allUS is the only file that I actually use in the analysis, as of July 2015*/

//It also collapses 2001-on deaths by date, and 1990-on deaths by date. 
//These files (deathsbydate, deathsbydate90) are used to make `Table 1' in DataSummaryTable.do
//The 1990-on death file starts from the raw FOIA data.

clear
set mem 20m
cd $dir\Deaths


/*CLEAN AFGHANISTAN FOREIGNER DEATHS*/
import excel using .\raw\oef_coalition.xls, clear
rename A dateofdeath
rename B name
rename C rank
rename D age
rename E unit
rename F servicecomponent
rename G homeofrecordstate
rename H homeofrecordcity
rename I hostile
rename J cityofloss
rename K casualtycountry
rename L homeofrecordcountry
drop if homeofrecordcountry=="usa"
compress
sa oef_coalition, replace

/*MERGE AFGHANISTAN FOREIGN WITH US DEATHS*/
insheet using .\raw\oef_list_of_names.txt, clear //This is 
append using oef_coalition
move servicecomponent name
move dateofdeath service
replace homeofrecordcountry="Canada" if homeofrecordcountry=="CA"
replace homeofrecordcountry="Micronesia" if homeofrecordcountry=="FM"
gen war="Afghanistan"	
rename homeofrecordcity homecity
rename homeofrecordcounty homecounty
rename homeofrecordstate homestate
rename homeofrecordcountry homecountry
compress
save oef_all, replace

/*CLEAN IRAQ FOREIGNER DEATHS*/
import excel using .\raw\oif_coalition.xls, clear
rename A dateofdeath
rename B name
rename C rank
rename D age
rename E unit
rename F servicecomponent
rename G homeofrecordstate
rename H homeofrecordcity
rename I hostile
rename J cityofloss
rename K casualtycountry
rename L homeofrecordcountry
compress
sa oif_coalition, replace

/*MERGE IRAQ FOREIGNER DEATHS WITH US DEATHS*/
insheet using .\raw\oif_list_of_names.txt, clear
append using oif_coalition
move servicecomponent name
move dateofdeath service
replace homeofrecordcountry="Canada" if homeofrecordcountry=="CA"
replace homeofrecordcountry="Micronesia" if homeofrecordcountry=="FM"
replace homeofrecordcountry="Panama" if homeofrecordcountry=="PM"
replace homeofrecordcountry="Palau" if homeofrecordcountry=="PS"
replace homeofrecordcountry="Marshall Islands" if homeofrecordcountry=="RM"
replace homeofrecordcountry="US" if name=="TAYLOR DAVID GLADNEY JR"
gen war="Iraq"
rename homeofrecordcity homecity
rename homeofrecordcounty homecounty
rename homeofrecordstate homestate
rename homeofrecordcountry homecountry
compress
save oif_all, replace
count
/*MERGE IRAQ AND AFGHANISTAN DEATHS*/
append using oef_all
count
compress
save alldeaths, replace
count
keep if homecountry=="US"
count
compress
note: This is the major deaths dataset, featuring only US deaths. Built in builddeaths.do
save allUS, replace

*Deaths are collapsed by date here.
*This is used in Table 1 construction by DataSummaryTable.do

/*COLLAPSE ALL DEATHS BY DATE*/
bysort dateofdeath: egen totaldeaths=count(dateofdeath)
gen US=1 if homecountry=="US"
gen other=1 if homecountry!="US"
bysort dateofdeath: egen totalUS=count(US)
bysort dateofdeath: egen totalother=count(other)
duplicates drop dateofdeath, force
keep dateofdeath totaldeaths totalUS totalother
rename dateofdeath date
sort date
save deathsbydate, replace



/*CREATE THE DATASET OF US DEATHS FROM 1990 ON USING DATA FROM FOIA 10-F-1140*/
/*RECEIVED VIA USPS MARCH 2011*/

clear
cd $dir/FOIA/DeathsSince1990
insheet using ./raw/Worldwide.csv
/*EDIT THE WORLDWIDE DEATHS SO THEY'RE IN THE SAME FORMAT AS ORIGINAL OEF/OIF DEATHS*/
replace service="M" if service=="USMC"
replace service="N" if service=="USN"
replace service="A" if service=="USA"
replace service="F" if service=="USAF"
replace component="R" if component=="USA"|component=="USAF"|component=="USMC"|component=="USN"
replace component="G" if component=="ANG"|component=="ARNG"
replace component="V" if component=="USAFR"|component=="USMCR"|component=="USNR"|component=="USAR"
rename hostilenonhostileindicator hostile
replace hostile="" if hostile=="NH"
gen war="Worldwide"
sa Worldwide.dta, replace

insheet using ./raw/OEF.csv, clear
gen war="Afghanistan"
sa OEF.dta, replace

insheet using ./raw/OIF.csv, clear
gen war="Iraq"
sa OIF.dta, replace

insheet using ./raw/OND.csv, clear
gen war="Iraq"
sa OND.dta, replace

use Worldwide.dta, clear
append using OEF.dta
append using OIF.dta
append using OND.dta
note: This is the complete set of 1990-on US deaths, built in builddeaths.do
sa post90deaths.dta, replace

/*COLLAPSE ALL (POST90) DEATHS BY DATE*/
cd $dir/Deaths
use post90deaths.dta, clear
rename homeofrecordstate homestate
rename homeofrecordcounty homecounty
rename homeofrecordcity homecity
gen Hdeath=1 if hostile=="H"
bysort dateofdeath: egen totaldeaths=count(dateofdeath)
bysort dateofdeath: egen totalHdeaths=count(Hdeath)
/*Post1990 data has no foreign deaths; drop that section*/
duplicates drop dateofdeath, force
keep dateofdeath totaldeaths totalHdeaths
rename dateofdeath date
sort date
save deathsbydate90, replace

cd $dir //Put yourself back in main dir so other builds work.




