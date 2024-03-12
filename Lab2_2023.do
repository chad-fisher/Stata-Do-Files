**************************************************************
* Nutr 307: Regression for Nutrition Policy
* Stata Lab 2
* Chad Fisher
*Parke Wilde Jan 21, 2018 
*Edited by Alissa Ebel, February 6, 2020
*Edited by Sarah Laves and Parke Wilde, March 2, 2021 
*Edited by Lizzy Cooper, Emma Laprise, and Parke Wilde, February 24, 2022
*Edited by Yu-Hsiang Chiu and Parke Wilde, February 27, 2023
**************************************************************
* Objectives 
**************************************************************
/*
1. Merge various datasets into one master dataset 
2. Understand and explore variables 
3. Generate, categorize, and label variables
4. Perform, understand, and interpret regressions
5. Create & understand figures showing multi-variable regression 
6. Begin to see / understand loops & programming 
*/ 

**************************************************************
* Setting Up 
**************************************************************
//Set working directory (replace with your own folder location)
cd "C:\Users\chadl\OneDrive\Desktop\NUTR 307\Lab 2"

//Clear previous data from memory*
capture clear all //  clears anything in the existing memory 

// Create a global macro $keepvars to hold the names of variables to keep.
// A macro is a programming variable in Stata.
// Later, every time we type $keepvars, Stata will use this variable list.
// See the final section of this lab for more detail about macros. 
global keepvars cuid newid interi  ///
  bls_urbn fam_size fam_type ///
  perslt18 persot64 region respstat  ///
  inclass psu ref_race sex_ref hisp_ref ///
  high_edu fincatax fdhomepq jfs_amt build ///
  age_ref earncomp educ_ref

**************************************************************
* Opening Datasets & Merging 
**************************************************************
* Clean the Data and Keep Only Selected Consumer Units (CUs) 
* This section of code reads 4 different survey files and combines them. 
*Note: These data are not very clean. Some people began the study late, and we only want people that interviewed the entire time. To do that, we keep only folks that had their 2nd interview in quarter 2(q2) , 3rd in q3, 4th in q4, and 5th in 2014 q1. We don't include 2013 q1, as they didn't include some important variables.*  

//Keep just consumer units (CUs) that had their second interview in quarter 2 of 2013 
use fmli132 if interi==2  // Keeps just selected observations.
summarize                 // The raw data have too many variables! 
keep $keepvars	          // Keeps just selected variables.	
summarize                 // Better. Not too many variables.						
save apr2013, replace
clear

//Keep just CUs that had their third interview in quarter 3 of 2013
use fmli133 if interi==3                     
keep $keepvars            // Using the macro $keepvars saves us time.
save july2013, replace
clear

//Keep just CUs that had their fourth interview in quarter 4 of 2013
use fmli134 if interi==4                   
keep $keepvars
save oct2013, replace
clear

//Keep just CUs that had their fifth interview in quarter 1 of 2014
use fmli141 if interi==5             
keep $keepvars
save jan2014, replace
clear
									
// Stack the 4 single-quarter datasets, one on top of the other 
use apr2013, clear				/*start with the quarter 2 dataset*/
append using july2013 oct2013 jan2014 	
save master.dta, replace
tab interi					    /*check how many observations for each quarter*/

summarize

// Add labels to some variables
label var bls_urbn "rural/urban status (=1 for urban, =2 for rural)"
label var sex_ref "sex (=1 for male, =2 for female)"
label var perslt18 "number of children less than 18yo"
label var inclass "income class (categorical variable)"
label var fincatax "annual income after taxes in dollars"
label var fdhomepq "food-at-home (grocery) spending per quarter in dollars"
label var jfs_amt "food stamp benefit amount in dollars"
// See how the variable labels work
describe

// Generate a SNAP participation variable (=1 when jfs_amt>0)
// This creates a binary or "dummy" variable for SNAP participants 
generate yessnap = (jfs_amt>0)
label var yessnap "SNAP benefits (1 = yes)"

// Recode variables to have clearer names
tab sex_ref
tab bls_urbn
// It is easier to understand "male" than "sex_ref" 
gen male = (sex_ref=="1")
// And it is easier to understand "urban" than "bls_urbn"
gen urban = (bls_urbn=="1")
tab male 
tab urban

describe inclass       // inclass storage type is "string" (Stata letters/symbols)
tab inclass            // but inclass values look like numbers

