#Occupational Fatalities and the Labor Supply: Evidence from the Wars in Iraq and Afghanistan#
by Garret Christensen, UC Berkeley

Please send questions or comments to <garret@berkeley.edu>

# Readme #
____________________________________________________

This repository contains the data and script files necessary to reproduce the above paper from the original raw data. Note that I learned about the finer points of reproducibility after I had already spent years on the project, so the workflow may not be what I'd set up if I started the project from scratch, but such is life. The goal is that anyone can download the original raw data and reproduce my final results with two clicks: one click in Stata to run every bit of analysis from start to finish, and one click in LaTeX to compile the output into the paper.

##Data##
The data consists of many parts, though there are two main files: deaths and recruits.
These are available for download from Harvard's Dataverse, but size permitting, they will also be available in this repository. 

[Recruits 1990-2006](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/27772 "Recruits Data Link")

[Deaths 1990-2010](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/27763 "Deaths Data Link")

Most of the analysis in the paper focuses on the period 2001-2006, because that is the period for which I have the best data and that is the period during which the deaths of primary interest were occurring. 

##Analysis##
The analysis necessary to reproduce the paper is found in this repository. Analysis files are found in the "Analysis" subfolder, though a stray .do file used to organize an intermediate data set (data on the number of recruiters by state, for example) may be in the subfolder with the relevant data, however.

To reproduce the analysis, run the "doeverything.do" file in Stata 12 or higher.
This file calls numerous other .do files. The file begins with several files with the "build" prefix that turn raw data (deaths, recruits, unemployment, county characteristics, recruiters) into the combined analysis data. Skip these if you so desire. 

##Paper##
The paper is written in LaTeX and (mostly) includes tables produced directly by the "doeverything.do" script files. The paper is the "militaryrecruiting.tex" found in the "Papers" subfolder.  

Please let me know if you have trouble reproducing my work!

