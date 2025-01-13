xquery version "1.0-ml";

module namespace miu = "http://lds.org/code/shared/lds-edit/multiImageUploader";

import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "dynamicForms.xqy";

declare namespace cts = "http://marklogic.com/cts";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare function multiImageUploader($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    <dl data-sequence="{xs:string($input/@seq)}" class="{xs:string($input/@dlClass)}">
        <script type="text/javascript" src="{df:getVariable('sharedPrefix')}/ice/resources/script/multiImageUpload.js"></script>
        <div>
            <div id="filedrag">drop files here</div>
            <div id="fileinfo">
                <ul></ul>
            </div>
        </div>
    </dl>
};
