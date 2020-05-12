# Covid-19 Model Evaluations
Repository for placing code related to COVID-19 model evaluations. The purpose is to evaluate the predictive capability
of the models currently being used to predict deaths and medical resources needed.

- [Paper Evaluation IHME – arXiv](https://arxiv.org/abs/2004.04734)
- [Online Visualisations](http://covid-paper-front.s3-website-ap-southeast-2.amazonaws.com)


## Installation

### Pre-requisits

1) You require Python 3 to run the backend analytics and Postgresql to handle the database.
    
    Ubuntu
    ```
    sudo apt-get install python3
    sudo apt-get install python3-pip
    sudo apt-get install postgresql-server-dev-all
    ```
    
    MacOS
    ```
    brew install python3
    brew install postgresql
    ```
   
2) Best practice is to use a virtual environment to ensure all packages are compatible with the specific version of the code:

    ```
    pip3 install virtualenv
    cd <project-path>
    virtualenv -p python3 <project-path>
    source <project-path>/bin/activate
    ```

3) Download Python package requirements, which are detailed in the "requirements.txt" file. These
dependencies can be installed by executing:

```
cd <project-path>
pip install -r requirements.txt
```

## Excecution

## Data Format

| Column Name      |  Units | Description           |
| ----------------:|-----------------------| ----- |
| target_date      | date | Actual date for which true observations are recorded and predictions evaluated |
| forecast_date    | date | Date for when the forecast was generated |
| lookahead        | days | target_date - forecast_date |
| model_name       | string | Name of model or institution producing the estimates | 
| location_long    | string | Actual name of state, country or other location |
| location_short   | string | Abbreviation of long name of state, country or other location |
| prediction_type  | string | Type of prediction (point_estimate, 95_PI or full_perc) | 
| expected_value   | double | Value of the expected number of daily deaths | 
| perc_0.010       | double | Percentile of posterior estimate of daily deaths | 
| perc_0.025       | double | Percentile of posterior estimate of daily deaths |
| perc_0.050       | double | Percentile of posterior estimate of daily deaths | 
| perc_0.100       | double | Percentile of posterior estimate of daily deaths | 
| . . .            | double | All other percentiles with 0.05 step | 
| perc_0.900       | double | Percentile of posterior estimate of daily deaths | 
| perc_0.950       | double | Percentile of posterior estimate of daily deaths | 
| perc_0.975       | double | Percentile of posterior estimate of daily deaths | 
| perc_0.990       | double | Percentile of posterior estimate of daily deaths | 
| gt_source        | string | Source of data used to evaluate the errors (depends on the data that each model uses to train their models.
| gt_jhu           | integer | Observed daily deaths according to JHU |
| gt_nyt           | integer | Observed daily deaths according to NYT | 
| error            | double | Error in prediction (gt - expected_value) |
| pe               | double | Percentage Error |
| adj_pe           | double | Adjusted Percentage Error |
| ape              | double | Absolute Percentage Error |
| adj_ape          | double | Adjusted Absolute Percentage Error |
| logistic_ape     | double | Logistic Absolute Percentage Error |
| logistic_adj_ape | double | Logistic Adjusted Absolute Percentage Error |
| within_95_pi     | string | inside, above or below of the 95% prediction intervals |
| outside_95p_by   | double | if inside 0, if outside is the amount by which it is outside of the 95% prediction interval |

## Data Models
- [x ] CU models [Columbia University](https://github.com/shaman-lab/COVID-19Projection)
- [x ] [IHME](https://covid19.healthdata.org/united-states-of-america)
- [x ]  [Imperial](https://github.com/sangeetabhatia03/covid19-short-term-forecasts)
- 
## Useful Links

- CDC Forecasting COVID Comparisons [https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html](https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html)
- Covid-19 Projections [https://covid19-projections.com/](https://covid19-projections.com/) – [Github](https://github.com/youyanggu/covid19_projections)
- China Coronavirus Map [https://www.mapbox.cn/coronavirusmap](https://www.mapbox.cn/coronavirusmap/?/=blog&utm_source=mapbox-blog&utm_campaign=blog%7Cmapbox-blog%7Ccoronavirus-map%7Cvisualizing-the-progression-of-the-2019-ncov-outbreak-66763eb59e79-20-02&utm_term=coronavirus-map&utm_content=visualizing-the-progression-of-the-2019-ncov-outbreak-66763eb59e79#3.35/28.47/109.74)
- Five Thirty Eight Covid Forecasts [https://projects.fivethirtyeight.com/covid-forecasts/](https://projects.fivethirtyeight.com/covid-forecasts/)
- Reich Lab Forecast Hub 
    - [Github](https://github.com/reichlab/covid19-forecast-hub)
    - [Javascript Visualisation](http://reichlab.io/d3-foresight/)
- Shaman Lab
    - [Github](https://github.com/shaman-lab/COVID-19Projection)
    - [Paper](https://www.medrxiv.org/content/10.1101/2020.03.21.20040303v2.full.pdf)
- USA Facts [https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/](https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/)
- IHME
    - [Historical Data](http://www.healthdata.org/covid/data-downloads)
    - [Projections Visuals](https://covid19.healthdata.org/united-states-of-america)
    - [Paper 26 April](https://www.medrxiv.org/content/10.1101/2020.04.21.20074732v1.full.pdf)
        - [Appendix Curve Fit Tool](https://www.medrxiv.org/content/medrxiv/suppl/2020/04/25/2020.04.21.20074732.DC1/2020.04.21.20074732-2.pdf)
        - [Hospital Resource Utilization](https://www.medrxiv.org/content/medrxiv/suppl/2020/04/25/2020.04.21.20074732.DC1/2020.04.21.20074732-1.pdf)
