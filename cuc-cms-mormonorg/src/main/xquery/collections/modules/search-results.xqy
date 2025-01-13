xquery version "1.0-ml";

module namespace search = "http://lds.org/code/shared/lds-edit/collections";

declare option xdmp:mapping "true";

declare function build-search-result-table() as item(){
    <ul id="results-list" class="sortable ui-sortable ldse-rowfix ldse-makeCols"> </ul>
};

declare function build-list-item() as element(script){
    <script class="handlebars-template" id="listItemTemplate" type="text/x-handlebars-template">
        {{{{#each results}}}}
            {{{{#if notApproved}}}}
                <li class="ldse-clearfix collection-item ldse-info-banner warning" data-id="{{{{fileID}}}}" data-type="{{{{type}}}}" data-new="true">
                    <section class="ldse-block">
                    	<header class="ldse-clearfix">
            		        <a href="#d" class="ldse-icon-ko-tri-right ldse-icon ldse-block-toggle collection-search-result">Toggle Full View</a>
            		        <h3>{{{{forceBreak title}}}}</h3>
            		        <button class="ldse-collection-button add ldse-icon-plus ldse-icon">Add</button>
            	        </header>
            	        <div class="ldse-block--body">
            		        <img src="{{{{image}}}}"/>
                            <div class="needCor">
                                <span class="approval-flag ldse-icon-ko-warning ldse-icon" title="Needs Approval">Pending Approval</span>
                                <span class="approval-text">Not Cor-IP / Cor-Eval approved</span>
                            </div>
            	        </div>
                    </section>
                </li>
            {{{{else}}}}
                <li class="ldse-clearfix collection-item ldse-info-banner" data-id="{{{{fileID}}}}" data-type="{{{{type}}}}" data-new="true">
                    <section class="ldse-block">
                    	<header class="ldse-clearfix">
            		        <a href="#d" class="ldse-icon-ko-tri-right ldse-icon ldse-block-toggle collection-search-result">Toggle Full View</a>
            		        <h3>{{{{forceBreak title}}}}</h3>
            		        <button class="ldse-collection-button add ldse-icon-plus ldse-icon">Add</button>
            	        </header>
            	        <div class="ldse-block--body">
            		        <img src="{{{{image}}}}" onerror="missingImage(this); return false;"/>
            		        <div class="ldse-teaser-buttons">
            		              <span class="ldse-icon-ko-info ldse-icon" >&amp;nbps;</span> You can't edit or publish this item until it is saved as part of the collection.
                            </div>
            	        </div>
            	        <div class="ldse-collection-status collection-new"><span class="ldse-icon-edit">New Item</span></div>
                    </section>
                </li>
            {{{{/if}}}}
        {{{{/each}}}}
    </script>
};