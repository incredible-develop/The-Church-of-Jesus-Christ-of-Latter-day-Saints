
var metricData = [];
var chart = null;
var selectedMetricIndexes = [0];
var selectedDays = 30;

$(window).resize(function(){
	if(chart != null){
		chart.setSize(850,400);
	}
});

function loadChartDays(days){
	selectedDays = days;
	chart.setTitle({text:"Omniture Stats " + days + " Days"},{});
	refreshChartState();
}	

function createChart(titleTxt,subtitleTxt,yAxisTxt){
	//the metricVar+metricId variables are declared in loadPage.xqy inside a script tag	
	metricData = OMNITUREDATA.metrics;
	var seriesData = OMNITUREDATA.metrics;
	$("#chart-container").hide();
	$("#chart-container").fadeIn("slow");
	    chart = new Highcharts.Chart({
	    	animation : false,
	        chart: {
	            renderTo: 'chart-container'
	        },
	        title: {
	            text: titleTxt
	        },
	        subtitle: {
	            text: subtitleTxt
	        },
	        legend : {
		        itemStyle: {
		        	fontSize:"14px",
		        	padding : "10px"
		        },
		        itemHiddenStyle: {
		        	color : "#555"
		        }
	        },
	        xAxis: {
	            type: 'datetime',
	        },
	        yAxis: {
	            title: {
	                text: yAxisTxt
	            },
	            min: 0
	        },
	        tooltip: {
	            formatter: function() {
	                    return '<b>'+ this.series.name +'</b><br/>'+
	                    Highcharts.dateFormat('%e. %b', this.x) +': '+ this.y + yAxisTxt;
	            }
	        },
        series: seriesData
    });
	    
    $(".highcharts-legend").find("tspan").click(function(){
		var index = $(".highcharts-legend").find("tspan").index(this);		
		if(!chart.series[index].visible && selectedMetricIndexes.indexOf(index)==-1){
			selectedMetricIndexes.push(index);
		}
		else{//if in selected and hidden remove from selected
			var selectedIndex = selectedMetricIndexes.indexOf(index);
			if(selectedIndex != -1){
				selectedMetricIndexes.splice(selectedIndex,1);
			}
		}
		setTimeout(function(){$(window).resize()},20);
	});
	refreshChartState();
}

function refreshChartState(){
	for(var i=0; i<chart.series.length; i++){
		var data = metricData[i].data;
		if(selectedMetricIndexes.indexOf(i)==-1){
			chart.series[i].hide();
		}
		else{
			chart.series[i].show();
		}
		var slicedData = sliceData(data);
		chart.series[i].setData(slicedData,true);/*data.slice(data.length-(selectedDays),data.length),false);*/
		//chart.redraw();
	}
	setTimeout(function(){$(window).resize()},20);
}

function sliceData(data){
	var today = new Date();
	var prevDate = new Date();
	prevDate.setDate(today.getDate() - selectedDays);
	var prevUTC = Date.UTC(prevDate.getFullYear(), prevDate.getMonth(), prevDate.getDate());
	return data.filter(function(dataItem){
		return dataItem[0] >= prevUTC
	});
}