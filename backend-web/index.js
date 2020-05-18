const express = require("express");
const app = express();
const bodyParser = require('body-parser');
const { Client } = require('pg')
var cors = require('cors')

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors())

const connectionData = {
    user: 'covidDB',
    host: 'covid-databases.cwtoyn9xsrzw.ap-southeast-2.rds.amazonaws.com',
    database: 'postgres',
    password: 'KiorwWN46Kjr1wC8WiZE',
    port: 5432,
  }

app.get('/query', function (req, res) {
    const client = new Client(connectionData)
    client.connect()
    var query = "SELECT * FROM all_results WHERE last_obs_date = '" + req.headers['model_date'] + "' AND lookahead = '"+req.headers['lookahead']+"'";
    client.query(query)
    .then(response => {
        console.log(response.rows)
        res.send(response.rows);
        client.end()
    })
    .catch(err => {
        client.end()
    })
    // res.send('Server: OK');
});

app.get('/timeLines', function (req, res) {
    const client = new Client(connectionData)
    client.connect()
    var query = "SELECT date,gt,ev,lb,ub,state_short FROM all_results WHERE last_obs_date = '" + req.headers['model_date'] + "'";
    client.query(query)
    .then(response => {
        res.send(response.rows);
        client.end()
    })
    .catch(err => {
        client.end()
    })
    // res.send('Server: OK');
});

app.listen(3500);