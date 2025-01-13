/*
	Node Json Templates
	20130710
*/

var nodes = {
	"published" : {
		"title": "Published Overview",
		"count": 3029,
		"data": {
			"values": [1,2,3,4,5],
			"startDate": "1 Jan 2013"
		}
	},

	"translation" : {
		"title": "Translation",
		"sent": {
			"count":357,
			"tgp": 889.66,
			"wordcount": 254443
		},
		"returned": {
			"count":357,
			"tgp": 889.66,
			"wordcount": 254443
		}
	},

	"ipeval" : {
		"title": "Cor IP / Cor Eval",
		"sent": 486,
		"approved":{
			"approved":386,
			"percent": 60,
			"time": "6hr"
		},
		"declined":{
			"declined":110,
			"percent": 60
		}
	},

	"top" : {
		"title": "Top 5 Sites",
		"subtitle": "Ranked by Content Published",
		"sites": [
			{
				"title": "Lds.org",
				"count": 603
			}
		]
	},

	"stories" : [
		{
			"site": "Mormon.org",
			"description": "President Eyering talks about BYU students about their future",
			"lang": "eng",
			"status": "published",
			"img": "http://local/mlw/placeholder/250/150",
			"date":{
				"day": "20",
				"month": "MAY",
				"year": "2013",
				"time": "12:34 PM"
			}
		}
	]
}