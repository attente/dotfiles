// ==UserScript==
// @name         youtube: keep shelf headers from navigating
// @namespace    https://attente.ca/userscripts
// @version      1.0.0
// @description  YouTube wraps a whole shelf header bar in a button, so clicking near the heading opens the memberships page. This keeps the heading but removes the tap target, the focus, and the keyboard path.
// @match        https://www.youtube.com/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(() => {
  'use strict';

  // Only headers whose text matches these are defused. Add strings to cover more
  // shelves, or set to null to defuse every tap-to-navigate shelf header.
  const TEXTS = ['get more from memberships'];

  const matches = (text) =>
    TEXTS === null || TEXTS.some((needle) => text.toLowerCase().includes(needle));

  const isTarget = (node) => {
    if (!node || node.nodeType !== 1) return false;
    const host = node.closest ? node.closest('yt-shelf-header-layout') : null;
    return Boolean(host && matches(host.textContent || ''));
  };

  // The mouse path. Hit testing never reaches the header, so the click that
  // YouTube listens for is never dispatched at all.
  const style = document.createElement('style');
  style.textContent = `
    yt-shelf-header-layout[role="button"],
    yt-shelf-header-layout.ytShelfHeaderLayoutTappable,
    yt-shelf-header-layout.ytShelfHeaderLayoutTap {
      pointer-events: none !important;
      cursor: default !important;
    }
  `;
  const attachStyle = () => {
    if (!style.isConnected) (document.head || document.documentElement).appendChild(style);
  };

  // The keyboard path. pointer-events does not stop Enter on a focused element, and
  // these handlers are attached by YouTube to the element itself, in the bubble
  // phase, so a capture listener on window runs first and can stop them.
  const guard = (event) => {
    if (!isTarget(event.target)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
  };
  for (const type of ['click', 'keydown', 'mousedown', 'pointerdown']) {
    window.addEventListener(type, guard, true);
  }

  // The focus path, and anything that survives a re-render: YouTube rebuilds this
  // part of the page on every navigation, so the attributes have to be removed
  // again each time rather than once at load.
  const defuse = (root) => {
    for (const host of root.querySelectorAll('yt-shelf-header-layout')) {
      if (!matches(host.textContent || '')) continue;
      if (host.hasAttribute('role')) host.removeAttribute('role');
      if (host.getAttribute('tabindex') !== '-1') host.setAttribute('tabindex', '-1');
    }
  };

  const sweep = () => {
    attachStyle();
    defuse(document);
  };

  const observer = new MutationObserver((records) => {
    let touched = false;
    for (const record of records) {
      for (const node of record.addedNodes) {
        if (node.nodeType !== 1) continue;
        touched = true;
        if (node.matches && node.matches('yt-shelf-header-layout')) defuse(node.parentElement || node);
        else defuse(node);
      }
    }
    if (touched) attachStyle();
  });

  const start = () => {
    sweep();
    observer.observe(document.documentElement, { childList: true, subtree: true });
    // Cheap backstop for re-renders the observer cannot see, and for the style
    // element being removed by a hard route change.
    setInterval(sweep, 4000);
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start, { once: true });
  } else {
    start();
  }
})();
