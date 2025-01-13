xquery version "1.0-ml";

module namespace inputGroupFunctions = "http://lds.org/code/lds-edit/modules/inputGroupFunctions";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../ice/modules/dynamicForms.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "utility-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare function inputGroupFunctions:addActiveAttributeHelper($node) {

    for $currNode as node() in $node/node()[fn:local-name(.) ne "ldse-meta"]
    return
        if ($currNode/node()) then (

        (: if a parent input group exists and $currNode is the active component, then add an 'active' attribute to $currNode :)
        if ($currNode/parent::*/@inputGroup/fn:string(.) eq "true") then (
            let $activeInputGroup as xs:string? := fn:tokenize(fn:normalize-space($currNode/parent::*/text()[1]),":")[last()]
            return
                if (fn:local-name($currNode) eq $activeInputGroup) then (
                    let $attributes := if (fn:exists($currNode/@active)) then ($currNode/attribute::*) else ($currNode/attribute::*,attribute active {"true"})
                    return
                        element { fn:local-name($currNode)} {$currNode/namespace::*,$attributes,inputGroupFunctions:addActiveAttributeHelper($currNode)}
                )
                else (
                    (: don't return the child because it's inactive and just adds empty contentm, but keep this in case we want to implement logic to have it both ways :)
                    (: element { fn:local-name($currNode)} {$currNode/namespace::*,$currNode/attribute::*,inputGroupFunctions:addActiveAttributeHelper($currNode)} :)
                )
        )
        else (
            element { fn:local-name($currNode)} {$currNode/namespace::*,$currNode/attribute::*,inputGroupFunctions:addActiveAttributeHelper($currNode)}
        )
        )
        else (
            $currNode
        )
};

declare function inputGroupFunctions:addActiveAttribute(
        $origFile,
        $newXml,
        $form
) {
    (: if we process ldse-meta normally, then a second copy gets put back in somewhere later on so save the
       original and restore it below, probably related to the namespace that is defined in-line in ldse-meta :)
    let $metaBefore := $newXml/ldse:ldse-meta

    (: now re-construct the root node with the correct namespace (which is no namespace) and attributes :)
    let $result := inputGroupFunctions:addActiveAttributeHelper($newXml)
    let $qName := fn:QName("","ldswebml")
    let $result2 := element {$qName} { $newXml/attribute::*, ($metaBefore,$result) }
    return $result2
};

declare function inputGroupFunctions:getComponentId(
    $component as node()
) as xs:string {

    let $tokens as xs:string* := fn:tokenize(fn:replace(xdmp:path($component),"ldse:",""),"/")
    let $final as xs:string := fn:concat("active-component:",$tokens[fn:last()])
    return $final
};

