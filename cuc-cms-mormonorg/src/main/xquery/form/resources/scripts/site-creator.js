
document.addEventListener("DOMContentLoaded", function(event) {
    var templates = document.getElementsByClassName('templates'),
        subTemplates = document.getElementsByClassName('sub-templates');
    for( var i = 0; i < templates.length; i++ ) {
        var template = templates[i].value,
            name = templates[i].getAttribute('name'),
            parent = templates[i].parentElement.parentElement.parentElement.parentElement,
            subTemplate = parent.querySelector('.sub-template'),
            subTemplateVal = subTemplate.value;
        getSubTemplates(template, subTemplateVal, subTemplate, i)
    };
    document.getElementById('name').addEventListener('change', function(event) {
        uniqueSite();
    });
    document.getElementById('name').addEventListener('keyup', function(event) {
        uniqueSite();
    });
});

function getSubTemplates(template, subTemplateVal, subTemplate, index) {
    var r = new XMLHttpRequest();
    r.open("GET", '/cms/form/ajax/get-sub-templates?lang=eng&template=' + template + '&sub-template=' + subTemplateVal + '&index=' + index + '&id=' + ICE.formVars.id);
    r.onreadystatechange = function () {
        if ( this.readyState == 4 ) {
            if ( this.status == 200 ) {
                subTemplate.innerHTML = this.response;
                var el = document.createElement('select');
                el.innerHTML = this.response;
                var options = el.getElementsByTagName('option');
                if ( this.response === '' ) {
                    subTemplate.parentElement.getElementsByClassName('text')[0].innerHTML = this.response;
                    subTemplate.parentElement.parentElement.parentElement.classList += ' hidden';
                } else {
                    subTemplate.parentElement.parentElement.parentElement.classList.remove('hidden');
                };
                var selectedIndex = subTemplate.selectedIndex;
                if ( selectedIndex > -1 ) {
                    subTemplate.parentElement.getElementsByClassName('text')[0].innerHTML = options[selectedIndex].innerHTML;
                } else if ( selectedIndex == -1 && this.response !== '' ) {
                    subTemplate.parentElement.getElementsByClassName('text')[0].innerHTML = options[0].innerHTML;
                }
            }
        }
    }
    r.send();
};

function getSubTemplateInfo(template) {
    var templateName = template.value,
        name = template.getAttribute('name'),
        parent = template.parentElement.parentElement.parentElement.parentElement,
        subTemplate = parent.querySelector('.sub-template'),
        subTemplateVal = subTemplate.value,
        strings = template.getAttribute('name').split('-'),
        index = strings[strings.length - 1] - 1;
    if ( document.readyState === 'complete' ) {
        getSubTemplates(templateName, subTemplateVal, subTemplate, index)
    }
};

function uniqueSite() {
    var siteName = document.getElementById('name').value;
    var action = document.getElementById('formAction').value
    var id = document.getElementById('content-id').value
    var r = new XMLHttpRequest();
    r.open("GET", '/cms/form/ajax/check-site?lang=eng&siteName=' + siteName + '&action=' + action + '&id=' + id);
    r.onreadystatechange = function () {
        if ( this.readyState == 4 ) {
            if ( this.status == 200 && this.response == "false" ) {
                document.getElementById('action-save').setAttribute('disabled', '');
                if ( !document.getElementById('site-name-error-label') ) {
                    el = document.createElement('label');
                    el.setAttribute('id', 'site-name-error-label');
                    el.setAttribute('class', 'existing');
                    el.setAttribute('for', 'name');
                    el.innerHTML = 'This site name already exists';
                    document.getElementById('name').parentElement.appendChild(el);
                    document.getElementById('name').classList.add('error')
                }
            } else {
                document.getElementById('action-save').removeAttribute('disabled');
                
                if ( document.getElementById('site-name-error-label') ) {
                    document.getElementById('site-name-error-label').remove();
                }
            }
        }
    }
    r.send();
};