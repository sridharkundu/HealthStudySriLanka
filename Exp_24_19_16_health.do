**Health expenditure
****************************************************************************************/
clear all
set more off
set scheme s1color
graph set window fontface "Garamond"
	glo macro "D:\macro\WBSrilanka\HumanCap" // <<==Sridhar
	glo do 			"${macro}/Health/do"
	glo hies16 		"${macro}/HIES16/raw"
	glo hies19 		"${macro}/HIES19/raw"
	glo bright2425 		"${macro}/BRIGHT/Survey1"		
	glo output 		"${macro}/output"
	glo input 		"${macro}/input"
	glo temp 		"${macro}/temp"
	glob wbest		"${macro}/WBestimate"
	glo graph 		"${macro}/graph"
****Chronology*************
**A.Year-2016
**B.Year-2019
**C. Year- 2024-25
****Estimation steps and processes used for each year as follows,
*1. Households and their status of health
*1.a. Demographic information for basic household information 
*2. Annualising the households' non-food expenditure- convering the weekly and monthly expenditure to annual
*3. Annualising the households' non-food expenditure- convering the weekly and monthly expenditure to annual*3. The health iterms items are identifield from the non-food items ///
*and added up separately to estimate the health expenditure
*4. Data on household level welfare have been sorted for further merger 
*5.Price Index
*6. Merger of all datasets
*7. Conversion of base year for welfare, education spending at household level using the price index and spatial index
*8. Construct indicators- household spending on health, spending share in welfare etc. 
**D. Append of the datasets for 2016,2019 and 2024-25
**E. Graphs and Analysis*********
**Graphs-National and Provincial

************************************************************************************************************************************************************************************************
*** Year-2016******************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************************************
* 1) Households and their health status
********************************************************************************
    use "${hies16}/sec_1_demographic_information", clear
	ren weight hhweight
replace hhweight=round(hhweight)
order hhid pid
sort hhid pid

**Household head characteristics
gen hh_head_type =1 if sex==2 & relationship==1  // 1- male, 2- female
replace hh_head_type=2 if sex==1 & relationship==1

gen head_ethncity= ethnicity if relationship==1
gen head_religion= religion if relationship==1
gen head_edu= education if relationship==1

collapse(max) person_serial_no hhweight sector hh_head_type head_ethncity ///
 head_religion head_edu, by(hhid district province)

  gen head_educ_cat = .
	replace head_educ_cat = 1 if inrange(head_edu, 0, 2)              // none/primary // Change codes by Sridhar
    replace head_educ_cat = 2 if inlist(head_edu, 3, 4)              // secondary (O/L–A/L)
    replace head_educ_cat = 3 if inrange(head_edu, 5, 7)             // TVET / diplomas
    replace head_educ_cat = 4 if inrange(head_edu, 8, 10)            // tertiary
   label define head_educ_cat 1 "None/Primary" 2 "Secondary (O/L–A/L)" 3 "TVET/Diploma" 4 "Tertiary", replace
    label values head_educ_cat head_educ_cat
drop head_edu
ren head_educ_cat head_edu
ren  person_serial_no hhsize //maximum person_serial_no is the hhsize
			gen popweight=hhweight*hhsize
order hhid 
sort hhid
save "${temp}/health_hh16",replace

*2. Annualising the households' non-food expenditure- convering the weekly and monthly expenditure to annual
********************************************************************************
use "${hies16}/sec_4_2_non_food_consumption_and_expenditure", clear
sort hhid
**Uniform estimation of all non-food consumption items
gen con_period=1 if nf_code>=2001 & nf_code<=2909  //one month
replace con_period=2 if nf_code>=3001 & nf_code<=3219 // 6 months
replace con_period=3 if nf_code>=3301 & nf_code<=3339 // 1 year
replace con_period=1 if nf_code>=3401 & nf_code<=3409
replace con_period=3 if nf_code>=3501 & nf_code<=3509
* Annualize each expenditure item
gen double nfe_annual_item = .
replace nfe_annual_item = nf_value * 12 if con_period == 1
replace nfe_annual_item = nf_value * 2 if con_period == 2
replace nfe_annual_item = nf_value *1     if con_period == 3
replace nfe_annual_item = 0 if missing(nfe_annual_item)

