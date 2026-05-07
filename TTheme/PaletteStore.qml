pragma Singleton

import QtQuick
import Qt.labs.platform as Platform

import "PaletteUtils.js" as PaletteUtils

Item {
    id: root

    readonly property string defaultPalettePath:
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation)
        + "/.config/terra/palette.json"

    property string palettePath: root.defaultPalettePath

    property bool ready: false

    property string mode: "dark"
    property var light: ({})
    property var dark: ({})
    readonly property var current: mode === "light" ? light : dark

    signal loaded

    function _urlForPath(path) {
        if (path.startsWith("file://") || path.startsWith("qrc://")) {
            return path;
        }
        return "file://" + path;
    }

    function markReadyWithDefaults() {
        const sanitized = PaletteUtils.sanitizePaletteData(({}), root.mode, root.light, root.dark);
        root.mode = sanitized.mode;
        root.light = sanitized.light;
        root.dark = sanitized.dark;
        root.ready = true;
        root.loaded();
    }

    function applyPaletteData(parsed) {
        const sanitized = PaletteUtils.sanitizePaletteData(parsed, root.mode, root.light, root.dark);
        root.mode = sanitized.mode;
        root.light = sanitized.light;
        root.dark = sanitized.dark;
        root.ready = true;
        root.loaded();
    }

    function loadPalette() {
        const xhr = new XMLHttpRequest();
        try {
            xhr.open("GET", root._urlForPath(root.palettePath), false);
            xhr.send();
            if (xhr.status === 0 || xhr.status === 200) {
                const parsed = JSON.parse(xhr.responseText);
                root.applyPaletteData(parsed);
            } else if (!root.ready) {
                root.markReadyWithDefaults();
            }
        } catch (error) {
            if (!root.ready) {
                root.markReadyWithDefaults();
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        triggeredOnStart: true
        onTriggered: root.loadPalette()
    }
}
