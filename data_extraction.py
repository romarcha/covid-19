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
        self.data_extraction_time = "06:00:00"#"09:00:00"
        self.datetime_last_captured = ""
        self.now_datetime = datetime.datetime.now()
        self.usa_states = ['AK', 'AL', 'AR', 'AZ', 'CA', 'DC', 'DE', 'FL', 'GA', 'HI', 'IA',
                            'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN','MO','MS',
                            'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'PR',
                            'RI', 'SC', 'SD', 'TN', 'TX', 'USA', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY']

    def download_predictions(self):
        # Checks the current date time, and adds that current date time to the downloaded zip file
        datetime_str = self.now_datetime.strftime("%Y-%m-%d_%H-%M-%S")
        r = requests.get(self.predictions_url, stream=True)
        output_filename = self.target_directory + "raw_data/predictions_" + datetime_str + ".zip"
        with open(output_filename, 'wb') as fd:
            for chunk in r.iter_content(chunk_size=self.chunk_size):
                fd.write(chunk)
        # Extract zip file.
        with zipfile.ZipFile(output_filename, 'r') as zip_ref:
            zip_ref.extractall(self.target_directory)

    def download_ground_truth(self):
        for state in self.usa_states:
            full_path = self.ground_truth_url+state
            r = requests.get(full_path, stream=True)
            datetime_str = self.now_datetime.strftime("%Y-%m-%d_%H-%M-%S")
            output_filename = self.target_directory + "raw_data/ground_truth_" + state + "_" + datetime_str + ".csv"
            with open(output_filename, 'wb') as fd:
                for chunk in r.iter_content(chunk_size=self.chunk_size):
                    fd.write(chunk)

    def was_data_captured_today(self):
        if self.datetime_last_captured == "":
            return False
        elif self.datetime_last_captured.date() == datetime.datetime.now().date():
            return True
        else:
            return False

    def extract(self):
        while True:
            # Check current time, if time is over extraction time, and data hasn't been captured today, then capture it.
            self.now_datetime = datetime.datetime.now()
            now_time = self.now_datetime.time()
            extraction_time = datetime.datetime.strptime(self.data_extraction_time, '%H:%M:%S').time()
            if now_time > extraction_time and not self.was_data_captured_today():
                print("COVID-19 Data Extractor: Extracting data")
                self.download_predictions()
                self.download_ground_truth()
                self.datetime_last_captured = self.now_datetime
            else:
                print("COVID-19 Data Extractor: Sleeping until "+self.data_extraction_time+". Last extraction ")#+self.datetime_last_captured.strftime("%Y-%m-%d_%H-%M-%S"))
            time.sleep(1)


predictions_url = "https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip"
ground_truth_url = "http://coronavirusapi.com/getTimeSeries/"
data_extractor = DataExtractor(predictions_url, ground_truth_url)
data_extractor.extract()