*3. The health iterms items are identifield from the non-food items ///
*and added up separately to estimate the health expenditure
********************************************************************************
*Health expenditure items
gen health_item=1 if inlist(nf_code, 2301,2302, ///
2303, 2304, 2305, 2306, 2307, 2308, 2309, 2310, 2319)
gen double health_exp = nfe_annual_item if health_item==1
replace health_exp = 0 if missing(health_exp)
keep if health_item==1
keep hhid nf_code health_exp

//drop if health==0 //only health expenditure is included
reshape wide health_exp, i( hhid) j( nf_code)

lab var health_exp2301 "Private medical practitioner fees"
lab var health_exp2302 "Ayurveda consultation fees"
lab var health_exp2303 "Consultation fees for specialists"
lab var health_exp2304 "Payment to medical laboratory for tests"
lab var health_exp2305 "Payment to private hospitals and nursing homes"
lab var health_exp2306 "Purchase of medical and pharmaceutical products"
lab var health_exp2307 "Spectacles"
lab var health_exp2308 "Hearing aids"
lab var health_exp2309 "Scan/C.T, Ultrasounds"
lab var health_exp2310 "Xray"
lab var health_exp2319 "Other health_exp expenditure"
foreach var of varlist health_exp2301- health_exp2319 {
replace `var'=0 if `var'==.
}
egen total_health_exp= rsum( health_exp2301- health_exp2319)
sort hhid
save "${temp}/health_exp16",replace

*4. Data on household level welfare have been sorted for further merger 
**************************************************************************
***International poverty measure- Welfare indicator
use "${wbest}/HIES_2016", clear
sum welfare
collapse(mean) welfare, by (hhid  year month)
sort hhid
save "$temp/welfare16", replace

*5.Price Index
*****************************************************************************
use "$wbest/NCPI_series_subgroups.dta",clear
sum cpi_base2013 cpi_base2013_food cpi_base2013_nonfood if year==2016
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
cpi_base2013 |         12    113.7917    2.438501        110        118
cpi_b~3_food |          0
cp~3_nonfood |          0
*/
keep if year==2016
sort year month
save "${temp}/NCPI_series_subgroups",replace

use "$wbest/spatial_priceindex.dta",clear
**Year of spatial price index is not mentioned
sort district 
save "${temp}/spatial_priceindex",replace

*6. Merger of all datasets
***************************************************************************
use "${temp}/health_hh16", clear
sort hhid
merge hhid using "${temp}/health_exp16"
drop _m
sort hhid
merge hhid using "${temp}/welfare16"
drop _m
sort hhid
order hhid sector district province hhsize hhweight popweight welfare
sort hhid
order year month
sort year month
merge m:1 year month using "$temp/NCPI_series_subgroups",nogen
sort district
merge m:1 district using "$temp/spatial_priceindex", keep(match master) nogen // will check from the collegues' do file
sort hhid

*7. Conversion of base year for welfare, education spending at household level using the price index and spatial index
*****************************************************************
foreach var of varlist health_exp2301- total_health_exp {
replace `var'=(`var'*avg2019nonfood)/cpi_base2013
replace `var'=`var'*lpindex1
}
gen   welfare_pc_real_month= (welfare* avg2019nonfood) / cpi_base2013
replace welfare_pc_real_month= welfare_pc_real_month * lpindex1
gen welfare_hh_real_ann= welfare_pc_real_month*hhsize*12

*8. Construct indicators- household spending on health, spending share in welfare etc. 
********************************************************************************
* Share
foreach var of varlist health_exp2301- total_health_exp {
gen `var'_share= 100 *(`var'/welfare_hh_real_ann)
}
*Quintiles
xtile quintile = welfare_pc_real_month[aw=hhweight], nquantiles(5)
label define q 1 "Q1 (poorest)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (richest)", replace
label values quintile q
sort hhid
save "${output}/health_humancap16_updt1",replace
use "${output}/health_humancap16_updt1",clear
*****************************************************************************************************************************************************************************
**Year 2019
******************************************************************************************************************************************************************
*1. Households and their status of health
*1.a. Demographic information for basic household information 
********************************************************************************

use "${hies19}/sec_1_demographic", clear
tostring district sector month psu snumber hhno nhh person_serial_no, replace force
replace month="0"+month if strlen(month)==1
replace snumber="0"+snumber if strlen(snumber)==1
replace person_serial_no="0"+person_serial_no if strlen(person_serial_no)==1
gen hhid=district+sector+month+psu+snumber+hhno
gen pid=district+sector+month+psu+snumber+hhno+person_serial_no
destring district sector month person_serial_no, replace force
ren finalweight hhweight
replace hhweight=round(hhweight)

