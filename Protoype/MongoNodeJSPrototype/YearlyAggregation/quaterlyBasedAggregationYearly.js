//set attributes
year = '2015';
registerId = 'E1';
nmi = 'NEM1201002';


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
var quaterlySchema = new Schema({
  nmi : String,
  registerId : String,
  year : String,
  quater : String,
  unitOfMeasure : String,
  usageData : Number
});
var quaterlyData = mongoose.model('quaterlyData', quaterlySchema);



// *****************数据库配置结束*******************************//


var quaterly = quaterlyData.find(
  {
    nmi : nmi,
    year: year,
    registerId : registerId
  },
  getSum
);


function getSum(err, docs) {
    for (var item in docs) {
        sum += docs[item].usageData;
    }

    var yearlySchema = new Schema({
      nmi : String,
      registerId : String,
      year : String,
      unitOfMeasure : String,
      usageData : Number
    });
    var yearlyData = mongoose.model('yearlyData', yearlySchema);

    var yearlyData = new yearlyData({
      nmi : nmi,
      registerId : registerId,
      year : year,
      unitOfMeasure : undefined === docs[0]?'nan':docs[0].unitOfMeasure,
      usageData : sum
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
