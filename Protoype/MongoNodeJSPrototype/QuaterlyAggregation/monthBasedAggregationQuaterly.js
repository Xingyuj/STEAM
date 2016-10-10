//set attributes
year = '2001';
quater = 'third';
registerId = 'Q1';
nmi = 'NEM1202020';


sum = 0;
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



// *****************数据库配置结束*******************************//

var dateMonthFrom;
var dateMonthTo;

switch(quater){
  case 'first':
  dateMonthFrom = year.concat('01');
  dateMonthTo = year.concat('03');
  break;
  case 'second':
  dateMonthFrom = year.concat('04');
  dateMonthTo = year.concat('06');
  break;
  case 'third':
  dateMonthFrom = year.concat('07');
  dateMonthTo = year.concat('09');
  break;
  case 'fourth':
  dateMonthFrom = year.concat('10');
  dateMonthTo = year.concat('12');
  break;
}

var monthly = monthelyData.find(
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
    }

    var quaterlySchema = new Schema({
      nmi : String,
      registerId : String,
      year : String,
      quater : String,
      unitOfMeasure : String,
      usageData : Number,
      PeriodOneUsage : Number,
      PeriodTwoUsage : Number,
      PeriodThreeUsage : Number
    });
    var quaterlyData = mongoose.model('quaterlyData', quaterlySchema);

    var quaterlyData = new quaterlyData({
      nmi : nmi,
      registerId : registerId,
      year : year,
      quater : quater,
      unitOfMeasure : undefined === docs[0]?'nan':docs[0].unitOfMeasure,
      usageData : sum
    });


    quaterlyData.save(function (err, data) {
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
