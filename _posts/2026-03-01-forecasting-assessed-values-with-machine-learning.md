---
layout: post
title: "Forecasting Assessed Values with Machine Learning"
date: 2026-03-01
description: "How the City of Seattle uses parcel-level ML models to forecast property assessed values for budget planning."
tags: [machine learning, property tax, forecasting, Seattle]
---

Property tax is one of the most important and predictable revenue streams for local governments — but "predictable" doesn't mean easy to forecast. Assessed values (AV) are set annually by the King County Assessor, and even modest surprises in that number can ripple through a city's budget. The goal of this project is to get ahead of those surprises using machine learning.

## Why Forecast Assessed Values?

The City of Seattle receives a share of property tax revenue based on total assessed values within city limits. Budget and revenue planning teams need forward-looking estimates of AV well before the Assessor publishes official numbers — sometimes a year or more in advance. That gap is where forecasting earns its keep.

The challenge is that assessed value is determined parcel by parcel, aggregated across hundreds of thousands of properties spanning single-family homes, commercial towers, and everything in between. A single macro-level forecast isn't granular enough to capture how different property types behave differently across market cycles.

## The Data

The model works at the **parcel level**, using historical assessed value records from the King County Assessor combined with Seattle housing market data from the NWMLS. Features include:

- Prior-year assessed values and year-over-year change rates
- Building type classifications (mapped from King County Assessor area codes), distinguishing residential, commercial, industrial, and mixed-use parcels
- Market-level signals such as median sale prices and inventory trends
- Temporal features capturing seasonality and cyclical patterns in the housing market

The parcel-level granularity matters. Commercial office properties, for instance, have behaved very differently from residential parcels in the post-COVID period — a distinction that a single aggregate model would smooth over.

## The Modeling Approach

Rather than forecasting the level of assessed value directly, the model forecasts the **year-over-year change** — or delta — in AV for each parcel. This delta-only approach has a few practical advantages:

- It's more stable across property types with very different absolute value scales
- It's easier to validate: you're checking whether direction and magnitude of change are reasonable, not whether a raw dollar figure lands correctly
- It plays well with how budget teams actually use forecasts — they care about growth rates, not absolute levels

Under the hood, the approach uses **gradient boosted trees**, trained separately for distinct building type strata. Stratifying by property type allows each sub-model to learn patterns relevant to that segment rather than averaging across very different market dynamics.

The pipeline is built in R, with model objects cached and loaded across scripts to keep the workflow modular. Each stratum produces a distribution of predicted deltas, which are then aggregated up to city-wide AV forecasts for planning use.

## How the Forecasts Are Used

The outputs feed directly into the City's internal revenue planning process. They are intentionally positioned as **planning estimates** rather than official projections — a distinction that matters when forecasts are presented alongside the Assessor's own numbers. The goal isn't to replace the Assessor's valuation process; it's to give budget staff a reasonable, defensible early signal.

Validation focuses on whether the model's gap distribution — the difference between forecast and actual AV — is well-centered and free of systematic drift across property types. Recursive forecasting checks help flag whether the model's accuracy degrades as the forecast horizon extends.

This is a living project. As Seattle's property landscape continues to evolve — particularly in the commercial sector — the model will evolve with it.
