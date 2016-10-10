// *****************Database Settings*******************************//
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

var dailyAggregation = require('./AggregationDailyFromRawdataCollection.js');

var dailySchema = new Schema({
  nmi : String,
  registerId : String,
  date : String,
  unitOfMeasure : String,
  usageData : Number,
  PeriodOneUsage : Number,
  PeriodTwoUsage : Number,
  PeriodThreeUsage : Number
});
var dailyData = mongoose.model('dailyData', dailySchema);


var rawDataSchema = new Schema({
  nmi : String,
  // organisation : String,
  // serialNumber : String,
  registerId : String,
  readDate : String,
  interval : Number,
  unitOfMeasure : String,
  usageData : [Number]

  // sum : Number
});
var meterData = mongoose.model('meterrawdata', rawDataSchema);

var startTime = Date.now();


// for (var i = 0; i < 10; i++) {
  // date++;
  var daily = new dailyAggregation(dailyData, meterData, startTime);
  var time = daily.storedaily();
// }
