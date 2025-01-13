xquery version "1.0-ml";

module namespace sync-meta-spawn = "http://lds.org/code/shared/lds-edit/sync-meta-spawn";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "utility-functions.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace sync-meta = "http://lds.org/code/shared/lds-edit/sync-meta-spawn";


declare option xdmp:mapping "true";

declare function sync-meta-spawn:build-sync-element($sync-element-xpath-parts as xs:string*, $from-xml-element as element()) as element()
{
	if(fn:count($sync-element-xpath-parts)  eq 1)
	then element {fn:node-name($from-xml-element)} {$from-xml-element/(@* | node())}
	else element {$sync-element-xpath-parts[1]} {sync-meta-spawn:build-sync-element($sync-element-xpath-parts[2 to fn:last()], $from-xml-element)}
};

declare function sync-meta-spawn:spawn($uris-map as map:map, $form-name as xs:string, $id as xs:string, $locale as xs:string, $username as xs:string?, $userid as xs:string?) as empty-sequence()
{
	
	let $setuser as empty-sequence() := ldsemeta:set-user(($username, "Sync Meta Function")[1], ($userid, "")[1])
	let $uris as xs:string* := map:get($uris-map, "uris")
	let $from-uri as xs:string := ldsemeta:get-file-by($id, $locale, (), ())/xdmp:node-uri(.)

	let $from-xml as element() := fn:doc($from-uri)/element()
	let $to-uris as xs:string* := $uris
	
	let $to-xmls as element()* :=
		for $to-uri as xs:string in $to-uris
		return fn:doc($to-uri)/element()
		
	let $form-template as element()  :=
		cts:search(
			/ldse:formTemplate,
			cts:and-query(
				(core:get-filter-query(),
				cts:element-attribute-value-query(
					xs:QName("ldse:formTemplate"),
					xs:QName("name"),
					$form-name
				))
			)
		)

	let $sync-paths as xs:string* := $form-template/fn:root()//*[@its:translate eq "no"][@sync eq "true"]/fn:substring-after(fn:replace(xdmp:path(., fn:false()), "ldse:", ""), "structure")
	let $sync-elements as element()* := $form-template/fn:root()//*[@its:translate eq "no"][@sync eq "true"]
	
	for $to-xml as element() in $to-xmls
		let $new-ldsemeta as element(ldse:ldse-meta) := ldsemeta:get-meta($to-xml)
		let $xml as element() :=
			element {fn:node-name($to-xml)}
			{
				$to-xml/@*,
				$new-ldsemeta,
				$to-xml/node() except $to-xml/ldse:ldse-meta
			}
			
		let $sync-attributes as empty-sequence() :=
			for $path as xs:string in $form-template/fn:root()//*[@its:translate eq "no"][@sync eq "true"]/xdmp:path(., fn:false())[fn:matches(., "/ldse:attribute")]
				let $form-element as element() := util:unpath(document{$form-template}, $path)
				let $form-element-parent as element() := $form-element/parent::element()
				let $parent-path as xs:string := $form-element-parent/fn:substring-after(fn:replace(xdmp:path(., fn:false()), "ldse:", ""), "structure")
				let $attribute-name as xs:string := $form-element/@name/fn:string(.)
				let $attribute-value as xs:string := $from-xml/util:unpath(document{$from-xml}, fn:concat($parent-path, "/@", $attribute-name))
				let $xml-element as element()? := util:unpath(document{$xml}, $parent-path)
				
				let $new-xml-element as element() :=
					if ( fn:exists($xml-element) ) then (
							element {fn:node-name($xml-element)} {
								for $xml-element-attribute as attribute() in $xml-element/@*
								where fn:not( fn:local-name($xml-element-attribute) = $attribute-name )
								return $xml-element-attribute,
								
								attribute {$attribute-name} {$attribute-value},
								
								$xml-element/node()
							}
					) else (
						element {fn:node-name($form-element-parent)} { attribute {$attribute-name} {$attribute-value} }
					)
					
				let $set as empty-sequence() :=
					if($to-xml/util:unpath(document{$to-xml}, fn:concat($parent-path, "/@", $attribute-name)))
					then xdmp:set($xml, mem:node-replace($xml-element, $new-xml-element)/*)
					
					else
						let $path-tok as xs:string* := fn:tokenize($path, "/")
						let $parent as xs:string := ""
						
						let $find-parent as empty-sequence() :=
							for $path-part as xs:string in $path-tok[2 to fn:last()]
								let $path-part as xs:string := fn:replace($path-part, "ldse:", "")
							return
								if(fn:concat($parent, "/", $path-part) eq $xml/descendant-or-self::element()/xdmp:path(.))
								then xdmp:set($parent, fn:concat($parent, "/", $path-part))
								else ()
								
						let $path as xs:string := fn:replace($path, "ldse:", "")
						let $sync-element as element() := sync-meta-spawn:build-sync-element(fn:tokenize(fn:substring-after($path, $parent), "/")[2 to fn:last()][. ne "attribute"], $new-xml-element)
							
						for $to-xml-element as element() in $xml/fn:root()//element()
						return
							if($to-xml-element/xdmp:path(., fn:false()) eq $parent)
							then xdmp:set($xml, mem:node-insert-child($to-xml-element, $sync-element)/*)
							else ()
							
			return ()
		
		
		let $sync-elements as empty-sequence() :=
			for $path as xs:string in $form-template/fn:root()//*[@its:translate eq "no"][@sync eq "true"]/xdmp:path(., fn:false())[fn:not(fn:matches(., "/ldse:attribute"))]
				let $form-element as element() := util:unpath(document{$form-template}, $path)
				let $path as xs:string := fn:replace(fn:replace($path, "ldse:", ""), "/formTemplate/structure", "")
				let $element-name as xs:string := $form-element/fn:local-name(.)
				let $element-value as item()* := $from-xml/util:unpath(document{$from-xml}, $path)/node()
				let $element-attributes as attribute()* := $from-xml/util:unpath(document{$from-xml}, $path)/@*
				let $xml-element as element()? := util:unpath(document{$xml}, $path)
				let $new-xml-element as element() := element {$element-name} {$element-attributes, $element-value}
					
				let $set as empty-sequence() :=
					if ( fn:exists($xml-element) )
					then xdmp:set($xml, mem:node-replace($xml-element, $new-xml-element)/*)
					
					else
						let $path-tok as xs:string* := fn:tokenize($path, "/")
						let $parent as xs:string := ""
						
						let $find-parent as empty-sequence() :=
							for $path-part as xs:string in $path-tok[2 to fn:last()]
								(:let $path-part as xs:string := fn:replace($path-part, "ldse:", ""):)
							return
								if(fn:concat($parent, "/", $path-part) eq $xml/descendant-or-self::element()/xdmp:path(.))
								then xdmp:set($parent, fn:concat($parent, "/", $path-part))
								else ()
								
						let $path as xs:string := fn:replace($path, "ldse:", "")
						let $sync-element as element() := sync-meta-spawn:build-sync-element(fn:tokenize(fn:substring-after($path, $parent), "/")[2 to fn:last()][. ne "attribute"], $new-xml-element)
							
						for $to-xml-element as element() in $xml/fn:root()//element()
						return
							if($to-xml-element/xdmp:path(., fn:false()) eq $parent)
							then xdmp:set($xml, mem:node-insert-child($to-xml-element, $sync-element)/*)
							else ()
							
			return ()
							
	return core:document-replace($to-xml, $xml)
};



















