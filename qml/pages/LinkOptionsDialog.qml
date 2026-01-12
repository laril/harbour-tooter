import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: linkDialog
    property string url: ""
    property bool openInReader: false

    canAccept: true

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Open Link")
                acceptText: qsTr("Cancel")
            }

            // URL display
            Label {
                text: url
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                maximumLineCount: 3
                truncationMode: TruncationMode.Fade
            }

            // Spacing
            Item { width: 1; height: Theme.paddingLarge }

            // Reader Mode button
            Button {
                text: qsTr("Reader Mode")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    openInReader = true
                    accept()
                }
            }

            // Open in Browser button
            Button {
                text: qsTr("Open in Browser")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    openInReader = false
                    accept()
                }
            }

            // Copy link button
            Button {
                text: qsTr("Copy Link")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Clipboard.text = url
                    reject()  // Close dialog after copying
                }
            }
        }
    }
}