**Household head characteristics
gen hh_head_type =1 if sex==2 & relationship==1  // sex 1- male, 2-female
replace hh_head_type=2 if sex==1 & relationship==1
gen head_ethncity= ethnicity if relationship==1
gen head_religion= religion if relationship==1
gen head_edu= education if relationship==1

collapse(max) person_serial_no hhweight sector hh_head_type head_ethncity ///
 head_religion head_edu, by(hhid district)
 
  gen head_educ_cat = .
	replace head_educ_cat = 1 if inrange(head_edu, 0, 2)              // none/primary // Change codes by Sridhar
    replace head_educ_cat = 2 if inlist(head_edu, 3, 4)              // secondary (O/L–A/L)
    replace head_educ_cat = 3 if inrange(head_edu, 5, 7)             // TVET / diplomas
    replace head_educ_cat = 4 if inrange(head_edu, 8, 10)            // tertiary
   label define head_educ_cat 1 "None/Primary" 2 "Secondary (O/L–A/L)" 3 "TVET/Diploma" 4 "Tertiary", replace
    label values head_educ_cat head_educ_cat
drop head_edu
ren head_educ_cat head_edu
ren  person_serial_no hhsize //maximum person_serial_no is the hhsize
			gen popweight=hhweight*hhsize
order hhid 
sort hhid
save "${temp}/health_hh19",replace

*2. Annualising the households' non-food expenditure- convering the weekly and monthly expenditure to annual
********************************************************************************
use "${hies19}/sec_4_2_nonfood", clear
tostring district sector month psu snumber hhno nhh, replace force
replace month="0"+month if strlen(month)==1
replace snumber="0"+snumber if strlen(snumber)==1
gen hhid=district+sector+month+psu+snumber+hhno
order hhid
sort hhid
**Categorising the non-food consumption items w.r.t their time period of consumption
gen con_period=1 if nf_code>=2001 & nf_code<=2419  //one month
replace con_period=3 if nf_code>=2421 & nf_code<=2422 // one year
replace con_period=1 if nf_code>=2501 & nf_code<=2608
replace con_period=3 if nf_code>=2609 & nf_code<=2613
replace con_period=1 if nf_code>=2701 & nf_code<=2909
replace con_period=2 if nf_code>=3001 & nf_code<=3219 // 6 months
replace con_period=3 if nf_code>=3301 & nf_code<=3339
replace con_period=1 if nf_code>=3341 & nf_code<=3419
replace con_period=3 if nf_code>=3501 & nf_code<=3519

* Annualize each expenditure item
gen double nfe_annual_item = .
replace nfe_annual_item = nf_value * 12 if con_period == 1
replace nfe_annual_item = nf_value * 2 if con_period == 2
replace nfe_annual_item = nf_value *1     if con_period == 3
replace nfe_annual_item = 0 if missing(nfe_annual_item)

*3. The health iterms items are identifield from the non-food items ///
*and added up separately to estimate the health expenditure
********************************************************************************
*Health expenditure items
gen health_item=1 if inlist(nf_code, 2301,2302, ///
2303, 2304, 2305, 2306, 2307, 2308, 2309, 2310, 2319)
gen double health_exp = nfe_annual_item if health_item==1
replace health_exp = 0 if missing(health_exp)
keep if health_item==1
keep hhid nf_code health_exp

//drop if health==0 //only health expenditure is included
reshape wide health_exp, i( hhid) j( nf_code)

lab var health_exp2301 "Private medical practitioner fees"
lab var health_exp2302 "Ayurveda consultation fees"
lab var health_exp2303 "Consultation fees for specialists"
lab var health_exp2304 "Payment to medical laboratory for tests"
lab var health_exp2305 "Payment to private hospitals and nursing homes"
lab var health_exp2306 "Purchase of medical and pharmaceutical products"
lab var health_exp2307 "Spectacles"
lab var health_exp2308 "Hearing aids"
lab var health_exp2309 "Scan/C.T, Ultrasounds"
lab var health_exp2310 "Xray"
lab var health_exp2319 "Other health_exp expenditure"
foreach var of varlist health_exp2301- health_exp2319 {
replace `var'=0 if `var'==.
}
egen total_health_exp= rsum( health_exp2301- health_exp2319)
sort hhid
save "${temp}/health_exp19",replace

*4. Data on household level welfare have been sorted for further merger 

