# uber_rides_R_dashboard
Uber Rides Dashboard in Shiny R
# DSCI-532_2026_32: Uber Dashboard Project
This project develops an interactive dashboard analyzing Uber’s 2024 ride data to evaluate operational performance, revenue trends, and customer satisfaction. The dashboard provides key business insights through visual analytics, helping stakeholders understand ride volume patterns, vehicle type performance, geographic demand distribution, trip duration trends, and customer ratings.

Built with Shiny R.

## Installations

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

## Demo
![App Demo](img/demo.gif)
