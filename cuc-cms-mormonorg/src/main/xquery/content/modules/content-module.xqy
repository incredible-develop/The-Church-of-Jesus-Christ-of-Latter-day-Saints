xquery version "1.0-ml";

module namespace content-module ="http://lds.org/code/shared/lds-edit/content/content-module";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";
declare function content-module:get-cell($column as element(ldse:column)) as element(td){
    let $data as xs:string? := if(fn:exists($column/@command))
                                then(fn:concat(fn:string($column/@command)," ",fn:string($column/@id))) 
                                else($column/@id)
    return
         <td>{$column/@class} 
              { if ( fn:empty($column/@link) and fn:empty($column/@read-more)) then (
                  fn:concat("{{",$data,"}}") 
               ) else if ( fn:exists($column/@read-more) ) then (
                    let $path as xs:string? := $column/@read-more
                    return (
                        fn:concat("{{", $data, "}}"), "&nbsp;",
                        <a href="{$settings:shared-prefix}/form{{{{previewLocale}}}}&amp;id={{{{id}}}}#workflow-comments" onclick="ICE.postLink(this); return false;" data-post.status="{{{{dataPostStatus}}}}" data-post.uri="{{{{uri}}}}" data-post.page="{{{{uri}}}}" data-post.option="{{{{option}}}}">(View Conversation)</a>
                   )
               ) else (
                      let $path as xs:string? := $column/@link
                      return (
                               fn:concat('{{#if this.option}}'),
                               		"{{#if this.isCustomPage}}",
	                                    <a href="{$settings:shared-prefix}/page-manager/page-editor{{{{previewLocale}}}}#settings" onclick="ICE.postLink(this); return false;" data-post.status="{{{{dataPostStatus}}}}" data-post.uri="{{{{uri}}}}" data-post.page="{{{{uri}}}}" data-post.option="{{{{option}}}}">
    	                                     {{{{{$data}}}}}
        	                            </a>,
                               		"{{else}}",
	                                    <a href="{$settings:shared-prefix}/form{{{{previewLocale}}}}&amp;id={{{{id}}}}&amp;site={{{{site}}}}" onclick="ICE.postLink(this); return false;" data-post.status="{{{{dataPostStatus}}}}" data-post.uri="{{{{uri}}}}" data-post.page="{{{{uri}}}}" data-post.option="{{{{option}}}}">
    	                                     {{{{{$data}}}}}
        	                            </a>,
        	                        "{{/if}}",
                               '{{else}}',
                                    <a href="{{{{previewUrl}}}}" onclick="C.nonExistantOptions(this.href, this); return false;">
                                         {{{{{$data}}}}}
                                    </a>,
                               '{{/if}}',
                            fn:concat('{{else}}
                               {{',$data,'}}')
                       )
                  )
              }
              </td>           
};



declare function content-module:generate-conditional-column($id as xs:string, $content as item()*) as item()*{
    "{{#ifShown", fn:concat($id,"}}"),
        $content,
     "{{/ifShown}}"
 };
declare function content-module:get-head-cell($column as element(ldse:column), $i as xs:int) as element(th){
    <th>{$column/@class,$column/@id,$column/@type,
            if($column/@type="date")then(attribute date-element {$column/search:sort-order/search:element/@name})else(),           
                        if(fn:exists($column/search:sort-order)) then
                           (
                            <a href="#d"  onclick='DetailTable.Sorting.sort(function(){{C.sortByColumn("{fn:string($column/@id)}");}});'>                                        
                            {fn:string($column/@title)}
                            </a>
                        )
                        else(fn:string($column/@title))
                       }
                </th>
};