*6. Merger of all datasets
*7. Conversion of base year for welfare, education spending at household level using the price index and spatial index
*8. Construct indicators- household spending on health, spending share in welfare etc. 
**************************************************************************
***International poverty measure- Welfare indicator
use "${wbest}/harmonized_HIES", clear
drop hhid
tostring district sector month psu snumber hhno nhh, replace force
replace month="0"+month if strlen(month)==1
replace snumber="0"+snumber if strlen(snumber)==1
gen hhid=district+sector+month+psu+snumber+hhno
destring district sector month , replace force
sum welfare
keep hhid sector district province welfare
sort hhid
save "$temp/welfare19", replace

*5. Data on price index and spatial price index are sorted at district level- Not required
*6. Merger all the aabove datasets- 1,2,3, 4
***************************************************************************
use "${temp}/health_hh19", clear
sort hhid
merge hhid using "${temp}/health_exp19"
drop _m
sort hhid
merge hhid using "${temp}/welfare19"
drop _m
order hhid sector district province hhsize hhweight popweight welfare
sort hhid

*7. Conversion of base year for welfare, education spending at household level using the price index and spatial index- Not needed
*8. Construct indicators- household spending on health, spending share in welfare etc.
********************************************************************************
rename welfare welfare_pc_real_month
gen welfare_hh_real_ann= welfare_pc_real_month*hhsize*12
/*
gen povline= 6996   
gen povline_real= povline //as at 2019 prices
*/
* Share
foreach var of varlist health_exp2301- total_health_exp {
gen `var'_share= 100 *(`var'/welfare_hh_real_ann)
}
*Quintiles
xtile quintile = welfare_pc_real_month[aw=hhweight], nquantiles(5)
label define q 1 "Q1 (poorest)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (richest)", replace
label values quintile q
gen year=2019
order year
sort hhid
save "${output}/health_humancap19_updt1",replace
use "${output}/health_humancap19_updt1",clear

**********************************************************************************************************************************************************************
***Year 2024-25**********************************************************************************************************************************************************************
******************************************************************************************************************************************************************************
* 1) Households and their health status
use "${bright2425}\mod_b0_roster_long.dta", clear
	//use "${data}\Long\mod_b0_roster_long.dta", clear
    isid hhcode pid
	* Merge in B1 roster for language, ethnicity and religion
	merge 1:1 hhcode pid using "${bright2425}\mod_b1_roster_long.dta", keep(match master) nogen
    * Merge in B2 roster for level of education of head
    merge 1:1 hhcode pid using "${bright2425}\mod_b2_roster_long.dta", keep(match master) nogen
	//merge 1:1 hhcode pid using "${data}\Long\mod_b2_roster_long.dta", keep(match master) nogen
ren hhcode hhid
ren b0_04_years age
ren b0_02 sex
ren b0_03 relationship
ren b1_08 ethnicity
ren b1_09 religion
ren b1_10 primary_language
ren b2_08 education
recode ethnicity (999=9)
recode religion ( 6=9) (7=9)

   * Sex and head
gen hh_head_type =1 if sex==1 & relationship==1  // sex 1- female, 0-male
replace hh_head_type=2 if sex==0 & relationship==1
gen head_ethncity= ethnicity if relationship==1
gen head_religion= religion if relationship==1
//gen head_language= primary_language if relationship==1
gen head_edu= education if relationship==1

collapse(max)  pid hh_head_type head_ethncity head_religion head_edu, by(hhid)
ren pid hhsize

gen head_educ_cat = .
	replace head_educ_cat = 1 if inrange(head_edu, 0, 2)              // none/primary // Change codes by Sridhar
    replace head_educ_cat = 2 if inlist(head_edu, 3, 4)              // secondary (O/L–A/L)
    replace head_educ_cat = 3 if inrange(head_edu, 5, 7)             // TVET / diplomas
    replace head_educ_cat = 4 if inrange(head_edu, 8, 10)            // tertiary

label define head_educ_cat 1 "None/Primary" 2 "Secondary (O/L–A/L)" 3 "TVET/Diploma" 4 "Tertiary", replace
    label values head_educ_cat head_educ_cat
drop head_edu
ren head_educ_cat head_edu

lab var hhsize hhsize
sort hhid
save "${temp}/health_hh25",replace   

*2. Annualising the households' non-food expenditure- convering the weekly and monthly expenditure to annual
*3.a. The category of core education and extended education items are identifield from the non-food items and ///
*added up separately to estimate the education expenditure
********************************************************************************
use "${bright2425}\mod_k_nfe_long.dta", clear
ren hhcode hhid
	sort hhid
	format k_item %30.0g
