# Explaining Czech Inflation with a Bernanke-Blanchard Framework: An Exploratory Price-Level Extension

This repository contains the source code, data, and text for the master's thesis defended at the Institute of Economic Studies, Faculty of Social Sciences, Charles University.

## About the Project
This project evaluates the determinants and drivers of post-pandemic inflation in the Czech Republic using the semi-structural model proposed by Bernanke and Blanchard. We apply this framework to Czech macroeconomic data to enable international comparison.

As an exploratory extension, we incorporate a domestic price-level gap variable into the price equation. This modification tests the hypothesis that a structurally lower domestic price level amplifies the transmission of external price shocks.

## Original Study (Bernanke & Blanchard)
The methodology builds directly on the theoretical and empirical inflation framework developed by Olivier Blanchard and Ben Bernanke:
* **Original paper:** Blanchard, O. J., & Bernanke, B. S. (2024). *An Analysis of Pandemic-Era Inflation in 11 Economies*.
* **Link:** [https://www.piie.com/publications/working-papers/2024/analysis-pandemic-era-inflation-11-economies](https://www.piie.com/publications/working-papers/2024/analysis-pandemic-era-inflation-11-economies)

---

## Repository Structure

The repository is organized into four main directories corresponding to the stages of data processing and econometric modeling:

* `data_processing/`
  * Python scripts for downloading, cleaning, and preparing macroeconomic data.
  * Includes time-series transformations from CZSO, CNB, ECB, and Eurostat databases, alongside the integration of the Global Supply Chain Pressure Index (GSCPI).

* `lockdown_per_employee - Main model/`
  * The core semi-structural Bernanke-Blanchard (BB) model applied to Czech data.
  * Contains estimations for the wage equation, price equation, and short- and long-term inflation expectations, as well as impulse response functions (IRFs) and historical decompositions of inflation.
  * Implements the baseline framework and the exploratory extension incorporating the price-level gap.

* `lockdown_per_hour/`
  * First set of robustness checks and sensitivity analyses.
  * Evaluates alternative wage equation specifications (using compensation per hour instead of compensation per employee) and alternative labor market tightness measures (using the unemployment gap instead of the $V/U$ ratio).

* `other_models - alternative data/`
  * Second set of robustness checks testing system stability and lag dynamics.
  * Includes estimations and historical decompositions using the Harmonised Index of Consumer Prices (HICP) instead of the national CPI, as well as tests across different lag structures.

---

## Thesis Details

* The full text of the thesis is available  in **`[thesis.pdf]`**.
* **Author:** Václav Šmíro
* **Supervisor:** PhDr. Jiří Schwarz, Ph.D.
* **Institution:** Charles University, Faculty of Social Sciences, Institute of Economic Studies (IES FSV UK)
* **Year of Defense:** 2026

---

## Main Findings
* **Sources of inflation:** The post-pandemic inflation surge in the Czech Republic was driven primarily by external cost shocks, specifically energy and food prices, which exhibited relatively strong transmission into domestic inflation.
* **Wage dynamics:** Labor market tightness contributed to wage growth, but the estimated catch-up effect is negative. Unexpected inflation did not translate into higher nominal wage growth, indicating the absence of a wage-price spiral.
* **Price-level impact:** Specifications incorporating the price-level gap yielded no statistically significant evidence of a state-dependent multiplier effect in the transmission of external shocks across the tested specifications.

