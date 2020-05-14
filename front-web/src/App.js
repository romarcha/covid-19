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
import CanvasJSReact from './assets/canvas/canvasjs.react'
import ClipLoader from "react-spinners/ClipLoader";
import Modal from 'react-modal';
import expand_icon from './assets/interface.png'
import minimize_icon from './assets/minimize.png'
import alternate_icon from './assets/directions.png'

const ROOT_URL = 'http://ec2-13-55-123-77.ap-southeast-2.compute.amazonaws.com:3500'
// const ROOT_URL = 'http://localhost:3500'
mapboxgl.accessToken = 'pk.eyJ1Ijoicm1hcjUyNTgiLCJhIjoiY2s5eHl1Y244MGtpNTNrcXdoZ3oyYjVqeCJ9.fkrVlktDGk0CNJieDExeVg';

var map;
var CanvasJSChart = CanvasJSReact.CanvasJSChart;

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      date: '2020-03-29',
      lookahead: '1',
      checkedItemsDate: new Map(),
      checkedItemsLookahead: new Map(),
      states_lines_data: [],
      loading: true,
      showModal: false,
      selected: false,
      active_models: ['2020-03-29'],
      fill: "PE",
      chart: {},
      chart_options: {
        height: window.screen.height*0.35,
        theme: "light1",
        animationEnabled: true,
        exportEnabled: true,
        zoomEnabled: true,
        title: {
          text: "Deaths per Day",
          fontColor: 'black',
          fontWeight: 'bold',
          padding: 10
        },
        subtitles: [{
          text: ""
        }],
        axisX:{
          stripLines:[
            {             
              color:"#d8d8d8",
              label : "Label 1",
              labelFontColor: "#a8a8a8"
            }
          ]
        },
        legend: {
          horizontalAlign: "right",
          verticalAlign: "top"
        },
        scaleBreaks: {
					autoCalculate: true
				},
        data: [
        {
          type: "line",
          lineDashType: "dash",
          color: '#1a1a1a',
          lineThickness: 1,
          showInLegend: true, 
          name: "series1",
          legendText: "OBSERVED",
          dataPoints: [
          ]
        },
        {
          type: "line",
          color: '#006699',
          lineThickness: 3,
          showInLegend: true, 
          name: "series2",
          legendText: "EXPECTED VALUE",
          dataPoints: [
          ]
        },
        {
          type: "rangeSplineArea",
          color: '#0066cc',
          fillOpacity: 0.4,
          lineThickness: 0,
          showInLegend: true, 
          name: "series3",
          legendText: "PREDICTION INTERVAL",
          toolTipContent: "{x}<br><b>UB:</b> {y[1]}<br><b>LB:</b> {y[0]}",
          dataPoints: [
          ]
        },
        {
          type: "line",
          color: '#1a1a1a',
          lineThickness: 1,
          dataPoints: [
          ]
        }
        ]
      },
      customStyles: {
        content : {
          top: '50%',
          left: '50%',
          right: 'auto',
          bottom: 'auto',
          marginRight: '-50%',
          transform: 'translate(-50%, -50%)',
          width: '50%'
        }
      }       
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleChangeLookahead = this.handleChangeLookahead.bind(this);
    this.create_geojson = this.create_geojson.bind(this);
    this.update_map = this.update_map.bind(this);
    this.create_charts = this.create_charts.bind(this);
    this.handleOpenModal = this.handleOpenModal.bind(this);
    this.handleCloseModal = this.handleCloseModal.bind(this);
    this.handleChangefill = this.handleChangefill.bind(this);
  }

  async componentDidMount() {
    map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/rmar5258/cka410a630xu21jpf514iqyfc',
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
        ['get', 'PE'],
        -250,
         'rgba(17,6,201,1)',
         0,
         'white',
         250,
         'rgba(228,9,9,1)'
        ],
    'fill-opacity': [
    'case',
    ['boolean', ['feature-state', 'hover'], false],
    1,
    0.8
    ]
    }
    });
    map.addLayer({
      'id': 'state-fills-undefined',
      'type': 'fill',
      'source': 'states',
      'layout': {},
      'filter': ['==','PE',''],
      'paint': {
        'fill-color': '#767676',
        'fill-opacity': 0.8
      }
    });
    map.moveLayer('state-fills', 'state-label');
    map.moveLayer('state-fills-undefined', 'state-label');
    map.addLayer({
      'id': 'state-borders',
      'type': 'line',
      'source': 'states',
      'layout': {},
      'paint': {
      'line-color': '#B3B6B7',
      'line-width': 1
      }
    });
    map.addLayer({
      'id': 'select-borders',
      'type': 'line',
      'source': 'states',
      'layout': {},
      'paint': {
      'line-color': '#B3B6B7',
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
        });
        if (states.length > 0) {
            if (states[0].properties.date !== undefined){
              document.getElementById('features').style.display = 'block';
              document.getElementById('pd').innerHTML = '<h3><strong>' + states[0].properties.name + '</strong></h3>'+
              '<table><tr><th></th><th></th></tr>'+
              '<tr><td>Date</td><td>' + states[0].properties.date.split('T')[0] + '</td></tr>'+
              '<tr><td>Expected Value</td><td>' + parseFloat(states[0].properties.ev).toFixed(2) + '</td></tr>'+
              '<tr><td>Lower Bound</td><td>' + parseFloat(states[0].properties.lb).toFixed(2) + '</td></tr>'+
              '<tr><td>Upper Bound</td><td>' + parseFloat(states[0].properties.ub).toFixed(2) + '</td></tr>'+
              '<tr><td>Ground Truth</td><td>' + parseFloat(states[0].properties.gt).toFixed(2) + '</td></tr>'+
              '<tr><td>Error</td><td>' + parseFloat(states[0].properties.error).toFixed(2) + '</td></tr>'+
              '<tr><td>Percentage Error</td><td>' + parseFloat(states[0].properties.PE).toFixed(2) + '</td></tr>'+
              '<tr><td>Adjusted PE</td><td>' + parseFloat(states[0].properties['Adj PE']).toFixed(2) + '</td></tr>'+
              '<tr><td>Absolute PE</td><td>' + parseFloat(states[0].properties.APE).toFixed(2) + '</td></tr>'+
              '<tr><td>Adjusted Absolute PE</td><td>' + parseFloat(states[0].properties['Adj APE']).toFixed(2) + '</td></tr>'+
              '<tr><td>Logistic Absolute PE</td><td>' + parseFloat(states[0].properties.LAPE).toFixed(2) + '</td></tr>'+
              '<tr><td>Logistic Adjusted Absolute PE</td><td>' + parseFloat(states[0].properties['LAdj APE']).toFixed(2) + '</td></tr>'+
              '<tr><td>Last Observation Date</td><td>' + states[0].properties.last_obs_date.split('T')[0] + '</td></tr>'+
              '<tr><td>Within Intervale Prediction</td><td>' + states[0].properties.within_PI + '</td></tr>'+
              '<tr><td>Outside by</td><td>' + states[0].properties.outside_by + '</td></tr>'+
              '<tr><td>Model Name</td><td>' + states[0].properties.model_name + '</td></tr>'+
              '<tr><td>Lookahead</td><td>' + states[0].properties.lookahead + '</td></tr>'+
              '</table>'
              let ev = this.state.states_lines_data.filter(element => element.state_short === states[0].properties.short_name).map(function(element){
                return {x: new Date(element.date),y: parseFloat(element.ev)}
              })
              let gt = this.state.states_lines_data.filter(element => element.state_short === states[0].properties.short_name).map(function(element){
                return {x: new Date(element.date),y: parseFloat(element.gt)}
              })
              let gt_previous_last_obs = this.state.states_lines_data.filter(element => (element.state_short === states[0].properties.short_name)&&(new Date(element.date) < new Date(states[0].properties.last_obs_date))).map(function(element){
                  return {x: new Date(element.date),y: parseFloat(element.gt)}
              })
              let range = this.state.states_lines_data.filter(element => element.state_short === states[0].properties.short_name).map(function(element){
                  return {x: new Date(element.date),y: [parseFloat(element.lb),parseFloat(element.ub)]}              
              })
              ev.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
              gt.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
              range.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
              this.state.chart.data[0].set("dataPoints", gt)
              this.state.chart.data[1].set("dataPoints", ev)
              this.state.chart.data[1].set("legendText", states[0].properties.model_name+'-EXPECTED VALUE')
              this.state.chart.data[2].set("dataPoints", range)
              this.state.chart.data[3].set("dataPoints", gt_previous_last_obs)
              this.state.chart.subtitles[0].set("text",states[0].properties.name)
              this.state.chart.set("axisX",{stripLines: [{
                startValue: new Date('2020-01-01'),
                endValue: new Date(states[0].properties.last_obs_date),
                color: '#b3b3b3',
                lineDashType: 'dash',
                opacity: 0.2
              }],
              viewportMinimum: new Date('2020-02-01'),
              viewportMaximum: new Date('2020-07-01'),})
              this.state.chart.set("axisY", {
                viewportMinimum: -5
              })
              map.setFilter('select-borders',['==',['get', 'name'], states[0].properties.name])
              map.setPaintProperty('select-borders', 'line-width', 3);
              // map.setPaintProperty('select-borders', 'line-color', 'black');
            } else {
              document.getElementById('features').style.display = 'none';
              map.setFilter('select-borders',['==',['get', 'name'], false])
            }               
        } else {
          document.getElementById('features').style.display = 'none';
          map.setFilter('select-borders',['==',['get', 'name'], false])
        }
        });
        this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(this.state.date, true) }));
        this.setState(prevState => ({ checkedItemsLookahead: prevState.checkedItemsLookahead.set(this.state.lookahead, true) }));
        this.create_charts(this.state.date)
        Modal.setAppElement('body');
        document.getElementById('features').style.display = 'none';
  }

  handleOpenModal() {
    this.setState({ showModal: true });
  }
  handleCloseModal() {
    this.setState({ showModal: false });
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
      if(element.PE == null){
        element.PE = ''
      }
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
    this.update_map(object)
  }

  update_map(geojson){
    map.getSource('states').setData(geojson);
  }

  async create_charts(date){
    this.setState({loading: true})
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
    this.setState({loading: false})
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
    this.setState({lookahead: e.target.value})
    let geoData = await this.read_database(this.state.date,e.target.value)
    this.create_geojson(geoData)
    this.create_charts(this.state.date)
  }

  handleChangefill(){
    let change = []
    if (this.state.fill === 'PE'){
        change = [
        'interpolate',
        ['linear'],
        ['get', 'outside_by'],
        -26,
         'rgba(17,6,201,1)',
         0,
         'white',
         26,
         'rgba(228,9,9,1)'
        ]
        map.setFilter('state-fills-undefined',['==',['get', 'outside_by'],''])
        this.setState({fill: "Outside"})
        const element = (
            <div>
            <strong>Number of Deaths Outside PI</strong>
            <span></span><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
            <h3 style={{position: 'absolute', left: 0, marginTop: '25px'}}>-26</h3>
            <h3 style={{position: 'absolute', left: 96, marginTop: '25px'}}>0</h3>
            <h3 style={{position: 'absolute', right: 0, marginTop: '25px'}}>26</h3>
            </div>)
        ReactDOM.render(element, document.getElementById('legend'));
    } else {
        change = [
        'interpolate',
        ['linear'],
        ['get', 'PE'],
        -250,
        'rgba(17,6,201,1)',
        0,
        'white',
        250,
        'rgba(228,9,9,1)'
        ]
        map.setFilter('state-fills-undefined',['==',['get', 'PE'],''])
        this.setState({fill: "PE"})
        const element = (
          <div>
            <strong>PE</strong><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
            <span></span>
            <h3 style={{position: 'absolute', left: 0, marginTop: '45px'}}>-250</h3>
            <h3 style={{position: 'absolute', left: 96, marginTop: '45px'}}>0</h3>
            <h3 style={{position: 'absolute', right: 0, marginTop: '45px'}}>250</h3>
          </div>)
        ReactDOM.render(element, document.getElementById('legend'));
    }    
    map.setPaintProperty('state-fills', 'fill-color', change);
  }

  render() {
    return (
      <div className="App">
        <div className="mapContainer">
          <div id='map'></div>
          <div id='legend'>
            <strong>PE</strong><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
            <span></span>
            <h3 style={{position: 'absolute', left: 0, marginTop: '45px'}}>-250</h3>
            <h3 style={{position: 'absolute', left: 96, marginTop: '45px'}}>0</h3>
            <h3 style={{position: 'absolute', right: 0, marginTop: '45px'}}>250</h3>
          </div>
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
            <input type="range" onChange={this.handleChangeLookahead} min="1" max="7" value={this.state.lookahead}></input>
            <br/><label>{this.state.lookahead}</label>
            <br/><br/>
            </div>
          </div>
          <div className='map-overlay' id='features'><h2>Data for State</h2><div id='pd' className="table"><p>Select a state!</p></div></div>          
          <div className='map-overlay-chart'>
          <img src={expand_icon} className="button" onClick={this.handleOpenModal} alt='expand'></img>
          <ClipLoader
            css={'position: absolute;z-index: 1; margin: auto; bottom: 0; left: 0;margin-left: 45%;margin-bottom: 15%'}
            size={50}
            color={"#006699"}
            loading={this.state.loading}
          />
          <CanvasJSChart options = {this.state.chart_options}
            onRef = {ref => this.setState({chart: ref})}
          />
          </div>
          <Modal
          isOpen={this.state.showModal}
          style={this.state.customStyles}
          >
          <ClipLoader
            css={'position: absolute;z-index: 1; margin: auto; bottom: 0; left: 0;margin-left: 45%;margin-bottom: 15%'}
            size={50}
            color={"#006699"}
            loading={this.state.loading}
          />
          <CanvasJSChart options = {this.state.chart_options}
          />
          <img src={minimize_icon} className="button" style={{top: 0, marginTop: '3%'}}  onClick={this.handleCloseModal} alt='minimize'></img>   
          </Modal>
        </div>
    </div>
    );
  }
}

export default App;