* Annualize each non-food expenditure item
gen double nfe_annual_item = .
replace nfe_annual_item = k_expend * 52 if k_period == 1
replace nfe_annual_item = k_expend * 12 if k_period == 2
replace nfe_annual_item = k_expend      if k_period == 3
replace nfe_annual_item = k_expend *  2 if k_period == 4
replace nfe_annual_item = 0 if missing(nfe_annual_item)
	
********************************************************************************
*3. The health iterms items are identifield from the non-food items ///
*and added up separately to estimate the health expenditure
********************************************************************************
gen health_item=1 if inlist(k_item, 43, 44)
gen double health_exp = nfe_annual_item if health_item==1
replace health_exp = 0 if missing(health_exp)
keep if health_item==1
keep hhid health_exp k_item
reshape wide health_exp, i( hhid) j( k_item)
egen total_health_exp= rsum( health_exp43- health_exp44)
sort hhid
save "${temp}/health_exp25",replace

*4. Data on household level welfare have been sorted for further merger 
**************************************************************************
use "$wbest/Imputed_Bright_match.dta",clear
keep hhid weight popweight month year district province sector welfare
replace popweight =round(popweight)
ren  weight hhweight
replace hhweight=round(hhweight)
lab def sector 1 "Urban" 2 "Rural" 3 "Estate", modify
lab val sector sector
sort hhid
save "$temp/welfare25", replace
use "$temp/welfare25", clear

*5. Data on price index and spatial price index are sorted at district level
*****************************************************************************
use "$wbest/NCPI_series_subgroups.dta",clear
sort year month
save "${temp}/NCPI_series_subgroups",replace

use "$wbest/spatial_priceindex.dta",clear
**Year of spatial price index is not mentioned
sort district 
save "${temp}/spatial_priceindex",replace

*6. Merger all the aabove datasets- 1,2,3, 4, 5
***************************************************************************
use "${temp}/health_hh25", clear
sort hhid
merge hhid using "${temp}/health_exp25"
drop _m
sort hhid
merge hhid using "${temp}/welfare25"
/*
gen welfare_missing=(welfare==.)
tab welfare_missing
welfare_mis |
       sing |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      6,835       99.81       99.81
          1 |         13        0.19      100.00  // Households with missing welfare values, sector, provinces etc. 
------------+-----------------------------------
      Total |      6,848      100.00
*/
drop _m
sort hhid
order hhid sector district province hhsize hhweight popweight welfare
sort hhid
order year month
sort year month
merge m:1 year month using "$temp/NCPI_series_subgroups",nogen
sort district
merge m:1 district using "$temp/spatial_priceindex", keep(match master) nogen // will check from the collegues' do file
sort hhid

drop if sector==.   // welfare value for a few households missing and some missing values for different years

*7. Conversion of base year for welfare, education spending at household level using the price index and spatial index
*****************************************************************
foreach var of varlist health_exp43 health_exp44 total_health_exp{
replace `var'=(`var'*avg2019nonfood)/cpi_base2013
replace `var'=`var'*lpindex1
}

***Base of welfare is not changed as it is already in real terms

ren welfare welfare_pc_real_month
gen welfare_hh_real_ann= welfare_pc_real_month*hhsize*12


* Share
foreach var of varlist health_exp43 health_exp44 total_health_exp {
gen `var'_share= 100 *(`var'/welfare_hh_real_ann)
}

*8. Construct indicators- per child spending on core and its components, spending share in welfare etc. 
********************************************************************************
*Quintiles
xtile quintile = welfare_pc_real_month[aw=hhweight], nquantiles(5)
label define q 1 "Q1 (poorest)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (richest)", replace
label values quintile q
drop year
gen year=2025 //Year 2025 is used for the combined samples collected in the year 2024 and 2025 for BRIGHT, 2024-25
order year
sort hhid
save "${output}/health_humancap25_updt1",replace
use "${output}/health_humancap25_updt1",clear

*****************************************************************************************************************************************************************************
***D. Append all three datasets******************************************************************************************************************************************
*******************************************************************************************************************************************************************************
use "${output}/health_humancap16_updt1",clear
keep year hhid  sector district province hhsize hhweight popweight ///
hh_head_type head_ethncity head_religion hh_head_type head_edu ///
welfare_pc_real_month total_health_exp total_health_exp_share quintile
sort year hhid
save "${temp}/health_16_1", replace

