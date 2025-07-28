import QtQuick
import QtCore

import QtQuick.Controls
import QtQuick.Layouts

import org.qfield
import org.qgis
import Theme

import "."

Item {
    id: plugin

    Settings {
        id: multiplierSettings
        property real selectedMultiplier: 1.0
        property int selectedMultiplierIndex: 2
        property var showCrosshairOverlay: true
    }

    property var mainWindow: iface.mainWindow()
    property var positionSource: iface.findItemByObjectName('positionSource')
    property var coordinateLocator: iface.findItemByObjectName('coordinateLocator')
    property var projectInfo: iface.findItemByObjectName('projectInfo')
    property var mapCanvas: null

    property var legend: iface.findItemByObjectName('Legend')

    property point crosshairPos: Qt.point(width / 2, height / 2)

    // This is the key - track the displayPosition from coordinateLocator
    property point displayPosition: coordinateLocator ? coordinateLocator.displayPosition : Qt.point(width / 2, height / 2)

    function recalculateLayerFontSize() {
        let multiplier = multiplierSettings.selectedMultiplier > 0.0 ? multiplierSettings.selectedMultiplier : 1.0;
        var pointSize = Theme.tipFont.pointSize * multiplier;
        var dashBoard = iface.findItemByObjectName('dashBoard');

        var layerElements = dashBoard?.contentData[2]?.children[2]?.children[0]?.children[0]?.children;
        if (!layerElements) {
            return;
        }

        for (var i = 0; i < layerElements.length; i++) {
            var element = layerElements[i];
            let label = element.children[2].children[1].children[2];
            label.font.pointSize = pointSize;
        }
    }
    // Update crosshair position when displayPosition changes
    onDisplayPositionChanged: {
        console.log("Display position changed to:", displayPosition);
        crosshairPos = displayPosition;
    }

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(makeItPinkButton);

        mapCanvas = iface.mapCanvas();
        if (mapCanvas) {
            console.log("MapCanvas found, size:", mapCanvas.width + "x" + mapCanvas.height);

            // Dynamically reparent crosshair to mapCanvas
            customCrosshair.parent = mapCanvas;

            // Set initial position from coordinateLocator's displayPosition
            if (coordinateLocator) {
                crosshairPos = coordinateLocator.displayPosition;
                console.log("Initial crosshair position set to:", crosshairPos);
            }
        } else {
            iface.logMessage("No mapCanvas available.");
        }
        layerTextSizeSettings.parent = iface.mainWindow().contentItem;
        comboBoxMultipliers.currentIndex = multiplierSettings.selectedMultiplierIndex;
        crosshairOverlayCheckbox.checked = multiplierSettings.showCrosshairOverlay;
        plugin.recalculateLayerFontSize();
    }

    // Timer to recalculate layer font size every 10 seconds
    Timer {
        id: fontSizeTimer
        interval: 5000  // 5 seconds in milliseconds
        running: true
        repeat: true
        onTriggered: {
            plugin.recalculateLayerFontSize();
        }
    }

    // Connect to coordinateLocator signals for real-time updates
    Connections {
        target: plugin.coordinateLocator
        function onDisplayPositionChanged() {
            plugin.crosshairPos = plugin.coordinateLocator.displayPosition;
        }
        function onSourceLocationChanged() {
            if (plugin.coordinateLocator.sourceLocation !== undefined) {
                plugin.crosshairPos = plugin.coordinateLocator.sourceLocation;
            }
        }
        function onCurrentCoordinateChanged() {
            // Update display position when coordinate changes
            if (plugin.coordinateLocator.displayPosition !== undefined) {
                plugin.crosshairPos = plugin.coordinateLocator.displayPosition;
            }
        }
    }

    Dialog {
        id: layerTextSizeSettings
        modal: true
        visible: false
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("Adjust Layer Text Size")

        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2

        ColumnLayout {
            spacing: 10

            Label {
                id: labelSelection
                wrapMode: Text.Wrap
                text: qsTr("Layer text size settings")
                font: Theme.defaultFont
            }

            ComboBox {
                id: comboBoxMultipliers
                Layout.fillWidth: true
                currentIndex: 2  // Default to 1.0 (index 2 in the model array)

                model: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
            }

            CheckBox {
                id: crosshairOverlayCheckbox
                text: qsTr("Show Crosshair Overlay")
                checked: multiplierSettings.showCrosshairOverlay
                font: Theme.defaultFont
            }
        }

        onAccepted: {
            multiplierSettings.selectedMultiplier = comboBoxMultipliers.currentText;
            multiplierSettings.selectedMultiplierIndex = comboBoxMultipliers.currentIndex;
            multiplierSettings.showCrosshairOverlay = crosshairOverlayCheckbox.checked;
            plugin.recalculateLayerFontSize();

            customCrosshair.visible = multiplierSettings.showCrosshairOverlay && projectInfo.stateMode === "digitize";
        }
    }

    CrosshairOverlay {
        id: customCrosshair
        width: 120
        height: 120

        x: plugin.crosshairPos.x - width / 2
        y: plugin.crosshairPos.y - height / 2
        visible: multiplierSettings.showCrosshairOverlay && projectInfo.stateMode === "digitize"
        z: 999 // High z-index to ensure visibility

        // Smooth animation to match QField's crosshair behavior
        Behavior on x {
            NumberAnimation {
                duration: 10
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 10
                easing.type: Easing.OutCubic
            }
        }
    }

    QfToolButton {
        id: makeItPinkButton
        iconSource: 'icon.svg'
        iconColor: Theme.white
        bgcolor: Theme.darkGray
        round: true

        onClicked: {
            layerTextSizeSettings.open();
            return;
        }
    }

    Connections {
        target: mainWindow
        onToggleDigitizeMode: {
            customCrosshair.visible = multiplierSettings.showCrosshairOverlay && projectInfo.stateMode === "digitize";
        }
    }

    function configure() {
        layerTextSizeSettings.open();
    }
}
