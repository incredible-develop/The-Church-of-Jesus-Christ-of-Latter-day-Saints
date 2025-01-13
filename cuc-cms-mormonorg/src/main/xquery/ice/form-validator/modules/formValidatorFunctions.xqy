xquery version "1.0-ml";

module namespace formValidatorFunctions = "http://lds.org/code/shared/lds-edit/formValidatorFunctions";

import module namespace functx = 'http://www.functx.com' at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare private variable $errorMap as map:map := map:map();
declare private variable $warningMap as map:map := map:map();

declare private variable $defaultSuccessMsg as xs:string := "";
declare private variable $defaultErrorMsg as xs:string := "Failed Validation";

declare private variable $thisNameSpace as xs:string := "http://lds.org/code/shared/lds-edit/formValidatorFunctions";

declare variable $RULE_ERROR as xs:string := "error";
declare variable $RULE_WARNING as xs:string := "warning";

declare private variable $ruleData as element(ruleData)*:=
    (<ruleData type="{$RULE_ERROR}" seq="1"><title>Unique &lt;input&gt; Names</title>
              <desc> The name attribute for each
              input element that is not of type "variable" or "duplicate" must be unique.</desc>
              <failMsg></failMsg>
              <functionName>checkUniqueInputNames</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="2"><title>Non-Unique Duplicate Names</title>
              <desc>Input Elements of type "duplicate" should have a name that matches another name attribute on an input element.</desc>
              <failMsg></failMsg>
              <functionName>checkUniqueDuplicateNames</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="3"><title>Input Type Attributes</title>
              <desc>Every input element must have a type attribute.</desc>
              <failMsg></failMsg>
              <functionName>inputTypeAttributes</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="4"><title>One-Child Structure Element</title>
              <desc>Form must contain a structure element with a single child.</desc>
              <failMsg>Form must contain a structure element with a single child.</failMsg>
              <functionName>validStructure</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="5"><title>Unique Input IDs</title>
              <desc>If an input contains an ID it must be unique.</desc>
              <failMsg></failMsg>
              <functionName>uniqueInputIds</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="5"><title>Wysiwyg Within Dynamic-xml</title>
              <desc>A wysiwyg shouldn't have an id when its within a dynamic-xml.</desc>
              <failMsg></failMsg>
              <functionName>wysiwygWithIdInDynamicXml</functionName>
    </ruleData>,
    
    <ruleData type="{$RULE_ERROR}" seq="6"><title>Undefined Functions</title>
              <desc>Attempting to use function that is never declared.</desc>
              <failMsg></failMsg>
              <functionName>undefinedFunctionUse</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="7"><title>Spaces in Option Attribute</title>
              <desc>Options attribute on input elements must be a comma seperated list (no spaces).</desc>
              <failMsg></failMsg>
              <functionName>noSpaceOptions</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="8"><title>Name Attribute Elements</title>
              <desc>Every &lt;attribute&gt; element must have a name attribute.</desc>
              <failMsg></failMsg>
              <functionName>namedAttributes</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9"><title>Attribute Children</title>
              <desc>Attribute elements can only contain input elements and text.</desc>
              <failMsg></failMsg>
              <functionName>attributeChildren</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9a"><title>No Nested Dynamic XML Support</title>
              <desc>&lt;dynamic-xml&gt; within a &lt;dynamic-xml&gt; is not currently supported</desc>
              <failMsg></failMsg>
              <functionName>nestedDynamicXML</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9b"><title>Dynamic XML Missing xpath Attribute</title>
              <desc>Every &lt;dynamic-xml&gt; element must have an xpath attribute.</desc>
              <failMsg></failMsg>
              <functionName>dynamicXMLXPathAttribute</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9c"><title>Type Select Needs Options or Function call</title>
              <desc>Inputs with type='select' either need &lt;option&gt; children or &lt;dynamic-option&gt; with call to function.</desc>
              <failMsg></failMsg>
              <functionName>typeSelectNeedsOptionsOrFunction</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9d"><title>Root Query Elements - cts Namespace</title>
              <desc>All elements in root-query must have cts namespace.</desc>
              <failMsg></failMsg>
              <functionName>rootQueryCtsNamespace</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9d"><title>Previous &lt;attribute&gt; Siblings</title>
              <desc>Attribute elements cannot follow other elements, they have to be the first children elements under the parent.</desc>
              <failMsg></failMsg>
              <functionName>previousAttributeSiblings</functionName>
    </ruleData>,
    <ruleData type="{$RULE_ERROR}" seq="9e"><title>Structure Namespace Attributes</title>
              <desc>Structure elements should never have a prefix or xmlns attribute - only ldse-prefix/namespace.</desc>
              <failMsg></failMsg>
              <functionName>structureNameSpace</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0a"><title>Tidy wysiwyg and ldswebml</title>
              <desc>It is highly recommended that input with type "wysiwyg" and "ldswebml" have one of the following options: "tidy", "xml", "html", or "xhtml".</desc>
              <failMsg>There were inputs of type wysiwyg and/or ldswebml with out an option of "tidy", "xml", "html", or "xhtml".</failMsg>
              <functionName>tidyOption</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0b"><title>Image Upload Option</title>
              <desc>Inputs of type image should have an imageUpload option.</desc>
              <failMsg>Found inputs of type image that did not have upload option.</failMsg>
              <functionName>imageUpload</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0c"><title>PDF Upload Option</title>
              <desc>Inputs of type pdf should have an pdfUpload option.</desc>
              <failMsg></failMsg>
              <functionName>pdfUpload</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0d"><title>DatePicker missing data-format Attribute</title>
              <desc>All the inputs of type datePicker should have a data-format attribute.</desc>
              <failMsg></failMsg>
              <functionName>datePickerMissingDataFormat</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0e"><title>Dynamic-xml missing title attribute.</title>
              <desc>Every dynamic-xml attribute should have a title attribute.</desc>
              <failMsg></failMsg>
              <functionName>dynamicXmlMissingTitleAttribute</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0f"><title>Leading Slash X-Paths</title>
              <desc>None of the xpath attributes on input elements should have a leading slash.</desc>
              <failMsg></failMsg>
              <functionName>xPathLeadingSlash</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0g"><title>Root-query $id Variable</title>
              <desc>The $id variable should be used in the root-query element - inside of a cts:text element.</desc>
              <failMsg></failMsg>
              <functionName>rootQueryId</functionName>
    </ruleData>,
    <ruleData type="{$RULE_WARNING}" seq="0h"><title>Unique Seq Attributes</title>
              <desc>The seq attributes on input elements should be unique. Dynamic-xml tags have their own
              unique seq sets.</desc>
              <failMsg></failMsg>
              <functionName>uniqueSeqAttributes</functionName>
    </ruleData>
    
);