// Make a numeric income category variable (ninclass) and label it 
gen ninclass = real(inclass)          // generates a new numeric variable
label var ninclass "income category"  // labels the variable
label define inccats ///              // creates a new label style for values
01 "Less than $5,000" ///
02 "$5,000 to $9,999" ///
03 "$10,000 to $14,999" ///
04 "$15,000 to $19,999" ///
05 "$20,000 to $29,999" ///
06 "$30,000 to $39,999" ///
07 "$40,000 to $49,999" ///
08 "$50,000 to $69,999" ///
09 "$70,000 and over" 

//Assigns the labels you created to the values of the ninclass variable
label values ninclass inccats

// Tabulate ninclass (notice how nicely the variable labels show up)
tab ninclass, missing 
// The missing option puts any missing values in their own row. 
// But we have no missing values.

**************************************************************
* Descriptive Statistics
**************************************************************
gen income = fincatax / 12        // converts annual income to monthly
gen foodhome = fdhomepq /3        // converts quarterly food to monthly
label var foodhome "monthly at-home (grocery) spending in dollars"
gen incomesq = income^2           // a quadratic term for income
summarize foodhome jfs_amt fam_size male urban income

// Compare results for SNAP and non-SNAP
summarize foodhome jfs_amt fam_size male urban income if yessnap==0
summarize foodhome jfs_amt fam_size male urban income if yessnap==1

// An easier way to see results for SNAP and non-SNAP
mean foodhome jfs_amt fam_size male urban income, over(yessnap)

**************************************************************
* Regressions
**************************************************************
// Linear model. The earlier labels explain the variable names.
regress foodhome income fam_size perslt18 male urban jfs_amt
estimates store linear

// Quadratic model.
regress foodhome income incomesq fam_size perslt18 male urban jfs_amt
estimates store quadratic

// Model with binary variables for SNAP participation.
regress foodhome income fam_size perslt18 male urban yessnap
estimates store binarySNAP

*Display the estimates in a single table.*
estimates table linear quadratic binarySNAP, star

//Play around with the regressions; try some other variables.
 

**************************************************************
* Graphs and Output
**************************************************************
keep if income <= 10000    // remove some outliers from charts
* We say "in 1/500" to show just first 500 observations in scatter plot.
twoway (scatter foodhome fam_size) (lfit foodhome fam_size) in 1/500

* After making this second plot, save the image to a location on your computer.
twoway (scatter foodhome income) (lfit foodhome income) in 1/500

* The "cloud of data" with a binary explanatory variable.
twoway (scatter foodhome yessnap) (lfit foodhome yessnap) in 1/500

* A two-color scatter plot for participants and non-participants.
gen food_snap = foodhome if yessnap==1
gen food_no_snap = foodhome if yessnap==0
twoway (scatter food_snap income) (scatter food_no_snap income) ///
 (lfit food_snap income) (lfit food_no_snap income) in 1/500

**************************************************************
* More Information About Loops & Programming 
**************************************************************
* Borrowed from Professor Aker's Impact Evaluation class 
  	*Local macros: programming variables (for loops and other uses) 
	*Local macros are more flexible than scalars (numbers) and take ANY value
	*Coding requires: `variable_name' syntax (notice distinctive single quotes) 
	*Stata replaces `variable_name' with the content of the variable.
	*Stata turns the name of the local variable turquouise.
	local ten = 10
	dis `ten'
	gen age = `ten' * 10
	browse age                 // afterwards, close the browsing window

	*Global macros: longer-lasting programming variables (for loops and other uses)
	*Local and global macros can contain numbers, strings, lists, etc
	*Coding requires: $variable_name syntax (dollar sign indicates global macro)
	*Global macros last until we exit Stata (local macros are more temporary)
	local a = "2+2"
	di `a'
	di "`a'"
	global b = "3+3"
	di $b
	di "$b"
  
  * Loops
	* forval, foreach are the commands to create loops in stata
	* forvalues loops over a predefined set of numbers
	forvalues i = 10(-1)1{
		display "This is iteration `i'"
	}

	forvalues x =-10(1)0{
		di `x'^2
	}

	*foreach loops over strings instead of numbers
	foreach method in "sum" "tab"{
		`method' build
	}
	 
	local controls "age_ref earncomp educ_ref"
		foreach x of varlist `controls'{
		di "`x'"
		sum `x', d
	}

 
 
 
 






