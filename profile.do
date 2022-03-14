* Pathing and setup
log close _all
snapshot erase _all
clear all

*storage of NAMCsd raw data
global r  				`"  "C:\Users\my name\my project\raw data\" "'

*analysis data
global d 				`"  "C:\Users\my name\my project\data\" "'


*results
global tab  		`"  "C:\Users\my name\my project\tables\" "'
global fig		`"  "C:\Users\my name\my project\figures\" "'


*Data were downloaded from https://ftp.cdc.gov/pub/Health_Statistics/NCHS/namcs_public_use_files/*
*1991 datasets and documentation: namcs91.exe; namcs91d.exe; namcs91doc.pdf*

*	Preparing NAMCS91:
******************************
use "$r\namcs91_raw.dta" , clear

* 1) Set up relevant dummies
gen female = sex == 1
gen nonwhite = race != 1
gen hispanic = ethnicity == 1
gen northeast = geo_reg == 1
gen midwest = geo_reg == 2
gen south = geo_reg == 3
gen west = geo_reg == 4
//Hellerstein defines specialists as 
//physicians who are not in general practice, family practice, or basic pediatrics.
gen specialist = (phys_special != "GP" & phys_special != "FP" & phys_special != "PD") 
//Medicare patients 
gen temp = selfpay + medicaid + other_gov_ins + private_ins + hmo_pre_paid
replace medicare = 0 if temp != 0  


* 2) Drop observations with unknown payment
gen temp1 = selfpay + medicaid  + medicare + other_gov_ins + private_ins + hmo_pre_paid
keep if temp1 == 1

compress
save "$d\namcs91.dta", replace




*	Preparing NAMCS91d:
****************************
use "$r\namcs91d_raw.dta" , clear


* 1) Removing observations with missing values:
***********************************************
replace generic_id = .b if generic_id == 50000
replace generic_status = .b if generic_status == 3
replace prescription_status = .b if prescription_status == 3
replace composition_status = .b if composition_status == 3 | composition_status == 6

drop if missing(generic_id)|missing(generic_status)|///
  missing(prescription_status)|missing(composition_status)

 
* 2) Creating required variables:
**********************************
** 2.1) Define 8 largest drug classes, see Table 3 and page 79 in Hellerstein's paper
gen major_drug_class = ///
	drug_class == 3 | drug_class == 5 | drug_class == 6 | drug_class == 10 | ///
	drug_class == 12 | drug_class == 15 | drug_class == 17 | drug_class ==  19


** 2.2) Creating some dummies
gen female = sex == 1
gen nonwhite = race != 1
gen hispanic = ethnicity == 1
gen northeast = geo_reg == 1
gen midwest = geo_reg == 2
gen south = geo_reg == 3
gen west = geo_reg == 4

gen specialist = (phys_special != "GP" & phys_special != "FP" & phys_special != "PD") 
gen temp = selfpay + medicaid + private_ins + hmo_pre_paid
replace medicare = 0 if temp != 0

replace generic_status = 0 if generic_status == 2
replace prescription_status = 0 if prescription_status == 2

tab drug_class, gen (drug_class_)
label variable drug_class_3 "Antimicrobial"
label variable drug_class_5 "Cardiovascular-renals"
label variable drug_class_6 "Central Nervous System"
label variable drug_class_10 "Hormones"
label variable drug_class_12 "Skin/Mucous Membranes"
label variable drug_class_15 "Ophthalmics"
label variable drug_class_17 "Pain Relief"
label variable drug_class_19 "Respiratory Test"


** 2.3) Create multisource indicator
*** 2.3.1) Create id for drugs with multiple ingrediants
replace ingredients = generic_id if ingredients == .

*** 2.3.2) Check whether there are both generic and trade-name drugs for each ingredients
bys ingredients: egen counter = mean(generic_status) 
bys ingredients: gen multisource = (counter >0 & counter <1)
drop counter


** 2.4) Set up physician averages
foreach x in age female nonwhite hispanic medicare medicaid hmo_pre_paid private_ins{
	cap: drop mean_`x'
	bys physician_id: egen mean_`x' = mean(`x')
}


* 3) Keeping relevant variables
****************************
//Dropping conditions
keep if prescription_status == 1 & multisource == 1 & major_drug_class == 1 & order_of_drug == 1  
* (selfpay == 1 | medicaid == 1 | private_ins == 1 | hmo_pre_paid == 1 | medicare == 1)
gen temp1 = selfpay + medicaid + medicare + private_ins + hmo_pre_paid
keep if temp1 == 1

keep ///
drug_id drug_name generic_id generic_name generic_status drug_class drug_class_* ingredients ///
age female nonwhite hispanic west northeast midwest south geo_reg specialist mean_* /// 
selfpay medicare medicaid private_ins hmo_pre_paid   ///
geo_reg phys_special phys_type physician_id patient_id

compress
save "$d\namcs91d.dta", replace
