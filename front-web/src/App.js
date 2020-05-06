import React, { Component } from "react";
import './App.css';
import axios from 'axios';
import './assets/css/map1.css';
import mapboxgl from 'mapbox-gl';
import data from "./data/out.geojson"
import Checkbox from './components/checkbox'
import checkboxes from './data/checkboxes'

const ROOT_URL = 'http://localhost:3500/query'
mapboxgl.accessToken = 'pk.eyJ1IjoibWFudWVsdXpjYXRlZ3VpIiwiYSI6ImNrOWs4OHdtNTAzcnczbm1rbnFqb3JzangifQ.L0zmTAujoe3rq_fG--1LDw';


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
  }

  async componentDidMount() {
    var map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v11',
      center: [-100.486052, 37.830348],
      zoom: 3
      });
      var hoveredStateId = null;
      console.log(this.props.data)
      
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
          ['get', 'gt'],
          0,
          '#F2F12D',
          10,
          '#EED322',
          20,
          '#E6B71E',
          50,
          '#DA9C20',
          100,
          '#CA8323',
          500,
          '#B86B25',
          1000,
          '#A25626',
          5000,
          '#8B4225',
          100000,
          '#723122'
          ],
      'fill-opacity': [
      'case',
      ['boolean', ['feature-state', 'hover'], false],
      0.5,
      0.3
      ]
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
      
      // When the mouse leaves the state-fill layer, update the feature state of the
      // previously hovered feature.
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
              // layout: "out-73seb6"
          });
          
          if (states.length > 0) {
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
          } else {
              document.getElementById('pd').innerHTML = '<p>Hover over a state!</p>';
          }
          });
    this.read_database()
  }

  async read_database(){
    let data = await axios.get(ROOT_URL, {
      headers: {'model_date': '2020-04-02', 'lookahead': 1}
      })
      .then(function async (response) {
        return response 
      })
      .catch(function (error) {
        console.log(error);
      })
    this.setState({geoData: data})
    console.log(this.state.geoData)
  }

  handleChange(e) {
    const item = e.target.name;
    const isChecked = e.target.checked;
    this.setState({checkedItemsDate: new Map()})
    this.setState(prevState => ({ checkedItemsDate: prevState.checkedItemsDate.set(item, isChecked) }));
    this.setState({date: item})
  }
  handleChangeLookahead(e) {
    // console.log(e.currentTarget.value);
    this.setState({lookahead: e.currentTarget.value })
  }
  handleSubmit(){
    console.log('test')
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
          <div className='map-overlay' id='features'><h2>DATA FOR STATE</h2><div id='pd'><p>Hover over a state!</p></div></div>
        </div>
        </div>
    </div>
    );
  }
}

export default App;
