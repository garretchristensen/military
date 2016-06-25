/*THIS FILE DOES EVERYTHING*/

version 12
global dir="C:/Users/garret/Documents/Research/Military" //Change this as necessary. 
cd $dir  
//Clone the GitHub repo at https://github.com/garretchristensen/military to get the necessary folder structure.


/*BUILD FROM THE RAW DATA*/
*do ./Analysis/buildfromFOIA.do //Takes original FOIA .txt datasets, compiles into one file of all APP, CON, ACC
*do ./Analysis/builddeaths.do //Takes the original DOD death data from OIF and OEF and makes a combined US death dataset
*do ./Analysis/buildunemployment.do //Formats BLS unemployment data
*do ./Analysis/buildcounty.do // puts together APPLICANTS, death, recruiter, mortality data
							 // separately does the same with CONTRACTS
*do ./Analysis/buildcounty90.do //puts together APPLICANTS DATA with ALL deaths from 1990 on,
							//not just 2001-on combat
							//separately does the same with CONTRACTS
													
*Run all five of these in order to create necessary ANALYSIS data sets*/


/*SHOW DISPERSION OF DEATHS*/
do ./Analysis/DataSummaryTable.do //simple data summary table
do ./Analysis/table1graph.do //prints the rec/pop, death/pop, and rec/death graphs, by state
do ./Analysis/table1bycounty.do //graphs binomial hazard rate

/*NATIONAL LEVEL STUFF*/
do ./Analysis/deathsvrecruits.do

/*RUN MAIN LINEAR REGRESSIONS*/
do ./Analysis/redefined.do /*linear and log-linear regressions, weighted*/
do ./Analysis/interactionscontrols.do /*linear regression recruit/mort controls and interactions*/

/*OTHER FUNCTIONAL FORMS*/
*do ./Analysis/redefinedpoisson2015.02.17.do /*poission regs, with recruit/mort controls, and interactions*/
*do ./Analysis/squareroot2015.2.17.do /*square root of recruits*/
*do ./Analaysis/nebinom2015.2.17.do /*negative binomial*/

/*OTHER*/
*do ./Analysis/90deaths/redefinedpoisson90_2015.02.17.do /*Main P-regs with 90-2006 deaths*/
*do ./Analysis/redefrunninglags2013.12.11.do /*poisson and linear regs for longer-term lags*/
*do ./Analysis/redefbyservice2013.12.11.do /*reshape the data month-county-service branch, run linear and possion regs*/
*do ./Analysis/redefhighquality2015.02.18.do /*P-regs of deaths of different types, and interactions with diff war deaths*/
