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
        self.n_lookahead_evaluations = 2

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
                zip_ref.extractall(self.target_directory)

    def download_ground_truth(self):
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
                state_df_diff = state_df_diff.rename(columns={"tested": "delta_tested", "positive": "delta_positive", "deaths": "delta_deaths"})
                state_df = pd.merge(state_df, state_df_diff, how='inner', left_index=True, right_index=True)
                state_df['state_short'] = state[0]
                state_df['state_long'] = state[1]
                self.data = self.data.append(state_df, sort=True)
            except KeyError:
                print("Captured Key Error")
        self.save_data()

    def save_data(self):
        self.data.to_csv(self.target_directory+'all_data.csv')

    def get_death_prediction(self, date_prediction, date_predicted, state):
        # This function will return three values, a dictionary, with EV (Expected Value), LB (Lower Bound) and UB (Upper Bound)
        # First, check if there is a historical prediction for the date requested.
        dir_contents = os.listdir(self.target_directory)
        string_date = date_prediction.strftime("%Y_%m_%d")
        # Is there a file for the predictions from that specific day?
        prediction_file_exists = False
        result = []
        for element in dir_contents:
            if string_date in element:
                prediction_file_exists = True
                # Open file containing predictions for that specific day
                temp_df = pd.read_csv(self.target_directory+element+'/Hospitalization_all_locs.csv')
                prediction = temp_df.loc[(temp_df["location"] == state) & (temp_df["date"] == date_predicted.strftime("%Y-%m-%d"))]
                result = {'EV': prediction['deaths_mean'], 'UB': prediction['deaths_upper'], 'LB': prediction['deaths_lower']}
                break
        return result


    def fetch_historical_predictions(self):
        # for each row in the Ground Truth data, search for up to X day lookahead of historical predictions.
        # Create prediction columns in the data
        for pred_idx in range(1, self.n_lookahead_evaluations+1):
            ev_column_title = 'deaths_pred_' + str(pred_idx) + '_EV'
            ub_column_title = 'deaths_pred_' + str(pred_idx) + '_UB'
            lb_column_title = 'deaths_pred_' + str(pred_idx) + '_LB'
            self.data[ev_column_title] = np.nan
            self.data[ub_column_title] = np.nan
            self.data[lb_column_title] = np.nan
        for index, row in self.data.iterrows():
            for pred_idx in range(1, self.n_lookahead_evaluations+1):
                result = self.get_death_prediction(index-pd.Timedelta(str(pred_idx)+' days'), index , row['state_long'])
                if result:
                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_EV'] = result['EV'].values[0]
                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_UB'] = result['UB'].values[0]
                    self.data.loc[(self.data['state_long'] == row['state_long']) & (self.data.index == index), 'deaths_pred_' + str(pred_idx) + '_LB'] = result['LB'].values[0]
        print("fetching predictions.")

    def extract(self):
        while True:
            print("COVID-19 Data Extractor: Extracting data")
            self.download_predictions()
            self.download_ground_truth()
            # Apend predictions to ground truth data
            self.fetch_historical_predictions()
            time.sleep(self.data_extraction_period)


predictions_url = "https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip"
ground_truth_url = "http://coronavirusapi.com/getTimeSeries/"
data_extractor = DataExtractor(predictions_url, ground_truth_url)
data_extractor.extract()