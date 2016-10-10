//set attributes
dateMonth = '200107'
registerId = 'Q1';
nmi = 'NEM1202020';


sum = 0;
p1sum = 0;
p2sum = 0;
p3sum = 0;
var mongoose = require("mongoose");

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
var dailySchema = new Schema({
  nmi : String,
  // organisation : String,
  // serialNumber : String,
  registerId : String,
  date : String,
  interval : Number,
  unitOfMeasure : String,
  usageData : Number,
  PeriodOneUsage : Number,
  PeriodTwoUsage : Number,
  PeriodThreeUsage : Number
});



var dailyData = mongoose.model('dailyData', dailySchema);

// *****************Database Settings End*******************************//

var datefrom = dateMonth.concat('010000');
var dateto = dateMonth.concat('310000');
var startTime = Date.now();

var daily = dailyData.find(
  {
    nmi : nmi,
    date:{$gte : datefrom, $lte : dateto},
    registerId : registerId
  },
  getSum
);


function getSum(err, docs) {
    for (var item in docs) {
        sum += docs[item].usageData;
        p1sum += docs[item].PeriodOneUsage;
        p2sum += docs[item].PeriodTwoUsage;
        p3sum += docs[item].PeriodThreeUsage;
    }


    var monthlySchema = new Schema({
      nmi : String,
      registerId : String,
      date : String,
      unitOfMeasure : String,
      usageData : Number,
      PeriodOneUsage : Number,
      PeriodTwoUsage : Number,
      PeriodThreeUsage : Number
    });
    var monthelyData = mongoose.model('monthlyData', monthlySchema);

    var monthelyData = new monthelyData({
      nmi : nmi,
      registerId : registerId,
      date : dateMonth,
      unitOfMeasure : undefined === docs[0]?'nan':docs[0].unitOfMeasure,
      usageData : sum,
      PeriodOneUsage : p1sum,
      PeriodTwoUsage : p2sum,
      PeriodThreeUsage : p3sum
    });
    var endTime = Date.now();

    timeProcessed = endTime - startTime;
    console.log("Aggregate Time: " + (endTime - startTime) + "ms");

    monthelyData.save(function (err, data) {
      if (err){
        console.log(err);
      } else {
        var endTime = Date.now();

        timeProcessed = endTime - startTime;
        console.log("Process Time Include Storing: " + (endTime - startTime) + "ms");
        db.close();
      }
    });

}
