import React from 'react';
import '../../assets/css/map1.css';
import mapboxgl from 'mapbox-gl';
import data from "../../data/out.geojson"

mapboxgl.accessToken = 'pk.eyJ1IjoibWFudWVsdXpjYXRlZ3VpIiwiYSI6ImNrOWs4OHdtNTAzcnczbm1rbnFqb3JzangifQ.L0zmTAujoe3rq_fG--1LDw';

class Map1 extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
    };
  }
  
  componentDidMount() {
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
    'data': data
    // 'https://docs.mapbox.com/mapbox-gl-js/assets/us_states.geojson'
    });


    // var sourceObject = map.getSource('states');
    // console.log(sourceObject)
    
    // The feature-state dependent fill-opacity expression will render the hover effect
    // when a feature's hover state is set to true.
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
    
    // map.addLayer({
    // 'id': 'state-borders',
    // 'type': 'line',
    // 'source': 'states',
    // 'layout': {},
    // 'paint': {
    // 'line-color': '#627BC1',
    // 'line-width': 2
    // }
    // });

    // map.moveLayer('state-fills', 'state-label');
    
    // When the user moves their mouse over the state-fill layer, we'll update the
    // feature state for the feature under the mouse.
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

    // const map = new mapboxgl.Map({
    // container: 'map',
    // style: 'mapbox://styles/manueluzcategui/ck9kf21ck1pnc1ildnu502bbx',
    // center: [this.state.lng, this.state.lat],
    // zoom: this.state.zoom
    // });
  
    // map.on('move', () => {
    // this.setState({
    // lng: map.getCenter().lng.toFixed(4),
    // lat: map.getCenter().lat.toFixed(4),
    // zoom: map.getZoom().toFixed(2)
    // });
    // });

    map.on('mousemove', (e) => {
        var states = map.queryRenderedFeatures(e.point, {
            // layout: "out-73seb6"
        });

        // map.getSource('states').setData({
        //   "type": "FeatureCollection",
        //   "features": [{
        //       "type": "Feature",
        //       "properties": { "name": "Alabama" },
        //       "geometry": {
        //           "type": "Point",
        //           "coordinates": [ 0, 0 ]
        //       }
        //   }]
        // });
        
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
  }
  
  render() {
    return (
      <div>
      <div id='map'></div>
      <div className='map-overlay' id='features'><h2>DATA FOR STATE</h2><div id='pd'><p>Hover over a state!</p></div></div>
      </div>
    )
  }
}

export default Map1;