declare function  getDynamicForms() as element(ldse:formTemplate)* {
    (: Perhaps change this to cts:search later :)
    cts:search(/ldse:formTemplate,
        core:get-filter-query()
    )[@name and @name != ""]
};

declare function getFormByName($name as xs:string) as element(ldse:formTemplate) {   
    cts:search(/ldse:formTemplate,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:formTemplate'), xs:QName('name'), $name, 'exact')
        ))
    )
};


declare private function getFunction($functionName as xs:string) as xdmp:function {
    getFunction($functionName,"formValidatorFunctions",$thisNameSpace)
};

declare function getFunction($functionName as xs:string, $functionPrefix as xs:string,$functionNameSpace as xs:string) as xdmp:function{
    xdmp:function(fn:QName($functionNameSpace,fn:concat($functionPrefix,":",$functionName)))
};


(: Loops through all the rules and returns validation objects for form :) 
declare function validateForm($form as element(ldse:formTemplate)) as element(validationInfo){
    <validationInfo>{    
        let $ruleValidations as element(ruleValidation)* := 
            for $rule as element(ruleData) in $ruleData                               
            return(validateRule($form,$rule))        
        return(
            for $ruleValidation as element(ruleValidation) in $ruleValidations
            order by if($ruleValidation/success="true") then(3) 
                    else if($ruleValidation/type=$RULE_ERROR) then (1)
                    else(2)
                    ,$ruleValidation/ruleSeq
                    
            
            return($ruleValidation/content),
            <successCount>{fn:count($ruleValidations[success = "true" and fn:string(type) eq $RULE_ERROR])}</successCount>,
            <failCount>{fn:count($ruleValidations[success eq "false" and fn:string(type) eq $RULE_ERROR])}</failCount>,
            <warnCount>{fn:count($ruleValidations[success eq "false" and fn:string(type) eq $RULE_WARNING])}</warnCount>,
            <map>{$errorMap}</map>,
            <warningMap>{$warningMap}</warningMap>
        )
        
    }</validationInfo>
};

