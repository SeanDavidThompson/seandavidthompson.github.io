---
title: "Forecasting Seattle's Housing Market: An Econometric Approach Using NWMLS Data"
date: 2026-03-03
layout: post
tags: [econometrics, housing, forecasting, Seattle, ARDL, VECM]
---

How do you build a credible multi-year forecast for a metropolitan housing market that went through a once-in-a-generation structural shock? That's the question I set out to answer using monthly data from the Northwest Multiple Listing Service (NWMLS), paired with macroeconomic fundamentals. This post walks through the modeling framework, the key decisions behind it, and the technical details that make it work.

## The Forecasting Problem

The City of Seattle needs forward-looking estimates of housing market conditions for internal planning and policy discussion. Three indicators anchor the work:

- **Active listings** (inventory on the market)
- **Closed listings** (completed transactions)
- **Median sale price**

Each of these behaves differently at different frequencies and responds to different macro drivers, so a single model can't do the job. The approach I developed uses two complementary frameworks: ARDL models for listings dynamics and a VECM for prices. The monthly sample begins around 2005, giving roughly 240 observations to work with — enough to identify meaningful dynamics, but not so much that you can throw parameters at the wall.

## Macro Drivers

Four macroeconomic series drive the system:

| Variable | Description |
|---|---|
| KS_N | King County nonfarm employment (log) |
| KS_PIPC | King County personal income per capita (log) |
| KSP_PHCL | S&P/Case-Shiller Seattle home price index (log) |
| Mortgage spread | 30-year mortgage rate minus 10-year Treasury yield |

The mortgage spread deserves a note. Rather than using the mortgage rate alone, the spread isolates the housing-specific financing wedge — the risk premium lenders charge over the benchmark long rate. When macro rates are already in the system via income and employment channels, the spread captures credit conditions more cleanly than the level of the mortgage rate itself.

## Integration Properties and Model Selection

The choice between ARDL and VECM isn't arbitrary; it follows from the data's integration properties.

Standard ADF testing reveals the expected pattern: median price, income, employment, and the Case-Shiller index are all I(1) in levels and stationary in first differences. The mortgage spread is I(0) or near-stationary. Listings variables are borderline — often failing to reject the unit root null at conventional levels, but not behaving like textbook I(1) processes either.

This mixed integration structure motivates the modeling split:

- **Listings → ARDL**: The Pesaran bounds-testing logic applies. ARDL is valid regardless of whether regressors are I(0), I(1), or a mix, making it the natural choice when integration orders are ambiguous.
- **Median price → VECM**: The four I(1) variables in the price system show evidence of cointegration — they share a common stochastic trend. Ignoring this long-run relationship and estimating in differences alone would throw away information.

## Active Listings: ARDL Specification

The active listings model takes the form:

$$
\Delta \ln(\text{ALES}_t) = \alpha + \sum_{i=1}^{p} \phi_i \, \Delta \ln(\text{ALES}_{t-i}) + \sum_{j=0}^{q_1} \beta_j \, \Delta \ln(\text{PHCL}_{t-j}) + \sum_{k=0}^{q_2} \gamma_k \, \Delta \ln(\text{N}_{t-k}) + \sum_{m=0}^{q_3} \delta_m \, \text{Spread}_{t-m} + \text{Seasonals} + \varepsilon_t
$$

Lag orders are selected via AIC, with dependent variable lags typically running up to 6 months. Distributed lags on the regressors capture the delayed response of inventory to price momentum, labor market shifts, and financing conditions.

One key design choice: **seasonal dummies replace a 12-month lag structure**. With three or four regressors and monthly data, a full seasonal lag specification on each variable quickly becomes unwieldy. A 12-lag ARDL on three regressors already implies 36+ distributed lag parameters before you count the dependent variable's own lags. Seasonal dummies accomplish the same goal — controlling for calendar effects — at a fraction of the parameter cost.

Diagnostically, I check residual autocorrelation, parameter significance, and stability across rolling windows. The model captures the intuition that active listings respond to mortgage financing conditions (via the spread), labor market health (via employment growth), and price momentum (via Case-Shiller growth).

## Closed Listings: ARDL Variant

The closed listings model follows a similar ARDL structure — a representative specification is ARDL(4,4,4,0) — but with some behavioral differences. Closed sales are more directly a measure of transaction flow and tend to respond more sharply to mortgage spread shocks. When financing conditions tighten, the volume of completed transactions drops faster than inventory adjusts.

## Median Price: VECM

The price model is where things get more interesting. The endogenous system is:

$$
Y_t = \begin{bmatrix} \ln(\text{SEA\_PMEDESFH}_t) \\ \ln(\text{KSP\_PHCL}_t) \\ \ln(\text{KS\_PIPC}_t) \\ \ln(\text{KS\_N}_t) \end{bmatrix}
$$

