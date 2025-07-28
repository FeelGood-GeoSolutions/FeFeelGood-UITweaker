import QtQuick 2.15
import QtQuick.Shapes 1.15

Item {
    id: crosshairOverlay
    width: 100    // Adjust size as needed
    height: 100
    
    Behavior on x { NumberAnimation { duration: 100 } }
    Behavior on y { NumberAnimation { duration: 100 } }

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeColor: "red"  // Crosshair color
            strokeWidth: 4
            startX: crosshairOverlay.width / 2
            startY: 0
            PathLine {
                x: crosshairOverlay.width / 2
                y: crosshairOverlay.height
            }
        }
        ShapePath {
            strokeColor: "red"
            strokeWidth: 4
            startX: 0
            startY: crosshairOverlay.height / 2
            PathLine {
                x: crosshairOverlay.width
                y: crosshairOverlay.height / 2
            }
        }
        ShapePath {
            strokeColor: "red"
            strokeWidth: 2
            fillColor: "transparent"
            startX: crosshairOverlay.width / 2 + 30
            startY: crosshairOverlay.height / 2
            PathArc {
                x: crosshairOverlay.width / 2 - 30
                y: crosshairOverlay.height / 2
                radiusX: 30
                radiusY: 30
                useLargeArc: true
            }
        }
    }
}
