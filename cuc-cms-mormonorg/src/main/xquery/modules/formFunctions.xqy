xquery version "1.0-ml";

module namespace formFunctions = "http://lds.org/code/lds-edit/modules/formFunctions";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace basic = "http://marklogic.com/xdmp/json/basic";
declare namespace its = "http://www.w3.org/2005/11/its";

declare default element namespace "http://lds.org/code/lds-edit";

declare variable $seqCount as map:map := map:map();
declare variable $ldse-settings as element(ldse:ldse-settings) := $core:ldse-settings;

declare function formFunctions:getNextSeqCount(
    $seqCount as map:map
) as xs:string {
    if ( fn:exists(map:get($seqCount,"count")) eq fn:true() ) then (
        map:put($seqCount, "count", xs:string(xs:integer(map:get($seqCount,"count")) +1) )
    ) else (
        map:put($seqCount, "count", "1")
    ),
    map:get($seqCount, "count")
};

(: traverse backwards looking for the top-most group or region (a region is treated the same as a group) :)
declare function getGroupNameHelper(
    $node as node(),$groupName as xs:string?) as xs:string?
{
    (: traverse backwards to the outer-most group and use it :)
    if (fn:exists($node/basic:group) or fn:exists($node/basic:region)) then (
        formFunctions:getGroupNameHelper($node/parent::*,$node/fn:local-name(.))
    )
    else if (fn:exists($node/parent::*)) then (
        formFunctions:getGroupNameHelper($node/parent::*,$groupName)
    )
    else (
        $groupName
    )
};

(: traverse backwards counting how many group are between $node and the root :)
declare function countParentGroups(
    $node as node()?,$cnt as xs:integer) as xs:integer
{
    if (fn:exists($node)) then (
        if (fn:exists($node/basic:group) or fn:exists($node/basic:region)) then (
            if (fn:exists($node/parent::*)) then (
                formFunctions:countParentGroups($node/parent::*,$cnt +1)
            )
            else ($cnt)
        )
        else (
            formFunctions:countParentGroups($node/parent::*,$cnt)
        )
    )
    else ($cnt)
};

declare function formFunctions:getGroupName(
    $inputMetaData as node()
) as attribute()? {

    let $groupName as xs:string? := formFunctions:getGroupNameHelper($inputMetaData/parent::*,())
    return if ($groupName) then ( attribute group {$groupName} )
           else ()
};

declare function formFunctions:getInput(
    $group as attribute()?,
    $seqNum as xs:string,
    $type as xs:string,
    $nameAttribute as xs:string,
    $class as xs:string?,
    $readOnly as xs:boolean?,
    $xpath as xs:string,
    $titleAttribute as xs:string,
    $config as xs:string?,
    $toolbar as xs:string?,
    $formName as xs:string?,
    $options as xs:string?,
    $select-options as element()*,
    $inlineHelp as xs:string?,
    $dlClass as xs:string?
) as element() {
    element { fn:QName("http://lds.org/code/lds-edit","input") } {
        $group,
        attribute seq { $seqNum },
        attribute type { $type },
        attribute name { $nameAttribute },
        if ( $class ) then ( attribute class { $class } ) else (),
        if ( $readOnly ) then ( attribute readonly { 'readonly' } ) else (),
        attribute xpath { $xpath },
        attribute title { $titleAttribute },
        if ( fn:exists($config) ) then ( attribute config { $config } ) else (),
        if ( fn:exists($toolbar) ) then ( attribute toolbar { $toolbar } ) else (),
        if ( $formName ) then ( attribute formName { $formName } ) else (),
        if ( $options ) then ( attribute options { $options } ) else (),
        if ( $inlineHelp ) then ( attribute inline-help { $inlineHelp } ) else (),
        if ( $dlClass ) then ( attribute dlClass { $dlClass } ) else (),
        $select-options
    }
};

(: normalize a string with ascii codes injected by the json transform, for example:

    let $json := '{ "options": [ { "here is a crazy name: ! # $ % &amp; ( ) * + , / : ; < = > ? @" : "some value" } ] }'
    let $name := json:transform-from-json($json)//basic:json/child::*[1]/fn:local-name(.)
    (: now $name = here_20_is_20_a_20_crazy_20_name_3A__20__21__20__23__20__24__20__25__20__26__20__28__20__29__20__2A__20__2B__20__2C__20__2F__20__3A__20__3B__20__3C__20__3D__20__3E__20__3F__20__40_ :)
    return
      functx:replace-multi(
        $name,
        $changeFrom,
        $changeTo
      )

   returns: here is a crazy name: ! # $ % & ( ) * + , / : ; < = > ? @
:)
declare function formFunctions:getNormalizedValue($value as xs:string?) as xs:string? {

    let $changeFrom := ('_20_','_21_','_23_','_24_','_25_','_26_', '_28_','_29_','_2A_','_2B_','_2C_','_2F_','_3A_','_3B_','_3C_','_3D_','_3E_','_3F_','_40_')
    let $changeTo   := (' ',   '!',   '#',   '\$',  '%',   '&amp;','(',   ')',   '*',   '+',   ',',   '/',   ':',   ';',   '<',   '=',   '>',   '?',   '@')
    return
        functx:replace-multi(
            $value,
            $changeFrom,
            $changeTo
        )
};