(: When "all" is passed in as the rule function then it performs the check on the entire form 
    Assumption that ruleFunction is string that matches function :) 
declare function validateFormWithRule($form as element(ldse:formTemplate), $ruleFunction as xs:string)as element(validationInfo){
    if ($ruleFunction eq "all") then(
        validateForm($form)
    ) else (
        <validationInfo>{    
            let $rule as element(ruleData) := $ruleData[fn:string(functionName) eq $ruleFunction] 
            let $ruleValidation as element(ruleValidation) := validateRule($form,$rule)        
            return(           
                $ruleValidation/content,
                <map>{$errorMap}</map>,
                <warningMap>{$warningMap}</warningMap>
            )
        }</validationInfo>
    )
};
  
declare private function validateRule($form as element(ldse:formTemplate), $rule as element(ruleData))  as element(ruleValidation){
    let $ruleTitle as xs:string := $rule/title
    let $ruleDesc as xs:string := $rule/desc
    let $ruleSeq as xs:string := $rule/@seq
    let $ruleType as xs:string := $rule/@type
    let $functionName as xs:string := $rule/functionName
    let $ruleFunction as xdmp:function := getFunction($functionName)
    let $valid as element(validationResults) := xdmp:apply($ruleFunction, $form,$rule)
    let $head as element(h4) :=  <h4> <b>{$ruleTitle}</b> - <i>{$ruleDesc} </i> </h4>  
    return(
        <ruleValidation>
           <content>
                <div>{
                    if($ruleType eq $RULE_ERROR) then(
                        if($valid/valid eq "true") then(
                            <span class="sprite check prefix">{$head}</span>
                        ) else (
                            <span class="sprite stop prefix">{$head}</span>,
                            <p class="failText">{$valid/return-message/*}</p>
                        )
                    ) else if($ruleType eq $RULE_WARNING) then(                    
                        if($valid/valid eq "true") then (
                            (: Warning passed - don't display :)
                        ) else(
                            <span class="sprite warning prefix">{$head}</span>,
                            <p class="warnText">{$valid/return-message/*}</p>
                        )
                    ) else()
                 }</div>
            </content>
             <success>{fn:string($valid/valid)}</success>
             <type>{fn:string($rule/@type)}</type>         
             <ruleSeq>{$ruleSeq}</ruleSeq>
        </ruleValidation>
    )
       
};

declare private function getValidResults($valid as xs:boolean, $msg as item()*) as element(validationResults){
    <validationResults>
        <valid>{$valid}</valid>
        <return-message>{$msg}</return-message>
    </validationResults>
};






declare function getTitle($form as element(ldse:formTemplate)) as element(ldse:title){
     if (fn:exists($form/ldse:title)) then(
         $form/ldse:title
     ) else (
         <ldse:title>{ fn:string($form/@name) }</ldse:title>
     )
};

declare function getFormList($forms as element(ldse:formTemplate)*) as element(ul){
    <ul id="dynamic-form-list">{
          for $form as element(ldse:formTemplate) in $forms
          let $title as xs:string? := getTitle($form)
          let $formName as xs:string := $form/@name
          order by $title
          return (
             <li>{
                 (: Perform check for duplicate form name here :)
                 if(fn:count($forms[@name = $formName]) lt 2) then (
                     <a id="{$formName}" onclick="displayData(this)" href='#'>
                     {$title}
                     </a>,
                     <span>&nbsp;</span>,
                     <span id="failCount_{$formName}" class="failText">                                     
                     &nbsp;</span>,
                     <span id="warnCount_{$formName}" class="warnText">&nbsp;</span>
                 ) else(
                     <span class="failText">{fn:string($title)} -- Critical Error! (Duplicate Form Name )</span>
                 
                 )
             }</li>
         )
    }</ul>
};

declare function getFormListNoNameSpace() as element(div)? {
    let $forms as element(formTemplate)* := cts:search(/formTemplate, core:get-filter-query())
    return(
        if(fn:count($forms) gt 0) then(
            <div>
                <hr />
                <h3>The following forms were missing the lds-edit namespace:</h3>
                <ul>{
                    for $form as element(formTemplate) in $forms
                    let $title as element(title)? := $form/title
                    let $formName as xs:string := $form/@name
                    return (<li class="sprite stop prefix">                     
                                 {fn:string($title)} <i>(Missing Namespace)</i> 
                             </li>,<br></br>)
                }</ul>
            </div>
          ) else()
    )
};

declare private function insertIntoErrorMap($form as element(ldse:formTemplate),$errorElements as element()*) as empty-sequence(){
     insertIntoMap($errorMap,$form,$errorElements)
};

declare private function insertIntoWarningMap($form as element(ldse:formTemplate),$warningElements as element()*) as empty-sequence(){
     insertIntoMap($warningMap,$form,$warningElements)
};

declare private function insertIntoMap($map as map:map, $form as element(ldse:formTemplate), $elements as element()*) as empty-sequence(){
     let $key as xs:string := $form/@name
     let $oldValue as xs:string* := map:get($map,$form/@name)
     let $newValue as xs:string* := ($oldValue,xdmp:path($elements))
     return( map:put($map,$key,$newValue))
};

declare function getErrorPaths($map as element(map:map)?, $key as xs:string) as xs:string*{
    let $entry as element(map:entry)? := $map/map:entry[@key eq $key]
    return $entry/map:value  
};

declare private function failLink($functionName as xs:string,$type as xs:string) as element(span){
   if ($type eq $RULE_ERROR) then (
        <span onclick="displayRuleErrorXML(this)" class="failRule sprite page prefix" id="{$functionName}">( View XML )</span>
   ) else (
        <span onclick="displayRuleWarningXML(this)" class="failRuleWarn sprite page prefix" id="{$functionName}">( View XML )</span>
   )
};

declare private function makeElementList($elements as element()*) as element(ul){
    <ul>{                    
        for $element as element() in $elements
        return (<li>{xdmp:quote($element)}</li>)
    }</ul>
};

declare private function failRuleContent($form as element(ldse:formTemplate),$rule as element(ruleData),$failElements as element()*) as item()*{
     let $ruleType as xs:string := $rule/@type
     let $descClass as xs:string := if($ruleType eq $RULE_ERROR) then ("failErrorDescription") else ("failWarnDescription")
     return(
         failLink(fn:string($rule/functionName),$ruleType),
         if ($ruleType eq $RULE_ERROR) then (
             insertIntoErrorMap($form,$failElements)
         ) else(
             insertIntoWarningMap($form,$failElements)
         ),
         if($rule/failMsg ne "") then(
             <div class="{$descClass}">
                  <span class="failMsg" >{fn:string($rule/failMsg)}</span>              
             </div>
         ) else()
    )    
};

(:
*************************************************************************
    ~~~RULE VALIDATION FUNCTIONS~~~
    Each of these function takes a form as a parameter,
    applies some type of validation check,
    then returns a validationResults element.
    The validationResults element containes two pieces of info:
      <valid>Boolean</valid>
      <return-message> String </return-message>
      Use the getValidResults($valid,$msg) function to format
*************************************************************************   
:)

(:Rule 1 - checking unique name on input elements :)
declare private function checkUniqueInputNames($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $requiredUniqueNameInputs as element(ldse:input)* := $form//ldse:input[@name ne "" and @type ne "variable" and @type ne "duplicate"]
    let $inputNames as xs:string* := $requiredUniqueNameInputs/@name
    let $duplicateNames as xs:string* := functx:non-distinct-values($inputNames)
    let $duplicateInputs as element(ldse:input)* := 
        for $requiredUniqueInput as element(ldse:input) in $requiredUniqueNameInputs
        where $requiredUniqueInput/@name = $duplicateNames
        return ($requiredUniqueInput)
    let $valid as xs:boolean := fn:not(fn:exists($duplicateNames))
    let $msg as item()* := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$duplicateInputs) )  
    return( getValidResults($valid,$msg) )
};


(:Rule 2 - ensure that inputs of type duplicate have match :)
declare private function checkUniqueDuplicateNames($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $namedInputs as element(ldse:input)* := $form//ldse:input[@name ne ""]
    let $typeDuplicateInputs as element(ldse:input)* := $namedInputs[@type eq "duplicate"]
    let $typeNonDuplicateInputs as element(ldse:input)* := $namedInputs[@type ne "duplicate"]
    let $nonMatchingDuplicates as element(ldse:input)* :=
        for $typeDuplicateInput as element(ldse:input) in $typeDuplicateInputs
        where fn:not($typeDuplicateInput/@name = $typeNonDuplicateInputs/@name)
        return $typeDuplicateInput
    let $valid as xs:boolean := fn:empty($nonMatchingDuplicates)
    let $msg as item()*  :=  if($valid) then ($defaultSuccessMsg) else( failRuleContent($form,$rule,$nonMatchingDuplicates) )
    return(getValidResults($valid,$msg))
};


declare private function inputTypeAttributes($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $nonTypedInputs as element(ldse:input)* := $form//ldse:input[@type eq "" or fn:not(@type)]
    let $valid as xs:boolean := fn:empty($nonTypedInputs)
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$nonTypedInputs) )
    return(getValidResults($valid,$msg))
};

declare private function validStructure($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $structureExists as xs:boolean := fn:exists($form/ldse:structure)
    let $singleChild as xs:boolean := fn:count($form/ldse:structure/*) eq 1
    let $valid as xs:boolean := $structureExists and $singleChild
    let $errorElements as element()* :=  $form/ldse:structure/*   
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$errorElements) )
    return(getValidResults($valid,$msg))
};

declare private function uniqueInputIds($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $inputs as element(ldse:input)* := $form//ldse:input
    let $ids as xs:string* := $inputs/@id
    let $nonUniqueIds as xs:string* := functx:non-distinct-values($ids)
    let $nonUniqueIdInputs as element(ldse:input)* := $inputs[@id = $nonUniqueIds]
    let $valid as xs:boolean := fn:not(fn:exists($nonUniqueIdInputs))    
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else( failRuleContent($form,$rule,$nonUniqueIdInputs) )
    return(getValidResults($valid,$msg))
};

declare private function wysiwygWithIdInDynamicXml($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $inputs as element(ldse:input)* := $form//ldse:dynamic-xml//ldse:input[@id and @type = ("wysiwyg", "ldswebml")]
    let $valid as xs:boolean := fn:empty($inputs)   
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else( failRuleContent($form,$rule,$inputs) )
    return(getValidResults($valid,$msg))
};

declare private function undefinedFunctionUse($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $declaredFunctionNames as xs:string* := $form/ldse:functions/ldse:function/@name
    (: Find Elements with function attributes :)
    let $usedFunctionElements as element()* := $form//*[@function ne ""]
    (: Find inputs with type attribute that contain a colon (indicates function name) :)
    let $inputs as element(ldse:input)* := $form//ldse:input 
    let $inputTypeFunctionElements as element(ldse:input)* := 
        for $input as element(ldse:input) in $inputs
        where fn:matches($input/@type, '.*[:].*') and fn:not($input/@type = $declaredFunctionNames)
        return ($input)
    let $inputOptions as xs:string* := $inputs[@options ne ""]/@options
    let $inputOptions as xs:string* :=
        for $inputOption as xs:string in $inputOptions
        return fn:tokenize($inputOption,",")
    let $inputOptionFunctions as xs:string* := 
        for $inputOption as xs:string in $inputOptions
        where fn:matches($inputOption ,".*[:].*")
        return $inputOption
    (: Remove any that are defined - left with undefined function options :)
    let $inputOptionFunctions as xs:string* :=
        for $inputOptionFunction as xs:string in $inputOptionFunctions
        where fn:not($inputOptionFunction = $declaredFunctionNames)
        return $inputOptionFunction
    let $inputOptionFunctionElements as element()* :=
        for $input as element() in $inputs
        where ( for $option as xs:string* in fn:tokenize($input/@options,",")
                return $option = $inputOptionFunctions )
        return $input
    (: append input with type="some:function" to functionElements :)
    let $usedFunctionElements as element()* := ($usedFunctionElements,$inputTypeFunctionElements,$inputOptionFunctionElements) 
    let $usedFunctionNames as xs:string* := $usedFunctionElements/@function
    let $usesUndefinedFunctionElements as element()* := 
        for $usedFunctionElement as element() in $usedFunctionElements
        where fn:not($usedFunctionElement/@function = $declaredFunctionNames)
        return($usedFunctionElement)
    let $valid as xs:boolean := fn:empty($usesUndefinedFunctionElements)    
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$usesUndefinedFunctionElements) )
    return(getValidResults($valid,$msg))
};

declare private function noSpaceOptions($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $options as xs:string* := $form//ldse:input[@options ne ""]/@options
    let $optionsWithSpaces as xs:string* :=
        for $option as xs:string in $options
        where fn:matches($option, " " )
        return $option
    let $inputsWithOptionsSpaces as element(ldse:input)* :=
        for $input as element(ldse:input)* in $form//ldse:input
        where $input/@options = $optionsWithSpaces
        return $input
    let $valid as xs:boolean := fn:empty($inputsWithOptionsSpaces) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$inputsWithOptionsSpaces) )
    return(getValidResults($valid,$msg))
};

declare private function namedAttributes($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $attributes as element(ldse:attribute)* := $form//ldse:attribute
    let $unNamedAttributes as element(ldse:attribute)* := $attributes[@name eq "" or fn:not(@name)]
    let $valid as xs:boolean := fn:empty($unNamedAttributes) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$unNamedAttributes) )
    return(getValidResults($valid,$msg))
};


declare private function attributeChildren($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $attributeChildren as element()* := $form//ldse:attribute/*
    let $invalidChildren as element()* := 
        for $attributeChild as element() in $attributeChildren
        where fn:local-name($attributeChild) ne "input"
        return $attributeChild
    let $valid as xs:boolean := fn:empty($invalidChildren) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else ( failRuleContent($form,$rule,$invalidChildren) )
    return(getValidResults($valid,$msg))
};

declare private function nestedDynamicXML($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $dynamicXMLElements as element(ldse:dynamic-xml)* := $form//ldse:dynamic-xml
    let $dynamicXMLChildren as element()* := $dynamicXMLElements//*
    let $nestedXML as element(ldse:dynamic-xml)* := 
        for $child as element() in $dynamicXMLChildren
        where fn:local-name($child) eq "dynamic-xml"
        return $child
    let $valid as xs:boolean := fn:empty($nestedXML) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else (failRuleContent($form,$rule,$nestedXML))
    return(getValidResults($valid,$msg))
};

declare private function dynamicXMLXPathAttribute($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $dynamicXMLElements as element(ldse:dynamic-xml)* := $form//ldse:dynamic-xml
    let $dynamicXMLMissingXPath as element(ldse:dynamic-xml)* := $dynamicXMLElements[@xpath eq "" or fn:not(@xpath)]
    let $valid as xs:boolean := fn:empty($dynamicXMLMissingXPath) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else( failRuleContent($form,$rule,$dynamicXMLMissingXPath))
    return(getValidResults($valid,$msg))
};

declare private function typeSelectNeedsOptionsOrFunction($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $typeSelectInputs as element(ldse:input)* := $form//ldse:input[@type = "select"]
    let $invalidInputs as element(ldse:input)* :=
        for $typeSelectInput as element(ldse:input) in $typeSelectInputs
        let $optionsFound as xs:boolean := fn:exists($typeSelectInput/ldse:option)
        let $dynamicOptions as xs:boolean := fn:exists($typeSelectInput/ldse:dynamic-options[@function ne ""])
        where fn:not($optionsFound) and fn:not($dynamicOptions)
        return $typeSelectInput
    let $valid as xs:boolean := fn:empty($invalidInputs) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$invalidInputs))
    return(getValidResults($valid,$msg))
};

declare private function rootQueryCtsNamespace($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $rootQuery as element(ldse:root-query)* := $form/ldse:root-query
    let $children as element()* := $rootQuery//cts:*
    let $nonNameSpaced as element()* := $rootQuery//*[ fn:not(self::cts:*) ]
    let $valid as xs:boolean := fn:exists($children) and fn:empty($nonNameSpaced) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else( failRuleContent($form,$rule,$nonNameSpaced) )
    return(getValidResults($valid,$msg))
};

declare private function previousAttributeSiblings($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $attributes as element(ldse:attribute)* := $form/ldse:structure//ldse:attribute
    let $invalidAttributes as element(ldse:attribute)* := $attributes[ preceding-sibling::*[fn:not(self::ldse:attribute)]]
    let $valid as xs:boolean := fn:empty($invalidAttributes) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$invalidAttributes))
    return(getValidResults($valid,$msg))
};

declare private function structureNameSpace($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $invalidNameSpaceElements as element()* := $form/ldse:structure//*[ fn:namespace-uri-from-QName(fn:node-name(.)) ne "http://lds.org/code/lds-edit" or fn:exists(fn:prefix-from-QName(fn:node-name(.)))]
    let $valid as xs:boolean := fn:empty($invalidNameSpaceElements) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$invalidNameSpaceElements))
    return(getValidResults($valid,$msg))
};

(:
________________________________________
        Warning Functions
________________________________________

:)

declare private function tidyOption($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $wysiwygInputs as element(ldse:input)* := $form//ldse:input[@type = "wysiwyg"]
    let $ldswebmlInputs as element(ldse:input)* := $form//ldse:input[@type = "ldswebml"]
    let $combinedInputs as element(ldse:input)* := ($wysiwygInputs,$ldswebmlInputs)
    let $unTidyInputs as element(ldse:input) * :=
        for $input as element(ldse:input) in $combinedInputs
        where ( fn:not(
                 let $options as xs:string* := fn:tokenize($input/@options,",")
                 for $option as xs:string in $options
                 return($option eq ("tidy", "xml", "html", "xhtml"))
              )
        )
        return $input
    let $valid as xs:boolean := fn:empty($unTidyInputs) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$unTidyInputs))
    return(getValidResults($valid,$msg))
};

declare private function imageUpload($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $imageInputs as element(ldse:input)* := $form//ldse:input[@type = "image"]
    let $missingUploadOptionInputs as element(ldse:input) * :=
        for $input as element(ldse:input) in $imageInputs
        where ( fn:not(
                 let $options as xs:string* := fn:tokenize($input/@options,",")
                 for $option as xs:string in $options
                 return($option eq "imageUpload")
              )
            )
        return $input
    let $valid as xs:boolean := fn:empty($missingUploadOptionInputs) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$missingUploadOptionInputs))
    return(getValidResults($valid,$msg))
};

declare private function pdfUpload($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $pdfInputs as element(ldse:input)* := $form//ldse:input[@type = "pdf"]
    let $missingUploadOptionInputs as element(ldse:input) * :=
        for $input as element(ldse:input) in $pdfInputs
        where ( fn:not(
                 let $options as xs:string* := fn:tokenize($input/@options,",")
                 for $option as xs:string in $options
                 return($option eq "pdfUpload")
              )
            )
        return $input
    let $valid as xs:boolean := fn:empty($missingUploadOptionInputs) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$missingUploadOptionInputs))
    return(getValidResults($valid,$msg))
};

declare private function datePickerMissingDataFormat($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $datePickerInputs as element(ldse:input)* := $form//ldse:input[@type = "datePicker"]
    let $missingDataFormat as element(ldse:input)* := $datePickerInputs[fn:not(@data-format) or @data-format=""]
    let $valid as xs:boolean := fn:empty($missingDataFormat) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$missingDataFormat))
    return(getValidResults($valid,$msg))
};

declare private function dynamicXmlMissingTitleAttribute($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $dynamicXmlElementMissingTitle as element(ldse:dynamic-xml)* := $form//ldse:dynamic-xml[@title="" or fn:not(@title)]
    let $valid as xs:boolean := fn:empty($dynamicXmlElementMissingTitle) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$dynamicXmlElementMissingTitle))
    return(getValidResults($valid,$msg))
};

declare private function xPathLeadingSlash($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $slashXPathElements as element()* := $form//ldse:*[fn:substring(@xpath,1,1) eq '/' or fn:substring(@xpath,1,1) eq '\']
    let $valid as xs:boolean := fn:empty($slashXPathElements) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$slashXPathElements))
    return(getValidResults($valid,$msg))
};

declare private function rootQueryId($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $id as xs:string? := $form//cts:text[. eq "$id"]
    let $failElement as element()* := $form//cts:text
    let $valid as xs:boolean := fn:exists($id) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$failElement))
    return(getValidResults($valid,$msg))
};

declare private function uniqueSeqAttributes($form as element(ldse:formTemplate),$rule as element(ruleData)) as element(validationResults){
    let $seqElements as element()* := $form//(ldse:input | ldse:dynamic-xml)[@seq][fn:not(ancestor::ldse:dynamic-xml)]
    let $nonUniqueSeqs as xs:string* := functx:non-distinct-values($seqElements/@seq)
    let $nonUniqueSeqElements as element()* := $seqElements[@seq = $nonUniqueSeqs]
    let $nonUniqueDynamicSeqElements as element()* := 
        for $dynamicElement as element()* in $form//ldse:dynamic-xml
        let $dynamicSeqElements as element()* :=$dynamicElement//ldse:input[@seq]
        let $nonUniqueDynamicSeqs as xs:string* := functx:non-distinct-values($dynamicSeqElements/@seq)
        return $dynamicSeqElements[@seq = $nonUniqueDynamicSeqs]
    let $failElements as element()* := ($nonUniqueSeqElements,$nonUniqueDynamicSeqElements)
    let $valid as xs:boolean := fn:empty($failElements) 
    let $msg as item()*  := if($valid) then ($defaultSuccessMsg) else(failRuleContent($form,$rule,$failElements))
    return(getValidResults($valid,$msg))
};