declare function getComponentInputsDefaultHelper(
    $componentChild as node(),
    $file as element()?,
    $index as xs:string?
) as element()* {

    (: todo: change from component to something else :)
    if ($componentChild/ldse:input/@type/fn:string(.) eq "inputGroupFunctions:inputGroupInput" or
        $componentChild/ldse:input/@actualType/fn:string(.) eq "inputGroupFunctions:inputGroupInput") then (

        inputGroupFunctions:getGroupInputDefault($componentChild/ldse:input,$file,$index)
    )
    else (

        if (fn:local-name($componentChild) eq "dynamic-xml") then (

            let $formTemplate as node()? := fn:root($componentChild)
            let $fakeTemplate as element(ldse:formTemplate) := element ldse:formTemplate {

                attribute name { "unusedFakeName" }, (: make sure a name attribute is there, it gets lost during recursion and won't work without it :)

                for $attr as node() in $formTemplate/ldse:formTemplate/attribute::*
                where $attr/fn:local-name(.) ne "name"
                return (attribute { fn:QName(fn:namespace-uri($attr),$attr/fn:local-name(.)) } { $attr/fn:string(.) }),

                element ldse:structure {
                    element ldse:ldswebml {
                        $componentChild
                    }
                }
            }

            return
                form:buildDynamicInputs(
                        $fakeTemplate/ldse:structure/ldse:ldswebml/ldse:dynamic-xml,
                        $file,
                        $index)
        )
        else if ( (fn:exists($componentChild/ldse:input) eq fn:false()) and (fn:exists($componentChild/child::*) eq fn:true())) then (

            (: recursively traverse through children :)
            for $child as node() in $componentChild/child::*
            return inputGroupFunctions:getComponentInputsDefaultHelper($child,$file,$index)
        )
        else if (fn:local-name($componentChild/child::*) eq "input") then (

            form:buildInput(
                element ldse:input {

                    (: copy attributes :)
                    for $attr in $componentChild/ldse:input/attribute::*
                    return (attribute { fn:QName(fn:namespace-uri($attr),$attr/fn:local-name(.)) } { $attr/fn:string(.) }),

                    (: copy options :)
                    if ($componentChild/ldse:input/ldse:option) then (
                        for $option in $componentChild/ldse:input/ldse:option
                        return element ldse:option {
                            attribute value {$option/@value/fn:string(.)},
                            $option/fn:string(.)
                        }
                    )
                    else ()
                },
                $file,
                $index
            )
        )
        else (

            (: else, we can't handle whatever the child is so just ignore it... we could call
           this but it may not work right if there is a child we couldn't handle above
           form:buildForm($componentChild/child::*,$file,$index) :)
        )
    )
};

declare function inputGroupFunctions:getGroupsInputsDefault(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?,
    $selectedValue as item()*
) as element(div)* {

    (: todo: rename component to group or inputGroup :)
    for $component as node() in $input/following-sibling::*
    let $class as xs:string := inputGroupFunctions:getComponentId($component)

    (: todo: rename component--active to group--active :)
    let $style as xs:string := if ($class eq $selectedValue) then ("component component--active") else ("component")
    let $class as xs:string := fn:concat($class," ",$style)
    return
        <div class="{$class}">
            {
                (: todo: rename :)
                for $componentChild in $component/child::*
                return (
                    inputGroupFunctions:getComponentInputsDefaultHelper($componentChild,$file,$index)
                )
            }
        </div>
};

declare function inputGroupFunctions:getGroupInputDefaultHelper(
    $selectNameAndId as xs:string,
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(div)* {

    let $selectedValue as item()* := form:dynamicXpath($file,xs:string($input/@xpath))
    return (

        <div class="ldse-region__item">
            <dl class="ldse-region__item__select" data-group="{$input/@group/fn:string(.)}" data-sequence="{$input/@seq}" > 
                <dt class="label">
                    <label for="{$selectNameAndId}">{$input/@title/fn:string(.)}</label> 
                </dt> 
                <dd> 
                    <select type="select" class="select-region xxxl" name="{$selectNameAndId}" id="{$selectNameAndId}"> 
                        {
                            if ($input/@required/fn:string(.) eq "true") then () else (<option value="none">None</option>),

                            (: todo: rename component to group :)
                            for $component in $input/following-sibling::*
                            let $label as xs:string? := ($component/ldse:label/fn:string(.),$component/fn:local-name(.))[1]
                            let $dataComponent as xs:string? := if ($component/ldse:component) then ($component/ldse:component/fn:string(.)) else ()
                            let $normalizedSelectValue as xs:string* := for $string as xs:string in $selectedValue return fn:normalize-space($string)
                            return if ($normalizedSelectValue eq inputGroupFunctions:getComponentId($component)) then (
                                <option selected="selected" value="{inputGroupFunctions:getComponentId($component)}" data-component="{$dataComponent}">{$label}</option>
                            )
                            else (
                                    <option value="{inputGroupFunctions:getComponentId($component)}" data-component="{$dataComponent}">{$label}</option>
                                )
                        }
                    </select> 
                 </dd> 
            </dl> 
            <div class="ldse-region__item__forms">
            {
                inputGroupFunctions:getGroupsInputsDefault($input,$file,$index,$selectedValue)
            }
            </div>
        </div>
    )
};

(: for dynamic-xml, finds the locations in the document for $file, which is a snippit of the document with attribute type="array"
   if $file is the 2nd of 3 siblings, then this returns 2, if $file is in the second parent group of 3 and the 3rd of it's siblings
    then this would return 2,3 The values are then appended to the name attribute and needed by javascript on the rendered form template :)
declare function inputGroupFunctions:findLocation(
    $file as element()?
) as xs:string* {

    if (fn:exists($file)) then (

        let $doc as node()? := fn:root($file)
        let $elementNames := fn:subsequence(fn:remove(fn:tokenize(xdmp:path($file),'/'),1),1)
        return for $elementName as xs:string at $index in $elementNames
               let $currPath as xs:string? := fn:string-join(fn:subsequence($elementNames,1,$index),'/')
               let $currElement as element()? := util:value($doc,$currPath)

               return if ($currElement/@type/fn:string(.) eq "array") then (
                          if (fn:ends-with($currPath,']'))
                          then (fn:substring-before(fn:substring-after($elementName,'['),']'))
                          else ("1")
                      )
                      else ()
    )
    else ()
};

declare function inputGroupFunctions:getGroupInputDefault(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as item()* {

    let $dynamicXml as element(ldse:dynamic-xml)? := $input/ancestor::ldse:dynamic-xml[1] (: could be more than one, get the closest :)

    (: find the location of $file in it's sublings and append that index onto the name for the inputGroup selector :)
    let $location as xs:string* := findLocation($file)
    let $location as xs:string? := if (fn:exists($location)) then (fn:string-join($location,'-')) else ()
    let $result as xs:string? := $location

    let $selectNameAndId as xs:string := if (fn:exists($result))
                                         then (fn:concat($input/@name/fn:string(.),"-",$result))
                                         else if (fn:exists($dynamicXml))
                                              then (fn:concat($input/@name/fn:string(.),"-",$index))
                                              else ($input/@name/fn:string(.))
    return (
       inputGroupFunctions:getGroupInputDefaultHelper($selectNameAndId,$input,$file,$index)
    )
};

declare function inputGroupFunctions:inputGroupInput(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as item()* {

    inputGroupFunctions:getGroupInputDefault($input,$file,$index)
};