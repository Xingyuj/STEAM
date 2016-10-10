// *****************Database Settings*******************************//
var mongoose = require("mongoose");
mongoose.connect('mongodb://localhost/test');



var Schema = mongoose.Schema;
// ****************************Schema**************************************//

var dailySchema = new Schema({
  nmi : String,
  registerId : String,
  date : String,
  unitOfMeasure : String,
  usageData : Number
});
dailyData = mongoose.model('dailyData', dailySchema);


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
meterData = mongoose.model('meterrawdata', rawDataSchema);

// ******************************************************************//


for (var i = 0; i < 5; i++) {
  var db = mongoose.connection;
  db.on('error', function callback () {
    console.log("Connection error");
  });

  db.once('open', function callback () {
    console.log("Mongo working!");
  });


    var startTime = Date.now();
    this.totalTime = 0;
    signal = 0;
    sum = 0;
    startTimeForQuery = Date.now();

    meterData.find(
      {
        // nmi : nmi,
        // readDate: dailydate,
        // registerId : registerId
      },
      // (function (dailydate) {
      //     return storeDailyData;
      // })(dailydate)
      storeDailyData
    );
}


  function storeDailyData(err, docs) {
      var endTimeForQuery = Date.now();
          console.log("Query Time: " + (endTimeForQuery - startTimeForQuery) + "ms");
          this.aggreTime = endTimeForQuery - startTimeForQuery;


      for (var item in docs) {
        var dailyData1 = new dailyData({
          nmi : docs[item].nmi,
          registerId : docs[item].registerId,
          date : docs[item].readDate,
          unitOfMeasure : undefined === docs[item]?'nan':docs[item].unitOfMeasure,
          usageData : getSum(docs[item].usageData)
        });


        dailyData1.save(function (err, data) {
          if (err){
            // console.log(err);
          } else {
            signal++;
            timeProcessed = endTime - startTime;
            // console.log("Process Time: " + (endTime - startTime) + "ms");
            // db.close();
            if (signal == 1855) {
              var endTime = Date.now();
              console.log("Total Process Time: " + (endTime - startTime) + "ms");
              this.totalTime = endTime - startTime;
              db.close();
            }
          }
        });
      }
  }

  function getSum(doc) {
    sum = 0;
    for (var item = 0; item < doc.length; item++) {
      sum += parseFloat(doc[item]);
    }
    return sum;
  }

  function generateUsageSumFrom0to7 (index, intervals) {
    var usages = 0;
    var count = 24*(60/intervals);
    for (var j = 0; j < count*(7/24); j++) {
      usages += parseFloat(content[index*2+2][j+2]);
    }
    return usages;
  };
  function generateUsageSumFrom7to19 (index, intervals) {
    var usages = 0;
    var count = 24*(60/intervals);
    for (var j = count*(7/24); j < count*(19/24); j++) {
      usages += parseFloat(content[index*2+2][j+2]);
    }
    return usages;
  };
  function generateUsageSumFrom19to24 (index, intervals) {
    var usages = 0;
    var count = 24*(60/intervals);
    for (var j = count*(19/24); j < count; j++) {
      usages += parseFloat(content[index*2+2][j+2]);
    }
    return usages;
  };