declare function formFunctions:generateDropDownOptions (
    $type as xs:string,
    $dropDownData as node()
) as element()* {
    if ( $type = "select" ) then (
        if ($dropDownData/basic:functionDetails/basic:function) then (
            element {"dynamic-options"} {
                attribute {"function"} {$dropDownData/basic:functionDetails/basic:function}
            }
        ) else (
            for $option in $dropDownData/basic:options[@type eq "array"]/basic:json/node()
            return (
                element option {
                    attribute value { $option/fn:string(.) },
                    formFunctions:getNormalizedValue(fn:local-name($option))
                }
            )
        )
    ) else ()
};

declare function formFunctions:getLdsPubInput(
    $inputMetaData as node(),
    $formTitle as xs:string?,
    (: $required as xs:boolean?, :)
    $classes as xs:string?,
    $myPath as xs:string?,
    $dlClass as xs:string?
) as element (ldse:input) {
    let $seqNum as xs:string := formFunctions:getNextSeqCount($seqCount)

    (: name & title attribute :)
    let $inputLocalName as xs:string := fn:local-name($inputMetaData)
    let $formTitle := ($formTitle,"WARNING-NO-TITLE-IN-SCHEMA")[1]

    let $node-path as xs:string := xdmp:path($inputMetaData)
    let $xpath as xs:string := fn:replace($node-path,"basic:", "")
    let $xpath as xs:string := fn:replace($xpath,"/json/", "")
    let $xpath as xs:string := ( $myPath, fn:replace($xpath, "properties/", "") )[1]
    let $xpath as xs:string := fn:concat($xpath, "node()")
    let $type as xs:string := if ( ( $inputMetaData/basic:type/fn:string(.), "text" )[1] eq "string") then ("text") else ($inputMetaData/basic:type/fn:string(.))

    let $nameAttribute as xs:string := fn:replace($node-path, "basic:", "")
    let $nameAttribute as xs:string := fn:replace($nameAttribute, "/json/", "")
    let $nameAttribute as xs:string := fn:replace($nameAttribute, "properties/", "")
    let $nameAttribute as xs:string := fn:replace($nameAttribute, "/", "-")
    let $readonly as xs:boolean := $inputMetaData/basic:readonly/fn:string(.) eq "true"
    let $titleAttribute as xs:string := ( $inputMetaData/basic:label/fn:string(.), $nameAttribute )[1]

    (: see if we are in a group, look to our ancestors to tell us :)
    let $group as attribute()? := formFunctions:getGroupName($inputMetaData)
    let $options as xs:string? := if ( $type = "image" ) then ("imageUpload") else if ($type = ('wysiwyg', 'small-wysiwyg')) then ("tidy") else ()
    let $select-options as element()* := formFunctions:generateDropDownOptions($type, $inputMetaData)
    let $inlineHelp as xs:string? := $inputMetaData/basic:inlineHelp/fn:string(.)

    return (
        switch ( $type )
        case "small-wysiwyg" return ( formFunctions:getInput($group, $seqNum, "wysiwyg", $nameAttribute, fn:string-join(($classes,"xxxl")," "), $readonly, $xpath, $titleAttribute, "limitied", "preferred", (), $options, (), $inlineHelp, $dlClass) )
        case "wysiwyg" return ( formFunctions:getInput($group, $seqNum, "wysiwyg", $nameAttribute, fn:string-join(($classes,"xxxl")," "), $readonly, $xpath, $titleAttribute, "full", "preferred", (), $options, (), $inlineHelp, $dlClass) )
        case "externalForm" return ( formFunctions:getInput($group, $seqNum, $type, $nameAttribute, (), (), 'node()', $titleAttribute, (), (), $formTitle, (), (), $inlineHelp, $dlClass) )
        case "externalDynamicForm" return ( formFunctions:getInput($group, $seqNum, $type, $nameAttribute, (), (), 'node()', $titleAttribute, (), (), $formTitle, (), (), $inlineHelp, $dlClass) )
        default return ( formFunctions:getInput($group, $seqNum, $type, $nameAttribute, fn:string-join(($classes,"xxxl")," "), $readonly, $xpath, $titleAttribute, (), (), (), $options, $select-options, $inlineHelp, $dlClass) )
    )

};

