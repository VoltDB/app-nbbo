var symbol = 'HP';
console.log('symbol=' + symbol);

// connect stored procedure calls with chart or table function
function RefreshTable1(){
    con.BeginExecute('nbbo_symbol', 
                     [symbol], 
                     function(response) {
                         DrawTable(response,'#table_nbbo',-1)}
                    );
}

function RefreshTable2(){
    con.BeginExecute('last_ticks_symbol', 
                     [symbol], 
                     function(response) {
                         DrawTable(response,'#table_last_ticks',-1);
                     }
                    );
}

function RefreshChart1(){
    con.BeginExecute('nbbo_symbol',
                     [symbol],
                     function(response) { 
                         DrawTimeLinesChart(response,'#nbbo_chart'); 
                     }
                    );

}

// schedule refresh functions to run periodically
function RefreshData(){
    RefreshTable1();
    RefreshTable2();
    RefreshChart1();
}

// when you click to select a row
$('#symbol').change(function(event) {
    // row was clicked
    symbol = $(this).val();
    console.log('symbol=' + symbol);

    // immediately refresh the drill-down table
    RefreshData();
});

// function DontSubmit(event) {
//     if (event.keyCode == 13) {
// 	return false;
//     }
// }

// custom chart or table functions
var d1 = [];
var d2 = [];

function DrawTimeLinesChart(response, placeholder) {
    var tables = response.results;
    var t0 = tables[0];
    var colcount = t0.schema.length;

    if (d1.length > 10)
	d1.slice(1);
    if (d2.length > 10)
	d2.slice(2);
    
    for(var r=0;r<t0.data.length;r++){ // for each row
        var time = t0.data[r][1]/1000;
        var v1 = t0.data[r][3];
        var v2 = t0.data[r][6];
        d1.push([time,v1]);
        d2.push([time,v2]);
    }
    
    //var d1 = [[0,0], [2,3], [3,2], [5,8]];
    //var d2 = [[0,0], [1,5], [3,8], [5,9]];
    var line1 = { label: "Bid", data: d1 };
    var line2 = { label: "Ask", data: d2 };

    var options = {
        series: {
	    lines: { show: true, fill: false },
	    //bars: { show: true, barWidth : 60*1000, fill: true},
	    points: { show: false }
        },
        xaxis: { mode: "time" },
        legend: { position: 'nw' }
    };

    $.plot($(placeholder), [line1, line2], options);
}

