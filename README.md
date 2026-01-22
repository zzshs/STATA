# STATA

Working Hours and Unmet Medical Care (KNHANES)

This repository contains Stata code for an applied empirical analysis using the Korea National Health and Nutrition Examination Survey (KNHANES). The project examines how weekly working hours are associated with unmet medical care among employed adults in South Korea.

The analysis pools repeated cross-sectional survey data across multiple KNHANES waves. Raw data were originally provided in SPSS format and converted to Stata prior to analysis. Due to data access restrictions, the microdata are not included in this repository.

Weekly working hours are discretized into detailed categories to allow for nonlinear effects. Unmet medical care is defined based on self-reported survey responses, with additional specifications distinguishing unmet care by reported reasons. The empirical models control for demographic characteristics, socioeconomic status, employment conditions, health status, and regional factors. All estimates account for the complex survey design of KNHANES using sampling weights, strata, and primary sampling units.

The main specifications rely on survey-weighted logistic regression. To evaluate policy-related changes, the analysis adopts a difference-in-differences framework around the 2018 labor policy reform, with treatment and comparison groups defined by employment status. Heterogeneity is explored through interaction models, and pre-trend regressions are used to assess identifying assumptions.

This repository is intended as a methodological portfolio demonstrating survey data construction and policy evaluation in Stata,
