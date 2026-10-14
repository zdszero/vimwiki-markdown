(function () {
  function markActive() {
    var here = location.href.split('#')[0];
    var links = document.querySelectorAll('.wiki-sidebar a');
    for (var i = 0; i < links.length; i++) {
      if (links[i].href.split('#')[0] === here) {
        links[i].classList.add('active');
      }
    }
  }
  // add a tap-to-expand header to a panel (styled visible on mobile only)
  function addToggle(el, label) {
    if (!el || el.querySelector('.wiki-collapse-btn')) { return; }
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'wiki-collapse-btn';
    btn.textContent = label;
    btn.setAttribute('aria-expanded', 'false');
    btn.addEventListener('click', function () {
      var open = el.classList.toggle('open');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    el.insertBefore(btn, el.firstChild);
  }
  // load the shared site directory once (served from the wiki root);
  // kept in a standalone file so adding a page needn't rebuild every page.
  var nav = document.getElementById('wiki-sidebar');
  if (nav) {
    fetch('/wiki_sidebar.html')
      .then(function (r) { return r.ok ? r.text() : ''; })
      .then(function (html) {
        if (html) {
          nav.innerHTML = html;
          nav.hidden = false;
          markActive();
          addToggle(nav, '全站目录');
        }
      })
      .catch(function () {});
  }
  addToggle(document.querySelector('.wiki-toc'), '本页目录');
  // keep bootstrap table styling (previously done by sticky_menu.js)
  var tables = document.getElementsByTagName('table');
  for (var j = 0; j < tables.length; j++) {
    tables[j].classList.add('table');
  }
})();
