//set attributes
year = '2001';
registerId = 'Q1';
nmi = 'NEM1202020';


sum = 0;
p1sum = 0;
p2sum = 0;
p3sum = 0;
var mongoose = require("mongoose");
var startTime = Date.now();

// *****************数据库配置*******************************//
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



// *****************数据库配置结束*******************************//

var dateMonthFrom;
var dateMonthTo;

dateMonthFrom = year.concat('01010000')
dateMonthTo = year.concat('12310000');

var monthly = dailyData.find(
  {
    nmi : nmi,
    date: {$gte : dateMonthFrom, $lte : dateMonthTo},
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

    var yearlySchema = new Schema({
      nmi : String,
      registerId : String,
      year : String,
      unitOfMeasure : String,
      usageData : Number,
      PeriodOneUsage : Number,
      PeriodTwoUsage : Number,
      PeriodThreeUsage : Number
    });
    var yearlyData = mongoose.model('yearlyData', yearlySchema);

    var yearlyData = new yearlyData({
      nmi : nmi,
      registerId : registerId,
      year : year,
      unitOfMeasure : undefined === docs[0]?'nan':docs[0].unitOfMeasure,
      usageData : sum,
      PeriodOneUsage : p1sum,
      PeriodTwoUsage : p2sum,
      PeriodThreeUsage : p3sum
    });


    yearlyData.save(function (err, data) {
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
