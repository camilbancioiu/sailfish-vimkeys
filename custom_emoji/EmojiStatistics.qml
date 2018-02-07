/*
 * Copyright (C) 2014 Janne Edelman.
 * Contact: Janne Edelman <janne.edelman@gmail.com>
 */

import QtQuick 2.0
// QtSystemInfo requires qt5-qtdeclarative-systeminfo package installed
import QtSystemInfo 5.0

Item {
    Image { id: icon; source: ""; cache: false; width: 0; height: 0 }

    property string baseURL: "http://www.google-analytics.com/collect?"
    property string statHandshake: "v=1&tid=UA-194078-6"
    property string cidURI: "&cid=" + anonUUID()
    property string appScreenURI: "&t=appview"
    property string appEventURI: "&t=event"
    property string appURI: "&an=EmojiKeyboard&av=" + emojiKeyboard.appVersion
    
    property string prefixURL: baseURL + statHandshake + cidURI + appURI
    property string localeURI: "&ul=" + Qt.locale().name;

    /* sendStatistics:
     *     0  -  No statistics sent
     *	   1  -  Keyboard load statistics sent
     *	   2  -  Selected emoji set and emoji page statistics sent 
     *	   3  -  Emoji symbol statistics sent 
     '   Note: levels above 1 are currently for debugging purposes only. Data caching needed to take into use
     */

    // sendStatistics >= 1
    function statLoaded(emojiSet,emojiPage) {
	icon.source = (emojiKeyboard.sendStatistics > 0) ? prefixURL + appScreenURI + localeURI + "&cd=Loaded+Set+" + emojiSet + ",+Page+" + emojiPage + cacheBooster() : '';
    }

    // sendStatistics >= 2
    // Developer statistics only
    function statSet(emojiSet,emojiPage) {
	icon.source = (emojiKeyboard.sendStatistics > 1) ? prefixURL + appEventURI + "&ec=Set&ea=Set+" + emojiSet + "&el=Page+" + emojiPage + cacheBooster() : '';
    }
    
    // sendStatistics >= 2
    // Developer statistics only
    function statPage(emojiSet,emojiPage) {
	icon.source = (emojiKeyboard.sendStatistics > 1) ? prefixURL + appEventURI + "&ec=Page&ea=Set+" + emojiSet + "&el=Page+" + emojiPage + cacheBooster() : '';
    }

    // sendStatistics >= 3
    // Developer statistics only
    function statSymbol(emojiSet,emojiPage,index) {
	icon.source = (emojiKeyboard.sendStatistics > 2) ? prefixURL + appEventURI + "&ec=Symbol&ea=Set+" + emojiSet + "&el=Page+" + emojiPage + "&ev=" + index + cacheBooster() : '';
    }

    function cacheBooster() {
	return "&z=" + Math.floor(Math.random() * 1000000000).toString();
    }

    /* We don't want to reveal real uniqueDeviceID for analytics platform */
    function anonUUID() {
	var salt = 'The Emoji Keyboard';
	var hash = Qt.md5(salt  + uniqueDeviceID());
        var y = ['8', '9', 'a', 'b'];
	return hash.substr(0,8) + '-' + hash.substr(8,4) + '-4' + hash.substr(13,3) + '-' + 
               y[uniqueDeviceID().substr(12,2) % 4] + hash.substr(17,3) + '-' + hash.substr(20,12);
    }

    function uniqueDeviceID() {
	// devinfo.uniqueDeviceID() is not unique in Jolla, so we replace it with IMEI without revealing it
	return devinfo.imei(0);
    }

    DeviceInfo {
        id: devinfo;
    }
}
