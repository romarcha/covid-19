#!/usr/bin/env python

# Data extraction about covid 19 and predictions
__author__ = "Roman Marchant"
__copyright__ = "Copyright (C) 2020, Data Analytics for Resources and Environment DARE, The University of Sydney"
__license__ = "BSD"
__version__ = "0.0.1"
__maintainer__ = "Roman Marchant"
__email__ = "roman.marchant@sydney.edu.au"

import os
import datetime
import time
import pandas as pd
import numpy as np

data_frame = pd.read_csv('data/all_data.csv')
data_frame['datetime'] = pd.to_datetime(data_frame['datetime'])
data_frame.index = data_frame['datetime']
data_frame = data_frame.drop(columns="datetime")
data_frame = data_frame.sort_index()

n_lookahead_evaluations = 7
# Calculate percentage inside, above and bellow for every prediction and day
performance_statistics = pd.DataFrame(columns=('date', 'percentage_inside', 'percentage_below', 'percentage_above', 'lookahead'))
for date in data_frame.index.unique():
    this_date_df = data_frame.loc[date]
    for lookahead in range(1, n_lookahead_evaluations+1):
        column_name = 'deaths_pred_'+str(lookahead)+'_outside_by'
        if this_date_df.count()[column_name] == 0:
            new_row_dict = {'date': date, 'percentage_inside': np.nan, 'percentage_below': np.nan, 'percentage_above': np.nan, 'lookahead':lookahead}
            new_row = pd.Series(new_row_dict)
            performance_statistics = performance_statistics.append(new_row, ignore_index=True)
        else:
            number_inside = this_date_df[this_date_df[column_name] == 0][column_name].count()
            number_above = this_date_df[this_date_df[column_name] > 0][column_name].count()
            number_below = this_date_df[this_date_df[column_name] < 0][column_name].count()
            total = number_inside+number_above+number_below
            new_row_dict = {'date': date, 'percentage_inside': 100*number_inside/total, 'percentage_below': 100*number_below/total,
                            'percentage_above': 100*number_above/total, 'lookahead': lookahead}
            new_row = pd.Series(new_row_dict)
            performance_statistics = performance_statistics.append(new_row, ignore_index=True)
performance_statistics['date'] = pd.to_datetime(performance_statistics['date'])
performance_statistics.index = performance_statistics['date']
performance_statistics = performance_statistics.drop(columns="date")
performance_statistics.to_csv('data/performance_statistics.csv')