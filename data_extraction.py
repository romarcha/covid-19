#!/usr/bin/env python

# Data extraction about covid 19 and predictions
__author__ = "Roman Marchant"
__copyright__ = "Copyright (C) 2020, Data Analytics for Resources and Environment DARE, The University of Sydney"
__license__ = "BSD"
__version__ = "0.0.1"
__maintainer__ = "Roman Marchant"
__email__ = "roman.marchant@sydney.edu.au"

import requests
import os
import datetime
import pandas as pd
import numpy as np
from io import StringIO
from defs import *


class PredictionDataset:
    def __init__(self, last_observation_date, data_frame):
        self.last_observation_date = last_observation_date
        # Only keep predictions and not historical observational data
        self.df = data_frame[data_frame.index > last_observation_date]
        self.processed_df = pd.DataFrame()

    def prediction_for_location(self, location):
        return self.df[self.df['location'] == location]

    def evaluate_performance(self, gt_data):
        first = True
        for state in usa_states:
            aux_gt_df = gt_data[gt_data['state_long'] == state[1]]
            state_df = self.df[self.df['location'] == state[1]]
            performance_df = pd.DataFrame()
            performance_df['ev'] =  state_df.loc[aux_gt_df.index]['deaths_mean']
            performance_df['lb'] = state_df.loc[aux_gt_df.index]['deaths_lower']
            performance_df['ub'] = state_df.loc[aux_gt_df.index]['deaths_upper']
            performance_df['gt'] = aux_gt_df['delta_deaths_jhu']
            performance_df['error'] = aux_gt_df['delta_deaths_jhu'] - state_df.loc[aux_gt_df.index]['deaths_mean']
            # Check if inside, below or above bounds
            performance_df = performance_df.dropna()

            performance_df['within_PI'] = ""
            performance_df['outside_by'] = np.nan
            performance_df['last_obs_date'] = self.last_observation_date

            performance_df.loc[performance_df['gt'] > performance_df['ub'], 'within_PI'] = "above"
            performance_df.loc[performance_df['gt'] > performance_df['ub'], 'outside_by'] = performance_df['gt'] - performance_df['ub']

            performance_df.loc[performance_df['gt'] < performance_df['lb'],'within_PI'] = "below"
            performance_df.loc[performance_df['gt'] < performance_df['lb'], 'outside_by'] = performance_df['gt'] - performance_df['lb']

            performance_df.loc[(performance_df['gt'] >= performance_df['lb']) & (performance_df['gt'] <= performance_df['ub']),'within_PI'] = "inside"
            performance_df.loc[(performance_df['gt'] >= performance_df['lb']) & (performance_df['gt'] <= performance_df['ub']), 'outside_by'] = 0

            performance_df['state_long'] = state[1]
            performance_df['state_short'] = state[0]
            performance_df['lookahead'] = (performance_df.index - self.last_observation_date).days
            if first:
                self.processed_df = performance_df
                first = False
            else:
                self.processed_df = self.processed_df.append(performance_df)


class CovidPredictionEvaluator:
    def __init__(self, model_directory):
        # Model directory contains the data of predictions by the model.
        self.model_directory = model_directory
        # It is up to the user to move the prediction datasets to be moved to specific directory.
        
        # If directory does not exist then evaluator cannot evaluate anything.
        if not os.path.exists(self.model_directory):
            raise BaseException("Directory for this model does not exist.")

        self.datasets = []
        self.gt_data = pd.DataFrame()
        self.all_data = pd.DataFrame()
        self.organise_data()
        self.evaluate_datasets()
        self.calculate_performance()
        print('Finished initialising model evaluation.')

    def calculate_performance(self):
        for lookahead in range(1, 5):
            lookahead_data = self.all_data[self.all_data['lookahead'] == lookahead]
            lookahead_data['range'] = lookahead_data['ub']-lookahead_data['lb']
            n_inside = lookahead_data[lookahead_data['within_PI'] == 'inside']['within_PI'].count()
            n_below = lookahead_data[lookahead_data['within_PI'] == 'below']['within_PI'].count()
            n_above = lookahead_data[lookahead_data['within_PI'] == 'above']['within_PI'].count()
            avg_range = lookahead_data['range'].mean()
            rmse = np.sqrt((lookahead_data['error'] ** 2).mean())
            n_total = n_inside + n_below + n_above
            perc_inside = 100 * n_inside / n_total
            perc_below = 100 * n_below / n_total
            perc_above = 100 * n_above / n_total
            print('Just Lookahead: ' + str(lookahead) + 'RMSE = ' + str(rmse)+ ' Range '+ str(avg_range) + ' (' + str(perc_inside) + ',' + str(
                perc_below) + ',' + str(perc_above) + ')')

        for dataset in self.datasets:
            last_obs_date = dataset.last_observation_date
            for lookahead in range(1,5):
                lookahead_data = self.all_data[(self.all_data['lookahead'] == lookahead) & (self.all_data['last_obs_date'] == last_obs_date)]
                n_inside = lookahead_data[lookahead_data['within_PI'] == 'inside']['within_PI'].count()
                n_below = lookahead_data[lookahead_data['within_PI'] == 'below']['within_PI'].count()
                n_above = lookahead_data[lookahead_data['within_PI'] == 'above']['within_PI'].count()
                n_total = n_inside + n_below + n_above
                perc_inside = 100* n_inside / n_total
                perc_below = 100 * n_below/ n_total
                perc_above = 100 * n_above / n_total
                print(str(last_obs_date)+' Lookahead = '+str(lookahead)+' ('+str(perc_inside)+','+str(perc_below)+','+str(perc_above)+')')
                #lookahead_data.groupby('last_obs_date')
                #percentage_inside = lookahead_data

    def organise_data(self):
        # Load all csv files with their respective last observation date.

        # Initialise latest file to early date
        latest_file = pd.to_datetime("2000-01-01")

        latest_filename = []
        dir_contents = os.listdir(self.model_directory)

        filename_date_format = "%Y_%m_%d"
        for element in dir_contents:
            # Check if element string starts with 2020
            if "2020" in element:
                print("Reading dataset for predictions on :"+element)
                last_observation_on = pd.to_datetime(element[:10], format=filename_date_format)
                if last_observation_on > latest_file:
                    latest_file = last_observation_on
                    latest_filename = element
                # Open file containing predictions for that specific day
                temp_df = pd.read_csv(self.model_directory+element+'/Hospitalization_all_locs.csv')
                # Change date column from string to actual date format
                date_format = "%Y-%m-%d"
                # Some datasets were preprocessed by third party so changed format of dates
                if "2020_03_30" in element or "2020_03_29" in element:
                    date_format = "%m/%d/%Y"
                temp_df.index = pd.to_datetime(temp_df['date'], format=date_format)
                # Check if file contains location as name, if not turn location_name to location
                if 'location' not in temp_df:
                    if 'location_name' in temp_df:
                        temp_df = temp_df.rename(columns ={'location_name':'location'})
                temp_df = temp_df[['location', 'deaths_mean', 'deaths_lower', 'deaths_upper']]
                prediction_dataset = PredictionDataset(last_observation_date=last_observation_on,data_frame=temp_df)
                self.datasets.append(prediction_dataset)

        # Find oldest CSV file to extract GT time series of IHME
