# Uber Rides Dashboard in Shiny R
This project models after the [DSCI-532_2026_32: Uber Dashboard Project](https://github.com/UBC-MDS/DSCI-532_2026_32_Uber_dashboard), but with R.

Built with Shiny R.

## Steps to Run the Dashboard:

1.  Clone the fork locally using:

``` bash
git clone git@github.com:alancmliu/uber_rides_R_dashboard.git
```
Then please cd into the root of the repo by:
```bash
cd uber_rides_R_dashboard
```

3.  Restore the `renv` environment with:

``` bash
Rscript -e "renv::restore()"
```

4.  Run the app locally with:

``` bash
Rscript -e "shiny::runApp('src/app.R')"
```
This will start the Shiny app on a local server, and please see the URL like this http://127.0.0.1:xxxx and paste into your browser.
The dashboard will allow you to explore Uber's 2024 ride data through interactive visualizations.

## Deployment
The dashboard is deployed on posit cloud.
