xquery version "1.0-ml";

module namespace fbf = "http://lds.org/code/shared/lds-edit/form-builder-functions";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace mljson = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cts = "http://marklogic.com/cts";
declare namespace basic = "http://marklogic.com/xdmp/json/basic";

declare function fbf:jsonBuildNewXml($file, $structure, $id) {
    let $formTemplate := 
        element formTemplate {
            attribute name { $structure/basic:name },
            attribute schedule-publish { $structure/basic:schedule-publish },
            attribute schedule-unpublish { $structure/basic:schedule-unpublish },
            attribute workflow { $structure/basic:workflow },
            element title { $structure/basic:title/node() },
            element documentTitle { $structure/basic:documentTitle/node() },
            element folder { $structure/basic:folder/node() },
            element filePrefix { $structure/basic:prefix/node() },
            element rootElement { $structure/basic:rootElement/node() },
            element functions {},
            element root-query {}
        }
    let $test := core:transform-to-json($file, ('functions'))
    return ( $formTemplate )
};

declare function fbf:getForm($name as xs:string?) {
    cts:search(/ldse:formTemplate,
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-attribute-value-query(xs:QName('ldse:formTemplate'), xs:QName('name'), ( $name, xdmp:get-request-field('name'), xdmp:get-request-field('formNameVal') )[1], 'exact')
        ))
    )
};

declare variable $empty-form :=
    element formTemplate {
        attribute name {  },
        attribute schedule-publish {  },
        attribute schedule-unpublish {  },
        attribute workflow {  },
        element title {  },
        element documentTitle {  },
        element folder {  },
        element filePrefix {  },
        element rootElement {  },
        <functions/>,
        element root-query {}
    }
;

