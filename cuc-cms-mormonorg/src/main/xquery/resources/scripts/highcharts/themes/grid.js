/**
 * Grid theme for Highcharts JS
 * @author Torstein Hønsi
 */

Highcharts.theme = {
	colors: ['#058DC7', '#50B432', '#ED561B', '#DDDF00', '#24CBE5', '#64E572', '#FF9655', '#FFF263', '#6AF9C4'],
	chart: {
		backgroundColor: "#f9f9f9",
		borderWidth: 0,
		plotBackgroundColor: 'rgba(255, 255, 255, .9)',
		plotShadow: true,
		plotBorderWidth: 1,
		maxWidth: "98%"
	},
	title: {
		style: {
			color: '#000',
			font: '20px OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;',
			textTransform: 'capitalize'
		}
	},
	subtitle: {
		style: {
			color: '#666666',
			font: 'bold 12px OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;'
		}
	},
	xAxis: {
		gridLineWidth: 1,
		lineColor: '#000',
		tickColor: '#000',
		labels: {
			style: {
				color: '#000',
				font: '11px OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;'
			}
		},
		title: {
			style: {
				color: '#333',
				fontWeight: 'bold',
				fontSize: '12px',
				fontFamily: 'OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;'

			}
		}
	},
	yAxis: {
		minorTickInterval: 'auto',
		lineColor: '#000',
		lineWidth: 1,
		tickWidth: 1,
		tickColor: '#000',
		labels: {
			style: {
				color: '#000',
				font: '11px OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;'
			}
		},
		title: {
			style: {
				color: '#666',
				fontSize: '14px',
				fontFamily: 'OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;'
			}
		}
	},
	legend: {
		itemStyle: {
			font: '9pt OpenSansRegular, Arial, Helvetica, "Lucida Grande", sans-serif;',
			color: 'black'
		},
		itemHoverStyle: {
			color: '#039'
		},
		itemHiddenStyle: {
			color: 'gray'
		}
	},
	labels: {
		style: {
			color: '#99b'
		}
	},

	navigation: {
		buttonOptions: {
			theme: {
				stroke: '#CCCCCC'
			}
		}
	}
};

// Apply the theme
var highchartsOptions = Highcharts.setOptions(Highcharts.theme);
