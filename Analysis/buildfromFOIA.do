set more off
cd $dir
clear

*This file is the first file necessary to reconstruct the entire project from scratch.
*It takes the FOIA data on military applicants (in text format, in the By_Zip_and_Date folder)
*insheets it, save it in Stata format, and appends all 16 years of data together.
*This happens separately for Applicants, Contracts, and Accessions, since those are different data sets.
*The data is saved as APP_all, CON_all, and ACC_all

*At one point I also compressed each of these by date. I don't believe I actually use that in analysis. 

/*INSHEET DATA AND SAVE AS STATA*/
foreach year in 90 91 92 93 94 95 96 97 98 99 00 01 02 03 04 05 06 {
 foreach type in APP CON ACC {
  /*bring in the data*/
  insheet using ./By_Zip_and_Date/A_FY`year'_`type'.txt, clear
  /*split the data into vars*/
  rename v1 original
  gen zip=substr(original,1,5)
  destring zip, replace
  gen unit=substr(original,6,2)
  gen date=substr(original,8,8)
  destring date, replace
  gen afqt=substr(original,16,2)
  destring afqt, replace
  gen educ=substr(original,18,2)
  destring educ, replace
  gen type="`type'"
  compress
  save ./Apps/A_FY`year'_`type', replace
 }
}
*/

/*MAKE THREE GIANT DATASETS FROM YEARLY SETS*/
clear
set mem 2g
foreach type in APP CON ACC{
 clear
 foreach year in 90 91 92 93 94 95 96 97 98 99 00 01 02 03 04 05 06 {
  append using ./Apps/A_FY`year'_`type'.dta
 }
 compress
 sa ./Apps/`type'_all.dta, replace
} 

/*2015/7/4 Collapsing by date isn't useful, so I'm commenting this out.
/*COLLAPSE GIANT SETS BY DATE*/
clear
set mem 2g
foreach type in APP CON ACC{
 use ./App/`type'_all.dta, clear
 bysort date: egen totapp=count(date)
 count 
 foreach var in AG AR AV AZ CR CV CZ FG FR FV FZ MR MV MZ NR NV NZ ZV ZZ{
  gen `var'=0
  replace `var'=1 if unit=="`var'" 
  bysort date: egen tot`var'=total(`var')
  drop `var'
  rename tot`var' `var'
  compress
 }
 duplicates drop date, force
 count
 keep date type totapp AG AR AV AZ CR CV CZ FG FR FV FZ MR MV MZ NR NV NZ ZV ZZ
 save ./App/`type'_bydate.dta, replace
 /*DO A SIMPLE GRAPH*/
 /*tostring date, replace
 generate fancydate=date(date, "YMD")
 destring date, replace
 graph twoway line totapp fancydate*/
 /*SAVE JUST RECENT YEARS*/
 keep if date>20000100
 save ./New/`type'_bydate2000.dta, replace
}
*/
 
