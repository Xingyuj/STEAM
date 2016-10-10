var fs = require('fs');
module.exports = function (fileName, rawData, starttimeinitial, signal) {
this.parseTime;
this.totalTime;
  file = fileName;
  startTime = starttimeinitial;
closeSignal = signal;
// console.log(closeSignal);
    var fileStr = fs.readFileSync(file, {
    	encoding: 'binary'
    });
    var lines = fileStr.split('\n');
    var count = lines.length;
    var content = new Array();
    for (var i = 0; i < count; i++) {
    	content[i] = new Array();
    	content[i] = lines[i].split(',');
    }

if (closeSignal == 53) {
  var endTime = Date.now();
  var parseTimeCount = endTime - startTime;
  console.log("Parse CSV Time: " + parseTimeCount + "ms");
  this.parseTime = parseTimeCount;
}


this.storeraw = function () {
  var timeProcessed = 0;
  for (var i = 0; i < (count-1)/2 -1; i++) {
    //closure
    // console.log(closeSignal);
    savedata(i)
  }


  function savedata(i) {
    // console.log(closeSignal);

    var data = new rawData({
      nmi : content[i*2+1][1],
      // organisation : content[][],
      // serialNumber : content[][],
      registerId : content[i*2+1][4],
      readDate : content[i*2+2][1],
      interval : content[i*2+1][8],
      unitOfMeasure : content[i*2+1][7],
      usageData : generateUsage(i,content[i*2+1][8]),
    });


      // var startTime = Date.now();

      closuresig (i,data, closeSignal, startTime);


  }
      function closuresig (i,data, closeSignal, startTime) {
        data.save(function (err, data) {
          if (err){
            console.log(err);
          } else {
            // console.log('Saved : ', data );
            timeProcessed = endTime - startTime;
            // console.log("Each Item Process Time: " + (endTime - startTime) + "ms");
            // console.log((count-1)/2);
            if (closeSignal == 53 && i== 33) {
              var endTime = Date.now();
              var total = endTime - startTime;
              console.log("Total Process Time Include Store: " + total + "ms");
              this.totalTime = total;
            }
          }
        });
      }

      function generateUsage (index, interval) {
        var usages = [];
        var count = 24*(60/interval);
        for (var i = 0; i < count; i++) {
          usages.push(content[index*2+2][i+2]);
        }
        return usages;
      };
}

}
