---
layout: post
title: "Forecasting Seattle Property Assessed Values with LightGBM"
author:
  name: "Sean Thompson"
  url: "/about/"
date: 2026-03-01
tags: [machine learning, LightGBM, R, forecasting, property tax, panel data]
---

Property tax revenue is one of the most stable and significant funding streams for municipal governments — but "stable" doesn't mean easy to predict. Assessed values fluctuate with the housing market, shift dramatically after reappraisal cycles, and interact in complex ways with macroeconomic conditions. At the City of Seattle, I built a parcel-level machine learning pipeline to forecast residential assessed values (AV) through 2031, replacing a simpler extrapolation approach with a system that learns from the full cross-sectional and temporal structure of the tax roll.

This post covers the modeling choices, the data architecture, and the practical compromises that come with deploying ML in a government planning context.

## The Problem

Seattle's Office of City Budget and Management needs multi-year AV forecasts to build revenue projections. The prior approach used aggregate trend extrapolation from the assessor's own projections — defensible but coarse, and unable to reflect heterogeneity across the city's parcel stock.

The challenge with going parcel-level is scale and structure. King County's residential roll contains roughly 300,000+ parcels, each observed annually, creating a panel dataset where you care about both cross-sectional variation (what makes one parcel more valuable than another) and temporal dynamics (how values change year over year). You also have to forecast at the individual parcel level and then aggregate up — meaning errors compound unless your model captures genuine signal rather than noise.

## Data Architecture

The modeling dataset is built from three sources joined into a panel:

**King County Assessor parcel data** provides the outcome variables — appraised land value (`appr_land_val`) and improvement value (`appr_imps_val`) — plus parcel-level features: building type, square footage, lot size, age, KCA area codes, and structural characteristics. These are treated as fixed parcel attributes (they don't change in the forecast horizon absent major renovation or demolition).

**NWMLS housing market data** provides time-varying economic context: median sale prices of single-family homes, active listing counts, and closed transaction counts at a sub-market level. These are forecasted separately using ARIMA/VECM models and fed into the ML pipeline as features during the forward simulation.

**Macroeconomic indicators** — mortgage rates, CPI, and unemployment — provide broader context for the market-level forecasts.

The full panel runs from 2006 through the most recent assessor vintage (2025), with the forecast horizon extending to 2031. Pre-joining, the pipeline handles type alignment carefully since the assessor data uses a mix of factor, numeric, and logical columns that require consistent treatment across training and prediction time.

## Model Design

I train two separate LightGBM models: one for **log land value** and one for **log improvement value**. The log transformation stabilizes variance across the wide AV distribution (Seattle parcels range from low six figures to eight figures) and allows the aggregated forecast to be back-transformed without the multiplicative bias that comes from Jensen's inequality.

Both models are gradient-boosted trees via `lightgbm` in R, with hyperparameters tuned via cross-validation on held-out years. A key design choice: training uses all years with observed values, but the feature matrix is constructed via `caret::dummyVars` to ensure consistent one-hot encoding between training time and forecast time. A helper function pads missing dummy columns with zeros when a category present in training isn't observed in the prediction frame — this matters for rare KCA area codes that may only appear in a subset of years.

Prediction is chunked (50,000 rows at a time) to manage memory on the full panel, with `gc()` calls between chunks. This is unglamorous but necessary when running the pipeline on a standard workstation.

## Forecasting Strategy: Sequential Simulation

The forecast isn't a one-shot prediction to 2031. It's a sequential simulation where each year's predictions become features for the next year.

For each year from 2026 to 2031:
1. Attach that year's market indicator forecasts (median price, active listings, closed listings) to the parcel panel.
2. Predict log land value and log improvement value using the trained models.
3. Compute total AV as the sum of back-transformed predictions.
4. Carry those predictions forward as lagged features for the subsequent year.

This structure lets the model capture mean-reversion and momentum dynamics — parcels with large predicted jumps in one year partially revert the next, consistent with how the assessor's own smoothing works. It also naturally propagates uncertainty, since errors in year *t* predictions feed into year *t+1* features.

For parcels that are new (annexed, subdivided, or rebuilt) or missing key attributes, a fallback level model predicts directly from parcel characteristics without relying on lagged values.

## Validation

Validation runs in two modes. First, in-sample hold-out: I train on 2006–2021 and predict 2022–2025, comparing predicted aggregate AV against the assessor's actual certified roll for those years. This gives a clean apples-to-apples comparison since the actual roll is the ground truth.

Second, I compare the ML forecast against the old extrapolation method on the same years. The ML models outperform on aggregate accuracy and, more importantly, on distributional accuracy — the old method tended to over-predict high-growth areas and under-predict stable ones, while the LightGBM models track the cross-sectional distribution more faithfully.

Diagnostic plots include residual distributions by building type and sub-market, prediction error over time (the percent difference between ML-predicted aggregate AV and actual AV for 2023–2025), and recursion drift — how much the sequential forecast drifts from a non-recursive baseline over the six-year horizon.

## Organizational Context

The ML forecasts are positioned internally as **planning estimates**, not official assessments. The distinction matters. King County's assessor is the legal authority on assessed values; our forecasts inform budget scenario modeling and revenue sensitivity analysis. This framing keeps the work defensible when presented to budget staff and elected officials who may be skeptical of black-box models.

It also shaped the design: interpretability is valued alongside accuracy. LightGBM's feature importance outputs and SHAP values (computed for a sample of parcels) are part of the standard diagnostic output, making it possible to explain why specific sub-markets are forecast to grow faster than others.

## What's Next

The current pipeline handles residential parcels. Commercial property — which has a fundamentally different valuation logic, driven by income approaches rather than comparable sales — is the logical next extension. The data architecture is designed to accommodate it with additional training data and a separate model family.

The sequential simulation also opens up scenario analysis: baseline, optimistic, and pessimistic market trajectories based on different NWMLS forecast paths. That's the near-term roadmap for the revenue planning team.

---

*The code for this pipeline is being prepared for public release. If you're working on similar problems in municipal finance or property tax forecasting, feel free to reach out.*
