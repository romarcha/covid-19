import React, { Component } from "react";
import ReactDOM from 'react-dom';
import './App.css';
import axios from 'axios';
import './assets/css/map1.css';
import mapboxgl from 'mapbox-gl';
import data from "./data/out.geojson"
import Checkbox from './components/checkbox'
import checkboxes from './data/checkboxes'
import geometry from './data/geometry'
import Chart from "react-google-charts";

const ROOT_URL = 'http://ec2-13-55-123-77.ap-southeast-2.compute.amazonaws.com:3500'
// const ROOT_URL = 'http://localhost:3500'
mapboxgl.accessToken = 'pk.eyJ1IjoibWFudWVsdXpjYXRlZ3VpIiwiYSI6ImNrOWs4OHdtNTAzcnczbm1rbnFqb3JzangifQ.L0zmTAujoe3rq_fG--1LDw';

var map;

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      date: '2020-03-29',
      lookahead: '1',
      geoData: {},
      checkedItemsDate: new Map(),
      checkedItemsLookahead: new Map(),
      states_lines_data: []
      
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleChangeLookahead = this.handleChangeLookahead.bind(this);
    // this.handleSubmit = this.handleSubmit.bind(this);
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

    map.on('click', (e) => {
        var states = map.queryRenderedFeatures(e.point, {
            // layout: "state-fills"
        });
        if (states.length > 0) {
            if (states[0].properties.date !== undefined){
              document.getElementById('pd').innerHTML = '<h3><strong>' + states[0].properties.name + '</strong></h3>'+
              '<p><strong>date: ' + states[0].properties.date + '</strong></p>'+
              '<p><strong>ev: ' + parseFloat(states[0].properties.ev).toFixed(2) + '</strong></p>'+
              '<p><strong>lb: ' + parseFloat(states[0].properties.lb).toFixed(2) + '</strong></p>'+
              '<p><strong>ub: ' + parseFloat(states[0].properties.ub).toFixed(2) + '</strong></p>'+
              '<p><strong>gt: ' + parseFloat(states[0].properties.gt).toFixed(2) + '</strong></p>'+
              '<p><strong>error: ' + parseFloat(states[0].properties.error).toFixed(2) + '</strong></p>'+
              '<p><strong>PE: ' + parseFloat(states[0].properties.PE).toFixed(2) + '</strong></p>'+
              '<p><strong>Adj PE: ' + parseFloat(states[0].properties['Adj PE']).toFixed(2) + '</strong></p>'+
              '<p><strong>APE: ' + parseFloat(states[0].properties.APE).toFixed(2) + '</strong></p>'+
              '<p><strong>Adj APE: ' + parseFloat(states[0].properties['Adj APE']).toFixed(2) + '</strong></p>'+
              '<p><strong>LAPE: ' + parseFloat(states[0].properties.LAPE).toFixed(2) + '</strong></p>'+
              '<p><strong>LAdj APE: ' + states[0].properties['LAdj APE'] + '</strong></p>'+
              '<p><strong>last_obs_date: ' + states[0].properties.last_obs_date + '</strong></p>'+
              '<p><strong>within_PI: ' + states[0].properties.within_PI + '</strong></p>'+
              '<p><strong>outside_by: ' + states[0].properties.outside_by + '</strong></p>'+
              '<p><strong>model_name: ' + states[0].properties.model_name + '</strong></p>'+
              '<p><strong>lookahead: ' + states[0].properties.lookahead + '</strong></p>'
              let dataChart = [
                [{ type: 'date', label: 'Day' },
                { type: 'number', label: 'LB' },
                { type: 'number', label: 'EV' },
                { type: 'number', label: 'UB' }]
              ]
              let temp_data = this.state.states_lines_data.filter(element => element.state_short === states[0].properties.short_name).map(function(element){
                return [new Date(parseFloat(element.date.split('-')[0]),parseFloat(element.date.split('-')[1])-1,parseFloat(element.date.split('-')[2])),parseFloat(element.lb),parseFloat(element.ev),parseFloat(element.ub)]
              })
              for (var date_element in temp_data){
                dataChart.push(temp_data[date_element])
              }
              const element = (
              <div>
              <Chart
                width={'100%'}
                height={'100%'}
                chartType="LineChart"
                loader={<div>Loading Chart</div>}
                data={dataChart}
                options={{
                  title: states[0].properties.name,
                  titleTextStyle: { 
                    fontSize: 24},
                }}
                />
                </div>
                );
              ReactDOM.render(element, document.getElementById('chart'));
            }               
        } 
        });
        this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(this.state.date, true) }));
        this.setState(prevState => ({ checkedItemsLookahead: prevState.checkedItemsLookahead.set(this.state.lookahead, true) }));
        this.create_charts(this.state.date)
  }

  async read_database(date,lookahead){
    let data = await axios.get(ROOT_URL+'/query', {
      headers: {'model_date': date, 'lookahead': lookahead}
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

  async create_charts(date){
    let data = await axios.get(ROOT_URL+'/timeLines', {
      headers: {'model_date': date}
      })
      .then(function async (response) {
        return response 
      })
      .catch(function (error) {
        console.log(error);
    })
    this.setState({states_lines_data: data.data})
  }


  async handleChange(e) {
    const item = e.target.name;
    const isChecked = e.target.checked;
    if (isChecked !== false){
      this.setState({checkedItemsDate: new Map()})
      this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
      this.setState({date: item})
      let geoData = await this.read_database(item,this.state.lookahead)
      this.create_geojson(geoData)
      this.create_charts(item)
    }    
  }
  async handleChangeLookahead(e) {
    const item = e.target.name;
    const isChecked = e.target.checked;
    if (isChecked !== false){
      this.setState({checkedItemsLookahead: new Map()})
      this.setState(prevState => ({ checkedItemsLookahead: prevState.checkedItemsLookahead.set(item, isChecked) }));
      this.setState({lookahead: parseFloat(item)})
      let geoData = await this.read_database(this.state.date,parseFloat(item))
      this.create_geojson(geoData)
      this.create_charts(this.state.date)
    }
  }
  // async handleSubmit(){
  //   // let geoData = await this.read_database(this.state.date,this.state.lookahead)
  //   // this.create_geojson(geoData)
  //   this.create_charts()
  // }

  render() {
    return (
      <div className="App">
        <div className="mapContainer">
        <div>
          <div id='map'></div>
          <div className='map-overlay-select' id='features-selection'><h2>Select Model</h2>
            <div id='selection'>
            {
              checkboxes[0].map(item => (
                <label key={item.key}>
                  {item.name}
                  <Checkbox name={item.name} checked={this.state.checkedItemsDate.get(item.name)} onChange={this.handleChange} />
                  <br/>
                </label>
              ))
            }
            <h2>Select Lookahead</h2>
            {
              checkboxes[1].map(item => (
                <label key={item.key}>
                  {item.name}
                  {item.key === "4"
                  ? <React-Fragment><Checkbox name={item.name} checked={this.state.checkedItemsLookahead.get(item.name)} onChange={this.handleChangeLookahead} /><br/></React-Fragment>
                  : <Checkbox name={item.name} checked={this.state.checkedItemsLookahead.get(item.name)} onChange={this.handleChangeLookahead} />
                  }
                </label>
              ))
            }
            {/* <input style={{width: '50px'}} type="number" value={this.state.lookahead} onChange={this.handleChangeLookahead} onInput={this.handleInput} /> */}
            <br/><br/>
            {/* <button onClick={this.handleSubmit}>
              send
            </button> */}
            </div>
          </div>
          <div className='map-overlay' id='features'><h2>Data for state</h2><div id='pd'><p>Select a state!</p></div></div>
          <div className='map-overlay-chart' id='features-chart'><h2>Timeline</h2>
          <div id="chart">Select a state!</div>
          </div>
        </div>
        </div>
    </div>
    );
  }
}

export default App;
