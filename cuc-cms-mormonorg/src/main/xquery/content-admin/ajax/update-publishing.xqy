xquery version "1.0-ml";

import module namespace bp = "http://lds.org/code/cms/modules/bulk-publishing" at "../../modules/bulk-publishing.xqy";

declare variable $selected as xs:string? := xdmp:get-request-field('selected');
declare variable $site as xs:string? := xdmp:get-request-field('site');

bp:update-facets-and-results($selected, $site)