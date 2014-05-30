var symbol = 'HP';
console.log('symbol=' + symbol);

// connect stored procedure calls with chart or table function
function RefreshTable1(){
    con.BeginExecute('nbbo_symbol', 
                     [symbol], 
                     function(response) {
                         DrawNBBOTable(response,'#table_nbbo')}
                    );
}

function RefreshTable2(){
    con.BeginExecute('last_bids_symbol', 
                     [symbol], 
                     function(response) {
                         DrawNBBOTable(response,'#table_last_bids');
                     }
                    );
}

function RefreshTable3(){
    con.BeginExecute('last_asks_symbol', 
                     [symbol], 
                     function(response) {
                         DrawNBBOTable(response,'#table_last_asks');
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
    RefreshTable3();
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
var bids = [];
var asks = [];

function DrawTimeLinesChart(response, placeholder) {
    var tables = response.results;
    var t0 = tables[0];
    var colcount = t0.schema.length;

    if (bids.length > 10)
	bids.slice(1);
    if (asks.length > 10)
	asks.slice(2);
    
    for(var r=0;r<t0.data.length;r++){ // for each row
        var time = t0.data[r][1]/1000;
        var bid = t0.data[r][3]/10000;
        var ask = t0.data[r][6]/10000;
        bids.push([time,bid]);
        asks.push([time,ask]);
    }
    
    //var bids = [[0,0], [2,3], [3,2], [5,8]];
    //var asks = [[0,0], [1,5], [3,8], [5,9]];
    var askline = { label: "Ask", data: asks };
    var bidline = { label: "Bid", data: bids };

    var options = {
        series: {
	    lines: { show: true, fill: false },
	    //bars: { show: true, barWidth : 60*1000, fill: true},
	    points: { show: false }
        },
        xaxis: { mode: "time" },
        yaxis: { position: "right" },
        legend: { position: 'nw' }
    };

    $.plot($(placeholder), [askline, bidline], options);
}

function DrawNBBOTable(response, tableName) {
    try {
        var tables = response.results;
        var hmt = tables[0];
        var colcount = hmt.schema.length;
        
        // the first time, initialize the table head
        if ($(tableName+' thead tr').length == 0) {
            var theadhtml = '<tr>';
            for (var i=0; i<colcount; i++) {
                theadhtml += '<th>' + hmt.schema[i].name + '</th>';
            }
            $(tableName).append('<thead></thead>');
            $(tableName).append('<tbody></tbody>');
            $(tableName).children('thead').html(theadhtml);
        }
        
        var tbodyhtml;
        for(var r=0;r<hmt.data.length;r++){ // for each row
            tbodyhtml += '<tr>';
            for (var c=0;c<colcount;c++) { // for each column
                var f = hmt.data[r][c];

                // if type is DECIMAL
                if (hmt.schema[c].type == 22 || hmt.schema[c].type == 8) {
                    f = formatDecimal(f);
                }
                // custom for NBBO
                if (hmt.schema[c].name == 'BID' || hmt.schema[c].name == 'ASK') {
                    f = formatDecimal(f/10000);
                }

                if (hmt.schema[c].type == 11) {
                    f = formatDateAsTime(f);
                }
                tbodyhtml += '<td>' + f + '</td>';
            }
            tbodyhtml += '</tr>';
        }
        $(tableName).children('tbody').html(tbodyhtml);

    } catch(x) {}
}
