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
import matplotlib.pyplot as plt

usa_states = [('AK', 'Alaska',10),
                   ('AL', 'Alabama', 1000),
                   ('AR', 'Arkansas', 50),
                   ('AZ', 'Arizona', 100),
                   ('CA', 'California', 300),
                   ('CO', 'Colorado', 150),
                   ('CT', 'Connecticut', 60),
                   ('DC', 'District of Columbia',30),
                   ('DE', 'Delaware',40),
                   ('FL', 'Florida',500),
                   ('GA', 'Georgia',120),
                   ('HI', 'Hawaii',25),
                   ('IA', 'Iowa',70),
                   ('ID', 'Idaho',30),
                   ('IL', 'Illinois',360),
                   ('IN', 'Indiana',80),
                   ('KS', 'Kansas',40),
                   ('KY', 'Kentucky',65),
                   ('LA', 'Louisiana',180),
                   ('MA', 'Massachusetts',180),
                   ('MD', 'Maryland',120),
                   ('ME', 'Maine',160),
                   ('MI', 'Michigan',250),
                   ('MN', 'Minnesota',130),
                   ('MO', 'Missouri',60),
                   ('MS', 'Mississippi',180),
                   ('MT', 'Montana',17),
                   ('NC', 'North Carolina',160),
                   ('ND', 'North Dakota',12),
                   ('NE', 'Nebraska',30),
                   ('NH', 'New Hampshire',20),
                   ('NJ', 'New Jersey',150),
                   ('NM', 'New Mexico',35),
                   ('NV', 'Nevada',60),
                   ('NY', 'New York',1200),
                   ('OH', 'Ohio',170),
                   ('OK', 'Oklahoma',100),
                   ('OR', 'Oregon',25),
                   ('PA', 'Pennsylvania',120),
                   ('RI', 'Rhode Island',15),
                   ('SC', 'South Carolina',65),
                   ('SD', 'South Dakota',12),
                   ('TN', 'Tennessee',350),
                   ('TX', 'Texas',400),
                   ('UT', 'Utah',35),
                   ('VA', 'Virginia',180),
                   ('VT', 'Vermont',4),
                   ('WA', 'Washington',80),
                   ('WI', 'Wisconsin',190),
                   ('WV', 'West Virginia',35),
                   ('WY', 'Wyoming',10)]

data_frame = pd.read_csv('data/all_data.csv')
data_frame['date'] = pd.to_datetime(data_frame['date'])
data_frame.index = data_frame['date']
data_frame = data_frame.drop(columns="date")
data_frame = data_frame.sort_index()

# Comparison prediction
for state in usa_states:
    fig, ax = plt.subplots()
    date_1 = "2020-04-01"
    date_2 = "2020-04-03"
    data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_' + date_1 + '_EV'].plot(
        title=state[1]+" model update", color='b', label='Model of '+date_1)
    # data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_jhu'].plot(marker='x', linewidth=0)
    avail_data = data_frame
    avail_data.loc[(avail_data['state_long'] == state[1]), 'delta_deaths_jhu'].plot(linewidth=1, alpha=0.5, color='k', marker='x', markersize=1, label='JHU Observed Deaths')
    d = data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_jhu'].index.values
    plt.fill_between(d, data_frame.loc[
        (data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_' + date_1 + '_LB'], data_frame.loc[
                         (data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_' + date_1 + '_UB'],
                     facecolor='blue', alpha=0.2, interpolate=True)
    data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_' + date_2 + '_EV'].plot(
        title=state[1]+" model update", color='r', label='Model of '+date_2)
    plt.fill_between(d, data_frame.loc[
        (data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_' + date_2 + '_LB'], data_frame.loc[
                         (data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_' + date_2 + '_UB'],
                     facecolor='red', alpha=0.2, interpolate=True)
    ax.legend()
    if not os.path.exists('data/results/comparisons'):
        os.makedirs('data/results/comparisons')
    #saving_filename = 'data/results/comparisons/' + state[1] + '_all.pdf'
    saving_filename = 'data/results/comparisons/' + state[1] + '_all.png'
    plt.savefig(saving_filename)
    print("Saving image to :"+saving_filename)

# All datapoints
pred_dates = ["2020-03-29"]
for pred_date in pred_dates:
    for state in usa_states:
        fig, ax = plt.subplots()
        data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_'+pred_date+'_EV'].plot(title=state[1]+" - predicted on "+pred_date)
        # data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_jhu'].plot(marker='x', linewidth=0)
        avail_data = data_frame
        avail_data.loc[(avail_data['state_long'] == state[1]), 'delta_deaths_jhu'].plot(linewidth=1, alpha=0.5, color='k')
        d = data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_jhu'].index.values
        plt.fill_between(d, data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_'+pred_date+'_LB'], data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_'+pred_date+'_UB'], facecolor='blue', alpha=0.2, interpolate=True)
        ax.set_ylim(0, state[2])
        if not os.path.exists('data/results/all_data'):
            os.makedirs('data/results/all_data')
        #saving_filename = 'data/results/all_data/'+state[1]+'_'+pred_date+'_all.pdf'
        saving_filename = 'data/results/all_data/' + state[1] + '_' + pred_date + '_all.png'
        plt.savefig(saving_filename)
        print("Saving image to :" + saving_filename)

# Incrementally add datapoints
pred_dates = ["2020-03-29", "2020-03-30", "2020-03-31", "2020-04-01", "2020-04-03", "2020-04-07", "2020-04-12"]
for pred_date in pred_dates:
    for state in usa_states:
        fig, ax = plt.subplots()
        data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_'+pred_date+'_EV'].plot(title=state[1]+" - predicted on "+pred_date)
        # data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_jhu'].plot(marker='x', linewidth=0)
        avail_data = data_frame[data_frame.index <= pd.to_datetime(pred_date)]
        avail_data.loc[(avail_data['state_long'] == state[1]), 'delta_deaths_jhu'].plot(linewidth=1, alpha=0.5)
        d = data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_jhu'].index.values
        plt.fill_between(d, data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_'+pred_date+'_LB'], data_frame.loc[(data_frame['state_long'] == state[1]), 'delta_deaths_ihme_pred_'+pred_date+'_UB'], facecolor='blue', alpha=0.2, interpolate=True)
        ax.set_ylim(0, state[2])
        if not os.path.exists('data/results/incremental/'):
            os.makedirs('data/results/incremental/')
        #saving_filename = 'data/results/incremental/'+state[1]+'_'+pred_date+'.pdf'
        saving_filename = 'data/results/incremental/' + state[1] + '_' + pred_date + '.png'
        plt.savefig(saving_filename)
        print("Saving image to :" + saving_filename)


n_lookahead_evaluations = 7
# Calculate percentage inside, above and bellow for every prediction and day
performance_statistics = pd.DataFrame(columns=('date', 'percentage_inside', 'percentage_below', 'percentage_above', 'lookahead'))
for date in data_frame.index.unique():
    this_date_df = data_frame.loc[date]
    for lookahead in range(1, n_lookahead_evaluations+1):
        column_name = 'deaths_pred_'+str(lookahead)+'_outside_by'
        if this_date_df.count()[column_name] == 0:
            new_row_dict = {'date': date, 'percentage_inside': np.nan, 'percentage_below': np.nan, 'percentage_above': np.nan, 'lookahead': lookahead}
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