declare function formFunctions:getDynamicFormRef(
    $childNode as node(),
    $myPath as xs:string
) as element() {
    let $seqNum as xs:string := formFunctions:getNextSeqCount($seqCount)
    let $qNameParent := fn:QName("http://lds.org/code/lds-edit",$childNode/fn:local-name(.))
    let $qNameDynamicFormRef := fn:QName("http://lds.org/code/lds-edit","dynamic-form-ref")
    let $qNameChild := fn:QName("http://lds.org/code/lds-edit",$childNode/fn:local-name(.))

    let $xpath as xs:string := fn:local-name($childNode)
    let $xpath as xs:string := fn:concat($xpath,"/",$childNode/fn:local-name(.))
    let $xpath as xs:string := fn:concat($myPath,fn:concat($xpath,"-docIds"))

    let $dynamicFormNames as xs:string* := for $formName in $childNode//basic:_24_lds-pub-ref/fn:string(.)
                                           return (
                                               fn:concat(fn:replace($formName,"-","_"),"_form")
                                           )
    let $formName as xs:string := $dynamicFormNames[1]
    let $auto-publish-ref as xs:string? := $childNode//basic:lds-pub-options[@type eq "array"]/basic:json/basic:auto-publish-ref
    let $autoPublishRefs as xs:boolean := $auto-publish-ref = "true"
    let $maxInputs as xs:string? := $childNode//basic:max-number/fn:string(.)

    return (
        element { $qNameParent } {
            attribute its:translate { "no" },
            element { $qNameDynamicFormRef } {
                formFunctions:getGroupName($childNode),
                attribute seq { $seqNum },
                attribute title { fn:local-name($childNode) },
                attribute xpath { $xpath },
                attribute class { "sortable" },
                if($maxInputs) then (attribute data-max { $maxInputs }) else (),
                attribute formName { $formName },
                attribute dynamic-form-names { fn:string-join($dynamicFormNames,",") },
                element { fn:concat($qNameChild,"-docIds") } {
                    attribute type { "array" },
                    attribute auto-publish-ref { if ( $autoPublishRefs ) then ( "true" ) else ( "false" ) },
                    attribute fetch-data { "true" },

                    let $input as element(basic:placeholder) :=
                        element { fn:QName("http://marklogic.com/xdmp/json/basic", "placeholder") } {
                            element { fn:QName("http://marklogic.com/xdmp/json/basic", "type") } { "externalDynamicForm" }
                        }
                    return (
                        formFunctions:getLdsPubInput($input, $formName, (), (), ())
                    )
                }
            }
        }
    )
};

declare function formFunctions:getDynamicForm(
    $childNode as node(),
    $formName as xs:string,
    $myPath as xs:string
) as element() {
    let $child-name as xs:string := fn:local-name($childNode)
    let $seqNum as xs:string := formFunctions:getNextSeqCount($seqCount)
    let $qName as xs:QName := fn:QName("http://lds.org/code/lds-edit", $child-name)
    let $qName2 as xs:QName := fn:QName("http://lds.org/code/lds-edit","dynamic-form-ref")

    let $xpath as xs:string := fn:concat($child-name, "/", $child-name)
    let $xpath as xs:string := fn:concat($myPath, $xpath, "-docIds")
    let $maxInputs as xs:string? := $childNode//basic:max-number/fn:string(.)
    let $label as xs:string? := $childNode//basic:label/fn:string(.)
    return (
        element { $qName } {
            attribute its:translate {"no"},
            element { $qName2 } {
                formFunctions:getGroupName($childNode),
                attribute seq { $seqNum },
                attribute title { ($label,fn:local-name($childNode))[1] },
                attribute xpath { $xpath },
                if($maxInputs) then (attribute data-max { $maxInputs }) else (),
                attribute class {"sortable"},
                attribute formName {$formName},
                element { fn:concat($qName, "-docIds") } {
                    attribute type { "array" },
                    attribute fetch-data { "true" },
                    attribute auto-publish-ref { "true" },
                    let $input as element() :=
                        element { fn:QName("http://marklogic.com/xdmp/json/basic", $child-name) } {
                            element { fn:QName("http://marklogic.com/xdmp/json/basic","type") } { "externalForm" }
                        }
                    return (
                        formFunctions:getLdsPubInput($input, $formName, (), (), ())
                    )
               }
           }
       }
    )
};


