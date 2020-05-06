import React, { Component } from "react";
import './App.css';
import axios from 'axios';
import './assets/css/map1.css';
import mapboxgl from 'mapbox-gl';
import data from "./data/out.geojson"
import Checkbox from './components/checkbox'
import checkboxes from './data/checkboxes'
import geometry from './data/geometry'
import Chart from "react-google-charts";

const ROOT_URL = 'http://ec2-13-55-123-77.ap-southeast-2.compute.amazonaws.com:3500/query'
// const ROOT_URL = 'http://localhost:3500'
mapboxgl.accessToken = 'pk.eyJ1IjoibWFudWVsdXpjYXRlZ3VpIiwiYSI6ImNrOWs4OHdtNTAzcnczbm1rbnFqb3JzangifQ.L0zmTAujoe3rq_fG--1LDw';

var map;

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      date: '',
      lookahead: 1,
      geoData: {},
      checkedItemsDate: new Map()
      
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleChangeLookahead = this.handleChangeLookahead.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.create_geojson = this.create_geojson.bind(this);
    this.update_map = this.update_map.bind(this);
    this.create_charts = this.create_charts.bind(this);
  }

  async componentDidMount() {
    map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/manueluzcategui/ck9vj0ls40m6g1iomdco2kw9e',
    center: [-100.486052, 37.830348],
    zoom: 3
    });
    var hoveredStateId = null;
    
    map.on('load', function() {
    map.addSource('states', {
    'type': 'geojson',
    'data': data});

    map.addLayer({
    'id': 'state-fills',
    'type': 'fill',
    'source': 'states',
    'layout': {},
    'paint': {
      'fill-color': [
        'interpolate',
        ['linear'],
        ['get', 'error'],
        -50,
        '#0e4d65',
        -40,
        '#10667d',
        -30,
        '#128095',
        -20,
        '#149aad',
        -10,
        '#16b4c5',
        0,
        '#ffffff',
        10,
        '#16b4c5',
        20,
        '#149aad',
        30,
        '#128095',
        40,
        '#10667d',
        50,
        '#0e4d65'
        ],
    'fill-opacity': [
    'case',
    ['boolean', ['feature-state', 'hover'], false],
    1,
    0.8
    ]
    }
    });
    map.moveLayer('state-fills', 'state-label');
    map.addLayer({
      'id': 'state-borders',
      'type': 'line',
      'source': 'states',
      'layout': {},
      'paint': {
      'line-color': '#0e4d65',
      'line-width': 1
      }
      });

    map.on('mousemove', 'state-fills', function(e) {
    if (e.features.length > 0) {
    if (hoveredStateId) {
    map.setFeatureState(
    { source: 'states', id: hoveredStateId },
    { hover: false }
    );
    }
    hoveredStateId = e.features[0].id;
    map.setFeatureState(
    { source: 'states', id: hoveredStateId },
    { hover: true }
    );
    }
    });

    map.on('mouseleave', 'state-fills', function() {
    if (hoveredStateId) {
    map.setFeatureState(
    { source: 'states', id: hoveredStateId },
    { hover: false }
    );
    }
    hoveredStateId = null;
    });
    });

    map.on('mousemove', (e) => {
        var states = map.queryRenderedFeatures(e.point, {
            // layout: "state-fills"
        });
        
        if (states.length > 0) {
            if (states[0].properties.date !== undefined){
              document.getElementById('pd').innerHTML = '<h3><strong>' + states[0].properties.name + '</strong></h3>'+
              '<p><strong>date: ' + states[0].properties.date + '</strong></p>'+
              '<p><strong>ev: ' + states[0].properties.ev + '</strong></p>'+
              '<p><strong>lb: ' + states[0].properties.lb + '</strong></p>'+
              '<p><strong>ub: ' + states[0].properties.ub + '</strong></p>'+
              '<p><strong>gt: ' + states[0].properties.gt + '</strong></p>'+
              '<p><strong>error: ' + states[0].properties.error + '</strong></p>'+
              '<p><strong>PE: ' + states[0].properties.PE + '</strong></p>'+
              '<p><strong>Adj PE: ' + states[0].properties['Adj PE'] + '</strong></p>'+
              '<p><strong>APE: ' + states[0].properties.APE + '</strong></p>'+
              '<p><strong>Adj APE: ' + states[0].properties['Adj APE'] + '</strong></p>'+
              '<p><strong>LAPE: ' + states[0].properties.LAPE + '</strong></p>'+
              '<p><strong>LAdj APE: ' + states[0].properties['LAdj APE'] + '</strong></p>'+
              '<p><strong>last_obs_date: ' + states[0].properties.last_obs_date + '</strong></p>'+
              '<p><strong>within_PI: ' + states[0].properties.within_PI + '</strong></p>'+
              '<p><strong>outside_by: ' + states[0].properties.outside_by + '</strong></p>'+
              '<p><strong>model_name: ' + states[0].properties.model_name + '</strong></p>'+
              '<p><strong>lookahead: ' + states[0].properties.lookahead + '</strong></p>'
            }
            else{
              document.getElementById('pd').innerHTML = '<p>Hover over a state!</p>';
            }              
        } else {
            document.getElementById('pd').innerHTML = '<p>Hover over a state!</p>';
        }
        });
  }

  async read_database(){
    let data = await axios.get(ROOT_URL+'/query', {
      headers: {'model_date': this.state.date, 'lookahead': this.state.lookahead}
      })
      .then(function async (response) {
        return response 
      })
      .catch(function (error) {
        console.log(error);
      })
    return data.data
  }

  create_geojson(data){
    let object = {}
    object['type'] = 'FeatureCollection'
    let features = data.map(function(element, index){
      let dict = {}
      dict['type'] = 'Feature'
      dict['id'] = index
      dict['properties'] = {
        "name": element['state_long'],
        "short_name": element['state_short'],
        "date": element['date'],
        "ev": element['ev'],
        "lb": element['lb'],
        "ub": element['ub'],
        "gt": element['gt'],
        "error": parseFloat(element['error']),
        "PE": element['PE'],
        "Adj PE": element['Adj PE'],
        "APE": element['APE'],
        "Adj APE": element['Adj APE'],
        "LAPE": element['LAPE'],
        "LAdj APE": element['LAdj APE'],
        "last_obs_date": element['last_obs_date'],
        "within_PI": element['within_PI'],
        "outside_by": element['outside_by'],
        "model_name": element['model_name'],
        "lookahead": element['lookahead']
      }
      dict['geometry'] = geometry[element['state_short']]
      return dict
    })
    object['features'] = features
    this.setState({geoData: object})
    this.update_map(object)
  }

  update_map(geojson){
    // console.log(geojson)
    map.getSource('states').setData(geojson);
  }

  async create_charts(){
    let data = await axios.get(ROOT_URL+'/timeLines', {
      headers: {'model_date': this.state.date}
      })
      .then(function async (response) {
        return response 
      })
      .catch(function (error) {
        console.log(error);
    })
    // console.log(data.data)
    let state_lines = []
    for (var key in geometry) {
      state_lines.push(data.data.filter(element => element.state_short === key))      
    }
    console.log(state_lines)

    // var data2 = new google.visualization.DataTable();
    // data2.addColumn('number', 'Day');
    // data2.addColumn('number', 'GT');

    // data.addRows([
    //   [1,  37.8, 80.8, 41.8],
    //   [2,  30.9, 69.5, 32.4],
    //   [3,  25.4,   57, 25.7],
    //   [4,  11.7, 18.8, 10.5],
    //   [5,  11.9, 17.6, 10.4],
    //   [6,   8.8, 13.6,  7.7],
    //   [7,   7.6, 12.3,  9.6],
    //   [8,  12.3, 29.2, 10.6],
    //   [9,  16.9, 42.9, 14.8],
    //   [10, 12.8, 30.9, 11.6],
    //   [11,  5.3,  7.9,  4.7],
    //   [12,  6.6,  8.4,  5.2],
    //   [13,  4.8,  6.3,  3.6],
    //   [14,  4.2,  6.2,  3.4]
    // ]);

    // var options = {
    //   chart: {
    //     title: 'Box Office Earnings in First Two Weeks of Opening',
    //     subtitle: 'in millions of dollars (USD)'
    //   },
    //   width: 900,
    //   height: 500,
    //   axes: {
    //     x: {
    //       0: {side: 'top'}
    //     }
    //   }
    // };

    // var chart = new google.charts.Line(document.getElementById('line_top_x'));

    // chart.draw(data, google.charts.Line.convertOptions(options));
  }


  async handleChange(e) {
    const item = e.target.name;
    const isChecked = e.target.checked;
    this.setState({checkedItemsDate: new Map()})
    this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
    this.setState({date: item})
  }
  async handleChangeLookahead(e) {
    this.setState({lookahead: e.currentTarget.value })
  }
  async handleSubmit(){
    let geoData = await this.read_database()
    this.create_geojson(geoData)
    // this.create_charts()
  }

  render() {
    return (
      <div className="App">
        <div className="mapContainer">
        <div>
          <div id='map'></div>
          <div className='map-overlay-select' id='features-selection'><h2>Select Model</h2>
            <div id='selection'>
            {
              checkboxes.map(item => (
                <label key={item.key}>
                  {item.name}
                  <Checkbox name={item.name} checked={this.state.checkedItemsDate.get(item.name)} onChange={this.handleChange} />
                  <br/>
                </label>
              ))
            }
            <h2>Select Lookahead</h2>
            <input style={{width: '50px'}} type="number" value={this.state.lookahead} onChange={this.handleChangeLookahead} onInput={this.handleInput} />
            <br/><br/>
            <button onClick={this.handleSubmit}>
              send
            </button>
            </div>
          </div>
          <div className='map-overlay' id='features'><h2>Data for state</h2><div id='pd'><p>Hover over a state!</p></div></div>
          <div className='map-overlay-chart' id='features-chart'><h2>Timeline</h2>
          <Chart
            width={'100%'}
            chartType="LineChart"
            loader={<div>Loading Chart</div>}
            data={[
              [
                { type: 'date', label: 'Day' },
                'GT',
              ],
              [new Date(2014, 0), -0.5]
            ]}
            options={{
              intervals: { style: 'sticks' },
              legend: 'none',
            }}
          />
          </div>
        </div>
        </div>
    </div>
    );
  }
}

export default App;