with the error correction representation:

$$
\Delta Y_t = \alpha \left( \beta' Y_{t-1} + c \right) + \sum_{i=1}^{k-1} \Gamma_i \, \Delta Y_{t-i} + \text{Seasonals} + u_t
$$

The cointegrating rank is set to 1, reflecting a single long-run equilibrium relationship tying Seattle's median price to regional employment, income, and the broader housing price index. The deterministic specification uses a restricted constant in the cointegrating vector (Johansen's Case 2) — allowing for a nonzero mean in the equilibrium relationship without introducing a linear trend in the levels of the system.

The $\alpha$ vector governs the speed at which each variable adjusts back to equilibrium after a shock. This is where the post-2020 story gets complicated.

### The Post-COVID Structural Break

The pandemic introduced at least two structural forces into Seattle's housing market:

1. **Rate lock-in**: Homeowners who refinanced at historically low rates face a large implicit cost of selling, suppressing turnover and slowing the speed at which the market corrects disequilibria.
2. **Remote work and spatial resorting**: Geographic demand patterns shifted as remote-capable workers re-optimized their location choices, altering the relationship between local employment and local housing demand.

In the VECM, this shows up as a reduction in the magnitude of the $\alpha$ parameters — the error correction mechanism weakens. Prices that are above (or below) their long-run equilibrium relative to fundamentals correct more slowly than the pre-2020 data would predict.

My current approach handles this with **rolling 15-year estimation windows**, selecting the window where $\alpha$ and $\beta$ estimates stabilize. This is pragmatic but admittedly ad hoc. More principled alternatives I've considered include:

- A post-2020 dummy in the $\Delta$ equations
- An interaction term: $\text{ECT} \times \mathbb{1}(\text{post-2020})$, allowing the speed of adjustment itself to shift
- Formal break tests (Chow, sup-Wald)
- A threshold or regime-switching ECM

Each of these trades off complexity against the limited post-break sample size. With roughly five years of post-2020 data, there's a real tension between wanting to model the structural shift formally and having enough observations to estimate the shift reliably.

## Forecast Generation

Forecasts are generated recursively: macro inputs (employment, income, interest rate paths) are projected externally under scenario assumptions, then fed into the ARDL and VECM systems month by month. This is the standard approach for conditional forecasting with time series models, but it comes with well-known risks:

- **Error accumulation**: Each step's forecast error feeds into the next period's inputs. Over a multi-year horizon, small biases can compound.
- **Sensitivity to the mortgage spread path**: The spread is the most volatile input and has the largest short-run impact on listings dynamics. Different rate scenarios can produce meaningfully different inventory and transaction forecasts.
- **Structural stability assumption**: The recursive approach assumes that the estimated parameters remain valid out of sample — exactly the assumption that the post-COVID break calls into question.

For these reasons, I treat the forecasts as planning estimates rather than point predictions. The value is in the conditional logic: *if* rates follow path X and employment follows path Y, *then* the models imply Z for prices and listings. Scenario comparison is more informative than any single baseline.

## Diagnostics for Review

For anyone evaluating this kind of framework — whether for organizational review or replication — the key diagnostics I'd highlight are:

- **Out-of-sample RMSE** on rolling-origin evaluation, which gives a more honest picture of forecast accuracy than in-sample fit
- **Stability of the cointegrating vector** across estimation windows
- **Forecast bias by horizon**, to check whether the models systematically over- or under-predict at longer leads
- **Impulse response functions** for rate shocks, to verify that the dynamic responses are economically plausible
- **Scenario stress tests**, comparing forecasts under contractionary vs. expansionary macro paths

## What's Next

Several extensions are on the roadmap:

- **Direct multi-horizon forecasting** to sidestep recursive error accumulation
- **Bayesian VECM shrinkage** to regularize the parameter space, especially useful given the structural instability
- **An expanded financial conditions index** to replace the single mortgage spread with a richer measure of credit availability
- **Regime-switching ECM** to formally allow the error correction dynamics to differ across market states
- **Explicit structural break estimation** using the full toolkit of sequential and simultaneous break tests

The broader goal is a forecasting system that's transparent enough to defend in front of stakeholders, flexible enough to incorporate new macro scenarios quickly, and rigorous enough that the conditional forecasts are actually informative for planning. It's an ongoing project, and I'll write more as the extensions come together.

---

*The code and data pipeline for this project are maintained in R. The ARDL models use AIC-based lag selection, and the VECM is estimated via the Johansen procedure with seasonal controls. If you have questions or want to discuss the methodology, feel free to reach out.*