#        oldest_filename = latest_filename
#        ihme_latest_df = pd.read_csv(self.model_directory + oldest_filename + '/Hospitalization_all_locs.csv')
#        date_format = "%Y-%m-%d"
#        # Check if file contains location as name, if not turn location_name to location
#        if 'location' not in ihme_latest_df:
#            if 'location_name' in ihme_latest_df:
#                ihme_latest_df = ihme_latest_df.rename(columns={'location_name': 'location'})
#        ihme_latest_df['date'] = pd.to_datetime(ihme_latest_df['date'], format=date_format)
#        ihme_latest_df.index = ihme_latest_df['date']

#        print('Extracting New York Times Data')
#        nyt_path = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"
#        nyt_r = requests.get(nyt_path, stream=True)
#        nytimes_df = pd.read_csv(StringIO(nyt_r.text))
#        date_format = "%Y-%m-%d"
#        nytimes_df['date'] = pd.to_datetime(nytimes_df['date'], format=date_format)
#        nytimes_df.index = nytimes_df['date']

        # John Hopkins University is different format, for each state there are multiple columns.
        print('Extracting John Hopkins University Data')
        jhu_path = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
        jhu_r = requests.get(jhu_path, stream=True)
        jhu_df = pd.read_csv(StringIO(jhu_r.text))
        jhu_date_format = "%m/%d/%y"

        for state in usa_states:
            print('Extracting state data for '+state[1])
            state_df = pd.DataFrame()
            state_df['date'] = pd.date_range(start=pd.to_datetime("2020-01-01"), end=pd.to_datetime("2020-12-31"))
            state_df.index = state_df['date']
            state_df = state_df.drop(columns=['date'])
            state_df['state_short'] = state[0]
            state_df['state_long'] = state[1]
            try:
                # Extract JHU Data
                jhu_tmp = jhu_df[jhu_df["Province_State"] == state[1]]
                #Sum per state, and filter for the dates containing 2020 as /20
                jhu_sum_series = jhu_tmp.sum(axis=0).filter(like='/20')
                jhu_sum_series = jhu_sum_series.diff()
                jhu_sum_series = jhu_sum_series.fillna(0)
                jhu_sum_series.index = pd.to_datetime(jhu_sum_series.index, format=jhu_date_format)
                state_df['delta_deaths_jhu'] = jhu_sum_series.loc[state_df.index]

                self.gt_data = self.gt_data.append(state_df, sort=True)

            except KeyError:
                print("Captured Key Error")
        self.gt_data = self.gt_data.dropna()

    def evaluate_datasets(self):
        first = True
        for prediction_dataset in self.datasets:
            prediction_dataset.evaluate_performance(self.gt_data)
            if first:
                self.all_data = prediction_dataset.processed_df
                first = False
            else:
                self.all_data = self.all_data.append(prediction_dataset.processed_df)

    def save_data(self):
        self.data.to_csv(self.model_directory+'all_data.csv')

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
        # Load all csv files as dataframes with their respective date as a tuple.
        prediction_datasets = []
        dir_contents = os.listdir(self.model_directory)
        for element in dir_contents:
            # Check if element string starts with 2020
            if "2020" in element:
                print("Reading dataset for predictions on :"+element)
                filename_date_format = "%Y_%m_%d"
                filename_predicted_on = pd.to_datetime(element[:10], format=filename_date_format)
                # Open file containing predictions for that specific day
                temp_df = pd.read_csv(self.model_directory+element+'/Hospitalization_all_locs.csv')
                # Change date column from string to actual date format
                date_format = "%Y-%m-%d"
                if "2020_03_30" in element or "2020_03_29" in element:
                    date_format = "%m/%d/%Y"
                temp_df.index = pd.to_datetime(temp_df['date'], format=date_format)
                temp_df.drop(columns="date")

                prediction_datasets.append((element, temp_df))

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


# Target directory contains data on predictions for every day.
evaluator_1 = CovidPredictionEvaluator(model_directory='data_model_1/')
evaluator_2 = CovidPredictionEvaluator(model_directory='data_model_2/')