declare function formFunctions:getLdsPubInputs(
    $node as node(),
    $myPath as xs:string
) as element()* {
    for $childNode in ($node/node()[@type eq "object" or fn:local-name(.) eq "group" or fn:local-name(.) eq "region"])
    return (
        if (fn:local-name($childNode) ne "properties") then (
            let $localName as xs:string := fn:local-name($childNode)

            (: if we have a 'type' child that is not an 'object', then create an lds-publisher input :)
            let $typeChild as xs:string? := $childNode/child::node()[fn:local-name(.) eq "type" and fn:string(.) ne "object"]
            let $dynamic as xs:string? := $childNode/child::node()[fn:local-name(.) eq "repeat" and fn:string(.) eq "true"]
            let $dynamic-template as xs:string? := $childNode/child::node()[fn:local-name(.) eq "dynamic-template" and fn:string(.) eq "true"]
            let $xpath as xs:string := fn:concat($myPath,$localName)
            let $ref as xs:boolean := fn:exists($childNode/child::node()[fn:local-name(.) eq "_24_lds-pub-ref"])
            let $translate as xs:string? := $childNode/basic:translate
            return (
                if (fn:exists($typeChild)) then (

                    (: translate element doesn't exist or, exists and is 'yes' :)
                    let $translate as xs:string :=
                        if ( ( fn:empty($translate) or $translate eq "true" ) and fn:not($childNode/basic:type/fn:string(.) eq "image") ) then (
                            "yes"
                        ) else ("no")

                    (: special case for images, always rig translate to 'no' :)
                    let $required as element(basic:required)? := $childNode/parent::node()/parent::node()/child::node()[fn:local-name(.) eq "required"]
                    let $required2 as xs:boolean := fn:exists($required/basic:item[fn:string(.) eq $localName]) or ($childNode/basic:required/fn:string(.) eq "true")
                    let $classes := (if ($required2) then ("required") else (),()) (: note: could add more classes here :)

                    let $formTitle as xs:string := ( fn:root($childNode)//basic:title )[1]
                    let $qName as xs:QName := fn:QName("http://lds.org/code/lds-edit", $localName)

                    return (
                        if ( fn:exists($dynamic) ) then ( (: note: this may not be needed now but was at one point, keep it to be safe :)

                        (: look for a child 'repeatClass' and use its value for the dlClass :)
                        let $repeatClass as xs:string? := $childNode/child::node()[fn:local-name(.) eq "repeatClass"]/fn:string(.)
                        let $dataMin as xs:string? := $childNode/parent::*:properties/parent::*/basic:dataMin/fn:string(.)
                        let $dataMax as xs:string? := $childNode/parent::*:properties/parent::*/basic:dataMax/fn:string(.)
                        let $allowed as xs:string? := $childNode/parent::*/basic:allowed/basic:value/fn:string(.)
                        return
                            element { "dynamic-xml" } {
                                formFunctions:getGroupName($childNode),
                                attribute seq { formFunctions:getNextSeqCount($seqCount) },
                                attribute title { ($childNode/basic:label/fn:string(.),$qName)[1] },
                                attribute name { fn:concat("xpath-hash32-",xdmp:hash32($xpath)) },
                                attribute add-label { ($childNode/basic:addLabel/fn:string(.)) },
                                attribute xpath { $xpath },
                                attribute class { "sortable" },
                                attribute collapsible { "true" },
                                if ($repeatClass) then ( attribute dlClass { $repeatClass } ) else (),
                                if ($dataMin) then ( attribute data-min {$dataMin} ) else(),
                                if ($dataMax) then ( attribute data-max {$dataMax} ) else(),
                                if ($allowed) then ( attribute allowed {$allowed} ) else(),
                                element { $qName } {
                                    attribute type { "array" },
                                    attribute its:translate { "no" },
                                    formFunctions:getLdsPubInput($childNode, $formTitle, $classes, "", ())
                                }
                            }
                        ) else if ( $typeChild eq 'static' ) then (
                            element { $qName } {
                                attribute its:translate { 'no' },
                                $childNode/basic:value/fn:string()
                            }
                        ) else (
                            element { $qName } {
                                if ($translate eq "no") then (
                                    attribute its:translate { 'no' }
                                )
                                else (),
                                if ($typeChild = ('wysiwyg', 'small-wysiwyg')) then(
                                    attribute type {"wysiwyg"}
                                ) else (),
                                formFunctions:getLdsPubInput($childNode, $formTitle, $classes, fn:concat($myPath, $localName, "/"), ())
                            }
                        )
                    )
                ) else if ( $ref ) then (
                    (: create a dynamic-form-ref to an another form if see _24_ref :)
                    let $formName as xs:string := $childNode/child::node()[fn:local-name(.) eq "_24_lds-pub-ref"]
                    let $formName as xs:string := fn:concat($formName, "-form")
                    return (
                        formFunctions:getDynamicForm($childNode, fn:replace($formName, "-", "_"), $myPath)
                    )

                ) else if ($childNode/fn:local-name(.) eq "group" or $childNode/fn:local-name(.) eq "region") then (
                    (: increment sequence number so next input will be the correct sequence with groups that may be present :)
                    let $parentGroupCnt as xs:integer := formFunctions:countParentGroups($childNode,xs:integer(0))
                    let $nop := if ($parentGroupCnt < 2) then (formFunctions:getNextSeqCount($seqCount)) else ()
                    return ()
                ) else if ($childNode/fn:local-name(.) eq "groupLabel") then (
                    element label { $childNode/fn:string(.) }
                ) else (
                    (: continue traversing the structure :)
                    let $qName as xs:QName := fn:QName("http://lds.org/code/lds-edit", $localName)

                    return (

                        if (fn:exists($childNode/basic:inputGroup) and $childNode/basic:inputGroup/fn:string(.) eq "true") then (

                            let $seqNum as xs:string := formFunctions:getNextSeqCount($seqCount)
                            let $hasInputGroupParent := fn:exists($childNode/ancestor::*/basic:inputGroup[fn:string(.) eq "true"])
                            let $hasDynamicParent := fn:exists($childNode/parent::*/basic:repeat[fn:string(.) eq "true"])
                            return
                                element { $qName } {
                                    attribute inputGroup {"true"},
                                    element input {
                                        attribute group { formFunctions:getGroupName($childNode) },
                                        attribute seq { $seqNum },

                                        (: when dynamic-xml is encountered in inputGroupFunctions, it calls buildDynamicInputs() herein which
                                           then traverses the children so we want that traversal to handle any inputGroup input naturally so
                                           we rig the inputGroup input with type="inputGroupFunctions:inputGroup"

                                           when publisher traverses the form naturally the first inputGroup input it encounters doesn't have any
                                           parents so we want it to call inputGroupFunctions:inputGroup for the first inputGroup encountered, and that
                                           function deals with any subsequent inputGroup inputs, ie, inputGroups that have parents, so we rig those
                                           (children) inputGroup inputs as an ordinary text input so they are not processed (as inputGroup inputs)
                                           during the natural form traversal. See also dynamicForms:builForm()
                                        :)
                                        attribute type {
                                            if ($hasDynamicParent) then ("inputGroupFunctions:inputGroupInput")
                                            else if ($hasInputGroupParent) then("text") else ("inputGroupFunctions:inputGroupInput")
                                        },

                                        (: this is used by inputGroupFunctions to handle an inputGroup that is in an inputGroup :)
                                        attribute actualType { if ($hasInputGroupParent) then("inputGroupFunctions:inputGroupInput") else ("") },

                                        (: need a unique name otherwise name would be 'inputGroup' for all inputGroup inputs and that won't work
                                           when publisher tries to match posted inputs to the form when building output xml :)
                                        attribute name { fn:concat(fn:replace($xpath,'/','-'),'-',xdmp:hash32(xdmp:path($node))) },

                                        attribute xpath { fn:concat($xpath,"/node()")},
                                        attribute title { ($childNode/basic:label/fn:string(.),"Select Input Group")[1] }
                                    },
                                    formFunctions:getLdsPubInputs($childNode, fn:concat($myPath, fn:concat($localName, "/")))
                                }

                        ) else if ( fn:exists($dynamic-template) ) then (
                            formFunctions:getDynamicFormRef($childNode, $myPath)
                        ) else if ( fn:exists($dynamic) ) then (

                            (: look for a child 'repeatClass' and use its value for the dlClass :)
                            let $repeatClass as xs:string? := $childNode/child::node()[fn:local-name(.) eq "repeatClass"]/fn:string(.)
                            let $dataMin as xs:string? := $childNode/parent::*:properties/parent::*/basic:dataMin/fn:string(.)
                            let $dataMax as xs:string? := $childNode/parent::*:properties/parent::*/basic:dataMax/fn:string(.)
                            let $allowed as xs:string? := $childNode/parent::*/basic:allowed/basic:value/fn:string(.)
                            return
                                element { "dynamic-xml" } {
                                    formFunctions:getGroupName($childNode),
                                    attribute seq { formFunctions:getNextSeqCount($seqCount) },
                                    attribute title { ($childNode/basic:label/fn:string(.),$localName)[1] },
                                    attribute name { fn:concat("xpath-hash32-",xdmp:hash32($xpath)) },
                                    attribute add-label { $childNode/basic:addLabel/fn:string(.) },
                                    attribute xpath { $xpath },
                                    attribute class { "sortable" },
                                    attribute collapsible { "true" },
                                    if ($repeatClass) then ( attribute dlClass { $repeatClass } ) else (),
                                    if ($dataMin) then ( attribute data-min {$dataMin} ) else(),
                                    if ($dataMax) then ( attribute data-max {$dataMax} ) else(),
                                    if ($allowed) then ( attribute allowed {$allowed} ) else(),
                                    element { $qName } {
                                        attribute type { "array" },
                                        formFunctions:getLdsPubInputs($childNode, "")
                                    }
                                }
                        ) else (
                            element { $qName } { formFunctions:getLdsPubInputs($childNode, fn:concat($myPath, fn:concat($localName, "/"))) }
                        )
                    )
                )
            )
        ) else (
            (: skip 'properties' element so it isn't included in the structure :)
            formFunctions:getLdsPubInputs($childNode, $myPath)
        )
    )
};

declare function formFunctions:getLdsPubForm(
    $jsonSchema as element(basic:json),
    $dataElementRootName as xs:string
) as element(ldse:formTemplate) {
    let $name as xs:string := $jsonSchema/basic:title
    let $title as xs:string := $jsonSchema/basic:title
    let $hasInputGroup as xs:boolean := fn:exists($jsonSchema//basic:inputGroup)
    let $formName as xs:string := fn:concat(fn:replace($name,"-","_"),"_form")

    return (
        <formTemplate schedule-publish="true" schedule-unpublish="true" name="{$formName}" workflow="true" search="true" created="{ fn:current-dateTime() }" schema-title="{ $title }" xmlns="http://lds.org/code/lds-edit">
            <title>{$title}</title>
            <document-title show="false">
                {($jsonSchema//basic:documentTitle/fn:string(), "doc-title/node()")[1]}
            </document-title>
            <image-path>(//img/@src)[1]</image-path>
            <file-prefix>{ fn:concat($name,"-") }</file-prefix>
            <folder>{$name}</folder>
            <functions>
                <function name="dynamicForms:clearNodeCache" namespace="http://lds.org/code/shared/lds-edit/dynamicForms" path="/ice/modules/dynamicForms.xqy"/>
                <function name="inputGroupFunctions:inputGroupInput" namespace="http://lds.org/code/lds-edit/modules/inputGroupFunctions" path="/modules/inputGroupFunctions.xqy"/>
                {
                    if ($jsonSchema/basic:contentSchemaType/fn:string(.) eq "regions_v1") then (
                        <function name="inputGroupFunctions:addActiveAttribute" namespace="http://lds.org/code/lds-edit/modules/inputGroupFunctions" path="/modules/inputGroupFunctions.xqy"/>
                    )
                    else (),

                    let $functionsToAdd as node()* := ($jsonSchema//basic:functions/*,  $jsonSchema//basic:functionDetails)
                    let $functionMap := map:map()
                    let $uniqueFunctions as node()* :=
                        for $entry in $functionsToAdd
                        return
                            if (fn:not(map:contains($functionMap, $entry//basic:function))) then (
                                let $_d := map:put($functionMap, $entry//basic:function, "")
                                return $entry
                            ) else ()

                    return
                        for $function in $uniqueFunctions
                        let $functionName as xs:string := $function/basic:function
                        let $functionNamespace as xs:string := $function/basic:namespace
                        let $functionPath as xs:string := $function/basic:path
                        return
                            element { 'function' } {
                                attribute { 'name' } { $functionName },
                                attribute { 'namespace' } { $functionNamespace },
                                attribute { 'path' } { $functionPath }
                            }
                }
            </functions>
            <post-processing>
                <function namespace="http://lds.org/code/shared/lds-edit/dynamicForms" name="dynamicForms:clearNodeCache"/>

                {
                    if ($jsonSchema/basic:contentSchemaType/fn:string(.) eq "regions_v1") then (
                        <function namespace="http://lds.org/code/lds-edit/modules/inputGroupFunctions" name="inputGroupFunctions:addActiveAttribute"/>
                    )
                    else (),

                    let $processes as node()* := $jsonSchema//basic:functions/*
                    return
                        for $process in $processes
                        let $processName as xs:string := $process/basic:function
                        let $processNamespace as xs:string := $process/basic:namespace
                        where $process/basic:postProcess eq "true"
                        return
                            element { 'function' } {
                                attribute { 'namespace' } { $processNamespace },
                                attribute { 'name' } { $processName }
                            }
                }
            </post-processing>
            <root-query>
                <cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts">
                    <cts:element>{$dataElementRootName}</cts:element>
                    <cts:attribute>id</cts:attribute>
                    <cts:text>$id</cts:text>
                    <cts:option>exact</cts:option>
                </cts:element-attribute-value-query>
                <cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts">
                    <cts:element>{$dataElementRootName}</cts:element>
                    <cts:attribute>locale</cts:attribute>
                    <cts:text>$locale</cts:text>
                    <cts:option>exact</cts:option>
                </cts:element-attribute-value-query>
                  <cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts">
                    <cts:element>{$dataElementRootName}</cts:element>
                    <cts:attribute>type</cts:attribute>
                    <cts:text>{$jsonSchema/basic:title/fn:string(.)}</cts:text>
                    <cts:option>exact</cts:option>
                </cts:element-attribute-value-query>
            </root-query>
            <javascript>
                {
                    if ($hasInputGroup) then (
                        <script src="{fn:concat($settings:cdn-path,'/cdn2/csp/ldspub/ldsorg/regions/scripts/regions_templates.min.js')}"></script>
                    )
                    else (),
                    for $jScripts in $jsonSchema//basic:scripts[@type eq "array"]/basic:json
                    return (
                        element { 'script' } {
                            attribute { 'type' } { $jScripts/basic:mediaType/fn:string(.) },
                            attribute { 'src' } { $jScripts/basic:source/fn:string(.) }
                        }
                    )
                }
            </javascript>
            <css>
                {
                    if ($hasInputGroup) then (
                        <link href="{fn:concat($settings:cdn-path,'/cdn2/csp/ldspub/ldsorg/regions/styles/regions_templates.min.css')}" rel="stylesheet"/>
                    )
                    else ()
                }
            </css>
            <groups>
            {
                (: get all group nodes and inputs, need inputs so we can get the sequence numbers correct below :)
                let $children as node()* := $jsonSchema//*
                let $groupsAndTypes as node()* := for $item in $children (: note: the last check for @type ne 'object' is for elements nodes that are named 'type' :)
                                                  let $localName as xs:string := $item/fn:local-name(.)
                                                  where (( ($localName eq "group" or $localName eq "region") or $localName eq "type") and $item/fn:string(.) ne "object" and $item/fn:string(.) ne 'static' and $item/@type ne "object")
                                                  return $item

                (: exclude groups that are second generation, ie, a group that has a parent with a group :)
                let $allowedGroupsAndInputs := for $groupAndType at $index in $groupsAndTypes
                                               let $localName as xs:string := $groupAndType/fn:local-name(.)
                                               where ($localName ne "group" and $localName ne "region") or ( ($localName eq "group" or $localName eq "region") and formFunctions:countParentGroups($groupAndType,xs:integer(0)) < 2)
                                               return $groupAndType

                (: now we have the final list where the allowed groups are ordered within the inputs :)                                                 
                return for $groupAndType at $index in $allowedGroupsAndInputs

                       let $groupLabel := $groupAndType/parent::*/child::*[fn:local-name(.) eq "label"]/fn:string(.)
                       let $groupParentName as xs:string := $groupAndType/parent::*/fn:local-name(.)
                       let $regionIndicator as xs:boolean := $groupAndType/fn:local-name(.) eq "region" and $groupAndType/fn:string(.) eq "true"
                       let $regionType as xs:string? := $groupAndType/parent::*/basic:regionType[./basic:type eq "static"]/basic:value/fn:string(.) (: require there be a child 'type' with value 'static' :)
                       let $regionRequired as xs:boolean := $groupAndType/fn:local-name(.) eq "region" and $groupAndType/parent::*/basic:required/fn:string(.) eq "true"
                       let $allowed as xs:string? := $groupAndType/parent::*/basic:allowed/basic:value/fn:string(.)
                       where ($groupAndType/fn:local-name(.) eq "group" or $groupAndType/fn:local-name(.) eq "region")
                       return (
                           element group {
                                attribute closed {"true"},
                                attribute name {$groupParentName},
                                attribute title {($groupLabel,$groupParentName)[1]},
                                attribute seq {$index},
                                if ($regionIndicator) then (attribute region {$regionIndicator}) else (),
                                if ($regionIndicator and fn:exists($regionType)) then (attribute regionType {$regionType}) else (),
                                if ($regionRequired) then (attribute required {"true"}) else (),
                                if ($allowed) then (attribute allowed {$allowed}) else ()
                           }
                       )
            }
            </groups>            
            <structure> {
                    element { $dataElementRootName } {

                        attribute xmlns:its { "http://www.w3.org/2005/11/its" },

                        <attribute name="id">
                            <input type="variable" value="$id" xpath="@id" options="variable"/>
                        </attribute>,
                        <attribute its:translate="no" name="uri">
                        {
                            if(($jsonSchema//basic:main/fn:string(.) eq "true") and ($settings:new-dynamic eq "true") and ($jsonSchema//basic:page-path/fn:string(.) eq "true"))
                            then 
                            (<input class="required" generate-from="{$jsonSchema/basic:uriSource/fn:string(.)}" data-root="{$jsonSchema/basic:uriRoot/fn:string(.)}" name="permalink" options="sanitize" seq="1" title="Page Path " type="text" value="{$jsonSchema/basic:uriRoot/fn:string(.)}" xpath="@uri"/>)
                            else 
                            (<input type="variable" value="$uri" xpath="@uri" options="variable"/>)
                        }
                        </attribute>,
                        <attribute name="locale">
                            <input type="variable" value="$locale" options="variable"/>
                        </attribute>,
                        <attribute name="xml:lang">
                            <input type="variable" value="$lang" options="variable"/>
                        </attribute>, 
                        <attribute name="status">
                            <input type="variable" value="$status" options="variable"/>
                        </attribute>,
                        <attribute name="type">{$jsonSchema/basic:title/fn:string(.)}</attribute>,
                        <attribute name="main">{$jsonSchema//basic:main/fn:string(.) eq "true"}</attribute>,                        
                        <attribute name="component-title">
                            { $jsonSchema/basic:title/fn:string(.) }
                        </attribute>,
                        <attribute name="contentSchemaType" >{ $jsonSchema/basic:contentSchemaType/fn:string(.) }</attribute>,

                        let $readOnlyUriInput as element(input)? := if ($jsonSchema/basic:contentSchemaType/fn:string(.) eq "regions_v1") then (
                                                                        let $pageLocationInputProperties as element(ldse:pageLocationInputProperties)? := $ldse-settings/ldse:pageLocationInputProperties
                                                                        where fn:exists($pageLocationInputProperties/excludeOnForms[./form/fn:string(.) eq $formName]) eq fn:false()
                                                                        return
                                                                            let $label as xs:string? := ($pageLocationInputProperties/label/fn:string(.),"Page Location")[1]
                                                                            return
                                                                                <input seq="0" type="text" name="readonly-uri" xpath="@uri" readonly="readonly" title="{$label}" options="constant"/>
                                                                    )
                                                                    else ()

                        (: look for an input named 'title', failing that an input with 'title' in the name, otherwise use the first input :)                        
                        let $inputs := formFunctions:getLdsPubInputs($jsonSchema, "")
                                              
                        (: this is needed to preserve the order of the generated inputs :)                                             
                        let $titleNames := for $item in $inputs
                                           return
                                               for $itemInput in $item//input
                                               where (fn:exists($itemInput[ancestor::dynamic-xml]) eq fn:false()) and ($itemInput/@name[fn:matches(fn:lower-case(.),'.*title.*')])
                                               return $itemInput/@name
                                               
                        let $inputNameToUse := ($titleNames[1],$inputs[1]//input/@name)[1]                                                
                        return (
                            $readOnlyUriInput,
                            element doc-title {
                                attribute its:translate { "no" },
                                element input {
                                    attribute type { "duplicate" },
                                    attribute name { $inputNameToUse },
                                    attribute xpath { "doc-title/node()" }
                                }
                            },
                            $inputs
                        )
                    }
            } </structure>
        </formTemplate>
    )
};

declare function formFunctions:createLdsPubForm(
    $jsonSchema as element(basic:json),
    $path as xs:string
) as element(root) {

    let $node as element(ldse:formTemplate) := formFunctions:getLdsPubForm($jsonSchema, "ldswebml")    
    let $formName as xs:string := $node/@name  
    let $uri as xs:string := fn:concat($path, $formName, ".xml")
    let $nop as item()* := xdmp:document-insert($uri, $node)                                          
    return (
        <root>
           <formName>{ $formName }</formName>
           <location>{ $uri }</location>
           <created>{ $node/@created/fn:string(.) }</created>
           <schema-title>{ $formName }</schema-title>
           <json-schema>{ $jsonSchema }</json-schema>
       </root>
   )
};
