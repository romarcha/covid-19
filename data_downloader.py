#!/usr/bin/env python

# Data extraction about covid 19 and predictions
__author__ = "Roman Marchant"
__copyright__ = "Copyright (C) 2020, Data Analytics for Resources and Environment DARE, The University of Sydney"
__license__ = "BSD"
__version__ = "0.0.1"
__maintainer__ = "Roman Marchant"
__email__ = "roman.marchant@sydney.edu.au"

import zipfile
import datetime
import requests
import time
import os


def download_predictions(predictions_url, raw_data_dir):
    if not os.path.exists(raw_data_dir):
        os.makedirs(raw_data_dir)
    # Checks the current date time, and adds that current date time to the downloaded zip file
    datetime_str = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    r = requests.get(predictions_url, stream=True)
    output_filename = raw_data_dir+datetime_str+".zip"
    with open(output_filename, 'wb') as fd:
        for chunk in r.iter_content(chunk_size=128):
            fd.write(chunk)

    # Extract zip file.
    with zipfile.ZipFile(output_filename, 'r') as zip_ref:
        file_list = zip_ref.filelist  # File list contains a list of all zip file contents
        # Only extract if contents don't already exist in self.target_directory
        if os.path.exists(raw_data_dir+file_list[0].filename):
            print(raw_data_dir+file_list[0].filename+' already exists, discarding download.')
            os.remove(output_filename)
            return
        else:
            print("New data found, writing "+file_list[0].filename)
            zip_ref.extractall(raw_data_dir)


ihme_predictions_url = "https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip"
while True:
    print("COVID-19 Data Downloader")
    download_predictions(ihme_predictions_url, raw_data_dir="raw_data/")
    print("Sleeping 10 minutes")
    time.sleep(600)