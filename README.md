# covid-19
Repository for placing code related to COVID-19 projects.

## Prerequesists

You require Python 3.

MacOS
```
brew install python3
pip3 install virtualenv
cd <project-path>
virtualenv -p python3 <project-path>
source <project-path>/bin/activate
```

Python required packages are detailed in the "requirements.txt" file. These
dependencies can be installed by executing:
```
cd <project-path>
pip install -r requirements.txt
```

## Results Format

date: Actual date for which true observations are recorded and predictions assesed.
ev: Expected value of the predicted number of deaths
lb: Lower bound of the prediction
ub: Upper bound of the prediction
gt: Ground Truth (Actual number of deaths)
error: Actual (gt) minus Predictions (ev) $gt-ev$
PE: Percentage Error $(gt-ev)/gt$
Adj PE: Adjusted Percentage Error $(gt-ev)/(gt+ev)$
APE: Absolute PE $abs(PE)$
Adj APE: Adjusted Absolute PE
LAPE: Logistic Absolute PE
LAdj APE: Logisticd Adjusted Absolute Percentage Error
last_obs_date: Each model generated predictions with observations until this date.
within_PI: {inside, above, below} Depending on the ev and if it is inside the ub,lb and ub.
outside_by: If prediction is inside PI, then outside_by is 0, otherwise is the amount by which the prediction is above or below the bounds.
model_name: Identifier of model used for predictions
state_long: Long name of the state for prediction
state_short: Two character summarised state code
lookahead: the number of days for future predictions.
