import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.1
import Firebird.UIComponents 1.0

Item {
    property alias text: label.text
    property alias iconSource: icon.source

    width: parent.width * 0.9
    height: width
    anchors.horizontalCenter: parent.horizontalCenter

    MouseArea {
        anchors.fill: parent
        onClicked: function() {
            parent.ListView.view.currentIndex = index
            parent.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Image {
            id: icon

            Layout.maximumWidth: parent.width
            Layout.maximumHeight: parent.height
            Layout.fillHeight: true
            anchors.horizontalCenter: parent.horizontalCenter

            fillMode: Image.PreserveAspectFit
            antialiasing: true
            smooth: true
        }

        FBLabel {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Text"
            font.pixelSize: TextMetrics.normalSize
        }
    }
}
