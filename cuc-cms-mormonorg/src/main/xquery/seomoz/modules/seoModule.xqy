xquery version "1.0-ml";

module namespace seomoz = "http://lds.org/code/shared/lds-edit/seo-functions";
 
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "../../modules/template.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $seoSettings as element(ldse:seomoz-settings) := $settings:seomoz;

declare variable $accessId as xs:string := fn:string($seoSettings/ldse:access-id);
declare variable $secretKey as xs:string := fn:string($seoSettings/ldse:secret-key);
declare variable $apiHost as xs:string := fn:string($seoSettings/ldse:api-host);
declare variable $serviceURL as xs:string := fn:string($seoSettings/ldse:service-url);
declare variable $activeMetrics as element(ldse:metric)* :=  $seoSettings/ldse:url-metrics/ldse:metric[@active eq "true"];

declare variable $minutesToExpiration as xs:string := $seoSettings/ldse:minutes-to-expiration;

declare variable $bitFlags as xs:string :=  fn:string(
                                                fn:sum(
                                                    for $metric as element(ldse:metric) in $activeMetrics
                                                    return xs:unsignedLong($metric/@bit-flag)
                                                )
                                            );
                                            
declare function seomoz:url-switch-domains($full-url as xs:string, $new-domain as xs:string) as xs:string {
    let $parts as element(url-parts) := util:get-url-parts($full-url)
    return (
        fn:concat(
            $parts/protocol,
            if ($parts/protocol != "") then ("://") else (),
            $new-domain,
            $parts/uri,
            $parts/params,
            $parts/hash
        )
    )
};

declare function getMapData($targetURL as xs:string) as map:map{
    let $today as xs:date := fn:current-date()
    let $year as xs:string := fn:string(fn:year-from-date($today))
    let $month as xs:string := fn:string(fn:month-from-date($today))
    let $seoData as element(ldse:seo-data)? :=
          cts:search(/ldse:seo-data, 
            cts:and-query(
                (
                core:get-filter-query(),
                cts:element-value-query(fn:QName("http://lds.org/code/lds-edit","url"),$targetURL),
                cts:element-value-query(fn:QName("http://lds.org/code/lds-edit","year"),$year),
                cts:element-value-query(fn:QName("http://lds.org/code/lds-edit","month"),$month)
                )
            )
          )
    
    let $mapFromDB as map:map? := 
        if(fn:exists($seoData)) then (
             map:map($seoData/map:map)
          )
        else()
     
    return(
        if(fn:empty($mapFromDB)) then(
            let $map as map:map := getDataMapFromService($targetURL)
            let $insertMap as empty-sequence() := insertMapIntoDB($targetURL,$map,$month,$year)
            return $map
        )
        else($mapFromDB)
     )
};

declare function getRequestDataFromService($targetURL as xs:string) as item(){
 let $expiration as xs:int := xs:int(util:date-time-in-seconds(
                                    fn:current-dateTime() + xs:dayTimeDuration(fn:concat('PT',$minutesToExpiration,'M')) 
                                    ))
    let $nl as xs:string := "&#10;"
    let $signString as xs:string := fn:concat($accessId,$nl,$expiration) 
    let $binarySignature as xs:string := xdmp:hmac-sha1($secretKey,$signString,"base64")
    let $signature as xs:string := fn:encode-for-uri($binarySignature)
    let $url as xs:string := fn:concat("http://extproxy",$serviceURL,$targetURL,"?Cols=",$bitFlags,
                                "&amp;AccessID=",$accessId,"&amp;Expires=",$expiration,"&amp;Signature=",$signature)
    let $options as element() := <options xmlns="xdmp:http">
                                 <headers xmlns="xdmp:http">
                                        <host>{$apiHost}</host>                
                                   </headers>
    	                           <format xmlns="xdmp:document-get">text</format>
    	                          </options>
    
    let $response as item() := util:http-get($url,$options)[2]
    return $response
};

declare function getDataMapFromService($targetURL as xs:string) as map:map{
    let $requestData as item() := getRequestDataFromService($targetURL)
    return xdmp:from-json($requestData)
   
};

declare function insertMapIntoDB($targetURL as xs:string, $map as map:map, 
                                     $month as xs:string, $year as xs:string) as empty-sequence(){
    let $data as element(ldse:seo-data) := <seo-data xmlns="http://lds.org/code/lds-edit">
                                                <url>{$targetURL}</url>
                                                <month>{$month}</month>
                                                <year>{$year}</year>
                                                {$map}
                                            </seo-data>
    let $stripLastSlashURL as xs:string :=
        if(fn:ends-with($targetURL,"/")) then(
          fn:substring-before($targetURL,"/")
        )
        else(
           $targetURL
        )
    let $dbpath as xs:string := core:build-db-path("", "", "", $data, <options><path>{fn:concat($year,'/',$month,'/',$stripLastSlashURL)}</path></options>)
    return core:save-file($dbpath, $data, ())
};


declare function getTableTemplate() as element(script){
    <script class="handlebars-template" id="seoTableTemplate" type="text/x-handlebars-template">
        <table class="ldse-table highlight-rows">
            <thead>
            <tr>
                <th>Metric</th>
                <th>Value</th>
            </tr>
            </thead>
            <tbody>
            {
                for $metric as element(ldse:metric) in $activeMetrics
                return(
                    <tr onmouseout="hideDescription()" onmouseover="showDescription('{fn:string($metric/ldse:desc)}')">
                        <td>{fn:string($metric/@name)}</td>
                        <td>{{{{round {fn:string($metric/@responseFld)} }}}}</td>
                    </tr>
                )
            }
            </tbody>
        </table>
    </script>

};
(:
declare function buildTableFromMap($jsonMap as map:map) as item()*{
    <link rel="stylesheet" href="/shared/lds-edit/seomoz/styles/seomoz.css" />,
    <link rel="stylesheet" href="/shared/lds-edit/omniture/styles/omniture.css" />,
    <div id="dataTable">
        <table class="ixf-table">
        <thead>
            <tr>
                <th>Metric</th>
                <th>Value</th>
            </tr>
        </thead>
        {
         for $metric as element(ldse:metric) in $activeMetrics
                 let $valueStr as xs:string? := fn:string(map:get($jsonMap,fn:string($metric/@responseFld)))
                 let $castableAsDouble as xs:boolean := xdmp:castable-as("http://www.w3.org/2001/XMLSchema","double",$valueStr)
                 let $value as xs:string? := 
                     if($castableAsDouble) then(
                         let $rounded as xs:string := xs:string(fn:round(xs:decimal(xs:double($valueStr) * 100)) div 100)
                         return ($rounded)
                     )
                     else(
                         $valueStr
                     )
                 return(
                     <tr>
                         <td>{fn:string($metric/@name)}</td><td>{$value}</td>
                     </tr>
                 )
         }
        </table>
    </div>
};
  :)
