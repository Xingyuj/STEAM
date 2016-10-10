// *****************Database Settings*******************************//
this.totalTime = 0;
this.parseTime;
exports.commence = function () {
  var mongoose = require("mongoose");
  mongoose.connect('mongodb://localhost/test');
  var db = mongoose.connection;
  db.on('error', function callback () {
    console.log("Connection error");
  });

  db.once('open', function callback () {
    console.log("Mongo working!");
  });
  var Schema = mongoose.Schema;
  // ******************************************************************//

  var rawDataInput = require('./InputCSVNew.js');

  var rawDataSchema = new Schema({
    nmi : String,
    registerId : String,
    readDate : String,
    interval : String,
    unitOfMeasure : String,
    usageData : [Number]
  });
  var rawData = mongoose.model('meterrawdata', rawDataSchema);
  var startTime = Date.now();
  for (var i = 1; i < 10; i++) {
    fileName = "/Users/xingyuji/meterdata/GeneratedNEM12/NEM12#00000000000000"+i+"#CNRGYMDP#NEMMCO.csv";

    closure(fileName, rawData, startTime, i);
  }
  for (var i = 10; i < 54; i++) {
    fileName = "/Users/xingyuji/meterdata/GeneratedNEM12/NEM12#0000000000000"+i+"#CNRGYMDP#NEMMCO.csv";
    closure1(fileName, rawData, startTime, i);
  }


  function closure (fileName, rawData, startTime, i) {
    var rawDataI = new rawDataInput(fileName, rawData, startTime, i);
    rawDataI.storeraw();
  }
  function closure1 (fileName, rawData, startTime, i) {
    var rawDataI = new rawDataInput(fileName, rawData, startTime, i);
    var time = rawDataI.storeraw();
  }

}
