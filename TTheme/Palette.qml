pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.platform as Platform

import "PaletteUtils.js" as PaletteUtils

QtObject {
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

    property bool _loading: false

    readonly property var _defaultDark: ({
        primary: "#D0BCFF",
        on_primary: "#381E72",
        primary_container: "#4F378B",
        on_primary_container: "#EADDFF",
        secondary: "#CCC2DC",
        on_secondary: "#332D41",
        secondary_container: "#4A4458",
        on_secondary_container: "#E8DEF8",
        tertiary: "#EFB8C8",
        on_tertiary: "#492532",
        tertiary_container: "#633B48",
        on_tertiary_container: "#FFD8E4",
        surface: "#141218",
        on_surface: "#E6E0E9",
        surface_variant: "#49454F",
        on_surface_variant: "#CAC4D0",
        background: "#141218",
        on_background: "#E6E0E9",
        outline: "#938F99",
        outline_variant: "#49454F",
        surface_container: "#211F26",
        surface_container_low: "#1D1B20",
        surface_container_high: "#2B2930",
        surface_container_highest: "#36343B",
        surface_container_lowest: "#0F0D13",
        surface_dim: "#141218",
        surface_bright: "#3B383E",
        inverse_surface: "#E6E0E9",
        inverse_on_surface: "#322F35",
        inverse_primary: "#6750A4",
        error: "#F2B8B5",
        on_error: "#601410",
        error_container: "#8C1D18",
        on_error_container: "#F9DEDC",
        scrim: "#000000",
        shadow: "#000000"
    })

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
        if (root._loading) return;
        root._loading = true;

        const url = root._urlForPath(root.palettePath);
        console.warn("TTheme: loading palette from", url);
        const xhr = new XMLHttpRequest();

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root._loading = false;

            if (xhr.status === 0 || xhr.status === 200) {
                try {
                    const parsed = JSON.parse(xhr.responseText);
                    root.applyPaletteData(parsed);
                    console.warn("TTheme: palette loaded successfully");
                    return;
                } catch (e) {
                    console.warn("TTheme: JSON parse error:", e);
                }
            } else {
                console.warn("TTheme: XHR failed with status", xhr.status);
            }

            if (!root.ready) {
                root.markReadyWithDefaults();
            }
        };

        try {
            xhr.open("GET", url, true);
            xhr.send();
        } catch (error) {
            console.warn("TTheme: XHR error:", error);
            root._loading = false;
            if (!root.ready) {
                root.markReadyWithDefaults();
            }
        }
    }

    Component.onCompleted: {
        root.loadPalette();
        setInterval(function() {
            root.loadPalette();
        }, 1500);
    }

    function color(role) {
        const value = current?.[role];
        if (value === undefined || value === null) {
            console.warn("TTheme: missing color role '" + role + "' in mode '" + root.mode + "', returning transparent");
            return "transparent";
        }
        return value;
    }

    readonly property color primary: current.primary || "#000000"
    readonly property color onPrimary: current.on_primary || "#ffffff"
    readonly property color primaryContainer: current.primary_container || "#000000"
    readonly property color onPrimaryContainer: current.on_primary_container || "#ffffff"

    readonly property color secondary: current.secondary || "#000000"
    readonly property color onSecondary: current.on_secondary || "#ffffff"
    readonly property color secondaryContainer: current.secondary_container || "#000000"
    readonly property color onSecondaryContainer: current.on_secondary_container || "#ffffff"

    readonly property color tertiary: current.tertiary || "#000000"
    readonly property color onTertiary: current.on_tertiary || "#ffffff"
    readonly property color tertiaryContainer: current.tertiary_container || "#000000"
    readonly property color onTertiaryContainer: current.on_tertiary_container || "#ffffff"

    readonly property color surface: current.surface || "#000000"
    readonly property color onSurface: current.on_surface || "#ffffff"
    readonly property color surfaceVariant: current.surface_variant || "#000000"
    readonly property color onSurfaceVariant: current.on_surface_variant || "#ffffff"

    readonly property color background: current.background || "#000000"
    readonly property color onBackground: current.on_background || "#ffffff"

    readonly property color outline: current.outline || "#ffffff"
    readonly property color outlineVariant: current.outline_variant || "#ffffff"

    readonly property color surfaceTint: current.surface_tint || primary
    readonly property color surfaceContainer: current.surface_container || surface
    readonly property color surfaceContainerLow: current.surface_container_low || surface
    readonly property color surfaceContainerHigh: current.surface_container_high || surface
    readonly property color surfaceContainerHighest: current.surface_container_highest || surface
    readonly property color surfaceContainerLowest: current.surface_container_lowest || surface
    readonly property color surfaceDim: current.surface_dim || surface
    readonly property color surfaceBright: current.surface_bright || surface

    readonly property color inverseSurface: current.inverse_surface || surface
    readonly property color inverseOnSurface: current.inverse_on_surface || onSurface
    readonly property color inversePrimary: current.inverse_primary || primary

    readonly property color error: current.error || "#b00020"
    readonly property color onError: current.on_error || "#ffffff"
    readonly property color errorContainer: current.error_container || error
    readonly property color onErrorContainer: current.on_error_container || onError

    readonly property color scrim: current.scrim || "#000000"
    readonly property color shadow: current.shadow || "#000000"
}
