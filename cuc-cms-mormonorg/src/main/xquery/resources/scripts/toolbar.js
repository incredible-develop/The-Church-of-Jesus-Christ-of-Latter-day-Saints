window.addEventListener("resize", function(event) {
    updateStyles();
});

var toolbar = {
    menu: function () {
        var elements = document.getElementsByClassName('ldse-dropdownMenu-trigger');
        if (elements.length > 0) {
            for (var i = 0; i < elements.length; i++ ){
                var node = elements[i].parentElement.parentElement;
                node.onclick = function (e) {
                    var item = e.target.parentElement,
                        menu = item.getElementsByClassName('ldse-menu'),
                        menus = document.getElementsByClassName('ldse-menu');
                    if ( e.target.className.indexOf('ldse-icon-close-menu') < 0 ) {

                        if ( menu.length == 0 ) {
                            menu = item.parentElement.getElementsByClassName('ldse-menu');
                        }
                        if ( menu[0] != undefined ) {
                            for (i = 0; i < menus.length; i++) {
                                if ( menus[i].parentElement.parentElement.className.toString() !== menu[0].parentElement.parentElement.className.toString() ) {
                                    menus[i].style.display = 'none';
                                }
                            }
                        }
                        if ( item.className.toString() == 'with-submenu' ) {
                            var itemChild = item.getElementsByTagName('ul');
                            displayOrHide(itemChild);
                        } else  {
                            if (menu.length > 0) {
                                displayOrHide(menu);
                            }
                        }
                    } else {
                        var menu = document.getElementsByClassName('ldse-menu');
                        for (var i = 0; i < menu.length; i++){
                            menu[i].style.display = 'none';
                        }
                    }
                }
            }
        }
        document.addEventListener('click', function (e) {
            e = e || window.event;
            var target = e.target || e.srcElement,
                text = target.textContent || (text || {}).innerText,
                parent = target.parentElement,
                parentParent = parent.parentElement;
            if (parent.className.toString().indexOf('ldse-toolbar-item') === -1 && parent.className.toString().indexOf('with-submenu') === -1 && parentParent.className.toString().indexOf('ldse-toolbar-item') === -1) {
                var menu = document.getElementsByClassName('ldse-menu');
                for (var i = 0; i < menu.length; i++){
                    menu[i].style.display = 'none';
                }
            }
        }, false);
        var close = document.getElementById('ldse-toolbar-toggle');
        close.addEventListener('click', function (e) {
            var toolBar = document.getElementById('ldse-toolbar');
            var container = document.getElementById('ldse-toolbar-container');
            if ( container.className.toString().indexOf('ldse-collapsed') === -1 ) {
                container.className = 'ldse-toolbar-container ldse-collapsed';
            } else {
                container.className = 'ldse-toolbar-container';
            }
        }, false);
    }
};

function displayOrHide(item) {
    if ( item[0].style.display == 'none' || item[0].style.display == '' ) {
        item[0].style.display = 'block';
        updateStyles(item);
    } else {
        item[0].style.display = 'none';
    }
};

function updateStyles(item) {
    item = item || document.getElementsByClassName('ldse-menu');
    if ( item[0].style.display == 'block' ) {
        item[0].style.overflowY = 'auto';
        item[0].style.overflowX = 'hidden';
        item[0].style.maxHeight = ( window.innerHeight - document.getElementById('ldse-toolbar').offsetHeight ) + 'px';
    }
};

toolbar.menu();