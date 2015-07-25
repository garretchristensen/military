/*THIS FILE DOES FUCKING EVERYTHING*/

cd C:/Users/garret/Documents/Research/Military
/*BUILD FROM THE RAW DATA*/
do ./Analysis/buildfromFOIA2015.07.04.do //Takes original FOIA .txt datasets, compiles into one file of all APP, CON, ACC

do ./Analysis/buildcounty2015.07.04.do // puts together APPLICANTS, death, recruiter, mortality data*/
*do ./Analysis/buildCONcounty2013.10.6.do /*puts together CONTRACTS, death, recruiter, mortality data*/

do ./Analysis/90deaths/buildcounty90.2014.11.27.do /*puts together APPLICANTS DATA with ALL deaths, not just combat*/
do ./Analysis/90deaths/buildCONcounty90.2014.11.27.do /*put together CONTRACTS data with ALL deaths, not just combat*/
*Run all four of these in order to create necessary data sets*/


/*SHOW DISPERSION OF DEATHS*/
*do DataSummaryTable2014.11.27.do //simple data summary table
*do table1graph2015.1.17.do //prints the rec/pop, death/pop, and rec/death graphs, by state
*do table1bycounty2015.1.17.do //graphs binomial hazard rate

/*NATIONAL LEVEL STUFF*/
do deathsvrecruits2015.1.17.do

/*RUN MAIN REGRESSIONS*/
*do ./Analysis/redefined2014.1.8.do /*linear regressions, weighted and unweighted*/
*do ./Analysis/redefinedinteractions2013.8.3.do /*linear regression interactions*/
*do ./Analysis/squareroot2015.2.17.do /*square root of recruits*/
*do ./Analaysis/nebinom2015.2.17.do /*negative binomial*/

*do ./Analysis/redefinedpoisson2015.02.17.do /*poission regs, with recruit/mort controls, and interactions*/
do ./Analysis/90deaths/redefinedpoisson90_2015.02.17.do /*Main P-regs with 90-2006 deaths*/
*do ./Analysis/redefrunninglags2013.12.11.do /*poisson and linear regs for longer-term lags*/
*do ./Analysis/redefbyservice2013.12.11.do /*reshape the data month-county-service branch, run linear and possion regs*/
*do ./Analysis/redefhighquality2015.02.18.do /*P-regs of deaths of different types, and interactions with diff war deaths*/
