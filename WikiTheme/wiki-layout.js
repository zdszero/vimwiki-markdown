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
  // index.md split by `---` gives one tree per sub notebook; show only the
  // notebook holding the current page, else the one picked last time.
  function setupNotebooks(nav, key) {
    var books = nav.querySelectorAll('.wiki-notebook');
    var tabs = nav.querySelectorAll('.wiki-notebook-tab');
    if (!books.length) { return; }
    function select(idx) {
      var name = '';
      for (var i = 0; i < books.length; i++) {
        var on = books[i].getAttribute('data-notebook') === idx;
        books[i].hidden = !on;
        if (on) { name = books[i].getAttribute('data-name'); }
      }
      for (var k = 0; k < tabs.length; k++) {
        var active = tabs[k].getAttribute('data-notebook') === idx;
        tabs[k].classList.toggle('active', active);
        tabs[k].setAttribute('aria-selected', active ? 'true' : 'false');
      }
      try { localStorage.setItem(key, name); } catch (e) {}
    }
    var stored = null;
    try { stored = localStorage.getItem(key); } catch (e) {}
    var owner = null, last = null;
    for (var i = 0; i < books.length; i++) {
      var idx = books[i].getAttribute('data-notebook');
      var mine = books[i].getAttribute('data-name') === stored;
      if (books[i].querySelector('a.active')) {
        if (owner === null || mine) { owner = idx; }
      }
      if (mine && last === null) { last = idx; }
    }
    var pick = owner !== null ? owner : (last !== null ? last : books[0].getAttribute('data-notebook'));
    for (var k = 0; k < tabs.length; k++) {
      tabs[k].addEventListener('click', function () {
        select(this.getAttribute('data-notebook'));
      });
    }
    select(pick);
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
  // each wiki directory with an index.md has its own sidebar; load the one of
  // the nearest directory up from this page. It is kept in a standalone file
  // so adding a page needn't rebuild every page.
  function loadSidebar(dir) {
    return fetch(dir + 'wiki_sidebar.html').then(function (r) {
      if (r.ok) {
        return r.text().then(function (html) { return { dir: dir, html: html }; });
      }
      if (dir === '/') { return null; }
      return loadSidebar(dir.replace(/[^\/]*\/$/, ''));
    });
  }
  var nav = document.getElementById('wiki-sidebar');
  if (nav) {
    loadSidebar(location.pathname.replace(/[^\/]*$/, ''))
      .then(function (res) {
        if (res && res.html) {
          nav.innerHTML = res.html;
          nav.hidden = false;
          markActive();
          setupNotebooks(nav, 'wiki-notebook:' + res.dir);
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
