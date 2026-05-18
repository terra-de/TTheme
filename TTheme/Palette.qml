pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.platform as Platform

import "PaletteUtils.js" as PaletteUtils

QtObject {
    id: root

    // --- Path & State ---

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

    // --- V2 Default Fallback (dark) ---
    // c0 = background source (darkest), c4 = loudest accent (lightest).
    // All backgrounds are in c0's hue family (cohesive single-source).
    // on-colors hand-crafted for readability.

    readonly property var _defaultDark: ({
        bottom:  "#0e0b0e",
        low:     "#140f15",
        base:    "#181114",
        high:    "#21171f",
        top:     "#29222a",
        standard:"#e7e9ea",
        muted:   "#929799",
        c0:      "#69374f",
        on_c0:   "#dfb9d6",
        c1:      "#874878",
        on_c1:   "#d5c1d7",
        c2:      "#906694",
        on_c2:   "#dbbdd8",
        c3:      "#ae7ba9",
        on_c3:   "#3e2541",
        c4:      "#c1a1c5",
        on_c4:   "#462032",
        error:   "#e10b10",
        on_error:"#d7ced5",
        outline: "#735965"
    })

    // --- Internal ---

    function _urlForPath(path) {
        if (path.startsWith("file://") || path.startsWith("qrc://")) {
            return path;
        }
        return "file://" + path;
    }

    function markReadyWithDefaults() {
        console.warn("TTheme: using fallback default palette (file not loaded)");
        root.mode = "dark";
        root.light = ({});
        root.dark = root._defaultDark;
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
        const url = root._urlForPath(root.palettePath);
        console.warn("TTheme: loading palette from", url);
        const xhr = new XMLHttpRequest();
        try {
            xhr.open("GET", url, false);
            xhr.send();
            if (xhr.status === 0 || xhr.status === 200) {
                const parsed = JSON.parse(xhr.responseText);
                root.applyPaletteData(parsed);
                console.warn("TTheme: palette loaded successfully");
            } else {
                console.warn("TTheme: XHR failed with status", xhr.status);
                if (!root.ready) root.markReadyWithDefaults();
            }
        } catch (error) {
            console.warn("TTheme: XHR error:", error);
            if (!root.ready) root.markReadyWithDefaults();
        }
    }

    Timer {
        id: pollTimer
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.loadPalette()
    }

    Component.onCompleted: {
        root.loadPalette();
    }

    // --- Dynamic role lookup (pure, no aliases) ---

    function color(role) {
        const value = current?.[role];
        if (value === undefined || value === null) {
            console.warn("TTheme: missing color role '" + role + "' in mode '" + root.mode + "', returning transparent");
            return "transparent";
        }
        return value;
    }

    // --- V2 Properties (17 total, no legacy names) ---

    // Background layers (bottom → low → base → high → top, deepest to foremost)
    readonly property color bottom: current.bottom  || _defaultDark.bottom
    readonly property color low:    current.low     || _defaultDark.low
    readonly property color base:   current.base    || _defaultDark.base
    readonly property color high:   current.high    || _defaultDark.high
    readonly property color top:    current.top     || _defaultDark.top

    // Text tokens
    readonly property color standard: current.standard || _defaultDark.standard
    readonly property color muted:    current.muted    || _defaultDark.muted

    // Semantic colors
    readonly property color c0:   current.c0   || _defaultDark.c0
    readonly property color onC0: current.on_c0 || _defaultDark.on_c0
    readonly property color c1:   current.c1   || _defaultDark.c1
    readonly property color onC1: current.on_c1 || _defaultDark.on_c1
    readonly property color c2:   current.c2   || _defaultDark.c2
    readonly property color onC2: current.on_c2 || _defaultDark.on_c2
    readonly property color c3:   current.c3   || _defaultDark.c3
    readonly property color onC3: current.on_c3 || _defaultDark.on_c3
    readonly property color c4:   current.c4   || _defaultDark.c4
    readonly property color onC4: current.on_c4 || _defaultDark.on_c4

    // Error
    readonly property color error:   current.error    || _defaultDark.error
    readonly property color onError: current.on_error || _defaultDark.on_error

    // Outline
    readonly property color outline: current.outline || _defaultDark.outline
}
