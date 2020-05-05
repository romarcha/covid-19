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
    database: 'covid_database_0',
    password: 'KiorwWN46Kjr1wC8WiZE',
    port: 5432,
  }

app.get('/query', function (req, res) {
    console.log(req.headers['model_date'])
    // console.log(req.headers['lookahead'])

    const client = new Client(connectionData)
    client.connect()
    var query = "SELECT * FROM datasets WHERE date = '" + req.headers['model_date'] + "' AND lookahead = '"+req.headers['lookahead']+"'";
    client.query(query)
    .then(response => {
        res.send(response.rows);
        console.log(response.rows)
        client.end()
    })
    .catch(err => {
        client.end()
    })
    // res.send('Server: OK');
});

app.listen(3500);