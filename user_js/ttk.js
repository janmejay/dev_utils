// ==UserScript==
// @name        TTK
// @namespace   TTK
// @description TTK
// @include     https://*.ttkhealthcareservices.com/*
// @include     http://*.ttkhealthcareservices.com/*
// @version     1
// ==/UserScript==

unsafeWindow.addEventListener ("load", function () {
    unsafeWindow.TrackChanges = function() { return true; };
}, false);

