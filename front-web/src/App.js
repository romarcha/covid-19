import React, { Component } from "react";
import './App.css';
import axios from 'axios';
import './assets/css/map1.css';
import mapboxgl from 'mapbox-gl';
import Checkbox from './components/checkbox'
import checkboxes from './data/checkboxes'
import styles from './data/styles'
import Switch from "react-switch";
import geometry from './data/geometry'
import CanvasJSReact from './assets/canvas/canvasjs.react'
import ClipLoader from "react-spinners/ClipLoader";
import Modal from 'react-modal';
import expand_icon from './assets/interface.png'
import minimize_icon from './assets/minimize.png'
import alternate_icon from './assets/directions.png'
import back_icon from './assets/arrowback.png'
import information_icon from './assets/information.png'

const ROOT_URL = 'http://ec2-13-55-123-77.ap-southeast-2.compute.amazonaws.com:3500'
// const ROOT_URL = 'http://localhost:3500'
mapboxgl.accessToken = 'pk.eyJ1Ijoicm1hcjUyNTgiLCJhIjoiY2s5eHl1Y244MGtpNTNrcXdoZ3oyYjVqeCJ9.fkrVlktDGk0CNJieDExeVg';

var map, map2;
var CanvasJSChart = CanvasJSReact.CanvasJSChart;

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      date: ['2020-03-29'],
      lastUpdateDate: '',
      lookahead: '1',
      checkedItemsDate: new Map(),
      checkedItemsLookahead: new Map(),
      statesLinesData: [],
      current_state: {name: '', short_name: '',last_obs_date: '', model_name: ''},
      loading: false,
      showModal: false,
      showInformationModal: false,
      selected: false,
      switchComparation: false,
      switchComparationLine: false,
      comparation: false,
      fill: "PE",
      chart: {},
      chart_options: styles.chart_options,
      customStyles: styles.customStyles,
      customStylesExpand: styles.customStylesExpand      
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleChangeLookahead = this.handleChangeLookahead.bind(this);
    this.create_geojson = this.create_geojson.bind(this);
    this.update_map = this.update_map.bind(this);
    this.update_data_charts = this.update_data_charts.bind(this);
    this.handleOpenModal = this.handleOpenModal.bind(this);
    this.handleCloseModal = this.handleCloseModal.bind(this);
    this.handleOpenInformationModal = this.handleOpenInformationModal.bind(this);
    this.handleCloseInformationModal = this.handleCloseInformationModal.bind(this);
    this.handleChangefill = this.handleChangefill.bind(this);
    this.closeComparation = this.closeComparation.bind(this);
    this.handleChangeSwitch = this.handleChangeSwitch.bind(this);
  }

  async componentDidMount() {
    map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/rmar5258/cka410a630xu21jpf514iqyfc',
      center: [-100.486052, 37.830348],
      zoom: 3
    });
    map2 = new mapboxgl.Map({
      container: 'map2',
      style: 'mapbox://styles/rmar5258/cka410a630xu21jpf514iqyfc',
      center: [-100.486052, 37.830348],
      zoom: 3
      });
    var hoveredStateId = null;

    map.on('load', function() {
    map.addSource('states', {
    'type': 'geojson',
    'data': {"type": "FeatureCollection", "features":[{}]}});

    map.addLayer(styles.layerStateFills);
    map.addLayer(styles.layerStateFillsUndefined);
    map.moveLayer('state-fills', 'state-label');
    map.moveLayer('state-fills-undefined', 'state-label');
    map.addLayer(styles.layerStateBorders);
    map.addLayer(styles.layerSelectBorders);

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
        layers: ['state-fills']
      });
      if (this.state.date.length === 2){
        var states2 = map2.querySourceFeatures('states', {
          filter: ['==', 'name', states[0].properties.name]
        });
      }
      if (states.length > 0) {
        if (states[0].properties.date !== undefined && !this.state.loading){
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
          if(this.state.date.length === 2 && !this.state.switchComparationLine){              
            document.getElementById('features2').style.display = 'block';
            document.getElementById('pd2').innerHTML = '<h3><strong>' + states2[0].properties.name + '</strong></h3>'+
            '<table><tr><th></th><th></th></tr>'+
            '<tr><td>Date</td><td>' + states2[0].properties.date.split('T')[0] + '</td></tr>'+
            '<tr><td>Expected Value</td><td>' + parseFloat(states2[0].properties.ev).toFixed(2) + '</td></tr>'+
            '<tr><td>Lower Bound</td><td>' + parseFloat(states2[0].properties.lb).toFixed(2) + '</td></tr>'+
            '<tr><td>Upper Bound</td><td>' + parseFloat(states2[0].properties.ub).toFixed(2) + '</td></tr>'+
            '<tr><td>Ground Truth</td><td>' + parseFloat(states2[0].properties.gt).toFixed(2) + '</td></tr>'+
            '<tr><td>Error</td><td>' + parseFloat(states2[0].properties.error).toFixed(2) + '</td></tr>'+
            '<tr><td>Percentage Error</td><td>' + parseFloat(states2[0].properties.PE).toFixed(2) + '</td></tr>'+
            '<tr><td>Adjusted PE</td><td>' + parseFloat(states2[0].properties['Adj PE']).toFixed(2) + '</td></tr>'+
            '<tr><td>Absolute PE</td><td>' + parseFloat(states2[0].properties.APE).toFixed(2) + '</td></tr>'+
            '<tr><td>Adjusted Absolute PE</td><td>' + parseFloat(states2[0].properties['Adj APE']).toFixed(2) + '</td></tr>'+
            '<tr><td>Logistic Absolute PE</td><td>' + parseFloat(states2[0].properties.LAPE).toFixed(2) + '</td></tr>'+
            '<tr><td>Logistic Adjusted Absolute PE</td><td>' + parseFloat(states2[0].properties['LAdj APE']).toFixed(2) + '</td></tr>'+
            '<tr><td>Last Observation Date</td><td>' + states2[0].properties.last_obs_date.split('T')[0] + '</td></tr>'+
            '<tr><td>Within Intervale Prediction</td><td>' + states2[0].properties.within_PI + '</td></tr>'+
            '<tr><td>Outside by</td><td>' + states2[0].properties.outside_by + '</td></tr>'+
            '<tr><td>Model Name</td><td>' + states2[0].properties.model_name + '</td></tr>'+
            '<tr><td>Lookahead</td><td>' + states2[0].properties.lookahead + '</td></tr>'+
            '</table>'
          }
          let current_state = {name: states[0].properties.name, short_name: states[0].properties.short_name,model_name: states[0].properties.model_name,last_obs_date: states[0].properties.last_obs_date}
          this.setState({current_state: current_state})
          this.build_charts(states[0].properties.model_name,states[0].properties.name,states[0].properties.short_name,states[0].properties.last_obs_date)
        } else {
          document.getElementById('features').style.display = 'none';
          document.getElementById('features2').style.display = 'none';
          map.setFilter('select-borders',['==',['get', 'name'], false])
        }               
      } else {
        document.getElementById('features').style.display = 'none';
        document.getElementById('features2').style.display = 'none';
        map.setFilter('select-borders',['==',['get', 'name'], false])
      }
    });

    map2.on('load', function() {
      map2.addSource('states', {
      'type': 'geojson',
      'data': {"type": "FeatureCollection", "features":[{}]}});
      
      map2.addLayer(styles.layerStateFillsMap2);
      map2.addLayer(styles.layerStateFillsUndefinedMap2);
      map2.moveLayer('state-fills', 'state-label');
      map2.moveLayer('state-fills-undefined', 'state-label');
      map2.addLayer(styles.layerStateBordersMap2);
      map2.addLayer(styles.layerSelectBordersMap2);

      map2.on('mousemove', 'state-fills', function(e) {
        if (e.features.length > 0) {
          if (hoveredStateId) {
            map2.setFeatureState(
              { source: 'states', id: hoveredStateId },
              { hover: false }
            );
          }
          hoveredStateId = e.features[0].id;
          map2.setFeatureState(
            { source: 'states', id: hoveredStateId },
            { hover: true }
          );
        }
      });
  
      map2.on('mouseleave', 'state-fills', function() {
        if (hoveredStateId) {
          map2.setFeatureState(
            { source: 'states', id: hoveredStateId },
            { hover: false }
          );
        }
        hoveredStateId = null;
      });
    });

    this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(this.state.date[0], true) }));
    this.setState(prevState => ({ checkedItemsLookahead: prevState.checkedItemsLookahead.set(this.state.lookahead, true) }));
    this.update_data_charts(this.state.date[0],0)
    Modal.setAppElement('body');
    document.getElementById('features').style.display = 'none';
    document.getElementById('features2').style.display = 'none';
  }

  handleOpenModal() {
    let chart_options = this.state.chart_options
    chart_options['height'] = window.screen.height*0.75
    this.setState({chart_options: chart_options})
    this.setState({ showModal: true });
  }
  handleCloseModal() {
    let chart_options = this.state.chart_options
    chart_options['height'] = window.screen.height*0.35
    this.setState({chart_options: chart_options})
    this.setState({ showModal: false });
  }
  handleOpenInformationModal() {
    this.setState({ showInformationModal: true });
  }
  handleCloseInformationModal() {
    this.setState({ showInformationModal: false });
  }

  async read_database(date,lookahead){
    let lastUpdateDate = await axios.get(ROOT_URL+'/lastUpdate', {})
      .then(function async (response) {
        return response.data 
      })
      .catch(function (error) {
        console.log(error);
      })
    this.setState({lastUpdateDate: lastUpdateDate})
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

  create_geojson(data,idMap){
    let object = {}
    object['type'] = 'FeatureCollection'
    let features = data.map(function(element, index){
      if(element.PE === null){
        element.PE = ''
      } else if(element.outside_by === null){
        element.outside_by = ''
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
    if(idMap === 1){
      this.update_map(object)
    } else {
      this.update_map2(object)
    }
  }

  update_map(geojson){
    map.getSource('states').setData(geojson);
  }
  update_map2(geojson){
    map2.getSource('states').setData(geojson);
  }

  async update_data_charts(date,idMap){
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
    if (idMap === 0){
      let geoData = await this.read_database(this.state.date[0],this.state.lookahead)
      this.create_geojson(geoData,1)
      this.setState({statesLinesData: [[data.data, date]]})
      this.setState({loading: false})
    } else if (idMap === 1){
      this.setState({statesLinesData: [[data.data,date]]}, function(){
        if (this.state.current_state.name !== ''){
          this.build_charts(this.state.current_state.model_name,this.state.current_state.name,this.state.current_state.short_name,this.state.current_state.last_obs_date)
        }
      })
    } else {
      let new_comparative_data = this.state.statesLinesData
      new_comparative_data.push([data.data,date])
      this.setState({statesLinesData: new_comparative_data}, function(){
        if (this.state.current_state.name !== ''){
          this.build_charts(this.state.current_state.model_name,this.state.current_state.name,this.state.current_state.short_name,this.state.current_state.last_obs_date)
        }
      })
    }
  }

  build_charts(model_name,state_name,state_short_name,last_obs_date){
    if(last_obs_date.length === 10){
      last_obs_date = last_obs_date+'T00:00:00.000Z'
    } 
    let ev = this.state.statesLinesData[0][0].filter(element => element.state_short === state_short_name).map(function(element){
      return {x: new Date(element.date.slice(0,-1)),y: parseFloat(element.ev)}
    })
    let gt = this.state.statesLinesData[0][0].filter(element => element.state_short === state_short_name).map(function(element){
      return {x: new Date(element.date.slice(0,-1)),y: parseFloat(element.gt)}
    })
    let gt_previous_last_obs = this.state.statesLinesData[0][0].filter(element => (element.state_short === state_short_name)&&(new Date(element.date.slice(0,-1)) < new Date(last_obs_date.slice(0,-1)))).map(function(element){
        return {x: new Date(element.date.slice(0,-1)),y: parseFloat(element.gt)}
    })
    let range = this.state.statesLinesData[0][0].filter(element => element.state_short === state_short_name).map(function(element){
        return {x: new Date(element.date.slice(0,-1)),y: [parseFloat(element.lb),parseFloat(element.ub)]}              
    })
    ev.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
    gt.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
    range.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
    this.state.chart.data[0].set("dataPoints", gt)
    this.state.chart.data[1].set("dataPoints", ev)
    this.state.chart.data[1].set("legendText", model_name+'-'+last_obs_date.split('T')[0]+'-EXPECTED VALUE')
    this.state.chart.data[2].set("dataPoints", range)
    this.state.chart.data[3].set("dataPoints", gt_previous_last_obs)

    if(this.state.statesLinesData.length > 1){
      for (let modelId = 1; modelId < this.state.statesLinesData.length; modelId++) {
        let ev2 = this.state.statesLinesData[modelId][0].filter(element => element.state_short === state_short_name).map(function(element){
          return {x: new Date(element.date.slice(0,-1)),y: parseFloat(element.ev)}
        })
        let range2 = this.state.statesLinesData[modelId][0].filter(element => element.state_short === state_short_name).map(function(element){
            return {x: new Date(element.date.slice(0,-1)),y: [parseFloat(element.lb),parseFloat(element.ub)]}              
        })
        ev2.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
        range2.sort((a, b) => new Date(a["x"]) - new Date(b["x"]))
        this.state.chart.data[(modelId+1)*2].set("dataPoints", ev2)
        this.state.chart.data[(modelId+1)*2].set("legendText",'IHME-'+this.state.statesLinesData[modelId][1]+'-EXPECTED VALUE')
        this.state.chart.data[(modelId+1)*2+1].set("dataPoints", range2)
      }
      this.state.chart.data[2].set("showInLegend",false)
      this.state.chart.data[5].set("showInLegend",false)              
    }
    this.state.chart.subtitles[0].set("text",state_name)
    if(this.state.date.length === 1){
      let forecastDate = new Date(last_obs_date.slice(0,-1))
      forecastDate = forecastDate.getTime() + 1000*60*60*24
      forecastDate = new Date(forecastDate)
      let date = new Date(last_obs_date.slice(0,-1))
      date = date.getTime() + 1000*60*60*24*this.state.lookahead
      date = new Date(date)
      this.state.chart.set("axisX",{stripLines: [{
        startValue: new Date('2020-01-01'),
        endValue: forecastDate,
        color: '#b3b3b3',
        lineDashType: 'dash',
        opacity: 0.2
      },{
        value: date,
        opacity: 1,
        label: 'Date',
        labelFontColor: '#b3b3b3',
        color: '#b3b3b3'
      }],
      viewportMinimum: new Date('2020-02-01'),
      viewportMaximum: new Date('2020-07-01'),})
    } else {
      this.state.chart.set("axisX",{
      viewportMinimum: new Date('2020-02-01'),
      viewportMaximum: new Date('2020-07-01'),})
    }
    this.state.chart.set("axisY", {
      viewportMinimum: -5,
      title: 'Deaths per day'
    })
    map.setFilter('select-borders',['==',['get', 'name'], state_name])
    map.setPaintProperty('select-borders', 'line-width', 3);
    map.setPaintProperty('select-borders', 'line-color', '#52c13f');
    map2.setFilter('select-borders',['==',['get', 'name'], state_name])
    map2.setPaintProperty('select-borders', 'line-width', 3);
    map2.setPaintProperty('select-borders', 'line-color', '#52c13f');
    if (this.state.statesLinesData.length === this.state.date.length){
      this.setState({loading: false})
    }    
  }

  renderChart(){
    document.getElementById('chart-comparative').style.display = 'block';
    document.getElementById('legend').style.display = 'block';
  }

  async handleChange(e) {
    const item = e.target.name;
    const isChecked = e.target.checked;
    if (isChecked !== false){
      if (this.state.switchComparation){
        map.setCenter([-70.486052, 37.830348]);
        this.setState({comparation: true},this.renderChart)
        let date = [this.state.date[0],item]
        this.setState({date: date})
        this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
        let new_date = [this.state.date[0],item]
        this.setState({date: new_date})
        let geoDataComparative = await this.read_database(item,this.state.lookahead)
        this.create_geojson(geoDataComparative,2)
        let geoData = await this.read_database(this.state.date[0],this.state.lookahead)
        this.create_geojson(geoData,1)
        this.update_data_charts(item,2)
      } else {
        if(this.state.switchComparationLine && this.state.date.length < 4){
          let count_models = this.state.date.length + 1;
          let date = this.state.date
          date.push(item)
          this.setState({date: date})
          this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
          this.update_data_charts(item,count_models)          
        } else if (!this.state.switchComparationLine) {
          let current_state = this.state.current_state
          current_state['last_obs_date'] = item
          this.setState({current_state: current_state})
          let date = [item]
          this.setState({date: date})
          this.setState({checkedItemsDate: new Map()})
          this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
          let geoData = await this.read_database(item,this.state.lookahead)
          this.create_geojson(geoData,1)
          this.update_data_charts(item,1)
        }
      }
    } else {
      if (this.state.switchComparationLine && this.state.date.length > 1 && !this.state.loading && this.state.date.length === this.state.statesLinesData.length && this.state.date[0] !== item){
        let index = this.state.date.indexOf(item)
        let date = this.state.date
        date.splice(index,1)
        this.setState({date: date})        
        this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
        let statesLinesData = this.state.statesLinesData.filter(element => element[1] !== item)
        for (let j=0; j<10; j++){
          this.state.chart.data[j].set("dataPoints", [])
        }  
        this.setState({statesLinesData: statesLinesData}, function(){
          if (this.state.current_state.name !== ''){
            this.build_charts(this.state.current_state.model_name,this.state.current_state.name,this.state.current_state.short_name,this.state.current_state.last_obs_date)
          }
        })
      }
    }
    document.getElementById('features').style.display = 'none';
    document.getElementById('features2').style.display = 'none';   
  }

  async handleChangeLookahead(e) {
    this.setState({lookahead: e.target.value})
    let geoData = await this.read_database(this.state.date[0],e.target.value)
    this.create_geojson(geoData,1)
    this.update_data_charts(this.state.date[0],1)
    if(this.state.date.length === 2 && this.state.switchComparation){
      geoData = await this.read_database(this.state.date[1],e.target.value)
      this.create_geojson(geoData,2)    
      this.update_data_charts(this.state.date[1],2)
    }
    document.getElementById('features').style.display = 'none';
    document.getElementById('features2').style.display = 'none';    
  }

  handleChangeSwitch(checked) {
    this.setState({ switchComparationLine: checked });
    for (let j=4; j<10; j++){
      this.state.chart.data[j].set("dataPoints", [])
    }    
  }

  handleChangefill(){
    let change = []
    if (this.state.fill === 'PE'){
        change = styles.changeFillPE 
        map.setFilter('state-fills-undefined',['==',['get', 'outside_by'],''])
        map2.setFilter('state-fills-undefined',['==',['get', 'outside_by'],''])
        this.setState({fill: "Outside"})
    } else {
        change = styles.changeFillOutside 
        map.setFilter('state-fills-undefined',['==',['get', 'PE'],''])
        map2.setFilter('state-fills-undefined',['==',['get', 'PE'],''])
        this.setState({fill: "PE"})
    }    
    map.setPaintProperty('state-fills', 'fill-color', change);
    map2.setPaintProperty('state-fills', 'fill-color', change);
  }

  closeComparation(){
    window.location.reload()
  }

  render() {
    return (
      <div className="App">
        {!this.state.comparation
          ? 
          <div className="mapContainer">
            <div id='map' style={{width: '100%'}}></div>
            <div id='map2'></div>
            <div className="model_title"><strong>{'IHME-'+this.state.date[0]}</strong></div>
            <div className='map-overlay-comparative2' id='features2'><h2>Data for State</h2><div id='pd2' className="table"><p>Select a state!</p></div></div>
            {this.state.fill === 'PE'
              ? 
                <div id='legend'>
                  <strong>PE</strong><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
                  <span></span>
                  <h3 style={{position: 'absolute', left: 0, marginTop: '45px'}}>-250</h3>
                  <h3 style={{position: 'absolute', left: 96, marginTop: '45px'}}>0</h3>
                  <h3 style={{position: 'absolute', right: 0, marginTop: '45px'}}>250</h3>
                </div>
              : <div id='legend'>
                  <strong>Number of Deaths Outside PI</strong>
                  <span></span><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
                  <h3 style={{position: 'absolute', left: 0, marginTop: '25px'}}>-26</h3>
                  <h3 style={{position: 'absolute', left: 96, marginTop: '25px'}}>0</h3>
                  <h3 style={{position: 'absolute', right: 0, marginTop: '25px'}}>26</h3>
                </div>
            }
            <div className='map-overlay-chart-comparative' id='chart-comparative'></div>
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
                <br/>
                <label>
                  <span>Compare Models</span><br/>
                  <Switch onChange={this.handleChangeSwitch} width={40} height={20} onColor="#1106c9" checked={this.state.switchComparationLine} />
                </label>
                <h2>Select Lookahead</h2>
                <input type="range" onChange={this.handleChangeLookahead} min="1" max="7" value={this.state.lookahead}></input>
                <br/><label>{this.state.lookahead}</label>
                <br/><br/>
              </div>
            </div>
            <div className='map-overlay' id='features'>
              <h2>Data for State <img src={information_icon} className="information" onClick={this.handleOpenInformationModal} alt='information'></img></h2>
              <div id='pd' className="table"><p>Select a state!</p></div>
            </div>          
            <div className='map-overlay-chart'>
              <img src={expand_icon} className="button" onClick={this.handleOpenModal} alt='expand'></img>
              <ClipLoader
                css={'position: absolute;z-index: 1; width: 50px; left: 50%; margin-left: -25px; top: 50%; margin-top: -25px'}
                size={50}
                color={"#006699"}
                loading={this.state.loading}
              />
              <CanvasJSChart options = {this.state.chart_options}
                onRef = {ref => this.setState({chart: ref})}
              />
              <small className="captionChart">* The continuous line depicts the expected value, while the shaded area represents the 95% prediction intervals provided by the model.</small>
            </div>
            <Modal
              isOpen={this.state.showModal}
              style={this.state.customStyles}
              >
              <ClipLoader
                css={'position: absolute;z-index: 1; width: 50px; left: 50%; margin-left: -25px; top: 50%; margin-top: -25px'}
                size={50}
                color={"#006699"}
                loading={this.state.loading}
              />
              <CanvasJSChart options = {this.state.chart_options}
              />
              <img src={minimize_icon} className="button" style={{top: 0, marginTop: '3%'}}  onClick={this.handleCloseModal} alt='minimize'></img>   
            </Modal>
            <Modal
              isOpen={this.state.showInformationModal}
              style={styles.customStylesExpand}
              >
              <div className="showInformation">
                <h2>Source</h2>
                <strong>Paper: </strong><a href="https://arxiv.org/abs/2004.04734" >https://arxiv.org/abs/2004.04734</a><br/><br/>
                <strong>{'Last Update: '+this.state.lastUpdateDate}</strong><br/>
                <button className="infoButton" onClick={this.handleCloseInformationModal}>Close</button>  
              </div>    
            </Modal>
          </div>
          //Dual map rendering
          : 
          <div className="mapContainer">
            <div id='map' style={{width: '50%'}}>
              <img src={back_icon} className="back" onClick={this.closeComparation} alt='minimize'></img>
            </div> 
            <div id='map2' style={{width: '50%', zIndex: 0,left: '50%'}}></div>               
            {this.state.fill === 'PE'
              ? 
              <div id='legend' className='legend-comparative'>
                <strong>PE</strong><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
                <span></span>
                <h3 style={{position: 'absolute', left: 0, marginTop: '45px'}}>-250</h3>
                <h3 style={{position: 'absolute', left: 96, marginTop: '45px'}}>0</h3>
                <h3 style={{position: 'absolute', right: 0, marginTop: '45px'}}>250</h3>
              </div>
              : 
              <div id='legend' className='legend-comparative'>
                <strong>Number of Deaths Outside PI</strong>
                <span></span><img src={alternate_icon} className="arrow" onClick={this.handleChangefill} alt='alternate'></img>
                <h3 style={{position: 'absolute', left: 0, marginTop: '25px'}}>-26</h3>
                <h3 style={{position: 'absolute', left: 96, marginTop: '25px'}}>0</h3>
                <h3 style={{position: 'absolute', right: 0, marginTop: '25px'}}>26</h3>
              </div>
            }
            <div className='map-overlay-comparative' id='features' style={{display: 'none'}}><h2>Data for State</h2><div id='pd' className="table"><p>Select a state!</p></div></div>
            <div className='map-overlay-comparative2' id='features2' style={{display: 'none'}}><h2>Data for State</h2><div id='pd2' className="table"><p>Select a state!</p></div></div>          
            <div className='map-overlay-chart-comparative' id='chart-comparative'>
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
              <CanvasJSChart options = {this.state.chart_options}/>
              <img src={minimize_icon} className="button" style={{top: 0, marginTop: '3%'}}  onClick={this.handleCloseModal} alt='minimize'></img>   
            </Modal>
          </div>
        }
      </div>
    );
  }
}

export default App;
