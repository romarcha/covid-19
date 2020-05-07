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
from sqlalchemy import create_engine


class PredictionDataset:
    def __init__(self, last_observation_date, data_frame, model_name):
        self.last_observation_date = last_observation_date
        # Only keep predictions and not historical observational data
        self.df = data_frame[data_frame.index > last_observation_date]
        self.processed_df = pd.DataFrame()
        self.model_name = model_name
        self.performance_evaluated = False

    def prediction_for_location(self, location):
        return self.df[self.df['location'] == location]

    def get_pi_stats(self, date):
        # For a specific date. Get the prediction interval statistics for each state.
        item_df = self.processed_df.loc[date]
        n_inside = item_df[item_df['within_PI'] == 'inside']['within_PI'].count()
        n_below = item_df[item_df['within_PI'] == 'below']['within_PI'].count()
        n_above = item_df[item_df['within_PI'] == 'above']['within_PI'].count()

        n_total = n_inside+n_below+n_above
        if not n_total == 51:
            print("Not 51 states in data, there are "+str(n_total))
        result = {'n_inside': 100*n_inside/n_total, 'n_below': 100*n_below/n_total, 'n_above': 100*n_above/n_total}
        return result

    def get_stats_per_state(self):
        # Return a list of states, with their respective area between PIs, i.e. sum over all time points
        result = []
        for state in usa_states:
            state_df = self.df[self.df['location'] == state[1]]
            state_df = state_df[state_df.index >= pd.to_datetime("2020-04-17")] #Use the same date as minimum for all models, otherwise the total area between lower and upper bound comparison is unfair.
            #todo: Even though the starting date is the same. Some models start predicting far after 2020-04-17, therefore comparisons are still unfair. The date should be selected as the maximum of the minimum of all predicted dates of models.
            area = sum(state_df['deaths_upper'] - state_df['deaths_lower'])
            max_val = max(state_df['deaths_mean'])
            max_date = state_df['deaths_mean'].idxmax()
            range_at_max = state_df.loc[max_date]['deaths_upper'] - state_df.loc[max_date]['deaths_lower']
            result.append([state[1], area, max_val, max_date, range_at_max, self.last_observation_date, self.model_name])

        df_result = pd.DataFrame(result, columns=['state', 'area_between_bounds', 'max_ev', 'date_max_ev', 'range_at_max', 'last_observation_date', 'model_name'])
        df_result.index = df_result['state']
        df_result = df_result.drop(columns='state')
        return df_result

    def get_max_prediction(self):
        print("Returning max prediction date")
        #Check per state the maximum date and maximum value
        for state in usa_states:
            state_df = self.df[self.df['location'] == state[1]]
            max_val = max(state_df['deaths_mean'])
            max_date = state_df['deaths_mean'].idxmax()
            print("Prediction max and date: "+str(self.last_observation_date)+" "+state[1]+": "+str(max_val)+", "+str(max_date))
        return max(self.df)

    def evaluate_performance(self, gt_data):
        first = True
        for state in usa_states:
            print("Evaluating performance for "+state[1]+" \t\t Model last obs: "+str(self.last_observation_date))
            aux_gt_df = gt_data[gt_data['state_long'] == state[1]]
            state_df = self.df[self.df['location'] == state[1]]
            performance_df = pd.DataFrame()
            performance_df['ev'] = state_df.reindex(aux_gt_df.index)['deaths_mean']
            performance_df['lb'] = state_df.reindex(aux_gt_df.index)['deaths_lower']
            performance_df['ub'] = state_df.reindex(aux_gt_df.index)['deaths_upper']
            # Only for new york use the data from the new york times
            if state[1] == "New York":
                performance_df['gt'] = aux_gt_df['delta_deaths_nyt']
            else:
                performance_df['gt'] = aux_gt_df['delta_deaths_jhu']

            performance_df['gt_ihme'] = aux_gt_df['delta_deaths_ihme']
            performance_df['gt_nyt'] = aux_gt_df['delta_deaths_nyt']
            performance_df['error'] = aux_gt_df['delta_deaths_jhu'] - state_df.reindex(aux_gt_df.index)['deaths_mean']

            # Fill up all performance values with default value
            performance_df['PE'] = np.nan
            performance_df['Adj PE'] = np.nan
            performance_df['APE'] = np.nan

            for i, row in performance_df.iterrows():
                if row['ev'] == 0 and row['gt'] == 0:
                    performance_df.at[i, 'PE'] = 0
                    performance_df.at[i, 'Adj PE'] = 0
                elif pd.isna(row['ev']) or pd.isna('gt'):
                    performance_df.at[i, 'PE'] = np.nan
                    performance_df.at[i, 'Adj PE'] = np.nan
                elif not row['ev'] == 0 and row['gt'] == 0:
                    performance_df.at[i, 'PE'] = np.inf
                    performance_df.at[i, 'Adj PE'] = 100 * row['error'] / (row['gt']+row['ev'])
                else:
                    performance_df.at[i, 'PE'] = 100 * row['error'] / row['gt']
                    performance_df.at[i, 'Adj PE'] = 100 * row['error'] / (row['gt']+row['ev'])

            performance_df['APE'] = np.abs(performance_df['PE'])
            performance_df['Adj APE'] = np.abs(performance_df['Adj PE'])
            performance_df['LAPE'] = 1 / (1 + np.exp(-performance_df['APE']/100))
            performance_df['LAdj APE'] = 1 / (1 + np.exp(-performance_df['Adj APE']/100))

            if (performance_df['LAPE'] > 1).any():
                raise Exception("LAPE greater than 1")

            performance_df['last_obs_date'] = self.last_observation_date
            # Check if inside, below or above bounds
            #performance_df = performance_df.dropna()

            performance_df['within_PI'] = ""
            performance_df['outside_by'] = np.nan
            performance_df['last_obs_date'] = self.last_observation_date
            performance_df['model_name'] = self.model_name

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
        self.performance_evaluated = True

