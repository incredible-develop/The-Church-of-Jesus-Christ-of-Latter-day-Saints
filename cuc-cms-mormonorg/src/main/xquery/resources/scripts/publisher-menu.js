var ICE = {
    menu: function () {
        var elements = document.getElementsByClassName('ldse-dropdownMenu-trigger');
        if (elements.length > 0) {
            elements[0].onclick = function () {
                var menu = document.getElementsByClassName('ldse-menu');
                if (menu.length > 0) {
                    if (menu[0].style.display == 'none' || menu[0].style.display == '') {
                        menu[0].style.display = 'block';
                    }
                    else {
                        menu[0].style.display = 'none';
                    }
                }
            }
        }

        document.addEventListener('click', function (e) {
            e = e || window.event;
            var target = e.target || e.srcElement,
                text = target.textContent || (text || {}).innerText;
            if (target.className.toString().indexOf('ldse-') === -1) {
                var menu = document.getElementsByClassName('ldse-menu');
                if (menu.length > 0) {
                    menu[0].style.display = 'none';
                }
            }
        }, false);

        var close = document.getElementById('ldse-toolbar-toggle');
        close.addEventListener('click', function (e) {
            var toolBar = document.getElementById('ldse-toolbar');
            var container = document.getElementById('ldse-toolbar-container');
            if (toolBar.style.display == 'none') {
                toolBar.style.display = 'block';
                container.className = 'ldse-toolbar-container front';
            }
            else {
                toolBar.style.display = 'none';
                container.className = 'ldse-toolbar-container front ldse-collapsed';
            }
        }, false);
    },
    post: function (path, params, method) {
        method = method || "post";
        var form = document.createElement('form'),
            hiddenField;
        debugger;
        if (params && params.id && params.id != "" && path.indexOf('/shared/lds-edit/form') != -1 && path.indexOf('&id=') == -1) {
            path += '&id=' + params.id;
            delete params.id;
        }
        form.setAttribute("method", method);
        form.setAttribute("action", path);
        form.style.display = 'none';
        for (var key in params) {
            if (Array.isArray(params[key])) {
                for (var i = 0; i < params[key].length; i++) {
                    hiddenField = document.createElement('<input>');
                    hiddenField.setAttribute("type", "hidden");
                    hiddenField.setAttribute("name", key.replace(/data-post\./, ''));
                    hiddenField.setAttribute("value", params[key][i]);
                    form.appendChild(hiddenField);
                }
            } else {
                hiddenField = document.createElement('input');
                hiddenField.setAttribute("type", "hidden");
                hiddenField.setAttribute("name", key.replace(/data-post\./, ''));
                hiddenField.setAttribute("value", params[key].value);
                form.appendChild(hiddenField);
                debugger;
            }
        }
        debugger;
        document.body.appendChild(form);
        form.submit();
        return false;
    },
    postLink: function (link) {

        var data = ICE.dataAttributes(link);
        var postData = [];
        for (var i in data) {
            if (data[i].name.indexOf('post.') > 0) {
                postData[data[i].name] = data[i];
            }
        }

        ICE.post(link.getAttribute('href'), postData);
        return false;
    },
    dataAttributes: function (element) {
        var attr = [];
        for (var key in element.attributes) {
            if (element.attributes.hasOwnProperty(key)) {
                var name = element.attributes[key].name;
                if (name && name.indexOf('data-') !== -1) {
                    attr.push(element.attributes[key]);
                }
            }
        }
        return attr;
    }
};

ICE.menu();