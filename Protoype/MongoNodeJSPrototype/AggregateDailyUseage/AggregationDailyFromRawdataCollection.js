
module.exports = function (dailyData, meterData, starttime) {
dailydata = dailyData;
startTime = starttime;
signal = 0;
  this.storedaily = function () {
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

      for (var item in docs) {
        var dailyData = new dailydata({
          nmi : docs[item].nmi,
          registerId : docs[item].registerId,
          date : docs[item].readDate,
          unitOfMeasure : undefined === docs[item]?'nan':docs[item].unitOfMeasure,
          usageData : getSum(docs[item].usageData),
          PeriodOneUsage: generateUsageSumFrom0to7(docs[item].interval,docs[item].usageData),
          PeriodTwoUsage: generateUsageSumFrom7to19(docs[item].interval,docs[item].usageData),
          PeriodThreeUsage: generateUsageSumFrom19to24(docs[item].interval,docs[item].usageData),
        });


        dailyData.save(function (err, data) {
          if (err){
            // console.log(err);
          } else {
            var endTime = Date.now();
            signal++;
            timeProcessed = endTime - startTime;
            // console.log("Process Time: " + (endTime - startTime) + "ms");
            // db.close();
            if (signal == 1855) {
              console.log("Total Process Time: " + (endTime - startTime) + "ms");
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
}