use "${output}/health_humancap19_updt1",clear
keep year hhid sector district province hhsize hhweight popweight ///
hh_head_type head_ethncity head_religion hh_head_type head_edu ///
 welfare_pc_real_month total_health_exp total_health_exp_share quintile
sort year hhid
save "${temp}/health_19_1", replace

use "${output}/health_humancap25_updt1",clear
keep year hhid sector district province hhsize hhweight popweight welfare_pc_real_month ///
hh_head_type head_ethncity head_religion hh_head_type head_edu ///
total_health_exp total_health_exp total_health_exp_share quintile
sort year hhid
append using "${temp}/health_16_1"
append using "${temp}/health_19_1"
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province
lab def hh_head_type 1 "Female headed" 2 "Male headed"
lab val hh_head_type hh_head_type
lab def head_ethncity 1"Sinhala" 2 "Sri Lankan Tamil" 3 "Indian Tamil" 4 "Sri Lankan Muslims" ///
5 "Burgher" 6 "Malay" 9 "Others"
lab val head_ethncity head_ethncity
lab def head_religion 1"Buddhist" 2 "Hindu" 3 "Islam" 4 "Roman catholic" ///
5 "Other christian" 9 "Others"
lab val head_religion head_religion
order year
sort year hhid
save "${output}/health_humancap16_19_25_1",replace
use "${output}/health_humancap16_19_25_1",clear
*********************************************************************************************************************************************************************************************
***E. Graphs********************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************
*E1- National and Provincial
use "${output}/health_humancap16_19_25_1",clear
graph bar total_health_exp_share[fw= hhweight], over(year) blab(bar, format(%2.1f))
 
*Graph1	
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(sector) legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(2) ring(0)) ///
blab(bar, format(%2.1f)) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By sector") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is households' monthly consumption expenditure, estimated by the World Bank", size(3))
graph export "${graph}/Health/graph1.png", replace
*Graph2
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(quintile) legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(11) ring(0)) ///
blab(bar, format(%2.1f)) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By Quintiles") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is household monthly consumption expenditure, estimated by the World Bank," ///
	" Houeholds' annual welfare percapita is used for Quantiles estimates", size(3))
graph export "${graph}/Health/graph2.png", replace

*Graph3
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(province) legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(11) ring(0)) ///
blab(bar, format(%2.1f)) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By provinces") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is household monthly consumption expenditure, estimated by the World Bank", size(3))
graph export "${graph}/Health/graph3.png", replace

*Graph4
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(hh_head_type) legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(11) ring(1)) ///
blab(bar, format(%2.1f) size(2) ) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By type of household head") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is household monthly consumption expenditure, estimated by the World Bank", size(3))
graph export "${graph}/Health/graph4.png", replace

*Graph5
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(head_ethncity, lab(labsize(3) angle(45))) ///
legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(11) ring(0)) ///
blab(bar, format(%2.1f) size(2) ) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By type of household ethnicity") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is household monthly consumption expenditure, estimated by the World Bank", size(3))
graph export "${graph}/Health/graph5.png", replace

*Graph6
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(head_religion,lab(labsize(3) angle(45))) legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(11) ring(1)) ///
blab(bar, format(%2.1f) size(2) ) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By type of household religion") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is household monthly consumption expenditure, estimated by the World Bank", size(3))
graph export "${graph}/Health/graph6.png", replace

*Graph7
graph bar total_health_exp_share[fw= hhweight], over(year, lab(nolab) gap(0)) asyvars ///
over(head_edu,lab(labsize(3) angle(45))) legend(order(1 "2016" 2 "2019" 3 "2024-25")region(lstyle(none)) size(2) bfcolor(none) pos(11) ring(1)) ///
blab(bar, format(%2.1f) size(2) ) bar(1, color(red) lcolor(none)) ///
    bar(2, color(blue) lcolor(none)) ytitle("Share(%)", size(3)) ///
    title("Households' out of pocket expenditure on healthcare" "(as a share of welfare,in %)", size(5)) ///
	subtitle("By type of household head education") ///
    note("Source-HIES,2016 and 2019, BRIGHT,2024-25" "Note-Spending in LKR at 2019 prices" ///
	"Note-Welfare is household monthly consumption expenditure, estimated by the World Bank", size(3))
graph export "${graph}/Health/graph6.png", replace


*******************************************************************************************************************

 





















































