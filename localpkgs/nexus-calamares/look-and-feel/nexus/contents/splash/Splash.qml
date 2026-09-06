import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    width: 500
    height: 500
    visible: true
    title: "Nexus Linux"
    color: "#1a1a2e"

    Rectangle {
        anchors.centerIn: parent
        width: 160
        height: 160
        radius: 80
        color: "#1793d1"
    }

    Text {
        anchors.centerIn: parent
        text: "Nexus Linux"
        font.pixelSize: 32
        font.bold: true
        color: "#ffffff"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 200
    }

    Text {
        anchors.centerIn: parent
        text: "Pure Arch Based"
        font.pixelSize: 16
        color: "#888888"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 240
    }