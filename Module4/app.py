import os

import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.express as px
import pandas as pd
from dash.dependencies import Input, Output
import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']

app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

def get_spp_list():
    soql_url = (
        'https://data.cityofnewyork.us/resource/nwxe-4ae8.json?' +\
        '$select=spc_common,count(tree_id)' +\
        '&$group=spc_common'
    ).replace(" ", "%20")
    spp_list = pd.read_json(soql_url).dropna()
    return spp_list.spc_common.tolist()

def get_steward(x):
    if x == "None":
        return "natural"
    else:
        return "steward"

# def bar_color()

boros = ['Bronx', 'Brooklyn', 'Manhattan', 'Staten Island', 'Queens']
species = get_spp_list()


app.layout = html.Div(children=[
    html.H4(className='page-title', children='DATA 608 - Assignment #4'),
    html.H5(className='author', children='Zach Alexander'),
    html.H5(className='date', children='October 18th, 2020'),
    html.H6(className='question-text', children='Question #1: What proportion of trees are in good, fair, or poor health according to the ‘health’ variable?'),

    html.Div([
        dcc.Dropdown(
            id='species-selection1',
            options=[{'label': i, 'value': i} for i in species],
            value='American beech',
            className='dropdown'
        ),
    ]),

    html.Div(
        dcc.Graph(id='health-graphic', className='graph1')
    ),

    html.H6(className='question-text', children='Question #2: Are stewards (steward activity measured by the ‘steward’ variable) having an impact on the health of trees?'),

    html.Div([
        html.Div([
            dcc.Dropdown(
                id='boro-selection',
                options=[{'label': j, 'value': j} for j in boros],
                value='Bronx',
                className='dropdown2',
                placeholder='Please select a Borough'
            ),
        ]),

        html.Div([
            dcc.Dropdown(
                id='species-selection2',
                options=[{'label': i, 'value': i} for i in species],
                value='American beech',
                className='dropdown2',
                placeholder='Please select a species'
            ),
        ])
    ], className='dropdown-wrapper'),


    html.Div(
        dcc.Graph(id='steward-graph', className='graph2')
    )
])

@app.callback(
    Output(component_id='health-graphic', component_property='figure'),
    [Input(component_id='species-selection1', component_property='value')]
)
def update_graph(species):
    final_df = pd.DataFrame([])
    for i in boros:
        soql_url = ('https://data.cityofnewyork.us/resource/nwxe-4ae8.json?' +\
                '$select=spc_common,health' +\
                '&$where=boroname=\'' + i + '\'' + '&spc_common=\'' + species +\
                '\'&$limit=300000').replace(' ', '%20')          

        soql_trees = pd.read_json(soql_url)
        soql_trees = soql_trees.groupby('health').count()['spc_common'].reset_index()
        soql_trees['boro'] = i
        final_df = final_df.append(soql_trees)

    fig = px.bar(final_df, x='boro', y='spc_common', color='health', barmode="group", labels=dict(boro="Borough", spc_common="Number of Trees"))

    return fig



@app.callback(
    Output(component_id='steward-graph', component_property='figure'),
    [Input(component_id='boro-selection', component_property='value'),
    Input(component_id='species-selection2', component_property='value')]
)
def get_steward_graph_data(boro, species):
    soql_url2 = ('https://data.cityofnewyork.us/resource/nwxe-4ae8.json?' +\
            '$select=steward,health,count(tree_id)' +\
            '&$where=boroname=\'' + boro + '\'' + '&spc_common=\'' + species +\
            '\'&$group=steward,health').replace(' ', '%20')  

    df = pd.read_json(soql_url2).dropna().rename(columns={"count_tree_id": "num_trees"})
    df["type"] = df.steward.apply(get_steward)
    df = df.groupby(["type", "health"])["num_trees"].sum().reset_index()
    df2 = df.groupby("type")["num_trees"].sum().reset_index().rename(columns={"num_trees": "total"})
    df = pd.merge(df, df2)
    df["share"] = df.num_trees / df.total * 100

    fig = px.bar(df, x='type', y='share', color='health', barmode="group", labels=dict(type="Whether steward intervened or nature", share="Proportion of trees (%)"))
    fig.update_layout(width=900, height=500)
    return fig

if __name__ == '__main__':
    app.run_server(debug=True)