#    def plot(self):


class CovidPredictionEvaluator:
    def __init__(self, model_directory, model_name):
        # Model directory contains the data of predictions by the model.
        self.model_directory = model_directory
        self.model_name = model_name
        # It is up to the user to move the prediction datasets to be moved to specific directory.
        
        # If directory does not exist then evaluator cannot evaluate anything.
        if not os.path.exists(self.model_directory):
            raise BaseException("Directory for this model does not exist.")

        self.datasets = []
        self.gt_data = pd.DataFrame()
        self.all_data = pd.DataFrame()
        self.organise_data()
        self.evaluate_datasets()
#        self.calculate_performance()
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

    def plot_results(self):
        # First plot consists of showing one-two-three and four steps lookahead by date on a box plot with the states.
        init_date = pd.to_datetime("2020-03-30")
        final_date = pd.to_datetime("2020-04-16")

        # Table of percentage within, below and above PIs
        date_range = pd.date_range(start="2020-03-30", end="2020-04-16")
        with open(self.model_directory+'PI_table.tex', mode='w') as file_:
            file_.write("\\begin{tabular}\n")
            file_.write("{ | l | c | c | c | c |}\n")
            file_.write("\\hline\n")
            file_.write("    & 1 - step & 2 - step & 3 - step & 4 - step \\\\\n")
            file_.write("\\hline\n")
            for date_ in date_range:
                print(date_)
                date_str = date_.strftime("%B %d")
                file_.write(date_str+" & ")
                for lookahead_ in range(1, 5):
                    values_str = ""
                    dataset_date = date_ - datetime.timedelta(days=lookahead_)
                    print("Dataset date: " + str(dataset_date))
                    for dataset in self.datasets:
                        if dataset.last_observation_date == dataset_date:
                            print("Dataset Found!")
                            pi_stats = dataset.get_pi_stats(date_)
                            values_str = "{:.0f}".format(pi_stats['n_inside'])+"("+"{:.0f}".format(pi_stats['n_below'])+","+"{:.0f}".format(pi_stats['n_above'])+")"
                            print(pi_stats)
                    if lookahead_ < 4:
                        file_.write(values_str+" & ")
                    else:
                        file_.write(values_str + " \\\\\n")
            file_.write("\\hline\n")
            file_.write("\\end{tabular}\n")

    def get_all_data_as_csv(self):
        # For each dataset
        df_list = []
        for dataset in self.datasets:
            df_list.append(dataset.processed_df)
        df_all = pd.concat(df_list)
        df_all.to_csv(self.model_directory + 'output_data.csv')
        print('Finished concatenating all.')
        return df_all

    def get_state_data_as_csv(self):
        df_list = []
        for dataset in self.datasets:
            df_list.append(dataset.get_stats_per_state())
        df_all = pd.concat(df_list)
        df_all.to_csv(self.model_directory + 'output_data_per_state.csv')
        return df_all

    def upload_to_db(self):
        # For each dataset
        df_list = []
        for dataset in self.datasets:
            df_list.append(dataset.processed_df)
        df_all = pd.concat(df_list)
        db_username = "covidDB"
        db_password = "KiorwWN46Kjr1wC8WiZE"
        db_host = "covid-databases.cwtoyn9xsrzw.ap-southeast-2.rds.amazonaws.com"
        db_port = "5432"
        db_database = "postgres"
        engine = create_engine('postgresql+psycopg2://'+db_username+':'+db_password+'@'+db_host+':'+db_port+'/'+db_database)
        print("Writing to SQL databbase.")
        df_all.head(0).to_sql('all_results', engine, if_exists='replace', index=True)  # truncates the table
        conn = engine.raw_connection()
        cur = conn.cursor()
        output = StringIO()
        df_all.to_csv(output, sep='\t', header=False, index=True)
        output.seek(0)
        cur.copy_from(output, 'all_results', null="")  # null values become ''
        conn.commit()
        print("Finished writing to SQL databbase.")

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
                prediction_dataset = PredictionDataset(last_observation_date=last_observation_on,data_frame=temp_df,model_name=self.model_name)
                self.datasets.append(prediction_dataset)

        # Find oldest CSV file to extract GT time series
        oldest_filename = latest_filename
        ihme_latest_df = pd.read_csv(self.model_directory + oldest_filename + '/Hospitalization_all_locs.csv')
        date_format = "%Y-%m-%d"
        # Some datasets were preprocessed by third party so changed format of dates
        if "2020_03_30" in oldest_filename or "2020_03_29" in oldest_filename:
            date_format = "%m/%d/%Y"
        ihme_latest_df['date'] = pd.to_datetime(ihme_latest_df['date'], format=date_format)
        ihme_latest_df.index = ihme_latest_df['date']
        # Check if file contains location as name, if not turn location_name to location
        if 'location' not in ihme_latest_df:
            if 'location_name' in ihme_latest_df:
                ihme_latest_df = ihme_latest_df.rename(columns={'location_name': 'location'})

        # 'Extracting New York Times Data'
        nyt_path = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"
        nyt_r = requests.get(nyt_path, stream=True)
        nytimes_df = pd.read_csv(StringIO(nyt_r.text))
        date_format = "%Y-%m-%d"
        nytimes_df['date'] = pd.to_datetime(nytimes_df['date'], format=date_format)
        nytimes_df.index = nytimes_df['date']

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
                # IHME Ground Truth Data
                original_state_df = ihme_latest_df[ihme_latest_df["location"] == state[1]]
                original_state_df = original_state_df[original_state_df.index < latest_file]
                state_df['delta_deaths_ihme'] = original_state_df.reindex(state_df.index)['deaths_mean']

                # New York Times Data
                nytimes_df_tmp = nytimes_df[nytimes_df["state"] == state[1]]
                nytimes_df_tmp = nytimes_df_tmp.drop(columns=['date', 'state'])
                nytimes_df_tmp = nytimes_df_tmp.diff()
                nytimes_df_tmp = nytimes_df_tmp.fillna(0)
                nytimes_df_tmp = nytimes_df_tmp.rename(columns={"deaths": "delta_deaths"})
                state_df['delta_deaths_nyt'] = nytimes_df_tmp.reindex(state_df.index)['delta_deaths']

                # Extract JHU Data
                jhu_tmp = jhu_df[jhu_df["Province_State"] == state[1]]
                #Sum per state, and filter for the dates containing 2020 as /20
                jhu_sum_series = jhu_tmp.sum(axis=0).filter(like='/20')
                jhu_sum_series = jhu_sum_series.diff()
                jhu_sum_series = jhu_sum_series.fillna(0)
                jhu_sum_series.index = pd.to_datetime(jhu_sum_series.index, format=jhu_date_format)
                state_df['delta_deaths_jhu'] = jhu_sum_series.reindex(state_df.index)

                self.gt_data = self.gt_data.append(state_df, sort=True)

            except KeyError as raised_error:
                print("Captured Key Error "+str(raised_error))
#        self.gt_data = self.gt_data.dropna()

    def evaluate_area_overlap_matrix(self):
        # Evaluate the overlap in total area between one model and the rest, summed for all states.
        for dataset_i in self.datasets:
            for dataset_j in self.datasets:
                overlap_val = dataset_i.overlap_with(dataset_j)

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


# Target directory contains data on predictions for every day.
evaluator = CovidPredictionEvaluator(model_directory='data/', model_name="IHME")
evaluator.plot_results()
evaluator.get_all_data_as_csv()
evaluator.get_state_data_as_csv()
evaluator.upload_to_db()
print("Written results to csv")
