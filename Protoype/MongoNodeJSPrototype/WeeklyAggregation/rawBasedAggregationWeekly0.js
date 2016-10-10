//set attributes
var fromdate = '200107140000';
var todate = '200107200000';
registerId = 'Q1';
nmi = 'NEM1202020';


sum = 0;
p1sum = 0;
p2sum = 0;
p3sum = 0;
var mongoose = require("mongoose");
var startTime = Date.now();

// *****************Database Settings*******************************//
mongoose.connect('mongodb://localhost/test');
var db = mongoose.connection;
db.on('error', function callback () {
  console.log("Connection error");
});

db.once('open', function callback () {
  console.log("Mongo working!");
});

var Schema = mongoose.Schema;
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

// *****************Database Settings End*******************************//


meterData.find(
  {
    nmi : nmi,
    readDate:{$gte : fromdate, $lte : todate},
    registerId : registerId
  },
  getSum
);


function getSum(err, docs) {
    for (var item in docs) {
        sum += generateUsage(docs[item].usageData);
        p1sum += generateUsageSumFrom0to7(docs[item].interval, docs[item].usageData);
        p2sum += generateUsageSumFrom7to19(docs[item].interval, docs[item].usageData);
        p3sum += generateUsageSumFrom19to24(docs[item].interval, docs[item].usageData);
    }


    var weeklySchema = new Schema({
      nmi : String,
      registerId : String,
      fromdate : String,
      todate : String,
      unitOfMeasure : String,
      usageData : Number,
      PeriodOneUsage : Number,
      PeriodTwoUsage : Number,
      PeriodThreeUsage : Number
    });

    var weeklyData = mongoose.model('weeklyData', weeklySchema);

    var weeklyData = new weeklyData({
      nmi : nmi,
      registerId : registerId,
      fromdate : fromdate,
      todate : todate,
      unitOfMeasure : undefined === docs[0]?'nan':docs[0].unitOfMeasure,
      usageData : sum,
      PeriodOneUsage : p1sum,
      PeriodTwoUsage : p2sum,
      PeriodThreeUsage : p3sum
    });


    weeklyData.save(function (err, data) {
      if (err){
        console.log(err);
      } else {
        var endTime = Date.now();
        timeProcessed = endTime - startTime;
        console.log("Process Time: " + (endTime - startTime) + "ms");
        db.close();
      }
    });

}


function generateUsage(doc) {
  sum = 0;
  for (var item = 0; item < doc.length; item++) {
    sum += parseFloat(doc[item]);
  }
  return sum;
}

function generateUsageSumFrom0to7 (intervals,doc) {
  var usages = 0;
  var count = 24*(60/intervals);
  for (var j = 0; j < count*(7/24); j++) {
    usages += parseFloat(doc[j]);
  }
  return usages;
};
function generateUsageSumFrom7to19 (intervals,doc) {
  var usages = 0;
  var count = 24*(60/intervals);
  for (var j = count*(7/24); j < count*(19/24); j++) {
    usages += parseFloat(doc[j]);
  }
  return usages;
};
function generateUsageSumFrom19to24 (intervals,doc) {
  var usages = 0;
  var count = 24*(60/intervals);
  for (var j = count*(19/24); j < count; j++) {
    usages += parseFloat(doc[j]);
  }
  return usages;
};
