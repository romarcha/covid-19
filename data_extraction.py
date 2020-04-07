#!/usr/bin/env python

# Data extraction about covid 19 and predictions
__author__ = "Roman Marchant"
__copyright__ = "Copyright (C) 2020, Data Analytics for Resources and Environment DARE, The University of Sydney"
__license__ = "BSD"
__version__ = "0.0.1"
__maintainer__ = "Roman Marchant"
__email__ = "roman.marchant@sydney.edu.au"

import requests
import zipfile
import os
import datetime
import time
import pandas as pd
import numpy as np
from io import StringIO


class DataExtractor:
    def __init__(self, predictions_url, ground_truth_url, target_directory = 'data/'):
        self.predictions_url = predictions_url
        self.ground_truth_url = ground_truth_url
        self.target_directory = target_directory
        if not os.path.exists(self.target_directory):
            os.makedirs(self.target_directory)
        if not os.path.exists(self.target_directory+'raw_data/'):
            os.makedirs(self.target_directory+'raw_data/')
        self.chunk_size = 128
        self.data_extraction_period = 60*10 # every 10 minutes
        self.usa_states = [('AK', 'Alaska'),
                           ('AL', 'Alabama'),
                           ('AR', 'Arkansas'),
                           ('AZ', 'Arizona'),
                           ('CA', 'California'),
                           ('CO', 'Colorado'),
                           ('CT', 'Connecticut'),
                           ('DC', 'District of Columbia'),
                           ('DE', 'Delaware'),
                           ('FL', 'Florida'),
                           ('GA', 'Georgia'),
                           ('HI', 'Hawaii'),
                           ('IA', 'Iowa'),
                           ('ID', 'Idaho'),
                           ('IL', 'Illinois'),
                           ('IN', 'Indiana'),
                           ('KS', 'Kansas'),
                           ('KY', 'Kentucky'),
                           ('LA', 'Louisiana'),
                           ('MA', 'Massachusetts'),
                           ('MD', 'Maryland'),
                           ('ME', 'Maine'),
                           ('MI', 'Michigan'),
                           ('MN', 'Minnesota'),
                           ('MO', 'Missouri'),
                           ('MS', 'Mississippi'),
                           ('MT', 'Montana'),
                           ('NC', 'North Carolina'),
                           ('ND', 'North Dakota'),
                           ('NE', 'Nebraska'),
                           ('NH', 'New Hampshire'),
                           ('NJ', 'New Jersey'),
                           ('NM', 'New Mexico'),
                           ('NV', 'Nevada'),
                           ('NY', 'New York'),
                           ('OH', 'Ohio'),
                           ('OK', 'Oklahoma'),
                           ('OR', 'Oregon'),
                           ('PA', 'Pennsylvania'),
                           ('RI', 'Rhode Island'),
                           ('SC', 'South Carolina'),
                           ('SD', 'South Dakota'),
                           ('TN', 'Tennessee'),
                           ('TX', 'Texas'),
                           ('UT', 'Utah'),
                           ('VA', 'Virginia'),
                           ('VT', 'Vermont'),
                           ('WA', 'Washington'),
                           ('WI', 'Wisconsin'),
                           ('WV', 'West Virginia'),
                           ('WY', 'Wyoming')]
        self.data = pd.DataFrame()
        self.n_lookahead_evaluations = 7

    def download_predictions(self):
        # Checks the current date time, and adds that current date time to the downloaded zip file
        datetime_str = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        r = requests.get(self.predictions_url, stream=True)
        output_filename = self.target_directory + "raw_data/predictions_" + datetime_str + ".zip"
        with open(output_filename, 'wb') as fd:
            for chunk in r.iter_content(chunk_size=self.chunk_size):
                fd.write(chunk)

        # Extract zip file.
        with zipfile.ZipFile(output_filename, 'r') as zip_ref:
            file_list = zip_ref.filelist # File list contains a list of all zip file contents
            # Only extract if contents don't already exist in self.target_directory
            if os.path.exists(self.target_directory+file_list[0].filename):
                print('Data was previously downloaded, discarding.')
                os.remove(output_filename)
                return
            else:
                print("New data found.")
                #zip_ref.extractall(self.target_directory)

    def download_ground_truth(self):
        if self.ground_truth_url == "http://coronavirusapi.com/getTimeSeries/":
            # Find oldest CSV file to extract GT time series
            oldest_filename = "2020_04_01.2"
            temp_df = pd.read_csv(self.target_directory + oldest_filename + '/Hospitalization_all_locs.csv')
            date_format = "%Y-%m-%d"
            temp_df['date'] = pd.to_datetime(temp_df['date'], format=date_format)
            temp_df.index = temp_df['date']

            nyt_path = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"
            nyt_r = requests.get(nyt_path, stream=True)
            nytimes_df = pd.read_csv(StringIO(nyt_r.text))
            date_format = "%Y-%m-%d"
            nytimes_df['date'] = pd.to_datetime(nytimes_df['date'], format=date_format)
            nytimes_df.index = nytimes_df['date']

            # John Hopkins University is different format, for each state there are multiple columns.
            jhu_path = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
            jhu_r = requests.get(jhu_path, stream=True)
            jhu_df = pd.read_csv(StringIO(jhu_r.text))
            jhu_date_format = "%m/%d/%y"

            for state in self.usa_states:
                print('Downloading state data for '+state[1])
                full_path = self.ground_truth_url+state[0]
                r = requests.get(full_path, stream=True)
                state_df = pd.read_csv(StringIO(r.text))
                try:
                    state_df['datetime'] = pd.to_datetime(state_df['seconds_since_Epoch'], unit='s')
                    state_df.index = state_df['datetime']
                    state_df = state_df.drop(columns=['seconds_since_Epoch', 'datetime'])
                    state_df = state_df.resample('D').max()
                    state_df = state_df.fillna(method='ffill')
                    state_df = state_df.fillna(0)
                    #Calculate deltas
                    state_df_diff = state_df.diff()
                    state_df_diff = state_df_diff.fillna(0)
                    state_df_diff = state_df_diff.rename(columns={"tested": "delta_tested", "positive": "delta_positive", "deaths": "delta_deaths_api"})
                    state_df = pd.merge(state_df, state_df_diff, how='inner', left_index=True, right_index=True)
                    state_df['state_short'] = state[0]
                    state_df['state_long'] = state[1]

                    original_state_df = temp_df[temp_df["location"] == state[1]]
                    state_df['delta_deaths_ihme'] = original_state_df.loc[state_df.index]['deaths_mean']

                    nytimes_df_tmp = nytimes_df[nytimes_df["state"] == state[1]]
                    nytimes_df_tmp = nytimes_df_tmp.drop(columns=['date', 'state'])
                    nytimes_df_tmp = nytimes_df_tmp.diff()
                    nytimes_df_tmp = nytimes_df_tmp.fillna(0)
                    nytimes_df_tmp = nytimes_df_tmp.rename(columns={"deaths": "delta_deaths"})
                    state_df['delta_deaths_nyt'] = nytimes_df_tmp.loc[state_df.index]['delta_deaths']

                    #Extract JHU Data
                    jhu_tmp = jhu_df[jhu_df["Province_State"] == state[1]]
                    #Sum per state, and filter for the dates containing 2020 as /20
                    jhu_sum_series = jhu_tmp.sum(axis=0).filter(like='/20')
                    jhu_sum_series = jhu_sum_series.diff()
                    jhu_sum_series = jhu_sum_series.fillna(0)
                    jhu_sum_series.index = pd.to_datetime(jhu_sum_series.index, format=jhu_date_format)
                    state_df['delta_deaths_jhu'] = jhu_sum_series.loc[state_df.index]

                    self.data = self.data.append(state_df, sort=True)
                except KeyError:
                    print("Captured Key Error")
        else:
            print('Data from existing source.')

    def save_data(self):
        self.data.to_csv(self.target_directory+'all_data.csv')

    def get_death_prediction(self, date_predicted, state, data_frame):
        try:
            prediction = data_frame.loc[
                    (data_frame["location"] == state) & (data_frame["date"] == date_predicted.date())]
        except:
            print('Prediction Fetch Failed')
        # Check if prediction was found
        result = []
        if len(prediction) == 1:
            result = {'EV': prediction['deaths_mean'], 'UB': prediction['deaths_upper'], 'LB': prediction['deaths_lower']}
        return result
        # This function will return three values, a dictionary, with EV (Expected Value), LB (Lower Bound) and UB (Upper Bound)

    def fetch_historical_predictions(self):
        # for each row in the Ground Truth data, search for up to X day lookahead of historical predictions.
        # Create prediction columns in the data
        for pred_idx in range(1, self.n_lookahead_evaluations+1):
            ev_column_title = 'deaths_pred_' + str(pred_idx) + '_EV'
            ub_column_title = 'deaths_pred_' + str(pred_idx) + '_UB'
            lb_column_title = 'deaths_pred_' + str(pred_idx) + '_LB'
            error_column_title = 'deaths_pred_' + str(pred_idx) + '_error'
            inside_column_title = 'deaths_pred_' + str(pred_idx) + '_inside'
            inside_detail_column_title = 'deaths_pred_' + str(pred_idx) + '_inside_detail'
            outside_by_column_title = 'deaths_pred_' + str(pred_idx) + '_outside_by'
            self.data[ev_column_title] = np.nan
            self.data[ub_column_title] = np.nan
            self.data[lb_column_title] = np.nan
            self.data[error_column_title] = np.nan
            self.data[inside_column_title] = np.nan
            self.data[inside_detail_column_title] = ''
            self.data[outside_by_column_title] = np.nan

        # Load all csv files as dataframes with their respective date as a tuple.
        prediction_datasets = []
        dir_contents = os.listdir(self.target_directory)
        for element in dir_contents:
            # Check if element string starts with 2020
            if "2020" in element:
                print("Reading dataset for predictions on :"+element)
                # Open file containing predictions for that specific day
                temp_df = pd.read_csv(self.target_directory+element+'/Hospitalization_all_locs.csv')
                # Change date column from string to actual date format
                date_format = "%Y-%m-%d"
                if "2020_03_30" in element or "2020_03_29" in element:
                    date_format = "%m/%d/%Y"
                temp_df['date'] = pd.to_datetime(temp_df['date'],format=date_format).dt.date
                prediction_datasets.append((element, temp_df))

        for index, row in self.data.iterrows():
            print(str(row["state_long"])+"\t -"+str(index))
            if index <= datetime.datetime.strptime('2020-04-08', '%Y-%m-%d'):
                for pred_idx in range(1, self.n_lookahead_evaluations+1):
                    prediction_dataset_date = index - pd.Timedelta(str(pred_idx)+' days') #On the day of the file, the next day is predicted
                    prediction_dataframe = pd.DataFrame()
                    for prediction_dataset in prediction_datasets:
                        if prediction_dataset_date.strftime("%Y_%m_%d") in prediction_dataset[0]:
                            prediction_dataframe = prediction_dataset[1]
                    if not prediction_dataframe.empty:
                        result = self.get_death_prediction(index , row['state_long'], prediction_dataframe)
                        if result:
                            self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_EV'] = result['EV'].values[0]
                            self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_UB'] = result['UB'].values[0]
                            self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_LB'] = result['LB'].values[0]
                            self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_error'] = row['delta_deaths_jhu'] - result['EV'].values[0]
                            if row['delta_deaths_jhu'] >= result['LB'].values[0] and row['delta_deaths_jhu'] <= result['UB'].values[0]:
                                self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_inside'] = 1
                                self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_outside_by'] = 0
                                self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_inside_detail'] = 'inside'

                            else:
                                self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_inside'] = 0
                                if row['delta_deaths_jhu'] < result['LB'].values[0]:
                                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_outside_by'] = row['delta_deaths_jhu'] - result['LB'].values[0]
                                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_inside_detail'] = 'below'
                                elif row['delta_deaths_jhu'] > result['UB'].values[0]:
                                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_outside_by'] = row['delta_deaths_jhu'] - result['UB'].values[0]
                                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_inside_detail'] = 'above'

        print("fetching predictions.")

    def extract(self):
        while True:
            print("COVID-19 Data Extractor: Extracting data")
            self.download_predictions()
            self.download_ground_truth()
            # Append predictions to ground truth data
            self.fetch_historical_predictions()

            self.save_data()
            print("Sleeping")
            time.sleep(self.data_extraction_period)


predictions_url = "https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip"
#ground_truth_url = "https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip"\
ground_truth_url = "http://coronavirusapi.com/getTimeSeries/"
data_extractor = DataExtractor(predictions_url, ground_truth_url)
data_extractor.extract()