declare function fbf:buildNewFormXml($origFile as element()?, $form as element(ldse:formTemplate), $index, $id as xs:string) as element() {
    let $xml as element()* := fbf:buildNewXml($origFile, $form/ldse:structure/*, $index, $id)
    let $xml as element() := form:postProcessing($origFile, $xml, $form)
    return $xml
};

declare function fbf:buildNewXml($file as element()?, $structure as item()*, $index as xs:string?, $id as xs:string) {
    for $n as item() in $structure
    return (
        typeswitch ($n)
        case comment() return ()
        case text() return (if (fn:normalize-space($n) eq '') then () else ($n))
        case element(ldse:formTemplate) return ( element formTemplate {fbf:buildNewXml($file, $n/node(), $index, $id)})
        case element(ldse:root-query) return ( fbf:buildRootQuery($file, $n, $index, $id) )
        case element(ldse:structure) return ( element structure {fbf:buildStructureRoot($file, $n/ldse:rootElement, $index, $n except $n/ldse:rootElement, $id)})
        case element(ldse:attribute) return ( attribute { $n/@name/xs:string(.) } { form:dispatchStructure($file, $n/node(), $id) } )
        case element(ldse:input) return (form:getInputValue($n, $file, $index))
        case element(ldse:root-query) return (fbf:buildRootQuery($file, $n, $index, $id))
        case element(ldse:dynamic-xml) return (form:getDynamicXmlValues($n, $file, $index, $id, (), fn:false()))
        case element(ldse:dynamic-form-ref) return (form:getDynamicXmlValues($n, $file, $index, $id, (), fn:false()))
        case element(ldse:xhtml) return () (: only used to help give content contributor help filling out form :)
        default return (
            form:createElement($n, $file, $index, $id, (), (), fn:false(), ())
        )
    )
};

declare function fbf:buildRootQuery($file as element()?, $structure as element(ldse:root-query), $index as xs:string?, $id as xs:string) as element(root-query) {
    element root-query {
        let $queries := form:getDynamicXmlValues($structure/element(), $file, $index, $id, (), fn:false())
        for $query as element() in $queries
        return (
            <cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts">{
                for $item as element() in $query/element()
                return (
                    element { fn:concat("cts:", fn:local-name($item)) } {
                        attribute xmlns:cts { "http://marklogic.com/cts" },
                        $item/fn:string()
                    }
                )
            }</cts:element-attribute-value-query>
        )
    }
};

declare function fbf:buildStructureRoot($file as element()?, $structure as element(ldse:rootElement), $index as xs:string?, $items as item()*, $id as xs:string) {
    element {fbf:buildNewXml($file, $structure/node(), $index, $id)} {
        fbf:getDynamicXmlValues($items/element(), $file, $index, $id)
    }
};

declare function fbf:buildStructureXml($file as element()?, $structure as item()*, $index as xs:string?, $id as xs:string) {
    for $n as item() in $structure
    return (
        typeswitch ($n)
        case comment() return ()
        case text() return (if (fn:normalize-space($n) eq '') then () else ($n))
        case element(ldse:formTemplate) return ( element formTemplate{fbf:buildNewXml($file, $n/node(), $index, $id)})
        case element(ldse:structure) return ( element structure {fbf:buildStructureXml($file, $n/node(), $index, $id)})
        case element(ldse:rootElement) return ( element {fbf:buildNewXml($file, $n/node(), $index, $id)} {} )
        case element(ldse:attribute) return (attribute {xs:string($n/@name)} {form:dispatchStructure($file, $n/node(), $index)})
        case element(ldse:input) return (form:getInputValue($n, $file, $index))
        case element(ldse:rootStructure) return (fbf:getDynamicXmlValues($n/element(), $file, $index, $id))
        default return (
            form:createElement($n, $file, $index, $id, (), (), fn:false(), ())
        )
    )
};

(: $dynamicXml should be as element(dynamic-xml) or element(dynamic-form-ref) :)
declare function fbf:getDynamicXmlValues($dynamicXml as element(), $file as element()?, $index as xs:string?, $id as xs:string) as element()* {
    let $dynamicRoot as element() := $dynamicXml/element()
    let $name as xs:string := if (fn:exists($dynamicRoot/@name)) then (xs:string($dynamicRoot/@name)) else (util:sanitize-uri($dynamicRoot/@title))
    let $name as xs:string := if (fn:exists($index)) then (fn:concat($name, '-', $index)) else ($name)
    let $childs as xs:string* :=
        for $child as xs:string in xdmp:get-request-field(fn:concat($name, '-child'))
        where $child
        return (xs:string($child))
    let $childs as xs:string* := 
        if ( fn:exists($childs) ) then ( 
            $childs
        ) else (
            for $child as xs:string in xdmp:get-request-field(fn:concat($name, '-1-child'))
            where $child
            return (xs:string($child))
        )
    let $inner-index as xs:string := if ( fn:exists($index) ) then ( fn:concat($index, '-') ) else ( "" )
    where fn:not(fn:local-name($dynamicRoot) = "rootElement")
    return (
        for $i as xs:string in $childs
        let $type := fbf:getInputValue($dynamicRoot/element()[$i]/ldse:type/ldse:input, $file, $i)
        return (
            if ( fn:local-name($dynamicXml) = 'root-attributes' or fn:local-name($dynamicXml) = 'item-attributes' ) then (
                element attribute {
                    attribute name { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:name/ldse:input, $file, $i) },
                    element input {
                        attribute type { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:type/ldse:input, $file, $i) },
                        attribute name { fn:concat(form:getInputValue($dynamicRoot/element()[$i]/ldse:name/ldse:input, $file, $i), '-', $i)},
                        attribute title { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:title/ldse:input, $file, $i) },
                        attribute seq { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:seq/ldse:input, $file, $i) },
                        attribute class { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:class/ldse:input, $file, $i) },
                        attribute xpath { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:xpath/ldse:input, $file, $i) },
                        attribute value { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:value/ldse:input, $file, $i) },
                        attribute options { fbf:getInputValue($dynamicRoot/element()[$i]/ldse:options/ldse:input, $file, $i) }
                    }
                }
            ) else (
                if ( $type = 'dynamicXml' ) then (
                    let $node := form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:node/ldse:input, $file, $i)
                    let $has-s := fn:ends-with($node, 's')
                    let $child-node := if ( $has-s ) then ( functx:substring-before-last($node, 's') ) else ( fn:concat($node, 's') )
                    return (
                        element { if ( $has-s ) then ( $node ) else ( fn:concat($node, 's') ) } {
                            element dynamic-xml {
                                attribute title { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:title/ldse:input, $file, $i) },
                                attribute seq { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:seq/ldse:input, $file, $i) },
                                attribute class { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:class/ldse:input, $file, $i) },
                                attribute xpath { fn:concat("ldse:", $node, '/ldse:', $child-node) },
                                element { $child-node } {
                                    fbf:getDynamicXmlValues($dynamicXml/ldse:items/ldse:dynamic-xml, $file, $index, $id)
                                }
                            }
                        }
                    )
                ) else (
                    let $test := 
                    element { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:node/ldse:input, $file, $i) } {
                        let $test := fbf:getDynamicXmlValues($dynamicRoot/ldse:item[$i]/ldse:item-attributes, $file, $index, $id)
                        
                        return (
                            $test
                        ),
                        element input {
                            attribute type { $type },
                            attribute name { fn:concat(form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:node/ldse:input, $file, $i), '-', $i)},
                            attribute title { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:title/ldse:input, $file, $i) },
                            attribute seq { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:seq/ldse:input, $file, $i) },
                            attribute class { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:class/ldse:input, $file, $i) },
                            attribute xpath { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:xpath/ldse:input, $file, $i) },
                            attribute options { form:getInputValue($dynamicRoot/ldse:item[$i]/ldse:options/ldse:input, $file, $i) }
                        }
                    }
                    return $test
                )
            )
        )
    )
};

declare function fbf:getInputValue($input as element(ldse:input), $file as element()?, $index as xs:string?) as item()* {
    let $name as xs:string? := form:buildInputName($input, $index)
    let $value as item()* := form:trim($file, $input, $index, xdmp:get-request-field($name, ""))
    let $value as item()* := if ( fn:exists($value) and fn:not($value = "") ) then ( $value ) else ( form:trim($file, $input, $index, xdmp:get-request-field(fn:concat($name, '-1'), "")) )
    return (
        form:valueOptions($file, $input, $value, $index)
    )
};

declare function fbf:saveForm($newXml as element(), $oldFile as element()?, $form as element()) {
(:    let $newXml as element() := :)
    let $newXml as element(ldse:formTemplate) := util:renamespace($newXml, "http://lds.org/code/lds-edit") 
    let $newQuery as element() := util:renamespace($newXml/ldse:root-query/ldse:element-attribute-value-query, "http://marklogic.com/cts")
    let $newXml as element(ldse:formTemplate) := mem:node-replace($newXml/ldse:root-query/ldse:element-attribute-value-query, $newQuery)
    return (
        if ( fn:exists($oldFile) ) then (
            core:document-replace($oldFile, $newXml)
        ) else (
            let $db-path as xs:string := fn:concat(core:get-site-root('preview'), '/content/_configuration/ice/ice-forms/custom/', $newXml/@name, '.xml')
            return (
                core:update-file('ldse:preview', $db-path, $newXml)
            )
        )
    )
};

declare function fbf:buildForm($structure as element()*, $file as element()?, $index as xs:string?, $id as xs:string) as element()* {
    for $n as element() in $structure
    return (
        typeswitch ($n)
        case element(ldse:rootElement) return (fbf:rootElementInput($n/ldse:input, $file, $index))
        case element(ldse:root-query) return (fbf:buildDynamicInputs($n/ldse:dynamic-xml, $file, $index, $id))
        case element(ldse:items) return (fbf:buildDynamicInputs($n/ldse:dynamic-xml, $file, $index, $id))
        case element(ldse:item) return (fbf:buildForm($n/element(), $file, $index, $id))
        case element(ldse:root-attributes) return (fbf:buildDynamicInputs($n/ldse:dynamic-xml, $file, $index, $id))
        case element(ldse:root-attribute) return (fbf:buildForm($n/element(), $file, $index, $id))
        case element(ldse:element-attribute-value-query) return (fbf:buildRootQueryInput($n/element(), $file, $index))
        case element(ldse:type) return (fbf:select($n, $file, $index))
        case element(ldse:name) return (fbf:buildAttributeNameInput($n, $file, $index))
(:        case element(ldse:dynamicItem) return (fbf:select($n, $file, $index)):)
        case element(ldse:node) return (fbf:buildNodeInput($n, $file, $index))
        case element(ldse:title) return (fbf:buildInput($n, $file, $index))
        case element(ldse:seq) return (fbf:buildInput($n, $file, $index))
        case element(ldse:xpath) return (fbf:buildInput($n, $file, $index))
        case element(ldse:value) return (fbf:buildInput($n, $file, $index))
        case element(ldse:class) return (fbf:buildInput($n, $file, $index))
        case element(ldse:options) return (fbf:buildInput($n, $file, $index))
        case element(ldse:xhtml) return form:buildXhtml($n, $file, $index)
        case element(ldse:input) return (form:buildInput($n, $file, $index))
        case element(ldse:dynamic-xml) return (form:buildDynamicInputs($n, $file, $index))
        case element(ldse:dynamic-form-ref) return (form:buildDynamicFormRefs($n, $file, $index))
        default return fbf:buildForm($n/element(), $file, $index, $id)
    )
};

declare function fbf:buildRootQueryInput($structure as element(), $file as element()?, $index as xs:string?) {
    for $root-item as element() in $structure
    return (
        fbf:buildOtherInput($root-item, $file, $index)
    )
};

(:declare function fbf:buildingForm($structure as element()*, $file as element()?, $index as xs:string?) as element()* {
    for $n as element() in $structure
    return (
        typeswitch ($n)
        case element(ldse:xhtml) return (form:buildXhtml($n, $file, $index))
        case element(ldse:dynamic-xml) return (form:buildDynamicInputs($n, $file, $index))
        case element(ldse:dynamic-form-ref) return (form:buildDynamicFormRefs($n, $file, $index))
        default return (fbf:buildingForm($n/element(), $file, $index))
    )
};:)

declare function fbf:select($inputer as element(), $file as element()?, $index as xs:string?) as element(dl) {
    let $xpath as xs:string := fn:concat("ldse:structure/ldse:", fn:local-name($file/ldse:structure/element()), '/ldse:', fn:local-name($inputer))
    let $input as element(ldse:input) := $inputer/ldse:input
    let $name as xs:string := form:buildInputName($input, $index)
    let $id as xs:string := $name
    let $value as xs:string := $file/ldse:input/@type/fn:string()
    let $blockAttrs as xs:string* := ('seq', 'name', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        if ( fn:not(fn:contains($name, 'attrType')) ) then (
            <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
                {form:inputLabel($input, $id, $index)}
                <dd>
                {
                    element select {
                        form:getInputAttributes($input, $blockAttrs, $index),
                        attribute name {$name},
                        attribute id {$id},
                        if (fn:exists($input/ldse:dynamic-options)) then (
                            xdmp:apply(form:getFunction($input/ldse:dynamic-options/@function), $value)
                        ) else (
                            for $option as element(ldse:option) in $input/ldse:option
                            return (
                                element option {
                                    $option/@*,
                                    if ($option/@value eq fn:string($value) or $option/@selected ) then (
                                        attribute selected {"selected"}
                                    ) else (),
                                    xs:string($option)
                                }
                            )
                        )
                    }
                }</dd>
            </dl>
        ) else ( fbf:buildInput($inputer, $file, $index) )
    )
};

declare function fbf:rootElementInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
        {form:inputLabel($input, "rootElement", $index)}
        <dd>{
            element input {
                attribute title { "Root Element" },
                attribute name { "rootElement" },
                attribute value { fn:local-name($file/ldse:structure/element()) },
                attribute id { "rootElement" }
            }
        }</dd>
    </dl>
};

declare function fbf:buildElement($structure as element(), $file as element()?, $index as xs:string?) {
    for $n as item() in $structure
    return (
        typeswitch ( $n )
        case element() return (fbf:buildInput($structure, $file, $index))
        case attribute() return ()
        default return ()
    )
};

declare function fbf:buildInput($input as element(), $file as element()?, $index as xs:string?) as element(dl)* {
    let $name as xs:string := form:buildInputName($input/ldse:input, $index)
    let $id as xs:string := form:buildInputId($input/ldse:input, $name)
    let $attr as xs:string := fn:concat('@', fn:local-name($input))
    let $value as item()* := fbf:dynamicXpath($file/ldse:input, $attr)
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {form:inputLabel($input/ldse:input, $id, $index)}
            <dd>{
                element input {
                    form:getInputAttributes($input/ldse:input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute value {xdmp:quote($value)},
                    attribute id {$id}
                }
            }</dd>
        </dl>
    )
};

declare function fbf:buildOtherInput($input as element()*, $file as element()?, $index as xs:string?) as element(dl)* {
    let $name as xs:string := form:buildInputName($input/ldse:input, $index)
    let $id as xs:string := form:buildInputId($input/ldse:input, $name)
    let $xpath as xs:string := fn:concat('cts:', fn:local-name($input)) 
    let $value as item()* := fbf:dynamicXpath($file, $xpath)/fn:string()
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {form:inputLabel($input/ldse:input, $id, $index)}
            <dd>{
                element input {
                    form:getInputAttributes($input/ldse:input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute value {xdmp:quote($value)},
                    attribute id {$id}
                }
            }</dd>
        </dl>
    )
};

declare function fbf:buildNodeInput($input as element(), $file as element()?, $index as xs:string?) as element(dl)* {
    let $name as xs:string := form:buildInputName($input/ldse:input, $index)
    let $id as xs:string := form:buildInputId($input/ldse:input, $name)
    let $value as xs:string := fn:local-name($file)
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {form:inputLabel($input/ldse:input, $id, $index)}
            <dd>{
                element input {
                    form:getInputAttributes($input/ldse:input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute value {xdmp:quote($value)},
                    attribute id {$id}
                }
            }</dd>
        </dl>
    )
};

declare function fbf:buildAttributeNameInput($input as element(), $file as element()?, $index as xs:string?) as element(dl)* {
    let $name as xs:string := form:buildInputName($input/ldse:input, $index)
    let $id as xs:string := form:buildInputId($input/ldse:input, $name)
    let $value as xs:string := $file/@name/fn:string()
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {form:inputLabel($input/ldse:input, $id, $index)}
            <dd>{
                element input {
                    form:getInputAttributes($input/ldse:input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute value {$value},
                    attribute id {$id}
                }
            }</dd>
        </dl>
    )
};

declare function fbf:dynamicXpath($file as element(), $xpath as xs:string) as item()* {
    let $value as item()* := util:value($file, $xpath)
    return (
        typeswitch ($value)
        case attribute() return ( fn:string($value) )
        default return (
            $value
        )
    )
};

declare function fbf:buildDynamicInputs($dynamicXml as element(ldse:dynamic-xml), $file as element()?, $index as xs:string?, $id as xs:string) as element(dl) {

        let $name as xs:string := if (fn:exists($dynamicXml/@name)) then (xs:string($dynamicXml/@name)) else (util:sanitize-uri($dynamicXml/@title))
        let $name as xs:string := if (fn:exists($index)) then (fn:concat($name, '-', $index)) else ($name)

        let $hash as xs:unsignedInt := xdmp:hash32( $name )
        let $inner-hash as xs:string := if (fn:exists($index)) then (fn:concat($index, '-')) else ("")
        let $addInput as element(li) :=
                element li {
                    attribute class { "repeated-item" },
                    if ( fn:exists($dynamicXml/@item-style) ) then (
                        attribute style { $dynamicXml/@item-style }
                    ) else (),
                    <dl>
                        {
                         if ($dynamicXml/@collapsible = "true") then (
                            <header class="dynamic-xml-header"><a href="#d" class="ldse-icon-rev-tri-down dynamic-xml-toggle"></a>
                               <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$hash}"/>
                               <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right deleteListItem">Delete</a>
                            </header>
                         ) else (
                            <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$hash}"/>,
                            <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right deleteListItem">Delete</a>
                         )
                        }
                    </dl>,
                    <fieldset class="table">{
                        for $node as element() in form:buildForm($dynamicXml/element(), (), fn:concat($inner-hash, $hash) )
                        order by fn:number($node/@data-sequence)
                        return ($node)
                    }</fieldset>
                }
        let $nodes as item()* := 
            for $element in $dynamicXml/element()
            return (
                typeswitch ( $element )
                case element(ldse:element-attribute-value-query) return (
                    for $node in $file/ldse:root-query/cts:element-attribute-value-query
                    let $xpath as xs:string := fn:concat('ldse:root-query/cts:element-attribute-value-query')
                    return (
                        form:dynamicXpath($file, $xpath)
                    )
                ) case element(ldse:root-attribute) return (
                    for $node in $file/ldse:structure/element()/ldse:attribute
                    let $xpath as xs:string := fn:concat("ldse:structure/ldse:", fn:local-name($file/ldse:structure/element()), '/ldse:', fn:local-name($node))
                    return (
                        fbf:dynamicXpath($file, $xpath)[@name = $node/@name]
                    )
                ) default return ( 
                    for $node in $file/ldse:structure/element()/element() except $file/ldse:structure/element()/ldse:attribute
                    let $xpath as xs:string := fn:concat("ldse:structure/ldse:", fn:local-name($file/ldse:structure/element()), '/ldse:', fn:local-name($node))
                    return (
                        fbf:dynamicXpath($file, $xpath)
                    )
                )
            )
            (:
            if ( fn:exists($dynamicXml/ldse:element-attribute-value-query) ) then ( 
                for $node as element() in $file/ldse:root-query/cts:element-attribute-value-query
                let $xpath as xs:string := fn:concat('ldse:root-query/cts:element-attribute-value-query')
                return (
                    fbf:dynamicXpath($file, $xpath)
                )
            ) else if ( fn:exists($dynamicXml/ldse:root-attribute) ) then (
                for $node in $file/ldse:structure/ldse:attribute/element()
                let $xpath as xs:string := fn:concat("ldse:structure/ldse:", fn:local-name($file/ldse:structure/element()), '/ldse:', fn:local-name($node))
                return (
                    fbf:dynamicXpath($file, $xpath)
                )
            ) else (
                for $node in $file/ldse:structure/element()/element()
                let $xpath as xs:string := fn:concat("ldse:structure/ldse:", fn:local-name($file/ldse:structure/element()), '/ldse:', fn:local-name($node))
                return (
                    fbf:dynamicXpath($file, $xpath)
                ):)
(:            ):)
        let $blockAttrs as xs:string* := ('seq', 'name', 'title', 'options', 'xpath', 'dlClass', 'help', 'item-style', 'add-label')
        let $minimum as xs:int? := $dynamicXml/@data-min
        let $count as xs:string :=  if (fn:exists($nodes)) then (xs:string(fn:count($nodes))) else ( (xs:string($minimum), '0' )[1] )
        let $blank-inputs as element(li)* := 
            for $i as xs:int in 1 to $minimum
            return (
                element li {
                    attribute class { "repeated-item" },
                    if ( fn:exists($dynamicXml/@item-style) ) then (
                        attribute style { $dynamicXml/@item-style }
                    ) else (),
                    <dl>
                        {
                         if ($dynamicXml/@collapsible = "true") then (
                            <header class="dynamic-xml-header"><a href="#d" class="{ if ( $dynamicXml/@collapsed = "true" ) then ( 'ldse-icon-rev-tri-right dynamic-xml-toggle closed' ) else ('ldse-icon-rev-tri-down dynamic-xml-toggle')}"></a>
                               <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$i}"/>
                               <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right deleteListItem">Delete</a>
                            </header>
                         ) else (
                           <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$i}"/>,
                           <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right deleteListItem">Delete</a>
                        )
                        }
                    </dl>,
                    <fieldset class="table">{
                        for $node as element() in form:buildForm($dynamicXml/element(), (), xs:string( fn:concat($inner-hash, $i) ))
                        order by fn:number($node/@data-sequence)
                        return ($node)
                    }</fieldset>
                }
            )
        return (
            <dl data-sequence="{xs:string($dynamicXml/@seq)}" data-group="{$dynamicXml/@group}" class="{xs:string($dynamicXml/@dlClass)}">
                <dt>
                    <label><b>{xs:string($dynamicXml/@title)}</b></label>
                </dt>
                <dd>
                    {
                        element ul {
                            form:getInputAttributes($dynamicXml, $blockAttrs, $index),
                            for $node as element() at $i in $nodes
                            return (
                                element li {
                                    attribute class { "repeated-item" },
                                    if ( fn:exists($dynamicXml/@item-style) ) then (
                                        attribute style { $dynamicXml/@item-style }
                                    ) else (),
                                    <dl>
                                        {
                                         if ($dynamicXml/@collapsible = "true") then (
                                            <header class="dynamic-xml-header"><a href="#d" class="{ if ( $dynamicXml/@collapsed = "true" ) then ( 'ldse-icon-rev-tri-right dynamic-xml-toggle closed' ) else ('ldse-icon-rev-tri-down dynamic-xml-toggle')}"></a>
                                               <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$i}"/>
                                               <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right deleteListItem">Delete</a>
                                            </header>
                                         ) else (
                                            <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$i}"/>,
                                            <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right deleteListItem">Delete</a>
                                         )
                                        }
                                    </dl>,
                                    <fieldset class="{if ( $dynamicXml/@collapsed = "true" ) then ( "table closed" ) else ( "table" )}" style="{if ( $dynamicXml/@collapsed = "true" ) then ( "display:none;" ) else ()}">{
                                        if ( fn:exists($dynamicXml/ldse:element-attribute-value-query) ) then ( 
                                            for $node as element() in fbf:buildForm($dynamicXml/ldse:element-attribute-value-query, $node, fn:concat($inner-hash, $i), $id)
                                            order by fn:number($node/@data-sequence)
                                            return ($node)                                        
                                        ) else (
                                            for $node as element() in fbf:buildForm($dynamicXml/element(), $node, fn:concat($inner-hash, $i), $id)
                                            order by fn:number($node/@data-sequence)
                                            return ($node)
                                        )
                                    }</fieldset>}
                            ),
                            if (fn:empty($nodes) and  fn:not($dynamicXml/@empty-child = "false")) then ($blank-inputs) else ()
                        },
                        <a href="#d" class="sprite ldse-icon-ko-add ldse-add prefix addListItem" data-item="{xdmp:quote($addInput)}" data-hash="{$hash}" data-childCount="{$count}">Add { xs:string($dynamicXml/@add-label) }</a>
                    }
                </dd>
            </dl>
        )
};
